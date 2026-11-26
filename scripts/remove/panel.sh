#!/bin/bash

systemctl disable --now -q panel
rm -rf /srv/panel > /dev/null 2>&1
rm -rf /opt/swizzin
rm -rf /opt/.venv/swizzin
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi
rm -f /etc/nginx/apps/panel.conf
rm -f /etc/sudoers.d/panel
setfacl -x u:swizzin /etc/htpasswd > /dev/null 2>&1
rm /etc/cron.d/set_interface > /dev/null 2>&1
rm /install/.panel.lock
