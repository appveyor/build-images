#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

# set variables
declare PACKAGES=( )
declare SDK_VERSIONS=( )
declare PROFILE_LINES=( )
if [ -f /etc/os-release ]; then
    OS_CODENAME=$(source /etc/os-release && echo $VERSION_CODENAME)
    OS_RELEASE=$(source /etc/os-release && echo $VERSION_ID)
else
    echo "[WARNING] /etc/os-release not found - cant find VERSION_CODENAME and VERSION_ID."
fi
if [[ -z "${LOGGING}" ]]; then LOGGING=true; fi

function init_logging() {
    if [[ -z $LOG_FILE ]]; then
        SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
        LOG_FILE=$HOME/${SCRIPT_NAME%.*}.log
    fi
    touch $LOG_FILE
}

function chown_logfile() {
    if [[ -n "${USER_NAME}" && -n "${LOG_FILE}" ]]; then
        if id -u "${USER_NAME}"; then
            chown $USER_NAME:$USER_NAME $LOG_FILE
        else
            return 1
        fi
    fi
}

function log() {
    local TIMESTAMP=$(date +[%Y%m%d--%H:%M:%S])
    echo "$TIMESTAMP (${SCRIPT_PID}): $*"
    echo "$TIMESTAMP (${SCRIPT_PID}): $*" >> $LOG_FILE 2>&1
}

function log_exec() {
    log "$@";
    "$@" 2>&1 | tee -a $LOG_FILE
}

# replace_line file line regex globalflag
function replace_line() {
    local FILE STRING REGEX GLOBAL REPLACED
    FILE=$1
    STRING=$2
    REGEX=$3
    GLOBAL=${4:-false}
    REPLACED=false

    OFS=$IFS
    export IFS=
    while read -r line; do
        if [[ ${line} =~ ${REGEX} ]] && ( ! ${REPLACED} || ${GLOBAL} ); then
            echo "${STRING}"
            REPLACED=true
        else
            echo "${line}"
        fi
    done < "${FILE}"

    if ! ${REPLACED}; then echo "${STRING}"; fi
    IFS=$OFS
}

# add_line file line
function add_line() {
    local FILE STRING FOUND
    FILE=$1
    STRING=$2
    FOUND=false

    OFS=$IFS
    export IFS=
    while read -r line; do
        echo "${line}"
        if [[ "${line}" == "${STRING}" ]]; then
            FOUND=true
        fi
    done < "${FILE}"

    if ! ${FOUND}; then
        echo "${STRING}"
    fi
    IFS=$OFS
}

# write_line file line regex globalflag
function write_line() {
    local FILE STRING NEW_TEXT
    FILE=$1
    STRING=$2
    if [ "$#" -eq 2 ]; then
        F=add_line
    else
        F=replace_line
    fi

    if [ -f "${FILE}" ]; then
        NEW_TEXT=$($F "$@")
    else
        NEW_TEXT="${STRING}"
    fi
    echo "${NEW_TEXT}" > "${FILE}"
}

function check_apt_locks() {
    local LOCK_TIMEOUT=60
    local START_TIME=$(date +%s)
    local END_TIME=$(( START_TIME + LOCK_TIMEOUT ))
    while [ "$(date +%s)" -lt "$END_TIME" ]; do
        if lsof /var/lib/apt/lists/lock; then
            sleep 1
        else
            return 0
        fi
    done
    return 1
}

function add_user() {
    PASSWD_LENGTH=${1:-32}
    id -u ${USER_NAME} >/dev/null 2>&1 || \
        useradd ${USER_NAME} --shell /bin/bash --create-home --password ${USER_NAME}
    usermod -aG sudo ${USER_NAME}

    # Add Appveyor user to sudoers.d
    {
    echo -e "${USER_NAME}\tALL=(ALL)\tNOPASSWD: ALL"
    echo -e "Defaults:${USER_NAME}        !requiretty"
    } > /etc/sudoers.d/${USER_NAME}

    local PASSWD
    PASSWD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${PASSWD_LENGTH};)
    echo -e "${PASSWD}\n${PASSWD}\n" | passwd "${USER_NAME}"
    if "${LOGGING}"; then
        echo "PASSWD=${PASSWD}" >${HOME}/pwd-$DATEMARK.log
    fi
    return 0
}

function configure_network() {
    # configure eth interface to manual
    read -r IP_NUM IP_DEV IP_FAM IP_ADDR IP_REST <<< "$(ip -o -4 addr show up primary scope global)"

    #lets just hope there is no other interfaces after IP_DEV
    sed -i -r -e "s/^(iface ${IP_DEV}).*/\\1 inet manual/;/^(iface ${IP_DEV}).*/q" /etc/network/interfaces

    log_exec cat /etc/network/interfaces

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
        echo "${HOST_NAME}" > /etc/hostname
    fi
}

function configure_uefi() {
    if [ -d /boot/efi/EFI/ubuntu/ ] && [ ! -d /boot/efi/EFI/boot/ ]; then
        cp -r /boot/efi/EFI/ubuntu/ /boot/efi/EFI/boot/
    fi
    if [ -f /boot/efi/EFI/boot/shimx64.efi ] && [ ! -f /boot/efi/EFI/boot/bootx64.efi ]; then
        mv /boot/efi/EFI/boot/shimx64.efi /boot/efi/EFI/boot/bootx64.efi
    fi
    if [ -f /boot/efi/EFI/boot/mmx64.efi ]; then
        rm /boot/efi/EFI/boot/mmx64.efi
    fi
}

function configure_locale() {
    echo LANG=C.UTF-8 >/etc/default/locale
}

# https://askubuntu.com/a/755969
function wait_cloudinit () {
    log "waiting 180 seconds for cloud-init to update /etc/apt/sources.list"
    log_exec timeout 180 /bin/bash -c \
        'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting ...; sleep 1; done'
    log "Wait for cloud-init finished."
}

function configure_apt() {
    dpkg --add-architecture i386
    export DEBIAN_FRONTEND=noninteractive
    export ACCEPT_EULA=Y
    # Update packages.
    check_apt_locks || true
    apt-get -y -qq update && apt-get -y -q upgrade ||
        { echo "[ERROR] Cannot upgrade packages." 1>&2; return 10; }
    apt-get -y -q install software-properties-common ||
        { echo "[ERROR] Cannot install software-properties-common package." 1>&2; return 10; }

    # Disable daily apt unattended updates.
    write_line /etc/apt/apt.conf.d/10periodic 'APT::Periodic::Enable "0";' 'APT::Periodic::Enable '
    # configure appveyor env variables for future apt-get upgrades
    write_line "$USER_HOME/.profile" 'export DEBIAN_FRONTEND=noninteractive'
    write_line "$USER_HOME/.profile" 'export ACCEPT_EULA=Y'
    return 0
}

