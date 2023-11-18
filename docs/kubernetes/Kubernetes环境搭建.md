# Kubernetes环境搭建

> 容器是软件、应用、进程。
>
> Kubernetes则是一个生产级别的容器编排平台和集群管理系统。
>
> 相当于操作系统，负责资源管理和作业调度。

## 基础环境

### Linux

真机或虚拟机。

[虚拟机安装配置](../env/虚拟机安装配置.md)

环境配置：

> 需要的工具

```shell
sudo apt update
sudo apt install -y git vim curl jq
```

### 配置远程登录

[Linux ssh 登录配置](../linux/ssh远程连接Linux.md)

测试ssh连接：

```shell
# 查看liunx ip地址
ip addr

# 用户：z
# ip：192.168.56.101
ssh z@192.168.56.101
```

### 安装Docker

[Docker Engine配置](../docker/Docker配置.md)

Kubernetes 支持多种容器运行时，这里选用Docker，作为它的容器驱动。

```shell
# 安装Docker Engine
sudo apt install -y docker.io

sudo service docker start
sudo systemctl restart docker
sudo systemctl enable docker

cat /etc/group | grep docker
sudo usermod -aG docker z

sudo chmod a+rw /var/run/docker.sock
```



---

[入门 | Kubernetes](https://kubernetes.io/zh-cn/docs/setup/)

## minikube 环境搭建

官方推荐 `kind` 和 `minikube` 两种方式管理Kubernetes集群环境。

minikube比较小巧适合学习实验使用，面向单机部署。

### 安装

> 查看安装设备的系统架构

```shell
uname -a 
```

> 在官网中选择对应架构。
>
> [minikube start | minikube (k8s.io)](https://minikube.sigs.k8s.io/docs/start/)

```shell
# Intel x86_64(amd64后缀)
curl -Lo minikube curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
# 安装
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

```shell
# Apple M1 : arm64
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-arm64
# 安装
sudo install minikube-darwin-arm64 /usr/local/bin/minikube
```

### 查看状态

```shell
minikube version
# 查看集群状态, 需要 start 创建集群后才能查看。
minikube status
minikube node list
```

### 启动

```shell
minikube start
# 指定 v1.23.3版本
minikube start --kubernetes-version=v1.23.3
# 使用国内镜像
minikube start --image-mirror-country='cn'
```

> 启动异常,  需要指定一种容器技术作为驱动，里面给出了建议。如Docker
>

![image-20230217191801252](./Kubernetes%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA.assets/image-20230217191801252.png)

> [Drivers | minikube (k8s.io)](https://minikube.sigs.k8s.io/docs/drivers/)

```shell
# 指定docker 作为驱动启动
minikube start --driver=docker
# root下使用
minikube start --force --driver=docker
minikube start --force --driver=docker --kubernetes-version=v1.23.3
```

### Dashboard界面

可以在浏览器中查看和管理Kubenetes集群。

```shell
# 使用浏览器打开 minikube的Dashboard页面
minikube dashboard
```

![image-20230217185049090](./Kubernetes%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA.assets/image-20230217185049090.png)



### 安装kubectl

`kubectl` Kubernetes客户端命令工具，负责和Kubernetes的Master节点的 apiserver 通信。

**安装**

```shell
# 安装
minikube kubectl
# 测试
minikube kubectl -- version
```

**设置别名**

```shell

alias kubectl="minikube kubectl --"
# 开启kubectl的自动补全功能
source <(kubectl completion bash)
```

**创建nginx**

```shell
kubectl run ngx --image=nginx:alpine
```

**查看pod**

```shell
kubectl get pod
```

---

## kubeadm环境搭建

`kubeadm` 是专门用来在集群中安装 Kubernetes 的工具。

原理和 `minikube`类似，也是用容器和镜像来封装Kubernetes各种组件，不过目标面向的是集群部署。

### 环境准备

这个是Master和Worker节点都需要做的准备工作

#### 1. 修改主机名

Kubernetes 使用主机名来区分集群里的节点，所以hostname不同重名。

取一个有意义的名字

* master：管理集群。
* worker：运行业务应用。
* console：安装 kubectl 来负责发送指令。

```shell
sudo vi /etc/hostname
```

#### 2. 调整Docker配置

修改 `/etc/docker/daemon.json` 文件。

将 `cgroup` 的驱动程序改成 `systemd`。

> 输入 EOF 表示结束

```shell
cat <<EOF | sudo tee /etc/docker/daemon.json
{
"registry-mirrors": ["https://docker.mirrors.ustc.edu.cn/","https://hub-mirror.c.163.com","https://registry.docker-cn.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
```

重启Docker守护进程

```shell
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

#### 3. 修改 Iptables

为了让 Kubernetes 能够检查、转发网络流量。

需要修改 iptables 的配置，启用 `br_netfilter`模块：

> 创建`/etc/modules-load.d/k8s.conf` 文件并配置 `br_netfilter`模块

```shell
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
```

> 创建`/etc/sysctl.d/k8s.conf`文件，并配置

```shell
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1 # better than modify /etc/sysctl.conf
EOF
```

> 更新配置

```shell
sudo sysctl --system
```

#### 4. 关闭 Linux 的 swap 分区

关闭 Linux 的 swap 分区，提升 Kubernetes 的性能。

修改 `/etc/fstab` ：

```shell
# Disable Swap
sudo swapoff -a
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# check
echo "please check these files:"
echo "/etc/docker/daemon.json"
echo "/etc/modules-load.d/k8s.conf"
echo "/etc/sysctl.d/k8s.conf"
echo "cat cat /etc/fstab"
```



#### 5.配置国内镜像

> 安装kubeadm 之前可以做个快照备份一下。

使用国内的软件源安装。

```shell
#
sudo apt install -y apt-transport-https ca-certificates curl
# 下载公钥
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
```

```shell
# 设置配置
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
```

```shell
# 更新源
sudo apt update
```

#### 6.安装 kubeadm

```shell
sudo apt install -y kubeadm=1.23.3-00 kubelet=1.23.3-00 kubectl=1.23.3-00
```

> 验证

```shell
kubeadm version
kubectl version --client
```

> 锁定 `kubeadm`、`kubelet`、 `kubectl`这个三个软件的版本。防止升级导致发生问题。

```shell
sudo apt-mark hold kubeadm kubelet kubectl
```

#### 7. 快照备份

### 配置Master节点

> 配置存在一定的要求：4G内存，双核。

#### 预安装 Kubernetes 组件（可选）

查看安装 Kubernetes 所需的镜像列表

```shell
# --kubernetes-version 指定版本
kubeadm config images list --kubernetes-version v1.23.3
```

拉取镜像

```shell
# 运行此脚本
repo=registry.aliyuncs.com/google_containers

for name in `kubeadm config images list --kubernetes-version v1.23.3`; do

    src_name=${name#k8s.gcr.io/}
    src_name=${src_name#coredns/}

    docker pull $repo/$src_name

    docker tag $repo/$src_name $name
    docker rmi $repo/$src_name
done

# chmod 777 xx.sh
```

```shell
# --image-repository 指定镜像下载地址
kubeadm config images pull --image-repository registry.aliyuncs.com/google_containers
docker images
# 重命名
docker tag $src_name $dst_name
```

#### init 环境

初始化环境，若之前没有下载镜像则会自动下载需要的镜像。

* `--pod-network-cidr`：设置集群里 Pod 的 IP 地址段。改为master所在设备的IP

* `--apiserver-advertise-address`：设置 apiserver 的 IP 地址。

* `--kubernetes-version`：指定 Kubernetes 的版本号。
* `--image-repository`：指定镜像下载地址

```shell
ip addr
# 192.168.56.8

# init
sudo kubeadm init \
    --pod-network-cidr=10.10.0.0/16 \
    --apiserver-advertise-address=192.168.56.8 \
    --image-repository registry.aliyuncs.com/google_containers\
    --kubernetes-version=v1.23.3
```

初始化完成后更具提示进行操作：

```shell
# 非Root
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# root用户设置环境变量即可
# export KUBECONFIG=/etc/kubernetes/admin.conf
```

同时还提供了其他节点加入需要的token和ca证书。

需要保存后续 Worker节点加入时需要使用。

```shell
kubeadm join 192.168.56.8:6443 --token 4k19s0.teja39vdnju1zlks \
        --discovery-token-ca-cert-hash sha256:54c15422bba3c81f4d1e4fa2d5d579a317b82cb4baa41ecee09962d1de6c547a 
```

查看节点状态

```shell
kubectl get node
```

#### 安装 Flannel 网络插件

需要安装网络插件后，集群内部网络能正常运作。

1.  下载kube-flannel.yml。也可手动下载然后拷贝

   ```shell
   curl https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml >> kube-flannel.yml
   ```

2.  修改 `net-conf.json` 字段：改为上方设置的 `--pod-network-cidr`

   ```json
   net-conf.json: |
       {
         "Network": "10.10.0.0/16",
         "Backend": {
           "Type": "vxlan"
         }
       }
   ```

3.  应用配置安装 Flannel 网络

   ```shell
   kubectl apply -f kube-flannel.yml
   ```

> 也可以直接应用在线文件：之前设置 `--pod-network-cidr=10.244.0.0/16`  即可。

```shell
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```



```shell
cat /run/flannel/subnet.env

# 删除 cni0
sudo ip link delete cni0

# 查看 Pod的DNS配置
cat  /etc/resolv.conf
```



---

### 配置Worker节点

> 内存 2GB，单核即可。内存太小节点容易被驱逐。

#### 执行环境准备

若是快照复制的节点，在配置节点前，先重置一下，在修改主机名。

```shell
sudo kubeadm reset
sudo vi /ect/hostname
```

否则重新安装环境准备的步骤操作一遍。

#### 加入Master

Worker节点 不需要kubeadm init ，而是执行 `kubeadm join`。会自动连接 Master 节点，然后拉取镜像，安装网络插件，最后把节点加入集群。

```shell
sudo kubeadm join 192.168.56.8:6443 --token 4k19s0.teja39vdnju1zlks \
        --discovery-token-ca-cert-hash sha256:54c15422bba3c81f4d1e4fa2d5d579a317b82cb4baa41ecee09962d1de6c547a 
```

> token 默认24小说过期，失效后 在 Master节点重新创建即可。
>
> ```shell
> kubeadm token create
> 
> # 显示加入命令
> kubeadm token create --print-join-command
> ```

### 配置 kubectl （可选）

> kubectl执行的关键就是下面两个文件。
>
> * kubectl 文件。
> * config 配置。

在Worker中 若想执行 `kubectl` 命令可以从 Master节点拷贝 `admin.conf`。

```shell
# 复制 master的 admin.conf内容
sudo vi /etc/kubernetes/admin.conf
```

环境配置操作是必不可少的。

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 配置Console （可选）

选择一个纯净的Linux环境, 只需要从master节点 拷贝 kubectl 和 `config`文件即可。

> 配置console后，我们后续只需要进入这个机器来操作Kubernetes即可。仅是一个控制台，要求的配置很低。

1. 进入Console 中创建目录

   ```shell
   mkdir -p $HOME/.kube
   ```

2. 进入Master，将需要的文件复制到Console。

   ```shell
   # console Ip：192.168.56.19
   scp `which kubectl` z@192.168.56.19:~/
   scp ~/.kube/config z@192.168.56.19:~/.kube/
   ```

3. 进入console验证

   ```shell
   # 安装一下
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   # 验证
   kubectl get node
   ```

   

### 环境异常处理

* 环境重置。

    ```shell
    sudo kubeadm reset
    ```

* 访问Pod时出现 `error: unable to upgrade connection: pod does not exist`。

    首先确定 Master init时是否设置了 

      ```shell
      --apiserver-advertise-address=<ip-address>
      ```

    其次需要修改Worker节点`/etc/systemd/system/kubelet.service.d/10-kubeadm.conf`，添加以下环境变量。

      ```shell
      sudo vi /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
      
      # Environment="KUBELET_EXTRA_ARGS=--node-ip=<worker IP address>"
      Environment="KUBELET_EXTRA_ARGS=--node-ip=192.168.56.21"
      ```

      然后重启`kubelet`

    ```shell
    sudo systemctl restart kubelet
    
    # sudo systemctl daemon-reload
    # sudo systemctl restart kubelet
    ```
    
    ![image-20230220233846313](./Kubernetes%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA.assets/image-20230220233846313.png)

