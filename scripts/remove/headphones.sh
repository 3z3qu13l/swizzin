#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user=$(cut -d: -f1 < /root/.master.info)

remove_unit headphones

rm -f /etc/nginx/apps/headphones.conf
rm -rf /opt/headphones
rm -rf /opt/.venv/headphones
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm /install/.headphones.lock
nginx_reload
