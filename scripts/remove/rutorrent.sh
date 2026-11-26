#!/bin/bash
# ruTorrent removal
# Author: liara

users=($(cut -d: -f1 < /etc/htpasswd))

#shellcheck source=sources/functions/rutorrent
. /etc/swizzin/sources/functions/rutorrent
rutorrent_profiles_unmount || {
    echo_error "/srv/rutorrent/share/users is still mounted, ruTorrent was not removed"
    exit 1
}
rm -f /install/.rutorrent.nosymfollow.failed /install/.rutorrent.nginx-deny.failed
rm -rf /srv/rutorrent
rm -rf /etc/nginx/apps/rutorrent.conf

if [[ ! -f /install/.flood.lock ]]; then
    rm -rf /etc/nginx/apps/rindex.conf
    for u in "${users[@]}"; do
        rm -f /etc/nginx/apps/${u}.scgi.conf
    done
fi
rm -rf /install/.rutorrent.lock
systemctl reload nginx
