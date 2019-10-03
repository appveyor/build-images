#!/bin/bash -e

USER_NAME="appveyor"
OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')
PlistBuddy="/usr/libexec/PlistBuddy"


# # Add Appveyor user to sudoers.d
# {
#     echo -e "${USER_NAME}\tALL=(ALL)\tNOPASSWD: ALL"
#     echo -e "Defaults:${USER_NAME}        !requiretty"
#     echo -e 'Defaults    env_keep += "DEBIAN_FRONTEND ACCEPT_EULA"'
# } > /etc/sudoers.d/${USER_NAME}



# install brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# install powershell
brew cask install powershell

#install Appveyor Agent
HOMEBREW_APPVEYOR_URL=$appVeyorUrl HOMEBREW_HOST_AUTH_TKN=$hostAuthorizationToken brew install appveyor/brew/appveyor-host-agent