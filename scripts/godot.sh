#!/usr/bin/env bash
set -euo pipefail

# Thin wrapper: always runs godot against the repo root, regardless of cwd.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

exec godot --path "$REPO_ROOT" "$@"
