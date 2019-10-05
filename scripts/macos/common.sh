#!/bin/bash -e

USER_NAME="appveyor"
OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')
PlistBuddy="/usr/libexec/PlistBuddy"

