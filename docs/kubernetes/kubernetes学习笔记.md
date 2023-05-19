# Kubernetes学习笔记

Kubernetes 源自Google的 Borg 系统，是一个生产级别的容器编排平台和集群管理系统。也是云原生时代的基础操作系统。

* **容器技术**：解决了应用的打包、安装问题。
* **容器编排（Container Orchestration）**：为了在复杂的生产环境中管理各个应用容器间的关系，并顺利地协同运行。

## 环境配置

[Kubernetes环境搭建流程](./Kubernetes环境搭建.md)

[Kubernetes常用命令](./Kubernetes常用命令.md)

## 基本架构

Kubernetes 采用的是**控制面 / 数据面（Control Plane / Data Plane）**架构，同时将集群里的**计算机被称为节点（Node）**。

![img](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/65d38ac50b4f2f1fd4b6700d5b8e7be1-1683443671876-1.jpg)

### Plane：面

- **控制面（Control Plane）**：执行集群的管理和维护工作。

- **数据面（Data Plane）**：跑业务应用

### Node：节点

节点就是集群中的计算机，可以是实机也可以是虚机。

节点可分为以下两类：

* **Master**：控制面节点（Master Node）。负责管理集群和运维监控应用。

* **Worker/Node** ：数据面节点（Worker Node）。受到Master节点的管理。

Master 和 Worker的划分不是绝对的, 当集群的规模较小、工作复杂较少时，Master可以承担Worker的工作。此时Master就是Worker。

```shell
# 查看节点状态
kubectl get node
```

> Master核心组件的YAML文件存放在 `/etc/kubernetes/manifests` 下。
>
> 这些组件都是以静态Pod的方式存在。

| Master核心组件       | 说明                                                         | 是否被容器化 |
| -------------------- | ------------------------------------------------------------ | ------------ |
| `apiserver`          | **Kubernetes系统的唯一入口**，所有其他组件只能和它通信。**提供RESTful API 通讯方式**。 | 容器化       |
| `etcd`               | **配置存储**。一种高可用的分布式Key-Value数据库，持久化资源对象和状态，管理配置。只能通过`apiserver` 访问。 | 容器化       |
| `scheduler`          | **负责容器编排，部署和调度Pod，检查节点的状态**，调度Pod到合适的节点上。不负责运行。 | 容器化       |
| `controller-manager` | **监控运维**：维护容器和节点等资源的状态。故障检测、服务迁移、应用伸缩等。 | 容器化       |

| Worker核心组件      |                                                              | 是否被容器化 |
| ------------------- | ------------------------------------------------------------ | ------------ |
| `kubelet`           | Worker的**操作代理**。只有它能与 `apiserver` 通信。状态报告、命令下发、启停容器等。 |              |
| `kube-proxy`        | Worker的**网络代理**。管理容器的网络通信，转发TCP/UDP数据包。实现反向代理。 | 容器化       |
| `container-runtime` | 可以是Docker等任意**符合标准的容器**。容器和镜像的实际使用者。创建容器，管理Pod的生命周期。 |              |

> Kubernates 的大致工作流程：

* 每个Worker的`kubelet`会定期向`apiserver`上报节点状态，`apiserver`则将状态存放到`etcd`中。
* 每个Worker上的`kube-proxy`实现了TCP/UDP反向代理，让容器对外提供稳定的服务。
* `scheduler`通过`apiserver`获取当前节点状态，调度pod到合适的Node上。接着`apiserver`下发命令给某个Node的`kubelet`，` kubelet`调用`container-runtime`启动容器。
* `controller-manager`也通过`apiserver`获取节点状态，监控可能的异常情况，再使用相应的手段区调节和恢复。

同时Kubernetes 使用主机名来区分集群里的节点，所以**每个节点的 hostname 必须不能重名**。

> 修改主机名

```shell
sudo vi /etc/hostname
```

### Addons：插件

**Addon 为Kubernetes增加扩展功能**。例如DNS、Dashboard等。

```shell
# 查看插件列表
minikube addons list

# 使用浏览器打开Dashboard页面
minikube dashboard
```

### API 对象

API 对象是指**用来描述系统的管理运维工作的理论层面抽象出来的概念**。

例如 Kubernetes 系统的唯一入口`apiserver`组件就是一个API对象，还有`Pod`、`Job`、`ConfigMap`等等都是API对象。这些组件往往提供了一套RESTful风格的通信方式。

API对象 通过 YAML来定义，其中 `apiVersion`、`kind`、`metadata` 这三个字段是必须存在的。其他字段还有 实体对象的`spec`，非实体对象的`data`等。

* 实体对象：Pod、Job等包含容器的对象。
* 非实体对象：ConfigMap、Secret等包含数据的配置对象。

```shell
# 查看当前 Kubernetes 版本支持的所有对象。
kubectl api-resources
```

关键字段：

| 字段         | 说明                                      | 值                                            |
| ------------ | ----------------------------------------- | --------------------------------------------- |
| `apiVersion` | 使用的api版本。（`/`前面代表不同的分组）  | `v1`、`apps/v1`、`batch/v1`等。               |
| `kind`       | api对象的类型。根据不同的对象有不同的值。 | `Pod`、`Job`、`Service`等。                   |
| `metadata`   | 标识对象的一些数据                        | name、labels                                  |
| `spec`       | 对象的状态                                | `containers`、`template`、`data`、`volumes`等 |

---

## Pod

### 什么是Pod

> Pod 是对容器的“打包”，里面的多个容器是一个整体，总是能够一起调度、一起运行，绝不会出现分离的情况。
>
> Pod也称为`容器组`、`逻辑主机`。
>

**Pod 是Kubernetes 最核心最基本的概念，Kubernetes中 其他所有的概念都是从pod衍生出来的**。把普通进程或应用加上权限限制就成不断抽象封装，是为了解决更加复杂的多应用联合运行问题，将多个应用作为一个整体使用。

Kubernetes 借鉴了 OOP的设计思想，保证单个Pod的职责单一，并以组合的方式来增强Pod的功能。所以扩展出了很多其他的衍生概念，如Job。

