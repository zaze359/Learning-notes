# kubeadm部署WordPress

[Kubernetes环境配置](./Kubernetes环境搭建.md)

* 搭建kubeadm环境。
* Deployment部署实例。
* Service作为集群内部的负载均衡，内部使用域名访问WorkPress 、MariaDB等服务。
* Ingress Controller作为反向代理。

执行配置：

```shell
# nginx-ingress
kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac
kubectl apply -f common
kubectl apply -f common/crds

#
kubectl apply -f wp-maria.yml

kubectl apply -f wp.yml

kubectl apply -f wp-ink.yml -f wp-ing.yml -f wp-kic-dep.yml
```

## 集群部署

| 虚拟机/实机     |                                                    |      |
| --------------- | -------------------------------------------------- | ---- |
| kubeadm-console | console 节点，我们主要就是来操作这个节点控制集群。 |      |
| kubeadm-master  | master 节点                                        |      |
| worker          | worker 节点                                        |      |
| nfs             | 网络存储                                           |      |

## NFS

首先需要选择一个机器搭建NFS：[NFS网络存储](../linux/NFS网络存储.md)

然后在集群中使用 `NFS Provisioner` 来部署 NFS。

* Worker节点需要安装对于网络存储的客户端。

* 涉及到的挂载路径需要预先创建好，否则Pod无法正常启动。

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

> wp-maria-sts.yml

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

# Service: maria-svc
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
kubectl apply -f wp-maria-sts.yml
#
kubectl get deploy
kubectl get pod -o wide
kubectl get svc -o wide
```

> 验证数据是否正常

```shell
# 启动 maria-pod sh
kubectl exec -it maria-dep-767bbdccb5-2xpkx -- sh
# 登录数据库
mysql -u wp -p
#
show databases;
show tables;
```

## WordPress

* ConfigMap：定义WordPress配置。HOST使用域名指向MariaDB。
* Deployment：部署多个WorkPress实例。

```shell
export out="--dry-run=client -o yaml"
# ConfigMap: wp-cm
kubectl create cm wp-cm --from-literal=HOST=maria-svc --from-literal=NAME='db' $out
# Deployment: wp-dep
kubectl create deploy wp-dep --image=wordpress:5 --port=80 $out
# Service: wp-svc
kubectl expose deploy wp-dep --name=wp-svc --port=3306 --type=nodeport $out
```

```yaml
# ConfigMap: wp-cm
apiVersion: v1
kind: ConfigMap
metadata:
  name: wp-cm

data:
  HOST: 'maria-sts-0.maria-svc'
  USER: 'wp'
  PASSWORD: '123'
  NAME: 'db'
  
---
# Deployment: wp-dep
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: wp-dep
  name: wp-dep
spec:
  replicas: 2
  selector:
    matchLabels:
      app: wp-dep
  template:
    metadata:
      labels:
        app: wp-dep
    spec:
      containers:
      - image: wordpress:5
        name: wordpress
        ports:
        - containerPort: 80
        
        envFrom:
        - prefix: 'WORDPRESS_DB_'
          configMapRef:
            name: wp-cm

---
# Service: wp-svc
apiVersion: v1
kind: Service
metadata:
  labels:
    app: wp-dep
  name: wp-svc

spec:
  ports:
  - name: http80
    port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 30088

  selector:
    app: wp-dep
  type: NodePort
```

```shell
kubectl apply -f wp.yml
```

## Nginx Ingress Controller

### Ingress Class

将路由规则分组分发

```yaml
# wp-ink
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
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wp-ing
spec:
  ingressClassName: wp-ink
  rules:
  - host: wp.test
    http:
      paths:
      - backend:
          service:
            name: wp-svc
            port:
              number: 80
        path: /
        pathType: Prefix
