#!/bin/bash
# Nginx Configuration for RapidLeech
MASTER=$(cut -d: -f1 < /root/.master.info)

#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
phpversion=$(php_service_version)
sock="php${phpversion}-fpm"

# PHP (www-data) reads the app and writes its configs and downloads; what it downloaded is already its own
rl=/home/${MASTER}/rapidleech
acl_ok=true
_www_acl_served "${MASTER}" rapidleech >> "$log" 2>&1 || acl_ok=false
(cd / && runuser -u "${MASTER}" -- find "$rl/configs" "$rl/files" -xdev -user "${MASTER}" ! -type l \( -type d -exec setfacl -P -m u:www-data:rwx,d:u:www-data:rwX {} + -o -exec setfacl -P -m u:www-data:rw {} + \)) >> "$log" 2>&1 || acl_ok=false
_as_www_data test -w "$rl/configs" -a -w "$rl/files" -a -w "$rl/configs/files.lst" || acl_ok=false
if [[ $acl_ok == false ]]; then echo_warn "Could not let nginx use $rl, see $log"; fi

if [[ ! -f /etc/nginx/apps/rapidleech.conf ]]; then
    cat > /etc/nginx/apps/rapidleech.conf << RAP
location /rapidleech {
  alias /home/${MASTER}/rapidleech/;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
  try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
  index index.php;
  allow all;
  location ~ \.php$
  {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/$sock.sock;
    #fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME /home/${MASTER}\$fastcgi_script_name;
  }
}
RAP
fi
[[ $acl_ok == true ]]
