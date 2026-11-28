#!/bin/bash
#xmr-stak upgrade to xmrig

if [[ -f /install/.xmr-stak.lock ]]; then
    echo_warn "xmr-stak is no longer supported: replace it with box remove xmr-stak && box install xmrig"
fi
