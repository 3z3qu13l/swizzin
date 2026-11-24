#!/bin/bash
# rtorrent upgrade/downgrade/reinstall script
# Author: liara

if [[ ! -f /install/.rtorrent.lock ]]; then
    echo_error "rTorrent doesn't appear to be installed. What do you hope to accomplish by running this script?"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive

#shellcheck source=sources/functions/rtorrent
. /etc/swizzin/sources/functions/rtorrent
#shellcheck source=sources/functions/curl
. /etc/swizzin/sources/functions/curl
whiptail_rtorrent

user=$(cut -d: -f1 < /root/.master.info)
rutorrent="/srv/rutorrent/"
users=($(cut -d: -f1 < /etc/htpasswd))

if [[ -n $noexec ]]; then
    mount -o remount,exec /tmp
    noexec=1
fi
isdeb=$(dpkg -l | grep rtorrent)
echo_progress_start "Removing old rTorrent binaries and libraries ... "
if [[ -z $isdeb ]]; then
    remove_rtorrent_legacy
else
    remove_rtorrent
fi
echo_progress_done

echo_progress_start "Checking rTorrent Dependencies ... "
depends_rtorrent
echo_progress_done
if [[ ! $rtorrentver == repo ]]; then
    configure_curl
    echo_progress_start "Building c-ares from source"
    build_cares
    echo_progress_done
    echo_progress_start "Building curl from source"
    build_curl
    echo_progress_done
    configure_rtorrent
    echo_progress_start "Building xmlrpc-c from source ... "
    build_xmlrpc-c
    echo_progress_done
    echo_progress_start "Building libtorrent from source ... "
    build_libtorrent_rakshasa
    echo_progress_done
    echo_progress_start "Building rtorrent from source ... "
    build_rtorrent
    echo_progress_done
else
    echo_progress_start "Installing rtorrent with apt-get ... "
    rtorrent_apt
    echo_progress_done
fi

if [[ -n $noexec ]]; then
    mount -o remount,noexec /tmp
fi

for u in "${users[@]}"; do
    if grep -q localhost /home/$u/.rtorrent.rc; then sed -i 's/localhost/127.0.0.1/g' /home/$u/.rtorrent.rc; fi
    rtorrent_rc_convert /home/$u/.rtorrent.rc
    systemctl try-restart rtorrent@${u}
done

if rtorrent_installed_atleast 0.16; then
    echo_warn "rTorrent 0.16 renamed some commands. swizzin converted its own settings in each .rtorrent.rc, check any line you added yourself if rTorrent does not start."
    # ruTorrent handles the 0.16 commands from v5.3.9 and is never updated in place
    rutorrent_tag=$(git -c safe.directory=/srv/rutorrent -C /srv/rutorrent describe --tags 2> /dev/null)
    if [[ -n $rutorrent_tag ]] && dpkg --compare-versions "${rutorrent_tag#v}" lt 5.3.9; then
        echo_warn "ruTorrent ${rutorrent_tag} does not support rTorrent 0.16 (settings and some plugins will fail). Reinstall ruTorrent to get the latest version."
    fi
fi
