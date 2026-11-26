#!/bin/bash
# shellcheck disable=SC2154 # log is exported by globals.sh
# %I unescapes the instance name, so a user name with a dash (qa-user) became qa/user and the service never
# started. %i keeps the name as it is, and is the same for every other name, so running services are not restarted.
# Install scripts moved to %i in 2020; units written before that were never rewritten.

changed=()
for unit in flood nzbget jackett sickchill rtorrent deluged deluge-web irssi rclone; do
    f=/etc/systemd/system/${unit}@.service
    if [[ -f $f ]] && grep -q '%I' "$f"; then
        sed -i 's/%I/%i/g' "$f"
        changed+=("$unit")
    fi
done
[[ ${#changed[@]} -gt 0 ]] || exit 0

echo_progress_start "Fixing ${changed[*]} services for user names with a dash"
systemctl daemon-reload
for unit in "${changed[@]}"; do
    for u in $(_get_user_list); do
        [[ $u == *-* ]] || continue
        if [[ $(systemctl is-enabled "${unit}@${u}" 2> /dev/null) == enabled ]]; then
            systemctl reset-failed "${unit}@${u}" > /dev/null 2>&1
            systemctl start "${unit}@${u}" >> "$log" 2>&1 || echo_warn "Could not start ${unit}@${u}, see ${log}"
        fi
    done
done
echo_progress_done
