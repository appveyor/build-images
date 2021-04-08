#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

# set variables
declare BASH_ATTRIBUTES
declare PACKAGES=( )
declare SDK_VERSIONS=( )
declare PROFILE_LINES=( )
if [ -f /etc/os-release ]; then
    OS_CODENAME=$(source /etc/os-release && echo $VERSION_CODENAME)
    OS_RELEASE=$(source /etc/os-release && echo $VERSION_ID)
else
    echo "[WARNING] /etc/os-release not found - cant find VERSION_CODENAME and VERSION_ID."
fi
if [[ -z "${LOGGING-}" ]]; then LOGGING=true; fi

function save_bash_attributes() {
    BASH_ATTRIBUTES=$(set -o)
}

function restore_bash_attributes() {
    if [[ -n "${BASH_ATTRIBUTES-}" && "${#BASH_ATTRIBUTES}" -gt "0" ]]; then
        while read -r BUILT STATUS; do
            if [ "$STATUS" == "on" ]; then
                set -o $BUILT
            else
                set +o $BUILT
            fi
        done <<< "$BASH_ATTRIBUTES"
    fi
}

function init_logging() {
    if [[ -z "${LOG_FILE-}" ]]; then
        SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
        LOG_FILE=$HOME/${SCRIPT_NAME%.*}.log
    fi
    touch "${LOG_FILE}"
    chmod a+w "${LOG_FILE}"
    if [ -n "${VERSIONS_FILE-}" ]; then
        touch "${VERSIONS_FILE}"
        chmod a+w "${VERSIONS_FILE}"
    fi
}

function chown_logfile() {
    if [[ -n "${USER_NAME-}" && -n "${LOG_FILE-}" ]]; then
        if id -u "${USER_NAME}"; then
            chown "$(id -u "${USER_NAME}"):$(id -g "${USER_NAME}")" -R "$LOG_FILE"
        else
            return 1
        fi
    fi
}

function log_version() {
    if [ -n "${VERSIONS_FILE-}" ]; then
        {
            echo "$@";
            "$@" 2>&1
        } | tee -a "${VERSIONS_FILE}"
    fi
}

function fail {
  echo $1 >&2
  exit 1
}

