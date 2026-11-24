#!/bin/bash
# Runs before any other update script: on a server upgraded to trixie in place, the signed-by
# Ombi source makes every apt update fail, which would stop box update before ombi.sh is reached.
if [[ -f /install/.ombi.lock ]] && [[ $(_os_codename) == "trixie" ]] &&
    { grep -q signed-by /etc/apt/sources.list.d/ombi.list || [[ ! -f /etc/apt/preferences.d/ombi ]]; }; then
    echo_progress_start "Switching ombi apt source for Debian trixie"
    #shellcheck source=sources/functions/ombi
    . /etc/swizzin/sources/functions/ombi
    ombi_apt_source
    echo_progress_done
fi
