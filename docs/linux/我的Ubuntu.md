# 我的Ubuntu

## 一、安装Ubuntu

### 制作U盘启动

1. 下载Ubuntu镜像文件
[Ubuntu官方镜像](https://ubuntu.com/download/desktop)
2. 下载UltraISO
[UltraISO下载后安装并试用](https://cn.ultraiso.net/xiazai.html)
3. 使用UltralSO制作U盘启动
  - 文件 > 打开 > 选择下载的ubuntu镜像
  - 启动 > 写入硬盘映像 > 选择u盘写入
### 安装系统
1. 开机 按 R2进入biso设置界面, 选择BootMenu
2. 选择你的U盘作为启动项
3. 选择Install Ubuntu

---



## 二、应用的安装

### 可能碰到一些应用无法安装的问题

#### 1. deb文件无法安装

在Ubuntu中安装应用时有时会碰到``.deb文件``无法安装的问题，此时可能是缺少依赖，通过以下命令安装所需依赖:

```shell
sudo apt-get install -f xxx.deb
```

安装完后，使用以下命令直接安装:

```shell
sudo dpkg -i xxx.deb
```



### Chrome

```

```





---

## E、问题处理记录

#### CMD Markdown无法打开

由于缺少libgconf-2.so.4导致

```
sudo apt -y install libgconf-2-4
```

---

### 系统黑屏无法启动

- Recovery Mode 启动进入系统
```
1. 重启选择 Ubuntu 高级选项
2. 选择 Recovery Mode 启动
3. 等待弹窗后直接回车 选择 resume -> ok 
4. 启动进入Ubuntu, 进行修复具体操作
```

- 查看驱动信息
```
ubuntu-drivers devices
# or 打开软件和更新 -> 附加驱动
```


- 更新驱动
```
sudo ubuntu-drivers autoinstall

# 安装指定版本
sudo apt install nvidia-470
```

- 重启进入ubuntu

---

### 亮度无法调节(显示设备无法识别)

查看显示器信息
```
xrandr
```

- 若使用了独显直连, 切换为混合模式

- 确认驱动版本

```
打开软件和更新 -> 附加驱动
```