# Kubernetes常用命令摘录

## kubectl

### 查看集群

```shell
# 开启kubectl的自动补全功能
source <(kubectl completion bash)

#################################
# 查看节点状态
kubectl get node

# 查看pod列表
kubectl get pod
# -o wide 更多的输出信息：如部署的节点、IP地址等。
kubectl get pod -o wide
# -w 实时状态
kubectl get pod -w

# 查看 kube-system 内的pod。默认时defalut
# -n 指定命名空间: kube-system。
kubectl get pod -n kube-system

# 所有命名空间中的pod
kubectl get pods --all-namespaces


# 找出 app标签是nginx的 所有Pod
kubectl get pod -l app=nginx
# 多匹配
kubectl get pod -l 'app in (ngx, nginx, ngx-dep)'
# 
kubectl get job
kubectl get cj
kubectl get cm
# 查看Daemonset
kubectl get ds
# 查看Deployment
kubectl get deploy
# 查看集群里有哪些 namespace
# 也代表API对象哪里，默认在default
kubectl get ns

# 也可以简单的直接创建namespace
kubectl create ns custom-ns

###############################
# 查看节点详细的状态
kubectl describe node

# 检查 busy-pod的详细状态
# kubectl describe [kind] [name]
kubectl describe pod busy-pod

###############################
# 启动 ngx
kubectl run ngx --image=nginx:alpine
# 进入到 ngx-pod 内部
kubectl exec -it busy-pod -- sh
# 拷贝文件
kubectl cp a.txt ngx-pod:/tmp

#################################
# &：端口转发工作在后台进行，这样退出也会继续运行
# 将本地的8080端口映射到 xx-pod的80端口
kubectl port-forward xx-pod 8080:80 &
# fg 将后台工作调到前台，可被关闭。
#################################
# 查看当前 Kubernetes 版本支持的所有对象
kubectl api-resources
# 查看对象字段的说明文档,根据说明来创建对象。
# kubectl explain [api-resources]
kubectl explain pod
```

### 创建/删除

```shell
# -f 指定YAML文件
# 以busy-pod.yml文件中的定义 创建对象
kubectl apply -f busy-pod.yml
# create 是创建新资源，已存在时会报错。apply则可以更新。
kubectl create -f busy-pod.yml
# 以busy-pod.yml文件中的定义 删除对象
kubectl delete -f busy-pod.yml
# 指定名字删除：删除name为busy-pod的pod
kubectl delete pod busy-pod
kubectl delete pod coredns-6d8c4cb4d-2kznc -n kube-system

# 删除指定pv
kubectl delete pv pv mongo-1g-pv
# 处理 指定pv无法删除 的问题
kubectl patch pv mongo-1g-pv -p '{"metadata":{"finalizers":null}}'



# 删除所有 Evicted的pod
kubectl get pods -A | awk '/Evicted/{print $1,$2}' \
  | xargs -r -n2 kubectl delete pod -n
```

### 查看日志

```shell
# 显示pod的日志
kubectl logs busy-pod
```



### 回滚操作

```shell
# 使用`kubectl rollout` 命令管理更新过程。
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



### 容忍度

```shell
kubectl describe node
kubectl taint node worker node.kubernetes.io/disk-pressure-


# 添加污点, 之前已调度创建的 pod并不会在添加污点后自动删除。
kubectl taint node master node-role.kubernetes.io/master:NoSchedule
# 末尾添加 `-` 表示删除 
kubectl taint node master node-role.kubernetes.io/master:NoSchedule-
kubectl taint node worker node-role.kubernetes.io/master:NoSchedule-
```

### 端口转发

```shell
# 把本地的 8080 端口映射到了 Ingress Controller Pod 的 80 端口
kubectl port-forward -n nginx-ingress ngx-kic-dep 8080:80 &
```





### 创建YAML模板

创建YAML模板，定义API对象

> --dry-run=client -o yaml：表示输出一份yaml样例模板

```shell
# 定义Shell变量 out, 方便使用
export out="--dry-run=client -o yaml"

#########################
### kubectl create 创建模板
# CronJob模板 name: echo-cj
kubectl create cj echo-cj --image=busybox --schedule="" $out

# Config Map模板
# kubectl create configmap <映射名称> <数据源>
kubectl create cm info $out
# ConfigMap + data字段
# 使用 --from-literal 定义的简单属性：k=v
# 使用 --from-file 定义复杂属性的例子：文件名作为key， 内容为value
kubectl create cm info --from-literal=k=v $out

# --namespace 指定命名空间
kubectl create configmap redis-conf --namespace=redis --from-file=redis.conf $out

# Secret模板
# Secret.name: user
# 参数：name: root。 
# 模板生成时会对value自动进行加密，默认是Base64编码
kubectl create secret generic user --from-literal=name=root $out

#######################
### kubectl expose 创建 Service 模板
# deploy ngx-dep 表示使用 名为ngx-dep的Deployment 
# --port：映射端口,Server的端口
# --target-port： 容器端口
kubectl expose deploy ngx-dep --port=80 --target-port=80 $out
```







## kubeadm

```shell
sudo kubeadm reset


kubeadm token create

# 显示加入命令
kubeadm token create --print-join-command

# 加入master
sudo kubeadm join 192.168.56.8:6443 --token 4k19s0.teja39vdnju1zlks \
        --discovery-token-ca-cert-hash sha256:54c15422bba3c81f4d1e4fa2d5d579a317b82cb4baa41ecee09962d1de6c547a 
```



```shell
sudo kubeadm init \
    --pod-network-cidr=10.10.0.0/16 \
    --apiserver-advertise-address=192.168.56.8 \
    --image-repository registry.aliyuncs.com/google_containers\
    --kubernetes-version=v1.23.3
```





## minikube

```shell
minikube version
# 查看集群状态
minikube status
# 启动
minikube start

# minikube 中设置别名
alias kubectl="minikube kubectl --"
```

```shell
# 使用浏览器打开 minikube的Dashboard页面
minikube dashboard

# 指定 docker 作为驱动启动
minikube start --driver=docker
# root下使用
minikube start --force --driver=docker
minikube start --force --driver=docker --kubernetes-version=v1.23.3


# 指定版本
minikube start --kubernetes-version=v1.23.3
# 指定docker
minikube start --force --driver=docker --kubernetes-version=v1.23.3
# 使用国内镜像
minikube start --kubernetes-version=v1.23.3 --image-mirror-country='cn'
# 删除
minikube delete pod busy-pod

# 查看节点列表
minikube node list
# 查看插件列表
minikube addons list

# ssh 方式进入minikube
minikube ssh
ps -ef|grep kubelet
```





