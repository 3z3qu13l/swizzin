#!/bin/bash

users=($(cut -d: -f1 < /etc/htpasswd))

for u in "${users[@]}"; do
    systemctl stop -q nzbget@$u
    systemctl disable -q nzbget@$u
    # NZBGet keeps its downloads in ~/nzbget/downloads: removing the program must not take them with it.
    # Only finished, unfinished and queued nzb files count, its log is written there too
    d=/home/$u/nzbget/downloads
    if [[ -n $(find "$d/completed" "$d/intermediate" "$d/nzb" -type f -print -quit 2> /dev/null) ]]; then
        # as the user: a root rm given these paths would follow ~/nzbget if the user swapped it for a link meanwhile
        (cd / && runuser -u "$u" -- find /home/$u/nzbget -mindepth 1 -maxdepth 1 ! -name downloads -exec rm -rf {} +)
        echo_info "The NZBGet downloads of $u are kept in /home/$u/nzbget/downloads"
    else
        rm -rf /home/$u/nzbget
    fi
    rm /etc/nginx/conf.d/$u.nzbget.conf
done

rm /etc/systemd/system/nzbget@.service
systemctl daemon-reload
rm /etc/nginx/apps/nzbget.conf
rm /install/.nzbget.lock
