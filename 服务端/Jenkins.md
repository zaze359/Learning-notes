---
title: Jenkins
date: 2020-04-27 10:08
---

## Docker 安装 Jenkins
```
docker pull zazegbc/jenkins
mkdir /home/jenkins          创建文件夹
ls -nd jenkins/                  查看文件权限
chown -R 1000:1000 jenkins/    给uid为1000的权限
docker run -itd -p 9090:8080 -p 50000:50000 --name jenkins --privileged=true  -v /home/jenkins:/var/jenkins_home jenkins:latest
```