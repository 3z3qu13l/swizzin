#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit bazarr

rm -rf /opt/bazarr
rm -rf /opt/.venv/bazarr
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi

rm -rf /etc/nginx/apps/bazarr.conf
nginx_reload

rm -rf /install/.bazarr.lock
