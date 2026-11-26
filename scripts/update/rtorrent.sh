#!/bin/bash
# shellcheck disable=SC2154 # log is exported by globals.sh
users=($(cut -d: -f1 < /etc/htpasswd))

#shellcheck source=sources/functions/rtorrent
. /etc/swizzin/sources/functions/rtorrent

for u in "${users[@]}"; do
    restart=0
    # Create tmpfiles.d for user if not exists
    if [[ ! -f /etc/tmpfiles.d/${u}.conf ]]; then
        echo_progress_start "Creating rtorrent tmpfiles.d for ${u}"
        echo "D /var/run/${u} 0750 ${u} ${u} -" >> /etc/tmpfiles.d/${u}.conf
        systemd-tmpfiles /etc/tmpfiles.d/${u}.conf --create
        echo_progress_done
    fi

    if [[ -f /home/${u}/.rtorrent.rc ]]; then
        if grep -q network.scgi.open_local /home/${u}/.rtorrent.rc; then
            :
        else
            sed -i 's/network.scgi.open_port.*/network.scgi.open_local = \/var\/run\/'${u}'\/.rtorrent.sock\nschedule = chmod_scgi_socket, 0, 0, "execute=chmod,\\"g+w,o=\\",\/var\/run\/'${u}'\/.rtorrent.sock"/' /home/${u}/.rtorrent.rc
            restart=1
        fi
        # rTorrent opened its session folder to everyone at each start, and chmodded an rpc.socket nothing uses.
        # Run as the user: a link they put there is never followed as root
        if runuser -u "${u}" -- grep -qE "^execute.nothrow = chmod,777,/home/${u}/(\.config/rpc\.socket|\.sessions)$" /home/${u}/.rtorrent.rc; then
            runuser -u "${u}" -- sed -i -E "/^execute.nothrow = chmod,777,\/home\/${u}\/(\.config\/rpc\.socket|\.sessions)$/d" /home/${u}/.rtorrent.rc 2>> "$log"
            runuser -u "${u}" -- chmod 755 /home/${u}/.sessions 2>> "$log"
        fi
        if ! grep -q /srv/rutorrent/php/initplugins.php /home/${u}/.rtorrent.rc; then
            sed -i 's:/var/www/rutorrent/php/initplugins.php:/srv/rutorrent/php/initplugins.php:g' /home/${u}/.rtorrent.rc
            restart=1
        fi
        # ruTorrent's Get .torrent reads the session folder, which rTorrent 0.16.25+ wrote 0600
        if rtorrent_installed_atleast 0.16.26 && ! grep -qE '^\s*session\.umask\.set\b' "/home/${u}/.rtorrent.rc"; then
            rtorrent_rc_convert "/home/${u}/.rtorrent.rc"
            grep -qE '^\s*session\.umask\.set\b' "/home/${u}/.rtorrent.rc" && restart=1
        fi
        if id -u "$u" > /dev/null 2>&1 && [[ -d /home/${u}/.sessions ]] &&
            ! getfacl -cp "/home/${u}/.sessions" 2> /dev/null | grep -q '^default:user:www-data:r'; then
            rtorrent_session_acl "$u" >> "$log" 2>&1 || echo_warn "Could not let ruTorrent read /home/${u}/.sessions, Get .torrent will fail"
        fi
    fi
    if [[ $restart = 1 ]]; then
        echo_progress_start "Restarting rtorrent for ${u} after config update"
        systemctl try-restart rtorrent@${u}
        echo_progress_done
    fi
    # Check if rTorrent using outdated/insecure scgi bind
    if [[ -f /etc/nginx/apps/${u}.scgi.conf ]]; then
        if grep -q "scgi_pass 127.0.0.1" /etc/nginx/apps/${u}.scgi.conf; then
            echo_progress_start "Updating nginx scgi config for ${u}"
            sed -i 's/scgi_pass.*/scgi_pass unix:\/var\/run\/'${u}'\/.rtorrent.sock;/g' /etc/nginx/apps/${u}.scgi.conf
            systemctl reload nginx
            echo_progress_done
        fi
    fi
    if [[ -f /srv/rutorrent/conf/users/${u}/config.php ]]; then
        if grep -q "scgi_host" /srv/rutorrent/conf/users/${u}/config.php; then
            :
        else
            echo_progress_start "Updating rutorrent config.php to use sockets for ${u}"
            sed -i 's/$scgi_port.*/$scgi_port = 0;\n$scgi_host = "unix:\/\/\/var\/run\/'${u}'\/.rtorrent.sock";/g' /srv/rutorrent/conf/users/${u}/config.php
            /usr/local/bin/swizzin/php-fpm-cli -r 'opcache_reset();'
            echo_progress_done
        fi
    fi
    if [[ -f /home/${u}/.flood/config.js ]]; then
        if grep -q "socket: false" /home/${u}/.flood/config.js; then
            echo_progress_start "Updating flood config.js to use sockets for ${u}"
            sed -i "s/socket: false/socket: true/g" /home/${u}/.flood/config.js
            sed -i "s/socketPath.*/socketPath: '\/var\/run\/${u}\/.rtorrent.sock'/g" /home/${u}/.flood/config.js
            systemctl try-restart flood@${u}
            echo_progress_done
        fi
    fi
done
