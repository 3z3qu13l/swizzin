#!/bin/bash
# Airsonic remover. Airsonic is archived upstream and no longer installed: this cleans up older servers.

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

systemctl disable --now airsonic -q
deluser airsonic --system --quiet
rm -rf /opt/airsonic

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/airsonic.conf
    systemctl reload nginx
fi

# Java 8 was there for Airsonic only
java8=()
for p in temurin-8-jdk adoptopenjdk-8-hotspot openjdk-8-jre openjdk-8-jre-headless; do
    dpkg -s "$p" > /dev/null 2>&1 && java8+=("$p")
done
((${#java8[@]})) && apt_remove --purge "${java8[@]}"
# adoptopenjdk.jfrog.io is gone: its source makes every apt update fail
rm -f /etc/apt/sources.list.d/adoptopenjdk.list /usr/share/keyrings/adoptopenjdk-archive-keyring.gpg
if ! dpkg -l 'temurin-*' 2> /dev/null | grep -q '^ii'; then
    rm -f /etc/apt/sources.list.d/temurin.list /usr/share/keyrings/temurin-archive-keyring.gpg
fi

rm /install/.airsonic.lock
