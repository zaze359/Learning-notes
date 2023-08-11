# Java执行环境

## 下载OpenJDK

[OpenJDK](https://openjdk.org/)

[Java Platform, Standard Edition 13 Reference Implementations](https://jdk.java.net/java-se-ri/13)



## 环境变量配置

新建系统变量`JAVA_HOME`

```shell
D:\openjdk\jdk-13
```

添加环境变量`path`

```shell
%JAVA_HOME%\bin
```

验证：

```shell
java -version
```

### 安装版本的Java

调整以下环境变量的顺序即可，`%JAVA_HOME%\bin`在上面。

![image-20230329212621613](./Java%E7%8E%AF%E5%A2%83%E9%85%8D%E7%BD%AE.assets/image-20230329212621613.png)