function install_tools() {
    declare tools_array
    # utilities
    tools_array=( "zip" "unzip" "wget" "curl" "time" "tree" "telnet" "dnsutils" "file" "ftp" "lftp" )
    tools_array+=( "p7zip-rar" "p7zip-full" "debconf-utils" "stress" "rng-tools"  "dkms" "dos2unix" )
    # build tools
    tools_array+=( "make" "binutils" "bison" "gcc" "tcl" )
    tools_array+=( "ant" "ant-optional" "maven" "gradle" "nuget" )
    # python packages
    tools_array+=( "python" "python-dev" "python3" )
    tools_array+=( "python-virtualenv" "virtualenv" "python-setuptools" )
    tools_array+=( "build-essential" "libssl-dev" "libcurl4-gnutls-dev" "libexpat1-dev" "libffi-dev" "gettext" )
    tools_array+=( "inotify-tools" "gfortran" "apt-transport-https" )
    tools_array+=( "libbz2-dev" "python3-tk" "tk-dev" "libsqlite3-dev" )
    # 32bit support
    tools_array+=( "libc6:i386" "libncurses5:i386" "libstdc++6:i386" )

    # Add release specific tools into tools_array
    if command -v add_releasespecific_tools; then
        add_releasespecific_tools
    fi

    # next packages required by KVP to communicate with HyperV
    if [ "${BUILD_AGENT_MODE}" = "HyperV" ]; then
#        tools_array+=( "linux-virtual-lts-${OS_CODENAME}" "linux-tools-virtual-lts-${OS_CODENAME}" "linux-cloud-tools-virtual-lts-${OS_CODENAME}" )
        tools_array+=( "linux-tools-generic" "linux-cloud-tools-generic" )
    fi
    sleep 5
    APT_GET_OPTIONS="-o Debug::pkgProblemResolver=true -o Debug::Acquire::http=true"
    apt-get -y ${APT_GET_OPTIONS} install "${tools_array[@]}" --no-install-recommends ||
        { 
            echo "[ERROR] Cannot install various packages. ERROR $?." 1>&2;
            apt-cache policy gcc 
            apt-cache policy zip
            apt-cache policy make
            return 10;
        }
    log_exec dpkg -l "${tools_array[@]}"
}

