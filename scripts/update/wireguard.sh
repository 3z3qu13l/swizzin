#!/bin/bash

if [[ -f /install/.wireguard.lock ]]; then
    if grep -q "Pin-Priority: 150" /etc/apt/preferences.d/limit-unstable 2> /dev/null; then
        echo_warn "WireGuard still installs from Debian unstable, which is no longer supported: back up its settings, then reinstall it with box remove wireguard && box install wireguard"
    fi
    # older installs appended this exact line to /etc/sysctl.conf (Debian's own template writes it without spaces)
    if grep -qsx 'net\.ipv4\.ip_forward = 1' /etc/sysctl.conf; then
        echo_progress_start "Moving the wireguard IP forwarding setting to /etc/sysctl.d"
        echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/60-swizzin-wireguard.conf
        sed -i '/^net\.ipv4\.ip_forward = 1$/d' /etc/sysctl.conf
        [[ -s /etc/sysctl.conf ]] || rm -f /etc/sysctl.conf
        sysctl -q -p /etc/sysctl.d/60-swizzin-wireguard.conf >> "$log" 2>&1
        echo_progress_done
    fi
fi
