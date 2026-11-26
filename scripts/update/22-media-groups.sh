#!/bin/bash
# Media servers used to join the group of the user whose libraries they read (the master, or Calibre's
# library user), which also opens everything group-readable in that home. New installs get ACLs on the
# folders the admin picks instead (box media-access). The libraries of an existing server are only
# known to the server itself, so its membership is kept and the admin is told once how to replace it.

# Jellyfin reads its certificate in ~/.ssl: given by ACL, so dropping the group keeps its HTTPS working
ssl=/home/$(_get_master_username)/.ssl
if [[ -f /install/.jellyfin.lock ]] && id -u jellyfin > /dev/null 2>&1; then
    if [[ -d $ssl ]] && ! getfacl -cp "$ssl" 2> /dev/null | grep -q '^user:jellyfin:'; then
        out=$(_media_acl jellyfin "$ssl" rX 2>&1) || echo_warn "Jellyfin could not be given its certificate in $ssl: $out"
    fi
fi

marker=/install/.media-groups.info
[[ -f $marker ]] && exit 0

declare -A unit=([plex]=plexmediaserver [emby]=emby-server [jellyfin]=jellyfin [airsonic]=airsonic [calibreweb]=calibreweb)
found=()
for a in plex emby jellyfin airsonic calibreweb; do
    id -u "$a" > /dev/null 2>&1 || continue
    # without its group, Jellyfin would lose its certificate
    if [[ $a == jellyfin && -d $ssl ]] && ! getfacl -cp "$ssl" 2> /dev/null | grep -q '^user:jellyfin:'; then continue; fi
    for u in $(_get_user_list); do
        if [[ ,$(getent group "$u" | cut -d: -f4), == *",$a,"* ]]; then
            found+=("gpasswd -d $a $u && systemctl restart ${unit[$a]}")
        fi
    done
done
if ((${#found[@]})); then
    echo_info "Media servers are in a user's group, so they read everything group-readable in that home.
They can now get their library folders only. For each folder, run:
  box media-access <app> <folder>
It gives read access only (calibreweb: read and write): a server saving images, NFO or subtitles
next to the media needs its group, or an ACL you set yourself. Then take it out of the group and restart it:
$(printf '  %s\n' "${found[@]}")
This message is shown once."
fi
touch "$marker"
