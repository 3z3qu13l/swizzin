#!/bin/bash
#
# Uninstaller for SickGear
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit sickgear
sudo rm /etc/nginx/apps/sickgear.conf > /dev/null 2>&1
sudo rm /install/.sickgear.lock
nginx_reload
rm -rf /opt/sickgear
rm -rf /opt/.venv/sickgear
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm -f /install/.sickgear.lock
