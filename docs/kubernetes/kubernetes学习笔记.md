# Kubernetes学习笔记

> 容器技术只解决了应用的打包、安装问题。
>
> 容器编排为了处理复杂的生产环境，管理各个应用容器间的关系，从而能顺利地协同运行。
>
> Kubernetes 是一个生产级别的容器编排平台和集群管理系统。

```shell
minikube version

# 查看集群状态
minikube status
minikube node list

#
minikube ssh
ps -ef|grep kubelet

minikube delete

# 启动
minikube start
# 指定版本
minikube start --kubernetes-version=v1.23.3
# 指定docker
minikube start --force --driver=docker --kubernetes-version=v1.23.3
# 使用国内镜像
minikube start --kubernetes-version=v1.23.3 --image-mirror-country='cn'


# 通过minikube安装kubectl（kubectl也可单独安装）。
minikube kubectl

# 查看插件列表
minikube addons list
```

## kubectl命令

```shell
# 设置别名
alias kubectl="minikube kubectl --"
# 开启kubectl的自动补全功能
source <(kubectl completion bash)

kubectl run ngx --image=nginx:alpine

# 查看pod列表
kubectl get pod
# 检查`kube-system`空间内的Pod
kubectl get pod -n kube-system
# 查看节点状态
kubectl get node
# 查看对象的apiVersion和kind
kubectl api-resources
# 查看对象字段的说明文档
kubectl explain [api-resources]


# -f 指定YAML文件
# 指定YAML文件创建容器
kubectl apply -f busy-pod.yml
# 指定YAML文件删除容器
kubectl delete -f busy-pod.yml
# 指定名字删除
kubectl delete pod busy-pod

# 显示日志
kubectl logs busy-pod

# 检查pod详细状态
kubectl describe pod busy-pod

# 拷贝文件
kubectl cp a.txt ngx-pod:/tmp

# 进入到ngx-pod内部
kubectl exec -it ngx-pod -- sh
```

## 环境搭建

[Kubernetes环境搭建流程](../env/Kubernetes环境搭建.md)

- minikube：
- kubectrl：Kubernetes客户端工具，用于操作k8s。

## 基本架构

Kubenetes采用的是**控制面 / 数据面（Control Plane / Data Plane）**架构，集群里的计算机被称为**节点（Node）**

- 控制面（Control Plane）：执行集群的管理和维护工作。

- 数据面（Data Plane）：跑业务应用

![img](./kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/65d38ac50b4f2f1fd4b6700d5b8e7be1.jpg)

### 节点

集群中的计算机被称为节点，可以是实机也可以是虚机。节点可分为以下两类：

* 控制面节点（**Master Node**）,简称**Master**

* 数据面节点（**Worker Node**）,简称**Worker**或**Node** 

> Master 和 Node 的划分不是绝对的, 当集群的规模较小、工作复杂较少时，Master可以承担Node的工作。

```shell
# 查看节点状态
kubectl get node
```



### 组件（Component）

> 控制面节点（**Master Node**）,简称**Master**

| Master内组件                   | 说明                                                         |        |
| ------------------------------ | ------------------------------------------------------------ | ------ |
| **apiserver（入口、通信API）** | Kubernetes系统的唯一入口，所有其他组件只能和它通信。提供RESTful API | 容器化 |
| etcd（配置存储）               | 一种高可用的分布式Key-Value数据库，持久化资源对象和状态，管理配置。只能通过apiserver访问。 | 容器化 |
| scheduler（部署、调度Pod）     | 负责容器编排，检查节点的状态，调度Pod到合适的节点上。不负责运行。 | 容器化 |
| controller-manager（监控运维） | 维护容器和节点等资源的状态。故障检测、服务迁移、应用伸缩等。 | 容器化 |

> 数据面节点（**Worker Node**）,简称**Worker**或**Node** 

| Node内组件                                  |                                                           |        |
| ------------------------------------------- | --------------------------------------------------------- | ------ |
| kubelet（Node的操作代理）                   | 只有它能与apiserver通信。状态报告、命令下发、启停容器等。 |        |
| kube-proxy（Node的网络代理）                | 管理容器的网络通信，转发TCP/UDP数据包。实现反向代理。     | 容器化 |
| container-runtime（Docker等符合标准的容器） | 容器和镜像的实际使用者。创建容器，管理Pod的生命周期。     |        |

Kubernates的大致工作流程

