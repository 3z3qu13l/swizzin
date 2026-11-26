#!/bin/bash

if [ -f /install/.transmission.lock ]; then

    if ! grep -q "\-\-logfile" /etc/systemd/system/transmission@.service; then
        echo_progress_start "Moving transmission's logs to a file instead of syslog"
        sed "s|ExecStart=.*|ExecStart=/usr/bin/transmission-daemon -f --log-error --logfile /home/%i/.config/transmission-daemon/transmission.log|g" -i /etc/systemd/system/transmission@.service
        systemctl daemon-reload
        readarray -t users < <(_get_user_list)
        for user in "${users[@]}"; do
            systemctl restart transmission@"$user"
        done
        echo_progress_done "Logs moved for all users"
    fi

    # A settings.json Transmission could not read (root-owned under a restrictive umask) was replaced by
    # its defaults: rpc-port 9091, no rpc user. swizzin's config is written again, on the port nginx expects.
    readarray -t users < <(_get_user_list)
    for u in "${users[@]}"; do
        conf="/home/${u}/.config/transmission-daemon/settings.json"
        [[ -f $conf ]] || continue
        active=$(systemctl is-active transmission@"$u")
        enabled=$(systemctl is-enabled transmission@"$u")
        # read as the user, never as root: the user can symlink this file or its folder anywhere.
        # A config the user cannot read is one Transmission cannot read either: it is written again.
        # rpc_username: the key name Transmission 4.1+ can save and 5 will save by default
        [[ -z $(runuser -u "$u" -- jq -r '.["rpc-username"] // .rpc_username // empty' "$conf" 2> /dev/null) ]] || continue
        echo_progress_start "Restoring the Transmission config of $u"
        systemctl stop transmission@"$u"
        rpc_port=$(grep -oP '127\.0\.0\.1:\K[0-9]+' "/etc/nginx/conf.d/${u}.transmission.conf" 2> /dev/null) \
            bash /etc/swizzin/scripts/install/transmission.sh "$u"
        # the installer enables and starts it, keep the state the admin chose
        if [[ $enabled != "enabled" ]]; then
            systemctl disable -q transmission@"$u"
        fi
        if [[ $active != "active" ]]; then
            systemctl stop transmission@"$u"
        fi
        echo_progress_done
    done

    # The web interface listened on every address (swizzin's old default), behind its own password only:
    # behind nginx it only needs to answer nginx, as qBittorrent and Deluge already do. Done once, and
    # only on that default: an address an admin chose, or sets back later, is kept
    if [[ -f /install/.nginx.lock && ! -f /install/.transmission-rpc-local.done ]]; then
        . /etc/swizzin/sources/functions/transmission
        moved=()
        for u in "${users[@]}"; do
            conf="/home/${u}/.config/transmission-daemon/settings.json"
            [[ -f $conf ]] || continue
            addr=$(runuser -u "$u" -- jq -r '.["rpc-bind-address"] // .rpc_bind_address // "0.0.0.0"' "$conf" 2> /dev/null) || continue
            [[ $addr == 0.0.0.0 ]] || continue
            echo_progress_start "Making the Transmission web interface of $u answer only through nginx"
            active=$(systemctl is-active transmission@"$u")
            systemctl stop transmission@"$u"
            if transmission_rpc_local "$u"; then
                moved+=("$u")
            else
                echo_warn "Could not make the Transmission web interface of $u listen on 127.0.0.1 only"
            fi
            # activating: a restart loop the stop above interrupted
            if [[ $active == "active" || $active == "activating" || $active == "reloading" ]]; then
                systemctl start transmission@"$u"
            fi
            echo_progress_done
        done
        if ((${#moved[@]})); then
            echo_info "Transmission (${moved[*]}) no longer answers on its port from other machines. Remote apps use https://<this server>/transmission/rpc with the swizzin user and password, apps on this server keep 127.0.0.1:<port>"
        fi
        touch /install/.transmission-rpc-local.done
    fi

    # Ubuntu 26.04+: the AppArmor profile blocks every user's folders
    if [[ -f /etc/apparmor.d/transmission ]]; then
        . /etc/swizzin/sources/functions/transmission
        readarray -t users < <(_get_user_list)
        dirs=()
        for u in "${users[@]}"; do
            conf="/home/${u}/.config/transmission-daemon/settings.json"
            [[ -f $conf ]] || continue
            readarray -t user_dirs < <(jq -r '(.["download-dir"] // .download_dir), (.["incomplete-dir"] // .incomplete_dir), (.["watch-dir"] // .watch_dir) | values' "$conf" 2> /dev/null)
            dirs+=("${user_dirs[@]}")
        done
        _apparmor_transmission "${dirs[@]}"
    fi
fi
