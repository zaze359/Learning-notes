---

title: Shadowsocks搭建
date: 2020-04-16 13:46
author: zaze

---
Tags： zaze cmd

[TOC]

# Shadowsocks搭建
---
## 服务器购买
- [ 搬瓦工](https://bwh88.net/)
- [Just My Socks](https://justmysocks2.net/)
- [Just My Socks中文网](https://www.jichang.us/)

## Shaowsocks安装

- Debian/Ubuntu
```
sudo apt-get install shadowsocks
```

```
apt-get install python-pip
pip install shadowsocks
```

- CentOS7

```
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python get-pip.py
pip install --upgrade pip
pip install shadowsocks
```

```
sudo yum install python-setuptools && easy_install pip
sudo pip install shadowsocks
```

```
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


- 一键安装
```
wget –no-check-certificate  https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks.sh
chmod +x shadowsocks.sh
./shadowsocks.sh 2>&1 | tee shadowsocks.log
```





## 服务端Shaowsocks

### 1. 购买VPS

[搬瓦工VPS - BandwagonHost 中文网][1]

### 2. 配置

vi /etc/shadowsocks.json

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

### 3. 配置防火墙

- iptables
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

- firewall
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


### 3. 启动/关闭

```
systemctl stop firewalld.service
ssserver -c /etc/shadowsocks.json -d start
ssserver -c /etc/shadowsocks.json -d stop 
```


## 客户端Shaowsocks

### 1. 配置

找到配置文件所在位置 例如在/etc/下
```
sudo vi /home/zhaozhen/桌面/shadowsocks.json
```

填写服务器信息
```
{
  "server":"104.225.151.111",
  "local_address": "127.0.0.1",
  "local_port":1080,
  "server_port":443,
  "password":"thEaN9cSgq",
  "timeout":300,
  "method":"aes-256-cfb"
}
```


### 2. privoxy socks转为http代理

- 安装
```
sudo apt-get install privoxy
```

- 配置
```
sudo vim /etc/privoxy/config
```
```
forward-socks5t   /               127.0.0.1:1080 .

listen-address localhost:8118

```
- privoxy
```
sudo systemctl restart privoxy
systemctl enable privoxy
```

### 3. 启动

```
sslocal -c /home/zhaozhen/桌面/shadowsocks.json
```

