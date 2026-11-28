#!/bin/bash
# Builds a newer curl and c-ares from source

#shellcheck source=sources/functions/curl
. /etc/swizzin/sources/functions/curl
configure_curl
build_cares
build_curl
