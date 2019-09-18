#!/bin/bash -eu

if [ -d /appveyor/temp ]; then
    sudo chown -R $(id -u):$(id -g) /appveyor/temp
fi

if [ -d /appveyor/bin ]; then
    sudo chown -R $(id -u):$(id -g) /appveyor/bin
fi

if [[ ! -z "${APPVEYOR_BUILD_FOLDER-}" ]]; then
    sudo chown -R $(id -u):$(id -g) ${APPVEYOR_BUILD_FOLDER}
fi

# execute build agent
/opt/appveyor/build-agent/appveyor-build-agent