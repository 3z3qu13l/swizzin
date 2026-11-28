#!/bin/bash

if [[ ! -f /install/.filebrowser.lock ]]; then
    echo_error "Filebrowser does not appear to be installed!"
    exit 1
fi

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
username=$(_get_master_username)

case "$(_os_arch)" in
    "amd64" | "arm64")
        fb_arch="$(_os_arch)"
        ;;
    "armhf")
        fb_arch="(uname -r)"
        ;;
    *)
        echo_error "$(_os_arch) not supported by filebrowser"
        exit 1
        ;;
esac

dlurl=$(github_release_asset filebrowser/filebrowser "linux-${fb_arch}.*\.tar\.gz$") || {
    echo_error "Could not find the latest File Browser release for ${fb_arch}"
    exit 1
}

mv /home/${username}/bin/filebrowser /home/${username}/bin/filebrowser.bak
wget -O "/home/${username}/filebrowser.tar.gz" "$dlurl" >> $log 2>&1 || {
    mv "/home/${username}/bin/filebrowser.bak" "/home/${username}/bin/filebrowser"
    echo_error "Failed to download archive"
    exit 1
}
tar -xvzf "/home/${username}/filebrowser.tar.gz" --exclude LICENSE --exclude README.md -C "/home/${username}/bin" >> $log 2>&1 || {
    mv "/home/${username}/bin/filebrowser.bak" "/home/${username}/bin/filebrowser"
    echo_error "Failed to extract downloaded file"
    exit 1
}

rm -f "/home/${username}/filebrowser.tar.gz"
chown $username: "/home/${username}/bin/filebrowser"
chmod 700 "/home/${username}/bin/filebrowser"
if [[ -f /home/${username}/bin/filebrowser ]]; then
    rm /home/${username}/bin/filebrowser.bak
else
    echo_error "Something went wrong during the upgrade, reverting changes"
    mv /home/${username}/bin/filebrowser.bak /home/${username}/bin/filebrowser
fi
systemctl try-restart filebrowser
