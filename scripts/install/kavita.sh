#!/bin/bash
# Kavita installer

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/kavita
. /etc/swizzin/sources/functions/kavita

user=$(_get_master_username)
port=5000

kavita_download_latest

echo_progress_start "Configuring Kavita"
# the token key signs the logins: one per server
(
    umask 077
    jq -n --arg key "$(openssl rand -hex 64)" --argjson port "$port" \
        '{TokenKey: $key, Port: $port, IpAddresses: "", BaseUrl: "/", Cache: 75}' > "$kavita_dir/config/appsettings.json"
)
chown -R "$user:" "$kavita_dir"

cat > /etc/systemd/system/kavita.service <<- SERV
	[Unit]
	Description=Kavita, library for books, comics and manga
	After=network.target

	[Service]
	User=${user}
	Group=${user}
	WorkingDirectory=${kavita_dir}
	ExecStart=${kavita_dir}/Kavita
	TimeoutStopSec=20
	Restart=on-failure

	[Install]
	WantedBy=multi-user.target
SERV
systemctl daemon-reload
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx for Kavita"
    bash /etc/swizzin/scripts/nginx/kavita.sh
    systemctl reload nginx
    echo_progress_done
fi

systemctl enable -q --now kavita >> "$log" 2>&1
touch /install/.kavita.lock
kavita_create_admin

if [[ -f /install/.nginx.lock ]]; then
    echo_success "Kavita installed, on /kavita/"
else
    echo_success "Kavita installed, on port ${port}"
fi
echo_info "Add your libraries in Kavita's settings: folders under /home/${user} work"
