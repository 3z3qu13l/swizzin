#! /bin/bash
# Netdata nginx proxy installer
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active netdata)

if [[ ! -f /etc/nginx/apps/netdata.conf ]]; then
    cat > /etc/nginx/apps/netdata.conf << NET
location /netdata {
  return 301 /netdata/;
}

location ~ /netdata/(?<ndpath>.*) {
  proxy_redirect off;
  proxy_set_header Host \$host;

  proxy_set_header X-Forwarded-Host \$host;
  proxy_set_header X-Forwarded-Server \$host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_http_version 1.1;
  proxy_pass_request_headers on;
  proxy_set_header Connection "keep-alive";
  proxy_store off;
  proxy_pass http://127.0.0.1:19999/\$ndpath\$is_args\$args;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};

  gzip on;
  gzip_proxied any;
  gzip_types *;
}
NET
fi
# Behind nginx netdata only answers on 127.0.0.1, or it shows the server's state to the network without a password.
# Recent netdata.conf files are a short stub, without the "# bind to = *" line older ones had
# a static netdata install (no package for the distribution) keeps its configuration under /opt/netdata
conf=/etc/netdata/netdata.conf
[[ -f $conf || ! -f /opt/netdata/etc/netdata/netdata.conf ]] || conf=/opt/netdata/etc/netdata/netdata.conf
if [[ ! -f $conf ]]; then
    echo_warn "netdata.conf not found: netdata may still answer the network on port 19999"
    exit 1
fi
if ! grep -qE '^\s*bind to\s*=\s*127\.0\.0\.1\s*$' "$conf"; then
    if grep -qE '^\s*bind to\s*=' "$conf"; then
        sed -i -E 's/^(\s*)bind to\s*=.*/\1bind to = 127.0.0.1/' "$conf"
    elif grep -q '^\[web\]' "$conf"; then
        sed -i '/^\[web\]/a\    bind to = 127.0.0.1' "$conf"
    else
        printf '\n[web]\n    bind to = 127.0.0.1\n' >> "$conf"
    fi
fi
if [[ $isactive == "active" ]]; then
    systemctl restart netdata
fi
