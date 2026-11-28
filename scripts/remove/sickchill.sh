#!/bin/bash
#
# Uninstaller for sickchill
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit sickchill
rm -rf /opt/sickchill
rm -rf /opt/.venv/sickchill
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm /etc/nginx/apps/sickchill.conf > /dev/null 2>&1
nginx_reload
rm -f /install/.sickchill.lock
