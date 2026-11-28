#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "syncthing@$(_get_master_username)" || BAD=true
check_port_curl "8384" || BAD=true
check_nginx "syncthing/" || BAD=true

evaluate_bad "syncthing"
