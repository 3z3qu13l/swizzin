#!/bin/bash
# Installs or updates the transmission-web-control interface. Transmission itself is upgraded through apt.

if [[ ! -f /install/.transmission.lock ]]; then
    echo_error "Transmission doesn't appear to be installed!"
    exit 1
fi

#shellcheck source=sources/functions/transmission
. /etc/swizzin/sources/functions/transmission
[[ -f /etc/systemd/system/transmission@.service.d/web-control.conf ]] && served=true
if [[ -n $SWIZZIN_UPGRADE_ALL && $served != true ]]; then
    # switching the interface restarts every daemon, which box upgrade --all should not do unasked
    echo_info "The transmission-web-control interface is not installed, add it with: box upgrade transmission"
    exit 0
fi
transmission_web_control_install || exit 1

# the daemons only read TRANSMISSION_WEB_HOME when they start
if [[ $served != true ]]; then
    for user in $(_get_user_list); do
        systemctl try-restart "transmission@${user}"
    done
fi
echo_success "transmission-web-control upgraded"
