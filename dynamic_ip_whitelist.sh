#!/bin/bash

API_TOKEN=""
FIREWALL_ID=""
PORT="22"

# get IP addresses
IPv4=$(curl --silent https://myip4.softcreatr.com/ | jq .ip)
IPv6=$(curl --silent https://myip6.softcreatr.com/ | jq .ip)

if [ ! -z "$IPv4" ] && [ ! -z "$IPv6" ]; then
        IPS=\""${IPv4:1:-1}"/32\",\""${IPv6:1:-1}"/128\"
elif [ ! -z "$IPv4" ]; then
        IPS=\""${IPv4:1:-1}"/32\"
elif [ ! -z "$IPv6" ]; then
        IPS=\""${IPv6:1:-1}"/128\"
else
        echo "No IP address provided"
        exit 0
fi

curl \
        -X PUT \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Dynamic IP Whitelist '"$(date +%d.%m.%Y)"' '"$(date +%R)"'"}' \
        'https://api.hetzner.cloud/v1/firewalls/'$FIREWALL_ID

curl \
        -X POST \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"rules":[{"direction":"in","source_ips":['"$IPS"'],"protocol":"tcp","port":"'"$PORT"'"}]}' \
        'https://api.hetzner.cloud/v1/firewalls/'$FIREWALL_ID'/actions/set_rules'
