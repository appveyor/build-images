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
CURRENT_NODEJS=16
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
            BUILD_AGENT_MODE='';;
    esac
fi

if [[ -z "${BUILD_AGENT_MODE-}" ]] && [[ ${OS_ARCH-} == "arm64" ]]; then
    BUILD_AGENT_MODE=AmazonEC2
fi

echo "OS_ARCH: ${OS_ARCH}"
echo "BUILD_AGENT_MODE: ${BUILD_AGENT_MODE}"

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

wait_cloudinit || _continue

configure_network ||
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
    cleanup         #cleanup should be executed each time.
    exit 0
fi


configure_path

if [[ -z "${BOOTSTRAP-}" || "${#BOOTSTRAP}" = "0" ]]; then
    add_user ||
        _abort $?
fi

chown_logfile || _continue

disable_automatic_apt_updates ||
    _abort $?

if [[ $OS_ARCH == "amd64" ]]; then
    configure_apt ||
        _abort $?
fi

configure_locale

install_tools ||
    _abort $?

if [ "${BUILD_AGENT_MODE}" == "HyperV" ]; then
    install_KVP_packages ||
        _abort $?
fi

if [[ -z "${BOOTSTRAP-}" || "${#BOOTSTRAP}" = "0" ]]; then
    install_appveyoragent "${BUILD_AGENT_MODE}" ||
        _abort $?
fi

install_7zip ||
    _abort $?

if [[ $OS_ARCH == "amd64" ]]; then
    install_gcc ||
        _abort $?

    install_clang ||
        _abort $?

    install_powershell ||
        _abort $?
else
    install_powershell_arm64 ||
        _abort $?
fi

su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        OS_ARCH=${OS_ARCH}
        LIB_FOLDER=${LIB_FOLDER}
        $(declare -f add_ssh_known_hosts)
        add_ssh_known_hosts" ||
    _abort $?

install_cvs ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        OS_ARCH=${OS_ARCH}
        $(declare -f configure_svn)
        configure_svn" ||
    _abort $?

update_git ||
    _abort $?

install_gitlfs ||
    _abort $?

install_gitversion ||
    _abort $?

if [[ $OS_ARCH == "amd64" ]]; then
    install_pip ||
        _abort $?
else
    install_pip3 ||
        _abort $?
fi

install_virtualenv ||
    _abort $?

if [[ $OS_ARCH == "amd64" ]]; then
    install_octo ||
        _abort $?
fi

su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        OS_ARCH=${OS_ARCH}
        $(declare -f install_pythons)
        install_pythons" ||
    _abort $?

# JDK
install_jdks ||
    _abort $?

if [[ $OS_ARCH == "amd64" ]]; then
    su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            $(declare -f install_android_sdk)
            $(declare -f write_line)
            $(declare -f add_line)
            $(declare -f replace_line)
            $(declare -f log_version)
            install_android_sdk" ||
        _abort $?
else
    echo "TODO: install_android_sdk for ARM"
fi

if [[ $OS_ARCH == "amd64" ]]; then
    su -l ${USER_NAME} -c "
            USER_NAME=${USER_NAME}
            $(declare -f install_flutter)
            $(declare -f write_line)
            $(declare -f add_line)
            $(declare -f replace_line)
            $(declare -f log_version)
            install_flutter" ||
        _abort $?
else
    echo "TODO: install_flutter for ARM"
fi

# .NET stuff
if [[ $OS_ARCH == "amd64" ]]; then
    install_dotnets ||
        _abort $?
else
    install_dotnet_arm64 ||
        _abort $?
fi
preheat_dotnet_sdks &&
log_version dotnet --list-sdks &&
log_version dotnet --list-runtimes ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        OS_ARCH=${OS_ARCH}
        $(declare -f configure_nuget)
        configure_nuget" ||
    _abort $?

if [[ $OS_ARCH == "amd64" ]]; then
    su -l ${USER_NAME} -c "
            curl -sflL 'https://raw.githubusercontent.com/appveyor/secure-file/master/install.sh' | bash -e -" ||
        _abort $?

    install_docker ||
        _abort $?
else
    install_docker_arm64 ||
        _abort $?
fi

su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        OS_ARCH=${OS_ARCH}
        $(declare -f install_nvm)
        $(declare -f write_line)
        $(declare -f add_line)
        $(declare -f replace_line)
        install_nvm" ||
    _abort $?
su -l ${USER_NAME} -c "
        [ -s \"${HOME}/.nvm/nvm.sh\" ] && . \"${HOME}/.nvm/nvm.sh\"
        USER_NAME=${USER_NAME}
        OS_ARCH=${OS_ARCH}
        $(declare -f log_version)
        $(declare -f install_nvm_nodejs)
        install_nvm_nodejs ${CURRENT_NODEJS}" ||
    _abort $?

install_mysql ||
    _abort $?
install_postgresql ||
    _abort $?

install_redis ||
    _abort $?

if [[ $OS_ARCH == "amd64" ]]; then
    install_virtualbox ||
        _abort $?
    install_mongodb ||
        _abort $?
    install_rabbitmq ||
        _abort $?
    install_qt ||
        _abort $?     
fi

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
        $(declare -f log_version)
        $(declare -f install_golangs)
        install_golangs" ||
    _abort $?

# Ruby
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        OS_ARCH=${OS_ARCH}
        $(declare -f install_rvm)
        install_rvm" ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        OS_ARCH=${OS_ARCH}
        [[ -s \"${HOME}/.rvm/scripts/rvm\" ]] && source \"${HOME}/.rvm/scripts/rvm\"
        $(declare -f log_version)
        $(declare -f install_rubies)
        install_rubies" ||
    _abort $?

if [[ $OS_ARCH == "amd64" ]]; then
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

    install_doxygen ||
        _abort $?

    install_azurecli ||
        _abort $?        
else
    # arm64
    install_azurecli_arm64 ||
        _abort $?    
fi

install_yarn ||
    _abort $?
install_packer ||
    _abort $?
install_awscli ||
    _abort $?
install_gcloud ||
    _abort $?
install_kubectl ||
    _abort $?
install_cmake ||
    _abort $?
su -l ${USER_NAME} -c "
        USER_NAME=${USER_NAME}
        OS_ARCH=${OS_ARCH}
        $(declare -f install_vcpkg)
        $(declare -f write_line)
        $(declare -f add_line)
        $(declare -f replace_line)
        $(declare -f log_version)
        install_vcpkg" ||
    _abort $?
if [[ $OS_ARCH == "amd64" ]]; then
    install_browsers ||
        _abort $?
    update_nuget ||
        _abort $?
else
    install_browsers_arm64 ||
        _abort $?
fi

configure_sshd ||
    _abort $?
configure_firewall ||
    _abort $?
configure_motd ||
    _abort $?
configure_uefi ||
    _abort $?
fix_apt_sources ||
    _abort $?

if [ "${BUILD_AGENT_MODE}" == "HyperV" ]; then
    fix_grub_timeout ||
        _abort $?
fi


cleanup