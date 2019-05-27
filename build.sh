#!/bin/bash -e

# This script checks that all variables are set and starts packer.
# this script should execute in an container.
#
# One must specify template filename in $TEMPLATE variable:
# TEMPLATE=ubuntu1604
#
# One can specify builders which should be build in variable $builders:
# builders=googlecompute,hyperv-vmcx,hyperv-iso,amazon-ebs,virtualbox-iso,vmware-iso,azure-arm

readonly AZURE_VARS="azure_client_id azure_client_secret azure_location azure_resource_group_name azure_storage_account azure_subscription_id"
readonly GCE_VARS="gce_account_file gce_project gce_zone"
readonly AWS_VARS="aws_access_key aws_secret_key aws_region"
readonly APPVEYOR_CREDENTIALS="appveyor_user appveyor_password"
readonly APPVEYOR_VARS="APPVEYOR_BUILD_NUMBER APPVEYOR_REPO_COMMIT APPVEYOR_REPO_COMMIT_MESSAGE"
PACKER_PARAMS=( )

function check_env_vars() {
    for v in "$@"; do
        # echo "$v"
        # echo "\$$v $(eval echo \$$v)"
        [ -z ${!v+x} ] && { echo "Error: Please define $v variable."; return 10; }
    done
    return 0
}

function make_params() {
    for v in "$@"; do
        PACKER_PARAMS+=( "-var"  "${v}=${!v}" )
    done
}

# check that all required variables are set
if [[ -z "${builders}" ]]; then
    echo "Builders variable not set. You should specify which packer builders to build in $builders variable.";
    exit 10;
fi
case "${builders}" in
  google* )
    # prepare account file
    echo "${gce_account_file}" > gce_account.json
    gce_account_file=gce_account.json
    ;;
esac
if [[ $builders =~ azure- ]]; then check_env_vars ${AZURE_VARS} || exit $?; make_params ${AZURE_VARS}; fi
if [[ $builders =~ amazon- ]]; then check_env_vars ${AWS_VARS} || exit $?; make_params ${AWS_VARS}; fi
if [[ $builders =~ google ]]; then check_env_vars ${GCE_VARS} || exit $?; make_params ${GCE_VARS}; fi

# check secret files passed to container
if [[ $builders =~ google ]]; then
    if [ ! -f "${gce_account_file}" ]; then
        echo "[ERROR] There is no '${gce_account_file}' file. packer require it to authenticate in GCE. Aborting build."
        exit 10
    fi
fi

# set additional parameters:
PACKER_CMD=$(which packer)
DATEMARK=$(date +%Y%m%d%H%M%S)
PACKER_PARAMS+=( "-var"  "datemark=${DATEMARK}" )

if check_env_vars ${APPVEYOR_VARS}; then
    DESCR="build N ${APPVEYOR_BUILD_NUMBER}, ${APPVEYOR_REPO_COMMIT:0:7}, ${APPVEYOR_REPO_COMMIT_MESSAGE}"
    PACKER_PARAMS+=( "-var"  "image_description=${DESCR}" )
fi

# check template exists
if [[ -z "${TEMPLATE}" ]]; then
    echo "[ERROR] TEMPLATE variable not set."
    exit 10
fi
if [ ! -f "${TEMPLATE}.json" ]; then
    echo "[ERROR] There is no '${TEMPLATE}.json' template to instruct packer. Aborting build."
    exit 10
fi

# set packer log file
if [[ -n "${APPVEYOR_BUILD_VERSION}" ]]; then
    PACKER_LOG=packer-${APPVEYOR_BUILD_VERSION}-${builders}-${TEMPLATE}-${DATEMARK}.log
else
    PACKER_LOG=packer-${builders}-${TEMPLATE}-${DATEMARK}.log
fi

if [ -d /mnt/packer-logs ]   # for file "if [-f /home/rama/file]" 
then
    APPVEYOR_LOGS_PATH=/mnt/packer-logs/${PACKER_LOG}
else
    APPVEYOR_LOGS_PATH=./${PACKER_LOG}
fi

# run packer
PACKER_LOG_PATH=${APPVEYOR_LOGS_PATH} PACKER_LOG=1 CHECKPOINT_DISABLE=1 ${PACKER_CMD} build \
        --only=${builders} \
        -var "install_user=${appveyor_user}" \
        -var "install_password=${appveyor_password}" \
        -var "build_agent_mode=${build_agent_mode}" \
        "${PACKER_PARAMS[@]}" \
        ${TEMPLATE}.json

# run post packer (GCE, Hyperv)

# publish log files
if [ -d /mnt/packer-logs ]; then
    if [ -f "./versions-${DATEMARK}.log" ]; then
        mv "./versions-${DATEMARK}.log" /mnt/packer-logs/
    fi

    if [ -f "./pwd-${DATEMARK}.log" ]; then
        mv "./pwd-${DATEMARK}.log" /mnt/packer-logs/
    fi
fi

# slack notification
if [[ -n "${slackhook_url}" ]]; then
    curl -X POST -H 'Content-type: application/json' \
    --data "{'text':'Image Build finished:\\n${TEMPLATE}\\n${DESCR}\\n${PACKER_LOG}\\nversions-${DATEMARK}.log\\npwd-${DATEMARK}.log'}" \
    "${slackhook_url}"
fi

