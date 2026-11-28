#!/bin/bash
if [[ ! -f /install/.syncthing.lock ]]; then
    echo_error "Syncthing not installed"
    exit 1
fi
#shellcheck source=sources/functions/syncthing
. /etc/swizzin/sources/functions/syncthing

# a server box update has not reached yet would stay on v1
bash /etc/swizzin/scripts/update/syncthing.sh || exit 1
grep -qs 'syncthing stable-v2' "$syncthing_list" || {
    echo_error "Syncthing's v2 apt channel could not be set up"
    exit 1
}

before=$(dpkg-query -f='${Version}' --show syncthing 2> /dev/null)
apt_update
apt_install --only-upgrade syncthing
after=$(dpkg-query -f='${Version}' --show syncthing 2> /dev/null)
if [[ $before == "$after" ]]; then
    echo_info "Syncthing ${after} is the latest version"
    exit 0
fi
case $before in 1.*) echo_info "Syncthing moves its database to a new format on the first start of v2: it can take a while on a large setup" ;; esac
systemctl try-restart 'syncthing@*' >> "$log" 2>&1
echo_success "Syncthing upgraded from ${before} to ${after}"
