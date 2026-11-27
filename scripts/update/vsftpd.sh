#!/usr/bin/env bash
if [[ -f /install/.vsftpd.lock ]]; then
    #shellcheck source=sources/functions/letsencrypt
    . /etc/swizzin/sources/functions/letsencrypt
    le_vsftpd_hook
    # TLS was offered but not required: a client could still send the password in clear. A value set by hand is kept.
    if grep -q '^ssl_enable=YES$' /etc/vsftpd.conf && ! grep -q '^force_local_\(logins\|data\)_ssl=' /etc/vsftpd.conf; then
        echo_progress_start "Requiring TLS for FTP logins and transfers"
        sed -i 's|^ssl_enable=YES$|ssl_enable=YES\nforce_local_logins_ssl=YES\nforce_local_data_ssl=YES|' /etc/vsftpd.conf
        systemctl try-restart vsftpd
        echo_progress_done
        echo_info "FTP clients must now use explicit FTP over TLS (FTPES)"
    fi
fi
