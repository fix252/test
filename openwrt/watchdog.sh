#!/bin/sh

# Monitor network status by ping.
# Usage: sh watchdog.sh 192.168.1.1

hostname="YOUR_HOSTNAME"
tries=0
current_status="Failed"   #Failed as default.
history_status="/PATH/TO/YOUR/HISTORY_FILE.txt"

if [ ! -f "${history_status}" ]; then
    touch "${history_status}"
fi

while [[ ${tries} -lt 5 ]]; do
	if ping -c 1 -W 1 $1 > /dev/null; then
		current_status="OK"
		# echo "ping ${hostname} --> $1: ${current_status}."
		break
	else
		tries=$((tries+1))
		# echo "ping ${hostname} --> $1: attempt ${tries} ${current_status}."
		sleep 3
	fi
done

#echo "Current status:${current_status}!"
last_status=$(tail -1 ${history_status} | awk '{print $2}')

# Send notifications to WXWork group via webhook
if [[ "${current_status}" != "${last_status}" ]]; then
	echo -e "$(date +'%Y-%m-%d_%H:%M:%S') ${current_status}" >> ${history_status}
	msg="$(date +'%F %T %A')\nping ${hostname} --> $1: ${current_status}."

	curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_WEBHOOK_ID' \
		-H 'Content-Type: application/json' \
		-d "{
            \"msgtype\": \"text\",
            \"text\": {
            		  \"content\": \"${msg}\"
					}
        }"
	echo ""

  # Send notifications to Apple device via Bark.
	curl -X "POST" "https://YOUR.BARK.SERVER/push" \
		-H 'Content-Type: application/json; charset=utf-8' \
		-d "{
				\"title\": \"Network Alert\",
				\"body\": \"${msg}\",
				\"device_keys\": [\"YOUR_APPLE_DEVICE_ID\"]
			}"
	echo ""
fi