* **Pod 是 API 对象**。
* **Pod是k8s管理应用的最小单位**。其他所有任务都是通过 Pod 来再包装实现的。
* **Pod 负责编排处理容器**，解决更加复杂的多应用联合运行问题。它捆绑了一组存在密切协作关系的容器，容器之间共享网络和存储，在集群里必须一起调度一起运行。
* Pod 是容器之上的一层抽象，避免了对某一容器技术的依赖。
* Pod 默认在后台运行。
* Pod 都是运行在 Kubernetes 内部的私有网段里的，**外界无法直接访问**。需要进行端口映射才能使外部访问。

![img](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/b5a7003788cb6f2b1c5c4f6873a8b5cf-1683443671876-2.jpg)

### 使用YAML描述Pod

YAML是 Kubernetes的标准工作语言，Kubernetes 中的 API对象都是用过 YAML来定义的。

```shell
# 查看 pod 的字段说明：
kubectl explain pod
```

* **metadata**：定义表示对象的一些信息

  * name：名字，基本标识。

  * labels：标签，可以是任何数量的key-value，可以方便我们归类区分。

  * annotations:：注解。添加一些扩展信息。

* **spec.containers** ：spec 指定规格，用于管理和维护Pod，包含很多关键信息。其中最重要的是`containers` 它表示容器。

  * `ports`：**容器对外暴露的端口**。
  * `imagePullPolicy`：指定**镜像拉取策略**，默认为`IfNotPresent`。包括`Always/Never/IfNotPresent`。
  * `env`：定义container的环境变量，类似 `Dockerfile` 中的`ENV`。区别是它是运行时指定。
  * `command`：定义container 启动时要执行的指令。 相当于`Dockerfile` 里的 `ENTRYPOINT` 指令
  * `args`：指`command` 运行时的参数。
  * `resources`：申请资源。CUP最小单位是0.001(即1m)，1表示完整的一个CPU。
    * 

> 样例：
>
> * pod的名字是：`busy-pod`。并添加了几个标签：owner、env等
>
> * 包含一个busy容器对象，容器的镜像是：busybox:latest。
>
> * 拉取策略是：IfNotPresent。
>
> * env中定义了两个环境变量：os，debug。
>
> * 容器启动时执行 `/bin/echo` ，输出"ubuntu,on"。
> * annotations 中指定了更新说明。
> * resources中, requests：cpu时间 10m即 1%, 内存需求 100MB。并通过limits限制了使用的上限 。

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
  annotations: 
  	kubernetes.io/change-cause: v1, busybox=latest
   
spec:
  containers:
  - image: busybox:latest
    name: busy
    imagePullPolicy: IfNotPresent
    
    resources:
      requests: 
        cpu: 10m 
        memory: 100Mi 
      limits: 
        cpu: 20m 
        memory: 200Mi
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



### 创建Pod

```shell
kubectl apply -f busy-pod.yml
```

### 静态Pod

* 这类Pod不受Kubernetes系统的管控，不和 `apiserver`、`scheduler`发生联系。

* 同节点中的 `kubectl` 会定期检查YAML文件，来创建或删除静态Pod。

* 会先于Kubernetes集群进行启动。

它们的YAML文件存放在 `/etc/kubernetes/manifests` 下。里面包括了4个核心组件，这些组件都是以静态Pod的方式存在。

![image-20230219151332222](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230219151332222-1683443671876-3.png)



---

## 配置文件

通常来说应用程序都会有一个配置文件，方便我们进行调整和优化。比如说 `Nginx: nginx.conf`、`Redis: redis.conf `等。

Kubernetes 将配置抽象为API对象，使用YAML语言进行定义配置，在pod中引用配置，以组合方式实现动态配置。

* **ConfigMap**：**明文配置**。如 服务端口、运行参数等可以随意查询修改的参数。
* **Secret**：**密文配置**。如 密钥、证书等敏感信息。

> `ConfigMap` 和 `Secret`, 他们会被**存储在 etcd 里**。比较适合简单的数据存，存储限制1MB。

### ConfigMap

* 定义配置： `data`字段。
* 存储数据类型：静态的明文数据。

* 存储结构： `Key-Value`结构。

> 定义ConfigMap：cm.yml

```shell
# Config Map模板
export out="--dry-run=client -o yaml"
# kubectl create configmap <映射名称> <数据源>
# kubectl create cm <映射名称> <数据源>
kubectl create cm info --from-literal=k=v $out
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: info

data:
  count: '10'
  debug: 'on'
  path: '/etc/systemd'
  greeting: |
    say hello to kubernetes.
```

> 创建配置

```shell
# 创建或更新
kubectl apply  -f cm.yml
kubectl get cm
kubectl describe cm info
```

### Secret

Secret 和 ConfigMap 结构类似，负责存储密钥、证书等敏感信息。

* 定义配置： `data`字段。
* 存储数据类型：需要加密的敏感数据。默认是Base64编码。

* 存储结构： `Key-Value`结构。

> 定义Secret：secret.yml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: user

data:
  name: cm9vdA==  # root
  pwd: MTIzNDU2   # 123456
  db: bXlzcWw=    # mysql
```

### 如何使用配置

`valueFrom` 字段：指明环境env 变量值的**来源**，需要一个个指明。

* `configMapKeyRef`：来自 ConfigMap。
* `secretKeyRef`：来自Secret。
  * `name`：**API对象的 name**。
  * `key`：对象内的**存储数据的 key** 。

> `COUNT`环境变量，来自 ConfigMap，这个ConfigMap对象的名字是 `info`，数据是 info的data中的`count`字段。 

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-pod

spec:
  containers:
  - env:
      - name: COUNT
        valueFrom:
          configMapKeyRef:
            name: info
            key: count
      - name: GREETING
        valueFrom:
          configMapKeyRef:
            name: info
            key: greeting
      - name: USERNAME
        valueFrom:
          secretKeyRef:
            name: user
            key: name
      - name: PASSWORD
        valueFrom:
          secretKeyRef:
            name: user
            key: pwd

    image: busybox
    name: busy
    imagePullPolicy: IfNotPresent
    command: ["/bin/sleep", "300"]
```

