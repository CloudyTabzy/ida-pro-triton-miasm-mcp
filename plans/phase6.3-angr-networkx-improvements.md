# Phase 6.3 — Angr & NetworkX Hardening

**Created:** 2026-05-22
**Based on:** `Feedbacks/synapse-mcp-tools-testing-report.md` (tested on `frz_crackme_rage_v7.exe`, 810 functions, x86_64 PE)

---

## Status of Phase 6.2 issues

| Issue | Status |
|---|---|
| `angr_find_paths` SIGINT handler crash | FIXED — three-layer `_patch_claripy_sigint()` + runtime retry guard in `_do_explore` |
| `angr_enumerate_reachable` SpillingCFG `.neighbors()` | FIXED — manual BFS with `.successors()` already in code |
| `angr_cfg_fast` generator `len()` | FIXED — uses `number_of_nodes()` / `number_of_edges()` fallbacks |
| YARA `algorithm` vs `algorithms` | FIXED — renamed parameter to `algorithm` |

---

## Remaining issues (Phase 6.3)

### 6.3.1 — `nx_neighborhood` radius expansion returns 1 node (Medium)

**Symptom:** `nx_neighborhood(center="0x140002590", radius=2)` returns only the center node, 0 edges.

**Possible causes:**
- The function is genuinely isolated (in_degree=0, out_degree=0) — the code already diagnoses this; verify if this is just an isolated function.
- `_nx.ego_graph(G, seed, radius=2, undirected=True)` silently returns only the center node when the graph is a `DiGraph` and `undirected=True` does not behave as expected in some NetworkX versions.
- The call graph was built before the function was created (stale cache) — the code already suggests `nx_call_graph` rebuild.

**Investigation needed:**
- Confirm `seed_degrees` in the response shows non-zero in/out degree when this "fails".
- If degrees are non-zero: test `_nx.ego_graph` on the same graph in isolation to check for a NetworkX version mismatch.
- If degrees are zero: expected behavior; update diagnostic to be even more explicit.

**Fix approach:** If `ego_graph` is the culprit, replace with a manual BFS that mirrors the `angr_enumerate_reachable` approach.

---

### 6.3.2 — NetworkX node address format edge case (Low)

**Symptom:** `nx_shortest_path` / `nx_all_paths` / `nx_cycles` fail to find nodes when called with addresses. Report states nodes are stored as decimal integers (e.g., `5375319936`) but agents pass hex strings.

**Current mitigation:** `_resolve_to_graph_node` already:
1. Parses hex strings via `parse_address()` → integer
2. Falls back to raw-hex parse for bare hex strings without `0x`
3. Normalizes to IDA function start

**Investigation needed:**
- Run `nx_shortest_path` with `"0x140002590"` on a freshly-built call graph.
- If it fails: add a decimal-string-to-int fallback path in `_resolve_to_graph_node`.
- If it succeeds: the bug report may have been caused by a stale graph or wrong address.

**Candidate fix:** In `_resolve_to_graph_node`, also try `int(stripped, 10)` as a last resort:
```python
# Last resort: bare decimal string
try:
    dec_parsed = int(stripped, 10)
    if G.has_node(dec_parsed):
        return dec_parsed
except ValueError:
    pass
```

---

### 6.3.3 — `angr_value_set` "No path found" clarity (Low)

**Symptom:** Returns `"No path reached 0x1400036a9 from 0x140002590."` with no additional context.

**Improvement:** Include:
- Whether the CFG was built (and if not, suggest `angr_cfg_fast`)
- The number of basic blocks between source and target in the CFG
- A note distinguishing "no concrete path in CFG" (dead code) vs "path exists but symbolic execution timed out"

---

### 6.3.4 — SIGINT stress-test verification (Medium)

**What to do:** After the Phase 6.2 SIGINT fixes, run `angr_find_paths` on several crackmes:
1. A simple crackme with stdin comparison (test the full path: patch fires, explore runs, solution extracted)
2. `frz_crackme_rage_v7.exe` with `char_constraint="printable"` to verify 0 SIGINT assertions
3. A looping crackme with `use_dfs=True` and `use_veritesting=True`

**What to verify:**
- No `"Told to uninstall SIGINT handler even though we didn't install it"` in IDA console
- States explored > 0
- `timed_out` field is accurate

---

### 6.3.5 — `hybrid_angr_unicorn_concrete` implementation (Large)

**Blocked on:** `api_unicorn.py` backend module (not yet created).

**Design:**
- Phase 1: concrete prefix — run entry→target with Unicorn (fast concrete emulation)
- Phase 2: symbolic suffix — hand state off to angr at the split point
- Use case: binaries with expensive initialization code before the serial check

**Files needed:**
- `src/ida_pro_mcp/ida_mcp/api_unicorn.py` — new module
- Add `unicorn_status`, `unicorn_emulate_range`, `unicorn_hook_memory` tools
- Wire `hybrid_angr_unicorn_concrete` in `api_angr.py` to use `api_unicorn` functions

**Dependency:** `pip install unicorn` (~15 MB; add to `pyproject.toml` as optional dep `[unicorn]`)

---

### 6.3.6 — Angr comprehensive regression suite (Medium)

**What:** A dedicated test binary for angr (similar to `crackme03.elf` for general tools).

**Requirements:**
- Small ELF or PE crackme solvable within 30s with `workflow_solve_crackme`
- Tests `angr_find_paths`, `angr_cfg_fast`, `angr_enumerate_reachable`, `angr_backward_slice`
- Run with `uv run ida-mcp-test tests/crackme_angr.elf -c api_angr`

**Alternative:** Use `tests/crackme03.elf` and add `@test(binary="crackme03.elf")` angr tests there (the binary is already loaded; just verify angr can load the same binary).

---

## Priority order

1. **6.3.4** (stress-test SIGINT) — highest leverage; verifies the Phase 6.2 fix actually works
2. **6.3.2** (decimal node edge case) — one-liner fix, low risk
3. **6.3.1** (neighborhood expansion) — investigate first, fix if ego_graph is the culprit
4. **6.3.3** (value_set clarity) — polish
5. **6.3.6** (regression suite) — adds long-term safety
6. **6.3.5** (unicorn hybrid) — large; separate phase when api_unicorn.py is ready
