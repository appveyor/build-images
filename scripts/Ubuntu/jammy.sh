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

function fix_apt_get_install() {
    sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

    cat >/etc/needrestart/conf.d/appveyor-build-agent.conf <<'EOF'
$nrconf{override_rc} = {
    %{ $nrconf{override_rc} || {} },
    qr(^appveyor-build-agent\.service$) => 0,
};
EOF

}

function configure_mercurial_repository() {
    echo "[INFO] Running configure_mercurial_repository on Ubuntu 22.04...skipped"
}

function prepare_dotnet_packages() {
    SDK_VERSIONS=( "8.0" "9.0" "10.0" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]

    # RUNTIME_VERSIONS=( "3.1" "6.0" )
    # dotnet_packages "dotnet-runtime-" RUNTIME_VERSIONS[@]
}

function config_dotnet_repository() {
    find /etc/apt/sources.list.d -maxdepth 1 -type f -name '*.list' -exec grep -l 'packages.microsoft.com/ubuntu/22.04/prod' {} + | xargs -r rm -f
    add-apt-repository -y ppa:dotnet/backports &&
    apt-get -y -q update ||
        { echo "[ERROR] Cannot configure Canonical's .NET APT sources." 1>&2; return 10; }
}

function install_outdated_dotnets() {
    echo "[INFO] Running install_outdated_dotnets on Ubuntu 22.04...skipped"
}

function install_flutter() {
    echo "[INFO] Running install_flutter..."

    local BIN_DIR="${HOME}/flutter/bin"

    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi

    sudo chown "$(id -u "${USER_NAME}"):$(id -g "${USER_NAME}")" -R "${HOME}"

    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"

    local RELEASE_URL
    RELEASE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.41.5-stable.tar.xz"
    curl -fsSL "$RELEASE_URL" -o "flutter_linux_stable.tar.xz" ||
        { echo "[ERROR] Cannot download Flutter distro '$RELEASE_URL'." 1>&2; return 10; }

    tar -xf "flutter_linux_stable.tar.xz" -C "${HOME}"

    write_line "${HOME}/.profile" "add2path_suffix $BIN_DIR"
    export PATH="$PATH:$BIN_DIR"

    flutter channel stable
    flutter upgrade
    yes "y" | flutter doctor --android-licenses > /dev/null
    flutter doctor -v

    popd &&
    rm -rf "${TMP_DIR}"

    log_version flutter --version
}

function install_dotnets() {
    echo "[INFO] Running install_dotnets..."
    prepare_dotnet_packages
    config_dotnet_repository

    #TODO REPO_LIST might be empty
    #REPO_LIST=$(apt-cache search dotnet-)
    # for i in "${!PACKAGES[@]}"; do
    #     if [[ ! ${REPO_LIST} =~ ${PACKAGES[i]} ]]; then
    #         echo "[WARNING] ${PACKAGES[i]} package not found in apt repositories. Skipping it."
    #         unset 'PACKAGES[i]'
    #     fi
    # done
    #TODO PACKAGES might be empty

    # it seems like there is dependency for mysql somethere in dotnet-* packages
    configure_apt_mysql

    apt-get -y -q install --no-install-recommends "${PACKAGES[@]}" ||
        { echo "[ERROR] Cannot install dotnet packages ${PACKAGES[*]}." 1>&2; return 20; }

    #set env
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        write_line "$USER_HOME/.profile" "export DOTNET_CLI_TELEMETRY_OPTOUT=1" 'DOTNET_CLI_TELEMETRY_OPTOUT='
        write_line "$USER_HOME/.profile" "export DOTNET_NOLOGO=1" 'DOTNET_NOLOGO='
    else
        echo "[WARNING] User '${USER_NAME-}' not found. User's profile will not be configured."
    fi

    install_outdated_dotnets
}

function configure_firefox_repository() {
    echo "[INFO] Running configure_firefox_repository on Ubuntu 22.04..."
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6DCF7707EBC211F
    add-apt-repository "deb [ arch=amd64 ] http://ppa.launchpad.net/ubuntu-mozilla-security/ppa/ubuntu jammy main"
    apt-get -y update
}

