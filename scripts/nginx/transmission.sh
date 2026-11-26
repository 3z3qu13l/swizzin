#!/bin/bash
# nginx setup for transmission
# by liara for swizzin
# copyright 2020 swizzin.ltd

users=($(cut -d: -f1 < /etc/htpasswd))
#shellcheck source=sources/functions/transmission
. /etc/swizzin/sources/functions/transmission

if [[ ! -f /etc/nginx/apps/tmsindex.conf ]]; then
    cat > /etc/nginx/apps/tmsindex.conf << DIN
location /transmission.downloads {
    alias /home/\$remote_user/transmission/downloads;
    disable_symlinks if_not_owner from=/home/\$remote_user;
    include /etc/nginx/snippets/fancyindex.conf;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd;

  location ~* \.php\$ {

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

if [[ ! -f /etc/nginx/apps/transmission.conf ]]; then
    cat > /etc/nginx/apps/transmission.conf << TCONF
location /transmission {
    return 301 /transmission/web/;
}

location /transmission/ {
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Host \$http_host;
    proxy_set_header X-NginX-Proxy true;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_pass_header X-Transmission-Session-Id;
    add_header   Front-End-Https   on;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd;
    proxy_pass http://\$remote_user.transmission;
}
TCONF
fi

for u in ${users[@]}; do
    active=$(systemctl is-active transmission@$u)
    echo_log_only "Service for $u was $active"
    if [[ $active == "active" ]]; then
        systemctl stop transmission@${u}
    fi

    timeout=0
    while systemctl is-active transmission@"$u" > /dev/null; do
        # echo "is active"
        timeout+=0.3
        if [[ $timeout -ge 20 ]]; then
            echo_error "The service transmission@$u took too long to shut down. Aborting."
            exit 1
        fi
        sleep 0.3
    done

    confpath="/home/${u}/.config/transmission-daemon/settings.json"
    # nginx is now the way in: the web interface no longer answers on every address
    if [[ -f $confpath ]] && ! transmission_rpc_is_local "$u" && ! transmission_rpc_local "$u"; then
        echo_warn "Could not make the Transmission web interface of $u listen on 127.0.0.1 only"
    fi
    if [[ ! -f /etc/nginx/conf.d/${u}.transmission.conf ]]; then
        # read as the user, who writes this file: a link must not reach what only root reads, and
        # anything but a number would be written into nginx's config
        RPCPORT=$(runuser -u "$u" -- jq -r '.["rpc-port"]' "$confpath")
        if [[ ! $RPCPORT =~ ^[0-9]{1,5}$ ]]; then
            echo_warn "The Transmission port of $u is not a number, its web interface is not set up"
        else
            cat > /etc/nginx/conf.d/${u}.transmission.conf << TDCONF
upstream ${u}.transmission {
    server 127.0.0.1:${RPCPORT};
}
TDCONF
        fi
    fi
    if [[ $active == "active" ]]; then
        systemctl start transmission@${u}
        echo_log_only "Activating service"
    fi
done
