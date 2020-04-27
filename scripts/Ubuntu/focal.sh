#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

function disable_automatic_apt_updates() {
    echo "[INFO] Disabling automatic apt updates..."
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

function install_powershell() {
    echo "[INFO] Install PowerShell on Ubuntu 20.04..."
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    local DEB_NAME
    DEB_NAME=powershell-lts_7.0.0-1.ubuntu.18.04_amd64.deb

    #download package
    curl -fsSL -O "https://github.com/PowerShell/PowerShell/releases/download/v7.0.0/${DEB_NAME}"

    # install
    dpkg -i "${DEB_NAME}"

    configure_powershell

    popd &&
    rm -rf "${TMP_DIR}"
    log_version pwsh --version
}

function config_dotnet_repository() {
    curl -fsSL -O https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb &&
    dpkg -i packages-microsoft-prod.deb &&
    apt-get -y -qq update ||
        { echo "[ERROR] Cannot download and install Microsoft's APT source." 1>&2; return 10; }
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

#this function deprecated
function install_sqlserver_deprecated() {
    echo "[INFO] Running install_sqlserver..."
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    local DEB_NAME
    DEB_NAME=mssql-server_14.0.3238.1-19_amd64.deb

    #download package
    curl -fsSL -O "https://packages.microsoft.com/ubuntu/16.04/mssql-server-2017/pool/main/m/mssql-server/${DEB_NAME}"
    # since build 3045 there is no need to repack package
    # dpkg-deb -x "${DEB_NAME}" newpkg/
    # dpkg-deb -e "${DEB_NAME}" newpkg/DEBIAN/

    # # change dependencies
    # sed -i -e 's#openssl (<= 1.1.0)#openssl (<= 1.1.1)#g' newpkg/DEBIAN/control
    # sed -i -e 's#libcurl3#libcurl4#g' newpkg/DEBIAN/control

    # #Repackage
    # dpkg-deb -b newpkg/ "18.04-${DEB_NAME}"
    # #install
    # apt-get install -y -qq libjemalloc1 libc++1 gdb libcurl4 libsss-nss-idmap0 gawk
    # dpkg -i "18.04-${DEB_NAME}"
    apt-get install -y -qq libjemalloc1 libc++1 gdb python libsss-nss-idmap0 libsasl2-modules-gssapi-mit
    dpkg -i "${DEB_NAME}"

    MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD \
        MSSQL_PID=developer \
        /opt/mssql/bin/mssql-conf -n setup accept-eula ||
        { echo "[ERROR] Cannot configure mssql-server." 1>&2; popd; return 30; }

    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -  &&
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/18.04/prod.list)" ||
        { echo "[ERROR] Cannot add mssql-server repository to APT sources." 1>&2; return 35; }

    ACCEPT_EULA=Y apt-get -y -q install mssql-tools unixodbc-dev
    systemctl restart mssql-server
    systemctl is-active mssql-server ||
        { echo "[ERROR] mssql-server service failed to start." 1>&2; popd; return 40; }



    popd &&
    rm -rf "${TMP_DIR}"
    log_version dpkg -l mssql-server
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

function prerequisites_dotnetv3_preview () {
    # https://github.com/dotnet/core/blob/master/Documentation/linux-prereqs.md
    echo "libicu60 openssl1.0"
}

function install_browsers() {
    echo "[INFO] Running install_browsers..."
    local DEBNAME=google-chrome-stable_current_amd64.deb
    add-apt-repository -y ppa:ubuntu-mozilla-security/ppa &&
    apt-get -y -qq update &&
    apt-get -y -q install libappindicator3-1 libu2f-udev fonts-liberation xvfb ||
        { echo "[ERROR] Cannot install libappindicator1 and fonts-liberation." 1>&2; return 10; }
    curl -fsSL -O https://dl.google.com/linux/direct/${DEBNAME}
    dpkg -i ${DEBNAME}
    apt-get -y -q install firefox
    log_version dpkg -l firefox google-chrome-stable
    #cleanup
    [ -f "${DEBNAME}" ] && rm -f "${DEBNAME}" || true
}
