# NFS网络存储

* 支持多个节点同时访问一个共享目录。

## 服务端

### 安装NFS服务端

```shell
sudo apt -y install nfs-kernel-server
```

### 创建存储路径

```shell
sudo mkdir -p /home/nfs
```

### 配置 NFS 访问共享目录

修改`/etc/exports`， 将 `/home/nfs `目录共享。

```shell
sudo vi /etc/exports

# 设置nfs允许访问的网段，即服务器所在网段
/home/nfs 192.168.56.0/24(rw,sync,no_subtree_check,no_root_squash,insecure)
```

更新配置

```shell
sudo exportfs -ra
# 验证
sudo exportfs -v
```

### 启动NFS

```shell
# 启动
sudo systemctl start  nfs-server
# 开机启动
sudo systemctl enable nfs-server
# 查看服务状态
sudo systemctl status nfs-server

# 查看挂载情况
showmount -e 127.0.0.1
```

---

## 客户端

### 安装NFS客户端

```shell
sudo apt -y install nfs-common
```

```shell
# 查看NFS. 192.168.56.22是服务端地址
showmount -e 192.168.56.22
```

### 挂载

```shell
# 创建挂载路径
mkdir -p /tmp/test


# -v：执行时显示详细信息
# -t：只当文件系统

# mount：将192.168.10.208:/home/nfs 挂载到 /tmp/test
sudo mount -t nfs 192.168.10.208:/home/nfs /tmp/test

# 
sudo umount -v /tmp/test
```

### 测试

```shell
# 创建一个文件
touch /tmp/test/x.yml
```

