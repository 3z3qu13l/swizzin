#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "prowlarr" || BAD=true
check_nginx "prowlarr" || BAD=true

evaluate_bad "prowlarr"
