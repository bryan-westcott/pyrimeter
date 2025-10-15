#!/usr/bin/env bash

_main() {
  # Avoid polluting shell history
  set +o history

  # Snapshot current opts & cwd; harden during run
  local __orig_pwd __orig_opts script_dir
  __orig_pwd="$PWD"
  __orig_opts="$(set +o)"
  set -euo pipefail
  trap 'eval "$__orig_opts"; cd "$__orig_pwd" || true; set +o history; trap - RETURN' RETURN

  # Work from parent of script directory
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "$script_dir/.." || { echo "Cannot cd to parent of $script_dir" >&2; return 1; }

  # --- prompts (no defaults) ---
  read -rp "Python minor version (e.g., 11): " PY_MINOR
  [[ "$PY_MINOR" =~ ^[0-9]+$ ]] || { echo "Digits only (e.g., 11)" >&2; return 1; }
  read -rp "Project name: " PROJECT_NAME; [[ -n "$PROJECT_NAME" ]] || { echo "Required" >&2; return 1; }
  read -rp "Project description: " PROJECT_DESCRIPTION; [[ -n "$PROJECT_DESCRIPTION" ]] || { echo "Required" >&2; return 1; }

  # --- escape for sed ---
  escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
  local PY_MINOR_E NAME_E DESC_E
  PY_MINOR_E=$(escape "$PY_MINOR"); NAME_E=$(escape "$PROJECT_NAME"); DESC_E=$(escape "$PROJECT_DESCRIPTION")

  # --- files to edit in place ---
  # Option A: pass files as args to the script
  # Option B: hardcode the list here:
  # FILES=("pyproject.template.toml" "README.template.md")
  local -a FILES
  if (( "$#" > 0 )); then
    FILES=("$@")
  else
    # Edit here if you prefer a fixed list:
    FILES=("pyproject.toml" ".pre-commit-config.yaml")
  fi

  # --- robust in-place edit (portable across GNU/BSD sed) ---
  inplace_sed() {
    local f="$1" tmp
    tmp="${f}.tmp.$$"
    sed -e "s/<PYTHON_MINOR_VERSION>/${PY_MINOR_E}/g" \
        -e "s/<PROJECT_NAME>/${NAME_E}/g" \
        -e "s/<PROJECT_DESCRIPTION>/${DESC_E}/g" \
        "$f" > "$tmp"
    mv "$tmp" "$f"
  }

  # --- process each file ---
  for f in "${FILES[@]}"; do
    [[ -f "$f" ]] || { echo "Skip (not found): $f" >&2; continue; }
    inplace_sed "$f"
    # assert no placeholders remain
    if grep -Eq '<[A-Z_]+>' "$f"; then
      echo "ERROR: Placeholder(s) remain in $f" >&2
      return 1
    fi
    echo "Updated: $f"
  done

  echo "Done."
}

_main "$@"
