---
name: miasm-ir-analysis
description: Miasm IR lifting, SSA transformation, CFG analysis, and data-flow tracing inside IDA Pro. Use for deobfuscation, complexity analysis, understanding data provenance, and cross-architecture assembly. Ideal for obfuscated binaries, control-flow flattening, and opaque predicate removal.
allowed-tools: mcp__ida_pro_mcp__miasm_status, mcp__ida_pro_mcp__miasm_sync, mcp__ida_pro_mcp__miasm_init, mcp__ida_pro_mcp__miasm_get_context_info, mcp__ida_pro_mcp__miasm_reset, mcp__ida_pro_mcp__miasm_lift_function, mcp__ida_pro_mcp__miasm_lift_to_ir, mcp__ida_pro_mcp__miasm_get_ssa, mcp__ida_pro_mcp__miasm_get_cfg_dot, mcp__ida_pro_mcp__miasm_get_cfg_summary, mcp__ida_pro_mcp__miasm_deobfuscate_cfg, mcp__ida_pro_mcp__miasm_trace_data_flow, mcp__ida_pro_mcp__miasm_find_paths, mcp__ida_pro_mcp__miasm_solve_path_constraints, mcp__ida_pro_mcp__miasm_annotate_data_flow, mcp__ida_pro_mcp__miasm_assemble, mcp__ida_pro_mcp__miasm_patch_instruction, mcp__ida_pro_mcp__miasm_simplify_block, mcp__ida_pro_mcp__miasm_emulate_symbolic, mcp__ida_pro_mcp__miasm_get_function_side_effects, mcp__ida_pro_mcp__miasm_search_instruction_pattern, mcp__ida_pro_mcp__lookup_funcs, mcp__ida_pro_mcp__decompile, mcp__ida_pro_mcp__disasm, mcp__ida_pro_mcp__basic_blocks, mcp__ida_pro_mcp__set_comments, mcp__ida_pro_mcp__rename, mcp__ida_pro_mcp__get_bytes, mcp__ida_pro_mcp__int_convert, Bash, Read, Write, AskUserQuestion
---

# miasm-ir-analysis

Use Miasm's intermediate representation (IR) lifting and analysis capabilities inside IDA Pro. Lift functions to IR, apply SSA transformation, analyze CFG structure, deobfuscate control flow, trace data flow, and solve path constraints.

> **Tool prefix note**: MCP tool names depend on your client configuration. If your server is named differently, adjust the prefix accordingly.

> **Dependency**: Requires `miasm` and `future` to be installed (`ida-pro-mcp --install-deps miasm`).

## Prerequisites

- Miasm must be installed and available (`miasm_status` returns `"available": true`)
- Target function must be defined in IDA

## Instructions

### 1. Verify Miasm availability

```
mcp__ida_pro_mcp__miasm_status()
```

If `"available": false`, stop and tell the user to install Miasm:
> Miasm is not installed. Install it with `ida-pro-mcp --install-deps miasm`

### 2. Sync architecture

```
mcp__ida_pro_mcp__miasm_sync()
```

This ensures Miasm's internal Machine matches the current IDA database. Note the returned architecture, bitness, and endianness.

If the architecture changed (e.g., after rebase or loading a different file), call:

```
mcp__ida_pro_mcp__miasm_reset()
```

### 3. Choose analysis mode

**Option A — CFG structural analysis:** Understand function complexity, loops, and dead code.

**Option B — IR lifting and SSA:** View the function in Miasm's intermediate representation.

**Option C — Deobfuscation:** Remove opaque predicates, fold constants, eliminate dead code.

**Option D — Data-flow tracing:** Find where a register's value originates.

**Option E — Path constraint solving:** Find concrete inputs that reach a specific basic block.

**Option F — Cross-arch assembly:** Assemble instructions and patch the database.

## Option A — CFG structural analysis: Understand function complexity, loops, and dead code.

**A1. Get CFG summary**

```
mcp__ida_pro_mcp__miasm_get_cfg_summary(address="<func_addr>")
```

Returns:
- **Block count** — total basic blocks
- **Edge count** — control flow edges
- **Cyclomatic complexity** — `edges - nodes + 2`
- **Loop count** — natural loops detected via Tarjan's SCC

High cyclomatic complexity (>10) suggests complex logic or obfuscation.

**A2. Get CFG DOT**

