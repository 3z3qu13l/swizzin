#!/bin/bash
# rclone installs before this change turned on user_allow_other in /etc/fuse.conf for every server. Turning it off
# would cut Plex, Emby or Jellyfin from the mounts, so existing servers keep it and are warned once.

[[ -f /install/.rclone.lock ]] || exit 0
[[ -f /install/.rclone-allow-other.warned ]] && exit 0
grep -qx 'user_allow_other' /etc/fuse.conf 2> /dev/null || exit 0
grep -q -- '--allow-other' /etc/systemd/system/rclone@.service 2> /dev/null || exit 0

echo_warn "rclone: user_allow_other is set in /etc/fuse.conf. It lets ANY user mount a FUSE filesystem other accounts can read, and use it to make the web server hand them files they should not see (other users' served folders, /etc/htpasswd).
It is only needed if another service (Plex, Emby, Jellyfin) reads the rclone mounts. If none does, turn it off with:
  sed -i 's/ --allow-other//' /etc/systemd/system/rclone@.service
  sed -i 's/^user_allow_other\$/#user_allow_other/' /etc/fuse.conf
  systemctl daemon-reload
  then for each user with a mount: systemctl restart rclone@<user>
This warning is not shown again."
touch /install/.rclone-allow-other.warned
