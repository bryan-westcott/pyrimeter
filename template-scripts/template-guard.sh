#!/usr/bin/env bash
set -euo pipefail

# Intended to be SOURCED by template-scripts/substitute-placeholders.sh
# Requires: REPO_ROOT set (absolute path)

pyrimeter_template_guard() {
  : "${REPO_ROOT:?REPO_ROOT must be set before calling pyrimeter_template_guard}"

  # Only enforce if a git directory exists
  if [[ -d "${REPO_ROOT}/.git" ]]; then
    # Step 1: If git exists, scan history for template identifiers and warn specifically.
    if command -v git >/dev/null 2>&1; then
      local forbidden_re
      forbidden_re='pyrimeter|pyrimiter|pyproj-template|pyrproj-template'

      if git -C "${REPO_ROOT}" log --all --pretty=format:%B | grep -Eqi "${forbidden_re}"; then
        cat >&2 <<'EOF'
It looks like you still have Pyrimeter template history in .git.

You will want to remove this to avoid inheriting any previous code and context,
including permissive licenses. You will need to create a fresh init to avoid
this scenario.

WARNING: Please ensure you didn't commit anything else you intend to keep.

Please run `substitute-placeholders` before the new git-init!
EOF
        return 1
      fi
    fi

    # Step 2: Always hard-stop if .git exists (even if history scan didn't match).
    cat >&2 <<EOF
ERROR: For safety (particularly inheriting Pyrimeter history and permissive licenses),
this script will not run with a .git directory present.

Action required:
  rm -rf "${REPO_ROOT}/.git"
  # run this script (substitute-placeholders)
  git init
EOF
    return 1
  fi
}
