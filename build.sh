#!/bin/bash -eu

# This script checks that all variables are set and starts packer.
# this script should execute in an container.
#
# One must specify template filename in $TEMPLATE variable:
# TEMPLATE=ubuntu1604
#
# One can specify builders which should be build in variable $builders:
# builders=googlecompute,hyperv-vmcx,hyperv-iso,amazon-ebs,virtualbox-iso,vmware-iso,azure-arm

readonly AZURE_VARS="azure_client_id azure_client_secret azure_location azure_resource_group_name azure_subscription_id"
readonly GCE_VARS="gce_account_file gce_project gce_zone"
readonly AWS_VARS="aws_access_key aws_secret_key aws_region aws_security_group_id aws_subnet_id"
readonly AWS_OPT_VARS="aws_ssh_keypair_name aws_ssh_private_key_file"
readonly VIRTUALBOX_VARS="host_ip_addr host_ip_mask host_ip_gw"
readonly APPVEYOR_CREDENTIALS="install_user install_password"
readonly APPVEYOR_BUILD_VARS="APPVEYOR_BUILD_VERSION APPVEYOR_BUILD_NUMBER APPVEYOR_REPO_COMMIT APPVEYOR_REPO_COMMIT_MESSAGE"
PACKER_PARAMS=( )

function check_env_vars() {
    local v
    if [ "$#" -gt 0 ]; then
        for v in "$@"; do
            # echo "$v"
            # echo "\$$v $(eval echo \$$v)"
            [ -z ${!v+x} ] && { echo "Error: Please define $v variable."; return 10; }
        done
    fi
    return 0
}

function make_params() {
    local v
    if [ "$#" -gt 0 ]; then
        for v in "$@"; do
            if [[ -n "${!v-}" ]]; then
                PACKER_PARAMS+=( "-var"  "${v}=${!v}" )
            fi
        done
    fi
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
  amazon-* )
    # prepare ssh private key file, if exist
    if [[ -n "${aws_ssh_private_key_file-}" ]] && [[ -n "${aws_ssh_private_key_base64-}" ]]; then
        echo "${aws_ssh_private_key_base64}" | base64 -d > "${aws_ssh_private_key_file}"
    fi
    make_params "aws_region"
    ;;
esac
if [[ $builders =~ azure- ]]; then check_env_vars ${AZURE_VARS} || exit $?; make_params ${AZURE_VARS}; fi
if [[ $builders =~ amazon- ]]; then check_env_vars ${AWS_VARS} || exit $?; make_params ${AWS_VARS} ${AWS_OPT_VARS}; fi
if [[ $builders =~ google ]]; then check_env_vars ${GCE_VARS} || exit $?; make_params ${GCE_VARS}; fi
if [[ $builders =~ virtualbox- ]]; then check_env_vars ${VIRTUALBOX_VARS} || exit $?; make_params ${VIRTUALBOX_VARS}; fi
make_params ${APPVEYOR_CREDENTIALS}

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

if check_env_vars ${APPVEYOR_BUILD_VARS}; then
    DESCR="build N ${APPVEYOR_BUILD_VERSION}, ${APPVEYOR_REPO_COMMIT:0:7}, ${APPVEYOR_REPO_COMMIT_MESSAGE}"
    PACKER_PARAMS+=( "-var" "image_description=${DESCR}" )
fi

if [[ -n "${DEPLOY_PARTS-}" ]]; then
    PACKER_PARAMS+=( "-var" "deploy_parts=${DEPLOY_PARTS}" )
    echo "DEPLOY_PARTS set to ${DEPLOY_PARTS}"
fi

if [[ -n "${APPVEYOR_BUILD_AGENT_VERSION-}" ]]; then
    PACKER_PARAMS+=( "-var" "APPVEYOR_BUILD_AGENT_VERSION=${APPVEYOR_BUILD_AGENT_VERSION}" )
    echo "APPVEYOR_BUILD_AGENT_VERSION set to ${APPVEYOR_BUILD_AGENT_VERSION}"
fi

if [[ -n "${OPT_FEATURES-}" ]]; then
    PACKER_PARAMS+=( "-var" "opt_features=${OPT_FEATURES}" )
    echo "OPT_FEATURES set to ${OPT_FEATURES}"
fi

if [[ -n "${build_agent_mode-}" ]]; then
    echo "build_agent_mode set to ${build_agent_mode}"
    PACKER_PARAMS+=( "-var" "build_agent_mode=${build_agent_mode}" )
fi

# check template exists
if [[ -z "${TEMPLATE-}" ]]; then
    echo "[ERROR] TEMPLATE variable not set."
    exit 10
fi
if [ ! -f "${TEMPLATE}.json" ]; then
    echo "[ERROR] There is no '${TEMPLATE}.json' template to instruct packer. Aborting build."
    exit 10
fi

# set packer log file
if [[ -n "${APPVEYOR_BUILD_VERSION-}" ]]; then
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
        "${PACKER_PARAMS[@]}" ${packer_custom_args-} \
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
    # this might be parametrized with packer_manifest variable
    if [ -f "./packer-manifest.json" ]; then
        mv "./packer-manifest.json" /mnt/packer-logs/packer-manifest-${DATEMARK}.json
    fi
fi

# slack notification
if [[ -n "${slackhook_url-}" ]]; then
    curl -X POST -H 'Content-type: application/json' \
    --data "{'text':'Image Build finished:\\n${TEMPLATE}\\n${DESCR-}\\n${PACKER_LOG}\\nversions-${DATEMARK}.log\\npwd-${DATEMARK}.log'}" \
    "${slackhook_url}"
else
    echo 'Cannot notify Slack: $slackhook_url not set'
fi

