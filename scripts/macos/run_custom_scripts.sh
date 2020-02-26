#!/bin/bash

echo "[INFO] Running custom scripts:"

if [ -d "./custom-scripts" ] && stat ./custom-scripts/*.sh >/dev/null 2>&1; then
    for CUSTOM_SCRIPT in $(ls ./custom-scripts/*.sh); do
        echo "Running script $CUSTOM_SCRIPT:"
        bash "${CUSTOM_SCRIPT}"
    done
else
    echo "[INFO] No custom-scripts found."
fi

if [ -d "./custom-scripts" ]; then
    echo "[INFO] Cleanup custom-scripts folder."
    rm -rf "./custom-scripts"
fi