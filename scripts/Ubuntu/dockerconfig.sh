#!/bin/bash -eu
#shellcheck disable=SC2086,SC2015,SC2164
DEBUG=false

USER_NAME=appveyor
DATEMARK=$(date +%Y%m%d%H%M%S)
AGENT_DIR=/opt/appveyor/build-agent
AGENT_VERSION=7.0.2326
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGGING=false

# shellcheck source=./common.sh
. "${WORK_DIR}/common.sh" ||
        { echo "[ERROR] Cannot source common.sh script. Aborting." 1>&2; exit 2; }

function _abort() {
    echo "Aborting." 1>&2
    exit "$1"
}

function _continue() {
    echo "Continue installation..." 1>&2
}

copy_appveyoragent ||
     _abort $?