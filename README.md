# pyproj-template

A modern Python project starter template featuring robust linting, pre-commit automation, and uv-based tooling.

## Quick start:

1. ## **Initialize pre-commit** (idempotent):
   ```bash
   ./dev-scripts/initialize-pre-commit.sh
   ```
2. ## **Activate the development environment** (_source don't run_)

   ```bash
   source dev-scripts/dev-init.sh
   ```

   - Creates the virtual environment (venv), if needed
   - Synchronized dependencies (safely)
   - Registers the environment as a jupyter kernel
   - Activates the environment

3. ## **Populate from templates**

   ```bash
   ./dev-scripts/substitute-placeholders.sh
   ```

   - Generates `pyroject.toml` and `.pre-commit-config.yaml`
   - Sets consistent python version throughout
   - Recommends and configures Torch repositories based on detected CUDA version

4. ## **Place modules under:\***
   ```bash
   src/<project_name>
   ```
5. ## **Launch jupyter and select the kernel**

   ```bash
   uv run jupyter lab
   ```

   - will have the same name as the project

## Helper Utils:

- ## safe synchronization:
  ```bash
  dev-scripts/safe-sync.sh
  ```

## Pre-commit linters included:

- **Ruff** -- Fast Python linter (replacement for flake8/pylint) and formatter (ruff format).
- **MyPy** -- Static type checker for Python code using type hints.
- **Hadolint** -- Dockerfile checker.
- **Prettier** -- Formatter for JSON, Markdown, YAML, and other text-based formats.
- **Docformatter** -- Reformats Python docstrings to follow standard width and style.
- **ShellCheck** -- Static analyzer for Bash and shell scripts.
- **Yamlfmt** -- Strict YAML formatter.
- **Yamllint** -- Linter for YAML syntax and structure.
- **Action-Validator** -- Validator and linter for GitHub Actions workflow files.
- **Latex** -- Common latex checks.
- **Taplo** -- Formatter and validator for TOML files (e.g. pyproject.toml).
- **Aspell** -- Spell checker using local dictionaries.
- **Proselint** -- Prose linter for English grammar, clarity, and style issues.
- **Latexmk** -- Builds LaTeX projects automatically and runs bibliography compilation (biber).
- **Pandoc** -- Converts Markdown documents to PDF and other output formats (when template exists)

## Additional features

- Single-source of truth (pyproject.toml) for linter versions
  - supports synchronization on CI/CD like GitHub actions
  - pre-commit will self-check its versions
- Sane default config for tools
- Tooling, test and notebook support built into `pyproject.toml`

## License

Apache 2.0, see LICENSE and NOTICE
