#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "radarr" || BAD=true
check_nginx "radarr" || BAD=true

evaluate_bad "radarr"
