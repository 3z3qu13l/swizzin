#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit tautulli
rm -rf /opt/tautulli
rm -rf /opt/.venv/tautulli
rm /install/.tautulli.lock
rm -f /etc/nginx/apps/tautulli.conf
nginx_reload
