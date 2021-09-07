# SSH key

## 创建生成ssh key

### 1. 查找本地ssh key(id_rsa.pub)

```bash
cd ~/.ssh
# 若没有则新建一个 mkdir .ssh
ls

# windows 进入git安装目标下, 例如 D:\Git\bin
```

### 2. 生成ssh key

```bash
ssh-keygen -t rsa -C "zhaozhen359@gmail.com"
```

### 3. 后续需要设置文件名和密码，可直接回车跳过即可

### 4. 查看复制**id_rsa.pub**中的内容

```bash
cat id_rsa.pub
```

## 问题处理

### ssh 连接超时, 修改为443端口

创建**/etc/ssh/ssh_config**文件, 写入以下配置:

```bash
Host github.com
User zhaozhen359@gmail.com
Hostname ssh.github.com
PreferredAuthentications publickey
IdentityFile C:/Users\Administrator/.ssh/id_rsa
Port 443
```