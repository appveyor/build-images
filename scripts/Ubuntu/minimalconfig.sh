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
fi

# Check for execution in docker container
if [[ -z "${IS_DOCKER-}" || "${#IS_DOCKER}" = "0" ]]; then
    if grep -Eq '/(lxc|docker)/[[:xdigit:]]{64}' /proc/1/cgroup; then
        IS_DOCKER=true
    else
        IS_DOCKER=false
    fi
fi

if [[ -z "${BOOTSTRAP-}" || "${#BOOTSTRAP}" = "0" ]]; then
    case  ${PACKER_BUILDER_TYPE-} in
        googlecompute )
            BUILD_AGENT_MODE=GCE;;
        hyperv* )
            BUILD_AGENT_MODE=HyperV;;
        azure* )
            BUILD_AGENT_MODE=Azure;;
        amazon-* )
            BUILD_AGENT_MODE=AmazonEC2;;
        * )
            BUILD_AGENT_MODE=''
            echo "[WARNING] Unknown packer builder '${PACKER_BUILDER_TYPE-}'. BUILD_AGENT_MODE variable not set." 1>&2
            ;;
    esac
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
    OS_CODENAME=$(source /etc/os-release && echo $VERSION_CODENAME)
    if [ -f "${LIB_FOLDER}/${OS_CODENAME}.sh" ]; then
        # shellcheck source=./bionic.sh
        . "${LIB_FOLDER}/${OS_CODENAME}.sh" ||
            { echo "[WARNING] Cannot source ${OS_CODENAME}.sh script." 1>&2; }
    fi
else
    echo "[WARNING] /etc/os-release not found - cant find VERSION_CODENAME. Will not install OS specific applications."
fi

function _abort() {
    echo "Aborting." 1>&2
    exit "$1"
}

function _continue() {
    echo "Continue installation..." 1>&2
}

init_logging

configure_path

if [[ -z "${BOOTSTRAP-}" || "${#BOOTSTRAP}" = "0" ]]; then
    add_user ||
        _abort $?
fi

if ! $IS_DOCKER; then
    wait_cloudinit || _continue

    configure_network ||
        _abort $?
fi

disable_automatic_apt_updates ||
    _abort $?

configure_apt ||
    _abort $?

configure_locale

install_tools ||
    _abort $?

if [ "${BUILD_AGENT_MODE}" == "HyperV" ]; then
    install_KVP_packages ||
        _abort $?
fi

if [ "${BUILD_AGENT_MODE}" == "Azure" ]; then
    install_azure_linux_agent ||
        _abort $?
fi

if $IS_DOCKER; then
    copy_appveyoragent ||
        _abort $?
else
    if [[ -z "${BOOTSTRAP-}" || "${#BOOTSTRAP}" = "0" ]]; then
        install_appveyoragent "${BUILD_AGENT_MODE}" ||
            _abort $?
    fi
fi

install_powershell ||
    _abort $?

install_cvs ||
    _abort $?

install_gitlfs ||
    _abort $?

# ====================================

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

# ====================================

su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        $(declare -f configure_svn)
        configure_svn" ||
    _abort $?

# execute optional Features
if [[ -n "${OPT_FEATURES-}" && "${#OPT_FEATURES}" -gt "0" ]]; then
    echo "[DEBUG] There is OPT_FEATURES variable defined: '$OPT_FEATURES'"
    OFS=$IFS; IFS=','; read -r -a arrFEATURES <<< "$OPT_FEATURES"; IFS=$OFS
    for i in "${!arrFEATURES[@]}"; do
        FEATURE=${arrFEATURES[i]}
        #shellcheck disable=SC2086
        WORD1=$(IFS=" " ; set -- $FEATURE ; echo "$1")
        if [ "$(type -t "$WORD1")x" == 'functionx' ]; then
            echo "[DEBUG] executing '$FEATURE'..."
            $FEATURE
        else
            echo "[WARNING] $WORD1 not a function, skipping"
        fi
    done
fi
# Deploy Parts of config
if [ "$#" -gt 0 ]; then
    echo "[DEBUG] $0 script have arguments: $*"
    while [[ "$#" -gt 0 ]]; do
        if [ "$(type -t $1)x" == 'functionx' ]; then
            echo "[DEBUG] argument recognized as a function to call: $1"
            if [ "$#" -gt 1 ] && [ "$(type -t $2)x" != 'functionx' ]; then
                #execute function with argument
                $1 $2
            else
                #execute function without argument
                $1
            fi
        else
            echo "[ERROR] Unknown argument '$1'";
        fi
        shift
    done
fi

add_ssh_known_hosts ||
    _continue $?
if ! $IS_DOCKER; then
    configure_sshd ||
        _abort $?
    configure_firewall ||
        _abort $?
    configure_uefi ||
        _abort $?
    if [ "${BUILD_AGENT_MODE}" == "HyperV" ]; then
        fix_grub_timeout ||
            _abort $?
    fi
fi
cleanup