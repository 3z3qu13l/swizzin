#!/bin/bash
# shellcheck disable=SC2154 # log is exported by globals.sh
users=($(cut -d: -f1 < /etc/htpasswd))

#shellcheck source=sources/functions/rtorrent
. /etc/swizzin/sources/functions/rtorrent

for u in "${users[@]}"; do
    restart=0
    # Create tmpfiles.d for user if not exists
    if [[ ! -f /etc/tmpfiles.d/${u}.conf ]]; then
        echo_progress_start "Creating rtorrent tmpfiles.d for ${u}"
        echo "D /var/run/${u} 0750 ${u} ${u} -" >> /etc/tmpfiles.d/${u}.conf
        systemd-tmpfiles /etc/tmpfiles.d/${u}.conf --create
        echo_progress_done
    fi

    if [[ -f /home/${u}/.rtorrent.rc ]]; then
        if ! grep -q network.scgi.open_local /home/${u}/.rtorrent.rc && grep -qE '^\s*network\.scgi\.open_port' /home/${u}/.rtorrent.rc; then
            echo_warn "rTorrent for ${u} still listens on an SCGI port, which ruTorrent and Flood no longer use: in /home/${u}/.rtorrent.rc, replace the network.scgi.open_port line with network.scgi.open_local = /var/run/${u}/.rtorrent.sock, then systemctl restart rtorrent@${u}"
        fi
        # rTorrent opened its session folder to everyone at each start, and chmodded an rpc.socket nothing uses.
        # Run as the user: a link they put there is never followed as root
        if runuser -u "${u}" -- grep -qE "^execute.nothrow = chmod,777,/home/${u}/(\.config/rpc\.socket|\.sessions)$" /home/${u}/.rtorrent.rc; then
            runuser -u "${u}" -- sed -i -E "/^execute.nothrow = chmod,777,\/home\/${u}\/(\.config\/rpc\.socket|\.sessions)$/d" /home/${u}/.rtorrent.rc 2>> "$log"
            runuser -u "${u}" -- chmod 755 /home/${u}/.sessions 2>> "$log"
        fi
        # ruTorrent's Get .torrent reads the session folder, which rTorrent 0.16.25+ wrote 0600
        if rtorrent_installed_atleast 0.16.26 && ! grep -qE '^\s*session\.umask\.set\b' "/home/${u}/.rtorrent.rc"; then
            rtorrent_rc_convert "/home/${u}/.rtorrent.rc"
            grep -qE '^\s*session\.umask\.set\b' "/home/${u}/.rtorrent.rc" && restart=1
        fi
        if id -u "$u" > /dev/null 2>&1 && [[ -d /home/${u}/.sessions ]] &&
            ! getfacl -cp "/home/${u}/.sessions" 2> /dev/null | grep -q "^default:user:$(rutorrent_web_account):r"; then
            rtorrent_session_acl "$u" >> "$log" 2>&1 || echo_warn "Could not let ruTorrent read /home/${u}/.sessions, Get .torrent will fail"
        fi
    fi
    if [[ $restart = 1 ]]; then
        echo_progress_start "Restarting rtorrent for ${u} after config update"
        systemctl try-restart rtorrent@${u}
        echo_progress_done
    fi
    if [[ -f /home/${u}/.flood/config.js ]] && grep -q "socket: false" /home/${u}/.flood/config.js; then
        echo_warn "Flood for ${u} still uses its v1 config (~/.flood/config.js), which is no longer supported: back up its settings, then reinstall it with box remove flood && box install flood"
    fi
done
