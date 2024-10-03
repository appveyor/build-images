#!/bin/bash

function build_vm() {
    MACOS_VER=$1
    PACKER_BUILDER=$2
    OUT_DIR="./output-parallels-pvm"
    BUILD_AGENT_MODE="Parallels"
    PACKER_CONFIG="$HOME/packer-config.json"
    PACKER_LOGS="$HOME/packer-logs"
    IMAGES_DIR="$HOME/Parallels"

    if [[ -z "${DATEMARK-}" || "${#DATEMARK}" = "0" ]]; then DATEMARK=$(date +%Y-%m-%d-%H%M%S); fi

    if [[ "${PACKER_BUILDER}" = "" ]]; then
        PACKER_BUILDER="parallels-pvm"
    fi

    if [[ "${PACKER_BUILDER}" = "vmware-vmx" ]]; then
        IMAGES_DIR="$HOME/appveyor-images"
        OUT_DIR="${IMAGES_DIR}/macos-${MACOS_VER}-${DATEMARK}"
        BUILD_AGENT_MODE="VMware"
    fi

    [ -d "${OUT_DIR}" ] && rm -rf "${OUT_DIR}"
    mkdir -p "${PACKER_LOGS}"

    [ -f "${PACKER_CONFIG}" ] || { echo "File '${PACKER_CONFIG}' does not exist. Aborting"; return; }

    export PACKER_LOG_PATH="${PACKER_LOGS}/${MACOS_VER}-${DATEMARK}.log"
    PACKER_LOG=1 packer build --only=${PACKER_BUILDER} "-var-file=${PACKER_CONFIG}" \
        -var "macos_version=${MACOS_VER}" \
        -var "datemark=${DATEMARK}" \
        -var "images_directory=${IMAGES_DIR}" \
        -var "output_directory=${OUT_DIR}" \
        -var "build_agent_mode=${BUILD_AGENT_MODE}" \
        -var "fastlaneSession=${FASTLANE_SESSION}" \
        macos.json

    if [[ "${PACKER_BUILDER}" = "parallels-pvm" ]]; then
        [ -d "${OUT_DIR}" ] && {
            mv -fv $OUT_DIR/packer-${MACOS_VER}-*.macvm "$HOME/Parallels/" &&
            prlctl register $HOME/Parallels/packer-${MACOS_VER}-*.macvm ||
                { echo "failed to copy PVM. Aborting"; exit 1; }
        }
    fi
}

if [ -z "$1" ]; then
    echo "No macOS codename provided"
    exit 1
fi

if [ -z "$FASTLANE_SESSION" ]; then
    echo "FASTLANE_SESSION variable is not set"
    exit 1
fi

#build_vm "catalina"
#build_vm "mojave" "parallels-pvm"
build_vm "$1"
