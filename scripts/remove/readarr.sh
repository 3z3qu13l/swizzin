#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/servarr
. /etc/swizzin/sources/functions/servarr

app_name="readarr"

READARR_OWNER=$(servarr_owner "$app_name")

user="$READARR_OWNER"
app_configdir="/home/$user/.config/${app_name^}"
app_dir="/opt/${app_name^}"
app_lockname="$app_name"

if ask "Would you like to purge the configuration?" Y; then
    purgeapp="True"
else
    purgeapp="False"
fi

remove_unit "$app_name"
rm -rf "$app_dir"

if [[ "$purgeapp" = "True" ]]; then
    rm -rf "$app_configdir"
fi

if [[ -f /install/.nginx.lock ]]; then
    rm "/etc/nginx/apps/$app_name.conf"
    systemctl reload nginx >> "$log" 2>&1
fi

swizdb clear "$app_name/owner"
rm "/install/.$app_lockname.lock"
