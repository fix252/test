#!/bin/sh

# When pppoe-wan interface up happens, interface IPv4 and IPv6 addresses change.
# In this case, update router DNS A and AAAA record via CloudFlare DNS API, and send results via email and Apple message.
# Install msmtp and update /etc/msmtprc first.
# Save shell script as /etc/hotplug.d/iface/30-dnsupdate.sh

router_name=""    # Update router name

# CloudFlare Token
record_name=""       # Update FQDN
a_record_id=""       # Update A record ID
aaaa_record_id=""    # Update AAAA record ID
zone_id=""           # Update CloudFlare DNS zone ID
api_token=""         # Update CloudFlare API token

# Email config
email_sender=""      # Update email SMTP sender
email_receiver=""    # Update email receiver. Use space seperator for multiple receivers
email_subject="Subject: "   # Fixed prefix for msmtp command, do NOT modify it.
email_content=""   # Keep content null here, do NOT modify it

# Public IPv4 and IPv6 on interface pppoe-wan
wan_ipv4=$(ip -4 addr show "pppoe-wan" | sed -n "2,2p" | awk '{print $2}')
wan_ipv6=$(ip -6 addr show "pppoe-wan" | grep global | awk '{print $2}' | awk -F / '{print $1}')

# Update DNS record via CloudFlare API
# 6 parameters are required as follows:
# String zone_id
# String record_id
# String api_token
# String record_name
# String record_type, "A" or "AAAA"
# String record_value
# result is returned as String
function update_dns_record(){
	_zone_id=$1
	_record_id=$2
	_api_token=$3
	_record_name=$4
	_record_type=$5
	_record_value=$6
	
	_update_result=$(curl -s --request PUT \
			  --url "https://api.cloudflare.com/client/v4/zones/${_zone_id}/dns_records/${_record_id}" \
			  --header "Content-Type: application/json" \
			  --header "X-Auth-Key: " \
			  --header "X-Auth-Email: " \
			  --header "Authorization: Bearer ${_api_token}" \
			  --data "{
			  \"name\": \"${_record_name}\",
			  \"type\": \"${_record_type}\",
			  \"content\": \"${_record_value}\",
     			  \"ttl\": 300, 
			  \"proxied\": false
			}")
			
	echo "${_update_result}"
}

# Send notifications to Apple devices via Bark
function send_bark_notification(){
    curl -X "POST" "https://YOUR.BARK.SERVER/push" \
	 -H 'Content-Type: application/json; charset=utf-8' \
	 -d "{
		\"title\": \"${router_name} $DEVICE $ACTION\",
		\"body\": \"IPv4: ${wan_ipv4}\nIPv6: ${wan_ipv6}\",
		\"device_keys\": [\"YOUR_APPLE_DEVICE_ID1\", \"YOUR_APPLE_DEVICE_ID2\"]
	     }"
}

# OpenWRT hotplug event for pppoe-wan ifup
if [ "$ACTION" == "ifup" ] && [ "$DEVICE" == "pppoe-wan" ]; then
		sleep 10
		
		email_subject="${email_subject}Public IP at ${router_name}"
		email_content="$(date +'%F %T %A %z')"
		
		update_result1=$(update_dns_record "${zone_id}" "${a_record_id}" "${api_token}" "${record_name}" "A" "${wan_ipv4}")
		
		if echo "${update_result1}" | grep -q "\"success\":true"; then
			email_content="${email_content}\nIPv4: ${wan_ipv4}, and update A record successfully."
		else
			email_content="${email_content}\nIPv4: ${wan_ipv4}, but update A record failed with message\n${update_result1}"
		fi
		
		if [ "${wan_ipv6}" ]; then
			update_result2=$(update_dns_record "${zone_id}" "${aaaa_record_id}" "${api_token}" "${record_name}" "AAAA" "${wan_ipv6}")
			if echo "${update_result2}" | grep -q "\"success\":true"; then
				email_content="${email_content}\nIPv6: ${wan_ipv6}, and update AAAA record successfully."
			else
				email_content="${email_content}\nIPv6: ${wan_ipv6}, but update AAAA record failed with message\n${update_result2}"
			fi
		fi
		
		echo -e "${email_subject}\n\n${email_content}" | msmtp -f ${email_sender} ${email_receiver}

    # Send messages to Apple device via bark
    send_bark_notification
    
fi

# Other event if you care
if [ "$DEVICE" == "WireGuard" ]; then
    # Send messages to Apple device via bark
    send_bark_notification
fi
