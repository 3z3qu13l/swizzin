#!/bin/bash
# Web login files used to be readable by every account on the server
[[ -f /etc/htpasswd ]] || exit 0

function is_closed() {
    local acl
    acl=$(getfacl -cp "$1" 2> /dev/null) || return 1
    [[ $(stat -c %a:%U "$1") == 640:root ]] && grep -qx 'user:www-data:r--' <<< "$acl" || return 1
    if [[ $1 == /etc/htpasswd && -f /install/.panel.lock ]]; then
        grep -qx 'user:swizzin:r--' <<< "$acl"
    fi
}

shopt -s nullglob
files=(/etc/htpasswd /etc/htpasswd.d/htpasswd.*)
shopt -u nullglob

for f in "${files[@]}"; do
    if ! is_closed "$f"; then
        echo_progress_start "Closing the web login files to other accounts"
        _htpasswd_perms "${files[@]}"
        echo_progress_done
        break
    fi
done
