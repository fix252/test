#!/bin/bash

#本脚本通过extrabackup 2.4恢复MySQL 5.x，执行前请确认innobackupex(xtrabackup)工具可用。
#恢复步骤：
#1，停mysql实例，删除data目录：mv data data_bk
#2，创建data目录：mkdir data
#3，恢复数据
#3.1 恢复全备
# innobackupex --apply-log 全备目录
# innobackupex --defaults-file=/etc/my.cnf --copy-back --rsync 全备目录
#3.2 恢复增备
# innobackupex --apply-log --redo-only 全备目录
# innobackupex --apply-log 全备目录 --incremental-dir=增备目录
# innobackupex --defaults-file=/etc/my.cnf --copy-back --rsync 全备目录
#4，修改data目录属主属组：chown -R mysql:mysql data，启动mysql实例。
#注意！！！数据恢复时，原始备份（全备和增备）文件会被修改，无法用于其他还原。在执行恢复操作前，务必保留原始备份的副本！！！

#恢复参数均从配置文件读取，执行恢复操作前，请确认配置文件exbackup.config的绝对路径！！
bk_config="/data/exbackup/exbackup.config"

if [ ! -f ${bk_config} ]; then
	_message="配置文件${bk_config}不存在，脚本退出！"
	echo -e "\e[1;31m${_message}\e[0m"
	exit 1
fi

#从配置文件获取参数值
#输入两个参数，依次为参数名、配置文件名，如"socket"和"/etc/my.cnf"
function get_config(){
	if [ ! -f $2 ];then
		_message="配置文件$2不存在，脚本退出！"
		echo -e "\e[1;31m${_message}\e[0m"
		exit 1
	fi
	
	echo $(grep -i "^[ ]*$1[ ]*=[ ]*" "$2" | awk -F'[ =]' '{print $NF}')
}

#从配置文件读取配置
db_config=$(get_config "db_config" ${bk_config})          #MySQL配置文件/etc/my.cnf
bk_basedir=$(get_config "bk_basedir" ${bk_config})
bk_backupdir=$(get_config "bk_backupdir" ${bk_config})

