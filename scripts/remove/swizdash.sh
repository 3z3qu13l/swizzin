#!/bin/bash
# swizdash removal

# an install or removal started from the dashboard would keep running
systemctl stop 'swizdash-job-*' > /dev/null 2>&1
systemctl disable -q --now swizdash swizdash.socket >> "$log" 2>&1
rm -f /etc/systemd/system/swizdash.service /etc/systemd/system/swizdash.socket
systemctl daemon-reload
rm -f /etc/nginx/sites-enabled/swizdash /etc/nginx/swizdash-token.conf
systemctl reload nginx
rm -f /etc/sudoers.d/swizdash /usr/local/sbin/swizdash-helper /run/swizdash-helper.lock
rm -rf /opt/swizdash /etc/swizdash /var/lib/swizdash /var/log/swizdash
userdel swizdash > /dev/null 2>&1

rm -f /install/.swizdash.lock
