#!/bin/bash

users=($(cut -d: -f1 < /etc/htpasswd))
master=$(cut -d: -f1 < /root/.master.info)
distribution=$(lsb_release -is)

if [[ ! -f /etc/sudoers.d/env_keep ]] && [[ $distribution = "Ubuntu" ]]; then
    echo_info "Adding env_keep to sudoers"
    echo 'Defaults  env_keep -="HOME"' > /etc/sudoers.d/env_keep
fi

# TODO this should probably skip the master?
for u in "${users[@]}"; do
    if [[ $u = "$master" ]]; then continue; fi
    USER=${u^^}
    if grep -q ${USER}CMNDS /etc/sudoers.d/$u; then
        echo_info "Fixing sudo permissions for $u"
        sed -i "s/${USER}CMNDS/${USER}CMDS/g" /etc/sudoers.d/$u
    fi
done

for u in "${users[@]}"; do
    if [[ $u = "$master" ]]; then continue; fi
    USER=${u^^}
    if grep -q flood /etc/sudoers.d/$u; then
        :
    else
        echo_info "Adding flood sudo permissions for $u"
        sed -i "s/${USER}CMDS = /${USER}CMDS = \/bin\/systemctl stop flood@${user}, \/bin\/systemctl restart flood@${user}, \/bin\/systemctl start flood@${user}, /g" /etc/sudoers.d/$u
    fi
done

# A user name with a dash gave an alias sudo rejects, which stops sudo for every account.
# Every per-user rule swizzin wrote is checked, also for accounts no longer in /etc/htpasswd
for f in /etc/sudoers.d/*; do
    u=${f##*/}
    [[ $u == *.* ]] && continue
    grep -qF "/usr/local/bin/swizzin/box chpasswd ${u}" "$f" || continue
    if ! visudo -cqf "$f" > /dev/null 2>&1; then
        echo_info "Rewriting the invalid sudo rule of $u"
        _write_user_sudoers "$u"
    fi
done

if [[ -f /etc/sudoers.d/panel ]]; then
    if grep -q -E "(sed|grep|box|drop_caches|set_interface|pkill|killall|reload|vnstat|ifstat|PACKAGECMNDS)" /etc/sudoers.d/panel; then
        echo_info "Fixing sudo permissions for panel"
        cat > /etc/sudoers.d/panel << SUD
#secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/swizzin:/usr/local/bin/swizzin/scripts:/usr/local/bin/swizzin/scripts/install:/usr/local/bin/swizzin/scripts/remove:/usr/local/bin/swizzin/panel"
#Defaults  env_keep -="HOME"

# Host alias specification

# User alias specification

# Cmnd alias specification
Cmnd_Alias   CLEANMEM = /usr/local/bin/swizzin/panel/clean_mem
Cmnd_Alias   SYSCMNDS = /usr/local/bin/swizzin/panel/lang/langSelect-*, /usr/local/bin/swizzin/panel/theme/themeSelect-*
Cmnd_Alias   GENERALCMNDS = /usr/sbin/repquota, /bin/systemctl

www-data     ALL = (ALL) NOPASSWD: CLEANMEM, SYSCMNDS, GENERALCMNDS

SUD
    fi
fi

# sudo reads any root-owned rule others cannot write, but visudo -c only accepts 0440, the mode sudo installs
for f in /etc/sudoers.d/*; do
    [[ -f $f && ! -L $f ]] || continue
    # sudo skips these names, so does this
    [[ ${f##*/} == *.* || ${f##*/} == *~ ]] && continue
    read -r mode owner group < <(stat -c '%a %U %G' "$f")
    [[ $mode:$owner:$group == 440:root:root ]] && continue
    # a rule sudo ignores (not root's, or writable by others) is never made valid: anyone could have written it
    if [[ $owner != root ]] || ((8#$mode & 8#002)) || { ((8#$mode & 8#020)) && [[ $group != root ]]; }; then
        echo_warn "$f is ignored by sudo (owner $owner, mode $mode) and was left as it is"
        continue
    fi
    chown root:root "$f"
    chmod 440 "$f"
done

if ! groups "$master" | grep -q sudo; then
    echo_log_only "Moving $master to the sudo usergroup"
    usermod -a -G sudo "$master"
    # rm /etc/sudoers.d/swizzin
fi
