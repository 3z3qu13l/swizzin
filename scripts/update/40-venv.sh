#!/bin/bash
user=$(_get_master_username)
# a venv of the user's own is not one of swizzin's app venvs
if [[ -d /home/${user}/.venv && ! -f /home/${user}/.venv/pyvenv.cfg ]]; then
    old=$(find "/home/${user}/.venv" -mindepth 1 -maxdepth 1 -type d -exec test -e {}/bin/python \; -printf '%f ')
    [[ -n $old ]] && echo_warn "Some apps still have their python venv in /home/${user}/.venv, which is no longer supported: back up their settings, then reinstall each with box remove <app> && box install <app> (${old% })"
fi

if [[ -d /opt/.venv ]]; then
    envs=($(find /opt/.venv/* -maxdepth 0 -type d))
    for venvpath in ${envs[@]}; do
        if ! grep -q "#\!${venvpath}/bin/python" ${venvpath}/bin/*; then
            echo_log_only "Replacing venv path in $venvpath"
            sed -i "s|#\!/.*/bin/python|#\!${venvpath}/bin/python|g" ${venvpath}/bin/*
        fi
    done
fi
