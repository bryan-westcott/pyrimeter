# CLAUDE.md — <PROJECT_NAME>

## Package management

- Uses **uv** (not pip, poetry, or conda)
- `pyproject.toml` is the single source of truth for all dependencies and tool versions
- Sync environment: `dev-scripts/safe-sync.sh`
- Activate environment: `source dev-scripts/dev-init.sh` (must be **sourced**, not executed)
- Add dependencies to the appropriate group in `pyproject.toml`, then run `dev-scripts/safe-sync.sh`
- **Do not run `uv sync` directly** — it is denied in `.claude/settings.json`.
  `safe-sync.sh` auto-detects dependency groups (notebook, tooling, test) and
  passes the correct flags; raw `uv sync` will miss them

## Project layout

- Source code: `src/<PROJECT_NAME>/`
- Tests: `src/<PROJECT_NAME>/tests/`
- Dev scripts: `dev-scripts/`

## Linting and formatting

- Pre-commit hooks run automatically on `git commit`
- To run all checks manually: `pre-commit run -a`
- Tools and their configs (all in `pyproject.toml` unless noted):
  - **Ruff** — Python linting (`ruff check`) and formatting (`ruff format`), line-length 120
  - **MyPy** — static type checking on `src/`
  - **Prettier** — Markdown, JSON formatting
  - **Docformatter** — Python docstring formatting
  - **ShellCheck** — Bash/shell script linting
  - **Hadolint** — Dockerfile linting
  - **Yamlfmt** / **Yamllint** — YAML formatting and linting (config in `.yamllint`)
  - **Taplo** — TOML formatting
  - **Aspell** — spell checking (dictionary in `.aspell.en.pws`)
  - **Proselint** — prose/grammar linting (config in `.proselintrc.json`)
- Tool versions in `.pre-commit-config.yaml` are auto-synced from `pyproject.toml`

## Testing

- Framework: **pytest**
- Run smoke tests: `uv run pytest -m smoke`
- Run all tests: `uv run pytest`
- The `smoke` marker is required at minimum — fast tests that run on CPU
- Test config is in `[tool.pytest.ini_options]` in `pyproject.toml`

## CI/CD

- PR workflow: `.github/workflows/pr.yaml`
- Runs code quality checks then pytest
- Actions dynamically skip steps when relevant files haven't changed

## Common commands

```bash
source dev-scripts/dev-init.sh        # activate environment
dev-scripts/safe-sync.sh              # sync environment (detects groups/extras)
pre-commit run -a                     # run all linters
uv run pytest -m smoke                # run smoke tests
uv run jupyter lab                    # launch Jupyter (kernel matches project name)
dev-scripts/spell-check-file.sh FILE  # interactive spell check
```
