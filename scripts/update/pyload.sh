#!/bin/bash
#
# [swizzin :: Install pyLoad package]
#
# Swizzin by liara
#
# swizzin Copyright (C) 2020 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ -f /install/.pyload.lock ]]; then
    echo_warn "The version of pyload installed is susceptible to remote code execution (CVE-2023-0297). It is strongly recommended you uninstall pyload. No fixes will be forthcoming."
fi
