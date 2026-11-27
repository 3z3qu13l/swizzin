#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "komga" || BAD=true
check_nginx "komga" || BAD=true

evaluate_bad "komga"
