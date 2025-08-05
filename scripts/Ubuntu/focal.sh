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
    SDK_VERSIONS=( "3.0" "3.1" "5.0" "6.0" "7.0" "8.0" )
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
    #install_jdk 7 https://download.java.net/openjdk/jdk7u75/ri/openjdk-7u75-b13-linux-x64-18_dec_2014.tar.gz

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
    echo "[INFO] Running configure_mono_repository on Ubuntu 20.04..."
    
    sudo apt-get install ca-certificates gnupg
    sudo gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
    sudo apt-get update

    #add-apt-repository "deb http://download.mono-project.com/repo/ubuntu stable-focal main" ||
     #   { echo "[ERROR] Cannot add Mono repository to APT sources." 1>&2; return 10; }
}

function pull_dockerimages() {
    local DOCKER_IMAGES
    local IMAGE
    declare DOCKER_IMAGES=( "mcr.microsoft.com/dotnet/sdk:7.0" "mcr.microsoft.com/dotnet/aspnet:7.0" "mcr.microsoft.com/mssql/server:2022-latest" "debian" "ubuntu" "centos" "alpine" "busybox" "quay.io/pypa/manylinux2014_x86_64")
    for IMAGE in "${DOCKER_IMAGES[@]}"; do
        docker pull "$IMAGE" ||
            { echo "[WARNING] Cannot pull docker image ${IMAGE}." 1>&2; }
    done
    log_version docker images
    log_version docker system df
}

function install_rbenv_rubies() {
    echo "[INFO] Running install_rbenv_rubies..."
    eval "$(~/.rbenv/bin/rbenv init - bash)"
    git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
    local DEFAULT_RUBY
    DEFAULT_RUBY="2.7.8"
    command -v rbenv ||
        { echo "Cannot find rbenv. Install rbenv first!" 1>&2; return 10; }
    local v

    declare RUBY_VERSIONS=( "2.4.10" "2.5.9" "2.6.10" "2.7.8" "3.0.6" "3.1.5" "3.2.9" "3.3.9" "3.4.5" )

    for v in "${RUBY_VERSIONS[@]}"; do
        rbenv install ${v} ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
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
        CURRENT_NODEJS=22
    else
        CURRENT_NODEJS=$1
    fi
    command -v nvm ||
        { echo "Cannot find nvm. Install nvm first!" 1>&2; return 10; }
    local v

    declare NVM_VERSIONS=( "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24")

    
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

function install_gcc() {
    echo "[INFO] Running install_gcc..."

    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get -y -qq update ||
        { echo "[ERROR] Cannot add gcc repository to APT sources." 1>&2; return 10; }
    apt-get -y -q install gcc-9 g++-9 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 20 --slave /usr/bin/g++ g++ /usr/bin/g++-9 ||
        { echo "[ERROR] Cannot install gcc-9." 1>&2; return 20; }
    apt-get -y -q install gcc-10 g++-10 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 30 --slave /usr/bin/g++ g++ /usr/bin/g++-10 ||
        { echo "[ERROR] Cannot install gcc-10." 1>&2; return 30; }
    apt-get -y -q install gcc-11 g++-11 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 40 --slave /usr/bin/g++ g++ /usr/bin/g++-11 ||
        { echo "[ERROR] Cannot install gcc-11." 1>&2; return 40; }
}

function install_postgresql() {
    echo "[INFO] Running install_postgresql..."
    if [[ -z "${POSTGRES_ROOT_PASSWORD-}" || "${#POSTGRES_ROOT_PASSWORD}" = "0" ]]; then POSTGRES_ROOT_PASSWORD="Password12!"; fi
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - &&
    add-apt-repository -y "deb http://apt-archive.postgresql.org/pub/repos/apt/ ${OS_CODENAME}-pgdg main" ||
        { echo "[ERROR] Cannot add postgresql repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install postgresql ||
        { echo "[ERROR] Cannot install postgresql." 1>&2; return 20; }
    systemctl start postgresql
    systemctl disable postgresql
    log_version dpkg -l postgresql

    sudo -u postgres createuser ${USER_NAME}
    sudo -u postgres psql -c "alter user ${USER_NAME} with createdb" postgres
    sudo -u postgres psql -c "ALTER USER postgres with password '${POSTGRES_ROOT_PASSWORD}';" postgres
    replace_line '/etc/postgresql/11/main/pg_hba.conf' 'local   all             postgres                                trust' 'local\s+all\s+postgres\s+peer'

}