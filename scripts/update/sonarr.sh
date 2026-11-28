#!/bin/bash
if [[ -f /install/.sonarr.lock ]]; then
    if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/sonarr.service; then
        echo_warn "Sonarr still runs on mono, which is no longer supported: back up its settings, then reinstall it with box remove sonarr && box install sonarr"
    fi
    if dpkg -l | grep sonarr | grep ^ii > /dev/null 2>&1; then
        echo_warn "Sonarr is still installed from its apt package, which is no longer supported: back up its settings, then box remove sonarr, apt purge sonarr and box install sonarr"
    fi
    #Mandatory SSL Port change for Readarr
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    app_name="sonarr"
    if [ -z "$sonarrOwner" ]; then
        if ! sonarrOwner="$(swizdb get $app_name/owner)"; then
            sonarrOwner=$(_get_master_username)
            ownerToSetInDB='True'
        fi
    else
        ownerToSetInDB='True'
    fi

    app_configfile="/home/$sonarrOwner/.config/Sonarr/config.xml"

    if [[ $ownerToSetInDB = 'True' ]]; then
        if [ -e "$app_configfile" ]; then
            echo_info "Setting ${app_name^} owner = $sonarrOwner in SwizDB"
            swizdb set "$app_name/owner" "$sonarrOwner"
        else
            echo_error "${app_name^} config file for sonarr owner does not exist in expected location.
We are checking for $app_configfile.
If the user here is incorrect, please run \`sonarrOwner=<user> box update\`.
${app_name^} updater is exiting, please try again later."
            exit 1
        fi
    else
        echo_log_only "Sonarr owner $sonarrOwner apparently did not need an update"
    fi

    if [[ -f /install/.nginx.lock ]]; then
        if grep -q "8989/sonarr" /etc/nginx/apps/sonarr.conf || ! grep -q "proxy_read_timeout" /etc/nginx/apps/sonarr.conf; then
            echo_progress_start "Upgrading nginx config for Sonarr"
            bash /etc/swizzin/scripts/nginx/sonarr.sh
            systemctl reload nginx -q
            echo_progress_done "Nginx config for Sonarr upgraded"
        fi
    fi
fi

if dpkg -l | grep nzbdrone > /dev/null 2>&1; then
    echo_warn "Sonarr v2 (nzbdrone package) is still installed, which is no longer supported: remove it with box remove sonarrold, then install Sonarr with box install sonarr"
fi
