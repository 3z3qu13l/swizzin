#!/bin/bash
# Komga behind nginx: on 127.0.0.1 only, under /komga/

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/komga
. /etc/swizzin/sources/functions/komga

config=$(_komga_config)
port=$(sed -n 's/^  port: \([0-9]*\)$/\1/p' "$config/application.yml")

_rewrite_config() {
    sed -i -e 's|^  address: .*|  address: 127.0.0.1|' -e 's|^    context-path: .*|    context-path: /komga|' "$config/application.yml"
}

if [[ -f /install/.komga.lock ]]; then
    systemctl stop komga
    _rewrite_config
    systemctl start komga
else
    _rewrite_config
fi

# the master's nginx password stays in front until Komga is claimed (komga_claim)
if [[ -f $config/.swizzin-open ]]; then
    auth="auth_basic off;"
else
    auth="auth_basic \"What's the password?\"; auth_basic_user_file /etc/htpasswd.d/htpasswd.$(_get_master_username);"
fi

cat > /etc/nginx/apps/komga.conf <<- NGX
	location /komga/ {
	    proxy_pass http://127.0.0.1:${port};
	    proxy_http_version 1.1;
	    proxy_set_header Host \$host;
	    proxy_set_header X-Real-IP \$remote_addr;
	    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	    proxy_set_header X-Forwarded-Proto \$scheme;
	    proxy_set_header Upgrade \$http_upgrade;
	    proxy_set_header Connection \$http_connection;
	    proxy_buffering off;
	    client_max_body_size 0;
	    ${auth}
	}
NGX
