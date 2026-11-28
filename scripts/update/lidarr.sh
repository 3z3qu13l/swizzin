#!/bin/bash
if [[ -f /install/.lidarr.lock ]]; then
    #shellcheck source=sources/functions/servarr
    . /etc/swizzin/sources/functions/servarr
    if ! LIDARR_OWNER=$(servarr_owner lidarr "$LIDARR_OWNER"); then
        echo_info "Setting Lidarr owner = $LIDARR_OWNER"
        swizdb set "lidarr/owner" "$LIDARR_OWNER"
    fi

    if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/lidarr.service; then
        echo_warn "Lidarr still runs on mono, which is no longer supported: back up its settings, then reinstall it with box remove lidarr && box install lidarr"
    fi

    if [[ -f /install/.nginx.lock ]]; then
        if grep -q "8686/lidarr" /etc/nginx/apps/lidarr.conf || ! grep -q "calendar" /etc/nginx/apps/lidarr.conf; then
            echo_progress_start "Updating nginx for config for lidarr"
            bash /etc/swizzin/scripts/nginx/lidarr.sh
            systemctl reload nginx -q
            echo_progress_done "nginx conf for lidarr upgraded"
        fi
    fi
fi
