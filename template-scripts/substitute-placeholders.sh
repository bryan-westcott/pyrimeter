#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check for existing .git repo and pyrimeter history
source "${SCRIPT_DIR}/template-guard.sh"
pyrimeter_template_guard

_main() {
  # Avoid polluting shell history
  set +o history

  # Snapshot current opts & cwd; harden during run
  local __orig_pwd __orig_opts
  __orig_pwd="$PWD"
  __orig_opts="$(set +o)"
  set -euo pipefail
  trap 'eval "$__orig_opts"; cd "$__orig_pwd" || true; set +o history; trap - RETURN' RETURN

  # Work from project root (parent of script directory)
  cd "$REPO_ROOT" || { echo "Cannot cd to REPO_ROOT=$REPO_ROOT" >&2; return 1; }

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
    echo "Please enter a numeric minor version (e.g., 6)."
  done

  echo "Using CUDA ${CUDA_MAJOR_VERSION}.${CUDA_MINOR_VERSION}"
  # Optionally export:
  # export CUDA_MAJOR_VERSION CUDA_MINOR_VERSION

  # Copyright holder
  GIT_USER_NAME="$(git config --get user.name || true)"
  while true; do
    read -r -p "Enter copyright holder name [${GIT_USER_NAME}]: " COPYRIGHT_HOLDER_NAME
    COPYRIGHT_HOLDER_NAME="${COPYRIGHT_HOLDER_NAME:-$GIT_USER_NAME}"
    if [[ -n "$COPYRIGHT_HOLDER_NAME" ]]; then
      break
    fi
    echo "Error: copyright holder name cannot be empty."
  done

  # Copyright year
  CURRENT_YEAR="$(date +%Y)"
  while true; do
    read -r -p "Enter copyright year [${CURRENT_YEAR}]: " COPYRIGHT_YEAR
    COPYRIGHT_YEAR="${COPYRIGHT_YEAR:-$CURRENT_YEAR}"
    if [[ "$COPYRIGHT_YEAR" =~ ^[0-9]{4}$ ]]; then
      break
    fi
    echo "Error: copyright year must be a 4-digit year."
  done

  CODEOWNER_SUGGESTION="$(git config --get github.user || true)"
  while true; do
    read -r -p "Enter CODEOWNER_USERNAME (GitHub username NOT legal name) [${CODEOWNER_SUGGESTION}]: " CODEOWNER_USERNAME
    CODEOWNER_USERNAME="${CODEOWNER_USERNAME:-$CODEOWNER_SUGGESTION}"

    if [[ -z "$CODEOWNER_USERNAME" ]]; then
      echo "Error: CODEOWNER_USERNAME cannot be empty."
      continue
    fi

    if [[ "$CODEOWNER_USERNAME" =~ [[:space:]] ]]; then
      echo "Error: CODEOWNER_USER must not contain spaces."
      continue
    fi

    break
  done

  while true; do
    read -r -p "Is this project open source? [y/N]: " _os
    case "${_os,,}" in
      y|yes)
        IS_OPEN_SOURCE=yes
        break
        ;;
      n|no|"")
        IS_OPEN_SOURCE=no
        break
        ;;
      *)
        echo "Please answer yes or no."
        ;;
    esac
  done

  if [[ "$IS_OPEN_SOURCE" == "yes" ]]; then
    DEFAULT_LICENSE="Apache-2.0"
    read -r -p "License name [${DEFAULT_LICENSE}]: " LICENSE_NAME
    LICENSE_NAME="${LICENSE_NAME:-$DEFAULT_LICENSE}"
  else
    LICENSE_NAME="Proprietary"
  fi

  # canonicalize license name casing without destroying
  LICENSE_CANON="${LICENSE_NAME}"
  [[ "${LICENSE_CANON,,}" == "apache-2.0" ]] && LICENSE_CANON="Apache-2.0"

  if [[ "$LICENSE_CANON" == "Apache-2.0" ]]; then
    LICENSE_FULL_NAME="the Apache License, Version 2.0"
    LICENSE_URI="http://www.apache.org/licenses/LICENSE-2.0"

  elif [[ "$LICENSE_NAME" == "Proprietary" ]]; then
    LICENSE_FULL_NAME="a Proprietary License"
    LICENSE_URI="file:LICENSE"

  else
    # Prompt for full license name
    while true; do
      read -r -p "Enter full license name (e.g., \"MIT License\"): " LICENSE_FULL_NAME
      [[ -n "$LICENSE_FULL_NAME" ]] && break
      echo "License full name cannot be empty."
    done

    # Prompt for license URI
    while true; do
      read -r -p "Enter license URI (URL or file: path): " LICENSE_URI
      [[ -n "$LICENSE_URI" ]] && break
      echo "License URI cannot be empty."
    done
  fi

  while true; do
    read -r -p "Use standard Contributor License Agreement (CLA)? [y/N]: " _cla
    case "${_cla,,}" in
      y|yes)
        USE_STANDARD_CLA="yes"
        break
        ;;
      n|no|"")
        USE_STANDARD_CLA="no"
        break
        ;;
      *)
        echo "Please answer yes or no."
        ;;
    esac
  done

  # --- escape for sed ---
  # Use | not / for sed escaping
  escape() { printf '%s' "$1" | sed -e 's/[|&\\]/\\&/g'; }
  local PY_MINOR_E NAME_E DESC_E CUDA_MAJOR_E CUDA_MINOR_E
  PY_MINOR_E=$(escape "$PY_MINOR")
  NAME_E=$(escape "$PROJECT_NAME")
  DESC_E=$(escape "$PROJECT_DESCRIPTION")
  CUDA_MAJOR_E=$(escape "$CUDA_MAJOR_VERSION")
  CUDA_MINOR_E=$(escape "$CUDA_MINOR_VERSION")
  COPYRIGHT_HOLDER_NAME_E=$(escape "$COPYRIGHT_HOLDER_NAME")
  COPYRIGHT_YEAR_E=$(escape "$COPYRIGHT_YEAR")
  CODEOWNER_USERNAME_E=$(escape "$CODEOWNER_USERNAME")
  LICENSE_NAME_E=$(escape "$LICENSE_NAME")
  LICENSE_FULL_NAME_E=$(escape "$LICENSE_FULL_NAME")
  LICENSE_URI_E=$(escape "$LICENSE_URI")

  # --- files to process (prefer args; else auto-detect base.*) ---

  # Note: will find all files with a base. prefix
  local -a FILES
  if (( "$#" > 0 )); then
    FILES=("$@")
  else
    shopt -s nullglob dotglob
    FILES=( "${REPO_ROOT}/templates/base."* )
    shopt -u nullglob dotglob
  fi


  # --- out-of-place edit: read $src, write to $dst (src with ".base." removed) ---
  outplace_sed() {
    local src="$1" dst="$2" tmp
    tmp="${dst}.tmp.$$"
    sed -e "s|<PYTHON_MINOR_VERSION>|${PY_MINOR_E}|g" \
        -e "s|<PROJECT_NAME>|${NAME_E}|g" \
        -e "s|<PROJECT_DESCRIPTION>|${DESC_E}|g" \
        -e "s|<CUDA_MAJOR_VERSION>|${CUDA_MAJOR_E}|g" \
        -e "s|<CUDA_MINOR_VERSION>|${CUDA_MINOR_E}|g" \
        -e "s|<COPYRIGHT_HOLDER_NAME>|${COPYRIGHT_HOLDER_NAME_E}|g" \
        -e "s|<COPYRIGHT_YEAR>|${COPYRIGHT_YEAR_E}|g" \
        -e "s|<CODEOWNER_USERNAME>|${CODEOWNER_USERNAME_E}|g" \
        -e "s|<LICENSE_NAME>|${LICENSE_NAME_E}|g" \
        -e "s|<LICENSE_FULL_NAME>|${LICENSE_FULL_NAME_E}|g" \
        -e "s|<LICENSE_URI>|${LICENSE_URI_E}|g" \
        "$src" > "$tmp"
    # atomic changes
    mv "$tmp" "$dst"
  }

  # --- process each file ---
  for src in "${FILES[@]}"; do
    [[ -f "$src" ]] || { echo "Skip (not found): $src" >&2; continue; }
    file=$(basename "$src")
    name="${file#base.}"
    case "$name" in
      # Special-case: pre-commit config gets a leading dot
      pre-commit-config.yaml)
        dst="${REPO_ROOT}/.pre-commit-config.yaml"
        ;;
      # Special-case: gitignore gets a leading dot
      gitignore)
        dst="${REPO_ROOT}/.gitignore"
        ;;
      CODEOWNERS)
        # Special-case: CODEOWNERS goes in .github
        mkdir -p "${REPO_ROOT}/.github"
        dst="${REPO_ROOT}/.github/CODEOWNERS"
        ;;
      *)
        # Others: just strip base. prefix and put in project root
        dst="${REPO_ROOT}/${name}"
        ;;
    esac
    outplace_sed "$src" "$dst"
    # assert no placeholders remain
    if grep -Eq '<[A-Z_]+>' "$dst"; then
      echo "ERROR: Placeholder(s) remain in $dst" >&2
      return 1
    fi

    # WE NEED AN ACTUAL .pre-commit-config FOR PROJECT TO LINT ITSELF!
    # Pre-commit hooks supporting python, docker and latex
    echo "Updated: $src -> $dst"
  done

  # Special handling

  # substitute standard CLA, if desired
  if [[ "$USE_STANDARD_CLA" == "yes" ]]; then
    cp -f "${REPO_ROOT}/templates/standard.CLA" "${REPO_ROOT}/CLA"
  fi

  if [[ "$LICENSE_CANON" == "Apache-2.0" ]]; then
    cp -f "${REPO_ROOT}/templates/apache2.LICENSE_TEXT" "${REPO_ROOT}/LICENSE"
  fi

  # --- make a placeholder directory ---
  mkdir -p "src/${PROJECT_NAME}"
  placeholder_file="src/${PROJECT_NAME}/place_python_files_here.txt"
  touch "${placeholder_file}"
  echo "Created: ${placeholder_file}"

  echo "Done."

  ${SCRIPT_DIR}/find-insert-todos.sh
}

_main "$@"
