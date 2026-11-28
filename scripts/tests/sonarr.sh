#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "sonarr" || BAD=true
check_nginx "sonarr" || BAD=true

evaluate_bad "sonarr"
