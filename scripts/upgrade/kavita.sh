#!/bin/bash
# Kavita upgrader

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/kavita
. /etc/swizzin/sources/functions/kavita

if [[ ! -f /install/.kavita.lock ]]; then
    echo_error "Kavita doesn't appear to be installed!"
    exit 1
fi

kavita_download_latest
echo_success "Kavita upgraded"
