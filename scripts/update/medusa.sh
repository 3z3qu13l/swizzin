#!/bin/bash

if [[ -f /install/.medusa.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    legacy_template_unit medusa Medusa
fi
