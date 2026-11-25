#!/bin/bash
# Simple tool to grab the latest release of emby

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
latest=$(github_latest_version MediaBrowser/Emby.Releases)
current=$(dpkg-query -f='${Version}' --show emby-server)
if [[ -z $latest ]]; then
    echo_error "Failed to query GitHub for the latest Emby release"
    exit 1
fi

if dpkg --compare-versions ${latest} gt ${current}; then
    echo_info "Upgrading Emby"
    releases=https://github.com/MediaBrowser/Emby.Releases/releases/download
    # The installed release is fetched first, so a failed upgrade can always be rolled back to it
    wget -O /tmp/emby-previous.dpkg ${releases}/${current}/emby-server-deb_${current}_$(_os_arch).deb >> $log 2>&1 || {
        echo_error "Could not download the installed Emby ${current} to roll back to, not upgrading. To upgrade without a rollback, install the latest .deb by hand with dpkg -i"
        rm -f /tmp/emby-previous.dpkg
        exit 1
    }
    wget -O /tmp/emby.dpkg ${releases}/${latest}/emby-server-deb_${latest}_$(_os_arch).deb >> $log 2>&1 || {
        echo_error "Emby failed to download"
        rm -f /tmp/emby.dpkg /tmp/emby-previous.dpkg
        exit 1
    }
    was_active=$(systemctl is-active emby-server)
    if ! dpkg -i --force-confdef --force-confold /tmp/emby.dpkg >> ${log} 2>&1; then
        if [[ $(dpkg-query -f='${db:Status-Status} ${Version}' -W emby-server) == "installed ${current}" ]]; then
            # dpkg changed nothing (busy lock, preinst failure it already undid)
            echo_error "Emby ${latest} failed to install, ${current} is unchanged, see ${log}"
        else
            echo_warn "Emby ${latest} failed to install, rolling back to ${current}"
            if ! dpkg -i --force-confdef --force-confold /tmp/emby-previous.dpkg >> ${log} 2>&1; then
                echo_error "Emby could not be upgraded nor restored to ${current}, see ${log}"
            elif [[ $was_active == active ]] && ! { sleep 15 && systemctl is-active -q emby-server; }; then
                # the new version may already have migrated Emby's database, which the old one cannot read
                echo_error "Emby ${current} was restored but does not start, see journalctl -u emby-server"
            else
                echo_error "Emby could not be upgraded, ${current} was restored"
            fi
        fi
        rm -f /tmp/emby.dpkg /tmp/emby-previous.dpkg
        exit 1
    fi
    rm -f /tmp/emby.dpkg /tmp/emby-previous.dpkg
else
    echo_info "Emby is already up to date!"
fi
