# 使用ssh远程连接到Linux



## 服务端开启ssh

### 安装openssh-server

```shell
sudo apt-get update
sudo apt-get install openssh-server
```

### 查看ssh状态

```shell
# 查看ssh状态
sudo systemctl status ssh
# or; 查看是否存在sshd进程
ps -e |grep sshd
```

### 启动ssh

```shell
# 启动ssh.service
sudo /etc/init.d/ssh start
```

### 设置密码

```shell
sudo passwd root
```

### sshd配置修改

> 使用vi编辑时发现按键错乱可以安装vim解决
>
> `sudo apt install -y vim`

```
vi /etc/ssh/sshd_config
```

设置允许密码登录:

```shell
PermitRootLogin yes
```



## 建立远程连接

> 若连接时出现**Connection refused**,则是远端服务器未启用ssh,先去启用ssh。

### 查询服务器ip

```shell
ifconfig
ip addr
```

### 连接

> 例如我的Linux 在局域网中ip为192.168.50.58,。
>
> 以root账号进行连接。

```shell
# ssh -p port user@ip
## 默认22端口
ssh root@192.168.50.58
```

## 文件传输

### scp

> 文件

```shell
# 将本地文件localFile.txt 上传到 远程remoteDir文件中取名localFile.txt。远程结果：remoteDir/localFile.txt
scp ./localFile.txt root@192.168.50.58:remoteDir/localFile.txt
# 将远程remoteDir/localFile.txt 下载到 当前目录中localFile.txt。本地结果：./localFile.txt
scp root@192.168.50.58:remoteDir/localFile.txt localFile.txt
```

> 文件夹

```shell
# 将本地文件夹localDir 上传到 远程remoteDir文件中。远程结果：remoteDir/localDir
scp -r localDir root@192.168.50.58:remoteDir
# 将远程remoteDir文件夹 下载到 localDir中。本地结果：localDir/remoteDir
scp -r root@192.168.50.58:remoteDir /localDir
```

