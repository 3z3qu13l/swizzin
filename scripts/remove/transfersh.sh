#!/bin/bash
# transfer.sh remover

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user=$(_get_master_username)
remove_unit transfersh
rm_if_exists /opt/transfersh
rm_if_exists /etc/transfersh.env
if [[ -f /install/.nginx.lock ]]; then
    rm_if_exists /etc/nginx/apps/transfersh.conf
    systemctl reload nginx
fi
if ask "Delete the shared files in /home/${user}/transfersh?" N; then
    rm_if_exists "/home/${user}/transfersh"
fi
rm_if_exists /install/.transfersh.lock
