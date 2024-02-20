# Docker基础

[TOC]

容器其实就是操作系统里的进程，只是被容器运行环境加上了 namespace、cgroup、chroot 的限制，所以容器和普通进程在资源的使用方面是没有什么区别的，也因为没有虚拟机的成本，启动更迅速，资源利用率也就更高。

Docker官网: [https://hub.docker.com/](https://hub.docker.com/)

[Reference documentation | Docker Documentation](https://docs.docker.com/reference/)

```shell
docker ps -a
docker info 
docker version
docker images
docker search xxx
docker pull xxx
```

## 容器操作命令清单

| 操作命令       | 作用                       |                                             |
| -------------- | -------------------------- | ------------------------------------------- |
| docker ps      | 查询容器                   |                                             |
| docker run     | 从镜像启动容器             |                                             |
| docker exec    | 在**容器内**执行另一个程序 |                                             |
| docker stop    | 强制停止关闭容器           |                                             |
| docker start   | 启动已停止的容器           |                                             |
| docker restart | 重启容器                   |                                             |
| docker rm      | 彻底删除容器               | 删除所有容器：docker rm \`docker ps -a -q\` |
| docker attach  | 附着容器                   |                                             |
| docker logs    | 容器日志相关               |                                             |

### docker ps（查询容器）

```shell
# 显示所有容器，包括已停止的
docker ps -a
# 显示正在运行的容器
docker ps
# 显示最近 x 个容器
docker ps -n x
```

### docker run（运行容器）

| 常用参数     | 作用                         |      |
| ------------ | ---------------------------- | ---- |
| -it          | 开启一个交互式操作的 Shell   |      |
| -d           | 后台运行                     |      |
| -e           | 设置环境变量                 |      |
| --name       | 为容器起名                   |      |
| --expose/ -p | 映射 [宿主端口] : [容器端口] |      |
| --link       | 链接不同容器                 |      |

```shell
docker run --name zaze_ubuntu -i -t ubuntu /bin/bash
```

* 守护式容器

  ```shell
  docker run --name daemon_dave -d zaze_ubuntu /bin/sh -c "while true; do echo hello world; sleep 1;  done"
  ```

* 自动重启容器

  ```shell
  # --restart
  docker run --restart=always --name daemon_dave -d ubuntu /bin/sh -c "while true; do echo hello world; sleep 1; done"
  # 仅退出代码非0时重启, 可指定重启次数,此处为指定5次。
  --restart=on-failure:5
  docker run --restart=on-failure:5 --name daemon_dave -d ubuntu /bin/sh -c "while true; do echo hello world; sleep 1; done"
  ```

### docker logs（容器日志）

```shell
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

```shell
# docker top + 容器id
docker top daemon_dave
```

- 在容器内运行进程

```shell
# 运行后台任务 
-ddocker exec -d daemon_dave touch /etc/new_config_file
# 在容器内进行交互命令
docker exec -t -i daemon_dave /bin/bash
```

### 深入容器

```shell
docker inspect daemon_dave
# -f 或者 --format指定查看
docker inspect --format='{{.State.Running}}' daemon_dave
```

### 容器与外部的交互

#### 1. 文件拷贝

> `docker cp` 命令

获取容器ID: 查找或启动容器

```shell
docker ps
docker run ...
```

将宿主机当前目录下的`a.txt`拷贝到 容器ID为`d9c` 的容器的`/tmp`目录下。

```shell
docker cp a.txt d9c:/tmp
```

验证：

```shell
# 进入到容器内
docker exec -it d9c sh
ls /tmp
```

将文件从容器中拷贝到宿主机。

```
docker cp d9c:/tmp/a.txt ./b.txt
```

#### 2. 共享文件

> `-v 宿主机路径: 容器内路径`
>
> 只读：`-v /tmp:/tmp:ro`

将宿主的`/tmp`目录挂载到容器的`/tmp`目录。

```shell
docker run -d --rm -v /tmp:/tmp redis
```

进入容器中，进行文件操作验证：

```shell
docker exec -it 183 sh
```

#### 3. 网络互通

> Docker 提供了三种网络模式：
>
> `null`：没有网络，允许其他网络插件来自定义网络。
>
> `host`：直接使用宿主机网络，去掉了容器的网络隔离，容易导致端口冲突。
>
> `bridge`：默认就是此模式，通过虚拟网桥和网卡收发网络数据包。

host模式：

```shell
docker run -d --rm --net=host nginx:alpine
```

端口映射：

> `-p 本机端口 : 容器端口`

```
docker run -d -p 8080:80 --rm nginx:alpine
```



## Docker镜像和仓库

### 镜像特征

* 只读，不可修改

- 打包系统文件和所有依赖
  ```
  最底端为bootfs(引导文件系统)
  第二层
  ```

* 任何系统上都有一致的运行环境
* 镜像是容器的静态形式。使用容器技术运行后就形成了动态的容器。

### 镜像操作命令清单

| 操作命令        | 作用               |                                 |
| --------------- | ------------------ | ------------------------------- |
| docker pull xxx | 拉取镜像           |                                 |
| docker images   | 列出本地已有镜像   |                                 |
| docker rmi      | 删除镜像           | docker rmi \`docker images -q\` |
| docker build    | 创建镜像           |                                 |
| docker history  | 回放镜像的构建过程 |                                 |
| docker search   | 查找镜像           |                                 |

### 镜像创建

| 指令    |                                    |                                                    |
| ------- | ---------------------------------- | -------------------------------------------------- |
| ARG     | 定义变量。                         | 仅在镜像构建过程中可见，容器运行时不可见。         |
| ENV     | 定义环境变量。                     | 不仅在镜像构建过程中可用，容器运行时也可用。       |
| FROM    | 指定构建的基础镜像                 | 构建镜像的第一条指令。                             |
| COPY    | 将制定资源、配置等文件打包进镜像。 | 只能使用构建上下文的相对路径。尽量只包含必要文件。 |
| RUN     | 构建镜像时要执行的shell命令        | 可以是任意的shell命令                              |
| EXPOSE  | 声明容器对外服务的端口号           |                                                    |
| WORKDIR | 容器的工作目录                     |                                                    |

新建文件`Dockerfile`, 进行编写:

```dockerfile
# Dockerfile
# docker build -t ngx-app .
# docker build -t ngx-app:1.0 .

# ARG指令：定义变量，只能在构建镜像的时候使用
ARG IMAGE_BASE="nginx"
ARG IMAGE_TAG="1.21-alpine"

# FROM指令： 指定构建的基础镜像
FROM ${IMAGE_BASE}:${IMAGE_TAG}

# ENV：定义环境变量，在容器运行的时候以环境变量的形式出现，让进程运行时使用。
ENV PATH=$PATH:/tmp
ENV DEBUG=OFF

# 拷贝到镜像中，只能使用相对路径
COPY ./default.conf /etc/nginx/conf.d/

# 执行shell命令
RUN cd /usr/share/nginx/html \
    && echo "hello nginx" > a.txt

# 声明容器对外服务的端口号
EXPOSE 8081 8082 8083

# 容器的工作目录
WORKDIR /etc/nginx
```

排除不需要文件`.dockerignore`:

```dockerfile
*.swp
*.sh
```


创建镜像:

> `.` ：就是指定的上下文
>
> `-f` ：指定`Dockerfile`文件，不指定时默认查找当前目录下名字为`Dockerfile`的文件; 
>
> `-t`：指定tag
>
> 构建时首先输出，`Sending build context to Docker daemon`，所以Docker daemon仅能访问基于指定上下文的相对路径。

```shell
# -f 指定Dockerfile文件 不指定时默认查找当前目录下名字为Dockerfile的文件; -t 指定tag
docker build -t ngx-app:1.0 .
docker build -f Dockerfile.mynginx .
```



### 镜像上传

登录docker hub：

```shell
docker login -u username
```

使用`tag`给镜像命名：

```
docker tag ngx-app chronolaw/ngx-app:1.0
```

`docker push`上传：

```
docker push chronolaw/ngx-app:1.0
```

### 镜像本地存储

导入/导出压缩包

```
docker save ngx-app:latest -o ngx.tar
docker load -i ngx.tar
```

### 镜像仓库

镜像地址配置文件

```shell
/etc/docker/daemon.json
```

#### 搭建私有镜像仓库

创建：

```shell
# 拉取官方提供的仓库镜像
docker pull registry
# 启动容器，端口映射
docker run -d -p 5000:5000 registry
```

上传镜像到私有仓库：

> 需要在镜像名前指定仓库的地址。

```shell
docker tag nginx:alpine 127.0.0.1:5000/nginx:alpine
```

```shell
docker push 127.0.0.1:5000/nginx:alpine
```

查看参考镜像列表：

> [HTTP API V2 | Docker Documentation](https://docs.docker.com/registry/spec/api/)

```shell
curl 127.1:5000/v2/_catalog
curl 127.1:5000/v2/nginx/tags/list
```



## 容器的实现技术

Linux 资源隔离 三大技术：namespace、cgrodocker-compose、chroot

* namespace：可以创建出独立的文件系统、主机名、进程号、网络等资源空间，实现了**系统全局资源和进程局部资源的隔离**。

* cgroup：用来实现对**进程的 CPU、内存等资源的优先级和配额限制**。

* chroot：可以更改进程的根目录，也就是**限制访问文件系统**。

  