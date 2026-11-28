#! /bin/bash
# Netdata uninstaller for swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ -f /usr/libexec/netdata/netdata-uninstaller.sh ]]; then
    /usr/libexec/netdata/netdata-uninstaller.sh --yes --env /etc/netdata/.environment -f >> $log 2>&1 || {
        echo_error "Netdata remover failed!"
        exit 1
    }
else
    bash <(curl -Ssf https://get.netdata.cloud/kickstart.sh 2>> ${log} || { echo "exit 1"; }) --uninstall --non-interactive >> $log 2>&1 || {
        echo_error "Netdata remover failed!"
        exit 1
    }
fi
rm /etc/nginx/apps/netdata.conf
nginx_reload
rm -rf /install/.netdata.lock
