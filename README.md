# Pyrimeter

Guard rails for code (human or AI)

## Overview

**Pyrimeter** defines the boundary between acceptable and unacceptable code.
It currently ships as a modern Python project template with robust linting, pre-commit automation, and uv-based tooling.
Its longer-term vision is to act as a protective perimeter around codebases, providing automated checks and policy enforcement for both human-written and generative-AI-produced code, especially local, on-prem tools.

In practical terms, Pyrimeter provides a ready-to-use Python project layout with a curated set of linters, formatters, and checks wired together through pre-commit hooks (for local development) and GitHub Actions (for pull requests). Once the placeholder substitution scripts are run, the project is immediately usable, with all tool versions and configuration defined in a single source of truth, ensuring consistent and enforceable code quality checks.

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

## GitHub Actions features

- Primary workflow for pull request: `.github/workflows/pr.yaml`
  - calls all reusable workflows
  - dynamically determines which steps are needed to save Github Actions minutes
  - designed to work with a dispatch call
- Reusable workflows:
  - run all code quality checks (same as pre-commit): `.github/workflow/all-code-tests.yaml`
  - run PyTest tests (currently just `smoke` test): `.github/workflows/all-pytest-tests.yaml`
- Actions:
  - same as those for pre-commit hook, with care to match versions and arguments

## Additional features

- Single-source of truth (pyproject.toml) for linter versions
  - supports synchronization on CI/CD like GitHub actions
  - pre-commit will self-check its versions
- Sane default config for tools
- Tooling, test and notebook support built into `pyproject.toml`

## Quick start:

0. ## **Download Pyrimeter**

   ```bash
   mkdir -p ~/Projects/my-new-project && cd ~/Projects/my-new-project
   curl -fL "https://github.com/bryan-westcott/pyrimeter/archive/refs/heads/main.tar.gz" \
       | tar -xzf - --strip-components=1
   ```

   - Note: It is better to curl, if you clone you will have Pyrimeter (and license) in your git history

1. ## **Populate from templates (just once)**

   ```bash
   ./template-scripts/substitute-placeholders.sh
   ```

   - Generates `pyroject.toml` and `.pre-commit-config.yaml`
   - Sets consistent python version throughout
   - Recommends and configures Torch repositories based on detected CUDA version

2. ## **Initialize pre-commit** (idempotent):
   ```bash
   ./dev-scripts/initialize-pre-commit.sh
   ```
3. ## **Activate the development environment** (_source don't run_)

   ```bash
   source dev-scripts/dev-init.sh
   ```

   - Creates the virtual environment (venv), if needed
   - Synchronized dependencies (safely)
   - Registers the environment as a jupyter kernel
   - Activates the environment

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

- ### safe synchronization (prep and sync environment as needed):
  ```bash
  dev-scripts/safe-sync.sh
  ```
- ### spell check failure (re-check and add to dictionary):
  ```bash
  dev-scripts/spell-checkfile.sh <file-to-check>
  git add <file-to-check> .aspell*
  ```

## License

Apache 2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE)
