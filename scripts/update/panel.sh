#! /bin/bash

if [[ -f /install/.panel.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    #shellcheck source=sources/functions/pyenv
    . /etc/swizzin/sources/functions/pyenv
    #shellcheck source=sources/functions/panel
    . /etc/swizzin/sources/functions/panel
    if [[ ! -d /opt/swizzin ]]; then
        echo_progress_start "swizzifying the panel"
        rm_if_exists "/srv/panel"
        rm_if_exists "/etc/cron.d/set_interface"
        rm_if_exists "/etc/nginx/apps/panel.conf"

        bash /usr/local/bin/swizzin/install/panel.sh

        echo_progress_done "Panel has been swizzified"
    else
        if [[ -d /opt/swizzin/venv ]]; then
            echo_progress_start "Moving swizzin venv to /opt/.venv"
            mkdir -p /opt/.venv
            python3 -m venv /opt/.venv/swizzin
            rm -rf /opt/swizzin/venv
            mv /opt/swizzin/swizzin/* /opt/swizzin/swizzin/.git /opt/swizzin
            rm_if_exists "/opt/swizzin/swizzin"
            sed -i 's|ExecStart=.*|ExecStart=/opt/.venv/swizzin/bin/python swizzin.py|g' /etc/systemd/system/panel.service
            sed -i 's|WorkingDirectory=.*|WorkingDirectory=/opt/swizzin|g' /etc/systemd/system/panel.service
            systemctl daemon-reload
            echo_progress_done "venv moved"
        fi

        pyminver=3.6.0
        pyenv_version=$(/opt/.venv/swizzin/bin/python3 --version | awk '{print $2}')

        if dpkg --compare-versions ${pyenv_version} lt ${pyminver}; then
            rm_if_exists "/opt/.venv/swizzin"
            pyenv_install
            pyenv_install_version 3.8.6
            pyenv_create_venv 3.8.6 /opt/.venv/swizzin
            chown -R swizzin: /opt/.venv/swizzin
        fi

        chown -R swizzin: /opt/swizzin
        chown -R swizzin: /opt/.venv/swizzin
        # Handles its own prints FYI
        bash /usr/local/bin/swizzin/upgrade/panel.sh

    fi

    # also rewrites the rules that sudo-rs rejects (Ubuntu 26.04)
    if ! grep -qs SYSDCMNDS /etc/sudoers.d/panel || ! visudo -cqf /etc/sudoers.d/panel > /dev/null 2>&1; then
        echo_progress_start "Updating panel sudoers"
        panel_sudoers && echo_progress_done
    fi

    if grep -q -E "swizzin.*/bin/sh" /etc/passwd; then
        echo_progress_start "Removing shell access for panel"
        usermod swizzin -s /usr/sbin/nologin
        echo_progress_done
    fi
fi
