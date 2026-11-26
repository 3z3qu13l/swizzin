#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
# loaded instances, plus enabled ones that are not loaded
for unit in $( (
    systemctl list-units 'rclone@*' --all --plain --no-legend | awk '{print $1}'
    find /etc/systemd/system -path '*.wants/rclone@*.service' -printf '%f\n'
) | sort -u); do
    systemctl disable --now "$unit"
done
rm_if_exists /usr/bin/rclone
rm_if_exists /usr/sbin/rclone
rm_if_exists /etc/systemd/system/rclone@.service
rm_if_exists /usr/local/share/man/man1/rclone.1
if [[ -f /install/.rclone-allow-other ]]; then
    sed -i 's/^user_allow_other$/#user_allow_other/' /etc/fuse.conf
elif grep -qx 'user_allow_other' /etc/fuse.conf 2> /dev/null; then
    echo_warn "user_allow_other stays set in /etc/fuse.conf: it lets any user mount FUSE filesystems other accounts read. An older rclone install may have set it; comment it out unless another FUSE tool (mergerfs...) needs it"
fi
rm -f /install/.rclone.lock /install/.rclone-allow-other /install/.rclone-allow-other.warned
