#!/bin/bash

#本脚本通过extrabackup 2.4备份MySQL 5.x，执行前请确认innobackupex(xtrabackup)工具可用。
#若不可用，可通过yum install -y percona-xtrabackup-24-2.4.24-1.el7.x86_64.rpm进行安装。
#全备增备判断：从备份配置文件中获取上次全备信息：若上次全备不存在或超过6天，进行全备；否则以该全备为基准，进行增备。
#备份过程：先备份至临时目录xxxxxxxx_xxxxxx_tmp。
#若备份成功，将临时目录mv至正式目录xxxxxxxx_xxxxxx_full或xxxxxxxx_xxxxxx_incre；并更新备份配置文件。若备份失败，删除临时目录。
#最后根据设置的备份保留周期，删除超期的备份。

#备份参数均从配置文件读取，执行备份操作前，请确认配置文件exbackup.config的绝对路径！！
bk_config="/data/exbackup/exbackup.config"
if [ ! -f ${bk_config} ]; then
	_message="配置文件${bk_config}不存在，脚本退出！"
	echo ${_message}
	echo ${_message} >> /data/exbackup/exbackup.log
	exit 1
fi

#从配置文件获取参数值
#输入两个参数，依次为参数名、配置文件名，如"socket"和"/etc/my.cnf"
function get_config(){
	if [ ! -f $2 ];then
		log "配置文件$2不存在，脚本退出！"
		exit 1
	fi
	
	echo $(grep -i "^[ ]*$1[ ]*=[ ]*" "$2" | awk -F'[ =]' 'NR==1 {print $NF}')
}

#从配置文件读取配置
db_user=$(get_config "db_user" ${bk_config})
db_passwd=$(get_config "db_passwd" ${bk_config})
db_config=$(get_config "db_config" ${bk_config})

bk_basedir=$(get_config "bk_basedir" ${bk_config})
bk_backupdir=$(get_config "bk_backupdir" ${bk_config})
bk_log=$(get_config "bk_log" ${bk_config})
bk_keep=$(get_config "bk_keep" ${bk_config})

#记录log
function log(){
	_message="$(date +'%Y-%m-%d %H:%M:%S %a') $*"
	echo ${_message}
	echo ${_message} >> "${bk_basedir}${bk_log}"
}

#计算日期与1970-01-01之间的天数
#3个输入参数依次表示日期的年份、月份、日，如2021 11 22，表示2021年11月22日。
function date2days() {
    echo "$*" | awk '{z=int((14-$2)/12);y=$1+4800-z;m=$2+12*z-3;j=int((153*m+2)/5)+$3+y*365+int(y/4)-int(y/100)+int(y/400)-2472633;print j}'
}

#更新bk_config文件
#输入两个参数，依次为参数名、参数值
function set_bk_config(){
	if grep -i -q "^[ ]*$1[ ]*=[ ]*" ${bk_config}; then
		sed -i 's/^[ ]*'"$1"'[ ]*=.*$/'"$1"'='"$2"'/' ${bk_config}
		log "已更新$1=$2"
	fi
}

if [ ! -d ${bk_basedir} ]; then
	mkdir -p ${bk_basedir}
fi

if [ ! -d ${bk_backupdir} ]; then
	mkdir -p ${bk_backupdir}
fi

cd ${bk_basedir}

#从配置文件获取上次备份信息
current=$(date +'%Y%m%d_%H%M%S')
backup_full_name=$(get_config "backup_full_name" ${bk_config})

#计算今天与上次全备间隔的天数
last_full=$(date2days `echo ${backup_full_name:0:4} ${backup_full_name:4:2} ${backup_full_name:6:2}`)
today=$(date2days `echo ${current:0:4} ${current:4:2} ${current:6:2}`)
let result=${today}-${last_full}

log "##########################################################################"
log "上次全备：${backup_full_name}"
log "当前时间：${current}"

#flag用于标记是否进行全备：0表示非全备，即增备；1表示全备。
flag=0
message=""

