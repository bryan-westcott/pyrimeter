#!/bin/bash
#------------------------------------------------------------------------------
# update-pre-commit-versions.sh
#
# Purpose
#   Update the `rev:` pin for a given tool's repository in `.pre-commit-config.yaml`
#   using the version discovered in `pyproject.toml`. It looks in two places:
#     1) As a requirement-style version (e.g., in `[project.dependencies]`
#        or similar), extracting the numeric version for the given tool name.
#     2) In a tool-specific section, e.g. `[tool.<name>]`, reading a `version = "..."`
#        line.
#
# How it works (high-level)
#   - Reads the current working directory as the repo root.
#   - Greps `pyproject.toml` for a version that matches the provided tool name.
#   - If not found in requirement-style entries, looks under `[tool.<name>]` for a
#     `version = ...` line.
#   - Constructs a regex for the tool's repo URL pattern expected in pre-commit
#     (default pattern is `.<tool>.*`, which matches URLs containing `.<tool>`)
#   - Uses `sed` to locate the matching `repo:` entry and then update the following
#     `rev:` line to the discovered version, preserving an optional leading `v`.
#
# Assumptions / Expectations
#   - `.pre-commit-config.yaml` has entries like:
#         - repo: <something ending in .<tool>...>
#           rev: vX.Y.Z
#     and that `rev:` is on the *next* line after the `repo:` line.
#   - The repo URL match pattern is deliberately broad: `.<tool>.*`
#     (e.g., matches `https://github.com/psf/black` when tool is `black` because
#     of `.black` in the path). Adjust if your repos use different naming.
#   - `pyproject.toml` contains either:
#       - a requirement-like spec including `<tool>` and a bare numeric version, or
#       - a `[tool.<tool>]` table with a `version = "X.Y.Z"` entry.
#
# Requirements
#   - GNU grep with PCRE support (uses `-P` and `-z`).
#   - sed with in-place editing (`-i`).
#   - tr, sed, grep standard behavior assumed on Linux/macOS.
#
# Usage
#   ./update-pre-commit-versions.sh <tool_name>
#
#   Examples:
#     ./update-pre-commit-versions.sh black
#     ./update-pre-commit-versions.sh ruff
#
# Exit codes
#   - Relies on `${1?}` to ensure a tool name is provided (shell will error if not).
#   - `sed` will quietly do nothing if it cannot find a matching `repo:` line
#     followed by a `rev:` line; inspect the final echo for the detected version.
#
# Caveats / Limitations
#   - If multiple `repo:` entries match `.<tool>.*`, sed will update the first match.
#   - If your `.pre-commit-config.yaml` is structured differently (e.g., `rev:` not
#     immediately after `repo:`), the update won’t occur.
#   - If versions in `pyproject.toml` are specified with complex constraints (e.g.,
#     `>=`, `~=`, extras), only the bare numeric version is extracted.
#   - BSD/macOS `sed -i` syntax differs when providing a backup suffix; this script
#     uses GNU-style `-i` without a suffix.
#
#------------------------------------------------------------------------------

update_pre_commit_versions() {
    # Treat the current working directory as the repo root
    root_dir=$(pwd)
    local pyproject_toml_path="${root_dir?}/pyproject.toml"
    local pre_commit_config_yaml_path="${root_dir?}/.pre-commit-config.yaml"

    # Required parameter: tool name (e.g., "ruff")
    local tool_name=${1?}

    # Pattern used to identify the target repo line in pre-commit config:
    # We expect something like: "repo: ...<something>.<tool_name>..."
    # The leading dot ensures we don't over-match short substrings (heuristic).
    local repo_url=".${tool_name?}.*"

    # ------------------------------------------------------------
    # 1) Try to extract a version from requirement-like entries in pyproject.toml
    #    Example matched text:  '"black" == "23.12.1",'  -> extract 23.12.1
    #    We:
    #      - first grep the dependency lines that include the tool and a version operator
    #      - then extract the version number itself (numbers and dots)
    # ------------------------------------------------------------
    version_requirements=$(
        grep -Eo "\s*\"?${tool_name?}\"?\s*(=|<|>)*=\s*\"?[0-9]+(\.[0-9]+)*\"?,?" ${pyproject_toml_path?} \
        | grep -Eo "[0-9]+(\.[0-9]+)*"
    )

    # ------------------------------------------------------------
    # 2) Also look for a tool section like:
    #       [tool.<tool_name>]
    #       version = "X.Y.Z"
    #    We:
    #      - grep from the section header up to (but not including) the next '['
    #      - find the `version =` line and extract the right-hand side sans quotes
    # ------------------------------------------------------------
    version_section=$(
        grep -Pzo "\[tool\.${tool_name?}\][^\[]*\n\s*version\s*=\s*\K[^\n]+" ${pyproject_toml_path?} \
        | tr -d '\0' \
        | sed 's/[\"'\'']//g'
    )

    # Prefer requirement-derived version; fall back to [tool.<name>] version
    version="${version_requirements:-$version_section}"

    # Escape slashes for sed; we inject the repo pattern into a sed script
    repo_url_escaped=${repo_url//\//\\/}

    # ------------------------------------------------------------
    # 3) Update `.pre-commit-config.yaml`:
    #    - Find the line that matches `repo:\s*.<tool>.*`
    #    - On the *next* line, replace `rev:` with the discovered version,
    #      preserving an optional existing leading 'v' (with `\(v\?\)`).
    #
    #    sed script breakdown:
    #      /repo:\s*${repo_url_escaped}.*/   -> match the target repo line
    #      !b                                 -> if not matched, branch to end (no-op)
    #      n                                  -> move to the next line (expected `rev:`)
    #      s/rev:\s\+\(v\?\).*/rev: \1${version}/ -> substitute rev, keep optional 'v'
    # ------------------------------------------------------------
    sed -i "/repo:\s*${repo_url_escaped?}.*/!b;n;s/rev:\s\+\(v\?\).*/rev: \1${version?}/" "${pre_commit_config_yaml_path?}"

    # Final status echo for visibility
    echo "tool=${tool_name}, repo_url=${repo_url}, version:(used=${version}, requirements=${version_requirements}, section=${version_section})"
}

# ------------------------------------------------------------------------------
# Entry point
#   If the script file is executed directly, run the updater with the first arg.
#   If it's sourced, do nothing (function is then available in the shell).
# ------------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    update_pre_commit_versions ${1?} ${2}
fi
