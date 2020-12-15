#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

function add_releasespecific_tools() {
    # 32bit support
    tools_array+=( "libcurl4:i386" "libcurl4-gnutls-dev" )
    # HWE kernel
    tools_array+=( "linux-generic-hwe-18.04" )
}

function configure_mercurial_repository() {
    echo "[INFO] Running configure_mercurial_repository on Ubuntu 18.04...skipped"
}

function install_outdated_dotnets() {
    echo "[INFO] Running install_outdated_dotnets..."

    # .NET SDK 1.1.14 with 1.1.13 & 1.0.16 runtimes
    wget -O dotnet-sdk.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/1.1.14/dotnet-dev-ubuntu.18.04-x64.1.1.14.tar.gz
    sudo tar zxf dotnet-sdk.tar.gz -C /usr/share/dotnet

    # .NET SDK 2.1.202 with 2.0.9 runtime
    wget -O dotnet-sdk.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/2.1.202/dotnet-sdk-2.1.202-linux-x64.tar.gz
    sudo tar zxf dotnet-sdk.tar.gz -C /usr/share/dotnet    

    rm dotnet-sdk.tar.gz
}

function prepare_dotnet_packages() {

    SDK_VERSIONS=( "2.1" "2.2" "3.0" "3.1" "5.0" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]

    declare RUNTIME_VERSIONS=( "2.1" "2.2" )
    dotnet_packages "dotnet-runtime-" RUNTIME_VERSIONS[@]
}

function install_mongodb() {
    echo "[INFO] Running install_mongodb..."
    apt install -yqq mongodb ||
        { echo "[ERROR] Cannot install mongodb." 1>&2; return 10; }

    log_version dpkg -l mongodb
}

function install_jdks_from_repository() {
    echo "[INFO] Running install_jdks_from_repository..."
    add-apt-repository -y ppa:openjdk-r/ppa
    apt-get -y -qq update && {
        apt-get -y -q install --no-install-recommends openjdk-8-jdk
    } ||
        { echo "[ERROR] Cannot install JDKs." 1>&2; return 10; }
    update-java-alternatives --set java-1.8.0-openjdk-amd64

    # there is no support for openJDK 7 in Ubuntu 18.04
    install_jdk 7 https://download.java.net/openjdk/jdk7u75/ri/openjdk-7u75-b13-linux-x64-18_dec_2014.tar.gz

    # hold openjdk 11 package if it was installed
    # newer version of openjdk will be installed later on
    if dpkg -l openjdk-11-jre-headless; then
        echo "openjdk-11-jre-headless hold" | dpkg --set-selections
    fi
}

function configure_sqlserver_repository() {
    echo "[INFO] Running configure_sqlserver_repository on Ubuntu 18.04..."
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/18.04/mssql-server-2019.list)" ||
        { echo "[ERROR] Cannot add mssql-server repository to APT sources." 1>&2; return 10; }
}

function fix_sqlserver() {
    echo "[INFO] Running fix_sqlserver..."

    # disable updates of the SQL Server
    apt-mark hold mssql-server

    # Workaround https://stackoverflow.com/a/57453901
    ln -sf /usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0 /opt/mssql/lib/libcrypto.so &&
    ln -sf /usr/lib/x86_64-linux-gnu/libssl.so.1.0.0 /opt/mssql/lib/libssl.so &&
    mkdir -p /etc/systemd/system/mssql-server.service.d/ &&
    (
        echo '[Service]'
        echo 'Environment="LD_LIBRARY_PATH=/opt/mssql/lib"'
    ) > /etc/systemd/system/mssql-server.service.d/override.conf ||
        { echo "[ERROR] Cannot configure workaround for mssql-server." 1>&2; return 45; }

}

function install_doxygen() {
    echo "[INFO] Running ${FUNCNAME[0]}..."
    install_doxygen_version '1.8.18'
}