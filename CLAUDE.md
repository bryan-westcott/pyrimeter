# CLAUDE.md — Pyrimeter Template Project

> **This file is only applicable to the Pyrimeter template repository itself
> (bryan-westcott/pyrimeter). It does NOT apply to projects created from this
> template. Downstream projects receive their own CLAUDE.md via the template
> substitution process.**

## What this project is

Pyrimeter is a **Python project template**, not a library or application. It
ships placeholder files that get customized when a user sets up a new project.
Do not treat the source under `src/pyproj_template_placeholder/` as production
code — it is scaffolding that gets renamed and substituted.

## Critical: download, never clone

Pyrimeter must be **downloaded via curl/tarball**, never cloned with `git clone`.
Cloning carries Pyrimeter's git history (including its Apache 2.0 license) into
the new project, which is almost never desired. The template guard
(`template-scripts/template-guard.sh`) will refuse to run if it detects
Pyrimeter history in `.git`.

Correct download command:

```bash
my_new_project_dir="${HOME}/Projects/my-new-project" && \
mkdir -p "${my_new_project_dir}" && \
cd "${my_new_project_dir}" && \
set -o pipefail && \
curl -fL "https://github.com/bryan-westcott/pyrimeter/archive/refs/heads/main.tar.gz" \
  | tar -xzf - --strip-components=1 --keep-old-files
```

## Template system

- Template files live in `templates/base.*` and use `<PLACEHOLDER>` syntax
  (e.g. `<PROJECT_NAME>`, `<PYTHON_MINOR_VERSION>`, `<CUDA_MAJOR_VERSION>`)
- `template-scripts/substitute-placeholders.sh` reads these templates,
  prompts the user for values, substitutes placeholders, and writes the
  output to the project root (stripping the `base.` prefix)
- The script also renames `src/pyproj_template_placeholder/` to
  `src/${PROJECT_NAME}/` and substitutes placeholders in its `.py` files
- After substitution, `template-scripts/find-insert-todos.sh` scans for any
  remaining `TODO: Insert` markers that need manual attention

## Package management

- Uses **uv** (not pip, poetry, or conda)
- `pyproject.toml` is the single source of truth for dependencies and tool versions
- `dev-scripts/safe-sync.sh` handles `uv sync` with the right groups/extras
- `dev-scripts/dev-init.sh` must be **sourced** (not executed) to activate the environment

## Linting and formatting

- Pre-commit hooks are defined in `.pre-commit-config.yaml`
- Tools: ruff (lint + format), mypy, prettier, docformatter, shellcheck,
  hadolint, yamlfmt, yamllint, taplo, aspell, proselint, action-validator
- Tool versions in `.pre-commit-config.yaml` are synchronized from
  `pyproject.toml` via local pre-commit hooks that run
  `dev-scripts/update-pre-commit-versions-from-pyproject-toml.sh`

## CI/CD

- `.github/workflows/pr.yaml` is the main workflow (PR, push to ci-cd, dispatch)
- It calls reusable workflows: `all-code-checks.yaml` and `all-pytest-tests.yaml`
- Custom actions under `.github/actions/` wrap each linter with smart skip logic

## Testing

- pytest with markers — `smoke` is the minimum required marker
- Tests live under `src/<project_name>/tests/`
- Run with: `uv run pytest -m smoke`

## Shell scripts

- All scripts use `set -euo pipefail` and proper trap handling
- `dev-scripts/initialize-pre-commit.sh` installs system dependencies (uses sudo)
- Scripts are designed to be idempotent where possible
