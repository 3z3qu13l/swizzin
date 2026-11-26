#!/bin/bash

if [[ -f /install/.nzbget.lock ]]; then
    if grep -qi "ExecStart=/home/%i/nzbget/nzbget -D" /etc/systemd/system/nzbget@.service; then
        echo_progress_start "Updating NZBGet systemd service file with forking"
        cat > /etc/systemd/system/nzbget@.service << NZBGD
[Unit]
Description=NZBGet Daemon
Documentation=http://nzbget.net/Documentation
After=network.target

[Service]
User=%i
Group=%i
Type=forking
ExecStart=/bin/sh -c "/home/%i/nzbget/nzbget -D"
ExecStop=/bin/sh -c "/home/%i/nzbget/nzbget -Q"
ExecReload=/bin/sh -c "/home/%i/nzbget/nzbget -O"
Restart=on-failure

[Install]
WantedBy=multi-user.target
NZBGD
        echo_progress_done
    fi
    # Do we always want to do this?
    systemctl daemon-reload
fi
