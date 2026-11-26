#!/bin/bash
# www-data (nginx, PHP) used to be in every user's group and every user in the www-data group: any SSH user
# could read what www-data reads (Nextcloud's config.php and data, Organizr), and www-data every home.
# Named ACLs now give www-data only the folders it serves and the rTorrent socket, then the groups are left.
# Nothing is removed until every ACL is in place: a home where ACLs do not work (NFS, ZFS without posixacl,
# mergerfs) stops it with a warning and leaves the old access as it was.
# shellcheck disable=SC2154 # log is exported by globals.sh

# $1 is listed as a member of group $2 in /etc/group
_in_group() {
    [[ ,$(getent group "$2" | cut -d: -f4), == *",$1,"* ]]
}

users=()
for u in $(_get_user_list); do
    if id -u "$u" > /dev/null 2>&1; then users+=("$u"); fi
done

needed=false
for u in "${users[@]}"; do
    if _in_group www-data "$u" || _in_group "$u" www-data; then needed=true; fi
done
[[ $needed == true ]] || exit 0

echo_progress_start "Replacing the www-data group memberships with ACLs"

for u in "${users[@]}"; do
    if ! _home_acl "$u" >> "$log" 2>&1 || ! getfacl -cp /home/"$u" 2> /dev/null | grep -q '^user:www-data:--x'; then
        echo_warn "ACLs do not work on /home/$u, www-data keeps its group access to every home. See $log"
        exit 0
    fi
done

failed=()
for u in "${users[@]}"; do
    for app in rtorrent:torrents/rtorrent deluge:torrents/deluge qbittorrent:torrents/qbittorrent transmission:transmission/downloads; do
        if [[ -f /install/.${app%%:*}.lock ]]; then
            _www_acl_served "$u" "${app#*:}" >> "$log" 2>&1 || failed+=("/home/$u/${app#*:}")
        fi
    done
done
if [[ -f /install/.rtorrent.lock ]]; then
    #shellcheck source=sources/functions/rtorrent
    . /etc/swizzin/sources/functions/rtorrent
    for u in "${users[@]}"; do
        rtorrent_socket_acl "$u"
        if ! getfacl -cp /run/"$u" 2> /dev/null | grep -q '^default:user:www-data:rw-'; then failed+=("/run/$u"); fi
    done
fi
if [[ -f /install/.rapidleech.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/rapidleech.sh
fi
if ((${#failed[@]})); then
    echo_warn "Could not set the ACLs on ${failed[*]}, www-data keeps its group access to every home. See $log"
    exit 0
fi

# A user's symlink in their download folder would otherwise serve, through nginx, any file www-data reads
patched=()
for f in rindex dindex qbtindex tmsindex; do
    conf=/etc/nginx/apps/${f}.conf
    if [[ -f $conf ]] && ! grep -q disable_symlinks "$conf"; then
        cp -p "$conf" /root/"${f}".conf.bak
        sed -i -E 's|^(\s*)(alias /home/\$remote_user/.*;)$|\1\2\n\1disable_symlinks if_not_owner;|' "$conf"
        patched+=("$f")
    fi
done
if ((${#patched[@]})) && ! nginx -t >> "$log" 2>&1; then
    for f in "${patched[@]}"; do mv -f /root/"${f}".conf.bak /etc/nginx/apps/"${f}".conf; done
    echo_warn "nginx refused disable_symlinks, download listings still follow symlinks. See $log"
else
    for f in "${patched[@]}"; do rm -f /root/"${f}".conf.bak; done
fi

for u in "${users[@]}"; do
    if _in_group "$u" www-data; then gpasswd -d "$u" www-data >> "$log" 2>&1; fi
    if _in_group www-data "$u"; then gpasswd -d www-data "$u" >> "$log" 2>&1; fi
done

# Running workers keep the groups they started with
for unit in $(systemctl list-units --type=service --all --no-legend --plain 'php*-fpm.service' | awk '{print $1}'); do
    systemctl try-restart "$unit" >> "$log" 2>&1
done
systemctl try-reload-or-restart nginx >> "$log" 2>&1
sleep 2

gids=()
for u in "${users[@]}"; do gids+=("$(getent group "$u" | cut -d: -f3)"); done
for pid in $(pgrep -u www-data -f 'nginx: worker process$|php-fpm: pool'); do
    for g in $(awk '/^Groups:/ {$1=""; print}' /proc/"$pid"/status 2> /dev/null); do
        if [[ " ${gids[*]} " == *" $g "* ]]; then
            echo_warn "www-data process $pid still has the group $g of a user, restart nginx and PHP-FPM"
            break 2
        fi
    done
done
echo_progress_done "www-data now only reaches the folders it serves"
echo_info "Torrent clients and other user services keep the www-data group until they restart"
