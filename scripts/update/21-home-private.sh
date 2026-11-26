#!/bin/bash
# The clients' configs in the homes (qBittorrent and Transmission password hashes, *arr API keys, flood's
# users and secret) were readable by www-data and by the media servers in the master's group.
# A few chmods per user, so it runs at every update and also closes what an app installed since opened.

errors=$(mktemp)
for u in $(_get_user_list); do
    id -u "$u" > /dev/null 2>&1 || continue
    # a missing home, a link or a root-owned home (SFTP chroot) is left as it is
    [[ -d /home/$u && ! -L /home/$u && $(stat -c %U "/home/$u") == "$u" ]] || continue
    out=$(_home_private "$u" 2> "$errors")
    if [[ -n $out ]]; then
        echo_info "Closed to everyone but $u in /home/$u: ${out//$'\n'/, }"
    fi
    if [[ -s $errors ]]; then
        echo_warn "Some configs in /home/$u stay readable by others: $(tr '\n' ' ' < "$errors")"
    fi
done
rm -f "$errors"
