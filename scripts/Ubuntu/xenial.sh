#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

function add_releasespecific_tools() {
    # 32bit support
    tools_array+=( "libcurl3:i386" "libcurl3-gnutls-dev" )
    # HWE kernel
    tools_array+=( "linux-generic-hwe-16.04" )
}

function configure_mongodb_repo() {
    echo "[INFO] Running configure_mongodb_repo for Xenial..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add - &&
    add-apt-repository "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu ${OS_CODENAME}/mongodb-org/4.2 multiverse" ||
        { echo "[ERROR] Cannot add mongodb repository to APT sources." 1>&2; return 10; }
}

function install_doxygen() {
    echo "[INFO] Running ${FUNCNAME[0]}..."
    install_doxygen_version '1.8.20' 'https://appveyordownloads.blob.core.windows.net/misc'
}

function install_clang() {
    echo "[INFO] Running install_clang for Xenial..."
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

    install_clang_version 9
    install_clang_version 10
    install_clang_version 11
    install_clang_version 12

    # make clang 10 default
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-10 1000
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-10 1000
    update-alternatives --config clang
    update-alternatives --config clang++

    log_version clang --version
}