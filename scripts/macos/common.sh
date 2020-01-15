#!/bin/bash -e
#shellcheck disable=SC2086,SC2015,SC2164

if [[ -z "${USER_NAME-}" || "${#USER_NAME}" = "0" ]]; then USER_NAME=appveyor; fi
if [[ -z "${USER_HOME-}" || "${#USER_HOME}" = "0" ]]; then USER_HOME=/home/appveyor; fi
if [[ -z "${VERSIONS_FILE-}" || "${#VERSIONS_FILE}" = "0" ]]; then VERSIONS_FILE=$HOME/versions.log; fi
HOST_NAME=appveyor-vm
OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')
PlistBuddy="/usr/libexec/PlistBuddy"
BREW_CMD=$(command -v brew)

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

function configure_path() {
    echo "[INFO] Running configure_path..."
    # shellcheck disable=SC2016
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

function check_user(){
    [ -n "${USER_NAME-}" ] &&
    [ "${#USER_NAME}" -gt "0" ] &&
    id -un ${USER_NAME}  >/dev/null
}

function brew_install() {
    run_brew "$@"
}

function brew_cask_install() {
    BREW_CASK=cask run_brew "$@"
}

function run_brew() {
    [ -x "${BREW_CMD-}" ] ||
        { echo "[ERROR] Cannot find brew. Install Homebrew first!" 1>&2; return 1; }
    if check_user; then
        su -l ${USER_NAME} -c "$BREW_CMD ${BREW_CASK-} install $*" ||
            { echo "[ERROR] Cannot install '$*' with Homebrew." 1>&2; return 20; }
    else
        echo "[WARNING] User '${USER_NAME-}' not found." 1>&2
    fi
}

function install_cvs() {
    echo "[INFO] Running install_cvs..."

    brew_install mercurial subversion git git-lfs
    if check_user; then
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
    echo "[INFO] Running configure_svn..."
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

function install_gpg() {
    echo "[INFO] Running install_gpg..."
    brew_install gnupg gnupg2
    if command -v gpg; then
        ln -s "$(command -v gpg)" "$(command -v gpg)2"
    fi

    log_version gpg --version
}

function install_fastlane() {
    echo "[INFO] Running install_fastlane..."

    # fastlane dependencies requires Ruby version >= 2.4.0.
    if command -v rvm; then
        # We take as granted that install_rubies set latest version as default
        rvm use default
    else
        echo "Cannot find rvm. Install rvm first!" 1>&2
        return 10
    fi

    brew_cask_install fastlane
    if check_user; then
        # shellcheck disable=SC2016
        write_line "${HOME}/.profile" 'export PATH="$HOME/.fastlane/bin:$PATH"'
    fi

}

function install_rvm() {
    echo "[INFO] Running install_rvm..."
    echo "gem: --no-document" >> $HOME/.gemrc
    command -v gpg ||
        { echo "Cannot find gpg. Install GPG first!" 1>&2; return 10; }
    gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
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
    local DEFAULT_RUBY
    DEFAULT_RUBY="ruby-2.6"
    command -v rvm ||
        { echo "Cannot find rvm. Install rvm first!" 1>&2; return 10; }
    local v
    declare RUBY_VERSIONS=( "ruby-2.0" "ruby-2.1" "ruby-2.2" "ruby-2.3" "ruby-2.4" "ruby-2.5" "ruby-2.6" "ruby-2.7" "ruby-head" )
    for v in "${RUBY_VERSIONS[@]}"; do
        rvm install "${v}" ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
    local index

    rvm use "$DEFAULT_RUBY" --default
    log_version rvm --version
    log_version rvm list
}

function install_rvm_and_rubies() {
    echo "[INFO] Running install_rvm_and_rubies..."
    if check_user; then
        su -l ${USER_NAME} -c "
            PATH=$PATH
            USER_NAME=${USER_NAME}
            $(declare -f install_rvm)
            install_rvm" &&
        su -l ${USER_NAME} -c "
            PATH=$PATH
            USER_NAME=${USER_NAME}
            VERSIONS_FILE=${VERSIONS_FILE}
            [[ -s \"${HOME}/.rvm/scripts/rvm\" ]] && source \"${HOME}/.rvm/scripts/rvm\"
            $(declare -f log_version)
            $(declare -f install_rubies)
            install_rubies" ||
                return $?
        # load RVM into current shell instance
        export PATH="$PATH:$HOME/.rvm/bin"
        #shellcheck disable=SC1090
        [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Cannot install RVM and rubies"
    fi
}

function install_gcc() {
    declare GCC_VERSIONS=( "gcc@6" "gcc@7" "gcc@8" )
    brew_install "${GCC_VERSIONS[@]}"
}

function install_cmake() {
    echo "[INFO] Running install_cmake..."
    local VERSION
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        VERSION=3.16.2
    else
        VERSION=$1
    fi
    local TAR_FILE=cmake-${VERSION}-Darwin-x86_64.tar.gz
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl -fsSL -O "https://cmake.org/files/v${VERSION%.*}/${TAR_FILE}" &&
    tar -zxf "${TAR_FILE}" ||
        { echo "[ERROR] Cannot download and untar cmake." 1>&2; popd; return 10; }
    DIR_NAME=$(tar -ztf ${TAR_FILE} |cut -d'/' -f1|sort|uniq|head -n1)
    cd -- "${DIR_NAME}" ||
        { echo "[ERROR] Cannot change directory to ${DIR_NAME}." 1>&2; popd; return 20; }
    [ -d "/Applications/CMake.app" ] && rm -rf "/Applications/CMake.app" || true
    cp -R CMake.app /Applications/ &&
    /Applications/CMake.app/Contents/bin/cmake-gui --install ||
        { echo "[ERROR] Cannot install cmake." 1>&2; popd; return 30; }
    log_version cmake --version
    popd &&
    rm -rf "${TMP_DIR}"
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
    echo "[INFO] Running install_pythons..."
    find /Library/Developer/CommandLineTools/Packages/ -name 'macOS_SDK_headers_*.pkg' |
        xargs -I {} sudo installer -pkg {} -target /

    brew install openssl sqilte3
    SSL_PATH=$(brew --prefix openssl)
    SQLITE_PATH=$(brew --prefix sqlite3)

    CPPFLAGS="-I${SSL_PATH}/include -I${SQLITE_PATH}/include -I$(xcrun --show-sdk-path)/usr/include"
    LDFLAGS="-L${SSL_PATH}/lib -L${SQLITE_PATH}/lib"

    command -v virtualenv || install_virtualenv
    declare PY_VERSIONS=( "2.6.9" "2.7.17" "3.4.10" "3.5.9" "3.6.9" "3.7.5" "3.8.0" "3.8.1" "3.9.0a2" )
    for i in "${PY_VERSIONS[@]}"; do
        VENV_PATH=${HOME}/venv${i%%[abrcf]*}
        if [ ! -d ${VENV_PATH} ]; then
        curl -fsSL -O "http://www.python.org/ftp/python/${i%%[abrcf]*}/Python-${i}.tgz" ||
            { echo "[WARNING] Cannot download Python ${i}."; continue; }
        tar -zxf Python-${i}.tgz &&
        pushd "Python-${i}" ||
            { echo "[WARNING] Cannot unpack Python ${i}."; continue; }
        PY_PATH=${HOME}/.localpython${i}
        mkdir -p "${PY_PATH}"
        ./configure --silent "--prefix=${PY_PATH}" "CPPFLAGS=${CPPFLAGS}" "LDFLAGS=${LDFLAGS}" &&
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
        fi
    done
    find "$HOME" -name "Python-*" -type d -maxdepth 1 | xargs -I {} rm -rf {}
    rm ${HOME}/Python-*.tgz
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

function install_dotnets() {
    echo "[INFO] Running install_dotnets..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    local SCRIPT_URL
    SCRIPT_URL="https://dot.net/v1/dotnet-install.sh"
    curl -fsSL "$SCRIPT_URL" -O ||
        { echo "[ERROR] Cannot download install script '$SCRIPT_URL'." 1>&2; return 10; }
    chmod a+x ./dotnet-install.sh
    declare DOTNET_VERSIONS=( "2.0" "2.1" "2.2" "3.0" "3.1" )
    for v in "${DOTNET_VERSIONS[@]}"; do
        echo "[INFO] Installing .NET Core ${v}..."
        ./dotnet-install.sh -channel "$v"
    done

    #shellcheck disable=SC2016
    write_line "${HOME}/.profile" 'add2path_suffix $HOME/.dotnet'
    export PATH="$PATH:$HOME/.dotnet"

    if command -v dotnet; then
        preheat_dotnet_sdks
        log_version dotnet --list-sdks
        log_version dotnet --list-runtimes
    else
        echo "[WARNING] Cannot find 'dotnet' executable in PATH. .NET not configured properly."
    fi
}

function install_gvm_and_golangs() {
    echo "[INFO] Running install_gvm_and_golangs..."
    # install go in system first
    brew_install go
    if check_user; then
        su -l ${USER_NAME} -c "
            PATH=$PATH
            USER_NAME=${USER_NAME}
            $(declare -f install_gvm)
            $(declare -f write_line)
            $(declare -f add_line)
            $(declare -f replace_line)
            install_gvm" &&
        su -l ${USER_NAME} -c "
            PATH=$PATH
            USER_NAME=${USER_NAME}
            VERSIONS_FILE=${VERSIONS_FILE}
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
    declare GO_VERSIONS=( "go1.7.6" "go1.8.7" "go1.9.7" "go1.10.8" "go1.11.13" "go1.12.14" "go1.13.5" )
    for v in "${GO_VERSIONS[@]}"; do
        gvm install "${v}" ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
    local index
    index=$(( ${#GO_VERSIONS[*]} - 1 ))
    gvm use "${GO_VERSIONS[$index]}" --default
    log_version gvm version
    log_version go version
}

function install_nvm_and_nodejs() {
    echo "[INFO] Running install_nvm_and_nodejs..."
    if check_user; then
        su -l ${USER_NAME} -c "
            PATH=$PATH
            USER_NAME=${USER_NAME}
            $(declare -f install_nvm)
            $(declare -f write_line)
            $(declare -f add_line)
            $(declare -f replace_line)
            install_nvm" &&
        su -l ${USER_NAME} -c "
            PATH=$PATH
            [ -s \"${HOME}/.nvm/nvm.sh\" ] && . \"${HOME}/.nvm/nvm.sh\"
            USER_NAME=${USER_NAME}
            VERSIONS_FILE=${VERSIONS_FILE}
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
    curl -fsSLo- https://raw.githubusercontent.com/creationix/nvm/v0.35.0/install.sh | bash
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
        CURRENT_NODEJS=12
    else
        CURRENT_NODEJS=$1
    fi
    command -v nvm ||
        { echo "Cannot find nvm. Install nvm first!" 1>&2; return 10; }
    local v
    declare NVM_VERSIONS=( "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "lts/argon" "lts/boron" "lts/carbon" "lts/dubnium" "lts/erbium" )
    for v in "${NVM_VERSIONS[@]}"; do
        nvm install "${v}" ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done

    nvm alias default "${CURRENT_NODEJS}"

    log_version nvm --version
    log_version nvm list

}

function install_xcode() {
    echo "[INFO] Running install_xcode..."
    XCODE_VERSION="11.2.1"
    #check fastlane
    if [ -n "${APPLEID_USER-}" ] && [ "${#APPLEID_USER}" -gt "0" ] &&
        [ -n "${APPLEID_PWD-}" ] && [ "${#APPLEID_PWD}" -gt "0" ] ; then
        gem install xcode-install
        export XCODE_INSTALL_USER=$APPLEID_USER
        export XCODE_INSTALL_PASSWORD=$APPLEID_PWD
        export FASTLANE_DONT_STORE_PASSWORD=1
        xcversion install "$XCODE_VERSION" --no-show-release-notes --verbose
        xcversion simulators --install='iOS 12.4'
        xcversion simulators --install='tvOS 12.4'
        xcversion simulators --install='watchOS 5.3'
        # Cleanup
        export XCODE_INSTALL_USER=
        export XCODE_INSTALL_PASSWORD=
    else
        echo "[ERROR] Variables APPLEID_USER and/or APPLEID_PWD not set."
        return 10
    fi
}

function install_mono() {
    brew_cask_install mono-mdk
    write_line "${HOME}/.profile" 'export MONO_HOME=/Library/Frameworks/Mono.framework/Home'
    write_line "${HOME}/.profile" 'export PATH=$MONO_HOME/bin:$PATH'
    export MONO_HOME=/Library/Frameworks/Mono.framework/Home
    export PATH=$MONO_HOME/bin:$PATH
    log_version mono --version
}

function install_cocoapods() {
    if check_user; then
        su -l ${USER_NAME} -c "
            gem install cocoapods
            VERSIONS_FILE=${VERSIONS_FILE}
            $(declare -f log_version)
            log_version pod --version
        " ||
            { echo "[ERROR] Cannot install cocoapods." 1>&2; return 20; }
    else
        echo "[WARNING] User '${USER_NAME-}' not found." 1>&2
    fi
}

function install_openjdk() {
    [ -x "${BREW_CMD-}" ] ||
        { echo "[ERROR] Cannot find brew. Install Homebrew first!" 1>&2; return 1; }
    if check_user; then
        su -l ${USER_NAME} -c "
            $BREW_CMD tap AdoptOpenJDK/openjdk
            $BREW_CMD cask install adoptopenjdk8 adoptopenjdk9 adoptopenjdk10 adoptopenjdk11 adoptopenjdk12 adoptopenjdk13
        " ||
            { echo "[ERROR] Cannot install adoptopenjdk with Homebrew." 1>&2; return 20; }

        JDK_PATH=$(/usr/libexec/java_home -v $i)
        write_line "${HOME}/.profile" 'export JAVA_HOME_8_X64='${JDK_PATH}
        for i in 9 10 11 12 13; do
            JDK_PATH=$(/usr/libexec/java_home -v $i)
            write_line "${HOME}/.profile" "export JAVA_HOME_${i}_X64=${JDK_PATH}"
        done
    else
        echo "[WARNING] User '${USER_NAME-}' not found." 1>&2
    fi
}

function configure_term() {
    write_line "${HOME}/.profile" 'export TERM=xterm-256color'
}

function enable_vnc() {
    defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
    launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
}

function configure_updates() {
    softwareupdate --schedule off
    defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -boolean FALSE
    defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -boolean FALSE
}

function configure_sshd() {
    systemsetup -setremotelogin on
    write_line /private/etc/ssh/sshd_config 'Protocol 2' '^Protocol '
    write_line /private/etc/ssh/sshd_config 'PasswordAuthentication no' '^PasswordAuthentication '
    write_line /private/etc/ssh/sshd_config 'ChallengeResponseAuthentication no' '^ChallengeResponseAuthentication '
    write_line /private/etc/ssh/sshd_config 'DenyUsers root' '^DenyUsers '
    write_line /private/etc/ssh/sshd_config 'PrintMotd /etc/appveyor.motd' '^PrintMotd '
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
    # clean bash_history
    [ -f ${HOME}/.bash_history ] && cat /dev/null > ${HOME}/.bash_history
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        [ -f ${USER_HOME}/.bash_history ] && cat /dev/null > ${USER_HOME}/.bash_history
        chown "$(id -u "${USER_NAME}"):$(id -g "${USER_NAME}")" -R "${USER_HOME}"
    fi

    # cleanup script guts
    # find $HOME -maxdepth 1 -name "*.sh" -delete

    #log some data about image size
    log_version df -h
    log_version ls -ltra "${HOME}"
    log_version check_folders ${HOME}/.*

}





