#!/bin/bash
# Syncthing's "stable" apt channel stopped at v1: move to "stable-v2", with a unit v2 can start.
# Syncthing itself moves to v2 on `box upgrade syncthing`, not here

[[ -f /install/.syncthing.lock ]] || exit 0
#shellcheck source=sources/functions/syncthing
. /etc/swizzin/sources/functions/syncthing

if ! grep -qs 'syncthing stable-v2' "$syncthing_list" || [[ ! -f $syncthing_pref ]]; then
    echo_progress_start "Moving Syncthing to its v2 apt channel"
    if syncthing_apt_source; then
        echo_progress_done
    else
        echo_warn "Syncthing stays on its v1 apt channel. Run \`box update\` again later to retry"
    fi
fi

if grep -qs -- ' -no-browser' "$syncthing_unit"; then
    echo_progress_start "Updating the Syncthing service for v2"
    syncthing_write_unit
    # v1 also starts with the new options: restart the running ones so a mistake shows now
    systemctl try-restart 'syncthing@*' >> "$log" 2>&1
    echo_progress_done
fi
