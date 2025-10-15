#!/bin/bash

# Prep dev environment
# Safely uv sync based on sections found

# Note: this has to be a subshell better trap error in the dev script itself
safe_sync() {

  # Temporarily disable interactive history & file appends to avoid pollution
  set +o history

  # Save current options
  local old_opts
  old_opts=$(set +o)

  # Safely remove traps
  # Always restore options and history recording when this function exits
  # Note: will handle even if old_opts is unset (which can leave stale
  #       traps in bash otherwise)
  trap 'set +u; trap - RETURN ERR; [ "${old_opts+x}" ] && eval "$old_opts"; set -o history' RETURN

  # Set temp options
  # -u (nounset): treat unset variables as an error
  #   Example: echo "$FOO" when FOO is not set → causes immediate failure
  #   Helps catch typos and missing env vars early.
  set -u
  # -o pipefail: makes a pipeline fail if *any* command in it fails
  #   Default in Bash: only the *last* command in a pipeline matters.
  #   Example:
  #     false | true
  #   Without pipefail → exit code 0 (because 'true' succeeded).
  #   With pipefail   → exit code 1 (because 'false' failed).
  #
  #   This is useful when chaining commands with | where every stage matters.
  set -o pipefail

  # trap errors (assume sourced) to indicate safe-sync problems
  # Note: trap persist until function succeeds and runs bottom "trap - ERR"
  trap 'echo "❌ Error in safe-sync.sh at line $LINENO"; return 1' ERR

  # Resolve directory of this script, then its parent (the project root)
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  cd "$PROJECT_ROOT" || {
    echo "❌ Could not cd to $PROJECT_ROOT" >&2
    return 1 2>/dev/null || true
  }

  # Check for pyproject.toml
  PYPROJECT_FILE="${PROJECT_ROOT?}/pyproject.toml"
  if [ ! -f "$PYPROJECT_FILE" ]; then
    echo "❌ No pyproject.toml found in $PROJECT_ROOT, expected a minimal skeleton" >&2
    { return 1 2>/dev/null; } || exit 1
  fi

  # -- Check for notebook ---

  # check if notebook section in pyproject.toml
  HAS_NOTEBOOK_GROUP=0
  if grep -q '^[[:space:]]*notebook[[:space:]]*=' "$PYPROJECT_FILE"; then
    echo "📓 Detected 'notebook' group in $PYPROJECT_FILE"
    HAS_NOTEBOOK_GROUP=1
  else
    echo "🚫📓 No 'notebook' group found in $PYPROJECT_FILE."
  fi

  # -- Check for tests ---

  # check if tests section in pyproject.toml
  # NOTE: this should be an EXTRA not a group!
  HAS_TEST_EXTRA=0
  if grep -q '^[[:space:]]*test[[:space:]]*=' "$PYPROJECT_FILE"; then
    echo "🔬 Detected 'tests' group in $PYPROJECT_FILE"
    HAS_TEST_EXTRA=1
  else
    echo "🚫🔬  No 'tests' group found in $PYPROJECT_FILE."
  fi

  # -- Check for tooling ---

  # check if tooling section in pyproject.toml
  HAS_TOOLING_GROUP=0
  if grep -q '^[[:space:]]*tooling[[:space:]]*=' "$PYPROJECT_FILE"; then
    echo "🛠️  Detected 'tooling' extra in $PYPROJECT_FILE"
    HAS_TOOLING_GROUP=1
  else
    echo "🚫🛠️  No 'tooling' extra found in $PYPROJECT_FILE; skipping Jupyter setup."
  fi

  # -- Compose sync args ---

  # One sync pass to populate venv (frozen if lock exists)
  UV_SYNC_ARGS=()
  # Make dev explicit
  UV_SYNC_ARGS+=(--dev)
  # For pre-commit/linting/CI/CD
  [[ "${HAS_TOOLING_GROUP:-0}" -eq 1 ]] && UV_SYNC_ARGS+=(--group tooling)
  # For notebook support
  [[ "${HAS_NOTEBOOK_GROUP:-0}" -eq 1 ]] && UV_SYNC_ARGS+=(--group notebook)
  # For tests
  # Note: an optional group not dependency group
  [[ "${HAS_TEST_EXTRA:-0}" -eq 1 ]] && UV_SYNC_ARGS+=(--extra test)
  # Run sync
  echo "🔄 Syncing with args: ${UV_SYNC_ARGS[*]}"
  uv sync "${UV_SYNC_ARGS[@]}"
  echo "...✅ Sync successful"

}

safe_sync "$@"
