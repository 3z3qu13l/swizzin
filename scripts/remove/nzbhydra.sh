#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
user=$(_get_master_username)
remove_unit nzbhydra

#Old nzbhydra1 installs
rm_if_exists /opt/nzbhydra
rm_if_exists /home/${user}/.config/nzbhydra
rm_if_exists /opt/.venv/nzbhydra
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi

#nzbhydra2 installs
rm_if_exists /opt/nzbhydra2
rm_if_exists /home/${user}/.config/nzbhydra2

rm -f /etc/nginx/apps/nzbhydra.conf
rm /install/.nzbhydra.lock
nginx_reload
