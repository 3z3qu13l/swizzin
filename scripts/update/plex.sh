#!/bin/bash

# the old endpoint stays until the new key is in place, so a failed download is tried again next update
if [[ -f /etc/apt/sources.list.d/plexmediaserver.list ]] && apt_key_install https://downloads.plex.tv/plex-keys/PlexSign.v2.key /usr/share/keyrings/plexmediaserver.v2.gpg; then
    echo_info "Updating plex apt repo endpoint"
    rm /etc/apt/sources.list.d/plexmediaserver.list
    # shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    rm_if_exists /usr/share/keyrings/plex-archive-keyring.gpg
    rm_if_exists /usr/share/keyrings/plexmediaserver.gpg
    echo "deb [signed-by=/usr/share/keyrings/plexmediaserver.v2.gpg] https://repo.plex.tv/deb/ public main" > /etc/apt/sources.list.d/plex.list
    apt_update
fi
