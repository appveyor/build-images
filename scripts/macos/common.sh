#!/bin/bash -e
#shellcheck disable=SC2086,SC2015,SC2164

if [[ -z "${USER_NAME-}" || "${#USER_NAME}" = "0" ]]; then USER_NAME=appveyor; fi
if [[ -z "${USER_HOME-}" || "${#USER_HOME}" = "0" ]]; then USER_HOME=/Users/appveyor; fi
if [[ -z "${VERSIONS_FILE-}" || "${#VERSIONS_FILE}" = "0" ]]; then VERSIONS_FILE=$HOME/versions.log; fi
HOST_NAME=appveyor-vm
OSX_MAJOR_VER=$(sw_vers -productVersion | awk -F "." '{print $1}')
OSX_MINOR_VER=$(sw_vers -productVersion | awk -F "." '{print $2}')
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

function brew_link() {
    run_brew link "$@"
}

function brew_install() {
    run_brew install "$@"
}

function brew_cask_install() {
    run_brew install --cask "$@"
}

function run_brew() {
    [ -x "${BREW_CMD-}" ] ||
        { echo "[ERROR] Cannot find brew. Install Homebrew first!" 1>&2; return 1; }
    if check_user; then
        su -l ${USER_NAME} -c "$BREW_CMD $*" ||
            { echo "[ERROR] Cannot install '$*' with Homebrew." 1>&2; return 20; }
    else
        echo "[WARNING] User '${USER_NAME-}' not found." 1>&2
    fi
}

function install_curl() {
    echo "[INFO] Running install_curl..."

    brew_install curl
    if check_user; then
        # shellcheck disable=SC2016
        export PATH="/usr/local/opt/curl/bin:$PATH"
        write_line "${HOME}/.profile" 'export PATH="/usr/local/opt/curl/bin:$PATH"'
    fi
}

