#!/bin/bash
# swizdash gets its own HTTPS port with the swizzin login, like Homepage

listen_port=$(grep -oP 'listen \K[0-9]+' /etc/nginx/sites-enabled/swizdash 2> /dev/null | head -1)
if [[ -z $listen_port ]]; then
    listen_port=8444
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
if [[ -z $cert || -z $key || ! -f /etc/nginx/swizdash-token.conf ]]; then
    echo_error "Could not find the nginx certificate or the swizdash token, swizdash nginx config not written"
    exit 1
fi
master=$(_get_master_username)

cat > /etc/nginx/sites-enabled/swizdash << NGINX
server {
  listen ${listen_port} ssl http2;
  listen [::]:${listen_port} ssl http2;
  server_name _;
  ssl_certificate ${cert};
  ssl_certificate_key ${key};
  include snippets/ssl-params.conf;
  server_tokens off;

  auth_basic "What's the password?";
  # the dashboard starts and installs apps as root, only the master may log in
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};

  location / {
    proxy_pass http://unix:/run/swizdash/http.sock;
    proxy_http_version 1.1;
    proxy_set_header Host \$http_host;
    proxy_set_header Authorization "";
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    include /etc/nginx/swizdash-token.conf;
    proxy_read_timeout 180s;
  }
}
NGINX
