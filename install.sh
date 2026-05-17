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
echo "[1/4] Removing conflicting upstream packages..."
pip3 uninstall -y ida-pro-mcp ida-pro-mcp-xjoker 2>/dev/null || true
echo "[OK] Done."
echo

# --- Install this fork in editable mode ---------------------------------------
echo "[2/4] Installing ida-pro-triton-miasm-mcp from source..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
pip3 install -e . >/dev/null 2>&1 || pip3 install -e .
echo "[OK] Fork installed successfully."
echo

# --- Install the IDA plugin (with interactive TUI) ----------------------------
echo "[3/4] Installing IDA Pro plugin..."
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

# --- Optional binary format parsing libraries ---------------------------------
echo
echo "[4/4] Optional binary format parsing libraries"
echo "-----------------------------------------------"
echo "These libraries add extra IDA tools for parsing binary structures and"
echo "identifying file types. Each is independently optional."
echo
echo "  construct       - construct_*  tools  (declarative binary format grammar)"
echo "  dissect.cstruct - cstruct_*    tools  (C-syntax struct/enum/typedef parsing)"
echo "  filetype        - filetype_*   tools  (magic-byte file type identification)"
echo

INSTALL_CONSTRUCT=n
INSTALL_CSTRUCT=n
INSTALL_FILETYPE=n

read -rp "Install ALL three parsing libraries? [y/N]: " CHOICE
if [[ "${CHOICE,,}" == "y" ]]; then
    INSTALL_CONSTRUCT=y
    INSTALL_CSTRUCT=y
    INSTALL_FILETYPE=y
else
    echo
    read -rp "  Install construct        (construct_* tools)?  [y/N]: " C
    [[ "${C,,}" == "y" ]] && INSTALL_CONSTRUCT=y

    read -rp "  Install dissect.cstruct  (cstruct_* tools)?   [y/N]: " CS
    [[ "${CS,,}" == "y" ]] && INSTALL_CSTRUCT=y

    read -rp "  Install filetype         (filetype_* tools)?  [y/N]: " FT
    [[ "${FT,,}" == "y" ]] && INSTALL_FILETYPE=y
fi

echo
ANY_INSTALLED=n

if [[ "$INSTALL_CONSTRUCT" == "y" ]]; then
    echo "Installing construct..."
    if pip3 install construct >/dev/null 2>&1; then
        echo "  [OK] construct installed."
        ANY_INSTALLED=y
    else
        echo "  [WARNING] construct install failed. Run manually: pip3 install construct"
    fi
fi

if [[ "$INSTALL_CSTRUCT" == "y" ]]; then
    echo "Installing dissect.cstruct..."
    if pip3 install "dissect.cstruct" >/dev/null 2>&1; then
        echo "  [OK] dissect.cstruct installed."
        ANY_INSTALLED=y
    else
        echo "  [WARNING] dissect.cstruct install failed. Run manually: pip3 install dissect.cstruct"
    fi
fi

if [[ "$INSTALL_FILETYPE" == "y" ]]; then
    echo "Installing filetype..."
    if pip3 install filetype >/dev/null 2>&1; then
        echo "  [OK] filetype installed."
        ANY_INSTALLED=y
    else
        echo "  [WARNING] filetype install failed. Run manually: pip3 install filetype"
    fi
fi

if [[ "$ANY_INSTALLED" == "n" && "$INSTALL_CONSTRUCT" == "n" && "$INSTALL_CSTRUCT" == "n" && "$INSTALL_FILETYPE" == "n" ]]; then
    echo "  [SKIP] No parsing libraries selected."
fi

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
echo "Tip: To install analysis engines later, run:"
echo "  ida-pro-mcp --install-deps triton"
echo "  ida-pro-mcp --install-deps miasm"
echo "  pip3 install construct dissect.cstruct filetype"
echo
