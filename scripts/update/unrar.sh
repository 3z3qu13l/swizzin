#!/bin/bash
# unrar used to be compiled on the architectures other than amd64 and arm64, then never updated.
# The package installs it as unrar-nonfree behind an alternative, which it does not create over a file
# shellcheck disable=SC2154 # log is exported by globals.sh

# a run stopped between the two moves below
if [[ ! -e /usr/bin/unrar && -f /usr/bin/unrar.swizzin-compiled ]]; then
    mv -f /usr/bin/unrar.swizzin-compiled /usr/bin/unrar
fi
[[ -f /usr/bin/unrar && ! -L /usr/bin/unrar ]] || exit 0
dpkg -S /usr/bin/unrar > /dev/null 2>&1 && exit 0
# no package for this architecture or repository: keep the compiled one without retrying at every update
apt-cache policy unrar 2> /dev/null | grep -q 'Candidate: [^(]' || exit 0

apt_install --ignore-errors unrar
if [[ -x /usr/bin/unrar-nonfree && ! -L /usr/bin/unrar ]]; then
    mv -f /usr/bin/unrar /usr/bin/unrar.swizzin-compiled
    update-alternatives --auto unrar >> "$log" 2>&1
    if [[ -L /usr/bin/unrar ]]; then
        rm -f /usr/bin/unrar.swizzin-compiled
    else
        mv -f /usr/bin/unrar.swizzin-compiled /usr/bin/unrar
    fi
fi
if [[ -L /usr/bin/unrar ]] || dpkg -S /usr/bin/unrar > /dev/null 2>&1; then
    echo_info "unrar now comes from the distribution's package"
else
    echo_warn "unrar could not be installed from the distribution, the compiled one is kept"
fi
