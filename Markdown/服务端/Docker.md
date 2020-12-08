# Docker

[TOC]

## Docker基础

Docker官网: [https://hub.docker.com/](https://hub.docker.com/)

```
docker ps -a
docker info 
docker version
docker images
docker search xxx
docker pull xxx
```

### 查询容器

```
# 显示所有容器
docker ps -a
# 显示正在运行的容器
docker ps
# 显示最近 x 个容器
docker os -n x
```

### 创建容器

```
docker run --name zaze_ubuntu -i -t ubuntu /bin/bash
```

### 使用容器

## 容器启动

- 启动容器

```
docker start zaze_ubuntu
docker restart zaze_ubuntu
# 守护式容器
docker run --name daemon_dave -d zaze_ubuntu /bin/sh -c "while true; do echo hello world; sleep 1;  done"
```

- 自动重启容器

```
# --restart
docker run --restart=always --name daemon_dave -d ubuntu /bin/sh -c "while true; do echo hello world; sleep 1; done"
# 仅退出代码非0时重启, 可指定重启次数,此处为指定5次。
--restart=on-failure:5
docker run --restart=on-failure:5 --name daemon_dave -d ubuntu /bin/sh -c "while true; do echo hello world; sleep 1; done"
```

### 附着容器

```
docker attach zaze_ubuntu
```

### 关闭容器

```
docker stop zaze_ubuntu
```

### 删除容器

```
docker rm 
# 删除全部容器
docker rm `docker ps -a -q`
```

### 容器日志

```
# 读取整个日志
docker logs daemon_dave
# 读取整个日志并持续跟踪
docker logs -f daemon_dave
# 跟踪最新日志，但不读取之前的日志
docker logs --tail 0 -f daemon_dave
# 最近10条
docker logs --tail 10 daemon_dave
```

### 容器进程

- 查看容器内的进程

```
➜  ~ docker top daemon_dave
```

- 在容器内运行进程

```
# 运行后台任务 
-ddocker exec -d daemon_dave touch /etc/new_config_file
# 在容器内进行交互命令
docker exec -t -i daemon_dave /bin/bash
```

### 深入容器

```
docker inspect daemon_dave
# -f 或者 --format指定查看
docker inspect --format='{{.State.Running}}' daemon_dave
```

## Docker镜像和仓库

### 什么是Docker镜像

- 文件系统叠加而成

```
最底端为bootfs(引导文件系统)
第二层
```