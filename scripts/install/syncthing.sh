#!/bin/bash
#
# [Quick Box :: Install syncthing]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | liara
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

MASTER=$(cut -d: -f1 < /root/.master.info)

#shellcheck source=sources/functions/syncthing
. /etc/swizzin/sources/functions/syncthing

echo_progress_start "Adding Syncthing Repository"
syncthing_apt_source || exit 1
echo_progress_done "Repo added"
apt_update

apt_install syncthing

echo_progress_start "Configuring Syncthing & Starting"
syncthing_write_unit
systemctl enable -q syncthing@${MASTER} 2>&1 | tee -a $log
systemctl start syncthing@${MASTER} >> $log 2>&1
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/syncthing.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Syncthing's web page only answers on this server (127.0.0.1:8384): install nginx to open it from elsewhere"
fi

touch /install/.syncthing.lock
echo_success "Syncthing installed"
