#!/bin/bash
#Couchpotato Removal

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user=$(cut -d: -f1 < /root/.master.info)
remove_unit couchpotato
rm -rf /opt/couchpotato
rm -rf /home/${user}/.config/couchpotato
rm -rf /opt/.venv/couchpotato
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm -f /etc/nginx/apps/couchpotato.conf
nginx_reload
rm /install/.couchpotato.lock
