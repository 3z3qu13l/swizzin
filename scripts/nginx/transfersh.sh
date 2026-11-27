#!/bin/bash
# transfer.sh behind nginx, under /transfersh/: downloads are public (the link is the secret), anything
# else (upload, delete) asks for the master's password

#shellcheck source=sources/functions/transfersh
. /etc/swizzin/sources/functions/transfersh

master=$(_get_master_username)
port=$(_transfersh_port)
# shellcheck disable=SC1090
auth=$(. "$transfersh_env" && printf '%s:%s' "$HTTP_AUTH_USER" "$HTTP_AUTH_PASS" | base64 -w0)

# The file holds transfer.sh's password: root only, nginx reads it as root
install -m 600 /dev/null /etc/nginx/apps/transfersh.conf
# A Referer it cannot parse makes transfer.sh exit (on an HTML preview): it does not get any
cat > /etc/nginx/apps/transfersh.conf <<- NGX
	location /transfersh/ {
	    proxy_pass http://127.0.0.1:${port}/;
	    proxy_http_version 1.1;
	    proxy_set_header Host \$http_host;
	    proxy_set_header X-Real-IP \$remote_addr;
	    proxy_set_header X-Forwarded-For \$remote_addr;
	    proxy_set_header X-Forwarded-Proto \$scheme;
	    proxy_set_header Referer "";
	    proxy_set_header Authorization "Basic ${auth}";
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
