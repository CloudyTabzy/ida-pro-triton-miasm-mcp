# CLAUDE.md

Guidance for working in this repository.

## What this project is

Fork of [mrexodia/ida-pro-mcp](https://github.com/mrexodia/ida-pro-mcp) that adds **Triton symbolic execution** and **Miasm IR analysis** as native built-in tool modules.

Main pieces:
- `src/ida_pro_mcp/server.py`: MCP server entrypoint
- `src/ida_pro_mcp/idalib_server.py`: headless idalib server
- `src/ida_pro_mcp/ida_mcp/`: IDA/plugin-side APIs

Core API modules (upstream):
- `api_core.py`: IDB metadata, functions, strings, imports
- `api_analysis.py`: decompilation, disassembly, xrefs, paths, pattern search
- `api_memory.py`: bytes/ints/strings, patching
- `api_types.py`: structs, type inference, type application
- `api_modify.py`: comments, renaming, asm patching
- `api_stack.py`: stack frame operations
- `api_sigmaker.py`: signature creation, scanning, xref signatures (uses sigmaker.py)
- `api_debug.py`: debugger control, unsafe / low priority for tests
- `api_python.py`: execute Python in IDA context
- `api_resources.py`: `ida://` MCP resources

Optional analysis engine modules (this fork):
- `api_triton.py`: Triton symbolic execution — 32 tools covering context lifecycle, symbolization, concrete values, instruction processing, taint analysis, SMT solving, and snapshots. Requires `pip install triton-library`.
- `api_miasm.py`: Miasm IR analysis — 14 tools covering IR lifting, SSA, CFG analysis, dead-code elimination, symbolic emulation, data-flow tracing, and cross-arch assembly/patching. Requires `pip install miasm future`.

## Optional-import pattern

Both `api_triton.py` and `api_miasm.py` guard their tool registrations so the plugin loads cleanly when the engine is absent:

```python
try:
    import triton as _triton_lib
    TRITON_AVAILABLE = True
except ImportError:
    TRITON_AVAILABLE = False

# One status probe tool is always registered (outside the guard)
@tool
@idasync
def triton_status() -> str: ...

# All other tools are inside the guard
if TRITON_AVAILABLE:
    @tool
    @idasync
    def triton_init(...): ...
```

`__init__.py` imports both modules inside `try/except Exception: pass` so a bad install can't break the plugin.

## Core implementation rules

### IDA thread safety
All IDA SDK calls must run on the main thread.
Use:
```python
from .rpc import tool
from .sync import idasync

@tool
@idasync
def my_tool(...):
    ...
```

Decorator order matters: `@tool` is outer, `@idasync` is inner.

### API conventions
- Prefer batch-first APIs.
- Many functions accept either a comma-separated string or a list.
- Use full type hints and `Annotated[...]` descriptions.
- The function docstring becomes the MCP tool description.

Example:
```python
def my_api(addrs: Annotated[str, "Addresses (0x401000, main) or list"]) -> list[dict]:
    ...
```

### Common helpers
- Parse addresses with `parse_address()`
- Normalize batch input with `normalize_list_input()` / `normalize_dict_list()`
- Use shared pagination / filtering helpers from `utils.py`

### Unsafe operations
Debugger or destructive operations should be marked unsafe:
```python
from .rpc import tool, unsafe

@unsafe
@tool
@idasync
def dangerous_op(...):
    ...
```

## Development commands

### Run
```bash
uv run ida-pro-mcp
uv run ida-pro-mcp --transport http://127.0.0.1:8744/sse
uv run idalib-mcp --stdio path/to/binary
uv run idalib-mcp --host 127.0.0.1 --port 8745 path/to/binary
uv run idalib-mcp --isolated-contexts --host 127.0.0.1 --port 8745 path/to/binary
uv run ida-pro-mcp --unsafe
```

### MCP inspector
```bash
uv run mcp dev src/ida_pro_mcp/server.py
```

### Install / uninstall
```bash
uv run ida-pro-mcp --install
uv run ida-pro-mcp --uninstall
```

## Testing and coverage

### Run tests
Use the headless test runner:
```bash
uv run ida-mcp-test tests/crackme03.elf -q
uv run ida-mcp-test tests/typed_fixture.elf -q
uv run ida-mcp-test tests/crackme03.elf -c api_analysis
uv run ida-mcp-test tests/typed_fixture.elf -p "*stack*"
```

Notes:
- Use `uv run ...`
- Non-interactive output should show failures only plus a summary
- Binary-specific tests should use `@test(binary="...")` with the executable basename

### Coverage
Measure coverage across both maintained fixtures:
```bash
uv run coverage erase
uv run coverage run -m ida_pro_mcp.test tests/crackme03.elf -q
uv run coverage run --append -m ida_pro_mcp.test tests/typed_fixture.elf -q
uv run coverage report --show-missing
```

Current fixture intent:
- `tests/crackme03.elf`: compact general regression fixture
- `tests/typed_fixture.elf`: typed globals / structs / locals / stack coverage fixture

### Test expectations
- Prefer semantic assertions, not weak "field exists" checks
- Prefer round-trip tests for mutating APIs
- If tests expose clearly wrong API behavior, fix the API instead of weakening the test
- Focus on IDA-facing modules, not server/config plumbing
- Expect some IDA / Hex-Rays variance; guarded assertions or runtime skips are acceptable when justified

### Generic-test sanity check
When adding generic tests, also try a non-fixture binary to avoid ELF-specific assumptions:
```bash
uv run ida-mcp-test "C:\CodeBlocks\x64dbg\bin\x64\x64dbg.dll" -q
```

## Scope priorities

High priority:
- `api_analysis.py`
- `api_types.py`
- `api_modify.py`
- `api_stack.py`
- `api_memory.py`
- `api_core.py`
- `api_resources.py`
- `api_triton.py`
- `api_miasm.py`
- `utils.py`
- `framework.py`

Lower priority:
- `api_debug.py`
- MCP transport / hosting details
- install / config mutation logic

## Practical notes

- Server/plugin Python: 3.11+
- IDA Pro 8.3+; 9.0 recommended
- IDA Free is not supported
- If IDA uses the wrong Python, use `idapyswitch`
