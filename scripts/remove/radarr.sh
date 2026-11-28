#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit radarr
rm -rf /opt/Radarr

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/radarr.conf
    systemctl reload nginx
fi

rm /install/.radarr.lock
