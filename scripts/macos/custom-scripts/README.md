This folder contains custon scripts to be run during creation of Ubuntu images.
All files will be copied to subfolder 'custom-scripts' of users $HOME folder.
All *.sh scripts will be executed by ../run_custom_scripts.sh in alphabet order.

If you need to run several scripts in particular order you may name them like  `00firstscript.sh`, `01secondscript.sh`
Scripts will not be removed after image creation. If you need to remove them (and all other files in `custom-scripts`) you may add next script and name it like `99rmscripts.sh`:
```
#!/bin/bash
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [[ -n "${WORK_DIR}" ]]; then
    rm -rf "${WORK_DIR}"
fi
```