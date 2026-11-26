#!/bin/bash
# www-data (nginx, PHP) used to be in every user's group and every user in the www-data group: any SSH user
# could read what www-data reads (Nextcloud's config.php and data, Organizr), and www-data every home.
# Named ACLs now give www-data only the folders it serves and the rTorrent socket, then the groups are left.
# Nothing is removed until every ACL is in place and www-data, without groups, really reads each folder.
# A failure is kept in $failed, so the long walk of the download folders is not redone at every update.
# shellcheck disable=SC2154 # log is exported by globals.sh

done_marker=/install/.www-data-acl.done
failed=/install/.www-data-acl.failed

# $1 is listed as a member of group $2 in /etc/group
_in_group() {
    [[ ,$(getent group "$2" | cut -d: -f4), == *",$1,"* ]]
}

# The folder a download listing conf serves, e.g. /home/$remote_user/torrents/rtorrent
_served_root() {
    [[ -f $1 ]] && sed -nE 's|^\s*alias (/home/\$remote_user/[^;]*[^/;])/?;\s*$|\1|p' "$1" | head -1
}

# nginx worker and PHP-FPM pool processes still holding a group other than www-data
_stale_workers() {
    local pid g
    for pid in $(pgrep -u www-data -f 'nginx: worker process$|php-fpm: pool'); do
        for g in $(awk '/^Groups:/ {$1=""; print}' /proc/"$pid"/status 2> /dev/null); do
            if [[ $g != 33 ]]; then
                echo "$pid"
                break
            fi
        done
    done
}

_stop() {
    printf '%s\n' "$@" > "$failed"
    echo_warn "www-data keeps its group access to every home: $1
Once fixed, run: rm $failed && box update"
    exit 0
}

