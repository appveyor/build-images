#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

function disable_automatic_apt_updates() {
    echo "[INFO] Disabling automatic apt updates on Ubuntu 20.04..."
    # https://askubuntu.com/questions/1059971/disable-updates-from-command-line-in-ubuntu-16-04
    # https://stackoverflow.com/questions/45269225/ansible-playbook-fails-to-lock-apt/51919678#51919678
    
    systemctl stop apt-daily.timer
    systemctl disable apt-daily.timer
    systemctl disable apt-daily.service
    systemctl stop apt-daily-upgrade.timer
    systemctl disable apt-daily-upgrade.timer
    systemctl disable apt-daily-upgrade.service
    systemctl daemon-reload
    systemd-run --property="After=apt-daily.service apt-daily-upgrade.service" --wait /bin/true
    apt-get -y purge unattended-upgrades

    echo 'APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/20auto-upgrades
}

function add_releasespecific_tools() {
    # 32bit support
    tools_array+=( "libcurl4:i386" "libcurl4-gnutls-dev" )
    # HWE kernel
    tools_array+=( "linux-generic-hwe-18.04" )
}

function configure_network() {
    # configure eth interface to manual
    read -r IP_NUM IP_DEV IP_FAM IP_ADDR IP_REST <<< "$(ip -o -4 addr show up primary scope global)"
echo "
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - 10.0.0.49/24
      gateway4: 10.0.0.1
      nameservers:
          addresses: [10.10.10.10, 8.8.8.8]
"
    #lets just hope there is no other interfaces after IP_DEV
    #sed -i -r -e "s/^(iface ${IP_DEV}).*/\\1 inet manual/;/^(iface ${IP_DEV}).*/q" /etc/network/interfaces
    #
    #log_exec cat /etc/network/interfaces
    netplan apply

    # remove host ip from /etc/hosts
    sed -i -e "/ $(hostname)/d" -e "/^${IP_ADDR%/*}/d" /etc/hosts
    if [[ -n "${HOST_NAME-}" ]]; then
        write_line "/etc/hosts" "127.0.1.1       $HOST_NAME" "127.0.1.1"
    else
        echo "[ERROR] Variable HOST_NAME not defined. Cannot configure network."
        return 10
    fi
    log_exec cat /etc/hosts

    # rename host
    if [[ -n "${HOST_NAME-}" ]]; then
        echo "${HOST_NAME}" > /etc/hostname
    fi
}


function install_pip() {
    echo "[INFO] Running install_pip..."
    curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" ||
        { echo "[WARNING] Cannot download pip bootstrap script." ; return 10; }
    python get-pip.py ||
        { echo "[WARNING] Cannot install pip." ; return 10; }

    log_version pip --version

    #cleanup
    rm get-pip.py
}

function install_gitlfs() {
    echo "[INFO] Running install_gitlfs on Ubuntu 20.04..."
    command -v git || apt-get -y -q install git
    #curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash &&
    apt-get -y -q install git-lfs ||
        { echo "Failed to install git lfs." 1>&2; return 10; }
    log_version dpkg -l git-lfs
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        su -l "${USER_NAME}" -c "
            USER_NAME=${USER_NAME}
            $(declare -f configure_gitlfs)
            configure_gitlfs"  ||
                return $?
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Skipping configure_gitlfs"
    fi
}

function install_powershell() {
    echo "[INFO] Install PowerShell on Ubuntu 20.04..."
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    local PWSH_INSTALL_DIR=/opt/microsoft/powershell/7-focal
    local TAR_NAME=powershell-7.0.0-linux-x64.tar.gz

    #download package
    curl -fsSL -O "https://github.com/PowerShell/PowerShell/releases/download/v7.0.0/${TAR_NAME}"

    # install
    mkdir -p ${PWSH_INSTALL_DIR}
    tar -zxf "${TAR_NAME}" -C ${PWSH_INSTALL_DIR}
    ln -s ${PWSH_INSTALL_DIR}/pwsh /usr/bin/pwsh

    configure_powershell

    popd &&
    rm -rf "${TMP_DIR}"
    log_version pwsh --version
}

function config_dotnet_repository() {
    # temp hack from here: https://github.com/dotnet/core/issues/4360#issuecomment-619598884
    wget http://mirrors.edge.kernel.org/ubuntu/pool/main/i/icu/libicu63_63.2-2_amd64.deb
    dpkg -i libicu63_63.2-2_amd64.deb
    rm libicu63_63.2-2_amd64.deb

    curl -fsSL -O https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb &&
    dpkg -i packages-microsoft-prod.deb &&
    apt-get -y -qq update ||
        { echo "[ERROR] Cannot download and install Microsoft's APT source." 1>&2; return 10; }
}

function install_outdated_dotnets() {
    echo "[INFO] Running install_outdated_dotnets on Ubuntu 20.04..."
    echo "[WARNING] Skipped!"
}

function install_nodejs() {
    echo "[INFO] Running install_nodejs..."
    apt-get -y -q install nodejs npm &&
    npm install -g pm2 ||
        { echo "[ERROR] Something went wrong."; return 100; }
    log_version dpkg -l nodejs
}

function install_cvs() {
    echo "[INFO] Running install_cvs..."
    # install git
    # at this time there is git version 2.7.4 in apt repos
    # in case if we need recent version we have to run make_git function
    apt-get -y -q install git

    #install Mercurial
    apt-get -y -q install mercurial

    #install subversion
    apt-get -y -q install subversion

    log_version dpkg -l git mercurial subversion
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            $(declare -f configure_svn)
            configure_svn" ||
                return $?
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Skipping configure_svn"
    fi
}

function configure_rabbitmq_repositories() {
    echo "[INFO] Running configure_rabbitmq_repositories..."

    add-apt-repository "deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang" ||
        { echo "[ERROR] Cannot add rabbitmq-erlang repository to APT sources." 1>&2; return 10; }

    add-apt-repository "deb https://dl.bintray.com/rabbitmq/debian bionic main" ||
        { echo "[ERROR] Cannot add rabbitmq repository to APT sources." 1>&2; return 10; }
}

function configure_virtualbox_repository() {
    echo "[INFO] Running configure_virtualbox_repository on Ubuntu 20.04..."

    add-apt-repository "deb http://download.virtualbox.org/virtualbox/debian bionic contrib" ||
        { echo "[ERROR] Cannot add virtualbox.org repository to APT sources." 1>&2; return 10; }    
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

function install_sqlserver() {
    echo "[INFO] Running install_sqlserver..."
    echo "[WARNING] SQL Server is not supported on Ubuntu 20.04 yet"
}

function configure_sqlserver() {
    echo "[INFO] Running configure_sqlserver..."
    echo "[WARNING] SQL Server is not supported on Ubuntu 20.04 yet"
}

function disable_sqlserver() {
    echo "[INFO] Running disable_sqlserver..."
    echo "[WARNING] SQL Server is not supported on Ubuntu 20.04 yet"
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
    echo "[INFO] Running install_mono..."
    add-apt-repository "deb http://download.mono-project.com/repo/ubuntu stable-bionic main" ||
        { echo "[ERROR] Cannot add Mono repository to APT sources." 1>&2; return 10; }
}

function configure_azurecli_repository() {
    echo "[INFO] Running configure_azurecli_repository..."
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ bionic main" > /etc/apt/sources.list.d/azure-cli.list
}
