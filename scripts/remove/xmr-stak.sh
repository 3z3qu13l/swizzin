#!/bin/bash
# xmr-stak(-cpu) removal

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user=$(cut -d: -f1 < /root/.master.info)
remove_unit xmr
su - ${user} -c "screen -X -S xmr quit" > /dev/null 2>&1
rm -rf /home/${user}/.xmr
rm -rf /usr/local/bin/xmr-stak-cpu
rm -rf /usr/local/bin/xmr-stak
rm -rf /install/.xmr-stak.lock
rm -rf /install/.xmr-stak-cpu.lock
