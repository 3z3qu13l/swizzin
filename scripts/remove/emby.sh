#!/bin/bash
# Removal script for emby

systemctl disable --now -q emby-server
dpkg --purge emby-server > /dev/null 2>&1
if [[ -f /etc/apt/sources.list.d/emby-server.list ]]; then
    rm /etc/apt/sources.list.d/emby-server.list
fi
# its library database and metadata, its settings and its account, as for Plex
rm -rf /var/lib/emby /opt/emby-server /etc/emby-server.conf
userdel emby > /dev/null 2>&1
groupdel emby > /dev/null 2>&1
rm -rf /etc/nginx/apps/emby.conf
if [[ -f /install/.nginx.lock ]]; then
    systemctl -q reload nginx
fi
rm -rf /install/.emby.lock