#若间隔大于等于7天，或上次全备名为空，或上次全备不存在，进行全备。
if [ ${result} -ge 7 ]; then
	flag=1
	message="相隔${result}天，进行全量备份。"
fi

if [ -z ${backup_full_name} ]; then
	flag=1
	message="无全备信息，进行全量备份。"
fi

if [ ! -d ${bk_backupdir}${backup_full_name} ]; then
	flag=1
	message="上次全备目录不存在，进行全量备份。"
fi

_tmpdir="${current}_tmp"   #临时目录名，形如"20211123_150911_tmp"
_socket=$(get_config "socket" ${db_config})

#全量备份
if [ ${flag} -ne 0 ]; then
	log ${message}
	log "全备至临时目录${bk_backupdir}${_tmpdir}/"
	innobackupex --defaults-file=${db_config} --no-timestamp --user=${db_user} --password=${db_passwd} --no-lock --socket=${_socket} --kill-long-query-type=all --kill-long-queries-timeout=60 ${bk_backupdir}${_tmpdir}/
	if [ $? -eq 0 ]; then
        _fulldir="${current}_full"
		log "移动临时目录${_tmpdir}至正式目录${_fulldir}。"
		mv ${bk_backupdir}${_tmpdir} ${bk_backupdir}${_fulldir}
		#更新本次全备情况
		set_bk_config "backup_full_name" ${_fulldir}
		set_bk_config "backup_pre_name" ${_fulldir}
		log "全量备份成功！"
    else
		/usr/bin/rm -rf ${bk_backupdir}${_tmpdir}
		log "全量备份失败，已删除临时目录${_tmpdir}。"
    fi
else
	log "相隔${result}天，进行增量备份。"
	log "增备至临时目录${bk_backupdir}${_tmpdir}/"
	echo ${_socket}
	echo ${_tmpdir}
	echo ${backup_full_name}
	innobackupex --defaults-file=${db_config} --no-timestamp --user=${db_user} --password=${db_passwd} --no-lock --socket=${_socket} --kill-long-query-type=all --kill-long-queries-timeout=60 --incremental-basedir=${bk_backupdir}${backup_full_name}/ --incremental ${bk_backupdir}${_tmpdir}/
	if [ $? -eq 0 ]; then
        _incredir="${current}_incre"
		log "移动临时目录${_tmpdir}至正式目录${_incredir}。"
		mv ${bk_backupdir}${_tmpdir} ${bk_backupdir}${_incredir}
		#更新本次备份情况
		set_bk_config "backup_pre_name" ${_incredir}
		log "增量备份成功！"
    else
		/usr/bin/rm -rf ${bk_backupdir}${_tmpdir}
		log "增量备份失败，已删除临时目录${_tmpdir}。"
    fi
fi

#删除过期的备份
newest_old_full=""   #最新的过期全备，以此为标准，所有早于此的备份（全备和增备）都将被删除

#_dir是全备的绝对路径，如/data/exbackup/backup/20211124_181034_full
for _dir in `find ${bk_backupdir} -depth -maxdepth 1 -mindepth 1 -type d -name "*_full" | sort -r`
do
	#_dirname是路径名，如20211124_181034_full
	_dirname=$(echo ${_dir} | awk -F'/' '{print $NF}')
	_full_days=$(date2days ${_dirname:0:4} ${_dirname:4:2} ${_dirname:6:2})
	let _result=${today}-${_full_days}
	let _keepdays=7*${bk_keep}
	if [ ${_result} -gt ${_keepdays} ]; then    #根据保留周期数
		newest_old_full=${_dir}
		break
	fi
done

if [ ! -z ${newest_old_full} ]; then
	log "newest_old_full: ${newest_old_full}"
	for _dir in `find ${bk_backupdir} -depth -maxdepth 1 -mindepth 1 -type d ! -newer ${newest_old_full} | grep -v "${newest_old_full}" | sort -r`
	do
		log "删除超期备份：rm -rf ${_dir}"
		rm -rf ${_dir}
	done
fi

log "脚本执行完成！"