# this exact packages required to communicate with HyperV
function install_KVP_packages(){
    local KERNEL_VERSION
    # running kernel (which version returns uname -r) may differ from updated one
    KERNEL_VERSION=$(ls -tr /boot/initrd.img-* | tail -n1)
    KERNEL_VERSION=${KERNEL_VERSION#*-}
    if [[ -n $KERNEL_VERSION ]]; then
        declare tools_array
        tools_array+=( "linux-tools-${KERNEL_VERSION}" "linux-cloud-tools-${KERNEL_VERSION}" )
        apt-get -y -q install "${tools_array[@]}" --no-install-recommends  ||
            { echo "[ERROR] Cannot install KVP packages." 1>&2; return 10; }
    else
        echo "[ERROR] Cannot get kernels version." 1>&2;
        return 1
    fi
}

function copy_appveyoragent() {
    AGENT_FILE=appveyor-build-agent-linux-x64.tar.gz

    if [[ -z "${AGENT_DIR}" ]]; then { echo "[ERROR] AGENT_DIR variable is not set." 1>&2; return 10; } fi

    mkdir -p ${AGENT_DIR} &&
    #chown -R ${USER_NAME}:${USER_NAME} ${AGENT_DIR} &&
    pushd -- ${AGENT_DIR} ||
        { echo "[ERROR] Cannot create ${AGENT_DIR} folder." 1>&2; return 10; }

    if [ -f "${HOME}/distrib/${AGENT_FILE}" ]; then
        cp "${HOME}/distrib/${AGENT_FILE}" ./
    else
        curl -fsSL https://www.appveyor.com/downloads/appveyor-build-agent/7.0/linux/${AGENT_FILE} -o ${AGENT_FILE}
    fi &&
    tar -zxf ${AGENT_FILE} ||
        { echo "[ERROR] Cannot download and untar ${AGENT_FILE}." 1>&2; popd; return 20; }
    chmod +x ${AGENT_DIR}/appveyor ||
        { echo "[ERROR] Cannot change mode for ${AGENT_DIR}/appveyor file." 1>&2; popd; return 30; }
    popd
}

function install_appveyoragent() {
    AGENT_MODE=$1
    CONFIG_FILE=appsettings.json
    PROJECT_BUILDS_DIRECTORY="$USER_HOME"/projects
    SERVICE_NAME=appveyor-build-agent.service
    if [[ -z "${AGENT_DIR}" ]]; then { echo "[ERROR] AGENT_DIR variable is not set." 1>&2; return 10; } fi

    copy_appveyoragent || return "$1"

    if id -u ${USER_NAME}; then
        chown -R ${USER_NAME}:${USER_NAME} ${AGENT_DIR}
    fi

    pushd -- ${AGENT_DIR} ||
        { echo "[ERROR] Cannot cd to ${AGENT_DIR} folder." 1>&2; return 10; }

    [ -f ${CONFIG_FILE} ] &&
        python -c "import json; import io;
a=json.load(io.open('${CONFIG_FILE}', encoding='utf-8-sig'));
a[u'AppVeyor'][u'Mode']='${AGENT_MODE}';
a[u'AppVeyor'][u'ProjectBuildsDirectory']='${PROJECT_BUILDS_DIRECTORY}';
json.dump(a,open('${CONFIG_FILE}','w'))" &&
        cat ${CONFIG_FILE} ||
        { echo "[ERROR] Cannot update config file '${CONFIG_FILE}'." 1>&2; popd; return 40; }

    echo "[Unit]
Description=Appveyor Build Agent

[Service]
WorkingDirectory=${AGENT_DIR}
ExecStart=${AGENT_DIR}/appveyor-build-agent
Restart=no
SyslogIdentifier=appveyor-build-agent
User=appveyor
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=TERM=xterm-256color

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/${SERVICE_NAME} &&
    systemctl enable ${SERVICE_NAME} &&
    systemctl start ${SERVICE_NAME} &&
    systemctl status ${SERVICE_NAME} --no-pager ||
        { echo "[ERROR] Cannot configure systemd ${SERVICE_NAME}." 1>&2; popd; return 50; }
    log_exec ${AGENT_DIR}/appveyor Version
    popd

}

function install_buildagent_docker() {
    AGENT_FILE=appveyor-build-agent-linux-x64.tar.gz

    if [[ -z "${AGENT_DIR}" ]]; then { echo "[ERROR] AGENT_DIR variable is not set." 1>&2; return 10; } fi

    mkdir -p ${AGENT_DIR} &&
    #chown -R ${USER_NAME}:${USER_NAME} ${AGENT_DIR} &&
    pushd -- ${AGENT_DIR} ||
        { echo "[ERROR] Cannot create ${AGENT_DIR} folder." 1>&2; return 10; }

    if [ -f "${HOME}/distrib/${AGENT_FILE}" ]; then
        cp "${HOME}/distrib/${AGENT_FILE}" ./
    else
        curl -fsSL https://www.appveyor.com/downloads/appveyor-build-agent/7.0/linux/${AGENT_FILE} -o ${AGENT_FILE}
    fi &&
    tar -zxf ${AGENT_FILE} ||
        { echo "[ERROR] Cannot download and untar ${AGENT_FILE}." 1>&2; popd; return 20; }

    chmod +x ${AGENT_DIR}/appveyor ||
        { echo "[ERROR] Cannot change mode for ${AGENT_DIR}/appveyor file." 1>&2; popd; return 30; }

    popd

}

# install dotnet prior executing this function, otherwise systemd will be configured incorrectly.
# This one is an old approach and was deprecated.
function install_buildagent() {
    AGENT_MODE=$1
    AGENT_FILE=appveyor-build-agent-xplat.zip
    CONFIG_FILE=appsettings.json
    PROJECT_BUILDS_DIRECTORY="$USER_HOME"/projects
    SERVICE_NAME=appveyor-build-agent.service

    if [[ -z "${AGENT_DIR}" ]]; then { echo "[ERROR] AGENT_DIR variable is not set." 1>&2; return 10; } fi

    mkdir -p ${AGENT_DIR} &&
    chown -R ${USER_NAME}:${USER_NAME} ${AGENT_DIR} &&
    pushd -- ${AGENT_DIR} ||
        { echo "[ERROR] Cannot create ${AGENT_DIR} folder." 1>&2; return 10; }

    if [ -f "${HOME}/distrib/${AGENT_FILE}" ]; then
        cp "${HOME}/distrib/${AGENT_FILE}" ./
    else
        curl -fsSL https://www.appveyor.com/downloads/build-agent-xplat/1.0.0/appveyor-build-agent-xplat.zip -o ${AGENT_FILE}
    fi &&
    unzip -q -o ${AGENT_FILE} ||
        { echo "[ERROR] Cannot download and unzip ${AGENT_FILE}." 1>&2; popd; return 20; }

    chmod +x ${AGENT_DIR}/appveyor ||
        { echo "[ERROR] Cannot change mode for ${AGENT_DIR}/appveyor file." 1>&2; popd; return 30; }

    [ -f ${CONFIG_FILE} ] &&
        python -c "import json; import io;
a=json.load(io.open('${CONFIG_FILE}', encoding='utf-8-sig'));
a[u'Agent'][u'Mode']='${AGENT_MODE}';
a[u'Agent'][u'ProjectBuildsDirectory']='${PROJECT_BUILDS_DIRECTORY}';
json.dump(a,open('${CONFIG_FILE}','w'))" &&
        cat ${CONFIG_FILE} ||
        { echo "[ERROR] Cannot update config file '${CONFIG_FILE}'." 1>&2; popd; return 40; }

    echo "[Unit]
Description=Appveyor Build Agent

[Service]
WorkingDirectory=${AGENT_DIR}
ExecStart=$(which dotnet) ${AGENT_DIR}/Appveyor.BuildAgent.Service.dll
Restart=no
SyslogIdentifier=appveyor-build-agent
User=appveyor
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=TERM=xterm-256color

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/${SERVICE_NAME} &&
    systemctl enable ${SERVICE_NAME} &&
    systemctl start ${SERVICE_NAME} &&
    systemctl status ${SERVICE_NAME} --no-pager ||
        { echo "[ERROR] Cannot configure systemd ${SERVICE_NAME}." 1>&2; popd; return 50; }
    log_exec ${AGENT_DIR}/appveyor Version
    popd

    # This module was deprecated
    # add_appveyor_module "${AGENT_DIR}"
}

function install_nodejs() {
    curl -fsSL https://deb.nodesource.com/setup_6.x | bash - &&
    apt-get -y -q install nodejs &&
    npm install -g pm2 ||
        { echo "[ERROR] Something went wrong."; return 100; }
    log_exec dpkg -l nodejs
}

function install_nvm() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    #TODO have to figure out latest release version automatically
    curl -fsSLo- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash

    write_line "${HOME}/.profile" 'export NVM_DIR="$HOME/.nvm"'
    write_line "${HOME}/.profile" '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'
    write_line "${HOME}/.profile" '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion'
}

function install_nvm_nodejs() {
    local CURRENT_NODEJS=$1
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    command -v nvm ||
        { echo "Cannot find nvm. Install nvm first!" 1>&2; return 10; }
    local v
    declare NVM_VERSIONS=( "4" "5" "6" "7" "8" "9" "10" "11" "lts/argon" "lts/boron" "lts/carbon" )
    for v in "${NVM_VERSIONS[@]}"; do
        nvm install ${v} ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
    log_exec nvm --version
    log_exec nvm list
    nvm use ${CURRENT_NODEJS}
}

function make_git() {
    GIT_VERSION=$1
    if command -v git && [[ $(git --version) =~ ${GIT_VERSION} ]]; then
        echo "[WARNING] git version ${GIT_VERSION} already installed.";
        return 0
    fi
    TMP_DIR=$(mktemp -d)
    pushd -- ${TMP_DIR}
    curl -fsSL https://github.com/git/git/archive/v${GIT_VERSION}.zip -o git-${GIT_VERSION}.zip ||
        { echo "[ERROR] Cannot download git ${GIT_VERSION}." 1>&2; popd; return 10; }
    DIR_NAME=$(unzip -l git-${GIT_VERSION}.zip | awk 'NR>4{sub(/\/.*/,"",$4);print $4;}'|sort|uniq|tr -d '\n')
    [ -d ${DIR_NAME} ] && rm -rf ${DIR_NAME} || true
    unzip -q -o git-${GIT_VERSION}.zip ||
        { echo "[ERROR] Cannot unzip git-${GIT_VERSION}.zip." 1>&2; popd; return 20; }
    cd -- ${DIR_NAME} || { echo "[ERROR] Cannot cd into ${DIR_NAME}. Something went wrong." 1>&2; popd; return 30; }
    #build
    make --silent prefix=/usr/local all &&
        make --silent prefix=/usr/local install ||
        { echo "Make command failed." 1>&2; popd; return 40; }

    # cleanup
    popd && rm -rf ${TMP_DIR}
    log_exec git --version
}

