#!/bin/bash
# NZBGet installer for swizzin
# Author: liara
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

# shellcheck source=sources/functions/nzbget
. /etc/swizzin/sources/functions/nzbget

function _install() {
    cd /tmp
    for u in "${users[@]}"; do
        echo_progress_start "Installing nzbget for $u"
        sh nzbget-latest-bin-linux.run --destdir /home/$u/nzbget >> $log 2>&1
        chown -R $u:$u /home/$u/nzbget
        if [[ $u == $master ]]; then
            :
        else
            port=$(shuf -i 6000-7000 -n 1)
            secureport=$(shuf -i 6000-7000 -n 1)
            # as the user: after the chown the user owns ~/nzbget and could swap the config for a link
            (cd / && runuser -u "$u" -- sed -i -e "s/ControlPort=6789/ControlPort=${port}/g" -e "s/SecurePort=6791/SecurePort=${secureport}/g" /home/$u/nzbget/nzbget.conf)
        fi
        # every user gets its certificate, not only the last one of the list
        if [[ ! -d /home/$u/.ssl/ ]]; then
            mkdir -p /home/$u/.ssl/
        fi
        . /etc/swizzin/sources/functions/ssl
        create_self_ssl $u
        (cd / && runuser -u "$u" -- sed -i -e "s/SecureControl=no/SecureControl=yes/g" -e "s/SecureCert=/SecureCert=\/home\/$u\/.ssl\/$u-self-signed.crt/g" -e "s/SecureKey=/SecureKey=\/home\/$u\/.ssl\/$u-self-signed.key/g" /home/$u/nzbget/nzbget.conf)
        echo_progress_done "Nzbget installed for $u"
    done

    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /usr/local/bin/swizzin/nginx/nzbget.sh
        systemctl reload nginx
        echo_progress_done
    else
        echo_info "Nzbget will run on port $port"
    fi

    echo_progress_start "Enabling nzbget for all users"
    for u in "${users[@]}"; do
        systemctl enable -q nzbget@$u 2>&1 | tee -a $log
        systemctl start nzbget@$u
    done
    echo_progress_done
}

function _cleanup() {
    cd /tmp
    rm -rf nzbget-latest-bin-linux.run
}

mapfile -t users < <(_get_user_list)
master=$(_get_master_username)
noexec=$(grep "/tmp" /etc/fstab | grep noexec)

if [[ -n $noexec ]]; then
    mount -o remount,exec /tmp
    noexec=1
fi

if [[ -n $1 ]]; then
    users=($1)
    _download
    _install
    _cleanup
    exit 0
fi

_download
_service
_install
_cleanup
echo_success "Nzbget installed"
touch /install/.nzbget.lock

if [[ -n $noexec ]]; then
    mount -o remount,noexec /tmp
fi
