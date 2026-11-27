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

# transfer.sh deletes every file older than 14 days in its folder: never one it did not make
if [[ -d $datadir && ! -f $datadir/.swizzin-transfersh && -n $(ls -A "$datadir") ]]; then
    echo_error "${datadir} already exists: move it away, transfer.sh would delete its files older than 14 days"
    exit 1
fi

transfersh_download_latest

echo_progress_start "Configuring transfer.sh"
# uploads are written to the temp path first: /tmp can be in RAM, keep them on the same disk as the files.
# The files sit one level below, so that a path going up from them stays in transfer.sh's folder.
install -d -o "$user" -g "$user" -m 750 "$datadir" "$datadir/files" "$datadir/.tmp"
touch "$datadir/.swizzin-transfersh"

# Its own password, given to nginx only. Nginx asks the master's on uploads: transfer.sh's own check can be
# bypassed from outside (dutchcoders/transfer.sh#670)
(
    umask 077
    printf 'HTTP_AUTH_USER=nginx\nHTTP_AUTH_PASS=%s\n' "$(openssl rand -hex 32)" > "$transfersh_env"
)

cat > /etc/systemd/system/transfersh.service <<- SERV
	[Unit]
	Description=transfer.sh, file sharing from the command line
	After=network.target
	# a request can make it exit: it is always started again
	StartLimitIntervalSec=0

	[Service]
	User=${user}
	Group=${user}
	EnvironmentFile=${transfersh_env}
	ExecStart=${transfersh_bin} --provider local --basedir ${datadir}/files --temp-path ${datadir}/.tmp --listener 127.0.0.1:${port} --proxy-path transfersh --purge-days 14 --purge-interval 1
	Restart=always
	RestartSec=2

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
