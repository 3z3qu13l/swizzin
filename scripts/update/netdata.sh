#!/bin/bash
# The nginx setup could not restrict netdata to 127.0.0.1 with recent netdata.conf files: it answered the network,
# without a password, on port 19999. The nginx script now can.

[[ -f /install/.netdata.lock && -f /install/.nginx.lock ]] || exit 0
grep -qsE '^\s*bind to\s*=\s*127\.0\.0\.1\s*$' /etc/netdata/netdata.conf /opt/netdata/etc/netdata/netdata.conf && exit 0

echo_progress_start "Restricting netdata to nginx (127.0.0.1)"
# a failure here must not stop the updaters that come after
if bash /usr/local/bin/swizzin/nginx/netdata.sh; then echo_progress_done; else echo_progress_done "Not done"; fi
