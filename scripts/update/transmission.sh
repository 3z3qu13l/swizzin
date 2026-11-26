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
