#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

remove_unit lounge

# remove old npm installs
npm uninstall -g thelounge --save >> /dev/null 2>&1

# remove modernized yarn installs
yarn --non-interactive global remove thelounge >> /dev/null 2>&1
yarn --non-interactive cache clean >> /dev/null 2>&1

deluser lounge --remove-home >> /dev/null 2>&1
rm -rf /home/lounge # just in case
rm -rf /opt/lounge  # new location who dis

rm -f /etc/nginx/apps/lounge.conf
nginx_reload

rm -f /install/.lounge.lock
