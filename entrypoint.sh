#!/bin/sh

# check if port variable is set or go with default
if [ -z ${PORT+x} ]; then echo "PORT variable not defined, leaving N8N to default port."; else export N8N_PORT="$PORT"; echo "N8N will start on '$PORT'"; fi

start_tailscale() {
  if [ -z "${TS_AUTHKEY:-}" ] && [ "${TS_ENABLE:-}" != "true" ]; then
    return 0
  fi

  TS_STATE_DIR="${TS_STATE_DIR:-/tmp/tailscale}"
  TS_SOCKET="${TS_SOCKET:-$TS_STATE_DIR/tailscaled.sock}"
  TS_TUN="${TS_TUN:-userspace-networking}"
  mkdir -p "$TS_STATE_DIR"

  echo "Starting tailscaled"
  tailscaled --state="$TS_STATE_DIR/tailscaled.state" --socket="$TS_SOCKET" --tun="$TS_TUN" &

  i=0
  while [ ! -S "$TS_SOCKET" ] && [ $i -lt 50 ]; do
    i=$((i + 1))
    sleep 0.1
  done

  if [ ! -S "$TS_SOCKET" ]; then
    echo "tailscaled socket not ready; skipping tailscale up"
    return 0
  fi

  TS_UP_ARGS="--socket=$TS_SOCKET"
  if [ -n "${TS_AUTHKEY:-}" ]; then
    TS_UP_ARGS="$TS_UP_ARGS --authkey=$TS_AUTHKEY"
  fi
  if [ -n "${TS_HOSTNAME:-}" ]; then
    TS_UP_ARGS="$TS_UP_ARGS --hostname=$TS_HOSTNAME"
  fi
  if [ -n "${TS_ADVERTISE_TAGS:-}" ]; then
    TS_UP_ARGS="$TS_UP_ARGS --advertise-tags=$TS_ADVERTISE_TAGS"
  fi
  if [ -n "${TS_ACCEPT_DNS:-}" ]; then
    TS_UP_ARGS="$TS_UP_ARGS --accept-dns=$TS_ACCEPT_DNS"
  fi
  if [ -n "${TS_ACCEPT_ROUTES:-}" ]; then
    TS_UP_ARGS="$TS_UP_ARGS --accept-routes=$TS_ACCEPT_ROUTES"
  fi
  if [ -n "${TS_EXTRA_ARGS:-}" ]; then
    TS_UP_ARGS="$TS_UP_ARGS $TS_EXTRA_ARGS"
  fi

  echo "Bringing Tailscale up"
  # shellcheck disable=SC2086
  tailscale up $TS_UP_ARGS || echo "tailscale up failed; continuing without it"
}

# regex function
parse_url() {
  eval $(echo "$1" | sed -e "s#^\(\(.*\)://\)\?\(\([^:@]*\)\(:\(.*\)\)\?@\)\?\([^/?]*\)\(/\(.*\)\)\?#${PREFIX:-URL_}SCHEME='\2' ${PREFIX:-URL_}USER='\4' ${PREFIX:-URL_}PASSWORD='\6' ${PREFIX:-URL_}HOSTPORT='\7' ${PREFIX:-URL_}DATABASE='\9'#")
}

# prefix variables to avoid conflicts and run parse url function on arg url
PREFIX="N8N_DB_" parse_url "$DATABASE_URL"
echo "$N8N_DB_SCHEME://$N8N_DB_USER:$N8N_DB_PASSWORD@$N8N_DB_HOSTPORT/$N8N_DB_DATABASE"
# Separate host and port    
N8N_DB_HOST="$(echo $N8N_DB_HOSTPORT | sed -e 's,:.*,,g')"
N8N_DB_PORT="$(echo $N8N_DB_HOSTPORT | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

export DB_TYPE=postgresdb
export DB_POSTGRESDB_HOST=$N8N_DB_HOST
export DB_POSTGRESDB_PORT=$N8N_DB_PORT
export DB_POSTGRESDB_DATABASE=$N8N_DB_DATABASE
export DB_POSTGRESDB_USER=$N8N_DB_USER
export DB_POSTGRESDB_PASSWORD=$N8N_DB_PASSWORD

start_tailscale

# kickstart nodemation
n8n
