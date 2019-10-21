#!/bin/bash -e

USER_NAME="appveyor"
OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')
PlistBuddy="/usr/libexec/PlistBuddy"

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

function log() {
    local TIMESTAMP
    # shellcheck disable=SC2102
    TIMESTAMP=$(date +[%Y%m%d--%H:%M:%S])
    echo "$TIMESTAMP (${SCRIPT_PID}): $*"
    echo "$TIMESTAMP (${SCRIPT_PID}): $*" >> "${LOG_FILE}" 2>&1
}

function log_exec() {
    log "$@";
    "$@" 2>&1 | tee -a "${LOG_FILE}"
}

function log_version() {
    if [ -n "${VERSIONS_FILE-}" ]; then
        {
            echo "$@";
            "$@" 2>&1
        } | tee -a "${VERSIONS_FILE}"
    fi
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




function install_fastline() {
    command -v brew ||
        { echo "Cannot find brew. Install Homebrew first!" 1>&2; return 10; }
    brew cask install fastlane ||
    { echo "Cannot install Fastline." 1>&2; return 20; }
    write_line "${HOME}/.profile" 'export PATH="$HOME/.fastlane/bin:$PATH"'
}

function install_rvm() {
    command -v gpg2 ||
        { echo "Cannot find gpg2. Install GPG first!" 1>&2; return 10; }
    gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    curl -fsSL https://get.rvm.io | bash -s stable
    # shellcheck disable=SC1090
    source "${HOME}/.rvm/scripts/rvm"
}

function install_rubies() {
    echo "[INFO] Running install_rubies..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    command -v rvm ||
        { echo "Cannot find rvm. Install rvm first!" 1>&2; return 10; }
    command -v brew ||
        { echo "Cannot find brew. Install Homebrew first!" 1>&2; return 20; }
    local v
    declare RUBY_VERSIONS=( "ruby-2.6" "ruby-2.7" )
    for v in "${RUBY_VERSIONS[@]}"; do
        rvm install "${v}" ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
    log_version rvm --version
    log_version rvm list
}

function install_rvm_and_rubies() {
    echo "[INFO] Running install_rvm_and_rubies..."
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && id -un ${USER_NAME}  >/dev/null; then
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
