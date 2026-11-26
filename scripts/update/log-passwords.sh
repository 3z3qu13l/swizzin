#!/bin/bash
# Passwords that reached the log: box logged its whole command line (`box adduser|chpasswd <user> <password>`),
# one argument per line after "Args after cleanup" with --test, and the transmission nginx script printed each
# settings.json there
# shellcheck disable=SC2154 # log is exported by globals.sh

box='(>>>> `box (--test )?(adduser|chpasswd) (--test )?[^ ]+) .*`'
rpc='^(\s*"rpc-password": ).*'
args='Args after cleanup: (adduser|chpasswd)$'
hidden='<password hidden>'
[[ -f $log ]] || exit 0
# -a: a log years old holds binary bytes, grep would then stop printing lines
if grep -aE "$box|$rpc" "$log" | grep -aqvF "$hidden" || grep -aqE "$args" "$log"; then
    # the line after the user name is the password unless it is the next log line, which starts with its date
    if sed -i --follow-symlinks -E -e "/$hidden/! s/$box/\1 $hidden\`/" -e "/$hidden/! s/$rpc/\1\"$hidden\",/" \
        -e "/$args/ { s//Args after cleanup: \1 (checked)/; n; n; /^(\x1b\[[0-9;]*m)?\[[A-Z][a-z]{2} /! s/.*/$hidden/; }" "$log"; then
        echo_info "Passwords removed from $log, copies of it made before still hold them"
    else
        echo_warn "Could not remove the passwords from $log"
    fi
fi
