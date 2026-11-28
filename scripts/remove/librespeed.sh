#!/bin/bash
# Librespeed uninstaller for swizzin
# Author: hwcltjn

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

function _removeLibreSpeed() {
    sudo rm -r /srv/librespeed
    sudo rm /etc/nginx/apps/librespeed.conf
    sudo rm /install/.librespeed.lock
    nginx_reload
}

_removeLibreSpeed
