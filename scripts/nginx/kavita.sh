#!/bin/bash
# Kavita behind nginx: on 127.0.0.1 only, under /kavita/

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/kavita
. /etc/swizzin/sources/functions/kavita

port=$(jq -r '.Port' "$kavita_settings")

if [[ -f /install/.kavita.lock ]]; then
    systemctl stop kavita
    _kavita_set '.IpAddresses = "127.0.0.1" | .BaseUrl = "/kavita/"'
    systemctl start kavita
else
    _kavita_set '.IpAddresses = "127.0.0.1" | .BaseUrl = "/kavita/"'
fi

# nginx's password stays in front until Kavita has an admin (kavita_create_admin)
open=
[[ -f $kavita_dir/config/.swizzin-open ]] && open="auth_basic off;"

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
	    ${open}
	}
NGX
