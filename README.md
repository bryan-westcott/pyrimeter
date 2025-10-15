Bolierplate template for a python project with UV and pre-commit linting

- Quick start:
  - run once: `./dev-scripts/initialize-pre-commit.sh`
  - fill in placeholders in pyproject.toml
  - source (not run): `source dev-scripts/dev-init.sh`
  - place modules in `src/<project_name>/`
  - launch jupyter and select project kernel

- To prep variables:

```bash
    SOURCE_DIR=$(pwd)
    UV_CACHE_DIR="$HOME/.cache/uv"
    UV_PROJECT_ENVIRONMENT="${SOURCE_DIR?}/venv"
    UV_SYNC_MODE="locked"
    UV_LINK_MODE="copy"

    UV_COMMAND="uv --project ${SOURCE_DIR?}"
    UV_SYNC_COMMAND="${UV_COMMAND?} sync --${UV_SYNC_MODE?}"
    # Note: UV venv will ignore UV_PROJECT_ENVIRONEMNT unless you explicitly add it to the end of UV_VENV_COMMAND
    UV_VENV_COMMAND="${UV_COMMAND?} venv --link-mode ${UV_LINK_MODE?} --relocatable ${UV_PROJECT_ENVIRONMENT?}"
```

- To create UV venv:
  - `${UV_VENV_COMMAND?} ${UV_PROJECT_ENVIRONMENT?}`
- To activate:
  - `source ${UV_PROJECT_ENVIRONMENT?}/bin/activate`
  - you MUST use SOURCE
- To sync:
  - `$UV_SYNC_COMMAND?} --group dev --group notebook`
- To deactivate:
  - `deactivate`