# A user's symlink in their download folder would otherwise serve, through nginx, any file www-data reads.
# Only links below the served folder are checked: one an admin made higher up (~/torrents -> a disk) works.
# Kept out of the migration below: update/nginx.sh may rewrite these confs after it ran
confs=()
for f in rindex dindex qbtindex tmsindex; do
    conf=/etc/nginx/apps/${f}.conf
    root=$(_served_root "$conf") || continue
    [[ -n $root ]] || continue
    line="disable_symlinks if_not_owner from=${root};"
    grep -qF "$line" "$conf" && continue
    re=${root//\$/\\\$}
    cp -p "$conf" /root/"${f}".conf.bak
    sed -i -E -e '/^\s*disable_symlinks /d' -e "s|^(\s*)alias ${re}/?;\s*$|&\n\1${line}|" "$conf"
    if grep -qF "$line" "$conf"; then
        confs+=("$f")
    else
        mv -f /root/"${f}".conf.bak "$conf"
        echo_warn "Could not add disable_symlinks to $conf"
    fi
done
if ((${#confs[@]})); then
    if nginx -t >> "$log" 2>&1; then
        for f in "${confs[@]}"; do rm -f /root/"${f}".conf.bak; done
        systemctl reload nginx >> "$log" 2>&1
    else
        for f in "${confs[@]}"; do mv -f /root/"${f}".conf.bak /etc/nginx/apps/"${f}".conf; done
        echo_warn "nginx refused disable_symlinks, download listings still follow symlinks. See $log"
    fi
fi

users=()
for u in $(_get_user_list); do
    if id -u "$u" > /dev/null 2>&1; then users+=("$u"); fi
done

members=false
for u in "${users[@]}"; do
    if _in_group www-data "$u" || _in_group "$u" www-data; then members=true; fi
done
[[ $members == true || ! -f $done_marker ]] || exit 0
if [[ -f $failed ]]; then
    echo_warn "www-data keeps its group access to every home: $(head -1 "$failed")
Once fixed, run: rm $failed && box update"
    exit 0
fi

echo_progress_start "Replacing the www-data group memberships with ACLs"

for u in "${users[@]}"; do
    h=/home/$u
    if [[ -L $h ]]; then
        _stop "$h is a symlink, give www-data and the swizzin group access to its target yourself"
    elif [[ ! -d $h ]]; then
        _stop "$h does not exist"
    elif [[ $(stat -c %U "$h") != "$u" ]]; then
        _stop "$h belongs to $(stat -c %U "$h"), not $u (an SFTP chroot?): $u cannot set its ACL"
    elif ! _home_acl "$u" >> "$log" 2>&1 || ! getfacl -cp "$h" 2> /dev/null | grep -q '^user:www-data:r-x'; then
        _stop "ACLs do not work on $h (NFS, ZFS without posixacl, mergerfs?)"
    fi
done

problems=()
for f in rindex dindex qbtindex tmsindex; do
    root=$(_served_root /etc/nginx/apps/"${f}".conf) || continue
    [[ -n $root ]] || continue
    rel=${root#/home/\$remote_user/}
    for u in "${users[@]}"; do
        if out=$(_www_acl_served "$u" "$rel" 2>&1); then
            if [[ -n $out ]]; then echo_info "$out"; fi
        else
            problems+=("/home/$u/$rel: ${out##*$'\n'}")
        fi
    done
done
if [[ -f /install/.rtorrent.lock ]]; then
    #shellcheck source=sources/functions/rtorrent
    . /etc/swizzin/sources/functions/rtorrent
    for u in "${users[@]}"; do
        rtorrent_socket_acl "$u"
        if ! getfacl -cp /run/"$u" 2> /dev/null | grep -q '^default:user:www-data:rw-' ||
            { [[ -S /run/$u/.rtorrent.sock ]] && ! _as_www_data test -w /run/"$u"/.rtorrent.sock; }; then
            problems+=("www-data cannot reach the rTorrent socket in /run/$u")
        fi
    done
fi
if [[ -f /install/.rapidleech.lock ]] && ! bash /usr/local/bin/swizzin/nginx/rapidleech.sh; then
    problems+=("www-data cannot write in /home/$(_get_master_username)/rapidleech")
fi
((${#problems[@]} == 0)) || _stop "${problems[@]}"

removed=false
for u in "${users[@]}"; do
    if _in_group "$u" www-data; then gpasswd -d "$u" www-data >> "$log" 2>&1 && removed=true; fi
    if _in_group www-data "$u"; then gpasswd -d www-data "$u" >> "$log" 2>&1 && removed=true; fi
done

# Running workers keep the groups they started with
if [[ $removed == true || -n $(_stale_workers) ]]; then
    for unit in $(systemctl list-units --type=service --all --no-legend --plain 'php*-fpm.service' | awk '{print $1}'); do
        systemctl try-restart "$unit" >> "$log" 2>&1
    done
    systemctl try-reload-or-restart nginx >> "$log" 2>&1
    sleep 2
fi
if [[ -n $(_stale_workers) ]]; then
    echo_warn "Some nginx or PHP-FPM processes still have a user's group, restart nginx and PHP-FPM"
fi

# Sessions and services started before keep the www-data group, which opens PHP-FPM's socket (PHP as www-data)
stale_users=()
for st in /proc/[0-9]*/status; do
    uid=$(awk '/^Uid:/ {print $2}' "$st" 2> /dev/null)
    [[ -n $uid && $uid != 0 && $uid != 33 ]] || continue
    if awk '/^Groups:/ {for (i = 2; i <= NF; i++) if ($i == 33) f = 1} END {exit !f}' "$st" 2> /dev/null; then
        name=$(id -nu "$uid" 2> /dev/null) || name=$uid
        _in_group "$name" www-data || stale_users+=("$name")
    fi
done
if ((${#stale_users[@]})); then
    echo_warn "These users still run processes in the www-data group (sessions or services started earlier): $(printf '%s\n' "${stale_users[@]}" | sort -u | tr '\n' ' ')
Reboot, or end their sessions (loginctl terminate-user <user>) and restart their services (rtorrent@<user>...)"
fi

touch "$done_marker"
echo_progress_done "www-data now only reaches the folders it serves"
