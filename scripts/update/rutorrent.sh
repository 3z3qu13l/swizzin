#!/bin/bash

if [ -f /install/.rutorrent.lock ]; then
    #Update club-QuickBox with latest changes
    # club-QuickBox was briefly set as the server-wide default theme, each user now picks theirs
    sed -i 's/^\$defaultTheme = "club-QuickBox";/$defaultTheme = "";/' /srv/rutorrent/plugins/theme/conf.php 2> /dev/null

    cqbdir="/srv/rutorrent/plugins/theme/themes/club-QuickBox"
    #shellcheck source=sources/functions/rutorrent
    . /etc/swizzin/sources/functions/rutorrent
    #shellcheck source=sources/functions/php
    . /etc/swizzin/sources/functions/php
    #shellcheck source=sources/functions/rtorrent
    . /etc/swizzin/sources/functions/rtorrent
    # also after a PHP version change, and before the theme update below: git then runs as root on it
    if rutorrent_setup_needed; then
        echo_progress_start "Running ruTorrent's PHP under its own account, its code root's, each profile its user's"
        rutorrent_setup
        echo_progress_done
    fi

    # Only a clone of its own: a copy without .git would make git act on /srv/rutorrent itself.
    # No credential prompt if the repository went private.
    if [[ -d $cqbdir/.git ]]; then
        if timeout 60 env GIT_TERMINAL_PROMPT=0 git -C "$cqbdir" fetch >> $log 2>&1 &&
            [[ ! $(git -C "$cqbdir" rev-parse HEAD) == $(git -C "$cqbdir" rev-parse @{u}) ]]; then
            echo_progress_start "Updating rutorrent theme"
            git -C "$cqbdir" reset HEAD --hard >> $log 2>&1
            timeout 60 env GIT_TERMINAL_PROMPT=0 git -C "$cqbdir" pull >> $log 2>&1
            echo_progress_done
        fi
    elif [[ -d $cqbdir ]] && rm -rf "${cqbdir}.new" &&
        GIT_TERMINAL_PROMPT=0 timeout 60 git clone --depth 1 -b latest https://github.com/QuickBox/club-QuickBox.git "${cqbdir}.new" >> $log 2>&1; then
        # the copy kept by swizzin was installed while GitHub was unavailable, switch back to GitHub
        echo_progress_start "Updating rutorrent theme from GitHub"
        rm -rf "${cqbdir}.old" && mv "$cqbdir" "${cqbdir}.old" && mv "${cqbdir}.new" "$cqbdir" && rm -rf "${cqbdir}.old"
        echo_progress_done
    else
        rm -rf "${cqbdir}.new"
    fi

    reloadnginx=0

    if [[ -f /etc/nginx/apps/rutorrent.conf ]]; then
        #Fix fastcgi path_info being blank with certain circumstances under ruTorrent
        #Essentially, disabling the distro snippet and ignoring try_files
        if grep -q '/srv\$fastcgi_script_name' /etc/nginx/apps/rutorrent.conf; then
            sed -i 's|/srv$fastcgi_script_name|$request_filename|g' /etc/nginx/apps/rutorrent.conf
            echo_log_only "ruTorrent fastcgi_script_name triggers nginx reload"
            reloadnginx=1
        fi
        if grep -q 'alias' /etc/nginx/apps/rutorrent.conf; then
            sed -i '/alias/d' /etc/nginx/apps/rutorrent.conf
            echo_log_only "ruTorrent alias triggers nginx reload"
            reloadnginx=1
        fi
        if ! grep -q fastcgi_split_path_info /etc/nginx/apps/rutorrent.conf; then
            sed -i 's|include snippets/fastcgi-php.conf;|fastcgi_split_path_info ^(.+\\.php)(/.+)$;|g' /etc/nginx/apps/rutorrent.conf
            sed -i '/SCRIPT_FILENAME/a \ \ \ \ include fastcgi_params;\n    fastcgi_index index.php;' /etc/nginx/apps/rutorrent.conf
            echo_log_only "ruTorrent fastcgi_split_path_info triggers nginx reload"
            reloadnginx=1
        fi
        # not tried again on a conf it could not change, until that conf changes
        if ! grep -qF 'rutorrent/(conf|share)/' /etc/nginx/apps/rutorrent.conf &&
            [[ $(cat /install/.rutorrent.nginx-deny.failed 2> /dev/null) != "$(md5sum < /etc/nginx/apps/rutorrent.conf)" ]]; then
            echo_progress_start "Closing ruTorrent's profiles to the web"
            deny=$(mktemp)
            bak=$(mktemp)
            cp -p /etc/nginx/apps/rutorrent.conf "$bak"
            rutorrent_nginx_deny > "$deny"
            sed -i -E "0,/^\s*location\s+(\^~\s+)?\/rutorrent\/?\s*\{/{//r $deny
}" /etc/nginx/apps/rutorrent.conf
            if grep -qF 'rutorrent/(conf|share)/' /etc/nginx/apps/rutorrent.conf && nginx -t >> "$log" 2>&1; then
                reloadnginx=1
            else
                cat "$bak" > /etc/nginx/apps/rutorrent.conf
                md5sum < /etc/nginx/apps/rutorrent.conf > /install/.rutorrent.nginx-deny.failed
                echo_warn "Could not close /rutorrent/share and /rutorrent/conf in /etc/nginx/apps/rutorrent.conf, add the rule yourself: $(rutorrent_nginx_deny | tr -s ' \n' ' ')"
            fi
            rm -f "$deny" "$bak"
            echo_progress_done
        fi
        if rutorrent_nginx_media_needed; then
            echo_progress_start "Letting the file manager's media plugin play files"
            rutorrent_nginx_media && reloadnginx=1
            echo_progress_done
        fi
    fi

    # rtx's share plugin pinned until 2026 failed with ruTorrent 5.3, and its media plugin had no player
    fmplugs=0
    if rutorrent_fm_share_needed; then
        echo_progress_start "Installing swizzin's corrected file manager share plugin"
        rutorrent_fm_share_install
        fmplugs=1
        echo_progress_done
    elif [[ -d /srv/rutorrent/plugins/filemanager-share ]] && _rutorrent_v5; then
        rutorrent_fm_share_link
    fi
    if rutorrent_fm_media_needed; then
        echo_progress_start "Updating the file manager media plugin"
        rutorrent_fm_media_install
        fmplugs=1
        echo_progress_done
    fi
    rm -f /srv/fancyindex/stream.php
    # the opcache would keep serving the old files for minutes
    if [[ $fmplugs == 1 ]]; then /usr/local/bin/swizzin/php-fpm-cli -r 'opcache_reset();' >> "$log" 2>&1; fi

    if [[ -f /install/.flood.lock ]]; then
        users=($(cut -d: -f1 < /etc/htpasswd))
        for user in ${users[@]}; do
            if [[ ! -f /etc/nginx/apps/${user}.scgi.conf ]]; then
                reloadnginx=1
                cat > /etc/nginx/apps/${user}.scgi.conf << RUC
location /${user} {
    include scgi_params;
    scgi_pass unix:/var/run/${user}/.rtorrent.sock;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
RUC
            fi
        done
    fi

    if [[ $reloadnginx == 1 ]]; then
        echo_progress_start "Reloading nginx due to ruTorrent config updates"
        systemctl reload nginx
        echo_progress_done
    fi

    if [[ -f /install/.quota.lock ]] && { ! grep -q "/usr/bin/quota -wu" /srv/rutorrent/plugins/diskspace/action.php > /dev/null 2>&1 || [[ ! $(grep -ic cachedEcho::send /srv/rutorrent/plugins/diskspace/action.php) == 2 ]]; }; then
        echo_progress_start "Fixing quota ruTorrent plugin"
        #shellcheck source=sources/functions/rutorrent
        . /etc/swizzin/sources/functions/rutorrent
        rutorrent_fix_quota
        #shellcheck source=sources/functions/php
        . /etc/swizzin/sources/functions/php
        restart_php_fpm
        echo_progress_done
    fi

fi
