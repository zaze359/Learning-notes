# Kubernetes集群配置

记录一些配置，方便后续使用时参考。

## NFS

首先需要选择一个机器搭建NFS：[NFS网络存储](../linux/NFS网络存储.md)

然后在集群中使用 `NFS Provisioner` 来部署 NFS。

* Worker节点需要安装对于网络存储的客户端。

* 涉及到的挂载路径需要预先创建好，否则Pod无法正常启动。



### NFS 配置

最基础的 NFS 配置

> 定义NFS PV：`nfs-static-pv.yml`
>
> 直接简单建立一个 storageClass： nfs-client

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-1g-pv

spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 1Gi

  nfs:
    path: /home/nfs
    server: 192.168.56.22
```

> 定义 一个 pvc 和 pod来使用 Volum

```yaml
# 定义PVC：nfs-static-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-static-pvc

spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany

  resources:
    requests:
      storage: 1Gi

---
# pod
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



### NFS Provisioner 配置

> class.yaml
>
> 定义了一个StorageClass。后面我定义PVC 会用到

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

> rbac.yaml

修改一下namespace，保证和deployment中部署的provisioner 一致即可。

> deployment.yaml
>
> 负责部署provisioner。需要修改namespace，并且将里面的SERVER和PATH改为我们nfs服务器的地址和里面共享目录。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  
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

### NFS 使用

Provisoner会帮我自动创建PV，所以不用定义PV，只需要定义 PVC 和 pod即可。

> 定义PVC 
>
> nfs-dyn-10m-pvc.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-dyn-10m-pvc

spec:
  storageClassName: nfs-client # class.yaml 中的 storageClass
  accessModes:
    - ReadWriteMany

  resources:
    requests:
      storage: 10Mi
```

> 定义pod
>
> nfs-dyn-pod.yml

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





## MariaDB

### 部署

* ConfigMap：定义数据库相关参数配置。
* Deployment：负责部署。为了保证数据一致性，一个实例即可。
* Service：映射3306端口。

```shell
export out="--dry-run=client -o yaml"
# ConfigMap: maria-cm
kubectl create cm maria-cm --from-literal=k=v $out
# Deployment: maria-dep
kubectl create deploy maria-dep --image=mariadb:10 --port=3306 $out
# Service: maria-svc
kubectl expose deploy maria-dep --name=maria-svc --port=3306 $out
```

> maria-sts.yml

```yaml
# ConfigMap: maria-cm
apiVersion: v1
kind: ConfigMap
metadata:
  name: maria-cm

data:
  DATABASE: 'db'
  USER: 'wp'
  PASSWORD: '123'
  ROOT_PASSWORD: '123'

---
# StatefulSet: maria-sts
apiVersion: apps/v1
kind: StatefulSet
metadata:
  labels:
    app: maria-sts
  name: maria-sts

spec:
  # headless svc
  serviceName: maria-svc

  # pvc
  volumeClaimTemplates:
  - metadata:
      name: maria-100m-pvc
    spec:
      storageClassName: nfs-client
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 100Mi

  replicas: 1
  selector:
    matchLabels:
      app: maria-sts

  template:
    metadata:
      labels:
        app: maria-sts
    spec:
      containers:
      - image: mariadb:10
        name: mariadb
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3306

        envFrom:
        - prefix: 'MARIADB_'
          configMapRef:
            name: maria-cm

        volumeMounts:
        - name: maria-100m-pvc
          mountPath: /var/lib/mysql

---

# headless servicee: maria-svc.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: maria-sts
  name: maria-svc

spec:
  clusterIP: None
  selector:
    app: maria-sts
    
  ports:
  - port: 3306
    protocol: TCP
    targetPort: 3306
```

```shell
# 创建
kubectl apply -f maria-sts.yml
#
kubectl get deploy
kubectl get pod -o wide
kubectl get svc -o wide

# 进入 maria-pod sh
kubectl exec -it maria-dep-767bbdccb5-2xpkx -- sh
```

### mariadb命令

```shell
# 登录数据库
mysql -u wp -p
#
show databases;
show tables;
```

---

## mongo db

```shell
kubectl create ns mongo
```

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongo-1g-pv

spec:
  storageClassName: nfs-mongo
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 1Gi

  nfs:
    path: /home/nfs/mongo
    server: 192.168.56.22
```

