#!/bin/bash

USE=$1
VERSION=$2
OPTIONS=$3

COUNT="${VERSION//[^.]}"

# cut version down if necessary
if [ ${#COUNT} == 2 ]; then
  echo "shortening version..."
  VERSION="${VERSION%.*}"
fi  

declare -A RubyVersions

# RubyVersions[2.1]=2.1.10
# RubyVersions[2.2]=2.2.10
# RubyVersions[2.3]=2.3.8
RubyVersions[2.4]=2.4.10
RubyVersions[2.5]=2.5.9
RubyVersions[2.6]=2.6.10
RubyVersions[2.7]=2.7.8
RubyVersions[3.0]=3.0.6
RubyVersions[3.1]=3.1.5
RubyVersions[3.2]=3.2.4
RubyVersions[3.3]=3.3.4

if [[ -v RubyVersions[$VERSION] ]]; then
  echo "Ruby version found: ${RubyVersions[$VERSION]}"
else
  echo "Ruby version not installed."
  exit 1
fi

pushd $APPVEYOR_BUILD_FOLDER
~/.rbenv/bin/rbenv local ${RubyVersions[$VERSION]}
echo "rbenv local ${RubyVersions[$VERSION]}"
~/.rbenv/bin/rbenv versions
popd
