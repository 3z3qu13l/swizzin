#!/bin/bash
# Kavita remover

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit kavita
rm_if_exists /opt/kavita
if [[ -f /install/.nginx.lock ]]; then
    rm_if_exists /etc/nginx/apps/kavita.conf
    systemctl reload nginx
fi
rm_if_exists /install/.kavita.lock