backups=(`ls -l ${bk_backupdir} | grep "^d" | awk '{if($NF~/^[0-9]{8}_[0-9]{6}_/) {print $NF}}' | sort -r`)
count=${#backups[@]}

if [ ${count} -lt 1 ];then
	echo "${bk_backupdir}目录无备份，脚本退出！"
	exit 1
fi

echo "${bk_backupdir}目录下存在如下${count}个备份："
for ((i=0;i<count;i++))
do
	echo "${i}: ${backups[i]}"
done

read -p "请选择待恢复的备份序号[0-$((count-1))]：" choice
#可能输入非数字，进行大小判断时会出错，需屏蔽错误信息
until [ ${choice} -ge 0 1>/dev/null 2>&1 ] && [ ${choice} -lt ${count} 1>/dev/null 2>&1 ]
do
	read -p "输入有误，请重新选择待恢复的备份序号[0-$((count-1))]：" choice
done

chosen_bk=${backups[choice]}
chosen_bk_type=$(get_config backup_type ${bk_backupdir}${chosen_bk}/xtrabackup_checkpoints)
chosen_bk_begin=$(get_config from_lsn ${bk_backupdir}${chosen_bk}/xtrabackup_checkpoints)
chosen_bk_end=$(get_config to_lsn ${bk_backupdir}${chosen_bk}/xtrabackup_checkpoints)

if [ -n ${db_config} ] && [ -f /etc/my.cnf ]; then
	db_config="/etc/my.cnf"
fi
db_datadir=$(get_config datadir ${db_config})

if [ ${chosen_bk_type} == "full-backuped" ] && [ ${chosen_bk_begin} -eq 0 ]; then
	#全备恢复步骤
	#1，停mysql实例，删除data目录，创建新data目录
	#2，复制全备副本至/tmp目录
	#3，恢复全备
	#   innobackupex --apply-log 全备副本目录
	#   innobackupex --defaults-file=/etc/my.cnf --copy-back --rsync 全备副本目录
	#4，修改mysql data目录属主属组，启mysql
	echo "您选择的${chosen_bk}是全备，现在开始恢复..."
	sleep 3
	service mysql stop
	if ps -ef | grep "mysqld" | grep -v "grep"; then
		echo -e "\e[1;43m注意：仍检测到mysql进程，脚本退出！请手动停止mysql后重试。\e[0m"
		exit 1
	fi
	mv ${db_datadir} "${db_datadir}_`date +'%Y%m%d%H%M%S'`" && mkdir ${db_datadir}
	
	echo "复制全备副本${chosen_bk} ===> /tmp/${chosen_bk}"
	cp -rf ${bk_backupdir}${chosen_bk} /tmp/${chosen_bk}
	
	echo "从全备副本/tmp/${chosen_bk}准备数据..."
	innobackupex --apply-log /tmp/${chosen_bk}
	
	echo "从全备副本/tmp/${_full_bk}恢复数据..."
	innobackupex --defaults-file=${db_config} --copy-back --rsync /tmp/${chosen_bk}
	
	chown -R mysql:mysql ${db_datadir} && service mysql start
	echo -e "\e[1;42m恭喜，全备${chosen_bk}恢复成功，脚本结束！若mysql服务启动失败，请手动启动。\e[0m"
	
	rm -rf /tmp/${chosen_bk}
	
elif [ ${chosen_bk_type} == "incremental" ] && [ ${chosen_bk_begin} -gt 0 ]; then
	#增备恢复步骤
	#1，停mysql实例，删除data目录，创建新data目录
	#2，定位增备所依赖的全备
	#3，复制增备副本和对应的全备副本至/tmp目录
	#4，恢复增备
	#   innobackupex --apply-log --redo-only 全备副本目录
	#   innobackupex --apply-log 全备副本目录 --incremental-dir=增备副本目录
	#   innobackupex --defaults-file=/etc/my.cnf --copy-back --rsync 全备副本目录
	#5，修改mysql data目录属主属组，启mysql
	
	#查找增备对应的全备
	for ((j=choice+1;j<count;j++))  
	do
		if echo ${backups[j]} | grep -qE "*_full$"; then
			#echo "${j}: ${backups[j]}"
			_full_bk=${backups[j]}
			_full_bk_type=$(get_config backup_type ${bk_backupdir}${_full_bk}/xtrabackup_checkpoints)
			_full_bk_begin=$(get_config from_lsn ${bk_backupdir}${_full_bk}/xtrabackup_checkpoints)
			_full_bk_end=$(get_config to_lsn ${bk_backupdir}${_full_bk}/xtrabackup_checkpoints)
			if [ ${_full_bk_type} == "full-backuped" ] && [ ${_full_bk_begin} -eq 0 ] && [ ${_full_bk_end} -eq ${chosen_bk_begin} ];then
				echo "您选择的${chosen_bk}是增备，其依赖的全备为${_full_bk}。"
				full_bk=${_full_bk}
				break
			fi
		fi
	done
	
	if [ -z ${_full_bk} ]; then
		echo "您选择的${chosen_bk}是增备，但无法定位其依赖的全备，无法进行数据恢复。脚本退出！"
		exit 1
	fi
	
	echo "现在开始恢复..."
	sleep 3
	service mysql stop
	if ps -ef | grep "mysqld" | grep -v "grep"; then
		echo -e "\e[1;43m注意：仍检测到mysql进程，脚本退出！请手动停止mysql后重试。\e[0m"
		exit 1
	fi
	mv ${db_datadir} "${db_datadir}_`date +'%Y%m%d%H%M%S'`" && mkdir ${db_datadir}
	
	echo "复制增备副本：${chosen_bk} ===> /tmp/${chosen_bk}"
	cp -rf ${bk_backupdir}${chosen_bk} /tmp/${chosen_bk}
	
	echo "复制全备副本：${_full_bk} ===> /tmp/${_full_bk}"
	cp -rf ${bk_backupdir}${_full_bk} /tmp/${_full_bk}
	
	echo "从副本/tmp/${_full_bk}准备全备..."
	innobackupex --apply-log --redo-only /tmp/${_full_bk}
	
	echo "合并增备副本/tmp/${chosen_bk}至全备副本/tmp/${_full_bk} ..."
	innobackupex --apply-log /tmp/${_full_bk} --incremental-dir=/tmp/${chosen_bk}
	
	echo "从全备副本/tmp/${_full_bk}恢复数据..."
	innobackupex --defaults-file=${db_config} --copy-back --rsync