#!/bin/bash
# Kavita remover

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

systemctl disable -q --now kavita >> "$log" 2>&1
rm_if_exists /etc/systemd/system/kavita.service
systemctl daemon-reload
rm_if_exists /opt/kavita
if [[ -f /install/.nginx.lock ]]; then
    rm_if_exists /etc/nginx/apps/kavita.conf
    systemctl reload nginx
fi
rm_if_exists /install/.kavita.lock
