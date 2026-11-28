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
case $before in
    1.*)
        # box upgrade has no one to ask: say it, the admin chose this upgrade
        echo_info "Syncthing v2 moves each user's database to a format v1 cannot read, on its first start: it can take a while on a large setup, and swizzin keeps no copy of the old one"
        ;;
esac
apt_update
apt_install --only-upgrade syncthing
after=$(dpkg-query -f='${Version}' --show syncthing 2> /dev/null)
if [[ $before == "$after" ]]; then
    echo_info "Syncthing ${after} is the latest version"
    exit 0
fi
# a Syncthing older than 1.15 kept its old unit until now
bash /etc/swizzin/scripts/update/syncthing.sh
systemctl try-restart 'syncthing@*' >> "$log" 2>&1
echo_success "Syncthing upgraded from ${before} to ${after}"
