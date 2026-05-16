#!/usr/bin/env bash
set -e

echo "============================================================"
echo "  IDA Pro Triton & Miasm MCP - Enhanced Fork Installer"
echo "  https://github.com/CloudyTabzy/ida-pro-triton-miasm-mcp"
echo "============================================================"
echo

# --- Check Python version -----------------------------------------------------
PY_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)' 2>/dev/null || echo 0)
PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)' 2>/dev/null || echo 0)

if [ "$PY_MAJOR" -lt 3 ] || [ "$PY_MINOR" -lt 11 ]; then
    echo "[ERROR] Python ${PY_MAJOR}.${PY_MINOR} found, but 3.11+ is required."
    exit 1
fi

echo "[OK] Python ${PY_MAJOR}.${PY_MINOR} detected."
echo

# --- Uninstall conflicting upstream packages ----------------------------------
echo "[1/3] Removing conflicting upstream packages..."
pip3 uninstall -y ida-pro-mcp ida-pro-mcp-xjoker 2>/dev/null || true
echo "[OK] Done."
echo

# --- Install this fork in editable mode ---------------------------------------
echo "[2/3] Installing ida-pro-triton-miasm-mcp from source..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
pip3 install -e . >/dev/null 2>&1 || pip3 install -e .
echo "[OK] Fork installed successfully."
echo

# --- Install the IDA plugin (with interactive TUI) ----------------------------
echo "[3/3] Installing IDA Pro plugin..."
echo
echo "The installer will now launch the IDA plugin installer."
echo "If prompted, use arrow keys + space to select optional engines"
echo "(Triton / Miasm), then press Enter to confirm."
echo
read -rp "Press Enter to continue..."

ida-pro-mcp --install || {
    echo
    echo "[WARNING] IDA plugin installation may have encountered an issue."
    echo "This is normal if IDA Pro is not currently running."
    echo "The plugin will be available the next time you start IDA."
}

echo
echo "============================================================"
echo "  Installation complete!"
echo "============================================================"
echo
echo "Available commands:"
echo "  ida-pro-mcp           (drop-in replacement for upstream)"
echo "  ida-triton-miasm-mcp  (fork alias)"
echo "  ida-pro-mcp-enhanced  (fork alias)"
echo "  idalib-mcp            (headless mode)"
echo "  ida-mcp-trace-dump    (trace export utility)"
echo
echo "Next steps:"
echo "  1. Restart IDA Pro completely"
echo "  2. The MCP server auto-starts on http://127.0.0.1:13337"
echo "  3. Configure your MCP client to connect"
echo
