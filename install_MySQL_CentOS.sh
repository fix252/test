#!/bin/bash

#本脚本在CentOS系统上通过Generic包安装mysql 5.7数据库
#安装前请确认脚本文件、tar包、配置模板等3个文件位于同一目录
#Generic tar包下载页面 https://downloads.mysql.com/archives/community/
tarball="mysql-5.7.36-linux-glibc2.12-x86_64.tar.gz"
template="my.cnf-standard"

#如需更改mysql安装目录，请修改以下3个参数。
#建议不做修改，以保持路径统一
basedir="/data/mysql"
datadir="/data/mysql/data"
logdir="/data/mysql/log"

#重要：请勿修改配置文件路径
conf="/etc/my.cnf"

#配色设置，请勿修改
red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33;40m'
blue='\e[1;34m'
default='\e[0m'

#高精度计算器
if ! rpm -qa | grep -E "^bc-"; then
    yum install -y bc
fi

#1，安装前环境检查：操作系统版本、是否已运行或安装了mysql
function check_env(){
	echo -e "${blue}1，安装前环境检查${default}"
	if [ -f /etc/redhat-release ]; then
		echo -e "操作系统版本：`cat /etc/redhat-release`"
	else
		echo -e "${yellow}注意：文件/etc/redhat-release不存在，未检测到操作系统版本。脚本退出！${default}"
		exit 1
	fi

	if ps -ef | grep "mysqld" | grep -v "grep"; then
		echo -e "${yellow}注意：检测到mysql进程。脚本退出！${default}"
		exit 1
	else
		echo -e "恭喜，未检测到mysql进程。"
	fi

	if rpm -qa | grep "mysql"; then
		echo -e "${yellow}注意：检测到mysql程序包。脚本退出！${default}"
		exit 1
	else
		echo -e "恭喜，未检测到mysql程序包。"
	fi

	if [ -d ${basedir} ] || [ -f ${conf} ]; then
		echo -e "${yellow}注意：basedir目录或${conf}文件存在。脚本退出！${default}"
		exit 1
	else
		echo -e "恭喜，未检测到basedir目录或my.cnf文件冲突。"
	fi
}

#2，安装前依赖包检查
function check_dependency(){
	echo -e "${blue}2，MySQL依赖包检查${default}"
	if rpm -qa | grep "libaio"; then
		echo -e "恭喜，依赖包已安装。"
	else
		echo -e "注意：未检测到依赖包libaio，即将安装。"
		yum install -y libaio
		if $?; then
			echo "恭喜，libaio包安装成功。"
		else
			echo -e "${yellow}注意：libaio包安装失败，请手动安装.${default}"
		fi
	fi
}

#3，初始化MySQL
function install_mysql(){
	echo -e "${blue}3，初始化MySQL${default}"
	
	echo "解压mysql安装包..."
	tar -xf ${tarball}
	if [ $? -ne 0 ]; then
		echo -e "${yellow}注意：安装包解压失败，脚本退出。${default}"
		exit 1
	fi
	
	#解压出的目录名应形如mysql-5.7.35-linux-glibc2.12-x86_64，对其进行正则匹配
	_dir=$(ls -lt -d */ | awk '{print $NF}' | grep "^mysql-.*-linux-glibc.*-x86_64/$")
	
	if [ ! -z ${_dir} ]; then
		echo "解压目录名为${_dir}"
	else
		echo -e "${yellow}未检测到解压出的目录，脚本退出！${default}"
		exit 1
	fi
	
	#判断basedir的父目录是否存在，如/data/mysql的父目录/data
	if [ ! -d `dirname ${basedir}` ]; then
		mkdir `dirname ${basedir}`
	fi
	
	mv ${_dir} ${basedir}
	mkdir -p ${datadir} ${logdir}
	
	if ! grep -q "mysql" /etc/group; then
		echo "注意：mysql用户组不存在，创建之！"
		groupadd mysql
	fi
	
	if ! grep -q "mysql" /etc/passwd; then
		echo "注意：mysql用户不存在，创建之！"
		useradd -g mysql -s /bin/false mysql
	fi
	
	chown -R mysql:mysql ${basedir}
	cd ${basedir}
	echo "开始初始化..."
	bin/mysqld --user=mysql --basedir=${basedir} --datadir=${datadir} --initialize-insecure
	bin/mysql_ssl_rsa_setup --datadir=${datadir}
	
	ln -sf "${basedir}/bin/mysql" /usr/bin/mysql
	ln -sf "${basedir}/bin/mysqldump" /usr/bin/mysqldump
	ln -sf "${basedir}/bin/mysqldumpslow" /usr/bin/mysqldumpslow
	ln -sf "${basedir}/bin/mysqlbinlog" /usr/bin/mysqlbinlog
	cp "${OLDPWD}/${template}" ${conf}
	echo "初始化已完成。"
}

