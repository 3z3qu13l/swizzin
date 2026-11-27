#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

check_service "filebrowserquantum" || BAD=true
check_nginx "filebrowserquantum" || BAD=true

evaluate_bad "filebrowserquantum"
