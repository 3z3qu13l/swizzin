#!/bin/bash
if [[ -f /install/.btsync.lock ]]; then
    if [[ ! -f /etc/systemd/system/resilio-sync.service ]]; then
        echo_warn "Resilio Sync still uses its packaged rslsync service, which is no longer supported: back up its settings, then reinstall it with box remove btsync && box install btsync"
    fi
    if grep -q EULA /etc/resilio-sync/config.json > /dev/null 2>&1; then
        isActive=$(systemctl is-active resilio-sync)
        if [[ $isActive == "active" ]]; then
            systemctl stop resilio-sync
        fi
        sed -i '/EULA/d' /etc/resilio-sync/config.json
        if [[ $isActive == "active" ]]; then
            systemctl start resilio-sync
        fi
    fi
fi
