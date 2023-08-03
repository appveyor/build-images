#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

function add_releasespecific_tools() {
    if [[ $OS_ARCH == "amd64" ]]; then
        # doxygen support
        tools_array+=( "libclang1-14" )
        # 32bit support
        tools_array+=( "libcurl4:i386" "libcurl4-gnutls-dev" )
        # HWE kernel
        tools_array+=( "linux-generic-hwe-22.04" )
    fi    
}

function configure_mercurial_repository() {
    echo "[INFO] Running configure_mercurial_repository on Ubuntu 22.04...skipped"
}

function prepare_dotnet_packages() {
    SDK_VERSIONS=("6.0" "7.0" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]
}

function install_outdated_dotnets() {
    echo "[INFO] Running install_outdated_dotnets on Ubuntu 22.04...skipped"
}

function configure_firefox_repository() {
    echo "[INFO] Running configure_firefox_repository on Ubuntu 22.04..."
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6DCF7707EBC211F
    add-apt-repository "deb [ arch=amd64 ] http://ppa.launchpad.net/ubuntu-mozilla-security/ppa/ubuntu jammy main"
    apt-get -y update
}

function install_jdks_from_repository() {
    echo "[INFO] Running install_jdks_from_repository..."
    add-apt-repository -y ppa:openjdk-r/ppa
    apt-get -y -qq update && {
        apt-get -y -q install --no-install-recommends openjdk-8-jdk
    } ||
        { echo "[ERROR] Cannot install JDKs." 1>&2; return 10; }
    update-java-alternatives --set java-1.8.0-openjdk-amd64

    # hold openjdk 11 package if it was installed
    # newer version of openjdk will be installed later on
    if dpkg -l openjdk-11-jre-headless; then
        echo "openjdk-11-jre-headless hold" | dpkg --set-selections
    fi
}

function configure_sqlserver_repository() {
    echo "[INFO] Running configure_sqlserver_repository on Ubuntu 22.04..."
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)" ||
        { echo "[ERROR] Cannot add mssql-server repository to APT sources." 1>&2; return 10; }
}


function install_nvm_nodejs() {
    echo "[INFO] Running install_nvm_nodejs..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    local CURRENT_NODEJS
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        CURRENT_NODEJS=16
    else
        CURRENT_NODEJS=$1
    fi
    command -v nvm ||
        { echo "Cannot find nvm. Install nvm first!" 1>&2; return 10; }

    local v

    declare NVM_VERSIONS=( "12" "13" "14" "15" "16" "17" "18" "19" "20")

    for v in "${NVM_VERSIONS[@]}"; do
        nvm install ${v} ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done

    nvm alias default ${CURRENT_NODEJS}

    log_version nvm --version
    log_version nvm list
    log_version node --version
    log_version npm --version
}