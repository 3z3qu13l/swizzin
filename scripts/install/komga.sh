#!/bin/bash
# Komga installer

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/komga
. /etc/swizzin/sources/functions/komga

user=$(_get_master_username)
port=$(port 10001 32001)
config=$(_komga_config)

komga_dependencies
komga_download_latest

echo_progress_start "Configuring Komga"
# a ~/.config made here by root would lock the master out of it
[[ -d /home/${user}/.config ]] || install -d -o "$user" -g "$user" "/home/${user}/.config"
install -d -m 700 -o "$user" -g "$user" "$config"
# on 127.0.0.1 until the master has claimed it
cat > "$config/application.yml" <<- YAML
	server:
	  port: ${port}
	  address: 127.0.0.1
	  servlet:
	    context-path: /
YAML
chown "$user:" "$config/application.yml"

cat > /etc/systemd/system/komga.service <<- SERV
	[Unit]
	Description=Komga, server for comics, manga and books
	After=network.target

	[Service]
	User=${user}
	Group=${user}
	Environment=KOMGA_CONFIGDIR=${config}
	WorkingDirectory=${config}
	ExecStart=$(komga_java) -jar ${komga_dir}/komga.jar
	SuccessExitStatus=143
	TimeoutStopSec=30
	Restart=on-failure

	[Install]
	WantedBy=multi-user.target
SERV
systemctl daemon-reload
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx for Komga"
    bash /etc/swizzin/scripts/nginx/komga.sh
    systemctl reload nginx
    echo_progress_done
fi

systemctl enable -q --now komga >> "$log" 2>&1
touch /install/.komga.lock
komga_claim

if [[ -f /install/.nginx.lock ]]; then
    echo_success "Komga installed, on /komga/"
else
    echo_success "Komga installed, on port ${port}"
fi
echo_info "Log in as $(komga_login), and add your libraries in Komga's settings: folders under /home/${user} work"
