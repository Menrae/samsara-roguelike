#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [ -d src ]; then
    gdformat src
else
    echo "No src/ directory yet — nothing to format."
fi
