#!/bin/bash
# ruTorrent removal
# Author: liara

users=($(cut -d: -f1 < /etc/htpasswd))

#shellcheck source=sources/functions/rutorrent
. /etc/swizzin/sources/functions/rutorrent
rutorrent_profiles_unmount
rm -f /install/.rutorrent.nosymfollow.failed
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