[Running MongoDB With Kubernetes | MongoDB](https://www.mongodb.com/kubernetes)

使用 StatefulSet 部署 mongodb，需要先配置 NFS。

### Headless Service

```yaml
# headless service: mongo-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: mongo-svc
  namespace: mongo
  labels:
    app: mongo-sts
  #annotations:
  #  zaze.io/change-cause: v1, mongo-svc
    
spec:
  clusterIP: None # 不分配ip
  selector:
    app: mongo-sts
  
  ports:
  - name: http27017
    port: 27017
    protocol: TCP
    targetPort: 27017
```





### ConfigMap

```yaml
# ConfigMap: mongo-cm
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongo-cm
  namespace: mongo

data:
  INITDB_ROOT_USERNAME: 'root'
  INITDB_ROOT_PASSWORD: '123'
```

### StatefulSet

```yaml
# StatefulSet: mongo-sts.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo-sts
  namespace: mongo
#  labels:
#    app: mongo-sts
spec:
  # headless svc
  serviceName: mongo-svc

  # pvc
  volumeClaimTemplates:
  - metadata:
      name: mongo-100m-pvc # pvc name
    spec:
      storageClassName: nfs-mongo # sc
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 100Mi # size

  replicas: 1 # only one
  
  selector:
    matchLabels:
      app: mongo-sts

  template:
    metadata:
      labels:
        app: mongo-sts
        role: mongo
        env: dev
        
    spec:
      containers:
      - image: mongo:6.0.5
        name: mongodb
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 27017
          protocol: TCP

        envFrom:
        - prefix: 'MONGO_'
          configMapRef:
            name: mongo-cm

        volumeMounts:
        - name: mongo-100m-pvc
          mountPath: /data/db # 这个是mongodb 的db存储路径
```

### mongo命令

> mongo命令 从6.0开始无法使用

```shell
kubectl exec -it mongo-sts-0 -n mongo -- bash

ps -ef | grep mongo

# shell 连接 mongo
mongosh  -u root -p 123

# 查看数据库
show dbs

# 默认进入 test.db

# 创建一个用户, test
# test用户对应 test.db 有读写权限
db.createUser({
	user: "test",
	pwd: "123",
	roles: [
		{role: "readWrite", db: "test"}
	]
})

# 查询用户
show users

# 切换数据库，不存在时会直接创建这个库
use dev

# 查询所有集合
show collections;
# 从集合中查询数据
db.user.find();
# 删除集合
db.user.drop();
# 删除指定名字的数据
db.user.remove({"name":"hutao"})
```



## Nginx



```yaml

```



## Redis

### ConfigMap

创建一个 `redis.conf`  redis 配置文件

```properties
# 基础配置
# 绑定的ip
bind 0.0.0.0
# 端口
prot 6379
# 是否守护进程运行
daemonize no
# 设置连接密码
requirepass 123456

# 是否使用 AOF持久化
appendonly yes

# 集群配置
# 是否开启集群
cluster-enabled yes
# 集群节点信息文件
cluster-config-file /var/lib/redis/node.conf
# 等待节点超时
cluster-node-timeout 5000
```

```shell
export out="--dry-run=client -o yaml"
# 根据 redis.conf 文件生成 configmap 模板
kubectl create configmap redis-conf --from-file=redis.conf $out

kubectl create configmap redis-conf --namespace=redis --from-file=redis.conf $out

# 直接根据 redis.conf 文件创建 configmap
kubectl create configmap redis-conf --from-file=redis.conf
```

```yaml
apiVersion: v1
data:
  redis.conf: |
    # 基础配置
    # 绑定的ip
    bind 0.0.0.0
    # 端口
    prot 6379
    # 是否守护进程运行
    daemonize no
    # 设置连接密码
    requirepass 123

    # 是否使用 AOF持久化
    appendonly yes

    # 集群配置
    # 是否开启集群
    cluster-enabled yes
    # 集群节点信息文件
    cluster-config-file /var/lib/redis/node.conf
    # 等待节点超时
    cluster-node-timeout 5000
kind: ConfigMap
metadata:
  creationTimestamp: null
  name: redis-conf
  namespace: redis
```

### Headless Service

```yaml
# Headless Service
apiVersion: v1
kind: Service
metadata:
  name: redis-svc
  namespace: redis
  labels:
    app: redis
    
spec:
  clusterIP: None # 不分配ip
  selector:
    app: redis
  
  ports:
  - name: http6379
    port: 6379
    protocol: TCP
    targetPort: 6379

```

### Out Service

配置一个对外访问的 service，方便测试。

```yml
# Service
apiVersion: v1
kind: Service
metadata:
  name: redis-out-svc
  namespace: redis
  labels:
    app: redis
    
spec:
  selector:
    app: redis

  ports:
  - name: redis-port
    port: 6379
    protocol: TCP
    targetPort: 6379
    nodePort: 30379
    
  type: NodePort
```

### StatefulSet

```yaml
# StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-app
  namespace: redis

spec:
  # headless svc
  serviceName: "redis-svc"
  replicas: 3 # 
  selector:
    matchLabels:
      app: redis

  template:
    metadata:
      labels:
        app: redis
        appCluster: redis-Cluster
        env: dev
        
    spec:
      terminationGracePeriodSeconds: 20
      containers:
      - image: redis:7.0.11-alpine
        name: redis
        imagePullPolicy: IfNotPresent
        command: # 启用配置
          - "redis-server"
        args:
          - "/etc/redis/redis.conf"
          - "--protected-mode"
          - "no"
        ports:
        - containerPort: 6379
          protocol: TCP

        volumeMounts: # 挂载
        - name: "redis-conf"
          mountPath: "/etc/redis"
        - name: "redis-data"
          mountPath: "/var/lib/redis"
      volumes:
      - name: "redis-conf"
        configMap:
          name: "redis-conf"
      - name: "redis-data"
        emptyDir: {} # 使用emptyDir卷作为缓存空间
```

### Redis命令

```shell
kubectl exec -it redis-app-0 -n redis -- sh

# 启用配置
# redis-server /etc/redis/redis.conf
#
redis-cli
redis-cli -h localhost -p 6379

# 临时设置密码
#config set requirepass 123456

#
keys *
```



## Nginx Ingress Controller

以 wordpress为例

### 处理 svc 的跨命名空间问题

使用 ExternalName Service 来处理。

* externalName：对象. 名字空间.svc.cluster.local

```yml
# wp-ext-svc.yml
kind: Service
apiVersion: v1
metadata:
  name: wp-ext-svc
spec:
  type: ExternalName
  externalName: wp-svc.wp.svc.cluster.local
```

### Ingress Class

将路由规则分组分发

```yaml
# wp-ink.yml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: wp-ink

spec:
  controller: nginx.org/ingress-controller
```

### Ingress 

定义路由规则

```yaml
# wp-ing.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wp-ing
spec:
  ingressClassName: wp-ink # IngressClass
  rules:
  - host: wp.test # 匹配 host
    http:
      paths:
      - backend:
          service:
            name: wp-ext-svc # service name
            port:
              number: 6379 # 端口
        path: /
        pathType: Prefix
```

### Ingress Controller

从 [nginxinc/kubernetes-ingress](https://github.com/nginxinc/kubernetes-ingress) 的 deployments目录中选择需要的文件。

```shell
# 这些配置不需要修改
kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac
kubectl apply -f common
kubectl apply -f common/crds
```

复制`deployment/nginx-ingress.yaml` 部署文件，并修改：

```yaml
# wp-kic-dep.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wp-kic-dep
  namespace: nginx-ingress

spec:
  replicas: 1
  selector:
    matchLabels:
      app: wp-kic-dep

  template:
    metadata:
      labels:
        app: wp-kic-dep

    spec:
      serviceAccountName: nginx-ingress

      # use host network  让 Pod 能够使用宿主机的网络。类似NodePort
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet

      containers:
      - image: nginx/nginx-ingress:2.2-alpine # nginx 镜像
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
          runAsUser: 101 # nginx
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
          - -ingress-class=wp-ink # 改为自己的 IngressClass
          - -health-status
          - -ready-status
          - -nginx-status
          - -enable-snippets

          - -nginx-configmaps=$(POD_NAMESPACE)/nginx-config
          - -default-server-tls-secret=$(POD_NAMESPACE)/default-server-secret
```

### 部署

```shell
kubectl apply -f wp-ing.yml -f wp-ink.yml -f wp-kic-dep.yml
```

### 测试访问

```shell
telnet 192.168.56.21 30379
```



