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
# an install that could not make the master its admin left Kavita closed: retried here
kavita_create_admin
echo_success "Kavita upgraded"