> `envFrom`：将配置中所有字段全部导入。
>
> `prefix`：给数据中的key添加指定的前缀。例如 `CM_count`、`CM_debug`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-pod

spec:
  containers:
  - envFrom:
      - prefix: 'CM_'
      	configMapKeyRef:
        	name: info
      - prefix: 'SECRET_'
        secretKeyRef:
        	name: user
          
    image: busybox
    name: busy
    imagePullPolicy: IfNotPresent
    command: ["/bin/sleep", "300"]
```



```shell
kubectl apply -f env-pod.yml
kubectl exec -it env-pod -- sh

echo $COUNT
echo $GREETING
echo $USERNAME $PASSWORD
```



## 存储设备

### Volume

Volume 是 Kubernetes为 Pod定义的一个概念，相当于存储卷。我们**可以为Pod挂载多个Volume，用以提供数据**。和Docker将计算机的磁盘挂载到容器中类似，Pod相当于计算机。

* Volume 可以挂载 ConfigMap/Secret、持久卷、临时卷等等的存储类型。
* Volume 属于Pod，定义在Pod内，和容器是同级的。Pod挂载后就可以被Pod内容器挂载。
* Volume 适合用于大数据量的配置文件。

> 定义Volume

* `volumes`：**需要在pod 中定义 Volume**。（这里定义了两个volume，一个是引用 ConfigMap(info) 的 cm-vol 。一个是引用 Secret(user)的 sec-vol。）
  * `confiMap`：指定引用的 ConfigMap 配置。配置中的key-value数据变成了一个个文件，默认使用key作为文件名，value 中文件中的数据。`items` 可以指定仅加载指定项，并且重命名key生成的文件。
  * `secret`：指定引用的 Secret 配置。
  * `emptyDir`：emptyDir卷会在容器删除时一起被清除，崩溃时并不会被清除，可以作为缓存空间使用。
* `containers`：定义Pod。（这里定义了一个使用 busybox 镜像的容器busy，启动后会 sleep 300秒。）
* `volumeMounts`：配置需要使用的 volume。（这里busy容器将 `cm-vol` 挂载到 `/tmp/cm-items`下， `sec-vol`挂载到`/tmp/sec-items`下。）
  * `mountPath`：挂载路径。
  * `name`：指定 volume。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: vol-pod

spec:
  volumes:
  - name: cm-vol
    configMap:
      name: info
      items:
      - key: # 原文件名
        path: # 修改后的文件名
  - name: sec-vol
    secret:
      secretName: user
      
  - name: chache-vol
  	emptyDir: {}

  containers:
  - volumeMounts:
    - mountPath: /tmp/cm-items
      name: cm-vol
    - mountPath: /tmp/sec-items
      name: sec-vol

    image: busybox
    name: busy
    imagePullPolicy: IfNotPresent
    command: ["/bin/sleep", "300"]
```

进入容器内部查看：一个个文件就是之前的configmap配置。

![image-20230217171226284](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230217171226284-1683443671876-4.png)



>利用这个特性可以快速的建立配置文件。
>
>例如创建nginx配置文件。直接将 default.conf文件名定义为 key， 配置 作为 value。
>
>```yaml
>apiVersion: v1
>kind: ConfigMap
>metadata:
>  name: ngx-conf
>
>data:
>  default.conf: |
>    server {
>      listen 80;
>      location / {
>        default_type text/plain;
>        return 200
>          'srv : $server_addr:$server_port\nhost: $hostname\nuri : $request_method $host $request_uri\ndate: $time_iso8601\n';
>      }
>    }
>```
>
>通过 volume 加载配置。
>
>```yaml
>spec:
>  # ..........
>  template:
>	# ..........
>    spec:
>      volumes:
>      - name: ngx-conf-vol
>        configMap:
>          name: ngx-conf
>
>      containers:
>      - image: nginx:alpine
>        name: nginx
>        ports:
>        - containerPort: 80
>
>        volumeMounts:
>        - mountPath: /etc/nginx/conf.d
>          name: ngx-conf-vol
>```

---



### PersistentVolume

**PersistentVolume 专门用于表示持久存储设备。**

PV属于集群的系统资源，和Node同级。Pod 可以使用它，但是无法管理它。

存储设备的种类十分繁多，且不同设备之间的差异也很大。

所以Kubernetes新增了两个对象来作为中间层，将相关业务解耦出去。

* `PersistentVolume`：表示存储设备。
* `PersistentVolumeClaim`：负责向系统申请PV。申请成功后将会和PV绑定。PVC可以理解为一份需求说明，表明需要什么样子的设备。
* `StorageClass`：抽象了特定类型的存储系统，将存储设备归纳分组，从而更容易选择PV对象，简化了PVC和PV的绑定过程。简单的StorageClass 可以不用单独定义直接取个别名即可。

#### 定义PV

PV 就是 `PersistentVolume`，它表示存储设备。

> 定义一个PV对象：host-path-pv.yml

字段说明：

* **storageClassName**：对应StorageClass，可以任意起。使用时对应就行。
* **accessModes**：访问模式。结构为 ：【权限+节点挂载次数】storageClass
  * ReadWriteOnce（RWO）：可读可写，但只能被一个节点上的 Pod 挂载。
  * ReadOnlyMany：只读不可写，可以被任意节点上的 Pod 多次挂载。
  * ReadWriteMany：可读可写，可以被任意节点上的 Pod 多次挂载。
* **capacity**：指定存储容量。Ki/Mi/Gi。(在Kubernetes中`1Mi=1024x1024`，`1M=1000x1000`)

* **hostPath**：使用本地存储卷。其他还有nfs等。

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: host-10m-pv

spec:
  storageClassName: host-test
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 10Mi
  hostPath:
    path: /tmp/host-10m-pv/
```

```shell
kubectl apply -f host-path-pv.yml
kubectl get pv


# pvc 删除后， pv会变为 Released状态,而pvc只能和 Available状态的 pv绑定。
# 此时可以编辑pv, 删除claimRef 中对pvc的引用。
# 当然也可以删除重建整个pv
kubectl edit pv host-10m-pv

