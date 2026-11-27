#!/bin/bash
# Ombi installer
# Swizzin gplv3 and all that

#shellcheck source=sources/functions/ombi
. /etc/swizzin/sources/functions/ombi

function _sources() {
    echo_progress_start "Installing ombi apt sources"
    ombi_apt_source || exit 1
    echo_progress_done "Sources installed"
    apt_update
}

function _dependencies() {
    echo_progress_start "Installing Ombi runtime dependencies"
    icu_pkg="$(apt-cache search '^libicu[0-9]+$' | awk '{print $1}' | sort -Vr | sed -n '1p')"
    if [[ -n "${icu_pkg}" ]]; then
        apt_install "${icu_pkg}"
    else
        # Fallback for older or unusual apt metadata where versioned runtime package is not listed.
        apt_install libicu-dev
    fi
    echo_progress_done "Dependencies installed"
}

function _install() {
    if ombi_from_github; then
        ombi_github_service
        ombi_github_upgrade || exit 1
    else
        _sources
        ombi_index_link
        apt_install ombi
    fi

    mkdir -p /etc/systemd/system/ombi.service.d
    cat > /etc/systemd/system/ombi.service.d/override.conf << CONF
[Service]
ExecStart=
ExecStart=/opt/Ombi/Ombi --host http://0.0.0.0:3000 --storage /etc/Ombi
CONF
    systemctl daemon-reload
    systemctl enable --now -q ombi
}

function _nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /usr/local/bin/swizzin/nginx/ombi.sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "Ombi is accessible under port 3000"
    fi

}

_dependencies
_install
_nginx
touch /install/.ombi.lock
echo_success "Ombi installed"
echo_info "Please continue setting up your administrator user through the browser"
