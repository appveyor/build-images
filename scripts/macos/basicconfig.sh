#!/bin/bash -e

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

#search for brew
echo "PATH variable:"
echo "$PATH" | tr ":" '\n'
if ! command -v brew; then
    if [ -x /usr/local/bin/brew ]; then
        export PATH="$PATH:/usr/local/bin"
    else
        echo "[ERROR] cannot find brew in default path /usr/local/bin or in \$PATH."
    fi
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
configure_updates
configure_sshd
install_cvs
install_gpg
install_rvm_and_rubies
install_fastlane
install_cmake
install_gcc
install_openjdk
install_virtualenv
su -l "${USER_NAME}" -c "
        PATH=$PATH
        USER_NAME=${USER_NAME}
        $(declare -f log_version)
        $(declare -f install_pip)
        $(declare -f install_virtualenv)
        $(declare -f install_pythons)
        install_pythons" ||
    _abort $?
install_xcode

su -l "${USER_NAME}" -c "
        PATH=$PATH
        USER_NAME=${USER_NAME}
        VERSIONS_FILE=${VERSIONS_FILE}
        $(declare -f log_version)
        $(declare -f add_line)
        $(declare -f replace_line)
        $(declare -f write_line)
        $(declare -f global_json)
        $(declare -f preheat_dotnet_sdks)
        $(declare -f install_dotnets)
        install_dotnets" ||
    _abort $?
install_cocoapods
install_mono
install_gvm_and_golangs
install_nvm_and_nodejs
configure_term
cleanup
