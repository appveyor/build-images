#!/bin/bash -eu
#shellcheck disable=SC2086,SC2015,SC2164
DEBUG=false

if [[ -z "$USER_NAME" || "${#USER_NAME}" = "0" ]]; then USER_NAME=appveyor; fi
if [[ -z "$USER_HOME" || "${#USER_HOME}" = "0" ]]; then USER_HOME=/home/appveyor; fi
if [[ -z "$DATEMARK" || "${#DATEMARK}" = "0" ]]; then DATEMARK=$(date +%Y%m%d%H%M%S); fi
HOST_NAME=appveyor-vm
MSSQL_SA_PASSWORD=Password12!
MYSQL_ROOT_PASSWORD=Password12!
POSTGRES_ROOT_PASSWORD=Password12!
CURRENT_NODEJS=8
AGENT_DIR=/opt/appveyor/build-agent
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE=$HOME/versions-$DATEMARK.log
LOGGING=true
SCRIPT_PID=$$

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root. Aborting." 1>&2
    exit 1
fi

case  ${PACKER_BUILDER_TYPE} in
    googlecompute )
        BUILD_AGENT_MODE=GCE;;
    hyperv* )
        BUILD_AGENT_MODE=HyperV;;
    azure* )
        BUILD_AGENT_MODE=Azure;;
    * )
        BUILD_AGENT_MODE=GCE;;
esac

# search for scripts we source
LIB_FOLDERS=( "${HOME}/scripts" "${WORK_DIR}" "${HOME}" )
for LIB_FOLDER in "${LIB_FOLDERS[@]}"; do
    if [ -f "${LIB_FOLDER}/common.sh" ]; then
        echo "[DEBUG] installation scripts found in ${LIB_FOLDERS[*]}"
        break
    fi
done

# shellcheck source=./common.sh
. "${LIB_FOLDER}/common.sh" ||
        { echo "[ERROR] Cannot source common.sh script. Aborting." 1>&2; exit 2; }

if [ -f /etc/os-release ]; then
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

# we have to create pwd.log, otherwise packer will fail on provisioner which downloads it.
touch ${HOME}/pwd.log

init_logging

# execute only required parts of deployment
if [ "$#" -gt 0 ]; then
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            install_buildagent)     install_buildagent "${BUILD_AGENT_MODE}" || _abort $?; ;;
            *)                      echo "[ERROR] Unknown argument '$1'"; ;;
        esac
        shift
    done
    exit 0
fi

configure_path

configure_locale

add_user ||
    _abort $?

chown_logfile || _continue

configure_apt ||
    _abort $?

install_tools ||
    _abort $?

if [ "${BUILD_AGENT_MODE}" == "HyperV" ]; then
    install_KVP_packages ||
        _abort $?
fi

install_appveyoragent "${BUILD_AGENT_MODE}" ||
    _abort $?

if ! ${DEBUG}; then                          ### Disabled for faster debugging

install_gcc ||
    _abort $?

install_clang ||
    _abort $?

install_p7zip

install_pip ||
    _abort $?

su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        $(declare -f install_pythons)
        install_pythons" ||
    _abort $?

# .NET stuff
install_dotnets ||
    _abort $?
install_powershell ||
    _abort $?

# install_buildagent "${BUILD_AGENT_MODE}" ||
#      _abort $?


make_git 2.21.0 ||
    _abort $?

install_gitlfs ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        $(declare -f configure_gitlfs)
        configure_gitlfs" ||
    _abort $?

su -l ${USER_NAME} -c "
        curl -sflL 'https://raw.githubusercontent.com/appveyor/secure-file/master/install.sh' | bash -e -" ||
    _abort $?

install_docker ||
    _abort $?

install_nodejs ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        $(declare -f install_nvm)
        $(declare -f write_line)
        $(declare -f add_line)
        $(declare -f replace_line)
        install_nvm" ||
    _abort $?
su -l ${USER_NAME} -c "
        [ -s \"${HOME}/.nvm/nvm.sh\" ] && . \"${HOME}/.nvm/nvm.sh\"
        USER_NAME=${USER_NAME}
        $(declare -f init_logging)
        init_logging
        $(declare -f log)
        $(declare -f log_exec)
        $(declare -f install_nvm_nodejs)
        install_nvm_nodejs ${CURRENT_NODEJS}" ||
    _abort $?

install_cvs ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        $(declare -f configure_svn)
        configure_svn" ||
    _abort $?
install_virtualbox 6.0.6 ||
    _continue $?
install_mysql ||
    _abort $?
install_postgresql ||
    _abort $?
install_redis ||
    _abort $?
install_mongodb ||
    _abort $?
install_rabbitmq ||
    _abort $?

# Go lang
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        $(declare -f install_gvm)
        $(declare -f write_line)
        $(declare -f add_line)
        $(declare -f replace_line)
        install_gvm" ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        source \"${HOME}/.gvm/scripts/gvm\"
        $(declare -f init_logging)
        init_logging
        $(declare -f log)
        $(declare -f log_exec)
        $(declare -f install_golangs)
        install_golangs" ||
    _abort $?

install_jdks ||
    _abort $?

install_jdk 9 https://download.java.net/java/GA/jdk9/9.0.4/binaries/openjdk-9.0.4_linux-x64_bin.tar.gz ||
    _abort $?
install_jdk 10 https://download.java.net/openjdk/jdk10/ri/openjdk-10+44_linux-x64_bin_ri.tar.gz ||
    _abort $?
install_jdk 11 https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz ||
    _abort $?
install_jdk 12 https://download.java.net/openjdk/jdk12/ri/openjdk-12+32_linux-x64_bin.tar.gz ||
    _abort $?
install_jdk 13 https://download.java.net/java/early_access/jdk13/21/GPL/openjdk-13-ea+21_linux-x64_bin.tar.gz ||
    _abort $?

OFS=$IFS
IFS=$'\n'
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        $(declare -f configure_jdk)
        $(declare -f write_line)
        $(declare -f add_line)
        $(declare -f replace_line)
        configure_jdk" <<< "${PROFILE_LINES[*]}" ||
    _abort $?
IFS=$OFS

# Ruby
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        $(declare -f install_rvm)
        install_rvm" ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        [[ -s \"${HOME}/.rvm/scripts/rvm\" ]] && source \"${HOME}/.rvm/scripts/rvm\"
        $(declare -f init_logging)
        init_logging
        $(declare -f log)
        $(declare -f log_exec)
        $(declare -f install_rubies)
        install_rubies" ||
    _abort $?

install_mono ||
    _abort $?

install_sqlserver ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD}
        $(declare -f configure_sqlserver)
        $(declare -f write_line)
        $(declare -f add_line)
        $(declare -f replace_line)
        configure_sqlserver" ||
    _abort $?
disable_sqlserver ||
    _abort $?

install_yarn ||
    _abort $?
install_packer 1.4.0 ||
    _abort $?

install_awscli ||
    _abort $?
install_localstack || _continue
install_azurecli ||
    _abort $?
install_kubectl ||
    _abort $?
install_cmake 3.14.3 ||
    _abort $?
# install_curl 7.63.0 ||
#     _abort $?
install_browsers ||
    _abort $?
update_nuget ||
    _abort $?
add_ssh_known_hosts ||
    _continue $?
fi
configure_sshd ||
    _abort $?
configure_uefi ||
    _abort $?
configure_network ||
    _abort $?

cleanup
