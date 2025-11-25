#!/usr/bin/env bash

YAML="servers.yaml"
OUT="server-status.json"
TMP=$(mktemp)

check_ping() {
  local host=$1
  ping -c 1 -W 1 "$host" >/dev/null 2>&1
}

check_port() {
  local host=$1
  local port=$2
  nc -z -w 1 "$host" $port
}

check_http() {
  local url=$1
  curl -fsS --max-time 2 "$url" >/dev/null 2>&1
}

#check_redis() {
#  local host=$1
#  local port=$2
#  redis-cli -h "$host" -p "$port" ping | grep -q PONG
#}
#
check_postgres() {
    local host="$1"
    local port="$2"
    local dbname="$3"
    local user="$4"

    pg_isready \
        -h "$host" \
        -p "$port" \
        ${dbname:+-d "$dbname"} \
        ${user:+-U "$user"} \
        -t 2 >/dev/null 2>&1
}

check_docker() {
  local name=$1
  ssh -o BatchMode=yes "$host" \
    docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null | grep -q true
}

echo '{' > "$TMP"
echo "  \"generated_at\": $(date +%s)," >> "$TMP"
echo '  "statuses": [' >> "$TMP"
first=true

servers_len=$(yq '.servers | length' "$YAML")

for ((i=0; i<servers_len; i++)); do
    id=$(yq -r ".servers[$i].id"   "$YAML")
    name=$(yq -r ".servers[$i].name" "$YAML")
    kind=$(yq -r ".servers[$i].kind" "$YAML")
    host=$(yq -r ".servers[$i].host // \"\"" "$YAML")
    port=$(yq -r ".servers[$i].port // \"\"" "$YAML")
    container=$(yq -r ".servers[$i].container // \"\"" "$YAML")

    # Run your check
    case "$kind" in
        ping)
            if check_ping $host; then
                status="up"
            else
                status="down"
            fi
            ;;
        port)
            if check_port $host $port; then
                status="up"
            else
                status="down"
            fi
            ;;
        http)
            if check_http $host; then
                status="up"
            else
                status="down"
            fi
            ;;
        postgres)
            if check_postgres $host $port; then
              status="up"
            else
              status="down"
            fi
            ;;
        docker)
            if check_docker $host $container; then
              status="up"
            else
              status="down"
            fi
            ;;
#        redis)
#            if $check_redis $host $port; then
#                status="up"
#            else
#                status="down"
#            fi
#            ;;
        *)
            status="unknown"
            ;;
    esac

    # Add to JSON
    if [ "$first" = true ]; then
        first=false
    else
        echo "," >> "$TMP"
    fi

    printf '    { "id": "%s", "name": "%s", "status": "%s" }' \
      "$id" "$name" "$status" >> "$TMP"
done


echo "] }" >> "$TMP"
mv "$TMP" "$OUT"
