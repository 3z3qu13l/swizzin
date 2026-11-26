#!/bin/bash

conf=/etc/nginx/apps/emby.conf
# without these headers the Emby web client's websocket (live updates, remote control) is refused
if [[ -f $conf ]] && ! grep -q 'http_upgrade' "$conf"; then
    echo_progress_start "Enabling websockets for Emby in nginx"
    cp "$conf" "$conf.bak"
    sed -i 's|^\(\s*\)include /etc/nginx/snippets/proxy.conf;|&\n\1proxy_set_header Upgrade $http_upgrade;\n\1proxy_set_header Connection $http_connection;|' "$conf"
    if grep -q 'http_upgrade' "$conf" && nginx -t > /dev/null 2>&1; then
        rm "$conf.bak"
        systemctl reload nginx
        echo_progress_done
    else
        mv "$conf.bak" "$conf"
        echo_warn "Could not add websocket headers to $conf, add 'proxy_set_header Upgrade \$http_upgrade;' and 'proxy_set_header Connection \$http_connection;' to its location manually"
    fi
fi
