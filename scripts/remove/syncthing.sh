#!/bin/bash
#shellcheck source=sources/functions/syncthing
. /etc/swizzin/sources/functions/syncthing

systemctl disable -q --now 'syncthing@*' >> "$log" 2>&1
apt_remove --purge syncthing
rm -f "$syncthing_unit"
systemctl daemon-reload
rm -f "$syncthing_list" "$syncthing_pref" "$syncthing_keyring"
rm -f /etc/nginx/apps/syncthing.conf
if [[ -f /install/.nginx.lock ]]; then systemctl reload nginx; fi
rm -f /install/.syncthing.lock
