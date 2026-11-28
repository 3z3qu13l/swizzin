#!/bin/bash

if [[ -f /install/.nzbhydra.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    legacy_template_unit nzbhydra NZBHydra
fi
