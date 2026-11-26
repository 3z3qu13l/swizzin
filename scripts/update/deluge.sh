#!/bin/bash

if [[ -f /install/.deluge.lock ]]; then
    if grep -q ExecStop /etc/systemd/system/deluged@.service > /dev/null 2>&1; then
        sed -i '/ExecStop/d' /etc/systemd/system/deluged@.service
        reloadsys=true
    fi
    if grep -q ExecStop /etc/systemd/system/deluge-web@.service > /dev/null 2>&1; then
        sed -i '/ExecStop/d' /etc/systemd/system/deluge-web@.service
        reloadsys=true
    fi
    if [[ $reloadsys == "true" ]]; then
        echo_progress_start "Updating Deluge systemd service files"
        systemctl daemon-reload
        echo_progress_done
    fi

    # Once: an admin may enable the distribution's instance again, or choose another web address
    if [[ ! -f /install/.deluge-listen-local.done ]]; then
        #shellcheck source=sources/functions/deluge
        . /etc/swizzin/sources/functions/deluge
        if deluge_disable_system_units; then
            echo_info "Stopped and disabled the distribution's own Deluge instance (deluged.service, deluge-web.service on port 8112), swizzin uses deluged@<user> and deluge-web@<user>"
        fi
        if [[ -f /install/.nginx.lock ]]; then
            readarray -t users < <(_get_user_list)
            moved=()
            for u in "${users[@]}"; do
                [[ -f /home/${u}/.config/deluge/web.conf && -f /etc/nginx/conf.d/${u}.deluge.conf ]] || continue
                [[ $(deluge_web_interface "$u") =~ ^(0\.0\.0\.0|::)$ ]] || continue
                echo_progress_start "Making the Deluge web interface of $u answer only through nginx"
                active=$(systemctl is-active deluge-web@"$u")
                systemctl stop deluge-web@"$u"
                if deluge_web_listen "$u" 127.0.0.1 false; then
                    moved+=("$u")
                else
                    echo_warn "Could not make the Deluge web interface of $u listen on 127.0.0.1 only"
                fi
                # activating: a restart loop the stop above interrupted
                if [[ $active == "active" || $active == "activating" || $active == "reloading" ]]; then
                    systemctl start deluge-web@"$u"
                fi
                echo_progress_done
            done
            if ((${#moved[@]})); then
                echo_info "The Deluge web interface (${moved[*]}) no longer answers on its port from other machines, use https://<this server>/deluge/"
            fi
        fi
        touch /install/.deluge-listen-local.done
    fi
fi
