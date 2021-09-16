#!/bin/bash

red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
purple='\e[1;35m'
white='\e[1;37m'
default='\e[0m'

if [ $UID -ne 0 ]; then
    sudo -i
fi

echo -e "${green}You are now running as root."

# 1, Add date and time to command history
Profile = "/root/1.txt"
if grep -q "^export HISTTIMEFORMAT" ${Profile}; then
  echo -e "${green}Details exist in command history. Won't re-do it."
else
  echo 'export HISTTIMEFORMAT="%F %T "' >> ${Profile}
  #source ${Profile}
  echo -e "${green}Done for command history optimization."
fi
