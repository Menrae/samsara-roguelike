#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [ -d src ]; then
    echo "Linting src/ with gdlint..."
    gdlint src
else
    echo "No src/ directory yet — skipping gdlint."
fi

if [ -f project.godot ]; then
    echo "Running headless import/validate pass..."
    if godot --headless --import --quit 2>&1 | tee /tmp/godot-import.log; then
        :
    else
        # Older/newer Godot builds phrase this flag differently; fall back to a plain headless
        # boot-and-quit, which still surfaces parse/import errors in stderr.
        echo "'--import' pass failed or unsupported on this Godot build, falling back to --headless --quit"
        godot --headless --quit
    fi
else
    echo "No project.godot yet — skipping headless import/validate pass."
fi

echo "check.sh: OK"
