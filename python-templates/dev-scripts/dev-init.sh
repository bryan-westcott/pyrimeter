#!/bin/bash

# Prep dev environment
# 1. check if sourcing
# 2. create project venv (if not exist)
# 3. activate venv (and check that VIRTUAL_ENV var is set)
# 4. sync dev/notebook dependencies 
# 5. install current project as an editable package
# 6. register environment as jupyter kernel

# trap errors
trap 'echo "❌ Error on line $LINENO"; (return 1 2>/dev/null) || exit 1' ERR

# Ensure script is sourced, not executed
(return 0 2>/dev/null) || {
  echo "❌ This script must be sourced, not executed."
  echo "   Run it like this:  source dev-init.sh"
  exit 1
}

# Resolve directory of this script, then its parent (the project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "📦 Creating virtual environment with uv..."
uv venv

echo "🔗 Activating virtual environment..."
if ! source .venv/bin/activate; then
  echo "❌ Failed to activate .venv"
  return 1 2>/dev/null || exit 1
fi
echo "VIRTUAL_ENV=${VIRTUAL_ENV?}"

echo "📋 Syncing dependencies from pyproject.toml..."
if ! uv sync --dev --group notebook; then
  echo "❌ Failed to sync dependencies"
  return 1 2>/dev/null || exit 1
fi

echo "🔧 Installing project in editable mode..."
if ! uv pip install -e .; then
  echo "❌ Failed to install editable project"
  return 1 2>/dev/null || exit 1
fi

echo "🧹 Removing default 'python3' kernel if present..."
jupyter kernelspec remove -y python3 || true

KERNEL_NAME="$(basename "$PROJECT_ROOT")"
echo "🧠 Registering Jupyter kernel: ${KERNEL_NAME?}..."
if ! uv run ipython kernel install \
  --user \
  --env VIRTUAL_ENV "$PROJECT_ROOT/.venv" \
  --name "${KERNEL_NAME?}" \
  --display-name "${KERNEL_NAME?}"; then
  echo "❌ Kernel registration failed — possibly missing ipykernel or misconfigured .venv"
  echo "   Try: uv sync --dev --group notebook"
  (return 1 2>/dev/null) || true  # Prevent terminal exit if sourced
fi

echo "✅ Dev environment ready, launch with:"
echo "uv run --with notebook jupyter lab"
echo "and select ${KERNEL_NAME?} kernel"

