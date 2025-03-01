Bolierplate template for a python project with UV and pre-commit linting

* To prep variables:
```bash
    SOURCE_DIR=$(pwd)
    UV_PROJECT_ENVIRONEMENT="${SOURCE_DIR?}/venv"
    UV_COMMAND="uv --project ${SOURCE_DIR?}"
    UV_SYNC_COMMAND="${UV_COMMAND?} sync --locked"
    UV_VENV_COMMAND="${UV_COMMAND?} venv --link-mode ${UV_LINK_MODE?} --relocatable"
```
* To create UV venv:
    * `${UV_VENV_COMMAND?} ${UV_PROJECT_ENVIRONMENT?}`
* To activate:
    * `source ${UV_PROJECT_ENVIRONMENT?}/bin/activate`
    * you MUST use SOURCE
* To sync: 
    * `$UV_SYNC_COMMAND?} --group dev --group notebook`
* To deactivate:
    * `deactivate`
