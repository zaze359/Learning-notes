---
title: Tomcat
date: 2020-07-01 10:57
---

# Tomcat

## Mac OS
### 安装
```bash
brew search tomcat
brew install tomcat
```

### 检查是否安装成功：
``` bash
catalina -h
```
### 运行tomcat：
```bash
catalina run
```

## Windows

### 下载tomcat

[Tomcat官网](https://tomcat.apache.org/)

> 注意选择的tomcat是否支持本地安装的java版本。

下载完zip包后直接解压即可


### 测试启动
1. cmd 进入tomcat目录: ``D:\apache-tomcat-10.0.17\bin``
2. ``.\startup.bat``测试启动服务
3. 浏览器打开: ``http://localhost:8080/``, 查看是否能正常打开。

### 问题处理

> tomcat服务启动，日志乱码

打开``D:\apache-tomcat-10.0.17\bin>logging.properties``文件:
```shell
java.util.logging.ConsoleHandler.encoding = UTF-8
# 修改为GBK
java.util.logging.ConsoleHandler.encoding = GBK
```