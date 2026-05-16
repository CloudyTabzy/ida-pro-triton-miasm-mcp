@echo off
setlocal

echo ============================================================
echo  IDA Pro Triton ^& Miasm MCP - Enhanced Fork Installer
echo  https://github.com/CloudyTabzy/ida-pro-triton-miasm-mcp
echo ============================================================
echo.

:: --- Check Python version ---------------------------------------------------
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please install Python 3.11+ from https://www.python.org/downloads/
    pause
    exit /b 1
)

for /f "usebackq tokens=*" %%a in (`python -c "import sys; v=sys.version_info; print(f'{v.major}.{v.minor}')"`) do set PY_VER=%%a

echo [OK] Python %PY_VER% detected.
echo.

:: --- Uninstall conflicting upstream packages --------------------------------
echo [1/3] Removing conflicting upstream packages...
pip uninstall -y ida-pro-mcp ida-pro-mcp-xjoker >nul 2>&1
echo [OK] Done.
echo.

:: --- Install this fork in editable mode -------------------------------------
echo [2/3] Installing ida-pro-triton-miasm-mcp from source...
cd /d "%~dp0"
pip install -e . >nul 2>&1
if errorlevel 1 (
    echo [ERROR] pip install failed. Trying with output...
    pip install -e .
    pause
    exit /b 1
)
echo [OK] Fork installed successfully.
echo.

:: --- Install the IDA plugin (with interactive TUI) --------------------------
echo [3/3] Installing IDA Pro plugin...
echo.
echo The installer will now launch the IDA plugin installer.
echo If prompted, use arrow keys + space to select optional engines
echo (Triton / Miasm), then press Enter to confirm.
echo.
pause

call ida-pro-mcp --install
if errorlevel 1 (
    echo.
    echo [WARNING] IDA plugin installation may have encountered an issue.
    echo This is normal if IDA Pro is not currently running.
    echo The plugin will be available the next time you start IDA.
    pause
)

echo.
echo ============================================================
echo  Installation complete!
echo ============================================================
echo.
echo Available commands:
echo   ida-pro-mcp           (drop-in replacement for upstream)
echo   ida-triton-miasm-mcp  (fork alias)
echo   ida-pro-mcp-enhanced  (fork alias)
echo   idalib-mcp            (headless mode)
echo   ida-mcp-trace-dump    (trace export utility)
echo.
echo Next steps:
echo   1. Restart IDA Pro completely
echo   2. The MCP server auto-starts on http://127.0.0.1:13337
echo   3. Configure your MCP client to connect
echo.
pause
