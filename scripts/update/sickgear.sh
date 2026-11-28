#!/bin/bash

if [[ -f /install/.sickgear.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    legacy_template_unit sickgear SickGear
fi
