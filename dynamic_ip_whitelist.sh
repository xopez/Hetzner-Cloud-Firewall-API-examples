#!/bin/bash

API_TOKEN=""
FIREWALL_ID=""
PORTS="22,23,24"

########################
# Check requirements   #
# Thanks to SoftCreatR #
########################
command_exists() {
  command -v "$@" >/dev/null 2>&1
}

required_packages="curl jq sipcalc"

for package in $required_packages; do
  if ! command_exists "$package"; then
    echo "The package $package is missing. Please install it, before continuing."
    exit 1
  fi
done

# get IP addresses
IPv4=$(curl --silent https://myip4.softcreatr.com/ | jq .ip)
IPv6=$(curl --silent https://myip6.softcreatr.com/ | jq .ip)

# Calc CIDR notation for IPv6
if [ -n "$IPv6" ]; then
	IPv6="${IPv6:1:-1}"
	IPv6=$(sipcalc "$IPv6"/"$(ip addr show |grep "$IPv6"|awk 'FNR==1 { print $2}'| cut -d "/" -f 2)"|grep "Subnet prefix"|awk '{print $5}')
fi

# Some magic
if [ -n "$IPv4" ] && [ -n "$IPv6" ]; then
    IPS="${IPv4::-1}"/32\",\""$IPv6"\"
elif [ -n "$IPv4" ]; then
    IPS="${IPv4::-1}"/32\"
elif [ -n "$IPv6" ]; then
    IPS=\""$IPv6"\"
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
    'https://api.hetzner.cloud/v1/firewalls/'"$FIREWALL_ID"

curl \
    -X POST \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"rules":['"$(IFS=, ; echo "${RULES[*]}")"']}' \
    'https://api.hetzner.cloud/v1/firewalls/'"$FIREWALL_ID"'/actions/set_rules'
