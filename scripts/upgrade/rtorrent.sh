#!/bin/bash
# rtorrent upgrade/downgrade/reinstall script
# shellcheck disable=SC2154 # log is exported by globals.sh
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
fi

# From here until the new rTorrent is installed there is none to start: put the previous one back if the upgrade stops.
# Its packages are copied aside, a rebuild of the same version overwrites them in /root/dist
old_debs=()
rollback=$(mktemp -d)
for p in libtorrent-rakshasa rtorrent; do
    v=$(dpkg-query -W -f='${Version}' "$p" 2> /dev/null)
    [[ -f /root/dist/${p}_${v}.deb ]] && cp "/root/dist/${p}_${v}.deb" "$rollback/" && old_debs+=("$rollback/${p}_${v}.deb")
done
old_repo=$(dpkg -l | grep -P 'libtorrent\d+')
restore_old_rtorrent() {
    if [[ ${#old_debs[@]} -gt 0 ]]; then
        echo_warn "rTorrent upgrade failed, reinstalling the previous version"
        dpkg -i "${old_debs[@]}" >> "$log" 2>&1 && apt-mark hold rtorrent >> "$log" 2>&1
    elif [[ -n $old_repo ]]; then
        echo_warn "rTorrent upgrade failed, reinstalling rtorrent with apt-get"
        apt-get remove -y -q libtorrent-rakshasa >> "$log" 2>&1
        apt_install rtorrent
    else
        echo_error "rTorrent upgrade failed and no previous package was found to reinstall: run box upgrade rtorrent again"
    fi
    rm -rf "$rollback"
    if [[ -n $noexec ]]; then mount -o remount,noexec /tmp; fi
}
trap restore_old_rtorrent EXIT

echo_progress_start "Removing old rTorrent binaries and libraries ... "
if [[ -z $isdeb ]]; then
    remove_rtorrent_legacy
else
    remove_rtorrent
fi
echo_progress_done

if [[ ! $rtorrentver == repo ]]; then
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
# the install steps do not check make install
installed=$(dpkg-query -W -f='${db:Status-Status} ${Version}' rtorrent 2> /dev/null)
if [[ $installed != "installed "* ]] || [[ $rtorrentver != repo && $installed != "installed $rtorrentver" ]]; then
    echo_error "The new rTorrent was not installed, check $log"
    exit 1
fi
trap - EXIT
rm -rf "$rollback"

if [[ -n $noexec ]]; then
    mount -o remount,noexec /tmp
fi

for u in "${users[@]}"; do
    if grep -q localhost /home/$u/.rtorrent.rc; then sed -i 's/localhost/127.0.0.1/g' /home/$u/.rtorrent.rc; fi
    rtorrent_rc_convert /home/$u/.rtorrent.rc
    rtorrent_session_acl "$u" >> "$log" 2>&1
    systemctl try-restart rtorrent@${u}
done

if rtorrent_installed_atleast 0.16; then
    echo_warn "rTorrent 0.16 renamed some commands. swizzin converted its own settings in each .rtorrent.rc, check any line you added yourself if rTorrent does not start."
    # ruTorrent handles the 0.16 commands from v5.3.9 and is never updated in place
    # root git only reads ruTorrent's clone once it is root's
    #shellcheck source=sources/functions/rutorrent
    . /etc/swizzin/sources/functions/rutorrent
    if rutorrent_perms_needed; then rutorrent_perms; fi
    rutorrent_tag=$(rutorrent_git describe --tags 2> /dev/null)
    if [[ -n $rutorrent_tag ]] && dpkg --compare-versions "${rutorrent_tag#v}" lt 5.3.9; then
        echo_warn "ruTorrent ${rutorrent_tag} does not support rTorrent 0.16 (settings and some plugins will fail). Reinstall ruTorrent to get the latest version."
    fi
fi
