# Docker配置

目前Docker使用存在两个选择：**Docker Desktop** 和 Docker Engine。

**Docker Desktop**是商业产品，个人使用免费，有直观的图形界面。

**Docker Engine**完全免费，但只能在Linux上使用。

## Docker Engine配置

### 1、安装

```shell
#安装Docker Engine
sudo apt install -y docker.io
```

### 2、启动服务

```shell
#启动docker服务
sudo service docker start
```

### 3、当前用户加入Docker用户组

> 操作Docker需要root权限，直接使用root不够安全，官方推荐使用加入用户组的方式。

```shell
sudo usermod -aG docker ${USER}
```

#### 4. 验证是否可用

> ssh连接需要先使用`exit`退出再重新连接。

```shell
docker version
```



