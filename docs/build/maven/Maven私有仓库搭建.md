# Maven私有仓库搭建

| maven仓库类型 | 具体说明                                   |
| :------------ | :----------------------------------------- |
| hosted        | 本地存储。                                 |
| proxy         | 提供代理其它仓库的类型                     |
| group         | 组类型，能够组合多个仓库为一个地址提供服务 |

## Docker + Nexus  搭建仓库

### 1.下载Nexus

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



---

## 发布到 Maven中央仓库sonatype

### 1. 注册sonatype账号

[sonatype注册地址]([https://issues.sonatype.org/secure/Dashboard.jspa)

### 2. 新建一个issues提交并等待审核。

![image-20210908010451062](Maven%E7%A7%81%E6%9C%89%E4%BB%93%E5%BA%93%E6%90%AD%E5%BB%BA.assets/image-20210908010451062.png)



![image-20210908010309978](Maven%E7%A7%81%E6%9C%89%E4%BB%93%E5%BA%93%E6%90%AD%E5%BB%BA.assets/image-20210908010309978.png)

![image-20210908010332122](Maven%E7%A7%81%E6%9C%89%E4%BB%93%E5%BA%93%E6%90%AD%E5%BB%BA.assets/image-20210908010332122.png)

### 3. 根据对方的回复进行操作。

会让你在github上建立一个指定名称的项目来验证身份。一步步操作即可。

![image-20210908010842300](Maven%E7%A7%81%E6%9C%89%E4%BB%93%E5%BA%93%E6%90%AD%E5%BB%BA.assets/image-20210908010842300.png)

### 4. [GPG 相关配置](docs/SecretKey/GPG.md)



## 项目配置Gradle上传脚本

>  [maven.gradle参考](https://github.com/zaze359/test/blob/master/maven.gradle)

新建**maven.properties**配置自己的仓库信息

```properties
signing.keyId=CExxxx
signing.password=xxxxx
signing.secretKeyRingFile=~/.gnupg/secret.gpg
RELEASE_REPOSITORY_URL="release仓库地址"
SNAPSHOT_REPOSITORY_URL="snapshot仓库地址"
NEXUS_USERNAME="账号"
NEXUS_PASSWORD="密码"
```
