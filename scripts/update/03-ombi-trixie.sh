#!/bin/bash
# Runs before any other update script. On Debian 13 and later apt cannot verify Ombi's repository (its key is
# bound with SHA1): an Ombi installed from it moves to its GitHub release, its data in /etc/Ombi kept.
[[ -f /install/.ombi.lock ]] || exit 0
#shellcheck source=sources/functions/ombi
. /etc/swizzin/sources/functions/ombi
ombi_from_github || exit 0
# whatever happens next: a signed-by source would make every apt update fail, and stop box update
ombi_drop_apt_source
if ombi_from_apt; then
    echo_info "Moving Ombi from its apt repository to its GitHub release"
    if ! ombi_migrate_to_github; then
        if ombi_from_apt; then
            echo_warn "Ombi stays on its apt package for now, run box update again later"
        else
            echo_warn "Ombi is stopped: run box upgrade ombi"
        fi
    fi
elif [[ $(dpkg-query -W -f='${db:Status-Status}' ombi 2> /dev/null) == config-files ]]; then
    # a package only removed keeps the purge that deletes /etc/Ombi: done now, with the data set aside
    systemctl stop ombi
    ombi_purge_package
    systemctl enable -q ombi >> "$log" 2>&1
    systemctl start ombi
fi
exit 0
