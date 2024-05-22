# Gradle本地环境

> 创建一个本地的Gradle环境，节约开发设备的内存

* 每一个版本的Gradle都会对应一个Daemon进程，使用同一个版本的进程可以节约配置
* 即使使用同一个版本的Gradle, 也会因为VM配置不同而启动多个Daemon进程。

## mac安装

```shell
brew install gradle
```

## window安装

下载地址：[Gradle Distributions](https://services.gradle.org/distributions/)，[Gradle | Releases](https://gradle.org/releases/)

一般选择新的下载即可。gradle版本跨度太大时需要注意适配。

[Compatibility Matrix (gradle.org)](https://docs.gradle.org/current/userguide/compatibility.html)

> Android Studio配置使用本地Gradle

![image-20221007215201059](./Gradle%E6%9C%AC%E5%9C%B0%E7%8E%AF%E5%A2%83.assets/image-20221007215201059.png)

windows 配置环境变量:

> GRADLE_HOME

![image-20221007213029484](./Gradle%E6%9C%AC%E5%9C%B0%E7%8E%AF%E5%A2%83.assets/image-20221007213029484.png)

> path 中新增

![image-20221007213116787](./Gradle%E6%9C%AC%E5%9C%B0%E7%8E%AF%E5%A2%83.assets/image-20221007213116787.png)



### 验证是否配置成功

```shell
gradle --version
gradle -v
```

