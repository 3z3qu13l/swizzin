#!/bin/bash
# Runs before any other update script: an apt upgrade to ombi 4.53 leaves the package half-configured
# (see ombi_index_link), and every later apt_install would then fail and stop box update.
if [[ $(dpkg-query -W -f='${db:Status-Status}' ombi 2> /dev/null) == half-configured ]]; then
    echo_progress_start "Finishing the ombi package configuration"
    #shellcheck source=sources/functions/ombi
    . /etc/swizzin/sources/functions/ombi
    ombi_index_link
    if dpkg --configure ombi >> $log 2>&1; then
        echo_progress_done
    else
        echo_warn "The ombi package is still half-configured, see $log"
    fi
fi