```

#### 定义PVC

PVC 就是 `PersistentVolumeClaim`，它负责向系统申请PV，里面定义了PV规格，表明需要什么样设备。申请成功后PVC就会和和PV绑定。

它的格式和 PersistentVolume类似。

> 定义一个PVC对象：host-path-pvc.yml

* resources.requests：需求多大的存储空间。
* storageClassName：需要和PV中的storageClassName对应。

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: host-5m-pvc

spec:
  storageClassName: host-test
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Mi
```

```shell
# 申请PV。
kubectl apply -f host-path-pvc.yml
kubectl get pvc
```

#### 定义Pod挂载PVC

挂载方式和 上方 Volume中挂载ConfigMap一样。只是改变了类型。

* `persistentVolumeClaim.claimName`：定义使用的PVC的名字。
* `volumeMounts`：指定Pod挂载路径和卷名。

> host-path-pod.yml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: host-pvc-pod

spec:
  volumes:
  - name: host-pvc-vol
    persistentVolumeClaim:
      claimName: host-5m-pvc

  containers:
    - name: ngx-pvc-pod
      image: nginx:alpine
      ports:
      - containerPort: 80
      volumeMounts:
      - name: host-pvc-vol
        mountPath: /tmp
```

```shell
kubectl apply -f host-path-pod.yml
```



---

### 网络存储(NFS)

hostPath的方式挂载的是本地存储，不适合在动态变化的集群中使用。应该使用网络存储。常见的网络存储有AWS、Azure、Ceph、NFS等。

> 部署NFS

* Worker节点需要安装对于网络存储的客户端。

* 涉及到的挂载路径需要预先创建好，否则Pod无法正常启动。

> 定义NFS PV：`nfs-static-pv.yml`

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-1g-pv

spec:
  storageClassName: nfs
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 1Gi

  nfs:
    path: /tmp/nfs/1g-pv
    server: 192.168.56.16
```

> 定义PVC：`nfs-static-pvc.yml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-static-pvc

spec:
  storageClassName: nfs
  accessModes:
    - ReadWriteMany

  resources:
    requests:
      storage: 1Gi
```

> Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nfs-static-pod

spec:
  volumes:
  - name: nfs-pvc-vol
    persistentVolumeClaim:
      claimName: nfs-static-pvc

  containers:
    - name: nfs-pvc-test
      image: nginx:alpine
      ports:
      - containerPort: 80

      volumeMounts:
        - name: nfs-pvc-vol
          mountPath: /tmp
```



### Provisoner

Provisioner 是一个能够**自动管理存储、创建 PV 的应用**，相当于是一个动态存储卷。

使用Provisioner 需要在 StorageClass中绑定一个Provisioner对象。由它来帮助我们创建符合PVC要求的PV对象。

Kubernetes中每类存储都有对应的Provisioner。

#### 配置部署

首先需要根据使用的Provisioner进行基础环境的部署。

例如 [NFS Provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)：它的部署涉及rbac.yaml、class.yaml 和 deployment.yaml这三个文件。

* class.yaml：不需要修改。定义了一个StorageClass。

  * `parameters`：指定了PV存储的策略。`archiveOnDelete: "false"`表示自动回收存储空间。
  * `provisioner`： 关联了具体的Provisoner。

  ```yaml
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: nfs-client
  provisioner: k8s-sigs.io/nfs-subdir-external-provisioner # or choose another name, must match deployment's env PROVISIONER_NAME'
  parameters:
    archiveOnDelete: "false"
    # onDelete: "retain"
  ```

* rbac.yaml：修改一下namespace，保证和deployment中部署的provisioner 一致即可。

* deployment.yaml：负责部署provisioner。需要修改namespace，并且将里面的SERVER和PATH改为我们nfs服务器的地址和里面共享目录。

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: nfs-client-provisioner
    labels:
      app: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: kube-nfs # 修改namespace
  spec:
    replicas: 1
    strategy:
      type: Recreate
    selector:
      matchLabels:
        app: nfs-client-provisioner
    template:
      metadata:
        labels:
          app: nfs-client-provisioner
      spec:
        serviceAccountName: nfs-client-provisioner
        containers:
          - name: nfs-client-provisioner
            image: chronolaw/nfs-subdir-external-provisioner:v4.0.2
            volumeMounts:
              - name: nfs-client-root
                mountPath: /persistentvolume
            env:
              - name: PROVISIONER_NAME
                value: k8s-sigs.io/nfs-subdir-external-provisioner
              - name: NFS_SERVER
                value: 192.168.56.16 # 修改IP
              - name: NFS_PATH
                value: /tmp/nfs # 修改目录
        volumes:
          - name: nfs-client-root
            nfs:
              server: 192.168.56.16 # 修改IP
              path: /tmp/nfs # 修改目录
  ```

```shell
kubectl apply -f class.yaml -f rbac.yaml -f deployment.yaml
```

#### 使用NFS

使用步骤基本没有改变，只是不在需要定义PV，Provisoner会帮我自动创建，只需要定义 PVC 和 pod即可

> nfs-dyn-10m-pvc.yml：定义PVC进行绑定，指定class.yaml 中的 storageClass。

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-dyn-10m-pvc

spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany

  resources:
    requests:
      storage: 10Mi
```

> nfs-dyn-pod.yml：定义pod

```yaml

apiVersion: v1
kind: Pod
metadata:
  name: nfs-dyn-pod

spec:
  volumes:
  - name: nfs-dyn-10m-vol
    persistentVolumeClaim:
      claimName: nfs-dyn-10m-pvc

  containers:
    - name: nfs-dyn-test
      image: nginx:alpine
      ports:
      - containerPort: 80

      volumeMounts:
        - name: nfs-dyn-10m-vol
          mountPath: /tmp