function install_gitlfs() {
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash &&
    apt-get -y -q install git-lfs ||
        { echo "Failed to install git lfs." 1>&2; return 10; }
    log_exec dpkg -l git-lfs
}

function configure_gitlfs() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    git lfs install ||
        { echo "Failed to configure git lfs." 1>&2; return 10; }
}

function install_cvs() {
    # install git
    # at this time there is git version 2.7.4 in apt repos
    # in case if we need recent version we have to run make_git function
    apt-get -y -q install git

    #install Mercurial
    add-apt-repository -y ppa:mercurial-ppa/releases
    apt-get -y -qq update
    apt-get -y -q install mercurial

    #install subversion
    apt-get -y -q install subversion

    log_exec dpkg -l git mercurial subversion
}

function configure_svn() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    pushd ${HOME}
    mkdir -p .subversion &&
    echo "[global]
store-passwords = yes
store-plaintext-passwords = yes" > .subversion/servers &&
    echo "[auth]
password-stores =" > .subversion/config ||
        { echo "[ERROR] Cannot configure svn." 1>&2; popd; return 10; }
    popd
}

function install_pip() {
    easy_install pip ||
        { echo "[WARNING] Cannot install pip." ; return 10; }

    # update all system's Python packages - Somehow this lead to inability to login via SSH later. 
    # I suppose it is because pip updates google's packages in system Python.
    # pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U

    log_exec pip --version
}

function install_pythons(){
    declare PY_VERSIONS=( "2.6.9" "2.7.16" "3.4.9" "3.5.6" "3.6.8" "3.7.0" "3.7.1" "3.7.2" "3.8.0" )
    for i in "${PY_VERSIONS[@]}"; do
        VENV_PATH=${HOME}/venv${i%[abrcf]*}
        if [ ! -d ${VENV_PATH} ]; then
        curl -fsSL -O http://www.python.org/ftp/python/${i%[abrcf]*}/Python-${i}.tgz ||
            { echo "[WARNING] Cannot download Python ${i}."; continue; }
        tar -zxf Python-${i}.tgz &&
        pushd Python-${i} ||
            { echo "[WARNING] Cannot unpack Python ${i}."; continue; }
        PY_PATH=${HOME}/.localpython${i}
        mkdir -p ${PY_PATH}
        ./configure --silent --prefix=${PY_PATH} &&
        make --silent &&
        make install --silent >/dev/null ||
            { echo "[WARNING] Cannot make Python ${i}."; popd; continue; }
        if [ ${i:0:1} -eq 3 ]; then
            PY_BIN=python3
        else
            PY_BIN=python
        fi
        virtualenv -p $PY_PATH/bin/${PY_BIN} ${VENV_PATH} ||
            { echo "[WARNING] Cannot make virtualenv for Python ${i}."; popd; continue; }
        popd
        fi
    done
    rm -rf ${HOME}/Python-*
}

function install_powershell() {
    # Import the public repository GPG keys
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - &&
    # Register the Microsoft Ubuntu repository
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/${OS_RELEASE}/prod.list)" ||
        { echo "[ERROR] Cannot add Microsoft's APT source." 1>&2; return 10; }

    # Update the list of products and Install PowerShell
    apt-get -y -qq update &&
    apt-get -y -q --allow-downgrades install powershell ||
        { echo "[ERROR] PowerShell install failed." 1>&2; return 10; }

    configure_powershell

    # Start PowerShell
    log_exec pwsh --version
}

function configure_powershell() {
    if [[ -z "${AGENT_DIR}" ]]; then { echo "[ERROR] AGENT_DIR variable is not set." 1>&2; return 10; } fi
    if [[ -z "${USER_HOME}" ]]; then { echo "[ERROR] USER_HOME variable is not set." 1>&2; return 20; } fi
    local PROFILE_PATH=${USER_HOME}/.config/powershell
    local PROFILE_NAME=Microsoft.PowerShell_profile.ps1
    # configure PWSH profile
    mkdir -p ${PROFILE_PATH} &&
    write_line "${PROFILE_PATH}/${PROFILE_NAME}" "Import-Module ${AGENT_DIR}/Appveyor.BuildAgent.PowerShell.dll" ||
        { echo "[ERROR] Cannot create and change PWSH profile ${PROFILE_PATH}/${PROFILE_NAME}." 1>&2; return 30; }

    pwsh -c 'Install-Module Pester -Force'
}

# This module was deprecated
function add_appveyor_module() {
    if [[ -z "${AGENT_DIR}" ]]; then { echo "[ERROR] AGENT_DIR variable is not set." 1>&2; return 10; } fi
    if [[ -z "${USER_HOME}" ]]; then { echo "[ERROR] USER_HOME variable is not set." 1>&2; return 20; } fi
    local MODULES_PATH=${USER_HOME}/.local/share/powershell/Modules/Appveyor/
    mkdir -p ${MODULES_PATH} &&
    for file in "Appveyor.BuildAgent.Api.dll" "Appveyor.BuildAgent.Models.dll" "Appveyor.BuildAgent.PowerShell.dll"; do
        cp "${AGENT_DIR}/${file}" "${MODULES_PATH}" ||
            { echo "[ERROR] Cannot copy '${AGENT_DIR}/${file}' to '${MODULES_PATH}'." 1>&2; return 30; }
    done
    echo "@{
RootModule = 'Appveyor.BuildAgent.PowerShell.dll'
ModuleVersion = '1.0'
GUID = '1a9a19d4-28de-4d1f-aa44-aecf16b423cb'
Author = 'Vasily Pleshakov'
CompanyName = 'Appveyor Systems Inc.'
Copyright = '(c) Appveyor Systems Inc. All rights reserved.'
FunctionsToExport = '*'
CmdletsToExport = '*'
VariablesToExport = '*'
AliasesToExport = '*'
PrivateData = @{
    PSData = @{
    }
}
}
" > ${MODULES_PATH}/Appveyor.psd1
}

function dotnet_packages() {
    local PREFIX=$1
    declare -a VERSIONS=("${!2}")
    local i
    for i in "${VERSIONS[@]}"; do
        PACKAGES+=( "${PREFIX}${i}" )
    done
}

function global_json() {
    echo "{
  \"sdk\": {
    \"version\": \"$1\"
  }
}"

}

