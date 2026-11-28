#!/bin/bash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

echo_log_only "Removing Transmission"
users=($(cut -d: -f1 < /etc/htpasswd))
for u in ${users[@]}; do
    echo_log_only "Shutting down transmission@$u"
    systemctl stop transmission@"$u" >> "$log" 2>&1
    systemctl disable transmission@"$u" >> "$log" 2>&1
    rm -f /home/${u}/.config/transmission-daemon/settings.json
done

add-apt-repository --remove ppa:transmissionbt/ppa -y >> $log 2>&1
apt_remove --purge transmission-common transmission-cli transmission-daemon
echo_log_only "Removing service file and nginx configs"
rm /etc/systemd/system/transmission@.service
rm /etc/nginx/apps/transmission.conf >> "$log" 2>&1
rm /etc/nginx/conf.d/*.transmission.conf >> "$log" 2>&1
if [[ -f /etc/apparmor.d/local/transmission-daemon ]]; then
    rm -f /etc/apparmor.d/local/transmission-daemon
    if grep -q '^transmission-daemon ' /sys/kernel/security/apparmor/profiles 2> /dev/null; then
        apparmor_parser -r /etc/apparmor.d/transmission >> "$log" 2>&1
    fi
fi
nginx_reload
systemctl daemon-reload

rm /install/.transmission.lock