function install_jdks_from_repository() {
    echo "[INFO] Skipping install_jdks_from_repository..."
    # apt-get -y -qq update && {
    #     apt-get -y -q install --no-install-recommends openjdk-8-jdk
    # } ||
    #     { echo "[ERROR] Cannot install JDKs." 1>&2; return 10; }
    # update-java-alternatives --set java-1.8.0-openjdk-amd64

    # # hold openjdk 11 package if it was installed
    # # newer version of openjdk will be installed later on
    # if dpkg -l openjdk-11-jre-headless; then
    #     echo "openjdk-11-jre-headless hold" | dpkg --set-selections
    # fi
}

function configure_docker_repository() {
    echo "[INFO] Running configure_docker_repository on Ubuntu 22.04..."

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    cat /etc/apt/sources.list.d/docker.list
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
    apt-get -y -q install gcc-12 g++-12 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 50 --slave /usr/bin/g++ g++ /usr/bin/g++-12 ||
        { echo "[ERROR] Cannot install gcc-12." 1>&2; return 50; }
    apt-get -y -q install gcc-13 g++-13 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 60 --slave /usr/bin/g++ g++ /usr/bin/g++-13 ||
        { echo "[ERROR] Cannot install gcc-13." 1>&2; return 60; }
    apt-get -y -q install gcc-14 g++-14 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 70 --slave /usr/bin/g++ g++ /usr/bin/g++-14 ||
        { echo "[ERROR] Cannot install gcc-14." 1>&2; return 70; }
}

function install_clang() {
    echo "[INFO] Running install_clang..."
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

    install_clang_version 13
    install_clang_version 14
    install_clang_version 15
    install_clang_version 16
    install_clang_version 17
    install_clang_version 18
    install_clang_version 19
    install_clang_version 20
    install_clang_version 21
    install_clang_version 22


    # make clang 17 default
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-17 1000
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-17 1000
    update-alternatives --config clang
    update-alternatives --config clang++

    log_version clang --version
}

function fix_clang() {
    echo "[INFO] Running fix_clang..."

    # make clang 17 default
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-17 1000
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-17 1000
    update-alternatives --config clang
    update-alternatives --config clang++

    log_version clang --version
}

