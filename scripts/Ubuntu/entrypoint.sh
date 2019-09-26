#!/bin/bash -eu

if [ -d /appveyor/temp ]; then
    sudo chown -R $(id -u):$(id -g) /appveyor/temp
fi

if [ -d /appveyor/bin ]; then
    sudo chown -R $(id -u):$(id -g) /appveyor/bin
fi

if [[ -n "${APPVEYOR_BUILD_AGENT_PROJECTS_BUILDS_PATH-}" && "${#APPVEYOR_BUILD_AGENT_PROJECTS_BUILDS_PATH}" -gt "0" ]]; then
    sudo chown -R $(id -u):$(id -g) ${APPVEYOR_BUILD_AGENT_PROJECTS_BUILDS_PATH}
fi

# execute build agent
/opt/appveyor/build-agent/appveyor-build-agent