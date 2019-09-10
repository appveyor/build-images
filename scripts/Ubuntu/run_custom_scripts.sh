#!/bin/bash

echo "Running custom scripts:"

if [ -d "./custom-scripts" ]; then
    for CUSTOM_SCRIPT in $(ls ./custom-scripts/*.sh); do
        echo "Running script $CUSTOM_SCRIPT:"
        bash "${CUSTOM_SCRIPT}"
    done
fi