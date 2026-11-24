#!/bin/bash
# Homepage upgrade, rebuilds the latest release

if [[ ! -f /install/.homepage.lock ]]; then
    echo_error "Homepage is not installed"
    exit 1
fi

#shellcheck source=sources/functions/homepage
. /etc/swizzin/sources/functions/homepage

homepage_build
homepage_services
echo_success "Homepage upgraded"
