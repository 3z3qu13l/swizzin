#!/bin/bash
# Homepage cannot run under a sub path, it gets its own HTTPS port with the swizzin login

app_port=$(grep -oP '^Environment=PORT=\K[0-9]+' /etc/systemd/system/homepage.service)
listen_port=$(grep -oP 'listen \K[0-9]+' /etc/nginx/sites-enabled/homepage 2> /dev/null | head -1)
if [[ -z $listen_port ]]; then
    listen_port=8443
    if ss -Htln "sport = :${listen_port}" | grep -q .; then
        #shellcheck source=sources/functions/utils
        . /etc/swizzin/sources/functions/utils
        listen_port=$(port 10001 32001)
    fi
fi

# same certificate as the main site, so Let's Encrypt is reused when present
cert=$(grep -m1 -oP '^\s*ssl_certificate\s+\K[^;]+' /etc/nginx/sites-enabled/default)
key=$(grep -m1 -oP '^\s*ssl_certificate_key\s+\K[^;]+' /etc/nginx/sites-enabled/default)
# a broken server block would take the whole nginx down
if [[ -z $app_port || -z $cert || -z $key ]]; then
    echo_error "Could not find the Homepage port or the nginx certificate, Homepage nginx config not written"
    exit 1
fi
master=$(_get_master_username)

cat > /etc/nginx/sites-enabled/homepage << NGINX
server {
  listen ${listen_port} ssl http2;
  listen [::]:${listen_port} ssl http2;
  server_name _;
  ssl_certificate ${cert};
  ssl_certificate_key ${key};
  include snippets/ssl-params.conf;
  server_tokens off;

  auth_basic "What's the password?";
  # widgets use the master credentials, so only the master may log in
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};

  # tiles link to the apps on the main site, whatever address the browser used
  # vnStat figures for the Traffic cards, read by Homepage itself
  location = /vnstat.json {
    auth_basic off;
    allow 127.0.0.1;
    deny all;
    default_type application/json;
    alias /var/lib/homepage-vnstat/vnstat.json;
  }

  location /swizzin/ {
    rewrite ^/swizzin(/.*)\$ https://\$host\$1 redirect;
  }

  location / {
    proxy_pass http://127.0.0.1:${app_port};
    # Homepage only answers to the hosts it knows, nginx already restricts access
    proxy_set_header Host 127.0.0.1:${app_port};
    proxy_set_header Authorization "";
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_http_version 1.1;
  }
}
NGINX
