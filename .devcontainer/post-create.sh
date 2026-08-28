#!/usr/bin/env bash
set -euo pipefail

# Runs once after the container is created. Safe against a repo with no game code yet.

chmod +x scripts/*.sh

# Named volumes for bash history / godot config are created root-owned; hand them to vscode.
sudo mkdir -p /commandhistory
sudo chown -R "$(id -u):$(id -g)" /commandhistory
touch /commandhistory/.bash_history || true

echo "=== Toolchain check ==="
echo "Godot:    $(godot --headless --version)"
echo "gdformat: $(gdformat --version 2>&1)"
echo "gdlint:   $(gdlint --version 2>&1 || echo 'gdlint has no --version flag; installed OK')"
echo "Python:   $(python3 --version)"
echo "========================"
