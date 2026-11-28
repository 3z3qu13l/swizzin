#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

username=$(cut -d: -f1 < /root/.master.info)

rm -r /home/$username/Jackett
rm /install/.jackett.lock
rm -r /home/${username}/.config/Jackett

systemctl stop -q jackett@${username}
systemctl disable -q jackett@${username}
rm /etc/systemd/system/jackett@.service
systemctl daemon-reload
rm -f /etc/nginx/apps/jackett.conf
nginx_reload
if [[ -f /etc/init.d/jackett ]]; then
    rm /etc/init.d/jackett
    update-rc.d -f jackett remove
    systemctl stop -q jackett
fi
