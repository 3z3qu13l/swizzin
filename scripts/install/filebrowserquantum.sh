#!/bin/bash
# FileBrowser Quantum installer

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/filebrowserquantum
. /etc/swizzin/sources/functions/filebrowserquantum

user=$(_get_master_username)
port=$(port 10001 32001)
confdir="/home/${user}/.config/filebrowserquantum"

fbq_download_latest

echo_progress_start "Configuring FileBrowser Quantum"
mkdir -p "$confdir"
cat > "$confdir/config.yaml" <<- YAML
	http:
	  port: ${port}
	  listen: 0.0.0.0
	  baseURL: /
	server:
	  sources:
	    - path: /home/${user}
	      name: Home
	  database:
	    path: ${confdir}/filebrowser.sqlite
	  cacheDir: ${confdir}/cache
	auth:
	  methods:
	    password:
	      enabled: true
	      adminUsername: ${user}
	      # swizzin checks the password strength already
	      minLength: 1
YAML
chown -R "$user:" "$confdir"
chmod 700 "$confdir"

if ! fbq_set_password "$user" "$(_get_user_password "$user")"; then
    echo_warn "Could not create the FileBrowser Quantum user (see $log), run box chpasswd ${user} to retry"
fi

cat > /etc/systemd/system/filebrowserquantum.service <<- SERV
	[Unit]
	Description=FileBrowser Quantum, web file manager
	After=network.target

	[Service]
	User=${user}
	Group=${user}
	UMask=002
	WorkingDirectory=${confdir}
	ExecStart=${fbq_bin} -c ${confdir}/config.yaml
	TimeoutStopSec=20
	Restart=on-failure

	[Install]
	WantedBy=multi-user.target
SERV
systemctl daemon-reload
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx for FileBrowser Quantum"
    bash /etc/swizzin/scripts/nginx/filebrowserquantum.sh
    systemctl reload nginx
    echo_progress_done
fi

systemctl enable -q --now filebrowserquantum >> "$log" 2>&1
touch /install/.filebrowserquantum.lock

if [[ -f /install/.nginx.lock ]]; then
    echo_success "FileBrowser Quantum installed, on /filebrowserquantum/"
else
    echo_success "FileBrowser Quantum installed, on port ${port}"
fi
echo_info "Log in with your swizzin credentials. The first start takes about a minute"
