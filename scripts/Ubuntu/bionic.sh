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

    SDK_VERSIONS=( "2.1" "2.2" "3.0" "3.1" "5.0" "6.0" "7.0" "8.0" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]

    declare RUNTIME_VERSIONS=( "2.1" "2.2" )
    dotnet_packages "dotnet-runtime-" RUNTIME_VERSIONS[@]
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
    install_doxygen_version '1.8.20' 'https://appveyordownloads.blob.core.windows.net/misc'
}

function install_google_chrome() {
    echo "[INFO] Running install_google_chrome on Bionic..."
    local CHROME_VERSION=107.0.5304.87-1
    local DEBNAME=google-chrome-stable_${CHROME_VERSION}_amd64.deb
    curl -fsSL -O https://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/${DEBNAME}
    dpkg -i ${DEBNAME}
    [ -f "${DEBNAME}" ] && rm -f "${DEBNAME}" || true
}

function install_postgresql() {
    echo "[INFO] Running install_postgresql..."
    if [[ -z "${POSTGRES_ROOT_PASSWORD-}" || "${#POSTGRES_ROOT_PASSWORD}" = "0" ]]; then POSTGRES_ROOT_PASSWORD="Password12!"; fi
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - &&
    add-apt-repository "deb https://apt-archive.postgresql.org/pub/repos/apt ${OS_CODENAME}-pgdg main" ||
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


function install_rabbitmq() {
    echo "[INFO] Running install_rabbitmq..."

    sudo apt-get update -y

    sudo apt-get install curl gnupg -y

    curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | sudo apt-key add -

    sudo apt-get install apt-transport-https

    # sudo tee /etc/apt/sources.list.d/bintray.rabbitmq.list <<EOF
    # deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang
    # deb https://dl.bintray.com/rabbitmq/debian bionic main
    # EOF
    sudo tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Provides modern Erlang/OTP releases from a Cloudsmith mirror
##
deb [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $distribution main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $distribution main

# another mirror for redundancy
deb [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $distribution main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $distribution main

## Provides RabbitMQ from a Cloudsmith mirror
##
deb [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu $distribution main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu $distribution main

# another mirror for redundancy
deb [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu $distribution main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.novemberain.com/rabbitmq/rabbitmq-server/deb/ubuntu $distribution main
EOF

    sudo apt-get install -y erlang-base \
                        erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
                        erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
                        erlang-runtime-tools erlang-snmp erlang-ssl \
                        erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl
    apt-get -y -qq update &&
    apt-get -y install rabbitmq-server ||
        { echo "[ERROR] Cannot install rabbitmq." 1>&2; return 20; }

    sed -ibak -E -e 's/#\s*ulimit/ulimit/' /etc/default/rabbitmq-server &&

    systemctl start rabbitmq-server &&
    systemctl status rabbitmq-server --no-pager &&
    systemctl enable rabbitmq-server &&
    systemctl disable rabbitmq-server ||
        { echo "[ERROR] Cannot configure rabbitmq." 1>&2; return 30; }

    log_version dpkg -l rabbitmq-server
    log_version erl -eval '{ok, Version} = file:read_file(filename:join([code:root_dir(), "releases", erlang:system_info(otp_release), "OTP_VERSION"])), io:fwrite(Version), halt().' -noshell
}

function configure_mono_repository () {
    echo "[INFO] Running configure_mono_repository on Ubuntu 18.04..."
    
    sudo apt-get install ca-certificates gnupg
    sudo gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
    sudo apt-get update

}