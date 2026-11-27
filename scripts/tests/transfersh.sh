#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "transfersh" || BAD=true
check_nginx "transfersh/" || BAD=true

evaluate_bad "transfersh"
