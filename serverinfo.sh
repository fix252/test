#!/bin/bash 

#echo "默认配色"
# \e[配色方案m
#\e、\E、\033表示转义开始；[表示开始定义颜色；m表示终止转义，即颜色定义结束；\e[0m再次定义颜色为默认颜色，即恢复之前的配色方案 
#字体控制：1高亮，4下划线，5闪烁，…… 
#字体颜色30-37：0默认，30黑色，31红色，32绿色，33黄色，34蓝色，35紫色，36天蓝色，37白色 
#背景颜色40-47：0默认，40黑色，41红色，42绿色，43黄色，44蓝色，45紫色，46天蓝色，47白色

#echo -e "\e[1;33;41m高亮黄字红底 \e[0m"
#echo -e "\e[4;42m 下划线绿底 \e[0m"

red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
blue='\e[1;34m'
purple='\e[1;35m'
white='\e[1;37m'
default='\e[0m'

if [ $UID -ne 0 ]; then
    sudo -i
else
    echo -e "${green}You are now running as root."
fi

if [ -f /etc/redhat-release ]; then
    echo -e "${blue}Server OS: ${default}`cat /etc/redhat-release`"
elif [ -f /etc/issue ]; then
    echo -e "${blue}Server OS: ${default}`cat /etc/issue`"
else
    echo -e "${red}Server OS could not be detected.${default}`cat /etc/issue`"
fi

echo -e "${blue}CPU Cores: ${default}`cat /proc/cpuinfo | grep processor | wc -l`"

echo -e "${blue}Memory Size: ${default}`free -h | grep Mem | awk '{print $2}'`"

echo -e "${blue}Disk Capacity:\n${default}`lsblk | awk '$6~/disk/ {print $1,$4}' OFS=\"\t\"`"

#echo -e "${blue} 高亮蓝字 ${default} 默认配色"
#echo -e "${yellow} 高亮黄字 ${default} 默认配色"
