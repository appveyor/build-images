#!/bin/bash -x


function build_vm() {
    MACOS_VER=$1
    [ -d "./output-parallels-pvm" ] && rm -rf "./output-parallels-pvm"
    if [[ -z "${DATEMARK-}" || "${#DATEMARK}" = "0" ]]; then DATEMARK=$(date +%Y%m%d%H%M%S); fi

    [ -f "${MACOS_VER}.json" ] || { echo "File '${MACOS_VER}.json' does not exist. Aborting"; return; }
    export PACKER_LOG_PATH=${MACOS_VER}-${DATEMARK}.log
    PACKER_LOG=1 packer build --only=parallels-pvm "-var-file=${MACOS_VER}.json" \
        -var "datemark=${DATEMARK}" \
        macos.json
    [ -d "./output-parallels-pvm" ] && {
        mv -fv ./output-parallels-pvm/packer-${MACOS_VER}-*.pvm "$HOME/Parallels/" &&
        prlctl register $HOME/Parallels/packer-${MACOS_VER}-*.pvm ||
            { echo "failed to copy PVM. Aborting"; exit 1; }
    }
}

build_vm "catalina"
build_vm "mojave"