```

### Ingress Controller

从[nginxinc/kubernetes-ingress](https://github.com/nginxinc/kubernetes-ingress)的 deployments目录中选择需要的文件。

```shell
# 
kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac
kubectl apply -f common
kubectl apply -f common/crds
```

复制`deployment/nginx-ingress.yaml` 部署文件，并修改：

```yaml
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

      # use host network
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet

      containers:
      #- image: nginx/nginx-ingress:2.2.0
      - image: nginx/nginx-ingress:2.2-alpine
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
          - -ingress-class=wp-ink # 改为自己的 IngressClass
          - -health-status
          - -ready-status
          - -nginx-status
          - -enable-snippets

          - -nginx-configmaps=$(POD_NAMESPACE)/nginx-config
          - -default-server-tls-secret=$(POD_NAMESPACE)/default-server-secret
         #- -v=3 # Enables extensive logging. Useful for troubleshooting.
         #- -report-ingress-status
         #- -external-service=nginx-ingress
         #- -enable-prometheus-metrics
         #- -global-configuration=$(POD_NAMESPACE)/nginx-configuration

```

```shell
kubectl apply -f wp-ing.yml -f wp-ink.yml -f wp-kic-dep.yml
```



## Dashboard

### 配置证书

```shell
openssl req -x509 -days 365 -out k8s.test.crt -keyout k8s.test.key \
  -newkey rsa:2048 -nodes -sha256 \
    -subj '/CN=k8s.test' -extensions EXT -config <( \
       printf "[dn]\nCN=k8s.test\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:k8s.test\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```

### 配置Dashboard

```shell
export out="--dry-run=client -o yaml"
kubectl create secret tls dash-tls -n kubernetes-dashboard --cert=k8s.test.crt --key=k8s.test.key $out > cert.yml
```

```yaml
# IngressClass 
apiVersion: networking.k8s.io/v1
kind: IngressClass

metadata:
  name: dash-ink
  namespace: kubernetes-dashboard
spec:
  controller: nginx.org/ingress-controller

---

# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: dash-ing
  namespace: kubernetes-dashboard
  annotations:
    # enable proxy_pass https://xxx
    nginx.org/ssl-services: "kubernetes-dashboard"

    # customize port
    #nginx.org/listen-ports-ssl: '8443'

spec:
  ingressClassName: dash-ink

  # kubectl explain ingress.spec.tls
  tls:
    - hosts:
      - k8s.test
      # must in ns kubernetes-dashboard
      secretName: dash-tls

  rules:
  - host: k8s.test
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            # same as dashboard.yml
            name: kubernetes-dashboard
            port:
              number: 443
---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: dash-kic-dep
  namespace: nginx-ingress

spec:
  replicas: 1
  selector:
    matchLabels:
      app: dash-kic-dep

  template:
    metadata:
      labels:
        app: dash-kic-dep

    spec:
      serviceAccountName: nginx-ingress

      # use host network
      #hostNetwork: true
      #dnsPolicy: ClusterFirstWithHostNet

      containers:
      - image: nginx/nginx-ingress:2.2-alpine
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
          - -ingress-class=dash-ink
          - -health-status
          - -ready-status
          - -nginx-status
          - -enable-snippets

          - -nginx-configmaps=$(POD_NAMESPACE)/nginx-config
          - -default-server-tls-secret=$(POD_NAMESPACE)/default-server-secret
          
---

# service
apiVersion: v1
kind: Service
metadata:
  name: dash-kic-svc
  namespace: nginx-ingress

spec:
  ports:
  - port: 443
    protocol: TCP
    targetPort: 443
    nodePort: 30443

  selector:
    app: dash-kic-dep
  type: NodePort
```

```shell
kubectl get pod -n nginx-ingress

kubectl get pod -n kubernetes-dashboard

kubectl create ing dash-ing --rule="k8s.test/=kubernetes-dashboard:443" --class=dash-ink -n kubernetes-dashboard $out
```



### 账号

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
```

```shell

kubectl get ingressclasses -n kubernetes-dashboard

kubectl get deploy -n nginx-ingress

kubectl get secret -n kubernetes-dashboard
kubectl describe secrets -n kubernetes-dashboard admin-user-token-462r2
```





## 域名解析

将Ingress 中配置的 `wp.test` 解析为 Ingress Controller所部署的Worker节点的IP。

> mac：`/etc/hosts`
>
> windows：`C:\Windows\System32\Drivers\etc\hosts`

```shell
192.168.56.18 wp.test
```

### 问题处理

提示 `Error establishing a database connection` 错误

删除dns后会重新创建

```shell
kubectl get pod -n kube-system

kubectl delete pod coredns-6d8c4cb4d-jhrz7 -n kube-system
kubectl delete pod coredns-6d8c4cb4d-jnz2w -n kube-system
```



