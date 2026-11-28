#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit pyload

rm -rf /opt/pyload
rm -rf /opt/.venv/pyload
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm -rf /etc/nginx/apps/pyload.conf
apt_remove tesseract-ocr gocr rhino
nginx_reload
rm /install/.pyload.lock
