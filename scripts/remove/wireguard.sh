#!/bin/bash
distribution=$(lsb_release -is)
codename=$(lsb_release -cs)

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
users=($(_get_user_list))
for u in ${users[@]}; do
    systemctl disable --now -q wg-quick@wg$(id -u $u)
    rm -rf /home/$u/.wireguard
done

rm -rf /etc/wireguard/

echo_progress_start "Removing the wireguard IP forwarding setting"
rm -f /etc/sysctl.d/60-swizzin-wireguard.conf
# older installs appended this exact line (Debian's own template writes it without spaces) and created the file on trixie
if [[ -f /etc/sysctl.conf ]]; then
    sed -i '/^net\.ipv4\.ip_forward = 1$/d' /etc/sysctl.conf
    [[ -s /etc/sysctl.conf ]] || rm -f /etc/sysctl.conf
fi
# Docker, LXC and libvirt turn forwarding on at runtime, without a sysctl file, and their containers need it
for bin in dockerd containerd podman lxc-start lxd incus libvirtd k3s kubelet; do
    command -v "$bin" > /dev/null && keep_forwarding=$bin
done
if [[ -n $keep_forwarding ]]; then
    echo_warn "IP forwarding stays on because $keep_forwarding is installed"
else
    # off, then the system's own sysctl files apply again in case one of them turns it on
    sysctl -q -w net.ipv4.ip_forward=0
    sysctl -q --system > /dev/null 2>&1
    if [[ $(sysctl -n net.ipv4.ip_forward) == 0 ]]; then
        echo_info "IP forwarding is now off. If something else on this server routes traffic, turn it back on in /etc/sysctl.d"
    fi
fi
echo_progress_done

apt_remove wireguard wireguard-tools wireguard-dkms qrencode

echo_progress_start "Removing unused repositories"

if [[ $distribution == "Debian" ]]; then
    rm_if_exists /etc/apt/sources.list.d/unstable.list
    rm_if_exists /etc/apt/preferences.d/limit-unstable
fi
echo_progress_done

apt_update

rm /install/.wireguard.lock
