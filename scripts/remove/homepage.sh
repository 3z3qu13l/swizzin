#!/bin/bash
# Homepage removal

user=$(_get_master_username)

systemctl disable -q --now homepage >> "$log" 2>&1
rm -f /etc/systemd/system/homepage.service
systemctl daemon-reload
rm -rf /opt/homepage "/home/${user}/.config/homepage"
rm -f /etc/nginx/sites-enabled/homepage
systemctl reload nginx

rm -f /install/.homepage.lock
