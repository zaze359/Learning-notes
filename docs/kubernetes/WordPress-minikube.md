# minikube搭建WordPress

[Kubernetes环境配置](./Kubernetes环境搭建.md)

* 安装minikube环境。

* 在minikube中使用裸Pod部署各个应用。

* 使用Docker 创建Nginx 作为反向代理，对外暴露访问接口。

## MariaDB

### ConfigMap

将MariaDB的数据库名、用户名、密码等配置使用ConfigMap进行配置。

> maria-cm.yml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: maria-cm

data:
  DATABASE: 'db'
  USER: 'wp'
  PASSWORD: '123'
  ROOT_PASSWORD: '123'
```

### Pod

注入ConfigMap中的配置。

> maria-pod.yml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: maria-pod
  labels:
    app: wordpress
    role: database

spec:
  containers:
  - image: mariadb:10
    name: maria
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 3306

    envFrom:
    - prefix: 'MARIADB_'
      configMapRef:
        name: maria-cm
```

### 启动

```shell
alias kubectl="minikube kubectl --"
# 创建配置
kubectl apply -f mariadb-cm.yml
# 创建pod
kubectl apply -f mariadb-pod.yml
# 查看IP地址
kubectl get pod -o wide
# 172.17.0.6
```

> 验证数据是否正常

```shell
# 进入 maria-pod sh
kubectl exec -it maria-pod -- sh
# 登录数据库
mysql -u wp -p
#
show databases;
show tables;
```



## WordPress

### ConfigMap

> wp-cm.yml
>

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: wp-cm

data:
  HOST: '172.17.0.6' # HOST 指向 mariadb-pod 的 ip
  USER: 'wp'
  PASSWORD: '123'
  NAME: 'db'
```

### Pod

> wp-pod.yml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wp-pod
  labels:
    app: wordpress
    role: website

spec:
  containers:
  - image: wordpress:5
    name: wp-pod
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80

    envFrom:
    - prefix: 'WORDPRESS_DB_'
      configMapRef:
        name: wp-cm
```

### 启动

```shell
kubectl apply -f wp-cm.yml
kubectl apply -f wp-pod.yml
```



## 端口映射

```shell
# &：端口转发工作在后台进行，防止阻塞
# 将kubernetes的 8080 端口映射到，wp-pod的80端口
kubectl port-forward wp-pod 8080:80 &
```

## Nginx

反向代理

> proxy.conf

```nginx
server {
  listen 80;
  default_type text/html;

  location / {
      proxy_http_version 1.1;
      proxy_set_header Host $host;
      proxy_pass http://127.0.0.1:8080;
  }
}
```

> 使用 proxy.conf 配置 启动 Nginx

```shell
docker run -d --rm \
    --net=host \
    -v /home/z/k8s/wordpress/proxy.conf:/etc/nginx/conf.d/default.conf \
    nginx:alpine
```



### 问题处理

提示 `Error establishing a database connection` 错误

删除dns后会重新创建

```shell
kubectl get pod -n kube-system

kubectl delete pod coredns-65c54cc984-4bmtv -n kube-system
kubectl delete pod coredns-6d8c4cb4d-jnz2w -n kube-system
```



将 `maria-pod` 和 `wp-pod` 删除重建。