function install_clang_version() {
    local LLVM_VERSION=$1
    echo "[INFO] Installing clang ${LLVM_VERSION}..."

    apt-add-repository -y "deb http://apt.llvm.org/${OS_CODENAME}/ llvm-toolchain-${OS_CODENAME}-${LLVM_VERSION} main" ||
        { echo "[ERROR] Cannot add llvm ${LLVM_VERSION} repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install clang-$LLVM_VERSION lldb-$LLVM_VERSION lld-$LLVM_VERSION clangd-$LLVM_VERSION ||
        { echo "[ERROR] Cannot install clang-${LLVM_VERSION}." 1>&2; return 20; }
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

function install_virtualenv() {
    echo "[INFO] Running install_virtualenv..."
    install_pip3
    # pip3 install virtualenv ||
    #     { echo "[WARNING] Cannot install virtualenv with pip." ; return 10; }
    # log_version python3 -m virtualenv --version
    install_pip
    log_version python -m virtualenv --version
    log_version virtualenv --version
}

function install_pip() {
    echo "[INFO] Running install_pip..."
    
    curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" ||
        { echo "[WARNING] Cannot download pip bootstrap script." ; return 10; }
    python3 get-pip.py ||
        { echo "[WARNING] Cannot install pip." ; return 10; }

    python3 -m pip install --upgrade pip setuptools wheel virtualenv

    log_version pip --version

    # cleanup
    rm get-pip.py
}
function configure_sqlserver_repository() {
    echo "[INFO] Running configure_sqlserver_repository on Ubuntu 22.04..."
    install -m 0755 -d /usr/share/keyrings /etc/apt/sources.list.d
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --yes --dearmor -o /usr/share/keyrings/microsoft-prod.gpg ||
        { echo "[ERROR] Cannot install Microsoft's signing key." 1>&2; return 10; }
    chmod a+r /usr/share/keyrings/microsoft-prod.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" \
        > /etc/apt/sources.list.d/microsoft-prod.list ||
        { echo "[ERROR] Cannot add Microsoft's APT source." 1>&2; return 10; }

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/mssql-server-2025 jammy main" \
        > /etc/apt/sources.list.d/mssql-server-2025.list ||
        { echo "[ERROR] Cannot add mssql-server repository to APT sources." 1>&2; return 10; }
}

function install_sqlserver() {
    echo "[INFO] Running install_sqlserver..."
    configure_sqlserver_repository

    apt-get -y -qq update &&
    apt-get -y -q install mssql-server ||
        { echo "[ERROR] Cannot install mssql-server." 1>&2; return 20; }
    MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD \
        MSSQL_PID=developer \
        /opt/mssql/bin/mssql-conf -n setup accept-eula ||
        { echo "[ERROR] Cannot configure mssql-server." 1>&2; return 30; }

    ACCEPT_EULA=Y apt-get -y -q install mssql-tools18 unixodbc-dev
    if [[ -x /opt/mssql-tools18/bin/sqlcmd ]]; then
        ln -s -f /opt/mssql-tools18/bin/sqlcmd /usr/local/bin/sqlcmd
    fi

    if type -t fix_sqlserver; then
        fix_sqlserver
    fi

    systemctl restart mssql-server
    systemctl is-active mssql-server ||
        { echo "[ERROR] mssql-server service failed to start." 1>&2; return 40; }
    log_version dpkg -l mssql-server
}

function install_pythons(){
    echo "[INFO] Installing pyenv..."

    curl https://pyenv.run | bash

    write_line "${HOME}/.profile" 'export PYENV_ROOT="$HOME/.pyenv"'
    write_line "${HOME}/.profile" 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
    write_line "${HOME}/.profile" 'eval "$(pyenv init -)"'

    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    echo "[INFO] Running install_pythons..."
    declare PY_VERSIONS=( "3.10.20" "3.11.15" "3.12.13" "3.13.13" "3.14.5" )

    for i in "${PY_VERSIONS[@]}"; do
        VENV_PATH=${HOME}/venv${i%%[abrcf]*}
        VENV_MINOR_PATH=${HOME}/venv${i%.*}

        pyenv install "${i}" ||
            { echo "[ERROR] Cannot install Python ${i}."; return 10; }

        pyenv global "${i}"
        python --version

        python -m pip install --upgrade pip ||
            { echo "[ERROR] Cannot upgrade pip for Python ${i}."; return 10; }

        python -m venv "${VENV_PATH}" ||
            { echo "[ERROR] Cannot make virtualenv for Python ${i}."; return 10; }

        echo "Linking ${VENV_MINOR_PATH} to ${VENV_PATH}"
        ln -s ${VENV_PATH} ${VENV_MINOR_PATH}
    done

    ls -al ~/venv*
}



function install_nvm() {
    echo "[INFO] Running install_nvm..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}' user. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    #This should install the latest release version automatically
    curl -fsSLo- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    #shellcheck disable=SC2016
    write_line "${HOME}/.profile" 'export NVM_DIR="$HOME/.nvm"'
    #shellcheck disable=SC2016
    write_line "${HOME}/.profile" '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'
    #shellcheck disable=SC2016
    write_line "${HOME}/.profile" '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion'
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
        echo "Current nodejs set to ${CURRENT_NODEJS}"
    else
        CURRENT_NODEJS=$1
        echo "Current nodejs (as param) set to ${CURRENT_NODEJS}"
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


function install_rbenv() {
    echo "[INFO] Running install_rbenv..."
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    #curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
    echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc

    #sudo sh -c "echo 'export PATH=~/.rbenv/shims:$PATH' > /etc/profile.d/system_env_vars.sh"
    write_line "${HOME}/.profile" 'add2path_suffix /home/appveyor/.rbenv/shims'
    write_line "${HOME}/.profile" 'add2path_suffix /home/appveyor/.rbenv/bin'
    export PATH="$PATH:${HOME}/.rbenv/shims:${HOME}/.rbenv/bin"
    # WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    # sudo cp "${WORK_DIR}"/rvm_wrapper.sh /usr/bin/rvm
    # sudo chmod +x /usr/bin/rvm

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

    declare RUBY_VERSIONS=( "3.1.5" "3.2.9" "3.3.9" "3.4.5" )

    for v in "${RUBY_VERSIONS[@]}"; do
        rbenv install ${v} ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
}

# https://jdk.java.net/archive/
function install_jdks() {
    echo "[INFO] Running install_jdks..."

    if [[ $OS_ARCH == "amd64" ]]; then
        TAR_ARCH="x64"
        install_jdk 11 https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz ||
            return $?
    else
        TAR_ARCH="aarch64"
    fi
    install_jdk 17 https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-${TAR_ARCH}_bin.tar.gz ||
        return $?                     
    install_jdk 21 https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-${TAR_ARCH}_bin.tar.gz ||
        return $? 
    install_jdk 25 https://download.java.net/java/GA/jdk25.0.2/b1e0dfa218384cb9959bdcb897162d4e/10/GPL/openjdk-25.0.2_linux-${TAR_ARCH}_bin.tar.gz ||
        return $?
    install_jdk 26 https://download.java.net/java/GA/jdk26/c3cc523845074aa0af4f5e1e1ed4151d/35/GPL/openjdk-26_linux-${TAR_ARCH}_bin.tar.gz ||
        return $?
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        OFS=$IFS
        IFS=$'\n'
        su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            $(declare -f configure_jdk)
            $(declare -f write_line)
            $(declare -f add_line)
            $(declare -f replace_line)
            $(declare -f log_version)
            configure_jdk" <<< "${PROFILE_LINES[*]}" ||
                return $?
        IFS=$OFS
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Skipping configure_jdk"
    fi
    echo "skipping configure_jdk"
}

function install_golangs() {
    echo "[INFO] Running install_golangs..."
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    command -v gvm && gvm version ||
        { echo "Cannot find or execute gvm. Install gvm first!" 1>&2; return 10; }

    declare GO_VERSIONS=( "go1.21.13" "go1.22.12" "go1.23.12" "go1.24.13" "go1.25.10" )

    for v in "${GO_VERSIONS[@]}"; do
        gvm install ${v} -B ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
    local index
    index=$(( ${#GO_VERSIONS[*]} - 1 ))
    gvm use "${GO_VERSIONS[$index]}" --default
    log_version gvm version
    log_version go version
}

function pull_dockerimages() {
    local DOCKER_IMAGES
    local IMAGE
    declare DOCKER_IMAGES=( "mcr.microsoft.com/dotnet/sdk:8.0" "mcr.microsoft.com/dotnet/aspnet:8.0" "mcr.microsoft.com/mssql/server:2025-latest" "debian" "ubuntu" "centos" "alpine" "busybox" "quay.io/pypa/manylinux2014_x86_64")
    for IMAGE in "${DOCKER_IMAGES[@]}"; do
        docker pull "$IMAGE" ||
            { echo "[WARNING] Cannot pull docker image ${IMAGE}." 1>&2; }
    done
    log_version docker images
    log_version docker system df
}

function install_rabbitmq() {
    echo "[INFO] Running install_rabbitmq..."

    ## Team RabbitMQ's main signing key
    apt-key adv --keyserver "hkps://keys.openpgp.org" --recv-keys "0x0A9AF2115F4687BD29803A206B73A36E6026DFCA"
    ## Launchpad PPA that provides modern Erlang releases
    apt-key adv --keyserver "keyserver.ubuntu.com" --recv-keys "F77F1EDA57EBB1CC"
    ## PackageCloud RabbitMQ repository
    apt-key adv --keyserver "keyserver.ubuntu.com" --recv-keys "F6609E60DC62814E"

    apt-get install curl gnupg apt-transport-https -y

    ## Team RabbitMQ's signing key
    curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | sudo gpg --dearmor | sudo tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null

    tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Modern Erlang/OTP releases
##
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb1.rabbitmq.com/rabbitmq-erlang/ubuntu/jammy jammy main
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb2.rabbitmq.com/rabbitmq-erlang/ubuntu/jammy jammy main
## Provides modern RabbitMQ releases
##
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb1.rabbitmq.com/rabbitmq-server/ubuntu/jammy jammy main
deb [arch=amd64 signed-by=/usr/share/keyrings/com.rabbitmq.team.gpg] https://deb2.rabbitmq.com/rabbitmq-server/ubuntu/jammy jammy main
EOF



    # mkdir -p /etc/rabbitmq
    # echo 'NODENAME=rabbitmq@localhost' > /etc/rabbitmq/rabbitmq-env.conf

    apt-get -y -qq update &&
    apt-get install -y erlang-base \
                        erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
                        erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
                        erlang-runtime-tools erlang-snmp erlang-ssl \
                        erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl ||
        { echo "[ERROR] Cannot install erlang." 1>&2; return 20; }

    apt-get install rabbitmq-server -y --fix-missing ||
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
