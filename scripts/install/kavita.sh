#!/bin/bash
# Kavita installer

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/kavita
. /etc/swizzin/sources/functions/kavita

user=$(_get_master_username)
port=$(port 10001 32001)

kavita_download_latest

echo_progress_start "Configuring Kavita"
# the token key signs the logins: one per server, kept off the command lines.
# On 127.0.0.1 until the master is its admin.
(
    umask 077
    openssl rand -hex 64 | jq -R --argjson port "$port" \
        '{TokenKey: ., Port: $port, IpAddresses: "127.0.0.1", BaseUrl: "/", Cache: 75}' > "$kavita_settings"
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
