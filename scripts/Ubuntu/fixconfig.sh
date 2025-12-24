#!/bin/bash -eu
#shellcheck disable=SC2086,SC2015,SC2164

DEBUG=false

if [[ -z "${USER_NAME-}" || "${#USER_NAME}" = "0" ]]; then USER_NAME=appveyor; fi
if [[ -z "${USER_HOME-}" || "${#USER_HOME}" = "0" ]]; then USER_HOME=/home/appveyor; fi
if [[ -z "${DATEMARK-}" || "${#DATEMARK}" = "0" ]]; then DATEMARK=$(date +%Y%m%d%H%M%S); fi
HOST_NAME=appveyor-vm
MSSQL_SA_PASSWORD=Password12!
MYSQL_ROOT_PASSWORD=Password12!
POSTGRES_ROOT_PASSWORD=Password12!
CURRENT_NODEJS=8
AGENT_DIR=/opt/appveyor/build-agent
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VERSIONS_FILE=$WORK_DIR/versions.log
LOGGING=true
SCRIPT_PID=$$

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root. Aborting." 1>&2
    exit 1
else
    echo "Running script as $(whoami)"
fi

OS_ARCH=$(uname -m)
if [[ $OS_ARCH == x86_64 ]] || [[ $OS_ARCH == amd64 ]]; then
    OS_ARCH="amd64"
elif [[ $OS_ARCH == arm64 ]] || [[ $OS_ARCH == aarch64 ]]; then
    OS_ARCH="arm64"
elif [[ $arch == arm* ]]; then
    OS_ARCH="arm"
else
    echo "Error: Unsupported architecture $OS_ARCH." 1>&2
    exit 1
fi

# search for scripts we source
LIB_FOLDERS=( "${HOME}/scripts" "${WORK_DIR}" "${HOME}" )
echo "[DEBUG] Searching installation scripts in ${LIB_FOLDERS[*]}"
for LIB_FOLDER in "${LIB_FOLDERS[@]}"; do
    if [ -f "${LIB_FOLDER}/common.sh" ]; then
        echo "[DEBUG] installation scripts found in ${LIB_FOLDER}"
        break
    fi
done

# shellcheck source=./common.sh
. "${LIB_FOLDER}/common.sh" ||
        { echo "[ERROR] Cannot source common.sh script. Aborting." 1>&2; exit 2; }

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    OS_CODENAME=$(source /etc/os-release && echo $VERSION_CODENAME)
    if [ -f "${LIB_FOLDER}/${OS_CODENAME}.sh" ]; then
        # shellcheck source=./bionic.sh
        . "${LIB_FOLDER}/${OS_CODENAME}.sh" ||
            { echo "[WARNING] Cannot source ${OS_CODENAME}.sh script." 1>&2; }
    fi
else
    echo "[WARNING] /etc/os-release not found - cant find VERSION_CODENAME. Will not install OS specific applications."
fi

function monitoring_host() {
    echo
    echo "-------------- Monitoring info ---------------"
    df -h
    ping 8.8.8.8 -c 4
    echo "-------------- Monitoring info ---------------"
    echo
}

function _abort() {
    monitoring_host
    echo "Aborting." 1>&2
    exit "$1"
}

function _continue() {
    monitoring_host
    echo "Continue installation..." 1>&2
}

init_logging


configure_path

# write_line "${HOME}/.profile" 'add2path_suffix /home/appveyor/.rbenv/bin'
# export PATH="$PATH:${HOME}/.rbenv/bin"
# apt-get -y -q install gcc-12 g++-12 && \
# update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 40 --slave /usr/bin/g++ g++ /usr/bin/g++-12 ||
#         { echo "[ERROR] Cannot install gcc-12." 1>&2; return 40; }
# type cd
# cat $HOME/.profile
# write_line "${HOME}/.profile" 'unset -f cd'
# cat $HOME/.profile
# su -l ${USER_NAME} -c "
#         USER_NAME=${USER_NAME}
#         $(declare -f install_google_chrome)
#         install_google_chrome" ||
#     _abort $?


# install_docker_compose ||
#     _abort $?


# install_qt ||
#     _abort $?

sudo apt-get update
sudo apt-get install -y ca-certificates
sudo update-ca-certificates


cleanup
