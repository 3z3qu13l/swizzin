#!/bin/bash
#
# ZNC Installer
#
# Originally written for QuickBox.io by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

DISTRO=$(lsb_release -is)
CODENAME=$(lsb_release -cs)
#shellcheck source=sources/functions/letsencrypt
. /etc/swizzin/sources/functions/letsencrypt

echo_progress_start "Creating system user for znc"
useradd znc -m -s /bin/bash
passwd znc -l >> ${log} 2>&1
echo_progress_done

if [[ $DISTRO == Debian ]]; then
    #shellcheck source=sources/functions/backports
    . /etc/swizzin/sources/functions/backports
    check_debian_backports
    set_packages_to_backports znc
    apt_update
fi
apt_install znc
#sudo -u znc crontab -l | echo -e "*/10 * * * * /usr/bin/znc >/dev/null 2>&1\n@reboot /usr/bin/znc >/dev/null 2>&1" | crontab -u znc - > /dev/null 2>&1
echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/znc.service << ZNC
[Unit]
Description=ZNC, an advanced IRC bouncer
After=network-online.target
     
[Service]
ExecStart=/usr/bin/znc -f
User=znc
Restart=always
     
[Install]
WantedBy=multi-user.target
ZNC
systemctl enable -q znc
echo_progress_done

if [[ -t 0 ]]; then
    echo_warn "ZNC configuration will now run. Please answer the following prompts"
    sleep 5
    sudo -H -u znc znc --makeconf
    killall -u znc znc > /dev/null 2>&1
    sleep 1
else
    # Nobody to answer --makeconf (unattended install, box run by a script): without a config ZNC does not start.
    # Write one: an SSL listener on a free port, the master as admin with the master password (salted SHA-256)
    echo_progress_start "Writing ZNC configuration"
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    znc_port=${ZNC_PORT:-$(port 10001 32001)}
    znc_user=$(_get_master_username)
    znc_salt=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c20)
    znc_hash=$({ _get_user_password "$znc_user" | tr -d '\n' && printf '%s' "$znc_salt"; } | sha256sum | cut -d' ' -f1)
    # the private key in znc.pem and the password hash: for the znc user only
    (umask 077 && sudo -H -u znc mkdir -p /home/znc/.znc/configs && sudo -H -u znc znc --makepem >> "$log" 2>&1)
    (umask 077 && sudo -H -u znc tee /home/znc/.znc/configs/znc.conf > /dev/null) << ZNCCONF
Version = $(znc --version | grep -oP '^ZNC \K[0-9]+\.[0-9]+')
LoadModule = webadmin
<Listener l>
    Port = ${znc_port}
    IPv4 = true
    IPv6 = true
    SSL = true
</Listener>
<User ${znc_user}>
    Admin = true
    Nick = ${znc_user}
    AltNick = ${znc_user}_
    Ident = ${znc_user}
    LoadModule = chansaver
    LoadModule = controlpanel
    <Pass password>
        Method = SHA256
        Hash = ${znc_hash}
        Salt = ${znc_salt}
    </Pass>
</User>
ZNCCONF
    echo_progress_done "ZNC listens on port ${znc_port} (SSL), log in as ${znc_user} with the master password"
fi

# Check for LE cert, and copy it if available.
if [[ -f /install/nginx.lock ]]; then
    le_znc_hook
fi

systemctl start znc
echo "$(grep Port /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" > /install/.znc.lock
echo "$(grep SSL /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" >> /install/.znc.lock
echo_success "ZNC installed"
