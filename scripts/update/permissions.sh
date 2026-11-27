#!/bin/bash

# Only swizzin's users: another account's home (an admin's 700) is not ours to open to its group.
# A root-owned home is an SFTP chroot, left as it is
for u in $(_get_user_list); do
    if [[ -d /home/$u && ! -L /home/$u && $(stat -c %U "/home/$u") == "$u" ]]; then chmod 750 "/home/$u"; fi
done
master=$(cut -d: -f1 < /root/.master.info)

if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.profile; then
    sed -i '/export PATH=$PATH:\/usr\/local\/bin\/swizzin/d' /root/.profile
fi

if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.bashrc; then
    :
else
    echo 'export PATH=$PATH:/usr/local/bin/swizzin' >> /root/.bashrc
fi

# Ensure .config dir is correctly owned
if [[ -e /home/${master}/.config ]]; then
    # TODO do for all users maybe?
    perm=$(stat -c '%U' /home/"${master}"/.config)
    if [[ ! $perm == ${master} ]]; then
        echo_progress_start "Fixing ownership of master's .config dir"
        chown -R "${master}": /home/"${master}"/.config
        echo_progress_done
    fi
fi
