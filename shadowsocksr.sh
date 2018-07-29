#This shell was written by Lirici
#/bin/sh
apt update -y
apt upgrade -y
apt install -y fail2ban
apt install -y git
apt install -y nano

#安装libsodium
wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig

#下载后端
cd 
git clone https://github.com/ssrpanel/shadowsocksr.git
cd /root/shadowsocksr
sh setup_cymysql2.sh

#对接面板
{
	cd /root/shadowsocksr
	echo '开始配置节点连接信息...'
	stty erase '^H' && read -p "数据库服务器地址:" mysqlserver
	stty erase '^H' && read -p "数据库服务器端口:" port
	stty erase '^H' && read -p "数据库名称:" database
	stty erase '^H' && read -p "数据库用户名:" username
	stty erase '^H' && read -p "数据库密码:" pwd
	stty erase '^H' && read -p "本节点ID:" nodeid
	stty erase '^H' && read -p "本节点流量计算比例:" ratio
	sed -i -e "s/server_host/$mysqlserver/g" usermysql.json
	sed -i -e "s/server_port/$port/g" usermysql.json
	sed -i -e "s/server_db/$database/g" usermysql.json
	sed -i -e "s/server_user/$username/g" usermysql.json
	sed -i -e "s/server_password/$pwd/g" usermysql.json
	sed -i -e "s/nodeid/$nodeid/g" usermysql.json
	sed -i -e "s/noderatio/$ratio/g" usermysql.json
	echo -e "配置完成!\n如果无法连上数据库，请检查本机防火墙或者数据库防火墙!\n请自行编辑user-config.json，配置节点加密方式、混淆、协议等"
}

#配置supervisor
apt-get install supervisor -y
cat > /etc/supervisor/conf.d/ssr.conf <<EOF
[program:ssr]
environment=LD_PRELOAD="/usr/lib/libtcmalloc.so"
command=sh /root/shadowsocksr/logrun.sh
autorestart=true
autostart=true
user=root
EOF

cat > /root/shadowsocksr/user-config.json <<EOF
{
    "server": "0.0.0.0",
    "server_ipv6": "::",
    "server_port": 8388,
    "local_address": "127.0.0.1",
    "local_port": 1080,

    "password": "m",
    "method": "aes-128-cfb",
    "protocol": "auth_chain_a",
    "protocol_param": "",
    "obfs": "tls1.2_ticket_auth",
    "obfs_param": "",
    "speed_limit_per_con": 0,
    "speed_limit_per_user": 0,

    "additional_ports" : {}, // only works under multi-user mode
    "additional_ports_only" : false, // only works under multi-user mode
    "timeout": 120,
    "udp_timeout": 60,
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": true
}
EOF


/etc/init.d/supervisor restart

# 取消文件数量限制
sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
