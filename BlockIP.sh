#!/bin/bash

# This script fetchs source IPs who failed to log in server via ssh for more than 10 times from system logs.
# Then theses IPs will be blocked by being added to file /etc/hosts.deny.

DenyFile="/etc/hosts.deny"
LogFile="/var/log/BlockIP.log"

#LoginHistory="/var/log/auth.log*"
#IPs=`grep -i "failed" ${LoginHistory} | egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | sort -n | uniq -c | awk '$1>=10 {print $2}'`

IPs=`lastb -a | awk '$2~/ssh/ {print $NF}'| sort -n | uniq -c | awk '$1>=10 {print $2}'`

echo -e "`date +"%F %T"`" >> ${LogFile}

for i in ${IPs}
do
        if grep -q "sshd:${i}$" ${DenyFile}; then
                #echo -e "`date +"%F %T"`: Existing IP ${i}" >> ${LogFile}
                :
        else
                echo -e "Blocking IP ${i}" >> ${LogFile}
                
                echo -e "\n#`date +"%F %T"`" >> ${DenyFile}
                echo "sshd:${i}" >> ${DenyFile}
        fi
done

echo "=======================================================" >> ${LogFile}
