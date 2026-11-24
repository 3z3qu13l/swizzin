#!/bin/bash
# Homepage installer
# https://gethomepage.dev
#
# GNU General Public License v3.0 or later

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "nginx does not appear to be installed, Homepage requires a webserver to function. Please install nginx first before installing this package."
    exit 1
fi

#shellcheck source=sources/functions/homepage
. /etc/swizzin/sources/functions/homepage

user=$(_get_master_username)

function _systemd() {
    local app_port
    app_port=$(port 10001 32001)
    cat > /etc/systemd/system/homepage.service << SERVICE
[Unit]
Description=Homepage dashboard
After=network.target

[Service]
User=${user}
Group=${user}
WorkingDirectory=${homepage_dir}
Environment=NODE_ENV=production
Environment=HOSTNAME=127.0.0.1
Environment=PORT=${app_port}
Environment=HOMEPAGE_CONFIG_DIR=/home/${user}/.config/homepage
Environment=HOMEPAGE_FILE_SWIZZIN_PASSWORD=/home/${user}/.config/homepage/swizzin.password
Environment=LOG_TARGETS=stdout
ExecStart=$(command -v node) server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE
    systemctl daemon-reload
    systemctl enable -q homepage 2>&1 | tee -a "$log"
    # restart, a leftover instance would still listen on the previous port
    systemctl restart homepage
}

homepage_build
# Glances feeds the system graphs, apt_install shows its own progress
homepage_glances
echo_progress_start "Configuring Homepage"
homepage_services
_systemd
echo_progress_done

echo_progress_start "Configuring nginx"
bash /usr/local/bin/swizzin/nginx/homepage.sh || exit 1
systemctl reload nginx
echo_progress_done

touch /install/.homepage.lock
echo_success "Homepage installed"
echo_info "Homepage is available at https://<your server>:$(grep -oP 'listen \K[0-9]+' /etc/nginx/sites-enabled/homepage | head -1), log in with your swizzin master credentials"
if [[ -f /install/.flood.lock ]]; then
    echo_info "The Flood widget logs in with your swizzin credentials, use them for your Flood account"
fi
