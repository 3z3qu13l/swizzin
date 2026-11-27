#!/bin/bash
if [[ ! -f /install/.ombi.lock ]]; then
    echo_error "Ombi not installed"
    exit 1
fi

#shellcheck source=sources/functions/ombi
. /etc/swizzin/sources/functions/ombi

if ombi_from_github; then
    if ombi_from_apt; then
        ombi_migrate_to_github || exit 1
    else
        ombi_github_upgrade || exit 1
    fi
    echo_success "Ombi upgraded"
    exit 0
fi

if ! grep -qs apt.ombi.app /etc/apt/sources.list.d/ombi.list; then

    echo_info "Upgrading ombi apt sources"
    ombi_apt_source || exit 1

    echo_progress_start "Backing up old Ombi config and database"
    mkdir -p /root/swizzin/backups/ombiv3
    cp -R /etc/Ombi /root/swizzin/backups/ombivx
    echo_progress_done "Backed up to /root/swizzin/backups/ombivx"

    apt_update
    ombi_index_link
    apt_install ombi
    if [[ -f /install/.nginx.lock ]]; then
        bash /etc/swizzin/scripts/nginx/ombi.sh
        systemctl reload nginx
    else
        echo_info "Ombi will be running on port 3000"
    fi
    echo_success "Ombi upgraded"
else
    apt_update
    ombi_index_link
    apt_install --only-upgrade ombi
    echo_success "Ombi upgraded"
fi
