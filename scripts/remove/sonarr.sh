#!/bin/bash

if ! user="$(swizdb get sonarr/owner)"; then
    user=$(grep User= /etc/systemd/system/sonarr.service | cut -d= -f2)
fi
ask "Would you like to purge the configuration?" Y && purge=true

systemctl disable --now -q sonarr
rm -f /etc/systemd/system/sonarr.service
systemctl daemon-reload -q
rm -rf /opt/Sonarr
[[ $purge == true ]] && rm -rf "/home/${user}/.config/Sonarr"
# left by Sonarr v3 installs on mono; box's apt_autoremove removes them once marked auto
mono=(mono-runtime ca-certificates-mono libmono-system-net-http4.0-cil libmono-corlib4.5-cil
    libmono-microsoft-csharp4.0-cil libmono-posix4.0-cil libmono-system-componentmodel-dataannotations4.0-cil
    libmono-system-configuration-install4.0-cil libmono-system-configuration4.0-cil libmono-system-core4.0-cil
    libmono-system-data-datasetextensions4.0-cil libmono-system-data4.0-cil libmono-system-identitymodel4.0-cil
    libmono-system-io-compression4.0-cil libmono-system-numerics4.0-cil libmono-system-runtime-serialization4.0-cil
    libmono-system-security4.0-cil libmono-system-servicemodel4.0a-cil libmono-system-serviceprocess4.0-cil
    libmono-system-transactions4.0-cil libmono-system-web4.0-cil libmono-system-xml-linq4.0-cil
    libmono-system-xml4.0-cil libmono-system4.0-cil)
# old Radarr, Lidarr or Jackett may still run on mono, and apt does not know they need it
if ! grep -qs "ExecStart=/usr/bin/mono" /etc/systemd/system/*.service; then
    # only the installed ones: Sonarr v4 servers have none, and the mono apt source may be gone
    mapfile -t installed < <(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' "${mono[@]}" 2> /dev/null | awk '/^ii/ {print $2}')
    [[ ${#installed[@]} -gt 0 ]] && apt-mark auto "${installed[@]}" >> "$log" 2>&1
    rm -f /etc/apt/sources.list.d/mono-xamarin.list*
fi

if [[ -f /install/.nginx.lock ]]; then
    rm -f /etc/nginx/apps/sonarr.conf
    systemctl reload nginx >> "$log" 2>&1
fi

swizdb clear sonarr/owner
rm /install/.sonarr.lock
