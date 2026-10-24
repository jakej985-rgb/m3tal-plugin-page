#!/usr/bin/env bash
# ==============================================================================
# scripts/smart-bump.sh
# Smart Semantic Version Bumper and Change Detector for M3TAL Plugins Monorepo.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="${SCRIPT_DIR}/smart-bump.py"

exec python3 "${PYTHON_SCRIPT}" "$@"
