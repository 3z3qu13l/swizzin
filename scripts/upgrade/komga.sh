#!/bin/bash
# Komga upgrader

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/komga
. /etc/swizzin/sources/functions/komga

if [[ ! -f /install/.komga.lock ]]; then
    echo_error "Komga doesn't appear to be installed!"
    exit 1
fi

komga_dependencies
komga_download_latest
# an install that could not claim Komga left it closed: retried here
komga_claim
echo_success "Komga upgraded"
