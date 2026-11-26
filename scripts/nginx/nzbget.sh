#!/bin/bash
# Nginx Configurator for nzbget
# Author: liara

users=($(cut -d: -f1 < /etc/htpasswd))

if [[ ! -f /etc/nginx/apps/nzbget.conf ]]; then
    cat > /etc/nginx/apps/nzbget.conf << 'NRP'
location /nzbget {
  return 301 /nzbget/;
}

location /nzbget/ {
  include /etc/nginx/snippets/proxy.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;
  rewrite ^/nzbget/(.*) /$1 break;
  proxy_pass http://$remote_user.nzbget;
}
NRP
fi

for u in "${users[@]}"; do
    isactive=$(systemctl is-active nzbget@$u)
    # as the user: the config is in their home, a root sed or grep would follow a link they put there
    (cd / && runuser -u "$u" -- sed -i -e "s/SecureControl=yes/SecureControl=no/g" -e "s/ControlIP=0.0.0.0/ControlIP=127.0.0.1/g" -e "s/ControlUsername=nzbget/ControlUsername=/g" -e "s/ControlPassword=tegbzn6789/ControlPassword=/g" /home/$u/nzbget/nzbget.conf)

    if [[ ! -f /etc/nginx/conf.d/${u}.nzbget.conf ]]; then
        NZBPORT=$(cd / && runuser -u "$u" -- grep ControlPort /home/$u/nzbget/nzbget.conf | cut -d= -f2)
        # the user can edit their config: only a port number goes into nginx
        if [[ ! $NZBPORT =~ ^[0-9]{1,5}$ ]]; then
            echo_warn "NZBGet of ${u} has no valid ControlPort, it is not added to nginx"
            continue
        fi
        cat > /etc/nginx/conf.d/${u}.nzbget.conf << NZBUPS
upstream $u.nzbget {
  server 127.0.0.1:$NZBPORT;
}
NZBUPS
    fi

    if [[ $isactive == "active" ]]; then
        systemctl restart nzbget@$u
    fi
done
