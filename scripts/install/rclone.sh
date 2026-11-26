#!/bin/bash
#
# [Quick Box :: Install rclone]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   DedSec | d2dyno
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

# Install fuse
apt_install fuse

# user_allow_other is system wide: any user could then mount a FUSE filesystem readable by nginx (www-data)
# and use its fake links to get files www-data can read served to them.
case $RCLONE_ALLOW_OTHER in
    yes | no) ;;
    "")
        if whiptail --title "rclone: let other services read the mount" --defaultno --yesno "Do you want services such as Plex, Emby or Jellyfin to read the rclone mount (~/cloud)?\n\nWARNING: this sets user_allow_other in /etc/fuse.conf, which lets ANY user on this server mount a FUSE filesystem that other accounts can read. A user can use it to make the web server hand them files they should not see (other users' served folders, /etc/htpasswd).\n\nAnswer Yes only if every user of this server is trusted." 17 78; then
            RCLONE_ALLOW_OTHER=yes
        fi
        ;;
    *) echo_warn "RCLONE_ALLOW_OTHER must be yes or no; \"$RCLONE_ALLOW_OTHER\" is read as no" ;;
esac

echo_progress_start "Downloading and installing rclone"
# One-liner to check arch/os type, as well as download latest rclone for relevant system.
wget -q https://rclone.org/install.sh -O /tmp/rcloneinstall.sh >> $log 2>&1

# Make sure rclone downloads and installs without error before proceeding
if ! bash /tmp/rcloneinstall.sh; then
    echo_error "Rclone installer failed"
    exit 1
fi
echo_progress_done

allow_other=""
if [[ $RCLONE_ALLOW_OTHER == yes ]]; then
    allow_other=" --allow-other"
    if ! grep -qx 'user_allow_other' /etc/fuse.conf 2> /dev/null; then
        if grep -qx '#user_allow_other' /etc/fuse.conf 2> /dev/null; then
            sed -i 's/^#user_allow_other$/user_allow_other/' /etc/fuse.conf
        else
            [[ -s /etc/fuse.conf && -n $(tail -c1 /etc/fuse.conf) ]] && echo >> /etc/fuse.conf
            echo user_allow_other >> /etc/fuse.conf
        fi
        # remove only reverts the setting when swizzin turned it on, an admin's own (mergerfs...) is kept
        touch /install/.rclone-allow-other
    fi
    touch /install/.rclone-allow-other.warned
    echo_warn "user_allow_other is set in /etc/fuse.conf: every user can now mount FUSE filesystems other accounts read"
fi

echo_progress_start "Adding rclone multi-user mount service"
cat > /etc/systemd/system/rclone@.service << EOF
[Unit]
Description=rclonemount
After=network.target

[Service]
Type=simple
User=%i
Group=%i
ExecStartPre=-/bin/mkdir -p /home/%i/cloud/
ExecStart=/usr/bin/rclone mount gdrive: /home/%i/cloud/ \
  --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36' \
  --config /home/%i/.config/rclone/rclone.conf \
  --use-mmap \
  --dir-cache-time 1h \
  --timeout 30s \
  --umask 002${allow_other} \
  --poll-interval=1h \
  --vfs-cache-mode writes \
  --vfs-read-chunk-size 1M \
  --vfs-read-chunk-size-limit 64M \
  --tpslimit 10
ExecStop=/bin/fusermount -u /home/%i/cloud
Restart=on-failure
RestartSec=30
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target

EOF
echo_progress_done

touch /install/.rclone.lock
echo_success "Rclone installed"
echo_info "Setup Rclone remote named \"gdrive\" And run sudo systemctl start rclone@username.service"
if [[ -z $allow_other ]]; then
    echo_info "Only its own user can read the mount. To let Plex, Emby or Jellyfin read it (this stops the running mounts): box remove rclone && RCLONE_ALLOW_OTHER=yes box install rclone"
    if grep -qx 'user_allow_other' /etc/fuse.conf 2> /dev/null; then
        echo_warn "user_allow_other was already set in /etc/fuse.conf and is left as it is: every user can still mount FUSE filesystems other accounts read"
    fi
fi
