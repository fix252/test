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

# 1, Optimize command history
Profile="/etc/profile"
if grep -q "^export HISTTIMEFORMAT" ${Profile}; then
  echo -e "${green}Command history was optimized. Won't re-do it."
else  
  cat >> ${Profile} << EOF
export HISTTIMEFORMAT="%F %T "
export PROMPT_COMMAND='{ date "+%F %T ## \$(who am i |awk "{print \\\$3,\\\$4,\\\$1,\\\$2,\\\$5}") ## \$(whoami) ## \$(history 1 | { read x cmd; echo "\$cmd"; })"; } >> /var/log/command.log'
EOF
  
  source ${Profile}
  echo -e "${green}Done for command history optimization."
fi

# 2, Update prompt for CentOS in /etc/bashrc
# cat >> /etc/bashrc << EOF
# PS1='[ \[\e]0;\u@\h: \w\a\]\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] ]\$ '
# alias ll='ls -alh'
# EOF
# echo 'PS1="[ \[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] ]\$ "' >> /etc/bashrc
# echo "alias ll='ls -alh'" >> /etc/bashrc
