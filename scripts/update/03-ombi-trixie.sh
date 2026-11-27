#!/bin/bash
# Runs before any other update script. On Debian 13 and later apt cannot verify Ombi's repository (its key is
# bound with SHA1): an Ombi installed from it moves to its GitHub release, its data in /etc/Ombi kept.
[[ -f /install/.ombi.lock ]] || exit 0
#shellcheck source=sources/functions/ombi
. /etc/swizzin/sources/functions/ombi
ombi_from_github || exit 0
dpkg -s ombi > /dev/null 2>&1 || exit 0
echo_info "Moving Ombi from its apt repository to its GitHub release"
if ! ombi_migrate_to_github; then
    echo_warn "Ombi stays on its apt package for now, run box update again later"
fi
exit 0