function install_vcs() {
    echo "[INFO] Running install_vcs..."

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

function install_rvm() {
    echo "[INFO] Running install_rvm..."
    brew install openssl@1.1
    #brew install openssl@3
    which curl
    curl --version
    echo "gem: --no-document" >> $HOME/.gemrc
    command -v gpg ||
        { echo "Cannot find gpg. Install GPG first!" 1>&2; return 10; }
    #gpg --version
    #gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    curl -sSL https://rvm.io/mpapis.asc | gpg --import -
    curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
    curl -fsSL https://get.rvm.io | bash -s stable
    # shellcheck disable=SC1090
    source "${HOME}/.rvm/scripts/rvm"
}

function install_rbenv() {
    echo "[INFO] Running install_rbenv..."
    sudo -u appveyor brew install rbenv ruby-build
    touch ~/.zshrc
    echo "eval '$(rbenv init - zsh)'" >> ~/.zshrc
}

function install_rubies() {
    echo "[INFO] Running install_rubies..."
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    local DEFAULT_RUBY
    DEFAULT_RUBY="ruby-3.3.0"
    command -v rvm ||
        { echo "Cannot find rvm. Install rvm first!" 1>&2; return 10; }
    local v
    declare RUBY_VERSIONS=( "ruby-2.7.8" "ruby-3.0.6" "ruby-3.1.4" "ruby-3.2.3" "ruby-3.3.0" )

    # sequoia
    if [ "$OSX_MAJOR_VER" -ge 15 ]; then
        RUBY_VERSIONS=( "ruby-2.7.8" "ruby-3.3.0" )
    fi

    for v in "${RUBY_VERSIONS[@]}"; do
        rvm install "${v}" --with-openssl-dir=/usr/local/opt/openssl@1.1 ||
            { echo "[ERROR] Cannot install Ruby ${v} with RVM." 1>&2; return 10; }
    done
    local index

    rvm use "$DEFAULT_RUBY" --default

    log_version rvm --version
    log_version ruby --version
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

function install_rubies_rbenv() {
    echo "[INFO] Running install_rubies with rbenv..."
    ruby -v
    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi
    local DEFAULT_RUBY
    DEFAULT_RUBY="2.7.8"
    command -v rbenv ||
        { echo "Cannot find rbenv. Install rbenv first!" 1>&2; return 10; }
    local v
    #declare RUBY_VERSIONS=( "ruby-2.0" "ruby-2.1" "ruby-2.2" "ruby-2.3" "ruby-2.4" "ruby-2.5" "ruby-2.6" "ruby-2.7" "ruby-3" "ruby-3.1.3" "ruby-head" )
    declare RUBY_VERSIONS=( "2.6.10" "2.7.8" "3.0.6" "3.1.4" "3.2.2" )
    for v in "${RUBY_VERSIONS[@]}"; do
        rbenv install "${v}" ||
            { echo "[WARNING] Cannot install ${v}." 1>&2; }
    done
    local index

    rbenv global "$DEFAULT_RUBY"
    ruby --version
    # add shims to path so system ruby is controlled by rbenv
    export PATH=~/.rbenv/shims:$PATH
    ruby --version
    rbenv version

    log_version rbenv --version
    log_version rbenv install -l
}

function install_rbenv_and_rubies() {
    echo "[INFO] Running install_rbenv_and_rubies..."
    
    if check_user; then
        su -l ${USER_NAME} -c "
            PATH=$PATH
            USER_NAME=${USER_NAME}
            $(declare -f install_rbenv)
            install_rbenv" &&
        su -l ${USER_NAME} -c "
            PATH=$PATH
            USER_NAME=${USER_NAME}
            VERSIONS_FILE=${VERSIONS_FILE}
            $(declare -f log_version)
            $(declare -f install_rubies)
            install_rubies" ||
                return $?
    else
        echo "[WARNING] User '${USER_NAME-}' not found. Cannot install rbenv and rubies"
    fi
}

function install_gcc() {
    declare GCC_VERSIONS=( "gcc@10" "gcc@11" "gcc@12" )
    brew_install "${GCC_VERSIONS[@]}"
}

function install_cmake() {
    echo "[INFO] Running install_cmake..."
    local VERSION
    if [[ -z "${1-}" || "${#1}" = "0" ]]; then
        VERSION=3.28.1
    else
        VERSION=$1
    fi
    local TAR_FILE="cmake-${VERSION}-macos-universal.tar.gz"
    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl -fsSL -O "https://github.com/Kitware/CMake/releases/download/v${VERSION}/${TAR_FILE}" &&
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

function install_qt() {
    echo "[INFO] Installing Qt..."
    if [ -f "./windows-scripts/install_qt_fast_macos.ps1" ] && command -v pwsh; then
        pwsh -nol -noni ./windows-scripts/install_qt_fast_macos.ps1
    else
        echo '[ERROR] Cannot run install_qt_fast_macos.ps1: Either PowerShell is not installed or install_qt_fast_macos.ps1 does not exist.' 1>&2;
        return 10;
    fi
}

function install_pythons(){
    echo "[INFO] Running install_pythons..."

    brew install pyenv

    write_line "${HOME}/.profile" 'export PYENV_ROOT="$HOME/.pyenv"'
    write_line "${HOME}/.profile" 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
    eval "$(pyenv init -)"

    declare PY_VERSIONS=( "2.7.18" "3.8.20" "3.9.22" "3.10.17" "3.11.12" "3.12.10" "3.13.3" )
    for i in "${PY_VERSIONS[@]}"; do
        VENV_PATH=${HOME}/venv${i%%[abrcf]*}
        VENV_MINOR_PATH=${HOME}/venv${i%.*}

        pyenv install "${i}" ||
            { echo "[ERROR] Cannot install Python ${i}."; return 10; }

        pyenv global "${i}"
        python --version

        python -m pip install --upgrade pip ||
            { echo "[ERROR] Cannot upgrade pip for Python ${i}."; return 10; }
        
        if [ ${i:0:1} -eq 3 ]; then
            python -m venv "${VENV_PATH}" ||
                { echo "[ERROR] Cannot make virtualenv for Python ${i}."; return 10; }
        else
            python -m pip install virtualenv ||
                { echo "[ERROR] Cannot install virtualenv for Python ${i}."; return 10; }

            python -m virtualenv "${VENV_PATH}" ||
                { echo "[ERROR] Cannot make virtualenv for Python ${i}."; return 10; }
        fi

        echo "Linking ${VENV_MINOR_PATH} to ${VENV_PATH}"
        ln -s ${VENV_PATH} ${VENV_MINOR_PATH}
    done

    ls -al ~/venv*
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

    local INSTALL_DIR="/usr/local/share/dotnet"

    # this must be executed as appveyor user
    if [ "$(whoami)" != "${USER_NAME}" ]; then
        echo "This script must be run as '${USER_NAME}'. Current user is '$(whoami)'" 1>&2
        return 1
    fi

    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"

    local SCRIPT_URL
    SCRIPT_URL="https://dot.net/v1/dotnet-install.sh"
    curl -fsSL "$SCRIPT_URL" -O ||
        { echo "[ERROR] Cannot download install script '$SCRIPT_URL'." 1>&2; return 10; }
    chmod a+x ./dotnet-install.sh
    declare DOTNET_VERSIONS=( "3.1" "6.0" "7.0" "8.0" "9.0" )
    for v in "${DOTNET_VERSIONS[@]}"; do
        echo "[INFO] Installing .NET Core ${v}..."
        sudo ./dotnet-install.sh -channel "$v" --install-dir "$INSTALL_DIR"
    done

    popd

    #shellcheck disable=SC2016
    write_line "${HOME}/.profile" "add2path_suffix $INSTALL_DIR"
    export PATH="$PATH:$INSTALL_DIR"
}

function install_gvm_and_golangs() {
    echo "[INFO] Running install_gvm_and_golangs..."
    # install go in system first
    brew install go
    install_gvm

    source "${HOME}/.gvm/scripts/gvm"

    install_golangs
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
    declare GO_VERSIONS=( "go1.19.13" "go1.20.13" "go1.21.6" )
    for v in "${GO_VERSIONS[@]}"; do
        # big sur
        if [ "$OSX_MAJOR_VER" -eq 10 ]; then
            # Catalina/Mojave - install from binaries
            gvm install "${v}" -B ||
                { echo "[WARNING] Cannot install ${v} from binary." 1>&2; }
        else
            # BigSur - install from source
            gvm install "${v}" ||
                { echo "[WARNING] Cannot install ${v}." 1>&2; }     
        fi

    done
    local index
    index=$(( ${#GO_VERSIONS[*]} - 1 ))
    gvm use "${GO_VERSIONS[$index]}" --default
    log_version gvm version
    log_version go version
}

function install_nvm_and_nodejs() {
    echo "[INFO] Running install_nvm_and_nodejs..."
    install_nvm

    [ -s "${HOME}/.nvm/nvm.sh" ] && . "${HOME}/.nvm/nvm.sh"

    install_nvm_nodejs "${CURRENT_NODEJS}"
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
        CURRENT_NODEJS=18
    else
        CURRENT_NODEJS=$1
    fi
    command -v nvm ||
        { echo "Cannot find nvm. Install nvm first!" 1>&2; return 10; }
    local v
    declare NVM_VERSIONS=( "8" "10" "14" "18" "19" "20" "21" )
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
    XCODE_VERSION="11.3.1"

    # all versions
    declare XCODE_VERSIONS=( "9.4.1" "10.3" "11.3.1" )

    # catalina
    if [ "$OSX_MAJOR_VER" -eq 10 ] && [ "$OSX_MINOR_VER" -gt 14 ]; then
        XCODE_VERSIONS+=( "11.7" "12.4" )
    fi

    # big sur
    if [ "$OSX_MAJOR_VER" -eq 11 ]; then
        XCODE_VERSIONS=( "12.5.1" "13.2.1" )
    fi

    # monterey
    if [ "$OSX_MAJOR_VER" -eq 12 ]; then
        XCODE_VERSIONS=( "13.4.1" "14.2" )
    fi
    
    # ventura and sonoma
    if [ "$OSX_MAJOR_VER" -ge 13 ]; then
        XCODE_VERSIONS=( "14.3.1" "15.4" )
    fi

    # sequoia
    if [ "$OSX_MAJOR_VER" -ge 15 ]; then
        XCODE_VERSIONS=( "15.4" "16.3" )
    fi

    # xcode-install
    if [ -n "${XCODES_USERNAME-}" ] && [ "${#XCODES_USERNAME}" -gt "0" ] &&
        [ -n "${XCODES_PASSWORD-}" ] && [ "${#XCODES_PASSWORD}" -gt "0" ] ; then

        if [ "$OSX_MAJOR_VER" -ge 12 ]; then
            brew_install xcodesorg/made/xcodes
        else
            gem install xcode-install
        fi

        for XCODE_VERSION in "${XCODE_VERSIONS[@]}"; do
            if [ "$OSX_MAJOR_VER" -ge 12 ]; then
                xcodes install --use-fastlane-auth "$XCODE_VERSION"
            else
                xcversion install "$XCODE_VERSION" --no-show-release-notes --verbose
            fi
        done

        if [ "$OSX_MAJOR_VER" -ge 12 ]; then
            local last_index=$(( ${#XCODE_VERSIONS[*]} - 1 ))
            xcodes select "${XCODE_VERSIONS[$last_index]}"
        fi

        if [ "$OSX_MAJOR_VER" -ge 15 ]; then
            xcodes runtimes install 'iOS 18.2'
            xcodes runtimes install 'watchOS 11.2'
            xcodes runtimes install 'tvOS 18.2'
        elif [ "$OSX_MAJOR_VER" -ge 13 ]; then
            xcodes runtimes install 'iOS 17.2'
            xcodes runtimes install 'watchOS 10.2'
            xcodes runtimes install 'tvOS 17.2'
        elif [ "$OSX_MAJOR_VER" -eq 12 ]; then
            xcodes runtimes install 'iOS 16.1'
            xcodes runtimes install 'watchOS 9.1'
            xcodes runtimes install 'tvOS 16.1'
        elif [ "$OSX_MAJOR_VER" -eq 11 ]; then
            xcversion simulators --install='iOS 15.2'
            xcversion simulators --install='tvOS 15.2'
            xcversion simulators --install='watchOS 8.3'
        fi

    else
        echo "[ERROR] Variables XCODES_USERNAME and/or XCODES_PASSWORD not set."
        return 10
    fi
}

function install_vcpkg() {
    echo "[INFO] Running install_vcpkg..."

    echo "Home: $HOME"

    echo "macOS version: $OSX_MINOR_VER"
    if [ "$OSX_MAJOR_VER" -eq 10 ] && [ "$OSX_MINOR_VER" -le 14 ]; then
        echo "Installing GCC"
        brew install gcc
    fi

    pushd "${HOME}"
    command -v git ||
        { echo "[ERROR] Cannot find git. Please install git first." 1>&2; return 10; }
    local TOOL
    for TOOL in curl unzip tar; do
        command -v "${TOOL}" ||
            { echo "[ERROR] Cannot find '${TOOL}'. Please install '${TOOL}' first." 1>&2; return 10; }
    done

    git clone --depth 1 https://github.com/Microsoft/vcpkg.git &&
    pushd vcpkg
    ./bootstrap-vcpkg.sh ||
        { echo "[ERROR] Cannot bootstrap vcpkg." 1>&2; popd; return 10; }

    write_line "${HOME}/.profile" 'add2path_suffix ${HOME}/vcpkg'
    export PATH="$PATH:${HOME}/vcpkg"
    vcpkg integrate install ||
        { echo "[WARNING] 'vcpkg integrate install' Failed." 1>&2; }

    popd
    popd
    log_version vcpkg version
}

function install_flutter() {
    echo "[INFO] Running install_flutter..."

    local FLUTTER_MACOS_ZIP="flutter_macos_3.16.8-stable.zip"
    local FLUTTER_MACOS_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/$FLUTTER_MACOS_ZIP"
    local TMP_DIR=$(mktemp -d)
    pushd -- "${TMP_DIR}"
    curl $FLUTTER_MACOS_URL -o $FLUTTER_MACOS_ZIP &&
    unzip -qq "$FLUTTER_MACOS_ZIP" -d $HOME ||
        { echo "[ERROR] Cannot download and unzip Flutter." 1>&2; popd; return 10; }

    export PATH="$PATH:$HOME/flutter/bin"
    write_line "${HOME}/.profile" 'add2path_suffix ${HOME}/flutter/bin'

    flutter channel stable
    flutter upgrade
    flutter config --enable-macos-desktop
    log_version flutter doctor

    popd &&
    rm -rf "${TMP_DIR}"
}

function install_cocoapods() {
    echo "[INFO] Running install_cocoapods..."
    if check_user; then
        su -l ${USER_NAME} -c "
            sudo gem install cocoapods
            VERSIONS_FILE=${VERSIONS_FILE}
            $(declare -f log_version)
            log_version pod --version
        " ||
            { echo "[ERROR] Cannot install cocoapods." 1>&2; return 20; }
    else
        echo "[WARNING] User '${USER_NAME-}' not found." 1>&2
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

function install_openjdk() {
    echo "[INFO] Running install_openjdk..."
    [ -x "${BREW_CMD-}" ] ||
        { echo "[ERROR] Cannot find brew. Install Homebrew first!" 1>&2; return 1; }
    if check_user; then

        # all versions
        declare JDK_VERSIONS=( "11" "19" "20" "21" )

        # # big sur, monterey
        # if [ "$OSX_MAJOR_VER" -ge 11 ]; then
        #     JDK_VERSIONS=( "15" "16" "17" "18" "19" )
        # fi  

        # install JDKs
        for JDK_VERSION in "${JDK_VERSIONS[@]}"; do
            su -l ${USER_NAME} -c "
                $BREW_CMD install --cask temurin@${JDK_VERSION}
            " || { echo "[ERROR] Cannot install adoptopenjdk ${JDK_VERSION} with Homebrew." 1>&2; return 20; }
        done

        JDK_PATH=$(/usr/libexec/java_home -v $i)
        write_line "${HOME}/.profile" 'export JAVA_HOME_8_X64='${JDK_PATH}
        for JDK_VERSION in "${JDK_VERSIONS[@]:1}"; do
            JDK_PATH=$(/usr/libexec/java_home -v ${JDK_VERSION})
            write_line "${HOME}/.profile" "export JAVA_HOME_${JDK_VERSION}_X64=${JDK_PATH}"
        done

        # # add JDK paths to the profile
        # for JDK_VERSION in "${JDK_VERSIONS[@]}"; do
        #     JDK_PATH=$(/usr/libexec/java_home -v $JDK_VERSION)
        #     write_line "${HOME}/.profile" "export JAVA_HOME_${JDK_VERSION}_X64=${JDK_PATH}"
        # done
    else
        echo "[WARNING] User '${USER_NAME-}' not found." 1>&2
    fi
}

function configure_autologin() {
    echo "[INFO] Running configure_autologin..."
    if [[ -z "${INSTALL_PASSWORD-}" || "${#INSTALL_PASSWORD}" = "0" ]]; then
        echo "[ERROR] Password is not set, cannot configure autologin." 1>&2
        return 10
    fi
    # brew_install xfreebird/utils/kcpassword &&
    # enable_autologin "$USER_NAME" "$INSTALL_PASSWORD" ||
    #     { echo "[ERROR] Cannot install kcpassword with Homebrew." 1>&2; return 20; }

    local PFILE=/usr/local/var/appveyor/build-agent/psw
    local PDIR=${PFILE%/*}

    mkdir -p "$PDIR" &&
    echo -n "$INSTALL_PASSWORD" >"$PFILE" &&
    chown -R "$(id -u "${USER_NAME}"):$(id -g "${USER_NAME}")" "$PDIR" ||
        { echo "[ERROR] Cannot save password in '$PFILE'." 1>&2; return 20; }

    log_version ls -la "$PDIR"
}

function configure_term() {
    echo "[INFO] Running configure_term..."
    write_line "${HOME}/.profile" 'export ASPNETCORE_ENVIRONMENT=Production'
    write_line "${HOME}/.profile" 'export TERM=xterm-256color'
    write_line "${HOME}/.profile" 'export BUILDKIT_PROGRESS=plain'
}

function enable_vnc() {
    echo "[INFO] Running enable_vnc..."
    defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
    launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
    log_version defaults read /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing
}

function configure_updates() {
    echo "[INFO] Running configure_updates..."
    softwareupdate --schedule off
    defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -boolean FALSE
    defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -boolean FALSE
    log_version defaults read /Library/Preferences/com.apple.SoftwareUpdate
}

function configure_sshd() {
    echo "[INFO] Running configure_sshd..."
    systemsetup -setremotelogin on
    write_line /private/etc/ssh/sshd_config 'Protocol 2' '^Protocol '
    write_line /private/etc/ssh/sshd_config 'PasswordAuthentication no' '^PasswordAuthentication '
    write_line /private/etc/ssh/sshd_config 'ChallengeResponseAuthentication no' '^ChallengeResponseAuthentication '
    write_line /private/etc/ssh/sshd_config 'DenyUsers root' '^DenyUsers '
    write_line /private/etc/ssh/sshd_config 'PrintMotd yes' '^PrintMotd '
}

function add_ssh_known_hosts() {
    echo "[INFO] Configuring ~/.ssh/known_hosts..."
    if [ -f "./windows-scripts/add_ssh_known_hosts.ps1" ] && command -v pwsh; then
        pwsh -nol -noni ./windows-scripts/add_ssh_known_hosts.ps1
        echo $HOME
        chmod 700 $HOME/.ssh
    else
        echo '[ERROR] Cannot run add_ssh_known_hosts.ps1: Either Powershell is not installed or add_ssh_known_hosts.ps1 does not exist.' 1>&2;
        return 10;
    fi
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

function fix_home_permissions() {
    echo "[INFO] Running fix_home_permissions..."
    sudo chown -R ${USER_NAME} $HOME
}

function cleanup() {
    echo "[INFO] Running cleanup..."

    # fix $HOME permissions
    fix_home_permissions

    # clean bash_history
    [ -f ${HOME}/.bash_history ] && cat /dev/null > ${HOME}/.bash_history
    if [ -n "${USER_NAME-}" ] && [ "${#USER_NAME}" -gt "0" ] && getent group ${USER_NAME}  >/dev/null; then
        [ -f ${USER_HOME}/.bash_history ] && cat /dev/null > ${USER_HOME}/.bash_history
        chown "$(id -u "${USER_NAME}"):$(id -g "${USER_NAME}")" -R "${USER_HOME}"
    fi

    # cleanup script guts
    find $HOME -maxdepth 1 -name "*.sh" -delete

    # delete windows PS scripts
    rm -rf "$HOME/windows-scripts"

    #log some data about image size
    log_version df -h
    log_version ls -ltra "${HOME}"
    log_version check_folders ${HOME}/.*
    log_version ls -al /Applications
}