* 每个Node的`kubelet`会定期向`apiserver`上报节点状态，`apiserver`将状态存放到`etcd`中。
* 每个Node上的`kube-proxy`实现了TCP/UDP反向代理，使容器哼对外提供稳定的服务。
* `scheduler`通过`apiserver`获取当前节点状态，调度pod。接着`apiserver`下发命令给某个Node的`kubelet`，` kubelet`调用`container-runtime`启动容器。
* `controller-manager`也通过`apiserver`获取节点状态，监控可能的异常情况，再使用相应的手段区调节和恢复。

### 插件（Addons）

> 通过Addon为Kubernetes增加扩展功能。例如DNS、Dashboard等。

```shell
# 查看插件列表
minikube addons list

# 使用浏览器打开Dashboard页面
minikube dashboard
```

### API 对象

理论层面抽象出了很多个概念，用来描述系统的管理运维工作，这些概念就叫做“API 对象”。Kubernetes 组件 的`apiserver`。

包含`apiVersion`、`kind`、`metadata`、`spec`四个基本组成部分

```shell
# 查看当前 Kubernetes 版本支持的所有对象
kubectl api-resources
```



## YAML：标准工作语言

> Kubernetes的标准工作语言
>
> YAML是`JSON的超集`，即所有合法的JSON都是YAML。

和JSON类比：

* `缩进对齐`表示层次，可以不使用`花括号{}`和`方括号[]`（有点类似 Python）。
*  `#` 书写注释。
* 对象（字典）的格式与 JSON 基本相同，但 Key 不需要使用`双引号""`。

* 数组（列表）是使用 `-`  开头的清单形式（有点类似 MarkDown）。
* 表示对象的 `: `和表示数组的 `-` 后面都**必须要有空格**。
* 可以使用 `---` 在一个文件里分隔多个 YAML 对象。

生成一份样例（`--dry-run=client -o yaml`）：

```shell
kubectl run ngx --image=nginx:alpine --dry-run=client -o yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: ngx
  name: ngx-pod
spec:
  containers:
  - image: nginx:alpine
    name: ngx
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

[转为json](https://www.bejson.com/json/json2yaml/)如下：

```json
{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
        "creationTimestamp": null,
        "labels": {
            "run": "ngx"
        },
        "name": "ngx-pod"
    },
    "spec": {
        "containers": [
            {
                "image": "nginx:alpine",
                "name": "ngx",
                "resources": {}
            }
        ],
        "dnsPolicy": "ClusterFirst",
        "restartPolicy": "Always"
    },
    "status": {}
}
```

## Pod：最核心最基本的概念

> Pod 是对容器的“打包”，里面的容器是一个整体，总是能够一起调度、一起运行，绝不会出现分离的情况。
>
> Pod也称为`容器组`、`逻辑主机`。
>
> Pod 也是 API 对象。
>
> 把普通进程或应用加上权限限制就成了容器，再把容器加上权限限制就成了 Pod。
>
> 从容器到Pod就相当于不断抽象封装，解决复杂问题。

Kubernetes 让 Pod 去**编排处理容器**，然后把 Pod 作为应用**调度部署的最小单位**。其他所有的概念都是从pod衍生出来的



使用YAML声明式描述Pod：

|            |        |      |
| ---------- | ------ | ---- |
| apiVersion | 版本   | v1   |
| kind       | 类型   | pod  |
| metadata   | 元数据 |      |
| spec       |        |      |



### metadata

* name：名字，基本标识。
* labels：标签，可以是任何数量的key-value，可以方便我们归类区分。



### spec

#### containers

> 是一个数组，每一个元素是一个container对象（容器）。
>
> 格式类似Dockerfile。

* ports：容器对外暴露的接口
* imagePullPolicy：指定镜像拉取策略，Always/Never/IfNotPresent，默认为IfNotPresent。
* env：定义pod的环境变量
* command：定义容器启动时要执行的指令。 相当于Dockerfile 里的 ENTRYPOINT 指令
* args：command运行时的参数。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busy-pod
  labels:
    owner: chrono
    env: demo
    region: north
    tier: back
spec:
  containers:
    - image: busybox:latest
      name: busy
      imagePullPolicy: IfNotPresent
      env:
        - name: os
          value: "ubuntu"
        - name: debug
          value: "on"
      command:
        - /bin/echo
      args:
        - "$(os), $(debug)"

```

