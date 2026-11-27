#!/bin/bash
# FileBrowser Quantum behind nginx: on 127.0.0.1 only, under /filebrowserquantum/

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/filebrowserquantum
. /etc/swizzin/sources/functions/filebrowserquantum

config=$(_fbq_config)
port=$(sed -n 's/^  port: \([0-9]*\)$/\1/p' "$config")

_rewrite_config() {
    # the forwarded headers are trusted from nginx only
    sed -i -e 's|^  listen: .*|  listen: 127.0.0.1|' \
        -e 's|^  baseURL: .*|  baseURL: /filebrowserquantum/\n  trustProxyHeaders: true\n  trustedProxies:\n    - 127.0.0.1|' "$config"
}

if ! grep -q '^  trustProxyHeaders:' "$config"; then
    if [[ -f /install/.filebrowserquantum.lock ]]; then
        systemctl stop filebrowserquantum
        _rewrite_config
        systemctl start filebrowserquantum
    else
        _rewrite_config
    fi
fi

cat > /etc/nginx/apps/filebrowserquantum.conf <<- NGX
	location /filebrowserquantum/ {
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
	    auth_basic off;
	}
NGX