function preheat_dotnet_sdks() {
    declare SDK_VERSIONS=("$@")
    for i in "${SDK_VERSIONS[@]}"; do
        TMP_DIR=$(mktemp -d)
        pushd  ${TMP_DIR}
        global_json ${i} >global.json
        dotnet new console
        popd
        rm -r ${TMP_DIR}
    done
}

function prepare_dotnet_packages() {
    SDK_VERSIONS=( "2.0.0" "2.0.2" "2.0.3" "2.1.2" "2.1.3" "2.1.4" "2.1.101" "2.1.103" "2.1.104" "2.1.105" "2.1.200" "2.1.201" "2.1.202" "2.1" "2.2" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]

    declare RUNTIME_VERSIONS=( "2.0.0" "2.0.3" "2.0.4" "2.0.5" "2.0.6" "2.0.7" "2.0.9" "2.1" "2.2" )
    dotnet_packages "dotnet-runtime-" RUNTIME_VERSIONS[@]

    declare DEV_VERSIONS=( "1.1.5" "1.1.6" "1.1.7" "1.1.8" "1.1.9" "1.1.10" "1.1.11" "1.1.12" )
    dotnet_packages "dotnet-dev-" DEV_VERSIONS[@]
}

function config_dotnet_repository() {
    curl -fsSL -O https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb &&
    dpkg -i packages-microsoft-prod.deb &&
    apt-get -y -qq update ||
        { echo "[ERROR] Cannot download and install Microsoft's APT source." 1>&2; return 10; }
}

function install_dotnets() {
    prepare_dotnet_packages
    config_dotnet_repository

    #TODO REPO_LIST might be empty
    REPO_LIST=$(apt-cache search dotnet-)
    for i in "${!PACKAGES[@]}"; do
        if [[ ! ${REPO_LIST} =~ ${PACKAGES[i]} ]]; then
            echo "[WARNING] ${PACKAGES[i]} package not found in apt repositories. Skipping it."
            unset 'PACKAGES[i]'
        fi
    done
    #TODO PACKAGES might be empty

    # it seems like there is dependency for mysql somethere in dotnet-* packages
    configure_apt_mysql

    apt-get -y -q install --no-install-recommends "${PACKAGES[@]}" ||
        { echo "[ERROR] Cannot install dotnet packages ${PACKAGES[*]}." 1>&2; return 20; }

    #set env
    write_line "$USER_HOME/.profile" "export DOTNET_CLI_TELEMETRY_OPTOUT=1" 'DOTNET_CLI_TELEMETRY_OPTOUT='
    write_line "$USER_HOME/.profile" "export DOTNET_PRINT_TELEMETRY_MESSAGE=false" 'DOTNET_PRINT_TELEMETRY_MESSAGE='

    #cleanup
    if [ -f packages-microsoft-prod.deb ]; then rm packages-microsoft-prod.deb; fi

    #pre-heat
    preheat_dotnet_sdks "${SDK_VERSIONS[@]}"
}

