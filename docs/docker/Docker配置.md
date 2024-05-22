# Docker配置

目前Docker使用存在两个选择：**Docker Desktop** 和 Docker Engine。

**Docker Desktop**是商业产品，个人使用免费，有直观的图形界面。

**Docker Engine**完全免费，但只能在Linux上使用。

## Docker Engine配置

### 1、安装

[Install Docker Engine | Docker Documentation](https://docs.docker.com/engine/install/)

> apt

```shell
# 安装Docker Engine
sudo apt install -y docker.io
```

> yum

```shell
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```



### 2、启动服务

```shell
# 启动docker服务
sudo service docker start

# 重启
sudo systemctl restart docker

# 开机启动
sudo systemctl enable docker
```

### 3、当前用户加入Docker用户组

> 操作Docker需要root权限，直接使用root不够安全，官方推荐使用加入用户组的方式。
>
> Got permission denied xxx 相关错误也可通过该方式处理

```shell
# 查看用户组
cat /etc/group | grep docker
# 不存在则 创建 docker 用户组
# sudo groupadd docker

# 添加到用户组
# sudo usermod -aG docker ${USER}
sudo usermod -aG docker z
```

添加完后重启dokcer 服务

```shell
sudo systemctl restart docker
```

`docker.sock`添加权限

```shell
sudo chmod a+rw /var/run/docker.sock
```

### 4. 验证是否可用

> ssh连接需要先使用`exit`退出再重新连接。

```shell
docker version
```

## Docker镜像地址配置

* 打开`/etc/docker/daemon.json`。

  ```shell
  sudo vi /etc/docker/daemon.json
  ```

* 配置完后重启docker服务。

```shell
{
"registry-mirrors": ["https://docker.mirrors.ustc.edu.cn/","https://hub-mirror.c.163.com","https://registry.docker-cn.com"]
}
# ,"insecure-registries": ["10.0.0.12:5000"]
```

