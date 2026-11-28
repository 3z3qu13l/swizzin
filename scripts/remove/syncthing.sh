#!/bin/bash
#shellcheck source=sources/functions/syncthing
. /etc/swizzin/sources/functions/syncthing

# loaded instances, plus enabled ones that are not loaded
for unit in $( (
    systemctl list-units 'syncthing@*' --all --plain --no-legend | awk '{print $1}'
    find /etc/systemd/system -path '*.wants/syncthing@*.service' -printf '%f\n'
) | sort -u); do
    systemctl disable -q --now "$unit" >> "$log" 2>&1
done
apt_remove --purge syncthing
rm -f "$syncthing_unit"
systemctl daemon-reload
rm -f "$syncthing_list" "$syncthing_pref" "$syncthing_keyring"
rm -f /etc/nginx/apps/syncthing.conf
if [[ -f /install/.nginx.lock ]]; then systemctl reload nginx; fi
rm -f /install/.syncthing.lock
