#!/bin/bash
# Syncthing's "stable" apt channel stopped at v1: move to "stable-v2", with a unit v2 can start.
# From then on, apt installs v2 with the next upgrade, box upgrade syncthing or apt upgrade

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
    if ! grep -qx "$syncthing_v1_exec" "$syncthing_unit"; then
        echo_warn "${syncthing_unit} was edited by hand: Syncthing v2 needs double-dash options (syncthing serve --no-browser --no-restart), convert yours before upgrading"
    # "serve" came with Syncthing 1.15: an older one keeps its unit until box upgrade syncthing
    elif /usr/bin/syncthing serve --help > /dev/null 2>&1; then
        echo_progress_start "Updating the Syncthing service for v2"
        syncthing_write_unit
        # the running v1 also starts with the new options: restart it so a mistake shows now
        systemctl try-restart 'syncthing@*' >> "$log" 2>&1
        echo_progress_done
    fi
fi
