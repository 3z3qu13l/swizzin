#!/bin/bash
# transfer.sh upgrader

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/transfersh
. /etc/swizzin/sources/functions/transfersh

if [[ ! -f /install/.transfersh.lock ]]; then
    echo_error "transfer.sh doesn't appear to be installed!"
    exit 1
fi

transfersh_download_latest
echo_success "transfer.sh upgraded"
