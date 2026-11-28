#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit lidarr

rm -rf /opt/Lidarr
rm -rf /install/.lidarr.lock

if [[ -f /install/.nginx.lock ]]; then
    rm -rf /etc/nginx/apps/lidarr.conf
    systemctl reload nginx
fi

swizdb clear "lidarr/owner"
