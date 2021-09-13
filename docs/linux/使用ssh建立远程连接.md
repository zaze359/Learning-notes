# 使用ssh远程连接到Linux



## 服务端开启ssh

### 安装openssh-server

```shell
sudo apt-get update
sudo apt-get install openssh-server
```

### 查看ssh状态

```shell
sudo systemctl status ssh
# or; 查看是否存在sshd进程
ps -e |grep sshd
# 启动ssh.service
sudo /etc/init.d/ssh start
```

### 设置密码

```shell
sudo passwd root
```



### sshd配置修改

> 使用vi编辑时发现按键错乱可以安装vim解决

```
vi /etc/ssh/sshd_config
```

设置允许密码登录:

```shell
PermitRootLogin yes
```



## 建立远程连接

> 若连接时出现**Connection refused**,则是远端服务器未启用ssh,先去启用ssh。

获取远端服务器ip

```shell
ifconfig
```

例如我的Linux在局域网中ip为192.168.50.58, 以root账号进行连接。

```shell
# ssh -p port user@ip
## 默认22端口
ssh root@192.168.50.58
```