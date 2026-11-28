#!/bin/bash

if [[ -f /install/.sickchill.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    legacy_template_unit sickchill SickChill
    if [[ -f /opt/.venv/sickchill/bin/python2 ]]; then
        echo_warn "SickChill still runs on python2, which is no longer supported: back up its settings, then reinstall it with box remove sickchill && box install sickchill"
    fi
fi
