#!/bin/bash
# Runs before any apt install: older installers wrote an empty or HTML keyring next to their source list,
# and that one source makes every apt update fail, which stops box update and every other box command.
# shellcheck disable=SC1091
dist_id="$(source /etc/os-release && echo "$ID")"
while read -r app list keyring url <&3; do
    list=/etc/apt/sources.list.d/$list
    src=$list
    # A source disabled by an earlier run is retried on every box update
    [[ -f $src ]] || src=$list.disabled
    # A list without signed-by (ombi on trixie) does not use the keyring
    grep -qs "signed-by=$keyring" "$src" || continue
    if [[ $src == "$list" ]] && gpg --show-keys "$keyring" > /dev/null 2>&1; then continue; fi
    echo_progress_start "Repairing the $app apt signing key"
    if gpg --show-keys "$keyring" > /dev/null 2>&1 || apt_key_install "$url" "$keyring"; then
        [[ $src == "$list" ]] || mv "$src" "$list"
        echo_progress_done
    else
        [[ $src == "$list" ]] && mv "$list" "$list.disabled"
        echo_warn "The $app signing key could not be downloaded, its apt source stays disabled. Run \`box update\` again later to retry"
    fi
done 3<< EOF
Resilio-Sync btsync.list /usr/share/keyrings/btsync-archive-keyring.gpg https://linux-packages.resilio.com/resilio-sync/key.asc
Jellyfin jellyfin.list /usr/share/keyrings/jellyfin-archive-keyring.gpg https://repo.jellyfin.org/$dist_id/jellyfin_team.gpg.key
jfa-go jfa-go.list /usr/share/keyrings/jfa-go-archive-keyring.gpg https://apt.hrfee.dev/hrfee.pubkey.gpg
Plex plex.list /usr/share/keyrings/plexmediaserver.v2.gpg https://downloads.plex.tv/plex-keys/PlexSign.v2.key
Syncthing syncthing.list /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.txt
Webmin webmin.list /usr/share/keyrings/webmin-archive-keyring.gpg https://download.webmin.com/developers-key.asc
Ombi ombi.list /usr/share/keyrings/ombi-archive-keyring.gpg https://apt.ombi.app/pub.key
Temurin temurin.list /usr/share/keyrings/temurin-archive-keyring.gpg https://packages.adoptium.net/artifactory/api/gpg/key/public
NodeSource nodesource.list /etc/apt/keyrings/nodesource.gpg https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key
EOF
