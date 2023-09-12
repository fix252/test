#!/bin/sh

# */5 * * * * sh block_ip.sh > /dev/null 2>&1

logread | grep "Bad password attempt" | awk '{print $NF}' | awk -F: '{print $1}' | sort -n | uniq -c | awk '$1>=10 {print $2}' >> /etc/luci-uploads/blacklist.txt

sort -u /etc/luci-uploads/blacklist.txt > /etc/luci-uploads/tmp.txt
mv /etc/luci-uploads/tmp.txt /etc/luci-uploads/blacklist.txt

fw4 reload
