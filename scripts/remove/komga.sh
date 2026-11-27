#!/bin/bash
# Komga remover. Java 25 stays: other apps may use it.

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user=$(_get_master_username)
systemctl disable -q --now komga >> "$log" 2>&1
rm_if_exists /etc/systemd/system/komga.service
systemctl daemon-reload
rm_if_exists /opt/komga
rm_if_exists "/home/${user}/.config/komga"
if [[ -f /install/.nginx.lock ]]; then
    rm_if_exists /etc/nginx/apps/komga.conf
    systemctl reload nginx
fi
rm_if_exists /install/.komga.lock
