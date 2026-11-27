#!/bin/bash
# transfer.sh installer: share files from the command line, through a link

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "transfer.sh needs nginx, which asks for the password on uploads: install nginx first"
    exit 1
fi

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/transfersh
. /etc/swizzin/sources/functions/transfersh

user=$(_get_master_username)
port=$(port 10001 32001)
datadir="/home/${user}/transfersh"

transfersh_download_latest

echo_progress_start "Configuring transfer.sh"
# uploads are written to the temp path first: /tmp can be in RAM, keep them on the same disk as the files
install -d -o "$user" -g "$user" -m 750 "$datadir" "$datadir/.tmp"

# Its own upload password can be bypassed (dutchcoders/transfer.sh#670): nginx asks for it instead, and
# transfer.sh only listens on 127.0.0.1
cat > /etc/systemd/system/transfersh.service <<- SERV
	[Unit]
	Description=transfer.sh, file sharing from the command line
	After=network.target

	[Service]
	User=${user}
	Group=${user}
	ExecStart=${transfersh_bin} --provider local --basedir ${datadir} --temp-path ${datadir}/.tmp --listener 127.0.0.1:${port} --proxy-path transfersh --purge-days 14 --purge-interval 24
	Restart=on-failure

	[Install]
	WantedBy=multi-user.target
SERV
systemctl daemon-reload
echo_progress_done

echo_progress_start "Configuring nginx for transfer.sh"
bash /etc/swizzin/scripts/nginx/transfersh.sh
systemctl reload nginx
echo_progress_done

systemctl enable -q --now transfersh >> "$log" 2>&1
touch /install/.transfersh.lock

echo_success "transfer.sh installed, on /transfersh/"
echo_info "Upload with: curl -u ${user} --upload-file ./file https://<your server>/transfersh/file
The link it gives back opens without a password. Files are deleted after 14 days"
