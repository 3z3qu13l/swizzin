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
        # Still unreadable and not yet overwritten: Transmission runs on its defaults and would save them when stopped
        if ! runuser -u "$u" -- test -r "$conf"; then
            echo_progress_start "Giving $u its Transmission config"
            cp -p "$conf" "${conf}.swizzin"
            systemctl stop transmission@"$u"
            mv -f "${conf}.swizzin" "$conf"
            chown "$u": "$conf"
            if [[ $active == "active" ]]; then
                systemctl start transmission@"$u"
            fi
            echo_progress_done
        fi
        # rpc_username: the key name Transmission 4.1+ can save and 5 will save by default
        [[ -z $(jq -r '.["rpc-username"] // .rpc_username // empty' "$conf" 2> /dev/null) ]] || continue
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
fi
