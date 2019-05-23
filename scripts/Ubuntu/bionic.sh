#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

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
    if [[ -n "${HOST_NAME}" ]]; then
        write_line "/etc/hosts" "127.0.1.1       $HOST_NAME" "127.0.1.1"
    else
        echo "[ERROR] Variable HOST_NAME not defined. Cannot configure network."
        return 10
    fi
    log_exec cat /etc/hosts

    # rename host
    if [[ -n "${HOST_NAME}" ]]; then
        hostnamectl set-hostname "${HOST_NAME}"
    fi
}


function install_pip() {
    curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" ||
        { echo "[WARNING] Cannot download pip bootstrap script." ; return 10; }
    python get-pip.py ||
        { echo "[WARNING] Cannot install pip." ; return 10; }

    log_exec pip --version

    #cleanup
    rm get-pip.py
}

function prepare_dotnet_packages() {
    declare SDK_VERSIONS=( "2.1.105" "2.1.200" "2.1.201" "2.1.202" "2.1" "2.2" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]

    declare RUNTIME_VERSIONS=( "2.0.7" "2.1" "2.2" )
    dotnet_packages "dotnet-runtime-" RUNTIME_VERSIONS[@]

    declare DEV_VERSIONS=( "1.1.5" "1.1.6" "1.1.7" "1.1.8" "1.1.9" "1.1.11" )
    dotnet_packages "dotnet-dev-" DEV_VERSIONS[@]
}

function config_dotnet_repository() {
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg &&
    mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ &&
    wget -q https://packages.microsoft.com/config/ubuntu/18.04/prod.list &&
    mv prod.list /etc/apt/sources.list.d/microsoft-prod.list &&
    chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg &&
    chown root:root /etc/apt/sources.list.d/microsoft-prod.list &&
    apt-get -y -qq update ||
        { echo "[ERROR] Cannot download and install Microsoft's APT source." 1>&2; return 10; }
}

function install_nodejs() {
    apt-get -y -q install nodejs npm &&
    npm install -g pm2 ||
        { echo "[ERROR] Something went wrong."; return 100; }
    log_exec dpkg -l nodejs
}

function install_cvs() {
    # install git
    # at this time there is git version 2.7.4 in apt repos
    # in case if we need recent version we have to run make_git function
    apt-get -y -q install git

    #install Mercurial
    apt-get -y -q install mercurial

    #install subversion
    apt-get -y -q install subversion

    log_exec dpkg -l git mercurial subversion
}

function install_mongodb() {
    apt install -yqq mongodb ||
        { echo "[ERROR] Cannot install mongodb." 1>&2; return 10; }

    log_exec dpkg -l mongodb
}

function install_jdks() {
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
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    local DEB_NAME
    DEB_NAME=mssql-server_14.0.3045.24-1_amd64.deb

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

    ACCEPT_EULA=Y apt-get -y -q install mssql-tools unixodbc-dev
    systemctl restart mssql-server
    systemctl is-active mssql-server ||
        { echo "[ERROR] mssql-server service failed to start." 1>&2; popd; return 40; }

    popd
    log_exec dpkg -l mssql-server
}

function install_azurecli() {
    AZ_REPO=$OS_CODENAME
    apt-key adv --keyserver packages.microsoft.com --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF ||
        { echo "[ERROR] Cannot add microsoft's repository key." 1>&2; return 5; }
    add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" ||
        { echo "[ERROR] Cannot add azure-cli repository to APT sources." 1>&2; return 10; }
    apt-get -y -q install apt-transport-https &&
    apt-get -y -qq update &&
    apt-get -y -q install azure-cli ||
        { echo "[ERROR] Cannot instal azure-cli."; return 20; }
    log_exec az --version
}


function install_browsers() {
    local DEBNAME=google-chrome-stable_current_amd64.deb
    add-apt-repository -y ppa:ubuntu-mozilla-security/ppa &&
    apt-get -y -qq update &&
    apt-get -y -q install libappindicator3-1 libu2f-udev fonts-liberation xvfb ||
        { echo "[ERROR] Cannot install libappindicator1 and fonts-liberation." 1>&2; return 10; }
    curl -fsSL -O https://dl.google.com/linux/direct/${DEBNAME}
    dpkg -i ${DEBNAME}
    apt-get -y -q install firefox
    #cleanup
    [ -f "${DEBNAME}" ] && rm -f "${DEBNAME}" || true
}
