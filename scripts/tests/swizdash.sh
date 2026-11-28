#!/usr/bin/env bash

#shellcheck source=sources/functions/tests
. /etc/swizzin/sources/functions/tests

# socket-activated: the service itself only starts on the first request
check_service "swizdash.socket" || BAD=true
# nginx/swizdash.sh picks another port when 8444 is taken
check_port "$(grep -oP 'listen \K[0-9]+' /etc/nginx/sites-enabled/swizdash | head -1)" || BAD=true

evaluate_bad "swizdash"
