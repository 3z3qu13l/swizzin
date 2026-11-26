#!/bin/bash
# Nginx configuration for Deluge
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#shellcheck source=sources/functions/deluge
. /etc/swizzin/sources/functions/deluge
users=($(cut -d: -f1 < /etc/htpasswd))

if [[ -n $1 ]]; then
    users=($1)
fi

if [[ ! -f /etc/nginx/apps/dindex.conf ]]; then
    cat > /etc/nginx/apps/dindex.conf << DIN
location /deluge.downloads {
  alias /home/\$remote_user/torrents/deluge;
  disable_symlinks if_not_owner from=/home/\$remote_user;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;

  location ~* \.php$ {

  }
  # Files that a browser opens as a document able to run scripts (HTML, XML, SVG...,
  # following nginx's mime.types) are sandboxed: their scripts cannot act as the
  # dashboard. An add_header here replaces the server's, so those are repeated.
  location ~* \.(s?html?|xhtml|xml|svgz?|atom|rss|mml|kml|xspf)\$ {
    add_header Content-Security-Policy "sandbox" always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-Frame-Options SAMEORIGIN always;
  }
}
DIN
fi

for u in "${users[@]}"; do
    if [[ -f /etc/nginx/apps/${u}.dindex.conf ]]; then rm -f /etc/nginx/apps/${u}.dindex.conf; fi
    [[ -f /home/$u/.config/deluge/web.conf ]] || continue

    isactive=$(systemctl is-active deluge-web@$u)
    if [[ $isactive == "active" ]]; then
        systemctl stop deluge-web@$u
    fi

    # nginx proxies over http to 127.0.0.1; any other address than all interfaces is an admin's choice, kept as is
    addr=$(deluge_web_interface "$u")
    if [[ $addr == 0.0.0.0 || $addr == :: || $addr == 127.0.0.1 ]]; then
        deluge_web_listen "$u" 127.0.0.1 false || echo_warn "Could not make the Deluge web interface of $u listen on 127.0.0.1 over http"
    fi

    if [[ $isactive == "active" ]]; then
        systemctl start deluge-web@$u
    fi

    if [[ ! -f /etc/nginx/conf.d/${u}.deluge.conf ]]; then
        # Read as the user and only a number: the file is theirs and the value lands in nginx's config
        DWPORT=$(cd / && runuser -u "$u" -- grep -oP '"port":\s*\K[0-9]+' "/home/$u/.config/deluge/web.conf" | head -n 1)
        [[ $DWPORT =~ ^[0-9]+$ ]] || {
            echo_warn "No Deluge web port found for $u"
            continue
        }
        cat > /etc/nginx/conf.d/${u}.deluge.conf << DUPS
upstream $u.deluge {
  server 127.0.0.1:$DWPORT;
}
DUPS
    fi

    if [[ ! -f /etc/nginx/apps/deluge.conf ]]; then
        cat > /etc/nginx/apps/deluge.conf << 'DRP'
location /deluge {
  return 301 /deluge/;
}

location /deluge/ {
  include /etc/nginx/snippets/proxy.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;
  proxy_set_header X-Deluge-Base "/deluge/";
  rewrite ^/deluge/(.*) /$1 break;
  proxy_pass http://$remote_user.deluge;
}
DRP
    fi
done
