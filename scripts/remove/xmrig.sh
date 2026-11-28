#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

user=$(cut -d: -f1 < /root/.master.info)
remove_unit xmrig
su - ${user} -c "screen -X -S xmrig quit" > /dev/null 2>&1
rm -rf /home/${user}/.xmrig
rm -rf /usr/local/bin/xmrig
rm -rf /install/.xmrig.lock
