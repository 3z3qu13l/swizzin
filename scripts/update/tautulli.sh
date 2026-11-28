#!/bin/bash

if [[ -f /install/.tautulli.lock ]]; then
    if [[ ! -d /opt/tautulli/.git ]]; then
        echo_progress_start "Updating Tautulli to use git"
        systemctl stop tautulli
        chown -R tautulli:nogroup /opt/tautulli
        sudo -u tautulli git -C /opt/tautulli init
        sudo -u tautulli git -C /opt/tautulli remote add origin https://github.com/Tautulli/Tautulli.git
        sudo -u tautulli git -C /opt/tautulli fetch origin
        sudo -u tautulli git -C /opt/tautulli reset --hard origin/master
        systemctl start tautulli
        echo_progress_done
    fi

    if [[ ! -d /opt/.venv/tautulli ]]; then
        echo_progress_start "Migrating Tautulli to venv"
        #shellcheck source=sources/functions/pyenv
        . /etc/swizzin/sources/functions/pyenv
        systempy3_ver=$(get_candidate_version python3)

        if dpkg --compare-versions ${systempy3_ver} lt 3.8.0 || dpkg --compare-versions ${systempy3_ver} ge 3.12.0; then
            PYENV=True
            echo_info "pyenv will be used for the Tautulli venv. You may need to restart tautulli manually!"
        else
            LIST='python3-dev python3-setuptools python3-pip python3-venv'
            apt_install $LIST
        fi

        case ${PYENV} in
            True)
                pyenv_install
                pyenv_install_version 3.11.3
                pyenv_create_venv 3.11.3 /opt/.venv/tautulli
                chown -R tautulli: /opt/.venv/tautulli
                ;;
            *)
                python3_venv tautulli tautulli
                ;;
        esac
        sed -i 's|ExecStart=/usr|ExecStart=/opt/.venv/tautulli|g' /etc/systemd/system/tautulli.service
        systemctl daemon-reload
        if systemctl is-active tautulli > /dev/null 2>&1; then
            systemctl restart tautulli
        fi
        echo_progress_done
    fi
fi
