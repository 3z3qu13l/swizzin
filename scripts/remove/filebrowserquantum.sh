#!/bin/bash
# FileBrowser Quantum remover

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user=$(_get_master_username)
remove_unit filebrowserquantum
rm_if_exists /opt/filebrowserquantum
rm_if_exists "/home/${user}/.config/filebrowserquantum"
if [[ -f /install/.nginx.lock ]]; then
    rm_if_exists /etc/nginx/apps/filebrowserquantum.conf
    systemctl reload nginx
fi
rm_if_exists /install/.filebrowserquantum.lock
