#!/bin/bash
# swizdash removal

# stopping an install started from the dashboard would leave that app half installed
if systemctl list-units --plain --no-legend --state=activating,active 'swizdash-job-*' | grep -q .; then
    echo_error "swizdash is installing or removing an app, try again once it is done"
    exit 1
fi
systemctl disable -q --now swizdash swizdash.socket >> "$log" 2>&1
rm -f /etc/systemd/system/swizdash.service /etc/systemd/system/swizdash.socket
systemctl daemon-reload
rm -f /etc/nginx/sites-enabled/swizdash /etc/nginx/swizdash-token.conf
systemctl reload nginx
rm -f /etc/sudoers.d/swizdash /usr/local/sbin/swizdash-helper /run/swizdash-helper.lock
rm -rf /opt/swizdash /etc/swizdash /var/lib/swizdash /var/log/swizdash
userdel swizdash > /dev/null 2>&1

rm -f /install/.swizdash.lock
