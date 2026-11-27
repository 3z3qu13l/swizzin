#!/bin/bash
# transfer.sh behind nginx, under /transfersh/: downloads are public (the link is the secret), anything
# else (upload, delete) asks for the master's password

master=$(_get_master_username)
port=$(grep -o -- '--listener 127.0.0.1:[0-9]*' /etc/systemd/system/transfersh.service | cut -d: -f2)

cat > /etc/nginx/apps/transfersh.conf <<- NGX
	location /transfersh/ {
	    proxy_pass http://127.0.0.1:${port}/;
	    proxy_http_version 1.1;
	    proxy_set_header Host \$http_host;
	    proxy_set_header X-Real-IP \$remote_addr;
	    proxy_set_header X-Forwarded-For \$remote_addr;
	    proxy_set_header X-Forwarded-Proto \$scheme;
	    proxy_request_buffering off;
	    proxy_buffering off;
	    proxy_read_timeout 1h;
	    client_max_body_size 0;
	    auth_basic off;
	    limit_except GET HEAD {
	        auth_basic "What's the password?";
	        auth_basic_user_file /etc/htpasswd.d/htpasswd.${master};
	    }
	}
NGX
