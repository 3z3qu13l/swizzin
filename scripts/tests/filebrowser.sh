#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "filebrowser" || BAD=true
check_nginx "filebrowser" || BAD=true

evaluate_bad "filebrowser"
