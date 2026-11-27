#!/bin/bash
# Kavita behind nginx: on 127.0.0.1 only, under /kavita/

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/kavita
. /etc/swizzin/sources/functions/kavita

settings="$kavita_dir/config/appsettings.json"
port=$(jq -r '.Port' "$settings")

_rewrite_json() {
    local tmp
    tmp=$(mktemp "$settings.XXXXXX")
    jq '.IpAddresses = "127.0.0.1" | .BaseUrl = "/kavita/"' "$settings" > "$tmp" &&
        chown --reference="$settings" "$tmp" && chmod 600 "$tmp" && mv "$tmp" "$settings"
}

if [[ -f /install/.kavita.lock ]]; then
    systemctl stop kavita
    _rewrite_json
    systemctl start kavita
else
    _rewrite_json
fi

cat > /etc/nginx/apps/kavita.conf <<- NGX
	location /kavita/ {
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
