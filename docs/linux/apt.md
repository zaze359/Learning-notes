# 软件包管理：apt 

## 常用命令

```shell

sudo apt update
# 更新
sudo apt upgrade

# -y 安装过程提示选择全部为"yes"
# -q 不显示安装过程
# git 
sudo apt install -y git
# curl
sudo apt install curl
# python
sudo apt install python
#

```



## 镜像源配置

### 方式一、直接修改镜像源配置文件

直接修改镜像源配置文件：`/etc/apt/sources.list`。最好备份一下。

将文件内的域名替换成 `mirrors.aliyun.com`

### 方式二、新建一个配置文件。

在`/etc/apt/sources.list.d/` 下新建一个配置文件

例如 `ubuntu 20.04` 设置镜像源

```shell
sudo apt install -y apt-transport-https ca-certificates curl
# 下载公钥
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
# 设置配置
sudo tee /etc/apt/sources.list.d/ubuntu_apt.list
deb https://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

# deb https://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
# deb-src https://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse

EOF
```

```shell

```