function retry {
  local n=1
  local max=5
  local delay=5
  while true; do
    "$@" && break || {
      if [[ $n -lt $max ]]; then
        ((n++))
        echo "Command failed. Attempt $n/$max:"
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

# Usage:
# replace_line <file> <line> <regex> <globalflag>
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

# Usage:
# add_line <file> <line>
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

# Usage:
# write_line <file> <line> <regex> <globalflag>
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

# check_apt_locks waits for LOCK_TIMEOUT seconds for apt locks released
function check_apt_locks() {
    echo "[INFO] check_apt_locks..."
    local LOCK_TIMEOUT=60
    local START_TIME
    START_TIME=$(date +%s)
    local END_TIME=$(( START_TIME + LOCK_TIMEOUT ))
    if ! command -v lsof >/dev/null; then
        echo "[WARNING] lsof command not found. Are we in docker container?"
        echo "[WARNING] Skipping check_apt_locks"
        return 1
    fi
    while [ "$(date +%s)" -lt "$END_TIME" ]; do
        if lsof /var/lib/apt/lists/lock; then
            sleep 1
        else
            echo "[INFO] apt succcessfully unlocked"
            return 0
        fi
    done

    return 1
}

function add_user() {
    echo "[INFO] Running add_user..."
    local USER_PASSWORD_LENGTH=${1:-32}
    save_bash_attributes
    set +o xtrace

    #generate password if it was not set before
    if [[ -z "${USER_PASSWORD-}" || "${#USER_PASSWORD}" = "0" ]]; then
        USER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${USER_PASSWORD_LENGTH};)
    fi

    # create user
    id -u ${USER_NAME} >/dev/null 2>&1 || \
        useradd ${USER_NAME} --shell /bin/bash --create-home --password ${USER_NAME}

    # change password
    echo -e "${USER_PASSWORD}\n${USER_PASSWORD}\n" | passwd "${USER_NAME}"

    configure_user

    restore_bash_attributes
    return 0
}

function configure_user() {
    echo "[INFO] Running configure_user..."
    if command -v sudo >/dev/null; then
        usermod -aG sudo ${USER_NAME}
        # Add Appveyor user to sudoers.d
        {
            echo -e "${USER_NAME}\tALL=(ALL)\tNOPASSWD: ALL"
            echo -e "Defaults:${USER_NAME}        !requiretty"
            echo -e 'Defaults    env_keep += "DEBIAN_FRONTEND ACCEPT_EULA"'
        } > /etc/sudoers.d/${USER_NAME}
    fi
}

function configure_network() {
    echo "[INFO] Running configure_network..."

    # remove host ip from /etc/hosts
    read -r IP_NUM IP_DEV IP_FAM IP_ADDR IP_REST <<< "$(ip -o -4 addr show up primary scope global)"
    sed -i -e "/ $(hostname)/d" -e "/^${IP_ADDR%/*}/d" /etc/hosts
    if [[ -n "${HOST_NAME-}" ]]; then
        write_line "/etc/hosts" "127.0.1.1       $HOST_NAME" "127.0.1.1"
    else
        echo "[ERROR] Variable HOST_NAME not defined. Cannot configure network."
        return 10
    fi

    cat /etc/hosts

    # rename host
    if [[ -n "${HOST_NAME-}" ]]; then
        echo "${HOST_NAME}" > /etc/hostname
    fi
}

function configure_uefi() {
    echo "[INFO] Running configure_uefi..."
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
    echo "[INFO] Running configure_locale..."
    echo LANG=C.UTF-8 >/etc/default/locale
    local lcl
    for lcl in en_US en_GB en_CA fr_CA ru_RU ru_UA uk_UA zh_CN zh_HK zh_TW; do
        sed -i '/^# '${lcl}'.UTF-8 UTF-8$/s/^# //' /etc/locale.gen
    done
    apt-get -y install language-pack-en language-pack-fr language-pack-uk \
                       language-pack-ru language-pack-zh-hans language-pack-zh-hant
    locale-gen
}

# https://askubuntu.com/a/755969
function wait_cloudinit () {
    if [ -d /var/lib/cloud/instances ]; then
        echo "waiting 180 seconds for cloud-init to update /etc/apt/sources.list"
        timeout 180 /bin/bash -c 'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do echo waiting for cloud-init to finish ...; sleep 1; done'
        echo "Wait for cloud-init finished."
    else
        echo "There are no cloud-init scripts."
    fi
}

function disable_automatic_apt_updates() {
    echo "[INFO] Disabling automatic apt updates..."
    # https://unix.stackexchange.com/questions/315502/how-to-disable-apt-daily-service-on-ubuntu-cloud-vm-image
    # https://askubuntu.com/questions/1059971/disable-updates-from-command-line-in-ubuntu-16-04
    # https://stackoverflow.com/questions/45269225/ansible-playbook-fails-to-lock-apt/51919678#51919678

    systemctl stop apt-daily.timer
    systemctl stop apt-daily-upgrade.timer
    systemctl stop apt-daily.service
    systemctl kill --kill-who=all apt-daily.service

    systemctl disable apt-daily.service
    systemctl disable apt-daily.timer
    systemctl disable apt-daily-upgrade.timer

    systemctl daemon-reload
    systemd-run --property="After=apt-daily.service apt-daily-upgrade.service" --wait /bin/true
    apt-get -y purge unattended-upgrades
#     apt-get -y remove update-notifier update-notifier-common
#     apt-get -y install python
#     sudo rm /etc/cron.daily/update-notifier-common

    echo 'APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
APT::Periodic::Unattended-Upgrade "0";' > /etc/apt/apt.conf.d/20auto-upgrades

#     echo 'APT::Periodic::Update-Package-Lists "0";
# APT::Periodic::Download-Upgradeable-Packages "0";
# APT::Periodic::AutocleanInterval "0";' > /etc/apt/apt.conf.d/10periodic
}

function configure_apt() {
    echo "[INFO] Running configure_apt..."
    dpkg --add-architecture i386
    export DEBIAN_FRONTEND=noninteractive
    export ACCEPT_EULA=Y
    # Update packages.
    check_apt_locks || true
    apt-get -y -qq update && apt-get -y -q upgrade ||
        { echo "[ERROR] Cannot upgrade packages." 1>&2; return 10; }
    apt-get -y -q install software-properties-common ||
        { echo "[ERROR] Cannot install software-properties-common package." 1>&2; return 10; }

    # configure appveyor env variables for future apt-get upgrades
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        write_line "$USER_HOME/.profile" 'export DEBIAN_FRONTEND=noninteractive'
        write_line "$USER_HOME/.profile" 'export ACCEPT_EULA=Y'
    else
        echo "[WARNING] User '${USER_NAME-}' not found. User's profile will not be configured."
    fi
    return 0
}

function install_tools() {
    echo "[INFO] Running install_tools..."
    declare tools_array
    # utilities
    tools_array=( "zip" "unzip" "wget" "curl" "time" "tree" "telnet" "dnsutils" "net-tools" "file" "ftp" "lftp" )
    tools_array+=( "p7zip-rar" "p7zip-full" "debconf-utils" "stress" "rng-tools"  "dkms" "dos2unix" )

    # build tools
    tools_array+=( "make" "binutils" "bison" "gcc" "tcl" "pkg-config" "ninja-build" )
    tools_array+=( "ant" "ant-optional" "maven" "gradle" "nuget" "graphviz" )

    # python packages
    tools_array+=( "python" "python-dev" "python3" )
    tools_array+=( "python-setuptools" )
    tools_array+=( "build-essential" "libssl-dev" "libcurl4-gnutls-dev" "libexpat1-dev" "libffi-dev" "gettext" )
    tools_array+=( "inotify-tools" "gfortran" "apt-transport-https" )
    tools_array+=( "libbz2-dev" "liblzma-dev" "python3-tk" "tk-dev" "libsqlite3-dev" )

    # 32bit support
    tools_array+=( "libc6:i386" "libncurses5:i386" "libstdc++6:i386" )

    # Add release specific tools into tools_array
    if command -v add_releasespecific_tools; then
        add_releasespecific_tools
    fi

    # next packages required by KVP to communicate with HyperV
    if [ "${BUILD_AGENT_MODE}" = "HyperV" ]; then
        tools_array+=( "linux-tools-generic" "linux-cloud-tools-generic" )
        tools_array+=( "openssh-server" )
    fi

    #APT_GET_OPTIONS="-o Debug::pkgProblemResolver=true -o Debug::Acquire::http=true"
    apt-get -y ${APT_GET_OPTIONS-} install "${tools_array[@]}" --no-install-recommends ||
        {
            echo "[ERROR] Cannot install various packages. ERROR $?." 1>&2;
            apt-cache policy gcc
            apt-cache policy zip
            apt-cache policy make
            return 10;
        }
    log_version dpkg -l "${tools_array[@]}"
}

# this exact packages required to communicate with HyperV
function install_KVP_packages(){
    echo "[INFO] Running install_KVP_packages..."

    apt-get -qq update
    apt-get -y install linux-azure
}

# this package is required to communicate with Azure
function install_azure_linux_agent(){
    echo "[INFO] Running install_azure_linux_agent..."

    apt-get -y install walinuxagent
    systemctl restart walinuxagent.service
}

function copy_appveyoragent() {
    if [[ -z "${APPVEYOR_BUILD_AGENT_VERSION-}" || "${#APPVEYOR_BUILD_AGENT_VERSION}" = "0" ]]; then
        APPVEYOR_BUILD_AGENT_VERSION=7.0.2572;
    fi

    echo "[INFO] Installing AppVeyor Build Agent v${APPVEYOR_BUILD_AGENT_VERSION}"

    local AGENT_FILE
    AGENT_FILE=appveyor-build-agent-${APPVEYOR_BUILD_AGENT_VERSION}-linux-x64.tar.gz

    if [[ -z "${AGENT_DIR-}" ]]; then
        echo "[WARNING] AGENT_DIR variable is not set. Setting it to AGENT_DIR=/opt/appveyor/build-agent" 1>&2;
        AGENT_DIR=/opt/appveyor/build-agent
    fi

    [ -d "${AGENT_DIR}" ] && rm -rf "${AGENT_DIR}" || true

    mkdir -p "${AGENT_DIR}" &&
    #chown -R ${USER_NAME}:${USER_NAME} ${AGENT_DIR} &&
    pushd -- "${AGENT_DIR}" ||
        { echo "[ERROR] Cannot create ${AGENT_DIR} folder." 1>&2; return 10; }

    local AGENT_URL
    AGENT_URL="https://appveyordownloads.blob.core.windows.net/appveyor/${APPVEYOR_BUILD_AGENT_VERSION}/${AGENT_FILE}"
    curl -fsSL "${AGENT_URL}" -o "${AGENT_FILE}" &&
    tar -zxf ${AGENT_FILE} ||
        { echo "[ERROR] Cannot download and untar ${AGENT_FILE}." 1>&2; popd; return 20; }
    chmod +x ${AGENT_DIR}/appveyor ||
        { echo "[ERROR] Cannot change mode for ${AGENT_DIR}/appveyor file." 1>&2; popd; return 30; }
    popd
}

function install_appveyoragent() {
    echo "[INFO] Running install_appveyoragent..."
    AGENT_MODE=${1-}
    CONFIG_FILE=appsettings.json
    PROJECT_BUILDS_DIRECTORY="$USER_HOME"/projects
    SERVICE_NAME=appveyor-build-agent.service
    if [[ -z "${AGENT_DIR-}" ]]; then { echo "[ERROR] AGENT_DIR variable is not set." 1>&2; return 10; } fi

    copy_appveyoragent || return "$?"

    if id -u "${USER_NAME}"; then
        chown "$(id -u "${USER_NAME}"):$(id -g "${USER_NAME}")" -R "${AGENT_DIR}"
    fi

    pushd -- "${AGENT_DIR}" ||
        { echo "[ERROR] Cannot cd to ${AGENT_DIR} folder." 1>&2; return 10; }
    if [ "${#AGENT_MODE}" -gt 0 ]; then
        if command -v python; then
            [ -f ${CONFIG_FILE} ] &&
            python -c "import json; import io;
a=json.load(io.open('${CONFIG_FILE}', encoding='utf-8-sig'));
a[u'AppVeyor'][u'Mode']='${AGENT_MODE}';
a[u'AppVeyor'][u'ProjectBuildsDirectory']='${PROJECT_BUILDS_DIRECTORY}';
json.dump(a,open('${CONFIG_FILE}','w'))" &&
            cat ${CONFIG_FILE} ||
                { echo "[ERROR] Cannot update config file '${CONFIG_FILE}'." 1>&2; popd; return 40; }
        else
            echo "[ERROR] Cannot update config file '${CONFIG_FILE}'. Python is not installed." 1>&2; popd; return 40;
        fi
    else
        echo "[WARNING] AGENT_MODE variable not set"
    fi

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
    log_version ${AGENT_DIR}/appveyor Version
    popd

}

function install_nvm_and_nodejs() {
    echo "[INFO] Running install_nvm_and_nodejs..."
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            $(declare -f install_nvm)
            $(declare -f write_line)
            $(declare -f add_line)
            $(declare -f replace_line)
            install_nvm" &&
        su -l ${USER_NAME} -c "
            [ -s \"${HOME}/.nvm/nvm.sh\" ] && . \"${HOME}/.nvm/nvm.sh\"
            USER_NAME=${USER_NAME}
            $(declare -f log_version)
            $(declare -f install_nvm_nodejs)
            install_nvm_nodejs ${CURRENT_NODEJS}" ||
        return $?
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Cannot install NVM and Nodejs"
    fi
}

function install_nvm() {
    echo "[INFO] Running install_nvm..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}' user. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    #TODO have to figure out latest release version automatically
    curl -fsSLo- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash
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
        CURRENT_NODEJS=8
    else
        CURRENT_NODEJS=$1
    fi
    command -v nvm ||
        { echo "Cannot find nvm. Install nvm first!" 1>&2; return 10; }
    local v
    declare NVM_VERSIONS=( "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "lts/argon" "lts/boron" "lts/carbon" "lts/dubnium" "lts/erbium" )
    for v in "${NVM_VERSIONS[@]}"; do
        nvm install ${v} ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done

    nvm alias default ${CURRENT_NODEJS}

    log_version nvm --version
    log_version nvm list

}

function update_git() {
    # https://itsfoss.com/install-git-ubuntu/
    echo "[INFO] Updating Git to the latest version.";
    add-apt-repository -y ppa:git-core/ppa
    apt-get update
    apt-get -y -q install git
    log_version git --version
}

function make_git() {
    local GIT_VERSION
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        GIT_VERSION=2.29.2
    else
        GIT_VERSION=$1
    fi
    if command -v git && [[ $(git --version| cut -d' ' -f 3) =~ ${GIT_VERSION} ]]; then
        echo "[WARNING] git version ${GIT_VERSION} already installed.";
        return 0
    fi
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl -fsSL https://github.com/git/git/archive/v${GIT_VERSION}.zip -o git-${GIT_VERSION}.zip ||
        { echo "[ERROR] Cannot download git ${GIT_VERSION}." 1>&2; popd; return 10; }
    DIR_NAME=$(unzip -l git-${GIT_VERSION}.zip | awk 'NR>4{sub(/\/.*/,"",$4);print $4;}'|sort|uniq|tr -d '\n')
    [ -d "${DIR_NAME}" ] && rm -rf "${DIR_NAME}" || true
    unzip -q -o "git-${GIT_VERSION}.zip" ||
        { echo "[ERROR] Cannot unzip 'git-${GIT_VERSION}.zip'." 1>&2; popd; return 20; }
    cd -- ${DIR_NAME} || { echo "[ERROR] Cannot cd into '${DIR_NAME}'. Something went wrong." 1>&2; popd; return 30; }
    #build
    make --silent prefix=/usr/local all &&
        make --silent prefix=/usr/local install ||
        { echo "Make command failed." 1>&2; popd; return 40; }

    # cleanup
    popd &&
    rm -rf "${TMP_DIR}"
    log_version git --version
}

function install_gitlfs() {
    echo "[INFO] Running install_gitlfs..."
    command -v git || apt-get -y -q install git
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash &&
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

function configure_gitlfs() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    git lfs install ||
        { echo "Failed to configure git lfs." 1>&2; return 10; }
}

function install_gitversion() {
    echo "[INFO] Running install_gitversion..."
    local VERSION
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        VERSION=5.1.2
    else
        VERSION=$1
    fi

    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"

    curl -fsSL -O https://github.com/GitTools/GitVersion/releases/download/${VERSION}/gitversion-linux-${VERSION}.tar.gz &&
    tar -zxf gitversion-linux-${VERSION}.tar.gz -C /usr/local/bin &&
    chmod a+rx /usr/local/bin/GitVersion* ||
        { echo "[ERROR] Cannot install GitVersion ${VERSION}." 1>&2; popd; return 10; }

    popd
    log_version GitVersion /version
    [ -d /var/tmp/.net/ ] && rm -rf /var/tmp/.net/
}

function configure_mercurial_repository() {
    echo "[INFO] Running configure_mercurial_repository..."
    add-apt-repository -y ppa:mercurial-ppa/releases
    apt-get -y -qq update
}

function install_cvs() {
    echo "[INFO] Running install_cvs..."
    # install git
    # at this time there is git version 2.7.4 in apt repos
    # in case if we need recent version we have to run make_git function
    apt-get -y -q install git

    #install Mercurial
    configure_mercurial_repository
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

function configure_svn() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    pushd "${HOME}"
    mkdir -p .subversion &&
    echo "[global]
store-passwords = yes
store-plaintext-passwords = yes" > .subversion/servers &&
    echo "[auth]
password-stores =" > .subversion/config ||
        { echo "[ERROR] Cannot configure svn." 1>&2; popd; return 10; }
    popd
}

function install_virtualenv() {
    echo "[INFO] Running install_virtualenv..."
    command -v pip || install_pip
    pip install virtualenv ||
        { echo "[WARNING] Cannot install virtualenv with pip." ; return 10; }

    log_version virtualenv --version
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

function install_pythons(){
    command -v virtualenv || install_virtualenv
    declare PY_VERSIONS=( "2.6.9" "2.7.18" "3.4.10" "3.5.10" "3.6.12" "3.7.9" "3.8.6" "3.9.1" )
    for i in "${PY_VERSIONS[@]}"; do
        VENV_PATH=${HOME}/venv${i%%[abrcf]*}
        VENV_MINOR_PATH=${HOME}/venv${i%.*}
        if [ ! -d ${VENV_PATH} ]; then
        curl -fsSL -O "http://www.python.org/ftp/python/${i%%[abrcf]*}/Python-${i}.tgz" ||
            { echo "[WARNING] Cannot download Python ${i}."; continue; }
        tar -zxf "Python-${i}.tgz" &&
        pushd "Python-${i}" ||
            { echo "[WARNING] Cannot unpack Python ${i}."; continue; }
        PY_PATH=${HOME}/.localpython${i}
        mkdir -p "${PY_PATH}"
        ./configure --enable-shared --silent "--prefix=${PY_PATH}" "LDFLAGS=-Wl,-rpath=${PY_PATH}/lib" &&
        make --silent &&
        make install --silent >/dev/null ||
            { echo "[WARNING] Cannot make Python ${i}."; popd; continue; }
        if [ ${i:0:1} -eq 3 ]; then
            PY_BIN=python3
        else
            PY_BIN=python
        fi
        virtualenv -p "$PY_PATH/bin/${PY_BIN}" "${VENV_PATH}" ||
            { echo "[WARNING] Cannot make virtualenv for Python ${i}."; popd; continue; }
        popd
        echo "Linking ${VENV_MINOR_PATH} to ${VENV_PATH}"
        rm -f ${VENV_MINOR_PATH}
        ln -s ${VENV_PATH} ${VENV_MINOR_PATH}
        fi
    done
    find "${HOME}" -name "Python-*" -type d -maxdepth 1 | xargs -I {} rm -rf {}
    rm ${HOME}/Python-*.tgz
}

function install_powershell() {
    echo "[INFO] Running install_powershell..."

    # Import the public repository GPG keys
    curl -fsSL "https://packages.microsoft.com/keys/microsoft.asc" | apt-key add - &&
    # Register the Microsoft Ubuntu repository
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/${OS_RELEASE}/prod.list)" ||
        { echo "[ERROR] Cannot add Microsoft's APT source." 1>&2; return 10; }

    # Update the list of products and Install PowerShell
    apt-get -y -qq update &&
    apt-get -y -q --allow-downgrades install powershell ||
        { echo "[ERROR] PowerShell install failed." 1>&2; return 10; }

    configure_powershell

    # Start PowerShell
    log_version pwsh --version
}

function configure_powershell() {
    if [[ -z "${AGENT_DIR-}" ]]; then { echo "[ERROR] AGENT_DIR variable is not set." 1>&2; return 10; } fi
    if [[ -z "${USER_HOME-}" ]]; then { echo "[ERROR] USER_HOME variable is not set." 1>&2; return 20; } fi
    local PROFILE_PATH=${USER_HOME}/.config/powershell
    local PROFILE_NAME=Microsoft.PowerShell_profile.ps1
    # configure PWSH profile
    mkdir -p "${PROFILE_PATH}" &&
    write_line "${PROFILE_PATH}/${PROFILE_NAME}" "Import-Module ${AGENT_DIR}/Appveyor.BuildAgent.PowerShell.dll" ||
        { echo "[ERROR] Cannot create and change PWSH profile ${PROFILE_PATH}/${PROFILE_NAME}." 1>&2; return 30; }

    pwsh -c 'Install-Module Pester -Force'
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
    for ver in $(dotnet --list-sdks|cut -f1 -d' '); do
        echo "Preheating .NET SDK version $ver"
        TMP_DIR=$(mktemp -d)
        pushd  ${TMP_DIR}
        global_json ${ver} >global.json
        dotnet new console
        popd &&
        rm -rf "${TMP_DIR}"
    done
}

function prepare_dotnet_packages() {

    SDK_VERSIONS=( "2.1" "2.2" "3.0" "3.1" "5.0" )
    dotnet_packages "dotnet-sdk-" SDK_VERSIONS[@]

    declare RUNTIME_VERSIONS=( "2.1" "2.2" )
    dotnet_packages "dotnet-runtime-" RUNTIME_VERSIONS[@]

    declare DEV_VERSIONS=( "1.1.12" )
    dotnet_packages "dotnet-dev-" DEV_VERSIONS[@]
}

function config_dotnet_repository() {
    curl -fsSL -O https://packages.microsoft.com/config/ubuntu/${OS_RELEASE}/packages-microsoft-prod.deb &&
    dpkg -i packages-microsoft-prod.deb &&
    apt-get -y -qq update ||
        { echo "[ERROR] Cannot download and install Microsoft's APT source." 1>&2; return 10; }
}

function install_outdated_dotnets() {
    echo "[INFO] Running install_outdated_dotnets..."

    # .NET SDK 1.1.14 with 1.1.13 & 1.0.16 runtimes
    wget -O dotnet-sdk.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/1.1.14/dotnet-dev-ubuntu.16.04-x64.1.1.14.tar.gz
    sudo tar zxf dotnet-sdk.tar.gz -C /usr/share/dotnet

    # .NET SDK 2.1.202 with 2.0.9 runtime
    wget -O dotnet-sdk.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/2.1.202/dotnet-sdk-2.1.202-linux-x64.tar.gz
    sudo tar zxf dotnet-sdk.tar.gz -C /usr/share/dotnet

    rm dotnet-sdk.tar.gz
}

function install_dotnets() {
    echo "[INFO] Running install_dotnets..."
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

function configure_mono_repository () {
    echo "[INFO] Running install_mono..."
    add-apt-repository "deb http://download.mono-project.com/repo/ubuntu stable-${OS_CODENAME} main" ||
        { echo "[ERROR] Cannot add Mono repository to APT sources." 1>&2; return 10; }
}

function install_mono() {
    echo "[INFO] Running install_mono..."
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

    configure_mono_repository

    apt-get -y -qq update &&
    apt-get -y -q install mono-complete mono-dbg referenceassemblies-pcl mono-xsp4 ||
        { echo "[ERROR] Cannot install Mono." 1>&2; return 20; }

    log_version mono --version
    log_version csc
    log_version xsp4 --version
    log_version mcs --version
}

function install_jdks_from_repository() {
    echo "[INFO] Running install_jdks_from_repository..."
    add-apt-repository -y ppa:openjdk-r/ppa
    apt-get -y -qq update && {
        apt-get -y -q install --no-install-recommends openjdk-7-jdk
        apt-get -y -q install --no-install-recommends openjdk-8-jdk
#        apt-get -y -q install --no-install-recommends openjdk-9-jdk -o Dpkg::Options::="--force-overwrite"
    } ||
        { echo "[ERROR] Cannot install JDKs." 1>&2; return 10; }
    update-java-alternatives --set java-1.8.0-openjdk-amd64
}

function install_jdks() {
    echo "[INFO] Running install_jdks..."
    install_jdks_from_repository || return $?

    install_jdk 9 https://download.java.net/java/GA/jdk9/9.0.4/binaries/openjdk-9.0.4_linux-x64_bin.tar.gz ||
        return $?
    install_jdk 10 https://download.java.net/openjdk/jdk10/ri/openjdk-10+44_linux-x64_bin_ri.tar.gz ||
        return $?
    install_jdk 11 https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz ||
        return $?
    install_jdk 12 https://download.java.net/java/GA/jdk12.0.2/e482c34c86bd4bf8b56c0b35558996b9/10/GPL/openjdk-12.0.2_linux-x64_bin.tar.gz ||
        return $?
    install_jdk 13 https://download.java.net/java/GA/jdk13.0.2/d4173c853231432d94f001e99d882ca7/8/GPL/openjdk-13.0.2_linux-x64_bin.tar.gz ||
        return $?
    install_jdk 14 https://download.java.net/java/GA/jdk14.0.1/664493ef4a6946b186ff29eb326336a2/7/GPL/openjdk-14.0.1_linux-x64_bin.tar.gz ||
        return $?
    install_jdk 15 https://download.java.net/java/GA/jdk15.0.1/51f4f36ad4ef43e39d0dfdbaf6549e32/9/GPL/openjdk-15.0.1_linux-x64_bin.tar.gz ||
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
            configure_jdk" <<< "${PROFILE_LINES[*]}" ||
                return $?
        IFS=$OFS
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Skipping configure_jdk"
    fi
}

function install_jdk() {
    local JDK_VERSION=$1
    local JDK_URL="$2"
    local JDK_ARCHIVE=${JDK_URL##*/}
    local JDK_PATH JDK_LINK

    echo "[INFO] Running install_jdk ${JDK_VERSION}..."

    JDK_PATH=/usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64/
    JDK_LINK=/usr/lib/jvm/java-1.${JDK_VERSION}.0-openjdk-amd64

    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"

    retry curl -fsSL -O "${JDK_URL}" &&
    tar zxf "${JDK_ARCHIVE}" ||
        { echo "[ERROR] Cannot download and unpack JDK ${JDK_VERSION}." 1>&2; popd; return 10; }
    DIR_NAME=$(tar tf "${JDK_ARCHIVE}" |cut -d'/' -f1|sort|uniq|head -n1)
    mkdir -p ${JDK_PATH} &&
    cp -R "${DIR_NAME}"/* "${JDK_PATH}" &&
    ln -s -f "${JDK_PATH}" "${JDK_LINK}" ||
        { echo "[ERROR] Cannot copy JDK ${JDK_VERSION} to /usr/lib/jvm." 1>&2; popd; return 20; }

    PROFILE_LINES+=( "export JAVA_HOME_${JDK_VERSION}_X64=${JDK_PATH}" )

    # cleanup
    rm -rf "${DIR_NAME}"
    rm "${JDK_ARCHIVE}"
    popd &&
    rm -rf "${TMP_DIR}"
}

function configure_jdk() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
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
    #shellcheck disable=SC2016
    write_line "${HOME}/.profile" 'add2path $JAVA_HOME/bin'
}

function install_rvm_and_rubies() {
    echo "[INFO] Running install_rvm_and_rubies..."
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            $(declare -f install_rvm)
            install_rvm" &&
        su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            [[ -s \"${HOME}/.rvm/scripts/rvm\" ]] && source \"${HOME}/.rvm/scripts/rvm\"
            $(declare -f log_version)
            $(declare -f install_rubies)
            install_rubies" ||
                return $?
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Cannot install RVM and rubies"
    fi
}

function install_rvm() {
    echo "[INFO] Running install_rvm..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi

    # Docker fix from here: https://github.com/inversepath/usbarmory-debian-base_image/issues/9#issuecomment-451635505
    mkdir -p ${HOME}/.gnupg
    echo "disable-ipv6" >> ${HOME}/.gnupg/dirmngr.conf

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
    echo "[INFO] Running install_rubies..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    local DEFAULT_RUBY
    DEFAULT_RUBY="ruby-2.7"
    command -v rvm ||
        { echo "Cannot find rvm. Install rvm first!" 1>&2; return 10; }
    local v
    declare RUBY_VERSIONS=( "ruby-2.0" "ruby-2.1" "ruby-2.2" "ruby-2.3" "ruby-2.4" "ruby-2.5" "ruby-2.6" "ruby-2.7" "ruby-head" )
    for v in "${RUBY_VERSIONS[@]}"; do
        rvm install ${v} ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done

    rvm use "$DEFAULT_RUBY" --default
    log_version rvm --version
    log_version rvm list
}

function install_gvm_and_golangs() {
    echo "[INFO] Running install_gvm_and_golangs..."
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            $(declare -f install_gvm)
            $(declare -f write_line)
            $(declare -f add_line)
            $(declare -f replace_line)
            install_gvm" &&
        su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            source \"${HOME}/.gvm/scripts/gvm\"
            $(declare -f log_version)
            $(declare -f install_golangs)
            install_golangs" ||
                return $?
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Cannot install GVM and Go Langs"
    fi
}

function install_gvm() {
    echo "[INFO] Running install_gvm..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
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
            write_line "${HOME}/.profile" '[[ -s "/home/appveyor/.gvm/scripts/gvm" ]] && source "/home/appveyor/.gvm/scripts/gvm"'
    ) || true
}

function install_golangs() {
    echo "[INFO] Running install_golangs..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    command -v gvm && gvm version ||
        { echo "Cannot find or execute gvm. Install gvm first!" 1>&2; return 10; }
    gvm install go1.4 -B &&
    gvm use go1.4 ||
        { echo "[WARNING] Cannot install go1.4 from binaries." 1>&2; return 10; }
    declare GO_VERSIONS=( "go1.7.6" "go1.8.7" "go1.9.7" "go1.10.8" "go1.11.13" "go1.12.17" "go1.13.15" "go1.14.13" "go1.15.6" )
    for v in "${GO_VERSIONS[@]}"; do
        gvm install ${v} ||
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
    declare DOCKER_IMAGES=( "microsoft/dotnet" "microsoft/aspnetcore" "debian" "ubuntu" "centos" "alpine" "busybox" )
    for IMAGE in "${DOCKER_IMAGES[@]}"; do
        docker pull "$IMAGE" ||
            { echo "[WARNING] Cannot pull docker image ${IMAGE}." 1>&2; }
    done
    log_version docker images
    log_version docker system df
}

function configure_docker_repository() {
    echo "[INFO] Running configure_docker_repository..."

    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${OS_CODENAME} stable" ||
        { echo "[ERROR] Cannot add Docker repository to APT sources." 1>&2; return 10; }
}

function install_docker() {
    echo "[INFO] Running install_docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - &&

    configure_docker_repository

    apt-get -y -qq update &&
    apt-get -y -q install docker-ce ||
        { echo "[ERROR] Cannot install Docker." 1>&2; return 20; }

    # Native Overlay Diff: true
    modprobe -r overlay && modprobe overlay redirect_dir=off
    echo 'options overlay redirect_dir=off' > /etc/modprobe.d/disable_overlay_redirect_dir.conf

    systemctl restart docker &&
    systemctl is-active docker ||
        { echo "[ERROR] Docker service failed to start." 1>&2; return 30; }
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        usermod -aG docker ${USER_NAME}
    fi
    docker info
    pull_dockerimages
    systemctl disable docker

    log_version dpkg -l docker-ce
}

function install_MSSQLServer() {
    echo "[INFO] Running install_MSSQLServer()..."
    if [[ -z "${MSSQL_SA_PASSWORD-}" || "${#MSSQL_SA_PASSWORD}" = "0" ]]; then MSSQL_SA_PASSWORD="Password12!"; fi
    install_sqlserver
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD}
            $(declare -f configure_sqlserver)
            $(declare -f write_line)
            $(declare -f add_line)
            $(declare -f replace_line)
            configure_sqlserver"
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Cannot installconfigure MS SQL Server"
    fi
    disable_sqlserver ||
            return $?
}

function configure_sqlserver_repository() {
    echo "[INFO] Running configure_sqlserver_repository..."
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2019.list)" &&
    add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/${OS_RELEASE}/prod.list)" ||
        { echo "[ERROR] Cannot add mssql-server repository to APT sources." 1>&2; return 10; }
}

function install_sqlserver() {
    echo "[INFO] Running install_sqlserver..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - &&

    configure_sqlserver_repository

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

function configure_sqlserver() {
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "[ERROR] This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    if [[ -z "${MSSQL_SA_PASSWORD-}" ]]; then
        echo "[ERROR] MSSQL_SA_PASSWORD variable not set!" 1>&2
        return 2
    fi
    # Add SQL Server tools to the path by default:
    write_line "${HOME}/.profile" 'add2path_suffix /opt/mssql-tools/bin'
    export PATH="$PATH:/opt/mssql-tools/bin"

    local counter=1
    local errstatus=1
    while [ $counter -le 5 ] && [ $errstatus = 1 ]; do
        echo Waiting for SQL Server to start...
        sleep 10s
        sqlcmd -S localhost -U SA -P ${MSSQL_SA_PASSWORD} -Q "SELECT @@VERSION"
        errstatus=$?
        echo "errstatus=${errstatus}"
        ((counter++))
    done
    if [ $errstatus = 1 ]; then
        systemctl status mssql-server
        if command -v netstat; then netstat -alnp|grep sqlservr; fi
        echo "[ERROR] Cannot connect to SQL Server." 1>&2
        return 10
    fi
}

function disable_sqlserver() {
    systemctl disable mssql-server
}

function configure_apt_mysql() {
    if [[ -z "${MYSQL_ROOT_PASSWORD-}" || "${#MYSQL_ROOT_PASSWORD}" = "0" ]]; then MYSQL_ROOT_PASSWORD="Password12!"; fi
    echo "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections &&
    echo "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections ||
        { echo "[ERROR] Cannot set apt's parameters for MySQL package." 1>&2; return 10;}
}

function install_mysql() {
    echo "[INFO] Running install_mysql..."
    configure_apt_mysql

    apt-get -y -q install mysql-server ||
        { echo "[ERROR] Cannot install MySQL." 1>&2; return 10;}
    systemctl start mysql
    #shellcheck disable=SC2016
    mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e 'USE mysql; SELECT Host,User FROM `user`;' ||
        { echo "[ERROR] Cannot connect to MySQL locally." 1>&2; return 20;}
    systemctl disable mysql
    log_version dpkg -l mysql-server
}

function install_postgresql() {
    echo "[INFO] Running install_postgresql..."
    if [[ -z "${POSTGRES_ROOT_PASSWORD-}" || "${#POSTGRES_ROOT_PASSWORD}" = "0" ]]; then POSTGRES_ROOT_PASSWORD="Password12!"; fi
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - &&
    add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ ${OS_CODENAME}-pgdg main" ||
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

function install_mongodb() {
    echo "[INFO] Running install_mongodb..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add - &&
    add-apt-repository "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu ${OS_CODENAME}/mongodb-org/4.2 multiverse" ||
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
    log_version dpkg -l mongodb-org
}

function install_redis() {
    echo "[INFO] Running install_redis..."
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
    mkdir -p "${WORKING_DIR}" &&
    chown redis:redis "${WORKING_DIR}" &&
    chmod 770 "${WORKING_DIR}"

    systemctl enable redis &&
    systemctl disable redis
    popd &&
    rm -rf "${TMP_DIR}"
    log_version redis-server --version
}

function configure_rabbitmq_repositories() {
    echo "[INFO] Running configure_rabbitmq_repositories..."

    add-apt-repository "deb https://dl.bintray.com/rabbitmq-erlang/debian ${OS_CODENAME} erlang" ||
        { echo "[ERROR] Cannot add rabbitmq-erlang repository to APT sources." 1>&2; return 10; }

    add-apt-repository "deb https://dl.bintray.com/rabbitmq/debian ${OS_CODENAME} main" ||
        { echo "[ERROR] Cannot add rabbitmq repository to APT sources." 1>&2; return 10; }
}

function install_rabbitmq() {
    echo "[INFO] Running install_rabbitmq..."
    curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | apt-key add -

    configure_rabbitmq_repositories

    # mkdir -p /etc/rabbitmq
    # echo 'NODENAME=rabbitmq@localhost' > /etc/rabbitmq/rabbitmq-env.conf

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

function install_p7zip() {
    echo "[INFO] Running install_p7zip..."
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl -fsSL -O "https://sourceforge.net/projects/p7zip/files/p7zip/16.02/p7zip_16.02_src_all.tar.bz2" &&
    tar jxf "p7zip_16.02_src_all.tar.bz2" ||
        { echo "[ERROR] Cannot download and unpack p7zip source code." 1>&2; popd; return 10; }
    cd "p7zip_16.02"
    make --silent all &&
    ./install.sh ||
        { echo "[ERROR] Cannot build and install p7zip." 1>&2; popd; return 20; }
    popd &&
    rm -rf "${TMP_DIR}"
}

function install_packer() {
    echo "[INFO] Running install_packer..."
    local VERSION
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        VERSION=1.6.5
    else
        VERSION=$1
    fi
    local ZIPNAME=packer_${VERSION}_linux_amd64.zip
    curl -fsSL -O https://releases.hashicorp.com/packer/${VERSION}/${ZIPNAME} &&
    unzip -q -o ${ZIPNAME} -d /usr/local/bin ||
        { echo "[ERROR] Cannot download and unzip packer." 1>&2; return 10; }
    log_version packer --version
    # cleanup
    [ -f "${ZIPNAME}" ] && rm -f "${ZIPNAME}" || true
}

function install_yarn() {
    echo "[INFO] Running install_yarn..."
    curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&
    add-apt-repository "deb https://dl.yarnpkg.com/debian/ stable main" ||
        { echo "[ERROR] Cannot add yarn repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install --no-install-recommends yarn ||
        { echo "[ERROR] Cannot install yarn." 1>&2; return 20; }
    log_version yarn --version
}

function install_awscli() {
    echo "[INFO] Running install_awscli..."
    pip install awscli ||
        { echo "[ERROR] Cannot install awscli." 1>&2; return 10; }
    log_version aws --version
}

function install_localstack() {
    echo "[INFO] Running install_localstack..."
    pip install localstack ||
        { echo "[ERROR] Cannot install localstack." 1>&2; return 10; }
    # since version 0.8.8 localstack requires but do not have in dependencies amazon_kclpy
    pip install amazon_kclpy ||
        { echo "[ERROR] Cannot install amazon_kclpy which is required by localstack." 1>&2; return 20; }
    log_version localstack --version
}

function install_gcloud() {
    echo "[INFO] Running install_gcloud..."
    apt-get install apt-transport-https ca-certificates &&
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" > /etc/apt/sources.list.d/google-cloud-sdk.list &&
    curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - ||
        { echo "[ERROR] Cannot add google-cloud-sdk repository to APT sources." 1>&2; return 10; }
    apt-get -y -qq update &&
    apt-get -y -q install google-cloud-sdk ||
        { echo "[ERROR] Cannot install google-cloud-sdk." 1>&2; return 20; }

    log_version gcloud version
}

function configure_azurecli_repository() {
    echo "[INFO] Running configure_azurecli_repository..."
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ ${OS_CODENAME} main" > /etc/apt/sources.list.d/azure-cli.list
}

function install_azurecli() {
    # https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
    echo "[INFO] Running install_azurecli..."

    apt-get update
    apt-get install -y apt-transport-https gnupg

    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.asc.gpg

    configure_azurecli_repository

    apt-get update
    apt-get install -y azure-cli

    log_version az --version
}

function install_cmake() {
    echo "[INFO] Running install_cmake..."
    local VERSION
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        VERSION=3.20.1
    else
        VERSION=$1
    fi
    local TAR_FILE=cmake-${VERSION}-linux-x86_64.tar.gz
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl -fsSL -O "https://cmake.org/files/v${VERSION%.*}/${TAR_FILE}" &&
    tar -zxf "${TAR_FILE}" ||
        { echo "[ERROR] Cannot download and untar cmake." 1>&2; popd; return 10; }
    DIR_NAME=$(tar -ztf ${TAR_FILE} |cut -d'/' -f1|sort|uniq|head -n1)
    cd -- "${DIR_NAME}" ||
        { echo "[ERROR] Cannot change directory to ${DIR_NAME}." 1>&2; popd; return 20; }
    [ -d "/usr/share/cmake-${VERSION%.*}" ] && rm -rf "/usr/share/cmake-${VERSION%.*}" || true
    mv -f ./bin/* /usr/bin/ &&
    mv -f ./share/cmake-${VERSION%.*} /usr/share/ &&
    mv -f ./share/aclocal/* /usr/share/aclocal/||
        { echo "[ERROR] Cannot install cmake." 1>&2; popd; return 30; }
    log_version cmake --version
    popd &&
    rm -rf "${TMP_DIR}"
}

function configure_nuget() {
    echo "[INFO] Configure nuget..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}' user. Current user is '$(whoami)'" 1>&2
        return 1
    fi

    local NUGET_CONFIG="$HOME/.nuget/NuGet/NuGet.Config"

    if [ -f "${NUGET_CONFIG}" ]; then
        echo "[WARNING] ${NUGET_CONFIG} already exists. Taking ownership."
        cat ${NUGET_CONFIG}
        sudo chown -R "$(id -u):$(id -g)" "$HOME/.nuget"
    else
        echo "[INFO] Creating ${NUGET_CONFIG}"
        mkdir -p "$HOME/.nuget/NuGet" &&
        echo '<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
  </packageSources>
</configuration>' > ${NUGET_CONFIG} ||
        { echo "[ERROR] Cannot configure nuget." 1>&2; return 10; }
    fi

    ls -al "$HOME/.nuget/NuGet"
}

function update_nuget() {
    nuget update -self ||
        { echo "[ERROR] Cannot update nuget."; return 10; }
}

function install_kubectl() {
    echo "[INFO] Running install_kubectl..."
    KUBE_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl" &&
    chmod +x ./kubectl &&
    mv -f ./kubectl /usr/local/bin/kubectl ||
        { echo "[ERROR] Cannot download and install kubectl."; return 10; }
}

function install_gcc() {
    echo "[INFO] Running install_gcc..."
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
    apt-get -y -q install gcc-9 g++-9 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9 ||
        { echo "[ERROR] Cannot install gcc-8." 1>&2; return 40; }
}

function install_curl() {
    echo "[INFO] Running install_curl..."
    local VERSION
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        VERSION=7.73.0
    else
        VERSION=$1
    fi
    local TAR_FILE=curl-${VERSION}.tar.gz
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl -fsSL -O "https://curl.haxx.se/download/${TAR_FILE}" &&
    tar -zxf "${TAR_FILE}" ||
        { echo "[ERROR] Cannot download and untar curl." 1>&2; popd; return 10; }
    DIR_NAME=$(tar -ztf ${TAR_FILE} |cut -d'/' -f1|sort|uniq|head -n1)
    cd -- "${DIR_NAME}" ||
        { echo "[ERROR] Cannot change directory to ${DIR_NAME}." 1>&2; popd; return 20; }

    # purge all installed curl packages
    #for p in $(dpkg --get-selections|grep -v deinstall|grep curl|cut -f1); do  apt-get purge -y $p; done

    apt-get install -y libldap2-dev libssh2-1-dev libpsl-dev libidn2-dev libnghttp2-dev librtmp-dev ||
        { echo "[ERROR] Cannot install additional libraries for curl." 1>&2; popd; return 20; }

    ./configure --with-libssh2 &&
    make &&
    make install ||
        { echo "[ERROR] Cannot make curl." 1>&2; popd; return 30; }
    log_version curl --version
    popd &&
    rm -rf "${TMP_DIR}"
}

function configure_firefox_repository() {
    echo "[INFO] Running configure_firefox_repository..."
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6DCF7707EBC211F
    add-apt-repository "deb [ arch=amd64 ] http://ppa.launchpad.net/ubuntu-mozilla-security/ppa/ubuntu ${OS_CODENAME} main"
    apt-get -y update
}

function install_browsers() {
    echo "[INFO] Running install_browsers..."
    local DEBNAME=google-chrome-stable_current_amd64.deb

    echo "[INFO] Running configure_firefox_repository..."
    configure_firefox_repository

    apt-get -y -q install libappindicator1 fonts-liberation xvfb ||
        { echo "[ERROR] Cannot install libappindicator1 and fonts-liberation." 1>&2; return 10; }
    curl -fsSL -O https://dl.google.com/linux/direct/${DEBNAME}
    dpkg -i ${DEBNAME}
    apt-get -y --fix-broken install
    apt-get -y -q install firefox
    log_version dpkg -l firefox google-chrome-stable
    #cleanup
    [ -f "${DEBNAME}" ] && rm -f "${DEBNAME}" || true
}

function install_virtualbox_core() {
    echo "[INFO] Running install_virtualbox_core..."

    local VB_VERSION=6.1
    retry curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc -o oracle_vbox_2016.asc ||
        { echo "[ERROR] Cannot download oracle_vbox_2016.asc." 1>&2; return 10; }

    apt-key add oracle_vbox_2016.asc
    rm oracle_vbox_2016.asc

    add-apt-repository "deb http://download.virtualbox.org/virtualbox/debian ${OS_CODENAME} contrib" ||
        { echo "[ERROR] Cannot add virtualbox.org repository to APT sources." 1>&2; return 10; }

    apt-get -y -qq update &&
    apt-get -y -q install virtualbox-${VB_VERSION} ||
        { echo "[ERROR] Cannot install virtualbox-${VB_VERSION}." 1>&2; return 20; }
}

# they have changed versioning and made Debain Repo. see https://www.virtualbox.org/wiki/Linux_Downloads
# https://download.virtualbox.org/virtualbox/6.0.6/virtualbox-6.0_6.0.6-130049~Ubuntu~bionic_amd64.deb
# https://download.virtualbox.org/virtualbox/6.0.6/virtualbox-6.0_6.0.6-130049~Ubuntu~xenial_amd64.deb
function install_virtualbox() {
    echo "[INFO] Running install_virtualbox..."

    local VERSION=6.1.16
    local VBE_URL=https://download.virtualbox.org/virtualbox/${VERSION}/Oracle_VM_VirtualBox_Extension_Pack-${VERSION}.vbox-extpack

    install_virtualbox_core || return $?

    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        usermod -aG vboxusers "${USER_NAME}"
    fi

    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl -fsSL -O "${VBE_URL}" ||
        { echo "[ERROR] Cannot download Virtualbox Extention pack." 1>&2; popd; return 30; }
    yes | VBoxManage extpack install --replace "${VBE_URL##*/}" ||
        { echo "[ERROR] Cannot install Virtualbox Extention pack." 1>&2; popd; return 40; }
    /sbin/vboxconfig ||
        { echo "[ERROR] Cannot configure Virtualbox." 1>&2; popd; return 50; }

    #cleanup
    rm -f "${VBE_URL##*/}"

    popd &&
    rm -rf "${TMP_DIR}"
    log_version vboxmanage --version
}

function install_rust() {
    echo "[INFO] Running install_rust..."
    curl https://sh.rustup.rs -sSf | sh -y ||
        { echo "[ERROR] Cannot install Rust." 1>&2; return 10; }

    log_version cargo --version
    log_version rustc --version
}

function install_clang() {
    echo "[INFO] Running install_clang..."
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

    install_clang_version 9
    install_clang_version 10
    install_clang_version 11

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

function install_octo() {
    echo "[INFO] Running install_octo..."
    local OCTO_VERSION OCTO_URL
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        OCTO_VERSION=6.17.0
    else
        OCTO_VERSION=$1
    fi
    OCTO_URL="https://download.octopusdeploy.com/octopus-tools/${OCTO_VERSION}/OctopusTools.${OCTO_VERSION}.ubuntu.16.04-x64.tar.gz"
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl -fsSL "${OCTO_URL}" -o OctopusTools.tar.gz ||
        { echo "[ERROR] Cannot download OctopusTools." 1>&2; popd; return 10; }
    mkdir -p /opt/octopus &&
    tar zxf OctopusTools.tar.gz -C /opt/octopus ||
        { echo "[ERROR] Cannot unpack and copy OctopusTools." 1>&2; popd; return 20; }
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        write_line "${HOME}/.profile" 'add2path /opt/octopus'
    else
        echo "[WARNING] User '${USER_NAME-}' not found. User's profile will not be configured."
    fi
    log_version /opt/octopus/Octo version
    # cleanup
    rm OctopusTools.tar.gz
    popd &&
    rm -rf "${TMP_DIR}"
}

function install_vcpkg() {
    echo "[INFO] Running install_vcpkg..."

    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}' user. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    pushd "${HOME}"
    command -v git ||
        { echo "[ERROR] Cannot find git. Please install git first." 1>&2; return 10; }
    local TOOL
    for TOOL in curl unzip tar; do
        command -v "${TOOL}" ||
            { echo "[ERROR] Cannot find '${TOOL}'. Please install '${TOOL}' first." 1>&2; return 10; }
    done

    git clone --depth 1 https://github.com/Microsoft/vcpkg.git &&
    pushd vcpkg
    ./bootstrap-vcpkg.sh ||
        { echo "[ERROR] Cannot bootstrap vcpkg." 1>&2; popd; return 10; }

    write_line "${HOME}/.profile" 'add2path_suffix ${HOME}/vcpkg'
    export PATH="$PATH:${HOME}/vcpkg"
    vcpkg integrate install ||
        { echo "[WARNING] 'vcpkg integrate install' Failed." 1>&2; }

    popd
    popd
    log_version vcpkg version
}

function install_qt() {
    echo "[INFO] Installing Qt..."
    if [ -f "../Windows/install_qt_fast_linux.ps1" ] && command -v pwsh; then
        pwsh -nol -noni ../Windows/install_qt_fast_linux.ps1
    else
        echo '[ERROR] Cannot run install_qt_fast_linux.ps1: Either PowerShell is not installed or install_qt_fast_linux.ps1 does not exist.' 1>&2;
        return 10;
    fi
}

function install_doxygen() {
    echo "[INFO] Running ${FUNCNAME[0]}..."
    install_doxygen_version '1.8.20'
}

function install_doxygen_version() {
    echo "[INFO] Running ${FUNCNAME[0]}..."
    local DOXYGEN_VERSION
    local DOXYGEN_URL
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        DOXYGEN_VERSION=1.8.20
    else
        DOXYGEN_VERSION=$1
    fi
    DOXYGEN_URL=https://phoenixnap.dl.sourceforge.net/project/doxygen/rel-${DOXYGEN_VERSION}/doxygen-${DOXYGEN_VERSION}.linux.bin.tar.gz
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl -fsSL -o doxygen.tar.gz "$DOXYGEN_URL" &&
    tar -xzf doxygen.tar.gz ||
        { echo "[ERROR] Cannot download and unpack doxygen from '$DOXYGEN_URL'." 1>&2; popd; return 10; }
    cp -a doxygen-${DOXYGEN_VERSION}/bin/doxy* /usr/local/bin
    popd
    log_version doxygen --version
}

function add_ssh_known_hosts() {
    echo "[INFO] Configuring ~/.ssh/known_hosts..."
    if [ -f "../Windows/add_ssh_known_hosts.ps1" ] && command -v pwsh; then
        pwsh -nol -noni ../Windows/add_ssh_known_hosts.ps1
        echo $HOME
        chmod 700 $HOME/.ssh
    else
        echo '[ERROR] Cannot run add_ssh_known_hosts.ps1: Either Powershell is not installed or add_ssh_known_hosts.ps1 does not exist.' 1>&2;
        return 10;
    fi
}

function configure_path() {
    echo "[INFO] Running configure_path..."
    #shellcheck disable=SC2016,SC2028
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
    /etc/init.d/ssh restart
}

function configure_motd() {
    chmod -x /etc/update-motd.d/*
    #shellcheck disable=SC2016,SC2028
    echo '#!/bin/sh
[ -r /etc/os-release ] && . /etc/os-release
printf "Appveyor Worker\n"
printf "OS %s (%s %s %s)\n" "$PRETTY_NAME" "$(uname -o)" "$(uname -r)" "$(uname -m)"
' >/etc/update-motd.d/00-appveyor

    chmod +x /etc/update-motd.d/00-appveyor
}

function configure_firewall() {
    echo "[INFO] Running configure_firewall..."
    ufw default deny incoming
    ufw default allow outgoing
    ufw --force enable
    ufw status verbose
}

function fix_grub_timeout() {
    # https://askubuntu.com/questions/1114797/grub-timeout-set-to-30-after-upgrade
    echo 'Fixing GRUB_TIMEOUT'
    echo "GRUB_RECORDFAIL_TIMEOUT=0" >> /etc/default/grub &&
    update-grub &&
    grub-install ||
        { echo "[ERROR] Cannot update grub." 1>&2; return 10; }
}

function check_folders() {
    if [ "$#" -gt 0 ]; then
        while [[ "$#" -gt 0 ]]; do
            # echo "$FUNCNAME $1"
            du -hs $1 2>/dev/null | sort -h |tail
            shift
        done
    fi
}

function cleanup() {
    echo "[INFO] Running cleanup..."
    # remove list of packages.
    # It frees up ~140Mb but it force users to execute `apt-get -y -qq update`
    # prior to install any other packages
    #rm -rf /var/lib/apt/lists/*

    apt-get -y -q autoremove

    # cleanup Systemd Journals
    if command -v journalctl; then
        journalctl --rotate
        journalctl --vacuum-time=1s
    fi
    # clean bash_history
    [ -f ${HOME}/.bash_history ] && cat /dev/null > ${HOME}/.bash_history
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        [ -f "${USER_HOME}/.bash_history" ] && cat /dev/null > "${USER_HOME}/.bash_history"
        chown "$(id -u "${USER_NAME}"):$(id -g "${USER_NAME}")" -R "${USER_HOME}"
    fi

    # cleanup script guts
    find $HOME -maxdepth 1 -name "*.sh" -delete

    #log some data about image size
    log_version df -h
    log_version ls -ltra "${HOME}"
    log_version check_folders ${HOME}/.*
    log_version check_folders "/*" "/opt/*" "/var/*" "/var/lib/*" "/var/cache/*" "/usr/*" "/usr/lib/*" "/usr/share/*"
}
