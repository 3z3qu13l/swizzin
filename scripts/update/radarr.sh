#!/bin/bash
if [[ -f /install/.radarr.lock ]]; then
    if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/radarr.service; then
        echo_warn "Radarr still runs on mono, which is no longer supported: back up its settings, then reinstall it with box remove radarr && box install radarr"
    fi
    #Mandatory SSL Port change for Readarr
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    #shellcheck source=sources/functions/servarr
    . /etc/swizzin/sources/functions/servarr
    app_name="radarr"
    if ! radarrOwner=$(servarr_owner "$app_name" "$radarrOwner"); then
        ownerToSetInDB='True'
    fi

    app_configfile="/home/$radarrOwner/.config/Radarr/config.xml"

    if [[ $ownerToSetInDB = 'True' ]]; then
        if [ -e "$app_configfile" ]; then
            echo_info "Setting ${app_name^} owner = $radarrOwner in SwizDB"
            swizdb set "$app_name/owner" "$radarrOwner"
        else
            echo_error "${app_name^} config file for radarr owner does not exist in expected location.
We are checking for $app_configfile.
If the user here is incorrect, please run \`radarrOwner=<user> box update\`.
${app_name^} updater is exiting, please try again later."
            exit 1
        fi
    else
        echo_log_only "Radarr owner $radarrOwner apparently did not need an update"
    fi

    if grep -q "<SslPort>8787" "$app_configfile"; then
        echo_progress_start "Changing Radarr's default SSL port"
        sed -i 's|<SslPort>8787</SslPort>|<SslPort>9898</SslPort>|g' "$app_configfile"
        systemctl try-restart -q radarr

        if grep -q "<EnableSsl>True" "$app_configfile"; then
            echo_info "Radarr SSL port changed from 8787 to 9898 due to Readarr conflicts; please ensure to adjust your dependent systems in case they were using this port"
        fi
        echo_progress_done "Radarr's default SSL port changed"
    else
        echo_log_only "Radarr's ports are not on 8787"
    fi
    if [[ -f /install/.nginx.lock ]]; then
        # check for /feed/calendar auth bypass
        if grep -q "7878/radarr" /etc/nginx/apps/radarr.conf || ! grep -q "calendar" /etc/nginx/apps/radarr.conf; then
            echo_progress_start "Upgrading nginx config for Radarr"
            bash /etc/swizzin/scripts/nginx/radarr.sh
            systemctl reload nginx -q
            echo_progress_done "nginx config for Radarr upgraded"
        fi
    fi
fi
