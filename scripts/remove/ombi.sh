#!/bin/bash
#shellcheck source=sources/functions/ombi
. /etc/swizzin/sources/functions/ombi

systemctl disable -q --now ombi
if [[ -f /install/.nginx.lock ]]; then
    rm -f /etc/nginx/apps/ombi.conf
    systemctl reload nginx
fi

rm -f /etc/apt/sources.list.d/ombi.list
rm -f /etc/apt/preferences.d/ombi

# installed from its GitHub release (Debian 13 and later), not from apt
github=
ombi_from_apt || github=1

if ask "Would you like to purge the configuration?" Y; then
    [[ -z $github ]] && apt_remove ombi --purge
    if [[ -d /opt/ombi ]]; then
        rm -rf /opt/ombi
        rm -rf /etc/ombi
    fi

    if [[ -d /opt/Ombi ]]; then
        rm -rf /opt/Ombi
        rm -rf /etc/Ombi
    fi
else
    if [[ -n $github ]]; then
        rm -rf /opt/Ombi
    else
        apt_remove ombi
    fi
fi

rm -f /usr/local/lib/systemd/system/ombi.service
rm -f /etc/systemd/system/ombi.service.d/override.conf
rmdir --ignore-fail-on-non-empty /etc/systemd/system/ombi.service.d 2> /dev/null
systemctl daemon-reload

rm /install/.ombi.lock
