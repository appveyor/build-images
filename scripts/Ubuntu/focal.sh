#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

function add_releasespecific_tools() {
    # doxygen support
    tools_array+=( "libclang1-9" )
    # 32bit support
    tools_array+=( "libcurl4:i386" "libcurl4-gnutls-dev" )
    # HWE kernel
    tools_array+=( "linux-generic-hwe-18.04" )
}

function configure_mercurial_repository() {
    echo "[INFO] Running configure_mercurial_repository on Ubuntu 20.04...skipped"
}

function prepare_dotnet_packages() {
    SDK_VERSIONS=( "2.1" "2.2" "3.0" "3.1" "5.0" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]

    declare RUNTIME_VERSIONS=( "2.1" "2.2" )
    dotnet_packages "dotnet-runtime-" RUNTIME_VERSIONS[@]
}

function install_outdated_dotnets() {
    echo "[INFO] Running install_outdated_dotnets on Ubuntu 20.04...skipped"
}

function configure_rabbitmq_repositories() {
    echo "[INFO] Running configure_rabbitmq_repositories..."

    add-apt-repository "deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang" ||
        { echo "[ERROR] Cannot add rabbitmq-erlang repository to APT sources." 1>&2; return 10; }

    add-apt-repository "deb https://dl.bintray.com/rabbitmq/debian bionic main" ||
        { echo "[ERROR] Cannot add rabbitmq repository to APT sources." 1>&2; return 10; }
}

function configure_firefox_repository() {
    echo "[INFO] Running configure_firefox_repository on Ubuntu 20.04..."
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6DCF7707EBC211F
    add-apt-repository "deb [ arch=amd64 ] http://ppa.launchpad.net/ubuntu-mozilla-security/ppa/ubuntu bionic main"
    apt-get -y update
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
    echo "[INFO] Running configure_sqlserver_repository on Ubuntu 20.04..."
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