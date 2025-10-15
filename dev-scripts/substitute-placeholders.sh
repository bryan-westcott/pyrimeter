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


  # --- cuda version ---

  # Detect CUDA version from nvidia-smi (banner), or warn if unavailable
  if command -v nvidia-smi >/dev/null 2>&1; then
    CUDA_VERSION=$(nvidia-smi | grep -oE 'CUDA Version: [0-9.]+' | head -n1 | awk '{print $3}')
    if [ -n "$CUDA_VERSION" ]; then
      echo "CUDA_VERSION=${CUDA_VERSION}"
      IFS=. read -r CUDA_MAJOR_VERSION CUDA_MINOR_VERSION _ <<<"$CUDA_VERSION"
    else
      echo "WARNING: Could not parse CUDA Version from nvidia-smi banner."
    fi
  else
    echo "WARNING: nvidia-smi not found; cannot auto-detect CUDA version."
  fi

  # Prompt for CUDA major/minor, defaulting to detected values if present
  while :; do
    read -rp "CUDA_MAJOR_VERSION [${CUDA_MAJOR_VERSION:-}]: " _in
    CUDA_MAJOR_VERSION="${_in:-${CUDA_MAJOR_VERSION:-}}"
    [[ "$CUDA_MAJOR_VERSION" =~ ^[0-9]+$ ]] && break
    echo "Please enter a numeric major version (e.g., 12)."
  done

  while :; do
    read -rp "CUDA_MINOR_VERSION [${CUDA_MINOR_VERSION:-0}]: " _in
    CUDA_MINOR_VERSION="${_in:-${CUDA_MINOR_VERSION:-0}}"
    [[ "$CUDA_MINOR_VERSION" =~ ^[0-9]+$ ]] && break
    echo "Please enter a numeric minor version (e.g., 4)."
  done

echo "Using CUDA ${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}"
# Optionally export:
# export CUDA_MAJOR_VERSION CUDA_MINOR_VERSION
#
  # --- escape for sed ---
  escape() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
  local PY_MINOR_E NAME_E DESC_E CUDA_MAJOR_E CUDA_MINOR_E
  PY_MINOR_E=$(escape "$PY_MINOR")
  NAME_E=$(escape "$PROJECT_NAME")
  DESC_E=$(escape "$PROJECT_DESCRIPTION")
  CUDA_MAJOR_E=$(escape "$CUDA_MAJOR_VERSION")
  CUDA_MINOR_E=$(escape "$CUDA_MINOR_VERSION")

  # --- files to process (prefer args; else auto-detect base.*) ---

  # Note: will find all files with a base. prefix
  local -a FILES
  if (( "$#" > 0 )); then
    FILES=("$@")
  else
    shopt -s nullglob dotglob
    FILES=( base.* )
    shopt -u nullglob dotglob
  fi


  # --- out-of-place edit: read $src, write to $dst (src with ".base." removed) ---
  outplace_sed() {
    local src="$1" dst="$2" tmp
    tmp="${dst}.tmp.$$"
    sed -e "s/<PYTHON_MINOR_VERSION>/${PY_MINOR_E}/g" \
        -e "s/<PROJECT_NAME>/${NAME_E}/g" \
        -e "s/<PROJECT_DESCRIPTION>/${DESC_E}/g" \
        -e "s/<CUDA_MAJOR_VERSION>/${CUDA_MAJOR_E}/g" \
        -e "s/<CUDA_MINOR_VERSION>/${CUDA_MINOR_E}/g" \
        "$src" > "$tmp"
    # atomic changes
    mv "$tmp" "$dst"
  }

  # --- process each file ---
  for src in "${FILES[@]}"; do
    [[ -f "$src" ]] || { echo "Skip (not found): $src" >&2; continue; }
    # destination has no base. prefix
    dst="${src#base.}"
    outplace_sed "$src" "$dst"
    # assert no placeholders remain
    if grep -Eq '<[A-Z_]+>' "$dst"; then
      echo "ERROR: Placeholder(s) remain in $dst" >&2
      return 1
    fi
    echo "Updated: $src -> $dst"
  done

  # --- make a placeholder directory ---
  mkdir -p "src/${PROJECT_NAME}"
  placeholder_file="src/${PROJECT_NAME}/place_python_files_here.txt"
  touch "${placeholder_file}"
  echo "Created: ${placeholder_file}"

  echo "Done."
}

_main "$@"
