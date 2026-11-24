#!/bin/bash
# Homepage removal

#shellcheck source=sources/functions/homepage
. /etc/swizzin/sources/functions/homepage

user=$(_get_master_username)

systemctl disable -q --now homepage >> "$log" 2>&1
rm -f /etc/systemd/system/homepage.service
rm -rf /opt/homepage "/home/${user}/.config/homepage"
rm -f /etc/nginx/sites-enabled/homepage
systemctl reload nginx

# Glances goes back to its own setup, and is only removed if swizzin installed it
glances_owned=false
grep -q '^# installed by swizzin' "$homepage_glances_conf" 2> /dev/null && glances_owned=true
rm -f "$homepage_glances_conf"
rmdir --ignore-fail-on-non-empty "${homepage_glances_conf%/*}" 2> /dev/null
systemctl daemon-reload
if [[ $glances_owned == true ]]; then
    apt_remove --purge glances
else
    systemctl try-restart glances
fi

rm -f /install/.homepage.lock
