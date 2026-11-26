#!/bin/bash
systemctl disable -q --now ombi
if [[ -f /install/.nginx.lock ]]; then
    rm -f /etc/nginx/apps/ombi.conf
    systemctl reload nginx
fi

rm /etc/apt/sources.list.d/ombi.list
rm -f /etc/apt/preferences.d/ombi

if ask "Would you like to purge the configuration?" Y; then
    apt_remove ombi --purge
    if [[ -d /opt/ombi ]]; then
        rm -rf /opt/ombi
        rm -rf /etc/ombi
    fi

    if [[ -d /opt/Ombi ]]; then
        rm -rf /opt/Ombi
        rm -rf /etc/Ombi
    fi
else
    apt_remove ombi
fi

rm -f /etc/systemd/system/ombi.service.d/override.conf
rmdir --ignore-fail-on-non-empty /etc/systemd/system/ombi.service.d 2> /dev/null
systemctl daemon-reload

rm /install/.ombi.lock
