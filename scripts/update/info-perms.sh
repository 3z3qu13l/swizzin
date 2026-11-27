#!/bin/bash
# The password files in /root (and Organizr's keys) were written with the default umask, often 644: only
# /root's own mode kept them private, and a backup or a copy of /root does not keep it
# shellcheck disable=SC2154 # log is exported by globals.sh
find /root -maxdepth 1 -type f \( -name '*.info' -o -name .organizr \) -user root -perm /077 -exec chmod 600 {} + -print >> "$log" 2>&1
