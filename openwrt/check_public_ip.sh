#!/bin/sh

# Install msmtp and update /etc/msmtprc first.
# Add hosts: 34.160.111.145 ifconfig.me in /etc/hosts.
# Add crontab task: */2 * * * * sh /root/check_public_ip.sh

# WAN interface name
interface_name=""

# Router name
router_name=""

# CloudFlare Token
zone_id=""
api_token=""
record_id=""
record_name=""       #FQDN

email_sender=""
email_receiver=""    #space seperator for multiple receivers
email_subject="Subject: New IP at ${router_name}"
email_content=""     #Keep content null here.

interface_ip=$(ifconfig ${interface_name} | sed -n "2,2p" | awk '{print $2}' | awk -F : '{print $2}')
outbound_ip=$(curl -s ifconfig.me)
history_ip="/root/device_ip.txt"

if [ ! -a ${history_ip} ]; then
        touch ${history_ip}
fi

if [ ${outbound_ip} == ${interface_ip} ]; then
        current_ip="${interface_ip}"
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
                          \"name\": \"${record_name}\",
                          \"proxied\": false,
                          \"type\": \"A\"
                        }")
                
                if echo ${update} | grep -q "\"success\":true";then
                        email_content="$(date +'%F %T %A %z'):\t${current_ip}, and update dns record successfully."
                else
                        email_content="$(date +'%F %T %A %z'):\t${current_ip}, but failed to update dns record with error message\n${update}"
                fi
        fi
else
        email_content="$(date +'%F %T %A %z'):\tPublic IP Error: outbound IP ${outbound_ip} != interface IP ${interface_ip}."
fi

#Send Email Notification
if [ ${email_content} ]; then
        echo -e "${email_subject}\n\n${email_content}" | msmtp -f ${email_sender} ${email_receiver}
fi
