#!/bin/bash
# swizdash upgrade, installs the latest release

if [[ ! -f /install/.swizdash.lock ]]; then
    echo_error "swizdash is not installed"
    exit 1
fi

#shellcheck source=sources/functions/swizdash
. /etc/swizzin/sources/functions/swizdash

swizdash_download
swizdash_token
swizdash_ptrace
swizdash_systemd
if ! bash /usr/local/bin/swizzin/nginx/swizdash.sh; then
    echo_error "swizdash is upgraded but its nginx config could not be written"
    exit 1
fi
systemctl reload nginx
echo_success "swizdash upgraded"
