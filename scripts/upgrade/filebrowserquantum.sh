#!/bin/bash
# FileBrowser Quantum upgrader

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/filebrowserquantum
. /etc/swizzin/sources/functions/filebrowserquantum

if [[ ! -f /install/.filebrowserquantum.lock ]]; then
    echo_error "FileBrowser Quantum doesn't appear to be installed!"
    exit 1
fi

fbq_download_latest
echo_success "FileBrowser Quantum upgraded"
