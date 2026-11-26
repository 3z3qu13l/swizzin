#!/bin/bash

systemctl stop -q nginx

[[ $(_os_codename) =~ ^(focal|buster|bullseye)$ ]] && geoip="php-geoip" || geoip=""
APT="nginx-extras nginx libnginx-mod-http-fancyindex ssl-cert php php-cli php-fpm php-dev php-xml php-curl php-xmlrpc php-json php-opcache ${geoip}"
apt_remove $APT

LIST='nginx-* php7.0-* php-*'
apt_remove --purge $LIST

rm -rf /etc/nginx
rm -rf /etc/php

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
rm_if_exists "/srv/rutorrent"
rm_if_exists "/install/.rutorrent.lock"

rm_if_exists "/srv/panel"
rm_if_exists "/etc/sudoers.d/panel"
rm_if_exists "/etc/cron.d/set_interface"

# rm_if_exists "/srv/organizr"
rm_if_exists "/install/.organizr.lock"

# Without nginx, Transmission's own port is the only way in again
if [[ -f /install/.transmission.lock ]]; then
    #shellcheck source=sources/functions/transmission
    . /etc/swizzin/sources/functions/transmission
    for u in $(_get_user_list); do
        [[ -f /home/${u}/.config/transmission-daemon/settings.json ]] || continue
        transmission_rpc_is_local "$u" || continue
        active=$(systemctl is-active transmission@"$u")
        systemctl stop transmission@"$u"
        transmission_rpc_local "$u" 0.0.0.0 || echo_warn "Transmission of $u still only listens on 127.0.0.1"
        if [[ $active == "active" ]]; then systemctl start transmission@"$u"; fi
    done
fi

rm /install/.nginx.lock
