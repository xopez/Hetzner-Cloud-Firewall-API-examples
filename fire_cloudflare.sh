#!/bin/bash

API_TOKEN="xxxx"
FIREWALL_ID="xxxx"
PORTS="80,443"

# get response codes
responseipv4=$(curl --head --write-out '%{http_code}' --silent --output /dev/null https://www.cloudflare.com/ips-v4)
responseipv6=$(curl --head --write-out '%{http_code}' --silent --output /dev/null https://www.cloudflare.com/ips-v6)

if [ "$responseipv4" == "200" ] && [ "$responseipv6" == "200" ]; then

    curl https://www.cloudflare.com/ips-v4 -o /tmp/cf_ips-v4
    curl https://www.cloudflare.com/ips-v6 -o /tmp/cf_ips-v6

    IPv4="\"$(sed ':a;N;$!ba;s/\n/","/g' /tmp/cf_ips-v4)\""
    IPv6="\"$(sed ':a;N;$!ba;s/\n/","/g' /tmp/cf_ips-v6)\""
    RULES=()

    for PORT in $(echo "${PORTS//,/ }"); do
        for IPS in "$IPv4" "$IPv6"; do
            RULES+=('{"direction":"in","source_ips":['"$IPS"'],"protocol":"tcp","port":"'"$PORT"'"}')
        done
    done

    curl \
        -X PUT \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Cloudflare '"$(date +%d.%m.%Y)"' '"$(date +%R)"'"}' \
        'https://api.hetzner.cloud/v1/firewalls/'"$FIREWALL_ID"

    curl \
        -X POST \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"rules":['"$(IFS=, ; echo "${RULES[*]}")"']}' \
        'https://api.hetzner.cloud/v1/firewalls/'"$FIREWALL_ID"'/actions/set_rules'
fi
