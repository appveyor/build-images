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
    SDK_VERSIONS=( "3.1" "6.0" "7.0" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]

    RUNTIME_VERSIONS=( "3.1" "6.0" )
    dotnet_packages "dotnet-runtime-" RUNTIME_VERSIONS[@]
}

function config_dotnet_repository() {
    touch /etc/apt/preferences
    echo -e 'Package: *\nPin: origin "packages.microsoft.com"\nPin-Priority: 1001' | sudo tee /etc/apt/preferences
    curl -fsSL -O https://packages.microsoft.com/config/ubuntu/${OS_RELEASE}/packages-microsoft-prod.deb &&
    dpkg -i packages-microsoft-prod.deb &&
    apt-get -y -q update ||
        { echo "[ERROR] Cannot download and install Microsoft's APT source." 1>&2; return 10; }
}

function install_outdated_dotnets() {
    echo "[INFO] Running install_outdated_dotnets on Ubuntu 22.04...skipped"
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
        write_line "$USER_HOME/.profile" "export DOTNET_PRINT_TELEMETRY_MESSAGE=false" 'DOTNET_PRINT_TELEMETRY_MESSAGE='
    else
        echo "[WARNING] User '${USER_NAME-}' not found. User's profile will not be configured."
    fi

    #cleanup
    if [ -f packages-microsoft-prod.deb ]; then rm packages-microsoft-prod.deb; fi

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

function configure_sqlserver_repository() {
    echo "[INFO] Running configure_sqlserver_repository on Ubuntu 22.04..."
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)" ||
        { echo "[ERROR] Cannot add mssql-server repository to APT sources." 1>&2; return 10; }
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

function install_clang() {
    echo "[INFO] Running install_clang..."
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

    install_clang_version 13
    install_clang_version 14
    install_clang_version 15
    install_clang_version 16
    install_clang_version 17

    # make clang 10 default
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-10 1000
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-10 1000
    update-alternatives --config clang
    update-alternatives --config clang++

    log_version clang --version
}

function install_clang_version() {
    local LLVM_VERSION=$1
    echo "[INFO] Installing clang ${LLVM_VERSION}..."

    apt-add-repository "deb http://apt.llvm.org/${OS_CODENAME}/ llvm-toolchain-${OS_CODENAME}-${LLVM_VERSION} main" ||
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

function configure_sqlserver_repository() {
    echo "[INFO] Running configure_sqlserver_repository on Ubuntu 22.04..."
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)" ||
        { echo "[ERROR] Cannot add mssql-server repository to APT sources." 1>&2; return 10; }
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
    
    curl "https://bootstrap.pypa.io/pip/3.6/get-pip.py" -o "get-pip.py" ||
        { echo "[WARNING] Cannot download pip bootstrap script." ; return 10; }
    python3 get-pip.py ||
        { echo "[WARNING] Cannot install pip." ; return 10; }

    python3 -m pip install --upgrade pip setuptools wheel virtualenv

    log_version pip --version

    # cleanup
    rm get-pip.py
}

function install_sqlserver() {
    echo "[INFO] Running install_sqlserver..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-preview.list | sudo tee /etc/apt/sources.list.d/mssql-server-preview.list
    #configure_sqlserver_repository

    apt-get -y -qq update &&
    apt-get -y -q install mssql-server ||
        { echo "[ERROR] Cannot install mssql-server." 1>&2; return 20; }
    MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD \
        MSSQL_PID=developer \
        /opt/mssql/bin/mssql-conf -n setup accept-eula ||
        { echo "[ERROR] Cannot configure mssql-server." 1>&2; return 30; }

    ACCEPT_EULA=Y apt-get -y -q install mssql-tools unixodbc-dev

    if type -t fix_sqlserver; then
        fix_sqlserver
    fi

    systemctl restart mssql-server
    systemctl is-active mssql-server ||
        { echo "[ERROR] mssql-server service failed to start." 1>&2; return 40; }
    log_version dpkg -l mssql-server
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
        CURRENT_NODEJS=16
    else
        CURRENT_NODEJS=$1
    fi
    command -v nvm ||
        { echo "Cannot find nvm. Install nvm first!" 1>&2; return 10; }
    local v

    declare NVM_VERSIONS=( "14" "15" "16" "17" "18" "19" "20" )

    
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

function install_rvm() {
    echo "[INFO] Running install_rvm..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    sudo apt update &&
    sudo apt install gnupg2

    # Install mpapis public key (might need `gpg2` and or `sudo`)
    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -

    # Download the installer
    curl -fsSL -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer &&
    curl -fsSL -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer.asc ||
        { echo "[ERROR] Cannot download rvm-installer." 1>&2; return 10; }

    # Verify the installer signature (might need `gpg2`), and if it validates...
    gpg2 --verify rvm-installer.asc &&

    # Run the installer
    bash rvm-installer stable ||
        { echo "[ERROR] Cannot install RVM." 1>&2; return 20; }

    # cleanup
    rm rvm-installer rvm-installer.asc
}

function install_rubies() {
    echo "[INFO] Running install_rubies..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    rvm pkg install openssl
    local DEFAULT_RUBY
    DEFAULT_RUBY="ruby-2.7"
    command -v rvm ||
        { echo "Cannot find rvm. Install rvm first!" 1>&2; return 10; }
    local v

    declare RUBY_VERSIONS=( "ruby-2.6" "ruby-2.7" "ruby-3.0" "ruby-3.1.4" "ruby-3.2.2" "ruby-head" )
    
    for v in "${RUBY_VERSIONS[@]}"; do
        rvm install ${v} --with-openssl-dir=$HOME/.rvm/usr ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done

    rvm use "$DEFAULT_RUBY" --default
    log_version rvm --version
    log_version rvm list
}

# https://jdk.java.net/archive/
function install_jdks() {
    echo "[INFO] Running install_jdks..."

    if [[ $OS_ARCH == "amd64" ]]; then
        TAR_ARCH="x64"
        install_jdk 9 https://download.java.net/java/GA/jdk9/9.0.4/binaries/openjdk-9.0.4_linux-x64_bin.tar.gz ||
            return $?
        install_jdk 10 https://download.java.net/java/GA/jdk10/10.0.2/19aef61b38124481863b1413dce1855f/13/openjdk-10.0.2_linux-x64_bin.tar.gz ||
            return $?
        install_jdk 11 https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz ||
            return $?
        install_jdk 12 https://download.java.net/java/GA/jdk12.0.2/e482c34c86bd4bf8b56c0b35558996b9/10/GPL/openjdk-12.0.2_linux-x64_bin.tar.gz ||
            return $?
        install_jdk 13 https://download.java.net/java/GA/jdk13.0.2/d4173c853231432d94f001e99d882ca7/8/GPL/openjdk-13.0.2_linux-x64_bin.tar.gz ||
            return $?
        install_jdk 14 https://download.java.net/java/GA/jdk14.0.2/205943a0976c4ed48cb16f1043c5c647/12/GPL/openjdk-14.0.2_linux-x64_bin.tar.gz ||
            return $?
    else
        TAR_ARCH="aarch64"
    fi
    install_jdk 15 https://download.java.net/java/GA/jdk15.0.2/0d1cfde4252546c6931946de8db48ee2/7/GPL/openjdk-15.0.2_linux-${TAR_ARCH}_bin.tar.gz ||
        return $?
    install_jdk 16 https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_linux-${TAR_ARCH}_bin.tar.gz ||
        return $?  
    install_jdk 17 https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-${TAR_ARCH}_bin.tar.gz ||
        return $?                     
    install_jdk 18 https://download.java.net/java/GA/jdk18.0.1.1/65ae32619e2f40f3a9af3af1851d6e19/2/GPL/openjdk-18.0.1.1_linux-${TAR_ARCH}_bin.tar.gz ||
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
}