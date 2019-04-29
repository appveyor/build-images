#!/bin/bash
#shellcheck disable=SC2086,SC2015,SC2164

function add_releasespecific_tools() {
    # 32bit support
    tools_array+=( "libcurl3:i386" "libcurl3-gnutls-dev" )
    # HWE kernel
    tools_array+=( "linux-generic-hwe-16.04" )
}
