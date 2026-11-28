#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "lidarr" || BAD=true
check_nginx "lidarr" || BAD=true

evaluate_bad "lidarr"
