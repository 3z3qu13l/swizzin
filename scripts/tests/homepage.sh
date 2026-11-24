#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "homepage" || BAD=true

listen_port=$(grep -oP 'listen \K[0-9]+' /etc/nginx/sites-enabled/homepage | head -1)
master="$(_get_master_username)"
password="$(_get_user_password "$master")"
curl --user "${master}:${password}" -sSfk "https://127.0.0.1:${listen_port}/api/services" -o /dev/null >> "$log" 2>&1 || {
    echo_warn "Querying Homepage on port ${listen_port} failed"
    BAD=true
}

evaluate_bad "homepage"
