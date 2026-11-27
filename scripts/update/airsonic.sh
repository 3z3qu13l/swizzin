#!/bin/bash
# Airsonic ran on /usr/bin/java, the newest Java, and does not start on Java 17 or newer: run it on the Java 8
# its installer adds

[[ -f /install/.airsonic.lock ]] || exit 0
unit=/etc/systemd/system/airsonic.service
grep -q '^ExecStart=/usr/bin/java' "$unit" 2> /dev/null || exit 0
#shellcheck source=sources/functions/java
. /etc/swizzin/sources/functions/java
java8=$(java8_bin)
if [[ -z $java8 ]]; then
    # not box remove airsonic: /opt/airsonic, which it deletes, also holds Airsonic's data
    echo_warn "Airsonic needs Java 8, which is not installed. Install it, then run box update again:
  bash -c '. /etc/swizzin/sources/globals.sh; . /etc/swizzin/sources/functions/java; install_java8'"
    exit 0
fi

echo_progress_start "Running Airsonic on Java 8"
sed -i "s|^ExecStart=/usr/bin/java|ExecStart=$java8|" "$unit"
systemctl daemon-reload
if systemctl -q is-enabled airsonic; then systemctl restart airsonic; fi
echo_progress_done
