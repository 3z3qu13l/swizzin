#!/bin/bash
# Nginx configuration for Shell in a Box
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active shellinabox)
if [[ ! -f /etc/nginx/apps/shell.conf ]]; then
    cat > /etc/nginx/apps/shell.conf << RAD
location /shell/ {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:4200;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
RAD
fi
# Behind nginx, shellinabox must only answer on 127.0.0.1, or its login prompt is open to the network without
# nginx's password. Set in a drop-in of ours: /etc/default/shellinabox belongs to the package (Ubuntu 26.04's has
# no SHELLINABOX_ARGS line, and a package upgrade can replace it). Keep ExecStart in step with install/shellinabox.sh
mkdir -p /etc/systemd/system/shellinabox.service.d
cat > /etc/systemd/system/shellinabox.service.d/swizzin-nginx.conf << 'SIAB'
[Service]
ExecStart=
ExecStart=/usr/bin/shellinaboxd -q --background=/var/run/shellinaboxd.pid -c /var/lib/shellinabox -p 4200 -u shellinabox -g shellinabox $SHELLINABOX_ARGS --localhost-only --disable-ssl
SIAB
systemctl daemon-reload

function _in_shellinabox() {
    local p=$$
    while ((p > 1)); do
        [[ $(ps -o comm= -p "$p") == shellinaboxd ]] && return 0
        p=$(ps -o ppid= -p "$p" | tr -d ' ')
        [[ -n $p ]] || return 1
    done
    return 1
}

if [[ $isactive == "active" ]]; then
    if _in_shellinabox; then
        # Restarting now would close the terminal box runs in, and stop it halfway: wait until box is done
        systemd-run -q /bin/sh -c 'sleep 5; while pgrep -f "[s]wizzin/box" > /dev/null; do sleep 5; done; systemctl restart shellinabox'
        echo_info "Shell in a Box restarts once box is done: this terminal will close, reload the page"
    else
        systemctl restart shellinabox
    fi
fi
