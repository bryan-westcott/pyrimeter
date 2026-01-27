#!/usr/bin/env bash

# Find all generated files that need manual substitution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "WARNING: The following files need manual substitution before committing!"
echo ""

( cd "${REPO_ROOT}" && grep --color=always -ir "TODO: Insert" . )
