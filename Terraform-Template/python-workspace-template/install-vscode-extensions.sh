#!/bin/bash
set -e

EXT_DIR="$HOME/.vscode-server/extensions"
BIN_DIR="$HOME/.vscode-server/bin"

mkdir -p "$EXT_DIR"

# List of extensions to install
EXTENSIONS=(
    "ms-python.python"
    "ms-python.black-formatter"
)

echo "[vscode-auto-setup] Watching for VS Code attach..."

# Wait until VS Code server is installed
while [ ! "$(ls -A $BIN_DIR 2>/dev/null)" ]; do
    sleep 2
done

echo "[vscode-auto-setup] VS Code server detected. Installing extensions..."

for EXT in "${EXTENSIONS[@]}"; do
    code-server --install-extension "$EXT" --force --extensions-dir "$EXT_DIR" || true 
done

echo "[vscode-auto-setup] Extensions installed."