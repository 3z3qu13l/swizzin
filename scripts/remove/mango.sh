#! /bin/bash
# Mango deyeeter by flying_sausages 2020 for swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

rm -rf /opt/mango
remove_unit mango

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/mango.conf
    systemctl reload nginx
fi

userdel mango -f -r >> $log 2>&1

rm /install/.mango.lock
