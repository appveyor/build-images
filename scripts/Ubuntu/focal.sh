#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

function add_releasespecific_tools() {
    if [[ $OS_ARCH == "amd64" ]]; then
        # doxygen support
        tools_array+=( "libclang1-9" )
        # 32bit support
        tools_array+=( "libcurl4:i386" "libcurl4-gnutls-dev" )
        # HWE kernel
        tools_array+=( "linux-generic-hwe-18.04" )
    fi    
}

function configure_mercurial_repository() {
    echo "[INFO] Running configure_mercurial_repository on Ubuntu 20.04...skipped"
}

function prepare_dotnet_packages() {
    SDK_VERSIONS=( "2.1" "2.2" "3.0" "3.1" "5.0" "6.0" "7.0" "8.0" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]
    
    declare RUNTIME_VERSIONS=( "2.1" "2.2" )
    dotnet_packages "dotnet-runtime-" RUNTIME_VERSIONS[@]
}

function install_outdated_dotnets() {
    echo "[INFO] Running install_outdated_dotnets on Ubuntu 20.04...skipped"
}

function configure_firefox_repository() {
    echo "[INFO] Running configure_firefox_repository on Ubuntu 20.04..."
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6DCF7707EBC211F
    add-apt-repository "deb [ arch=amd64 ] http://ppa.launchpad.net/ubuntu-mozilla-security/ppa/ubuntu bionic main"
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

function configure_mono_repository () {
    echo "[INFO] Running configure_mono_repository on Ubuntu 22.04..."
    
    sudo apt-get install ca-certificates gnupg
    sudo gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
    sudo apt-get update

    #add-apt-repository "deb http://download.mono-project.com/repo/ubuntu stable-focal main" ||
     #   { echo "[ERROR] Cannot add Mono repository to APT sources." 1>&2; return 10; }
}