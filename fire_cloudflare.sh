#!/bin/bash

API_TOKEN="xxxx"
FIREWALL_ID="xxxx"

# get response codes
responseipv4=$(curl --head --write-out '%{http_code}' --silent --output /dev/null https://www.cloudflare.com/ips-v4)
responseipv6=$(curl --head --write-out '%{http_code}' --silent --output /dev/null https://www.cloudflare.com/ips-v6)

if [ "$responseipv4" == "200" ] && [ "$responseipv6" == "200" ]; then

	curl https://www.cloudflare.com/ips-v4 -o /tmp/ips-v4
	curl https://www.cloudflare.com/ips-v6 -o /tmp/ips-v6
	IP_CF="\"$(sed ':a;N;$!ba;s/\n/","/g' /tmp/ips-v4)\",\"$(sed ':a;N;$!ba;s/\n/","/g' /tmp/ips-v6)\""

	curl \
		-X PUT \
		-H "Authorization: Bearer $API_TOKEN" \
		-H "Content-Type: application/json" \
		-d '{"name":"Cloudflare '"$(date +%d.%m.%Y)"' '"$(date +%T)"'"}' \
		'https://api.hetzner.cloud/v1/firewalls/'$FIREWALL_ID

	curl \
		-X POST \
		-H "Authorization: Bearer $API_TOKEN" \
		-H "Content-Type: application/json" \
		-d '{"rules":[{"direction":"in","source_ips":['"$IP_CF"'],"protocol":"tcp","port":"443"}]}' \
		'https://api.hetzner.cloud/v1/firewalls/'$FIREWALL_ID'/actions/set_rules'
fi