```

---



## 离线业务

Pod负责容器的管理，但是容器执行多久，什么时候执行等这些具有业务特性的功能并不属于Pod的负责范围，Kubernetes是通过组合方式来处理。如`Job/CronJob`处理 负责处理离线业务。

* **在线业务**：长时间一直运行的业务。如Nginx、MySQL等
  * `Deployment`：保证应用永久运行，可以实现应用的动态伸缩。

  * `Daemonset`：保证集群的每个节点上运行且仅运行一个 Pod。用于监控、日志等。

* **离线业务**：短时间运行且运行完成后就结束。如日志分析、数据建模、视频转码等。
  * `Job`：**临时任务**，直接执行。

  * `CronJob`：**定时任务**，特定时间或周期运行。

> 为了方便获取结果，Job 运行结束后不会立即删除。
>
> `ttlSecondsAfterFinished` 指定保留时限。

### Job

整体结构 和Pod的描述很相似，不过 Job是属于 `batch`组而不是`apps` 组。

![img](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/9b780905a824d2103d4ayyc79267ae28-1683443671876-5.jpg)

Job中重要的控制字段：

> 查看字段说明：

```shell
kubectl explain job
```

* `activeDeadlineSeconds`：设置 Pod **运行的超时时间**。
* `backoffLimit`：设置 Pod 的**失败重试次数**。
* `completions`：Job 完成需要运行多少个 Pod，默认是 1 个。
* `parallelism`：它与 completions 相关，表示**允许并发运行的 Pod 数量**，避免过多占用资源。
* `template`：应用模板，内嵌了一个 pod的描述，用于构建pod。这个pod由Job控制。

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sleep-job

spec:
  activeDeadlineSeconds: 15
  backoffLimit: 2
  completions: 4
  parallelism: 2

  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - image: busybox
        name: echo-job
        imagePullPolicy: IfNotPresent
        command:
          - sh
          - -c
          - sleep $(($RANDOM % 10 + 1)) && echo done
```

执行方式和pod相同。

```shell
kubectl apply -f echo-job.yml
```

> 查看 Job 和 Pod的状态

```shell
kubectl get job

kubectl get pod -w
```

pod的名字：job名字 + 随机字符串

![image-20230217015106545](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230217015106545-1683443671876-6.png)



### CronJob

spec 是一个层层套娃的结构。

 `schedule`指定任务的运行规则，使用的Cron 语法.

