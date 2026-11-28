#!/bin/bash
# Runs before any app update: on a server upgraded to a new Debian release, the curl that rTorrent's
# installer built in /usr/local can link libraries that are gone, which breaks curl and cmake.
# No lock check: box upgrade curl builds it without rTorrent.
#shellcheck source=sources/functions/curl
. /etc/swizzin/sources/functions/curl
curl_local_remove_broken
