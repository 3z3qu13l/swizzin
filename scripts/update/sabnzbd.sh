#!/bin/bash

if [[ -f /install/.sabnzbd.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    legacy_template_unit sabnzbd SABnzbd
fi
