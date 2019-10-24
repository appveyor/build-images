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

install_cvs
install_gpg
install_rvm_and_rubies
install_fastlane
install_dotnets
install_gvm_and_golangs
install_nvm_and_nodejs
