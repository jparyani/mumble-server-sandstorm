#!/bin/bash
set -euo pipefail
# something something folders
mkdir -p /var/lib/nginx
mkdir -p /var/log
mkdir -p /var/log/nginx
# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
rm -rf /var/run
mkdir -p /var/run

UWSGI_SOCKET_FILE=/var/run/uwsgi.sock

# Spawn uwsgi
HOME=/var uwsgi \
        --socket $UWSGI_SOCKET_FILE \
        --plugin python \
        --virtualenv /opt/app/env \
        --wsgi-file /opt/app/main.py &

# Wait for uwsgi to bind its socket
while [ ! -e $UWSGI_SOCKET_FILE ] ; do
    echo "waiting for uwsgi to be available at $UWSGI_SOCKET_FILE"
    sleep .2
done

mkdir -p /var/lib/mumble-server
mkdir -p /var/run/mumble-server
test -e /var/token && bash -c 'sleep 5; /opt/app/deps/sandstorm-tcp-listener-proxy/bin/sandstorm-tcp-listener-proxy -c "$(cat /var/token)" 3334 "$(jq .port /var/state -r)"'&
/usr/sbin/murmurd -ini /opt/app/mumble-server.ini&

# Start nginx.
/usr/sbin/nginx -g "daemon off;"
