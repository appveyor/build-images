#!/bin/bash -x


function build_vm() {
    MACOS_VER=$1
    OUT_DIR="./output-parallels-pvm"
    PACKER_CONFIG="$HOME/${MACOS_VER}-packer-config.json"
    PACKER_LOGS="$HOME/packer-logs"

    [ -d "${OUT_DIR}" ] && rm -rf "${OUT_DIR}"
    mkdir -p "${PACKER_LOGS}"

    if [[ -z "${DATEMARK-}" || "${#DATEMARK}" = "0" ]]; then DATEMARK=$(date +%Y%m%d%H%M%S); fi

    [ -f "${PACKER_CONFIG}" ] || { echo "File '${PACKER_CONFIG}' does not exist. Aborting"; return; }

    export PACKER_LOG_PATH="${PACKER_LOGS}/${MACOS_VER}-${DATEMARK}.log"
    PACKER_LOG=1 packer build --only=parallels-pvm "-var-file=${PACKER_CONFIG}" \
        -var "datemark=${DATEMARK}" \
        macos.json

    [ -d "${OUT_DIR}" ] && {
        mv -fv $OUT_DIR/packer-${MACOS_VER}-*.pvm "$HOME/Parallels/" &&
        prlctl register $HOME/Parallels/packer-${MACOS_VER}-*.pvm ||
            { echo "failed to copy PVM. Aborting"; exit 1; }
    }
}

#build_vm "catalina"
build_vm "mojave"
