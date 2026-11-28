#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user=$(cut -d: -f1 < /root/.master.info)

remove_unit sabnzbd
rm -rf /opt/sabnzbd
rm -rf /home/$user/.config/sabnzbd
rm -rf /opt/.venv/sabnzbd
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm -f /etc/nginx/apps/sabnzbd.conf
nginx_reload
rm /install/.sabnzbd.lock
