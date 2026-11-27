#!/bin/bash

# Installs made before the wizard was finished at install time left it open to whoever reaches the server first
if [[ -f /install/.emby.lock ]] && ! grep -q '<IsStartupWizardCompleted>true</IsStartupWizardCompleted>' /var/lib/emby/config/system.xml 2> /dev/null &&
    systemctl -q is-active emby-server; then
    #shellcheck source=sources/functions/emby
    . /etc/swizzin/sources/functions/emby
    echo_progress_start "Finishing Emby's first-run wizard"
    if emby_finish_wizard; then echo_progress_done; else echo_progress_done "Not finished"; fi
fi

conf=/etc/nginx/apps/emby.conf
# without these headers the Emby web client's websocket (live updates, remote control) is refused
if [[ -f $conf ]] && ! grep -q 'http_upgrade' "$conf"; then
    echo_progress_start "Enabling websockets for Emby in nginx"
    cp "$conf" "$conf.bak"
    sed -i 's|^\(\s*\)include /etc/nginx/snippets/proxy.conf;|&\n\1proxy_set_header Upgrade $http_upgrade;\n\1proxy_set_header Connection $http_connection;|' "$conf"
    if grep -q 'http_upgrade' "$conf" && nginx -t > /dev/null 2>&1; then
        rm "$conf.bak"
        if systemctl reload nginx; then
            echo_progress_done
        else
            echo_warn "nginx did not reload, Emby websockets work after its next restart"
        fi
    else
        mv "$conf.bak" "$conf"
        echo_warn "Could not add websocket headers to $conf, add 'proxy_set_header Upgrade \$http_upgrade;' and 'proxy_set_header Connection \$http_connection;' to its location manually"
    fi
fi
