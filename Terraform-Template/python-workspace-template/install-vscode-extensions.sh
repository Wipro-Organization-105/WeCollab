#!/bin/bash
set -e

EXT_DIR="$HOME/.vscode-server/extensions"
BIN_DIR="$HOME/.vscode-server/bin"

mkdir -p "$EXT_DIR"

echo "[vscode-auto-setup] Watching for VS Code attach..."

# Wait until VS Code server is installed
while [ ! "$(ls -A $BIN_DIR 2>/dev/null)" ]; do
    sleep 2
done

echo "[vscode-auto-setup] VS Code server detected. Installing extensions..."

EXTENSIONS=`cat /tmp/extensions.txt|sed 's/,/ /g'`
if [ -n "$EXTENSIONS" ]; then
    for EXT in $EXTENSIONS; do
        echo "[vscode-auto-setup] Installing extension: $EXT"
        code-server --install-extension "$EXT" --force --extensions-dir "$EXT_DIR" || true
    done
else
    echo "[vscode-auto-setup] No extensions to install. Exiting."
    exit 0
fi