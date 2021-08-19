# maven-publish

[TOC]

## 一、仓库搭建

### 1. 下载Nexus

```javascript
docker pull sonatype/nexus3
```

### 2. 创建Nexus的挂载文件夹(可选)

```bash
mkdir /usr/local/nexus-data && chown -R 200 /usr/local/nexus-data
```

### 3. 启动容器

```bash
docker run -d -p 8081:8081 --name nexus -v /usr/local/nexus-data:/nexus-data --restart=always sonatype/nexus3
docker run -d -p 8081:8081 --name nexus --restart=always sonatype/nexus3
```



