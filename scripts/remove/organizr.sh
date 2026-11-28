#!/bin/bash
# Organizr removal
# Author: flying_sausages for Swizzin 2020

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

rm -rf /srv/organizr
rm -rf /srv/organizr_db
rm -rf /etc/nginx/apps/organizr.conf
rm -rf /install/.organizr.lock
rm /etc/fail2ban/filter.d/organizr-auth.conf
rm /etc/fail2ban/jail.d/organizr-auth.conf
fail2ban-client reload

nginx_reload
