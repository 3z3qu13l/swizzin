#!/bin/bash
# nginx setup for qbittorrent
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/qbittorrent
. /etc/swizzin/sources/functions/qbittorrent
users=($(_get_user_list))

if [[ ! -f /etc/nginx/apps/qbtindex.conf ]]; then
    cat > /etc/nginx/apps/qbtindex.conf << DIN
location /qbittorrent.downloads {
    alias /home/\$remote_user/torrents/qbittorrent;
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

if [[ ! -f /etc/nginx/apps/qbittorrent.conf ]]; then
    cat > /etc/nginx/apps/qbittorrent.conf << 'QBTN'
location /qbt {
    return 301 /qbittorrent/;
}

location /qbittorrent/ {
    proxy_pass              http://$remote_user.qbittorrent;
    proxy_http_version      1.1;
    # qBittorrent 5.2+ accepts Basic auth: do not forward the dashboard's credentials to it
    proxy_set_header        Authorization           "";
    proxy_set_header        X-Forwarded-Host        $http_host;
    http2_push_preload on; # Enable http2 push
    auth_basic "What's the password?";

    auth_basic_user_file /etc/htpasswd;
    rewrite ^/qbittorrent/(.*) /$1 break;
    proxy_cookie_path / "/qbittorrent/; Secure";

    # The following directives effectively nullify Cross-site request forgery (CSRF)
    # protection mechanism in qBittorrent, only use them when you encountered connection problems.
    # You should consider disable "Enable Cross-site request forgery (CSRF) protection"
    # setting in qBittorrent instead of using these directives to tamper the headers.
    # The setting is located under "Options -> WebUI tab" in qBittorrent since v4.1.2.
    #proxy_hide_header       Referer;
    #proxy_hide_header       Origin;
    #proxy_set_header        Referer                 '';
    #proxy_set_header        Origin                  '';

    # Not needed since qBittorrent v4.1.0
    #add_header              X-Frame-Options         "SAMEORIGIN";
}
QBTN
fi

for user in ${users[@]}; do
    port=$(qbittorrent_webui_setting "$user" Port)
    # the user can edit their config: only a port number goes into nginx
    if [[ ! $port =~ ^[0-9]{1,5}$ ]]; then
        echo_warn "qBittorrent of ${user} has no valid WebUI port, it is not added to nginx"
        continue
    fi
    cat > /etc/nginx/conf.d/${user}.qbittorrent.conf << QBTUC
upstream ${user}.qbittorrent {
  server 127.0.0.1:${port};
}
QBTUC
    if [[ $(qbittorrent_webui_setting "$user" Address) == "*" ]]; then
        active=$(systemctl is-active qbittorrent@${user})
        if [[ $active == "active" ]]; then
            systemctl stop qbittorrent@${user} >> ${log} 2>&1
        fi
        runuser -u "${user}" -- sed -i -e 's|WebUI\\Address=.*|WebUI\\Address=127.0.0.1|g' -e '/^\[WebUI\]/,/^\[/ s|^Address=.*|Address=127.0.0.1|' /home/${user}/.config/qBittorrent/qBittorrent.conf
        if [[ $active == "active" ]]; then
            systemctl start qbittorrent@${user} >> ${log} 2>&1
        fi
    fi
done
