# Shadowsocks

## 服务选择

[搬瓦工](https://bwh88.net/)

### 客户端下载地址

- [shadowsocks-windows](https://github.com/shadowsocks/shadowsocks-windows)
- [shadowsocks-android](https://github.com/shadowsocks/shadowsocks-android)


## 自己搭建Shaowsocks
- 一键安装

```
wget –no-check-certificate  https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks.sh
chmod +x shadowsocks.sh
./shadowsocks.sh 2>&1 | tee shadowsocks.log
```

- Debian/Ubuntu

```bash
sudo apt-get install shadowsocks
```

```bash
apt-get install python-pip
pip install shadowsocks
```

- CentOS7

```bash
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
pip install --upgrade pip
pip install shadowsocks
```

```bash
sudo yum install python-setuptools && easy_install pip
sudo pip install shadowsocks
```

```bash
wget --no-check-certificate http://www.vofac.com/download/66R.sh&&bash 66R.sh
```

- CentOS8

```bash
sudo dnf update
sudo dnf install python3
sudo dnf install python3-pip
后续使用
pip3 xxxxx
```

## 服务端Shaowsocks配置

### 创建并编辑shadowsocks.json文件

```
vi /etc/shadowsocks.json
```

```
{
    "server": "0.0.0.0",
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "port_password":
    {
        "8388": "password",
        "8389": "password"
    },
    "timeout": 300,
    "method": "aes-256-cfb",
    "fast_open": false
}
```

### 配置防火墙

- 使用iptables

```
more /etc/sysconfig/iptables

/etc/init.d/iptables restart
/etc/rc.d/init.d/iptables save
```
```
vi /etc/sysconfig/iptables
-A INPUT -p tcp -m tcp --dport 8889 -j ACCEPT
```
```
iptables -I INPUT -p tcp --dport 27726 -j ACCEPT
```

- 使用firewall

```
systemctl start firewalld.service
systemctl stop firewalld.service
```

```
firewall-cmd --state 
firewall-cmd --reload
firewall-cmd --list-ports
```

```
firewall-cmd --zone=public --add-port=27726/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=8388/tcp --permanent
firewall-cmd --zone=public --add-port=8389/tcp --permanent
```

### 开启/关闭 ss服务

```
systemctl stop firewalld.service
ssserver -c /etc/shadowsocks.json -d start
ssserver -c /etc/shadowsocks.json -d stop 
```


## 客户端Shaowsocks配置

### 创建shadowsocks.json文件
填写服务器信息

```
{
  "server":"xxx.xxx.xxx.xxx",
  "local_address": "127.0.0.1",
  "local_port":1080,
  "server_port":443,
  "password":"123456",
  "timeout":300,
  "method":"aes-256-cfb"
}
```

### privoxy socks转为http代理

- 安装

```
sudo apt-get install privoxy
```

- 配置

打开config文件
```
sudo vim /etc/privoxy/config
```

写入以下配置

```
forward-socks5t   /               127.0.0.1:1080 .
listen-address localhost:8118
```

- 启用privoxy

```
sudo systemctl restart privoxy
systemctl enable privoxy
```

### 客户端启动SS

```
sslocal -c /home/shadowsocks.json
```

