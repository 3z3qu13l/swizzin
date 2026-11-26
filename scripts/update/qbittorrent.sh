#!/bin/bash

if [[ -f /install/.qbittorrent.lock ]]; then
    #shellcheck source=sources/functions/qbittorrent
    . /etc/swizzin/sources/functions/qbittorrent
    #Check systemd service for updates
    type=simple
    if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
        unittype=exec
    fi
    if ! grep -q Type=$unittype /etc/systemd/system/qbittorrent@.service; then
        sed -i "s/Type=.*/Type=$unittype/g" /etc/systemd/system/qbittorrent@.service
        reloadsys=true
    fi
    if grep -q "qbittorrent-nox -d" /etc/systemd/system/qbittorrent@.service; then
        sed -i 's|/usr/bin/qbittorrent-nox -d|/usr/bin/qbittorrent-nox|g' /etc/systemd/system/qbittorrent@.service
        reloadsys=true
    fi
    if [[ $reloadsys == true ]]; then
        systemctl daemon-reload
        echo_info "qBittorrent systemd services have been updated. Please restart qBittorrent services at your convenience."
    fi
    #End systemd service updates
    # A config qBittorrent could not read (root-owned under a restrictive umask) was replaced by its
    # defaults: WebUI on *:8080, no user, no password. Nothing to keep there, swizzin's config is written again.
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    for u in $(_get_user_list); do
        [[ -f /home/${u}/.config/qBittorrent/qBittorrent.conf ]] || continue
        [[ -z $(qbittorrent_webui_setting "$u" Username) && -z $(qbittorrent_webui_setting "$u" Password_PBKDF2) && -z $(qbittorrent_webui_setting "$u" Password_ha1) ]] || continue
        echo_progress_start "Restoring the qBittorrent config of $u"
        active=$(systemctl is-active qbittorrent@"$u")
        systemctl stop qbittorrent@"$u"
        qbittorrent_user_config "$u"
        if [[ -f /install/.nginx.lock ]]; then
            bash /etc/swizzin/scripts/nginx/qbittorrent.sh
            systemctl reload nginx
        fi
        if [[ $active == "active" ]]; then
            systemctl start qbittorrent@"$u"
        fi
        echo_progress_done
    done
    #Check for proxy_cookie_path in nginx to prevent writing cookies to /
    if [[ -f /install/.nginx.lock ]]; then
        if ! grep -q proxy_cookie_path /etc/nginx/apps/qbittorrent.conf; then
            echo_progress_start "Updating qBittorrent nginx config"
            sed -r 's|(rewrite .*)|\1\n    proxy_cookie_path / "/qbittorrent/; Secure";|g' -i /etc/nginx/apps/qbittorrent.conf
            systemctl reload nginx
            echo_progress_done
        fi
        if ! grep -qE '^\s*proxy_set_header\s+Authorization' /etc/nginx/apps/qbittorrent.conf; then
            echo_progress_start "Updating qBittorrent nginx config for 5.2+ authentication"
            sed -r 's|(proxy_http_version .*)|\1\n    proxy_set_header        Authorization           "";|' -i /etc/nginx/apps/qbittorrent.conf
            systemctl reload nginx
            echo_progress_done
        fi
        users=($(_get_user_list))
        for user in ${users[@]}; do
            if [[ $(qbittorrent_webui_setting "$user" Address) == "*" ]]; then
                echo_warn "qBittorrent WebUI for ${user} is bound to all interfaces and can be accessed without the nginx proxy. The updater will not update this default for you in the event you want to keep it this way. You can fix this yourself in the qBittorrent WebUI: Settings > Web UI > Web User Interface > IP Address: 127.0.0.1. You can suppress this warning by changing your bind address to 0.0.0.0, though this may interfere with ipv6 access. Restart qBittorrent after making the change."
            fi
        done
    fi
fi
