#This shell was written by Lirici
#/bin/sh
apt update -y
apt upgrade -y
apt install -y fail2ban
apt install -y libgoogle-perftools-dev
apt install -y python-setuptools && easy_install pip
apt install -y git
apt install -y build-essential
apt install -y nano
pip install cymysql

#安装libsodium
wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
tar xf libsodium-1.0.16.tar.gz && cd libsodium-1.0.16
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig

#下载后端
cd 
git clone -b manyuser https://github.com/glzjin/shadowsocks.git
cd shadowsocks
apt install -y libssl-dev
apt install -y python-dev
apt install -y libffi-dev
pip install requests
cp apiconfig.py userapiconfig.py
cp config.json user-config.json

#对接面板

sed -i "22s/false/true/g" /root/shadowsocks/user-config.json

echo
read -p "请输入 node_id[1-99]: " node_id
sed -i "2s/1/$node_id/g" /root/shadowsocks/userapiconfig.py
#对接模式选择
echo "---------------------------------"
echo "对接模式选择"
echo "---------------------------------"
echo "1). glzjinmod"
echo "2). modwebapi"
echo "---------------------------------"
read select
case $select in
	1)

echo
read -p "请输入 mysql host[数据库地址]: " sqlhost
echo
read -p "请输入 mysql username[数据库用户]: " sqluser
echo
read -p "请输入 mysql password[数据库密码]: " sqlpass
echo
read -p "请输入 mysql dbname[数据库库名]: " sqldbname

sed -i "15s/modwebapi/glzjinmod/1"  /root/shadowsocks/userapiconfig.py
sed -i "24s/127.0.0.1/$sqlhost/g" /root/shadowsocks/userapiconfig.py
sed -i "26s/ss/$sqluser/g" /root/shadowsocks/userapiconfig.py
sed -i "27s/ss/$sqlpass/g" /root/shadowsocks/userapiconfig.py
sed -i "28s/shadowsocks/$sqldbname/g" /root/shadowsocks/userapiconfig.py
;;
	2)
echo
read -p "请输入 webapi_url[webapi地址]: " webapi
echo
read -p "请输入 webapi_token[面板config参数]: " webtoken
echo
read -p "请输入 测速周期: " speedtest
echo
read -p "请输入 混淆参数: " suffix

sed -i "15s/modwebapi/glzjinmod/0"  /root/shadowsocks/userapiconfig.py
sed -i "17s#https://zhaoj.in#$webapi#g"  /root/shadowsocks/userapiconfig.py
sed -i "18s/glzjin/$webtoken/g" /root/shadowsocks/userapiconfig.py
sed -i "6s/6/$speedtest/g" /root/shadowsocks/userapiconfig.py
sed -i "11s/zhaoj.in/$suffix/g" /root/shadowsocks/userapiconfig.py
		;;
esac

#配置supervisor
apt-get install supervisor -y
cat > /etc/supervisor/conf.d/ssr.conf <<EOF
[program:ssr]
environment=LD_PRELOAD="/usr/lib/libtcmalloc.so"
command=python /root/shadowsocks/server.py
autorestart=true
autostart=true
user=root
EOF
/etc/init.d/supervisor restart

# 取消文件数量限制
sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf

#aliyun service
wget https://raw.githubusercontent.com/nya-static/src/master/sh/rm-aliyun-service.sh
if [ -f /usr/sbin/aliyun-service ]
then
    bash rm-aliyun-service.sh;
fi
cd 
echo done.....