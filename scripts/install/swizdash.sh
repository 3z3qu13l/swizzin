#!/bin/bash
# swizdash installer
# https://github.com/3z3qu13l/swizzin-dashboard
#
# GNU General Public License v3.0 or later

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "nginx does not appear to be installed, swizdash requires a webserver to function. Please install nginx first before installing this package."
    exit 1
fi

#shellcheck source=sources/functions/swizdash
. /etc/swizzin/sources/functions/swizdash
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

apt_install jq curl sudo vnstat

if ! id swizdash > /dev/null 2>&1; then
    useradd --system --home-dir /var/lib/swizdash --no-create-home --shell /usr/sbin/nologin swizdash
fi
# box writes the install and removal logs here, the dashboard only reads them
mkdir -p /var/log/swizdash/jobs
chown root:swizdash /var/log/swizdash /var/log/swizdash/jobs
chmod 0750 /var/log/swizdash /var/log/swizdash/jobs

swizdash_download

echo_progress_start "Configuring swizdash"
swizdash_token
swizdash_systemd
echo_progress_done

echo_progress_start "Configuring nginx"
bash /usr/local/bin/swizzin/nginx/swizdash.sh || exit 1
systemctl reload nginx
echo_progress_done

touch /install/.swizdash.lock
echo_success "swizdash installed"
echo_info "swizdash is available at https://<your server>:$(grep -oP 'listen \K[0-9]+' /etc/nginx/sites-enabled/swizdash | head -1), log in with your swizzin master credentials"