> `* * * * *` 一次为 分钟、小时、天、月、周。
>
> [crontab.guru](https://crontab.guru)

| 字符 | 说明             | 例子                                                |
| ---- | ---------------- | --------------------------------------------------- |
| `*`  | 任何值           | 【0 12 * * *】表示任何时刻的 12:00                  |
| `,`  | 多个字段的分割符 | 【0 1,2 * * *】1:00, 2:00                           |
| `-`  | 表示连续范围     | 【0 9-12 * * *】9:00,10:00,11:00,12:00 这四个时间点 |
| `/n` | n表示间隔        | 【*/1 * * * *】每隔一分钟执行一次。                 |

![img](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/yy352c661ae37dd116dd12c61932b43c-1683443671876-7.jpg)



## 应用部署

* Deployment/Daemonset 负责无状态应用的部署
* StatefulSet 专门用来负责管理有状态的应用的部署

### Deployment

**Deployment 是用来管理 Pod的API对象**。在集群中部署应用的多个实例，它会监控集群的状态，并将Pod部署在任意Worker节点，能够方便的实现应用伸缩。

代表了运维中的常见的在线业务。但不适用于监控、日志等这类每个节点都会需要的场景。因为Deployment 只保证了Pod实例的数量，但是保证会位于哪个节点。

> 定义Deployment：deploy.yml

* `replicas`：表示**Pod实例的期望数量**。即希望在集群中运行多少个 Pod实例。当实例不足时就会去自动创建，超过时会自动关闭。实现了 **应用伸缩**。
* `selector`：**筛选出被管理的Pod对象**。
  * `matchLabels`：按照 label 来匹配 Pod。必须和 `template`下的labels相同。
* `template`：和Job 一样，定义要运行的Pod模板。
* `minReadySeconds`：设置Pod准备就绪后的等待时间。可以方便观测更新过程。

```shell
# 模板
export out="--dry-run=client -o yaml"
kubectl create deploy ngx-dep --image=nginx:alpine $out
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: ngx-dep
  name: ngx-dep
  
spec:
  replicas: 2
  minReadySeconds: 15
  selector:
    matchLabels:
      app: ngx-dep
      
  template:
    metadata:
      labels:
        app: ngx-dep
    spec:
      containers:
      - image: nginx:alpine
        name: nginx
```

```shell
kubectl apply -f deploy.yml
# 查看Deployment
kubectl get deploy
```

> kubectl scale 可以**临时修改**允许实例数。
>
> 并不会修改配置中原来的数据，所以是临时修改。

```shell
kubectl scale --replicas=5 deploy ngx-dep
```



### DaemonSet

DaemonSet也是用于在线业务的API对象，在结构上和 Deployment类似。

两者最大的区别在于对Pod的调度策略不同，**DaemonSet会在集群的每个节点上运行且仅运行一个 Pod**。类似系统的守护进程。适合部署监控、日志等类型的应用。

> ds.yml

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: redis-ds
  labels:
    app: redis-ds

spec:
  selector:
    matchLabels:
      name: redis-ds

  template:
    metadata:
      labels:
        name: redis-ds
    spec:
      containers:
      - image: redis:5-alpine
        name: redis
        ports:
        - containerPort: 6379
```

```shell
kubectl apply -f ds.yml
# 查看Daemonset
kubectl get ds
```



应用部署

### StatefullSet

Deployment/DaemonSet 负责无状态应用的部署，而**StatefulSet 专门用来负责管理有状态的应用的部署**。它能处理多实例的依赖关系、启动顺序和网络标识等。

StatefulSet 创建的Pod的名字是固定的，每次启动都是同样配置的Pod，如：`redis-pv-sts-0`、`redis-pv-sts-1`。而且名字内存在一个编号，编号表示了**启动顺序**。

它的定义格式和 `Deployment` 类似。

#### 定义StatefullSet

* `serviceName`：指定关联的 Service。和Service中的name对应。
* `volumeClaimTemplates`：定义一个PVC 实现数据持久化存储。

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-pv-sts

spec:
  serviceName: redis-pv-svc

  volumeClaimTemplates:
  - metadata:
      name: redis-100m-pvc
    spec:
      storageClassName: nfs-client
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 100Mi

  replicas: 2
  selector:
    matchLabels:
      app: redis-pv-sts

  template:
    metadata:
      labels:
        app: redis-pv-sts
    spec:
      containers:
      - image: redis:5-alpine
        name: redis
        ports:
        - containerPort: 6379

        volumeMounts:
        - name: redis-100m-pvc
          mountPath: /data
```

```shell

kubectl apply -f redis-pv-sts.yml
kubectl get sts
kubectl get pod
```

#### 创建Service服务

Service会为StatefulSet管理的每一个Pod创建一个域名，保证 Pod 有稳定的网络标识。

格式：**Pod 名. 服务名. 名字空间.svc.cluster.local** 或 **Pod 名. 服务名. 名字空间**。例如 `redis-pv-sts-0.redis-pv-svc`。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis-pv-svc

spec:
  clusterIP: None
  selector:
    app: redis-pv-sts

  ports:
  - port: 6379
    protocol: TCP
    targetPort: 6379
```

```shell
kubectl apply -f redis-pv-sts.yml
```



## 调度、抢占和驱逐

Deployment和Daemonset都涉及到了对节点调度，在上述操作过程中，始终是没有Pod实例被调度到Master节点上的，这里涉及了**污点**和**容忍度**这两个概念。它们互相配合可以避免Pod被调度到不合适的节点上。

* **污点（taint）**：它是节点Node 的一个属性，和labels作用类似，不过打上的是负面标签，使节点会排斥一类特定的pod。Master节点包含了 `NoSchedule`这个污点， 所以默认情况下不会被调度。

* **容忍度（toleration）**：它是Pod的属性。表示这个Pod可以允许哪些污点。

> 查看节点的详细状态

```shell
kubectl describe node
```

### taint

已经创建的 pod并不会在添加污点后自动删除。

* `NoSchedule`：表示这个节点拒绝Pod调度。

```shell
# 添加污点, 之前以调度创建的 pod并不会在添加污点后自动删除。
kubectl taint node master node-role.kubernetes.io/master:NoSchedule
# 末尾添加 `-` 表示删除 
kubectl taint node master node-role.kubernetes.io/master:NoSchedule-
```

### toleration

已经创建的 pod会在将 toleration 取消后被关闭。

* **tolerations**：指定Pod的容忍度。此处设置容忍master节点的NoSchedule，这样master节点也会创建pod。

```shell
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: redis-ds
  labels:
    app: redis-ds

spec:
  selector:
    matchLabels:
      name: redis-ds

  template:
    metadata:
      labels:
        name: redis-ds
    spec:
      containers:
      - image: redis:5-alpine
        name: redis
        ports:
        - containerPort: 6379

      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
        operator: Exists
```

## namespace

Kubernetes中的 **namespace（命名空间） 用于对 API 对象的隔离和分组**。

同时也可以**通过namespace和ResourceQuota来设置资源配额**。

Kubernetes 在初始化集群的时候已经预设 4 个名字空间：default、kube-system、kube-public、kube-node-lease。	

* default：API对象默认这个命名空间中。
* kube-system：包含apiserver、etcd 等核心组件的 Pod。

```shell
# 查看集群里有哪些 namespace
kubectl get ns
```

![image-20230219191042949](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230219191042949-1683443671876-8.png)

定义namespace：

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: custom-ns
```

```shell
kubectl apply -f custom-ns.yml

# 也可以简单的直接创建namespace
kubectl create ns custom-ns
```

使用namespace：

在metadata中添加namespace字段，指定命名空间。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ngx
  namespace: custom-ns

spec:
  containers:
  - image: nginx:alpine
    name: ngx
```

```shell
# 根据命名空间查询信息
kubectl get pod -n custom-ns
```

---

## 域名

kubernetes 为每个Pod、Service等都分配了域名，其中也将 namespace作为域名一部分，避免发生冲突。

* service：
  * **对象. 名字空间.svc.cluster.local**：`ngx-svc.default.svc.cluster.local`
  * **对象名.命名空间**：`ngx-svc.default`
  * **对象名**：`ngx-svc`
* pod：
  * **IP 地址. 名字空间.pod.cluster.local**：`10-10-2-8.defalut.pod.cluster.local`

---

## Service

Service 是集群内部的由 kube-proxy 控制的四层**负载均衡**，用来解决**服务发现**的问题。支持微服务以及服务网格这样的应用架构。它的共组原理和 LVS、Nginx差不多。可以从`Pod`、`Deployment`、`DaemonSet`中创建Service，由Service负责

* Service 拥有一个固定的 IP 地址。
* Service 是四层的负载均衡，基于的是iptables规则。
* Service 自动管理维护动态变化的Pod。
* 客户端访问Service时，会按一定策略转发给内部的Pod。
* Service 基于 DNS 插件支持域名。

### 创建Service

```shell
### 创建 Service 模板
# 从一个名为ngx-dep的Deployment 中创建Service
# 将Service的80端口 和 容器的80端口 进行关联
# --port：映射端口
# --target-port： 容器端口
# --type：可以指定类型。nodeport等。
kubectl expose deploy ngx-dep --port=80 --target-port=80 $out
```

* `selector`：过滤需要代理的Pod。此处关联了deploy ngx-dep中的Pod。
* `clusterIP`: 指定service的IP。None表示不需要分配IP。
* `ports`：端口及协议。此处将Service的80端口 和 容器的80端口关联。
  * `port`：映射端口。即在集群内部可以使用80端口访问Service。
  * `targetPort`：容器端口。对应containerPort
  * `protocol`：使用的协议。

```shell
apiVersion: v1
kind: Service
metadata:
  name: ngx-svc
  
spec:
  #clusterIP: None
  selector:
    app: ngx-dep
    
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
```

```shell
# 创建
kubectl apply -f svc.yml
# 查看Service
kubectl get svc
# 查看 ngx-svc 的详细情况
kubectl describe svc ngx-svc
```

* Endpoints： 管理的Pod的ip。表示`10.102.239.88` 这个ip代理了`172.17.0.5`和`172.17.0.6`这个两个IP。

* Type：表示负载均衡类型。

![image-20230219180128128](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230219180128128-1683443671876-9.png)

### Service Type

Type 表示负载均衡类型。

* **ClusterIP**：**默认类型，是对集群内部 Pod的负载均衡，只能在集群内部访问**。此处是ngx-svc 80端口。

  ![image-20230219181955143](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230219181955143-1683443671876-10.png)

* **NodePort**：除了内部能访问之外，还允许外部访问，它**在每个节点上创建一个对外暴露的节点端口，它通过kube-proxy路由到service的port中，再通过service负载均衡到容器中**。范围是(30000~32767)，下方是32280，它映射 ngx-svc 的80端口，外部可以使用 **节点IP:32280（192.168.56.5:32280）**的方式来访问。

  映射关系：**node:32280 -> service:80 -> container:80**  。

  ![image-20230219181857821](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230219181857821-1683443671876-11.png)



### Headless Service

Headless Service就是没有指定Cluster IP的Service，即 `clusterIP: None`。Headless Service的解析结果不是一个Cluster IP，而是它所关联的所有Pod的IP列表。

StatefulsSet 配合  Headless Service使用时，可以通过 域名来访问pod

```shell
${pod.name}.${headless service.name}.${namespace}.svc.cluster.local
```



## Ingress

由于Service是四层的负载均衡，但是大多数应用都是HTTP/HTTPS协议，位于七层。而 Ingress 就是用于处理七层负载均衡的对象。

* `Ingress`：主要用于定义路由规则。
* `Ingress Class`：负责将路由规则分组然后交给不同的Ingress Controller处理。
* `Ingress Controller`：主要负责处理Ingress 规则、管理出入口流量等。相当于反向代理或网关。。

### Ingress

> 创建模板
>
> * --class：指定 Ingress Class对象。
> * --rule：指定路由规则。将HTTP转发给Service。格式：`URI=Service`。

```shell
export out="--dry-run=client -o yaml"
kubectl create ing ngx-ing --rule="ngx.test/=ngx-svc:80" --class=ngx-ink $out
```

* `ingressClassName`：引用的Ingress Class 的名字
* `rules`：定义路由规则。
  * pathType：指定path的匹配规则。Exact、Prefix。
  * backend：指定转发的Service对象。

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ngx-ing
  
spec:

  ingressClassName: ngx-ink
  
  rules:
  - host: ngx.test
    http:
      paths:
      - path: /
        pathType: Exact
        backend:
          service:
            name: ngx-svc
            port:
              number: 80
```

```shell
kubectl get ing
```

![image-20230219205509066](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230219205509066-1683443671876-12.png)

### Ingress Class

Ingress 和 Ingress Controller 的中间连接层，方便我们将路由规则分组然后交给不同的Ingress Controller处理，降低了维护成本。

* controller：指定使用什么 Ingress Controller。
* name: 指定 Ingress Class，使用同一个 Ingress Class的 Ingress会由同一个 Ingress Controller处理。

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: ngx-ink

spec:
  controller: nginx.org/ingress-controller
```

```shell
kubectl get ingressclass
```

![image-20230219205500221](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230219205500221-1683443671876-13.png)

### Ingress Controller

**是真正的集群入口，主要负责应用Ingress的规则进行调度和分发流量**。此外还有反向代理、TLS卸载、安全防护等功能。自身也是一个Pod，需要通过 Service对外暴露。

* 主要负责处理Ingress 规则。 
* 管理出入口流量。
* 身份认证。
* 网络应用防火墙。
* ......

它的具体实现也有很多：

* 社区的 [Kubernetes Ingress Controller](https://github.com/kubernetes/ingress-nginx)。
* Nginx 公司的 [Nginx Ingress Controller](https://github.com/nginxinc/kubernetes-ingress)。
* 基于 OpenResty 的 [Kong Ingress Controller](基于 OpenResty 的 Kong Ingress Controller)。

* ....

从[nginxinc/kubernetes-ingress](https://github.com/nginxinc/kubernetes-ingress)的 deployments目录中选择需要的文件。

![image-20230220190726412](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230220190726412-1683443671876-14.png)



```shell
# 创建 nginx-ingress 命名空间、账号和权限。
# 为了访问 apiserver 获取 Service、Endpoint 信息
kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac


# 创建 ConfigMap 和 Secret
# 用来配置 HTTP/HTTPS 服务
kubectl apply -f common
kubectl apply -f common/crds


```

修改`deployment/nginx-ingress.yaml` 部署文件：

* metadata：修改 name: ngx-kic-dep
* spec.selector：修改 app: ngx-kic-dep
* spec.template.labels：修改 app: ngx-kic-dep
* containers.image：调整镜像版本
* containers.args：添加 -ingress-class=ngx-ink。指向自己的Ingress Class。
* **hostNetwork**：让 Pod 能够使用宿主机的网络。类似NodePort

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ngx-kic-dep  # 修改
  namespace: nginx-ingress

spec:
  replicas: 1
  selector:
    matchLabels:
      app: ngx-kic-dep # 修改

  template:
    metadata:
      labels:
        app: ngx-kic-dep # 修改

    spec:
      serviceAccountName: nginx-ingress

      # use host network 让 Pod 能够使用宿主机的网络。类似NodePort
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet

      containers:

      - image: nginx/nginx-ingress:2.2-alpine # 修改
        imagePullPolicy: IfNotPresent
        name: nginx-ingress
        ports:
        - name: http
          containerPort: 80
        - name: https
          containerPort: 443
        - name: readiness-port
          containerPort: 8081
        - name: prometheus
          containerPort: 9113
        readinessProbe:
          httpGet:
            path: /nginx-ready
            port: readiness-port
          periodSeconds: 1
        securityContext:
          allowPrivilegeEscalation: true
          runAsUser: 101 #nginx
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        args:
          - -ingress-class=ngx-ink # 指向自己的Ingress Class
          - -health-status
          - -ready-status
          - -nginx-status
          - -enable-snippets

          - -nginx-configmaps=$(POD_NAMESPACE)/nginx-config
          - -default-server-tls-secret=$(POD_NAMESPACE)/default-server-secret

```

## 网络模型

Kubernetes 使用的是“IP-per-pod”网络模型，为每个 Pod 分配了唯一的 IP 地址。并专门制定了**CNI（Container Networking Interface）**标准来规范网络模型的实现方式。开发者只要遵循这个规范就可以接入 Kubernetes，为 Pod 创建虚拟网卡、分配 IP 地址、设置路由规则。

常见的网络插件有：Flannel、Calico、Cilium 等。

CNI插件类型：

* Overlay：覆盖。在真实网络之上构建一个 逻辑网络对Pod网络数据进行封包、拆包。适应性强，性能低。
* Route：路由。使用系统内置的路由功能实现Pod跨主机通信。性能好，依赖底层网络。
* Underlay：直接用底层网络来实现CNI。强依赖底层的硬件和网络，性能最好但是不灵活。

```shell
#
route
# 查看网桥信息
brctl show

```



## 运维

常见的运维操作有应用更新、版本回退、应用伸缩等

结合DaemonSet/Deployment/StatefulSet

### 应用版本

Kubernetes使用摘要算法计算YAML中 template 的 **Hash 值作为 版本号**。

![image-20230222170049649](./Kubernetes%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230222170049649-1683443671876-15.png)

Pod中的 `767bbdccb5` 就是Hash值的前几位，作为版本号。

### 应用伸缩

动态的改变应用的数量，使用`kubectl scale`命令来实现应用伸缩。

```shell
# kubectl scale
kubectl scale --replicas=5 deploy ngx-dep
```

### 滚动更新

`kubectl apply`执行应用更新。旧版本将会缩容和新版本扩容交替进行，实现无感知的应用升降级。

```shell
kubectl apply -f ngx-dep.yml
```

使用`kubectl rollout` 命令来管理更新过程。

> 更新说明：`metadata.annotations`中添加
>
> kubernetes.io/change-cause: v1, ngx=1.21

```shell
# 查看更新过程
kubectl rollout status deployment ngx-dep
# 暂停
kubectl rollout pause deployment ngx-dep
# 继续
kubectl rollout resume deployment ngx-dep

# 查看 ngx-dep 更新历史版本，保存的是YAML。
kubectl rollout history deploy ngx-dep
# --revision 查看版本详情
kubectl rollout history deploy --revision=3 ngx-dep

# 回退到上一个版本
kubectl rollout undo deploy ngx-dep
# 回退到指定版本 --to-revision
kubectl rollout undo deploy ngx-dep --to-revision=4
```

### 资源限额

可以通过 resources 字段来配置Pod容器的资源。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ngx-pod-resources

spec:
  containers:
  - image: nginx:alpine
    name: ngx

    resources:
      requests:
        cpu: 10m
        memory: 100Mi
      limits:
        cpu: 20m
        memory: 200Mi
```

通过namespace和ResourceQuota来设置资源配额。

### 容器状态探针

用于探测容器当前的状态，主动对容器进行健康检查，当发现不可用时就会重启容器。

探针类型：

* **startupProbe：启动探针（Startup）**，用来检查应用是否已经启动成功，适合那些有大量初始化工作要做，启动很慢的应用。
* **livenessProbe：存活探针（Liveness）**，用来检查应用是否正常运行，是否存在死锁、死循环。
* **readinessProbe：就绪探针（Readiness）**，用来检查应用是否可以接收流量，是否能够对外提供服务。

探测方式：

* exec：执行Shell 命令，比如 ps、cat 等等。
* tcpSocket：使用 TCP 协议尝试连接容器的指定端口。
* httpGet：连接端口并发送 HTTP GET 请求。

定义方式：探针是定义在容器中的。

* periodSeconds：探测间隔。默认10s探测一次。
* timeoutSeconds：探测超时时间。超时则表示失败，默认1s。
* successThreshold：成功阈值。即连续成功指定次数才算真的正常。
* failureThreshold：失败阈值。连续失败几次才算真的失败。

```yaml
# 定义Nginx，定义 HTTP路径 `/ready` ，对外访问。
apiVersion: v1
kind: ConfigMap
metadata:
  name: ngx-conf

data:
  default.conf: |
    server {
      listen 80;
      location = /ready {
        return 200 'I am ready';
      }
    }
    
---   
# Pod
apiVersion: v1
kind: Pod
metadata:
  name: ngx-pod-probe

spec:
  volumes:
  - name: ngx-conf-vol
    configMap:
      name: ngx-conf

  containers:
  - image: nginx:alpine
    name: ngx
    ports:
    - containerPort: 80
    volumeMounts:
    - mountPath: /etc/nginx/conf.d
      name: ngx-conf-vol

    startupProbe:
      periodSeconds: 1
      exec:
        command: ["cat", "/var/run/nginx.pid"]

    livenessProbe:
      periodSeconds: 10
      tcpSocket:
        port: 80

    readinessProbe:
      periodSeconds: 5
      httpGet:
        path: /ready
        port: 80

```

```shell
kubectl logs ngx-pod-probe
kubectl get pod

#
kubectl logs ngx-pod-probe

```

### Metrics Server

Metrics Server 能够收集系统的核心资源指标。

```shell
# 查看集群的状态
kubectl top
```

### HorizontalPodAutoscaler

从 Metrics Server 获取应用的运行指标，再实时调整 Pod 数量，实现了应用的自动水平伸缩功能。

### Prometheus

Prometheus 云原生监控领域的“事实标准”。

* PromQL：查询数据
* Grafana：提供可视化监控图形界面，展示各种指标信息、自动报警等。



### Dashboard

[GitHub - kubernetes/dashboard: General-purpose web UI for Kubernetes clusters](https://github.com/kubernetes/dashboard)

* Dashboard 使用 Deployment 部署了一个实例，端口号是 8443。
* Dashboard  所有的对象都属于`kubernetes-dashboard`名字空间。
* 启用 Liveness 探针，使用 HTTPS 方式检查存活状态。
* Service 对象使用的是 443 端口，映射了 Dashboard 的 8443 端口。



```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# 或者下载后执行 apply
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml -o recommended.yaml

kubectl apply -f recommended.yaml
```



---

## 参考资料

[极客时间《Kubernetes 入门实战课》](https://time.geekbang.org/column/intro/100114501)

[Kubernetes 文档 | Kubernetes](https://kubernetes.io/zh-cn/docs/home/)
