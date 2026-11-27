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
#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
#shellcheck source=sources/functions/rtorrent
. /etc/swizzin/sources/functions/rtorrent
#shellcheck source=sources/functions/rutorrent
. /etc/swizzin/sources/functions/rutorrent
rutorrent_remove_account
rm_if_exists "/install/.rutorrent.nosymfollow.failed"
rm_if_exists "/install/.rutorrent.nginx-deny.failed"
rm -f /install/.rutorrent.nginx-php.failed /install/.rutorrent.tag /install/.rutorrent.account.foreign
# rm would empty the profiles through the mount
if rutorrent_profiles_unmount; then rm_if_exists "/srv/rutorrent"; else echo_warn "/srv/rutorrent/share/users is still mounted, /srv/rutorrent was kept"; fi
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

# Same for Deluge's web interface, back to its install defaults without nginx
if [[ -f /install/.deluge.lock ]]; then
    #shellcheck source=sources/functions/deluge
    . /etc/swizzin/sources/functions/deluge
    for u in $(_get_user_list); do
        [[ -f /home/${u}/.config/deluge/web.conf ]] || continue
        [[ $(deluge_web_interface "$u") == 127.0.0.1 ]] || continue
        active=$(systemctl is-active deluge-web@"$u")
        systemctl stop deluge-web@"$u"
        deluge_web_listen "$u" 0.0.0.0 true || echo_warn "Deluge web interface of $u still only listens on 127.0.0.1"
        if [[ $active == "active" ]]; then systemctl start deluge-web@"$u"; fi
    done
fi

# Shell in a Box back to its package settings without nginx
if [[ -f /etc/systemd/system/shellinabox.service.d/swizzin-nginx.conf ]]; then
    rm -f /etc/systemd/system/shellinabox.service.d/swizzin-nginx.conf
    systemctl daemon-reload
    if systemctl -q is-active shellinabox; then systemctl restart shellinabox; fi
fi

# transfer.sh stays on 127.0.0.1: without nginx, nothing would ask for the password on uploads
if [[ -f /install/.transfersh.lock ]]; then
    echo_warn "transfer.sh cannot be reached without nginx: install nginx again, or remove transfer.sh"
fi

# Kavita and Komga back on their own port at the root, open to the network once they have an admin
if [[ -f /install/.kavita.lock ]]; then
    #shellcheck source=sources/functions/kavita
    . /etc/swizzin/sources/functions/kavita
    ip=127.0.0.1
    [[ -f $kavita_dir/config/.swizzin-open ]] && ip=""
    systemctl stop kavita
    _kavita_set ".IpAddresses = \"$ip\" | .BaseUrl = \"/\""
    systemctl start kavita
fi
if [[ -f /install/.komga.lock ]]; then
    #shellcheck source=sources/functions/komga
    . /etc/swizzin/sources/functions/komga
    config=$(_komga_config)
    ip=127.0.0.1
    [[ -f $config/.swizzin-open ]] && ip=0.0.0.0
    systemctl stop komga
    sed -i -e "s|^  address: .*|  address: $ip|" -e 's|^    context-path: .*|    context-path: /|' "$config/application.yml"
    systemctl start komga
fi

rm /install/.nginx.lock
