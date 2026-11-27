#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "kavita" || BAD=true
check_nginx "kavita" || BAD=true

evaluate_bad "kavita"
