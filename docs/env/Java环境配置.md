# Java环境配置



## Windows

### 下载OpenJDK

[OpenJDK](https://openjdk.org/)

[Java Platform, Standard Edition 13 Reference Implementations](https://jdk.java.net/java-se-ri/13)

### 环境变量配置

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

## MAC多JDK版本切换

```shell
export JAVA_8_HOME=/Library/Java/JavaVirtualMachines/jdk-1.8.jdk/Contents/Home
export JAVA_11_HOME=/Library/Java/JavaVirtualMachines/jdk-11.jdk/Contents/Home
export JAVA_17_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
export JAVA_HOME=$JAVA_11_HOME
export PATH=$PATH:$JAVA_HOME/bin

alias jdk8 ="export JAVA_HOME=$JAVA_8_HOME"
alias jdk11="export JAVA_HOME=$JAVA_11_HOME"
alias jdk17="export JAVA_HOME=$JAVA_17_HOME"

```

```shell
# 加载配置
source .zshrc
```





## 其他

### 优先使用安装版本的Java

调整以下环境变量的顺序即可，`%JAVA_HOME%\bin`在上面。

![image-20230329212621613](./Java%E7%8E%AF%E5%A2%83%E9%85%8D%E7%BD%AE.assets/image-20230329212621613.png)



