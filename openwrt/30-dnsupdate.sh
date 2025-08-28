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

# IPv4 and IPv6 on interface pppoe-wan
# wan_ipv4=$(ip -4 addr show "pppoe-wan" | sed -n "2,2p" | awk '{print $2}')
# wan_ipv6=$(ip -6 addr show "pppoe-wan" | grep global | awk '{print $2}' | awk -F / '{print $1}')
wan_ipv4=$(ubus call network.interface.wan status | jsonfilter -e '@["ipv4-address"][0].address')
wan_ipv6=$(ubus call network.interface.wan_6 status | jsonfilter -e '@["ipv6-address"][0].address')

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
     		  \"proxied\": false,
		 	  \"ttl\": 300, 
			  \"comment\": \"$(date +'%F %T %A')\"
			}")
			
	echo "${_update_result}"
}

# Send notifications to Apple devices via Bark
# 1 parameter is required as follows:
# $1 String notification_body
function send_bark_notification(){
    curl -X "POST" "https://YOUR.BARK.SERVER/push" \
	 -H 'Content-Type: application/json; charset=utf-8' \
	 -d "{
		\"title\": \"${router_name} $DEVICE $ACTION\",
		\"body\": \"$1\",
		\"device_keys\": [\"YOUR_APPLE_DEVICE_ID1\", \"YOUR_APPLE_DEVICE_ID2\"]
	     }"
}

# Send notifications to WXWork webhook
# 1 parameter is required as follows:
# $1 String notification_content
function send_wxwork_notification(){
	curl "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_WXWORK_WEBHOOK_ID" \
    	-H 'Content-Type: application/json' \
    	-d "{
            	\"msgtype\": \"text\",
            	\"text\": {
                          	\"content\": \"$1\"
                      	  }
         	}"
}

# OpenWRT hotplug event for pppoe-wan ifup
if [ "$ACTION" == "ifup" ] && [ "$DEVICE" == "pppoe-wan" ]; then
		sleep 10
		
		email_subject="${email_subject}Public IP at ${router_name}"
		email_content="$(date +'%F %T %A')"
		
		update_result1=$(update_dns_record "${zone_id}" "${a_record_id}" "${api_token}" "${record_name}" "A" "${wan_ipv4}")
		
		if echo "${update_result1}" | grep -q "\"success\":true"; then
			email_content="${email_content}\nIPv4: ${wan_ipv4}, and update succeed."
		else
			email_content="${email_content}\nIPv4: ${wan_ipv4}, but update failed: \n${update_result1}"
		fi
		
		if [ "${wan_ipv6}" ]; then
			update_result2=$(update_dns_record "${zone_id}" "${aaaa_record_id}" "${api_token}" "${record_name}" "AAAA" "${wan_ipv6}")
			if echo "${update_result2}" | grep -q "\"success\":true"; then
				email_content="${email_content}\nIPv6: ${wan_ipv6}, and update succeed."
			else
				email_content="${email_content}\nIPv6: ${wan_ipv6}, but update failed: \n${update_result2}"
			fi
		fi

    # Send notifications
    send_bark_notification ${email_content}
	send_wxwork_notification ${email_content}
	echo -e "${email_subject}\n\n${email_content}" | msmtp -f ${email_sender} ${email_receiver}
fi

# Other event if you care
if [ "$DEVICE" == "WireGuard" ]; then
    send_bark_notification "IPv4: ${wan_ipv4}\nIPv6: {wan_ipv6}"
	send_wxwork_notification "${router_name} $DEVICE $ACTION\nIPv4: ${wan_ipv4}\nIPv6: {wan_ipv6}"
fi
