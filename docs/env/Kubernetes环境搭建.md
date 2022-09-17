# Kubernetes环境搭建

> 容器是软件、应用、进程。
>
> Kubernetes则是一个生产级别的容器编排平台和集群管理系统。
>
> 相当于操作系统，负责资源管理和作业调度。

## 安装虚拟机

### 1. 下载虚拟机软件

[Downloads – Oracle VM VirtualBox](https://www.virtualbox.org/wiki/Downloads) 或者[Download VMware Fusion | VMware](https://www.vmware.com/products/fusion/fusion-evaluation.html)

### 2. 下载Linux镜像

[Ubuntu 22.04 Jammy Jellyfish 桌面版](https://ubuntu.com/download/desktop)

### 3.  虚拟机配置

网络配置（VMWare Fusion）

```tex
VMWare Fusion -> 偏好设置 -> 网络 -> + （添加一个网络）
```

![image-20220706175103184](./Kubernetes%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA.assets/image-20220706175103184.png)

安装虚拟机


| 配置项 | 参数               |      |
| ------ | ------------------ | ---- |
| 处理器 | > 2核              | 2    |
| 内存   | > 2G               | 4    |
| 存储   | > 20G              | 40   |
| 网络   | 选择之前创建的网络 |      |

直接选择下载的镜像进行`最小安装`, 最好断网离线安装，避免更新。

环境配置：

> 安装git、vim等常用的一些工具

```shell
sudo apt update
sudo apt install -y git vim curl jq
```

## 配置远程登录

```shell
sudo apt install -y openssh-server
## 查看虚拟机ip地址
ip addr
```

测试ssh连接：

```shell
ssh 用户名@xxx.xxx.xxx
```

> 最后拍个快照，方便后续进行恢复。



## 搭建minikube环境

> 官方推荐 `kind` 和 `minikube` 两种方式
>
> minikube管理Kubernetes集群环境。

下载：

```shell
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
```

安装：

```shell
sudo install minikube /usr/local/bin/
```

检测：

```shell
minikube version
```

安装`kebectl`操作Kubernetes：

```shell
minikube kubectl
```

启动minikube：

```
minikube start --kubernetes-version=v1.23.3
```

