# Linux常用命令

[Linux 教程 | 菜鸟教程 (runoob.com)](https://www.runoob.com/linux/linux-tutorial.html)

```shell
# 打开当前目录, 类似mac open
xdg-open .
```



## 环境变量

```shell
# 输出环境变量
printenv
# 设置环境变量
setenv

# 查看 path
export
export $PATH

```



## 用户/用户组管理

* 查看用户

  ```shell
  cat /etc/passwd

* 创建用户：

  ```shell
  # 自动建立用户的登入目录
  # /home/z
  sudo useradd -m z
  ```

* 设置 新用户 z 的密码

  ```shell
  sudo passwd z
  ```

* 设置权限

  ```shell
  sudo vi /etc/sudoers
  ```

* 删除用户

  ```shell
  sudo userdel -r z
  ```

* 查询用户组

  ```shell
  cat /etc/group
  #
  cat /etc/group | grep docker
  ```

* 创建用户组

  ```shell
  # 创建 docker 用户组
  sudo groupadd docker
  ```

* 将用户添加到指定用户组中

  ```shell
  # 将 z 添加到 docker 用户组中
  sudo usermod -aG docker z
  ```
  

---

## 文件管理

| 操作命令 | 说明                 |      |
| -------- | -------------------- | ---- |
| du       | 查看文件大小         |      |
| df       | 查询磁盘挂载使用情况 |      |
| mount    | 分区挂载             |      |
| ls       | 列出文件列表         |      |
| touch    | 创建文件             |      |



### touch（创建文件）

```shell
# 创建一个文件,已存在时为修改文件时间
touch aa.txt
# 创建2个文件
touch aa.txt bb.txt
# 批量创建
touch aa{0001..1000}.txt
```

### mv

移动文件，也能用于重命名。

```shell
mv *.yml /base
```

### rename

需要安装 `rename`

```shell
sudo apt install rename
```

将所有后缀为.log的文件修改改.txt

```shell
rename 's/\.log/\.txt/' *
```

### tee

将用户输入的数据 追加到文件中。

```shell
# 可指定多个文件，一同追加。
tee ./a.txt ./b.txt
```



### du: 查看文件大小

```shell
## 控制显示单位
du -m
du -hs /sdcard/
du -ms /sdcard/
du -ks /sdcard/
du -gs /sdcard/

## 控制层级: 一级目录
du -h -d1
```

### mount: 分区挂载

```
mount -o remount, rw /
```

### ls

```shell
ls
# 显示详情，不包括隐藏文件
ls -l
# 包括隐藏文件
ls -la
```



![image-20220214102626948](Linux常用命令.assets/image-20220214102626948.png)



| 文件属性                                                     |      | 拥有者 | 拥有者所在的组 | 文件所占用的空间(以字节为单位) | 最近修改时间     | README.md |
| ------------------------------------------------------------ | ---- | ------ | -------------- | ------------------------------ | ---------------- | --------- |
| -rw-rw----                                                   | 1    | root   | scared_rw      | 5942417                        | 2020-09-28 15:18 | README.md |
| 第一个字符表示文件类型<br />'-': 表示普通文件<br />'d': 表示目录<br />'i':链接文件<br />'b':块设备文件<br />'c':字符设备文件<br />'p':命令管道<br />'s':sock文件 |      |        |                |                                |                  |           |
| r表是读 (Read) 、w表示写 (Write) 、x表示执行 (eXecute)       |      |        |                |                                |                  |           |
|                                                              |      |        |                |                                |                  |           |







---

## apt: 软件包管理

```bash

sudo apt update
# 更新
sudo apt upgrade

# -y 安装过程提示选择全部为"yes"
# -q 不显示安装过程
# git 
sudo apt install -y git
# curl
sudo apt install curl
# python
sudo apt install python
#

```

## ps: 进程查询

查询所有进程

```
ps -A
```

查询指定pid的进程信息

```
ps -p pid
```

查询根据指定文本查询

```shell
ps | grep packageName
```



## chmod

用于控制用户对文件的操作权限。

符号：

|      |                         |      |
| ---- | ----------------------- | ---- |
| u    | user：所有者            |      |
| g    | group：所有者所在用户组 |      |
| o    | other：其他用户组       |      |
| a    | all：任何用户           |      |
|      |                         |      |
| r    | 读                      |      |
| w    | 写                      |      |
| x    | 执行                    |      |
| -    | 无对应权限              |      |

数字表示法：采用的是八进制。

| 八进制 | 二进制 | rwx  | 权限         |
| ------ | ------ | ---- | ------------ |
| 7      | 111    | rwx  | 读、写、执行 |
| 6      | 110    | rw-  | 读、写       |
| 5      | 101    | r-x  | 读、执行     |
| 4      | 100    | r--  | 只读         |
| 3      | 011    | -wx  | 写、执行     |
| 2      | 010    | -w-  | 只写         |
| 1      | 001    | --x  | 仅执行       |
| 0      | 000    | ---  | 无权限       |

```shell
#依次为： u,g,o
chmod 755 a.txt
# 4000 Sets user ID on execution,其他用户执行期间拥有和所有者相同的权限，在此处表示执行程序的用户的权限变为了7
# 2000 Sets group ID on execution
# 1000 Sets the link permission to directoires or sets the save-text attribute for files.
chmod 4755 a.txt
```





## vi

| 指令                        |                                                              |                                             |
| --------------------------- | ------------------------------------------------------------ | ------------------------------------------- |
| `ESC`                       | 切换模式                                                     |                                             |
| `i`                         | 插入模式                                                     |                                             |
| `:wq`                       | 保存并退出                                                   |                                             |
| `:q!`                       | 强制退出                                                     |                                             |
| -                           |                                                              |                                             |
| `ctrl + b`                  | 后移一页                                                     |                                             |
| `ctrl + f`                  | 前移一页                                                     |                                             |
| -                           |                                                              |                                             |
| `x`                         | 删除光标 后面的字符                                          | `6x`：表示删除光标后面6个字符               |
| `X`                         | 大写,删除光标前面                                            |                                             |
| `dd`                        | 删除所在行                                                   |                                             |
| -                           |                                                              |                                             |
| `yw`                        | 字符范围：复制光标到字尾                                     |                                             |
| `yy`                        | 复制光标所在行。                                             |                                             |
| -                           |                                                              |                                             |
| `r`                         | 替换光标指定字符                                             |                                             |
| -                           |                                                              |                                             |
| `u`                         | 撤销回退操作                                                 |                                             |
| -                           |                                                              |                                             |
| `/str`                      | 从**光标之下开始匹配搜索**str字符串。                        |                                             |
| `?str`                      | 从**光标之上开始匹配搜索**。                                 |                                             |
| n                           | 搜索下一个                                                   |                                             |
| N                           | 搜索上一个                                                   |                                             |
| `:line1,line2s/str1/str2/g` | 将第line1行到line2行中str1替换为str2。`1,$ = %` 这两个表示 第一行到最后一行。`gc`表示需要用户确认 | `:1,$s/str1/str2/g`<br />`:%s/str1/str2/gc` |





## 网络相关

> 若指令执行报错，根据提示安装net-tools即可

```shell
sudo apt install net-tools
```

### 查询本机ip

```shell
ifconfig -a
```

### netstat: 监控TCP/IP网络

> 用于显示实际的网络连接、路由表、网络接口设备的状态信息

显示网络状态

```shell
netstat -a
```

xxxxxxxx

```bash
netstat -anp |grep 80

# windows
netstat -anp |findstr :80

lsof -i:80
//查看当前所有tcp端口·
netstat -ntlp   
netstat -ntulp |grep 80   //查看所有80端口使用情况·
netstat -an | grep 3306   //查看所有3306端口使用情况·
```

### dig:用于查询DNS

Dig是一个在类Unix命令行模式下查询DNS包括NS记录，A记录，MX记录等相关信息的工具
```bash
dig www.baidu.com
dig @114.114.114.114 www.baidu.com
dig baidu.com A +noall +answer
```

```bash
; <<>> DiG 9.10.6 <<>> www.baidu.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 25392
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 5, ADDITIONAL: 6

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.baidu.com.			IN	A

;; ANSWER SECTION:
www.baidu.com.		679	IN	CNAME	www.a.shifen.com.
www.a.shifen.com.	3	IN	A	112.80.248.76
www.a.shifen.com.	3	IN	A	112.80.248.75

;; AUTHORITY SECTION:
a.shifen.com.		903	IN	NS	ns2.a.shifen.com.
a.shifen.com.		903	IN	NS	ns4.a.shifen.com.
a.shifen.com.		903	IN	NS	ns5.a.shifen.com.
a.shifen.com.		903	IN	NS	ns1.a.shifen.com.
a.shifen.com.		903	IN	NS	ns3.a.shifen.com.

;; ADDITIONAL SECTION:
ns3.a.shifen.com.	903	IN	A	112.80.255.253
ns4.a.shifen.com.	903	IN	A	14.215.177.229
ns5.a.shifen.com.	903	IN	A	180.76.76.95
ns1.a.shifen.com.	903	IN	A	61.135.165.224
ns2.a.shifen.com.	903	IN	A	220.181.33.32

;; Query time: 3 msec
;; SERVER: 192.168.5.50#53(192.168.5.50)
;; WHEN: Mon Apr 27 10:26:25 CST 2020
;; MSG SIZE  rcvd: 271
```



## 12345

```bash
ifconfig en0
查看内核版本 ``cat /proc/version``
which date
alias freak="free -h"
type date
whatis ls 简单介绍ls
man ls 帮助信息ls
info ls 更详细的帮助信息
```