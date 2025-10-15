#!/bin/bash -i

# Setup pre-commit hooks on local dev environment, including required
# tools that may come from python, node, apt or compiled rust
#
# Note: tested on ubuntu 22.04


initialize_pre_commit() {

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

  # trap errors (assume sourced) to indicate dev-init problems
  # Note: trap persist until function succeeds and runs bottom "trap - ERR"
  trap 'echo "❌ Error in initialize-pre-commit.sh at line $LINENO"; return 1' ERR

  # Resolve directory of this script, then its parent (the project root)
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  cd "$PROJECT_ROOT" || {
    echo "❌ Could not cd to $PROJECT_ROOT" >&2
    return 1 2>/dev/null || true
  }

  # safely sync
  source "${PROJECT_ROOT}/dev-scripts/safe-sync.sh"

  # node-based tools
  echo "📦 Installing npm (requires sudo for apt)"
  sudo apt install npm
  prettier_version=$(extract-tool-version-from-pyproject-toml.sh prettier)
  npm install --save-dev --save-exact "prettier@${prettier_version}"
  action_validator_version=$(extract-tool-version-from-pyproject-toml.sh action-validator)
  npm install --save-dev --save-exact "@action-validator/core@${action_validator_version}" "@action-validator/cli@${action_validator_version}"

  # apt-based tools
  echo "📦 Installing yamllint and shellcheck (requires sudo for apt)"
  sudo apt install yamllint shellcheck

  # install latest rust for some tools
  echo "🗑️ removing old rustc and cargo prior to refresh (requires sudo for apt)"
  sudo apt remove rustc cargo
  curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh

  echo "📦 Installing rust"
  # reload the bashrc
  # WARNING: this will only work if shebang has the -i option due to ubuntu
  source $HOME/.bashrc
  # Install rust toolchain
  rustup toolchain install stable

  echo "📦 Installing golang (requires sudo for apt)"
  # Install golang for yamlfmt
  sudo apt install golang

  echo "🔄 Installing pre-commit, with hooks"

  # Note: pre-commit and pre-commit-uv are installed in the tooling extra
  #       section in pyproject.toml.
  uv run pre-commit clean && uv run pre-commit install --install-hooks

  # test run
  pre-commit run -a

  echo "✅ Pre-commit ready"
  # Note: trap will restore old opts and history recording

}

initialize_pre_commit "$@"
