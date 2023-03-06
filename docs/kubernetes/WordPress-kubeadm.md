# kubeadm部署WordPress

[Kubernetes环境配置](./Kubernetes环境搭建.md)

* 搭建kubeadm环境。
* Deployment部署实例。
* Service作为集群内部的负载均衡，内部使用域名访问WorkPress 、MariaDB等服务。
* Ingress Controller作为反向代理。

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
apiVersion: networking.k8s.io/v1
kind: IngressClass

metadata:
  name: dash-ink
  namespace: kubernetes-dashboard
spec:
  controller: nginx.org/ingress-controller

---

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