```
mcp__ida_pro_mcp__miasm_get_cfg_dot(address="<func_addr>")
```

Returns the Graphviz DOT string of the assembly CFG. Save to a file and render:

```
Bash("dot -Tpng cfg.dot -o cfg.png")
```

## Option B — IR lifting and SSA: View the function in Miasm's intermediate representation.

**B1. Lift to IR**

```
mcp__ida_pro_mcp__miasm_lift_function(address="<func_addr>")
```

Returns the IRCFG as JSON blocks and edges. Each block contains IR statements in Miasm's syntax. For a single block, use `miasm_lift_to_ir(address, end_address)`.

**B2. Apply SSA transformation**

```
mcp__ida_pro_mcp__miasm_get_ssa(address="<func_addr>")
```

SSA form ensures each variable is assigned exactly once, enabling clear def-use chains. Look for:
- Simplified expressions at merge points
- Clear register assignment history

## Option C — Deobfuscation: Remove opaque predicates, fold constants, eliminate dead code.

**C1. Get baseline**

```
mcp__ida_pro_mcp__miasm_get_cfg_summary(address="<func_addr>")
```

Record the original block count and complexity.

**C2. Run deobfuscation**

```
mcp__ida_pro_mcp__miasm_deobfuscate_cfg(address="<func_addr>")
```

Applies constant folding, dead code elimination, and expression simplification via Miasm's `DeadRemoval` pass.

**C3. Compare**

```
mcp__ida_pro_mcp__miasm_get_cfg_summary(address="<func_addr>")
```

Look for reduced block count, reduced cyclomatic complexity, and simplified expressions.

## Option D — Data-flow tracing: Find where a register's value originates.

**D1. Trace origins**

```
mcp__ida_pro_mcp__miasm_trace_data_flow(
    address="<addr>",
    register="RAX"
)
```

Uses Miasm's dependency graph to perform a backward slice. Returns IR expression nodes that contribute to the register's value.

**D2. Annotate in IDA (`@unsafe`)**

> Requires `--unsafe` flag.

```
mcp__ida_pro_mcp__miasm_annotate_data_flow(
    address="<addr>",
    register="RAX",
    overwrite=False
)
```

Writes `[DF] RAX <- <origin>` comments at each data-flow origin instruction.

## Option E — Path constraint solving: Find concrete inputs that reach a specific block.

**E1. Find paths**

```
mcp__ida_pro_mcp__miasm_find_paths(
    start_ea="<func_entry>",
    target_ea="<target_block>",
    max_paths=20
)
```

Enumerates execution paths between two addresses within the same function.

**E2. Solve for inputs**

```
mcp__ida_pro_mcp__miasm_solve_path_constraints(
    start_ea="<func_entry>",
    target_ea="<target_block>",
    symbolize_args="rdi,rsi,rdx",
    timeout_ms=10000
)
```

Uses Miasm's CFG path finding to enumerate up to 5 paths. When Triton is available, attempts Z3 solving. Gracefully returns path addresses without Z3 model if Triton is absent.

## Option F — Cross-arch assembly and patching: Assemble and write instructions.

**F1. Assemble**

```
mcp__ida_pro_mcp__miasm_assemble(
    asm_string="MOV EAX, 1",
    arch=""
)
```

Architecture is auto-detected from IDA. Returns all possible encodings with the shortest/longest.

**F2. Patch (`@unsafe`)**

> Requires `--unsafe` flag.

```
mcp__ida_pro_mcp__miasm_patch_instruction(
    address="<addr>",
    asm_string="NOP"
)
```

Uses the shortest encoding. The change is immediately reflected in IDA's view.

### 4. Report results

Present findings in a structured format:

```markdown
## Miasm IR Analysis Results

### Target
- Function: `<name>` at `<addr>`

### CFG Summary
- Blocks: N → M (after deobfuscation)
- Complexity: N → M
- Loops: ...

### IR/SSA Highlights
- <notable IR pattern>
- <phi functions at merge points>

### Data Flow (if traced)
- `<register>` at `<addr>` originates from: ...

### Path Constraints (if solved)
| Path | Feasible | Constraints |
|---|---|---|
| ... | ... | ... |

### Patches Applied (if any)
| Address | Original | New | Reason |
|---|---|---|---|
| ... | ... | ... | ... |
```
