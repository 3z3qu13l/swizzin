#!/bin/bash
# Medusa Uninstaller for Swizzin
# Author: liara

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit medusa

sudo rm /etc/nginx/apps/medusa.conf > /dev/null 2>&1
nginx_reload
rm -rf /opt/medusa
rm -rf /opt/.venv/medusa
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi

sudo rm /install/.medusa.lock
