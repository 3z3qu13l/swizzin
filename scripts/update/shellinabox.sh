#!/bin/bash
# On Ubuntu 26.04 the nginx setup could not restrict shellinabox to 127.0.0.1: its login prompt was open to the
# network on port 4200. The nginx script now does it with a systemd drop-in.

[[ -f /install/.shellinabox.lock && -f /install/.nginx.lock ]] || exit 0
[[ -f /etc/systemd/system/shellinabox.service.d/swizzin-nginx.conf ]] && exit 0

echo_progress_start "Restricting Shell in a Box to nginx (127.0.0.1)"
bash /usr/local/bin/swizzin/nginx/shellinabox.sh || exit 1
echo_progress_done
