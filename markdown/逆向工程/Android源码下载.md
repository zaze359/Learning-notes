---
title: Android源码下载
date: 2020-05-29 16:58
---

# 源码下载
[官方地址: https://source.android.com/index.html](https://source.android.com/index.html)
[清华大学开源软件镜像站：https://mirror.tuna.tsinghua.edu.cn/help/AOSP/](https://mirror.tuna.tsinghua.edu.cn/help/AOSP/)


## Repo 安装
```
mkdir ~/bin
PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

## 初始化 Repo 客户端
1. 创建一个空目录来存放您的工作文件。如果您使用的是 MacOS，必须在区分大小写的文件系统中创建该目录。为其指定一个您喜欢的任意名称：
```
mkdir WORKING_DIRECTORY
cd WORKING_DIRECTORY
```
```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```
```
repo init -u https://android.googlesource.com/platform/manifest

-b 指定分支
repo init -u https://android.googlesource.com/platform/manifest -b android-4.0.1_r1
```

## 下载Android源代码
```
repo sync
```



