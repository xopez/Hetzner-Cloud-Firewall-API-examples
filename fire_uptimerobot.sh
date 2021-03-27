#!/bin/bash

API_TOKEN="xxxx"
FIREWALL_ID="xxxx"

# get response code
response=$(curl --head --write-out '%{http_code}' --silent --output /dev/null https://uptimerobot.com/inc/files/ips/IPv4andIPv6.txt)

if [ "$response" == "200" ]; then

	curl https://uptimerobot.com/inc/files/ips/IPv4andIPv6.txt -o /tmp/uptimerobot_IPv4andIPv6.txt
	
	# remove \r
	sed -i 's/\r$//' /tmp/uptimerobot_IPv4andIPv6.txt
	
	# split IPv4 and IPv6
	< /tmp/uptimerobot_IPv4andIPv6.txt grep "\." > /tmp/uptimerobot_IPv4.txt
	< /tmp/uptimerobot_IPv4andIPv6.txt grep "\:" > /tmp/uptimerobot_IPv6.txt

	# extend with CIDR
	IPv4="\"$(sed ':a;N;$!ba;s/\n/\/32","/g' /tmp/uptimerobot_IPv4.txt)\/32\""
	IPv6="\"$(sed ':a;N;$!ba;s/\n/\/128","/g' /tmp/uptimerobot_IPv6.txt)\/128\""

	curl \
		-X PUT \
		-H "Authorization: Bearer $API_TOKEN" \
		-H "Content-Type: application/json" \
		-d '{"name":"Uptimerobot '"$(date +%d.%m.%Y)"' '"$(date +%T)"'"}' \
		'https://api.hetzner.cloud/v1/firewalls/'$FIREWALL_ID

	curl \
		-X POST \
		-H "Authorization: Bearer $API_TOKEN" \
		-H "Content-Type: application/json" \
		-d '{"rules":[{"direction":"in","source_ips":['"$IPv4"'],"protocol":"icmp"},{"direction":"in","source_ips":['"$IPv6"'],"protocol":"icmp"}]}' \
		'https://api.hetzner.cloud/v1/firewalls/'$FIREWALL_ID'/actions/set_rules'
fi
