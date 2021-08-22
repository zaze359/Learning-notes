---

title: Android源码下载
date: 2020-05-29 16:58
---

# AOSP源码下载
[官方地址: https://source.android.com/index.html](https://source.android.com/index.html)
[清华大学开源软件镜像站：https://mirror.tuna.tsinghua.edu.cn/help/AOSP/](https://mirror.tuna.tsinghua.edu.cn/help/AOSP/)



## 基础环境配置

```shell
sudo apt-get upgrade
sudo apt-get install git curl python
```

## Repo 安装

```shell
mkdir ~/bin
PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

## 初始化 Repo 客户端
1. 创建一个空目录来存放您的工作文件。如果您使用的是 MacOS，必须在区分大小写的文件系统中创建该目录。为其指定一个您喜欢的任意名称：
```shell
mkdir aosp
cd aosp
```
```shell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```
- Google

```shell
repo init -u https://android.googlesource.com/platform/manifest
## -b 指定分支
repo init -u https://android.googlesource.com/platform/manifest -b android-4.0.1_r1
```

- 清华镜像

```shell
repo init -u https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/platform/manifest
```



## 同步Android源代码

```shell
# -c 仅下载当前分支
# -j4 启动4个线程下载
# 2>&1 | tee sync.log 记录错误日志
# 根据自身调衡参数
repo sync -c -j4 2>&1 | tee sync.log
```

