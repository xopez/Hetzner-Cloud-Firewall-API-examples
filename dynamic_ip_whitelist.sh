#!/bin/bash

API_TOKEN=""
FIREWALL_ID=""
PORTS="22,23,24"

# get IP addresses
IPv4=$(curl --silent https://myip4.softcreatr.com/ | jq .ip)
IPv6=$(curl --silent https://myip6.softcreatr.com/ | jq .ip)

if [ ! -z "$IPv4" ] && [ ! -z "$IPv6" ]; then
    IPS="${IPv4::-1}"/32\","${IPv6::-1}"/128\"
elif [ ! -z "$IPv4" ]; then
    IPS="${IPv4::-1}"/32\"
elif [ ! -z "$IPv6" ]; then
    IPS="${IPv6::-1}"/128\"
else
    echo "No IP address provided"
    exit 0
fi

RULES=()
for PORT in $(echo "${PORTS//,/ }"); do
    RULES+=('{"direction":"in","source_ips":['"$IPS"'],"protocol":"tcp","port":"'"$PORT"'"}')
done

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
    -d '{"rules":['"$(IFS=, ; echo "${RULES[*]}")"']}' \
    'https://api.hetzner.cloud/v1/firewalls/'$FIREWALL_ID'/actions/set_rules'
