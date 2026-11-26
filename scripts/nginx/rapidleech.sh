#!/bin/bash
# Nginx Configuration for RapidLeech
MASTER=$(cut -d: -f1 < /root/.master.info)

#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
phpversion=$(php_service_version)
sock="php${phpversion}-fpm"

# PHP (www-data) reads the app and writes its configs and downloads
_www_acl_served "${MASTER}" rapidleech >> "$log" 2>&1 &&
    (cd / && runuser -u "${MASTER}" -- setfacl -P -R -m u:www-data:rwX,d:u:www-data:rwX /home/"${MASTER}"/rapidleech/configs /home/"${MASTER}"/rapidleech/files) >> "$log" 2>&1 ||
    echo_warn "Could not let nginx use /home/${MASTER}/rapidleech"

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
