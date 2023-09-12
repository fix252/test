#!/bin/sh

# Install msmtp and update /etc/msmtprc first.
# Add crontab task: */2 * * * * sh check_public_IP.sh

history_ip="/root/device_ip.txt"

interface_ip=$(ifconfig pppoe-WAN | sed -n "2,2p" | awk '{print $2}' | awk -F : '{print $2}')
outbound_ip=$(curl -s ifconfig.me)

current_ip=$(curl -s ifconfig.me)
last_ip=$(tail -1 ${history_ip} | awk '{print $2}')

# CloudFlare Token
zone_id=""
api_token=""
record_id=""
name=""       #FQDN
result=""

if [ -z ${last_ip} ] || [ ${last_ip} != ${current_ip} ]; then
        echo -e "$(date +'%Y%m%d%H%M%S') ${current_ip}" >> ${history_ip}
        # Update DNS record
        update=$(curl -s --request PUT \
                  --url "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
                  --header "Content-Type: application/json" \
                  --header "X-Auth-Key: " \
                  --header "X-Auth-Email: " \
                  --header "Authorization: Bearer ${api_token}" \
                  --data "{
                  \"content\": \"${current_ip}\",
                  \"name\": \"${name}\",
                  \"proxied\": false,
                  \"type\": \"A\"
                }")
        
        if echo ${update} | grep -q "\"success\":true";then
                result="${current_ip}, and update dns record successfully."
        else
                result="${current_ip}, but failed to update dns record with error message\n${update}"
        fi

        #Send Email Notification
        echo -e "Subject: New IP\n\n$(date +'%F %T %A %z'):\t${result}" | msmtp -f FROM_ADDRESS TO_ADDRESS_WHIT_SPACE_FOR_MULTI_RECEIVERS
fi