function install_mono() {
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF &&
    add-apt-repository "deb http://download.mono-project.com/repo/ubuntu stable-${OS_CODENAME} main" ||
        { echo "[ERROR] Cannot add Mono repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install mono-complete mono-dbg referenceassemblies-pcl mono-xsp4 ||
        { echo "[ERROR] Cannot install Mono." 1>&2; return 20; }

    log_exec mono --version
    log_exec csc
    log_exec xsp4 --version
    log_exec mcs --version
}

function install_jdks() {
    add-apt-repository -y ppa:openjdk-r/ppa
    apt-get -y -qq update && {
        apt-get -y -q install --no-install-recommends openjdk-7-jdk
        apt-get -y -q install --no-install-recommends openjdk-8-jdk
#        apt-get -y -q install --no-install-recommends openjdk-9-jdk -o Dpkg::Options::="--force-overwrite"
    } ||
        { echo "[ERROR] Cannot install JDKs." 1>&2; return 10; }
    update-java-alternatives --set java-1.8.0-openjdk-amd64
}

function install_jdk() {
    local JDK_VERSION=$1
    local JDK_URL="$2"
    local JDK_ARCHIVE=${JDK_URL##*/}
    local JDK_PATH JDK_LINK
    JDK_PATH=/usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64/
    JDK_LINK=/usr/lib/jvm/java-1.${JDK_VERSION}.0-openjdk-amd64

    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"

    curl -fsSL -O "${JDK_URL}" &&
    tar zxf "${JDK_ARCHIVE}" ||
        { echo "[ERROR] Cannot download and unpack JDK 10." 1>&2; popd; return 10; }
    DIR_NAME=$(tar tf "${JDK_ARCHIVE}" |cut -d'/' -f1|sort|uniq|head -n1)
    mkdir -p ${JDK_PATH} &&
    cp -R "${DIR_NAME}"/* "${JDK_PATH}" &&
    ln -s -f "${JDK_PATH}" "${JDK_LINK}" ||
        { echo "[ERROR] Cannot copy JDK 10 to /usr/lib/jvm." 1>&2; popd; return 20; }

    PROFILE_LINES+=( "export JAVA_HOME_${JDK_VERSION}_X64=${JDK_PATH}" )

    # cleanup
    rm -rf "${DIR_NAME}"
    rm "${JDK_ARCHIVE}"
    popd
}

function configure_jdk() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    local file

    write_line "${HOME}/.profile" 'export JAVA_HOME_7_X64=/usr/lib/jvm/java-7-openjdk-amd64'
    write_line "${HOME}/.profile" 'export JAVA_HOME_8_X64=/usr/lib/jvm/java-8-openjdk-amd64'
    while read -r line; do
        write_line "${HOME}/.profile" "${line}"
    done
    write_line "${HOME}/.profile" 'export JAVA_HOME=/usr/lib/jvm/java-9-openjdk-amd64'
    write_line "${HOME}/.profile" 'export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8'
    write_line "${HOME}/.profile" 'add2path $JAVA_HOME/bin'
}

function install_rvm() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    # Install mpapis public key (might need `gpg2` and or `sudo`)
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

    # Download the installer
    curl -fsSL -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer &&
    curl -fsSL -O https://raw.githubusercontent.com/rvm/rvm/master/binscripts/rvm-installer.asc ||
        { echo "[ERROR] Cannot download rvm-installer." 1>&2; return 10; }

    # Verify the installer signature (might need `gpg2`), and if it validates...
    gpg --verify rvm-installer.asc &&

    # Run the installer
    bash rvm-installer stable ||
        { echo "[ERROR] Cannot install RVM." 1>&2; return 20; }

    # cleanup
    rm rvm-installer rvm-installer.asc
}

function install_rubies() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    command -v rvm ||
        { echo "Cannot find rvm. Install rvm first!" 1>&2; return 10; }
    local v
    declare RUBY_VERSIONS=( "ruby-2.0" "ruby-2.1" "ruby-2.2" "ruby-2.3" "ruby-2.4" "ruby-2.5" "ruby-2.6" "ruby-head" )
    for v in "${RUBY_VERSIONS[@]}"; do
        rvm install ${v} ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
    log_exec rvm --version
    log_exec rvm list
}

function install_gvm(){
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    if [[ -s "${HOME}/.gvm/scripts/gvm" ]]; then
        echo "[WARNING] GVM already installed."
        command -v gvm
        gvm version
    else
        for pkg in curl git mercurial make binutils bison gcc build-essential; do
            dpkg -s ${pkg} ||
                { echo "[WARNING] $pkg is not installed! GVM may fail." 1>&2; }
        done
        bash < <(curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer) ||
            { echo "[ERROR] Cannot install GVM." 1>&2; return 10; }
    fi
    # gvm-installer do not fix .profile for non-interactive shell
    [[ -s "${HOME}/.gvm/scripts/gvm" ]] && (
        local file
        for file in "${HOME}/.profile"; do
            write_line "${file}" '[[ -s "/home/appveyor/.gvm/scripts/gvm" ]] && source "/home/appveyor/.gvm/scripts/gvm"'
        done
    ) || true
}

function install_golangs() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    command -v gvm && gvm version ||
        { echo "Cannot find or execute gvm. Install gvm first!" 1>&2; return 10; }
    gvm install go1.4 -B &&
    gvm use go1.4 ||
        { echo "[WARNING] Cannot install go1.4 from binaries." 1>&2; return 10; }
    declare GO_VERSIONS=( "go1.7.6" "go1.8.7" "go1.9.7" "go1.10.8" "go1.11.5" "go1.12" )
    for v in "${GO_VERSIONS[@]}"; do
        gvm install ${v} ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
    gvm use ${GO_VERSIONS[-1]} --default
    log_exec gvm version
    log_exec go version
}

function install_docker() {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - &&
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${OS_CODENAME} stable" ||
        { echo "[ERROR] Cannot add Docker repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install docker-ce ||
        { echo "[ERROR] Cannot install Docker." 1>&2; return 20; }
    systemctl start docker &&
    systemctl is-active docker ||
        { echo "[ERROR] Docker service failed to start." 1>&2; return 30; }
    usermod -aG docker ${USER_NAME}
    systemctl disable docker

    log_exec dpkg -l docker-ce
}

function install_sqlserver() {
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - &&
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2017.list)" ||
        { echo "[ERROR] Cannot add mssql-server repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install mssql-server ||
        { echo "[ERROR] Cannot install mssql-server." 1>&2; return 20; }
    MSSQL_SA_PASSWORD=$MSSQL_SA_PASSWORD \
        MSSQL_PID=developer \
        /opt/mssql/bin/mssql-conf -n setup accept-eula ||
        { echo "[ERROR] Cannot configure mssql-server." 1>&2; return 30; }

    ACCEPT_EULA=Y apt-get -y -q install mssql-tools unixodbc-dev
    systemctl restart mssql-server
    systemctl is-active mssql-server ||
        { echo "[ERROR] mssql-server service failed to start." 1>&2; return 40; }
    log_exec dpkg -l mssql-server
}

function configure_sqlserver() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != ${USER_NAME} ]; then
        echo "This script must be run as ${USER_NAME}. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    if [[ -z "${MSSQL_SA_PASSWORD}" ]]; then
        echo "MSSQL_SA_PASSWORD variable not set!" 1>&2
        return 2
    fi
    # Add SQL Server tools to the path by default:
    local file
    write_line "${HOME}/.profile" 'add2path_suffix /opt/mssql-tools/bin'
    export PATH="$PATH:/opt/mssql-tools/bin"
    
    local counter=1
    local errstatus=1
    while [ $counter -le 30 ] && [ $errstatus = 1 ]; do
        echo Waiting for SQL Server to start...
        sleep 10s
        sqlcmd -S localhost -U SA -P ${MSSQL_SA_PASSWORD} -Q "SELECT @@VERSION"
        errstatus=$?
        echo "errstatus=${errstatus}"
        ((counter++))
    done
    if [ $errstatus = 1 ]; then
        systemctl status mssql-server
        echo "Cannot connect to SQL Server." 1>&2
        return 10
    fi
}

function disable_sqlserver() {
    systemctl disable mssql-server
}

function configure_apt_mysql() {
    echo "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections &&
    echo "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections ||
        { echo "[ERROR] Cannot set apt's parameters for MySQL package." 1>&2; return 10;}
}

function install_mysql() {
    configure_apt_mysql

    apt-get -y -q install mysql-server ||
        { echo "[ERROR] Cannot install MySQL." 1>&2; return 10;}
    systemctl start mysql
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e 'USE mysql; SELECT Host,User FROM `user`;' ||
        { echo "[ERROR] Cannot connect to MySQL locally." 1>&2; return 20;}
    systemctl disable mysql
    log_exec dpkg -l mysql-server
}

function install_postgresql() {
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - &&
    add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ ${OS_CODENAME}-pgdg main" ||
        { echo "[ERROR] Cannot add postgresql repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install postgresql ||
        { echo "[ERROR] Cannot install postgresql." 1>&2; return 20; }
    systemctl start postgresql
    systemctl disable postgresql
    log_exec dpkg -l postgresql

    sudo -u postgres createuser ${USER_NAME}
    sudo -u postgres psql -c "alter user ${USER_NAME} with createdb" postgres
    sudo -u postgres psql -c "ALTER USER postgres with password '${POSTGRES_ROOT_PASSWORD}';" postgres
    replace_line '/etc/postgresql/11/main/pg_hba.conf' 'local   all             postgres                                trust' 'local\s+all\s+postgres\s+peer'
}

function install_mongodb() {
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 &&
    add-apt-repository "deb http://repo.mongodb.org/apt/ubuntu ${OS_CODENAME}/mongodb-org/3.2 multiverse" ||
        { echo "[ERROR] Cannot add mongodb repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install mongodb-org ||
        { echo "[ERROR] Cannot install mongodb." 1>&2; return 20; }
    echo "[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target

[Service]
User=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/mongodb.service &&
    systemctl start mongodb &&
    systemctl status mongodb --no-pager &&
    systemctl enable mongodb &&
    systemctl disable mongodb ||
        { echo "[ERROR] Cannot configure mongodb." 1>&2; return 30; }
    log_exec dpkg -l mongodb-org
}

function install_redis() {
    if command -v redis-server && redis-server --version; then
        echo "[WARNING] Redis server already installed."
        return 0
    fi
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    local WORKING_DIR=/var/lib/redis
    pushd -- "${TMP_DIR}"
    curl -fsSL -O http://download.redis.io/redis-stable.tar.gz &&
    tar xzf redis-stable.tar.gz &&
    cd redis-stable ||
        { echo "[ERROR] Cannot download and unpack redis-stable." 1>&2; popd; return 10; }
    make --silent &&
#    make --silent test &&
    make --silent install ||
        { echo "[ERROR] Cannot make redis." 1>&2; popd; return 20; }

    sed -ibak -E -e 's/^supervised .*/supervised systemd/' -e "s:^dir .*:dir ${WORKING_DIR}:" redis.conf

    mkdir -p /etc/redis &&
    cp redis.conf /etc/redis
    echo "[Unit]
Description=Redis In-Memory Data Store
After=network.target
[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always" > /etc/systemd/system/redis.service
    adduser --system --group --no-create-home redis &&
    mkdir -p ${WORKING_DIR} &&
    chown redis:redis ${WORKING_DIR} &&
    chmod 770 ${WORKING_DIR}

    systemctl enable redis &&
    systemctl disable redis
    popd
    log_exec redis-server --version
}

function install_rabbitmq() {
    curl -fsSL https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc | apt-key add - &&
    curl -fsSL http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add - &&
    add-apt-repository "deb http://www.rabbitmq.com/debian/ testing main" ||
        { echo "[ERROR] Cannot add rabbitmq repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install rabbitmq-server ||
        { echo "[ERROR] Cannot install rabbitmq." 1>&2; return 20; }
    sed -ibak -E -e 's/#\s*ulimit/ulimit/' /etc/default/rabbitmq-server &&
    systemctl start rabbitmq-server &&
    systemctl status rabbitmq-server --no-pager &&
    systemctl enable rabbitmq-server &&
    systemctl disable rabbitmq-server ||
        { echo "[ERROR] Cannot configure rabbitmq." 1>&2; return 30; }
    log_exec dpkg -l rabbitmq-server
}

function install_p7zip() {
    local TMP_DIR=$(mktemp -d)
    pushd -- ${TMP_DIR}
    curl -fsSL -O https://sourceforge.net/projects/p7zip/files/p7zip/16.02/p7zip_16.02_src_all.tar.bz2 &&
    tar jxf p7zip_16.02_src_all.tar.bz2 ||
        { echo "[ERROR] Cannot download and unpack p7zip source code." 1>&2; popd; return 10; }
    cd p7zip_16.02
    make --silent all &&
    ./install.sh ||
        { echo "[ERROR] Cannot build and install p7zip." 1>&2; popd; return 20; }
    popd
    rm -rf ${TMP_DIR}
}

function install_packer() {
    local VERSION=$1
    local ZIPNAME=packer_${VERSION}_linux_amd64.zip
    curl -fsSL -O https://releases.hashicorp.com/packer/${VERSION}/${ZIPNAME} &&
    unzip -q -o ${ZIPNAME} -d /usr/local/bin ||
        { echo "[ERROR] Cannot download and unzip packer." 1>&2; return 10; }
    log_exec packer --version
    # cleanup
    [ -f "${ZIPNAME}" ] && rm -f "${ZIPNAME}" || true
}

function install_yarn() {
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&
    add-apt-repository "deb https://dl.yarnpkg.com/debian/ stable main" ||
        { echo "[ERROR] Cannot add yarn repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install --no-install-recommends yarn ||
        { echo "[ERROR] Cannot install yarn." 1>&2; return 20; }
    log_exec yarn --version
}

function install_awscli() {
    pip install awscli ||
        { echo "[ERROR] Cannot install awscli." 1>&2; return 10; }
    log_exec aws --version
}

function install_localstack() {
    pip install localstack ||
        { echo "[ERROR] Cannot install localstack." 1>&2; return 10; }
    # since version 0.8.8 localstack requires but do not have in dependencies amazon_kclpy
    pip install amazon_kclpy ||
        { echo "[ERROR] Cannot install amazon_kclpy which is required by localstack." 1>&2; return 20; }
    log_exec localstack --version
}

function install_gcloud() {
    CLOUD_SDK_REPO="cloud-sdk-${OS_CODENAME}"
    add-apt-repository "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" &&
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - &&
    apt-get -y -qq update &&
    apt-get -y -q install google-cloud-sdk ||
        { echo "[ERROR] Cannot install google-cloud-sdk." 1>&2; return 10; }
}

function install_azurecli() {
    AZ_REPO=${OS_CODENAME}
    add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" ||
        { echo "[ERROR] Cannot add azure-cli repository to APT sources." 1>&2; return 10; }
    apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893 &&
    apt-get -y -q install apt-transport-https &&
    apt-get -y -qq update &&
    apt-get -y -q install azure-cli ||
        { echo "[ERROR] Cannot instal azure-cli."; return 20; }
    log_exec az --version
}

function install_cmake() {
    local VERSION=$1
    local TAR_FILE=cmake-${VERSION}-Linux-x86_64.tar.gz
    local TMP_DIR=$(mktemp -d)
    pushd -- ${TMP_DIR}
    curl -fsSL -O https://cmake.org/files/v${VERSION%.*}/${TAR_FILE} &&
    tar -zxf ${TAR_FILE} ||
        { echo "[ERROR] Cannot download and untar cmake." 1>&2; popd; return 10; }
    DIR_NAME=$(tar -ztf ${TAR_FILE} |cut -d'/' -f1|sort|uniq|head -n1)
    cd -- ${DIR_NAME} ||
        { echo "[ERROR] Cannot change directory to ${DIR_NAME}." 1>&2; popd; return 20; }
    [ -d "/usr/share/cmake-${VERSION%.*}" ] && rm -rf "/usr/share/cmake-${VERSION%.*}" || true
    mv -f ./bin/* /usr/bin/ &&
    mv -f ./share/cmake-${VERSION%.*} /usr/share/ &&
    mv -f ./share/aclocal/* /usr/share/aclocal/||
        { echo "[ERROR] Cannot install cmake." 1>&2; popd; return 30; }
    log_exec cmake --version
    popd
}

function update_nuget() {
    nuget update -self ||
        { echo "[ERROR] Cannot update nuget."; return 10; }
}

function install_kubectl() {
    KUBE_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl" &&
    chmod +x ./kubectl &&
    mv -f ./kubectl /usr/local/bin/kubectl ||
        { echo "[ERROR] Cannot download and install kubectl."; return 10; }
}

function install_gcc() {
    # add existing gcc's to alternatives
    if [[ -f /usr/bin/gcc-5 ]] && [[ -f /usr/bin/g++-5 ]]; then
        update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 60 --slave /usr/bin/g++ g++ /usr/bin/g++-5 ||
            { echo "[ERROR] Cannot install gcc-8." 1>&2; return 10; }
    fi
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get -y -qq update ||
        { echo "[ERROR] Cannot add gcc repository to APT sources." 1>&2; return 20; }
    apt-get -y -q install gcc-7 g++-7 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-7 ||
        { echo "[ERROR] Cannot install gcc-7." 1>&2; return 30; }
    apt-get -y -q install gcc-8 g++-8 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 60 --slave /usr/bin/g++ g++ /usr/bin/g++-8 ||
        { echo "[ERROR] Cannot install gcc-8." 1>&2; return 40; }

}

function install_curl() {
    local VERSION=$1
    local TAR_FILE=curl-${VERSION}.tar.gz
    local TMP_DIR=$(mktemp -d)
    pushd -- ${TMP_DIR}
    curl -fsSL -O https://curl.haxx.se/download/${TAR_FILE} &&
    tar -zxf ${TAR_FILE} ||
        { echo "[ERROR] Cannot download and untar curl." 1>&2; popd; return 10; }
    DIR_NAME=$(tar -ztf ${TAR_FILE} |cut -d'/' -f1|sort|uniq|head -n1)
    cd -- ${DIR_NAME} ||
        { echo "[ERROR] Cannot change directory to ${DIR_NAME}." 1>&2; popd; return 20; }
    ./configure &&
    make &&
    make install ||
        { echo "[ERROR] Cannot make curl." 1>&2; popd; return 30; }
    log_exec curl --version
    popd
}

function install_browsers() {
    local DEBNAME=google-chrome-stable_current_amd64.deb
    add-apt-repository -y ppa:ubuntu-mozilla-security/ppa &&
    apt-get -y -qq update &&
    apt-get -y -q install libappindicator1 fonts-liberation xvfb ||
        { echo "[ERROR] Cannot install libappindicator1 and fonts-liberation." 1>&2; return 10; }
    curl -fsSL -O https://dl.google.com/linux/direct/${DEBNAME}
    dpkg -i ${DEBNAME}
    apt-get -y -q install firefox
    log_exec dpkg -l firefox google-chrome-stable
    #cleanup
    [ -f "${DEBNAME}" ] && rm -f "${DEBNAME}" || true
}

# they have changed versioning and made Debain Repo. see https://www.virtualbox.org/wiki/Linux_Downloads
# https://download.virtualbox.org/virtualbox/6.0.6/virtualbox-6.0_6.0.6-130049~Ubuntu~bionic_amd64.deb
# https://download.virtualbox.org/virtualbox/6.0.6/virtualbox-6.0_6.0.6-130049~Ubuntu~xenial_amd64.deb
function install_virtualbox() {
    local VB_VERSION=${1%.*}
    local VBE_URL=https://download.virtualbox.org/virtualbox/${1}/Oracle_VM_VirtualBox_Extension_Pack-${1}.vbox-extpack

    echo "deb http://download.virtualbox.org/virtualbox/debian ${OS_CODENAME} contrib" >/etc/apt/sources.list.d/virtualboxorg.list &&
    curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | apt-key add - ||
        { echo "[ERROR] Cannot add virtualbox.org repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install virtualbox-${VB_VERSION} ||
        { echo "[ERROR] Cannot install virtualbox-${VB_VERSION}." 1>&2; return 20; }
    usermod -aG vboxusers "${USER_NAME}"

    TMP_DIR=$(mktemp -d)
    pushd -- ${TMP_DIR}
    curl -fsSL -O "${VBE_URL}" ||
        { echo "[ERROR] Cannot download Virtualbox Extention pack." 1>&2; popd; return 30; }
    yes | VBoxManage extpack install --replace "${VBE_URL##*/}" ||
        { echo "[ERROR] Cannot install Virtualbox Extention pack." 1>&2; popd; return 40; }
    
    #cleanup
    rm -f "${VBE_URL##*/}"

    popd

    log_exec vboxmanage --version
}

function install_clang() {
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - &&
    apt-add-repository "deb http://apt.llvm.org/${OS_CODENAME}/ llvm-toolchain-${OS_CODENAME}-6.0 main" ||
        { echo "[ERROR] Cannot add llvm repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install clang-6.0 ||
        { echo "[ERROR] Cannot install libappindicator1 and fonts-liberation." 1>&2; return 20; }

    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-6.0 1000
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-6.0 1000
    update-alternatives --config clang
    update-alternatives --config clang++

    log_exec clang --version
}

function add_ssh_known_hosts() {
    if [ -f "add_ssh_known_hosts.ps1" ] && command -v pwsh; then
        pwsh ./add_ssh_known_hosts.ps1
    else
        echo '[ERROR] Cannot run add_ssh_known_hosts.ps1: Either Powershell is not installed or add_ssh_known_hosts.ps1 does not exist.' 1>&2;
        return 10;
    fi
}

function configure_path() {
    echo '

function add2path() {
    case ":$PATH:" in
        *":$1:"*) :;;
        *) export PATH="$1:$PATH" ;;
    esac
}

function add2path_suffix() {
    case ":$PATH:" in
        *":$1:"*) :;;
        *) export PATH="$PATH:$1" ;;
    esac
}
' >> /etc/profile
}

function configure_sshd() {
    write_line /etc/ssh/sshd_config 'PasswordAuthentication no' '^PasswordAuthentication '
}

function cleanup() {
    # remove list of packages.
    # It frees up ~140Mb but it force users to execute `apt-get -y -qq update`
    # prior to install any other packages
    #rm -rf /var/lib/apt/lists/*

    apt-get -y -q autoremove

    # clean bash_history
    cat /dev/null > ${HOME}/.bash_history
    cat /dev/null > ${USER_HOME}/.bash_history
    chown ${USER_NAME}:${USER_NAME} -R ${USER_HOME}

    # cleanup script guts
    for f in "$HOME/common.sh" "$HOME/bionic.sh" "$HOME/xenial.sh" "$HOME/basicconfig.sh" "$HOME/adduser.sh"; do
        if [ -f "$f" ]; then rm "$f"; fi
    done
    if [ -d "$HOME/distrib" ]; then rm -rf "$HOME/distrib"; fi
}