#更改单项配置
#函数传入两个参数：参数1，mysql的参数名；参数2，对应的参数值。
#更新后的配置文件内容形如"setting = value"格式，如"server_id = 18"。
#请注意，如果参数值需要带引号，请在传参时带上对应的引号。
function update_setting(){
	_setting=$1
	_passed_value=$2
	_value=${_passed_value//\//\\/}  #因sed用法，将路径中的/替换为\/
	
	if grep -i -q "^[ #]*${_setting}[ ]*=[ ]*" ${conf}; then
		sed -i 's/^[ #]*'"${_setting}"'[ ]*=.*$/'"${_setting}"' = '"${_value}"'/' "${conf}"
	else
		sed -i '$a\'"${_setting}"' = '"${_value}"'' "${conf}"
	fi
	
	echo "已修改：${_setting}=${_passed_value}"
}

#4，更新配置文件
function update_settings(){
	echo -e "${blue}4，更新配置文件${conf}${default}"
	if [ ! -f ${conf} ]; then
		echo -e "${yellow}注意：配置文件不存在，跳过更新。${default}"
		return
	fi
	
	#设置server_id为IP地址的第4位
	_id=`ip address | grep -P "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v -w "lo" | grep -v -E "veth|docker|flannel|br-" | awk '{print $2}' | awk -F'/' 'NR==1{print $1}' | awk -F'.' '{print $4}'`
	update_setting "server_id" ${_id}
	
	#设置innodb_buffer_pool_size为内存的75%
	_memory=`free -h | grep Mem | awk '{print $2}'`   #形如"15G"
	_number=${_memory:0:${#_memory}-1}                #数字部分，15
	_calculate=$(echo "${_number}*3/4+1" | bc)        #十进制数字部分的75%（向下取整）+1，值为12
	_unit=${_memory:${#_memory}-1}                    #内存单位：G
	_size="${_calculate}${_unit}"                     #计算值和单位进行拼接，结果为"12G"
	update_setting "innodb_buffer_pool_size" ${_size}
	
	#设置innodb_buffer_pool_instances为core数的一半
	_core=`cat /proc/cpuinfo | grep processor | wc -l`    #CPU core数，如16
	_instances=$(echo "${_core}/2" | bc)                  #CPU core数的一半，如8
	update_setting "innodb_buffer_pool_instances" ${_instances}
	
	update_setting "basedir" ${basedir}
	update_setting "datadir" ${datadir}
	update_setting "pid_file" "${basedir}/mysql.pid"
	update_setting "log_bin" "${logdir}/master-bin"
	update_setting "log_error" "${logdir}/mysql-error.log"
	if [ ! -f "${logdir}/mysql-error.log" ]; then      #MySQL bug：若自定义的error log文件不存在，mysql服务无法启动，必须提前创建，修改属主。
		touch "${logdir}/mysql-error.log"
		chown mysql:mysql "${logdir}/mysql-error.log"
	fi
	
	update_setting "long_query_time" 5
	update_setting "slow_query_log_file" "${logdir}/mysql-slow.log"
	update_setting "relay_log" "${logdir}/mysql-relay.log"
	update_setting "innodb_undo_directory" ${logdir}
	echo "其他参数设置，请到配置文件${conf}中查看。"
}

#5，启动服务，更新账号
function update_account(){
	echo -e "${blue}5，启动mysql，设置root密码${default}"
	cd ${basedir}
	./support-files/mysql.server start
	
	if [ $? -ne 0 ]; then
		echo -e "${yellow}注意：启动mysql服务失败，请检查error log后手动启动服务后修改设置root密码。脚本退出！${default}"
		exit 1
	fi
	
	mysql -uroot -e "create user 'bk'@'%' identified by 'bk@monitor';"
	mysql -uroot -e "grant process,references,replication client,replication slave,select,show databases,show view on *.* to 'bk'@'%';"
	echo "已创建账号bk，密码bk@monitor，用于蓝鲸监控。"
	
	mysql -uroot -e "create user 'backup'@'%' identified by 'backup';"
	mysql -uroot -e "grant process, select, reload, show view, lock tables, trigger, replication client, event on *.* to 'backup'@'%';"
	#若为MySQL 8.0，授予replication_slave_admin权限后，可在从实例进行mysqldump操作，命令如下：
	#mysqldump -ubackup -pbackup -R -E --triggers --single-transaction --dump-slave=2 --all-databases > slave_`date +'%Y%m%d%H%M%S'`.sql
	#mysql -uroot -e "grant replication_slave_admin on *.* to backup;"
	echo "已创建账号backup，密码backup，用于备份。"
	
	mysql -uroot -e "create user 'repl'@'%' identified by 'repl';"
	mysql -uroot -e "grant replication slave on *.* to 'repl'@'%';"
	echo "已创建账号repl，密码repl，用于主从同步。"
	
	read -sp "请设置root密码：" _pass1
	echo
	read -sp "请再次输入root密码：" _pass2
	echo
	until [ ${_pass1} == ${_pass2} ]
	do {
		read -sp "密码不匹配，请重新设置root密码：" _pass1
		echo
		read -sp "请再次输入root密码：" _pass2
		echo
	}
	done
	
	#创建账号root@%
	mysql -uroot -e "create user 'root'@'%' identified by '${_pass1}';"
	mysql -uroot -e "grant all privileges on *.* to 'root'@'%' with grant option;"
	
	#修改密码root@localhost
	mysql -uroot -e "alter user 'root'@'localhost' identified by '${_pass1}';"
	mysql -uroot -p${_pass1} -e "flush privileges;" 2>/dev/null
	
	echo -e "已设置root密码，请使用新密码登录。"
}

#6，设置系统服务
function add_service(){
	echo -e "${blue}6，设置系统服务${default}"
	cd ${basedir}
	/usr/bin/cp -f support-files/mysql.server /etc/init.d/mysql
	chmod +x /etc/init.d/mysql
	chkconfig --add mysql
	chkconfig --level 345 mysql on
	chkconfig mysql on
	echo -e "恭喜，已设置开机自启mysql服务。"
	echo -e "请使用service mysql start|stop|restart|status管理mysql。"
}

#7，个性化设置
function customize(){
	_profile="/etc/profile.d/custom.sh"
	if [ ! -f ${_profile} ]; then
		cat > ${_profile} << EOF
#!/bin/bash
red='\e[1;31m'
green='\e[32m'
yellow='\e[1;33;40m'
blue='\e[1;34m'
purple='\e[1;35m'
default='\e[0m'

echo -e "${blue}------------------------------------------------------------"
echo -e "请使用如下命令管理mysql服务："
echo -e "service mysql start|stop|restart|status"
echo -e "------------------------------------------------------------${default}"

PS1='[\[\e]0;\u@\h: \w\a\]\${debian_chroot:+(\$debian_chroot)}\[\033[32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]]\\$ '
alias ll='ls -alh'
EOF
	elif ! grep -qi "mysql" ${_profile}; then
		cat >> ${_profile} << EOF

echo -e "\e[1;34m请使用如下命令管理mysql服务："
echo -e "service mysql start|stop|restart|status\e[0m"
EOF
	fi
}

check_env
check_dependency
install_mysql
update_settings
update_account
add_service
customize

echo -e "${blue}恭喜，安装配置已完成，开始使用mysql吧！${default}"
