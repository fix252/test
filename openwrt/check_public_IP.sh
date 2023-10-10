#!/bin/sh

# Install msmtp and update /etc/msmtprc first.
# Add crontab task: */2 * * * * sh check_public_IP.sh

# WAN interface name
interface_name="pppoe-WAN"

# Router name
router_name=""

# CloudFlare Token
zone_id=""
api_token=""
record_id=""
name=""       #FQDN
result=""

email_sender=""
email_receiver=""    #space seperator for multiple receivers

interface_ip=$(ifconfig ${interface_name} | sed -n "2,2p" | awk '{print $2}' | awk -F : '{print $2}')
outbound_ip=$(curl -s ifconfig.me)
history_ip="/root/device_ip.txt"

if [ ${outbound_ip} == ${interface_ip} ]; then
        current_ip=${interface_ip}
        last_ip=$(tail -1 ${history_ip} | awk '{print $2}')
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
                        result="$(date +'%F %T %A %z'):\t${current_ip}, and update dns record successfully."
                else
                        result="$(date +'%F %T %A %z'):\t${current_ip}, but failed to update dns record with error message\n${update}"
                fi
                
        fi
else
        result="$(date +'%F %T %A %z'):\tPublic IP Error: outbound IP ${outbound_ip} != interface IP ${interface_ip}."
fi

#Send Email Notification
echo -e "Subject: New IP at ${router_name}\n\n${result}" | msmtp -f ${email_sender} ${email_receiver}
