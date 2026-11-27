#!/bin/bash
# ruTorrent removal
# Author: liara

users=($(cut -d: -f1 < /etc/htpasswd))

#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
#shellcheck source=sources/functions/rtorrent
. /etc/swizzin/sources/functions/rtorrent
#shellcheck source=sources/functions/rutorrent
. /etc/swizzin/sources/functions/rutorrent
rutorrent_profiles_unmount || {
    echo_error "/srv/rutorrent/share/users is still mounted, ruTorrent was not removed"
    exit 1
}
rm -f /install/.rutorrent.nosymfollow.failed /install/.rutorrent.nginx-deny.failed /install/.rutorrent.nginx-php.failed /install/.rutorrent.tag /install/.rutorrent.account.foreign /install/.rutorrent.nginx-media.failed /install/.rutorrent.share.key
rm -rf /etc/nginx/apps/rutorrent.conf
systemctl reload nginx
rutorrent_remove_account
rm -rf /srv/rutorrent

if [[ ! -f /install/.flood.lock ]]; then
    rm -rf /etc/nginx/apps/rindex.conf
    for u in "${users[@]}"; do
        rm -f /etc/nginx/apps/${u}.scgi.conf
    done
fi
rm -rf /install/.rutorrent.lock
systemctl reload nginx
