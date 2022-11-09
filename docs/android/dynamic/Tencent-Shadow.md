# Tencent/Shadow

## 一、clone项目

[Tencent/Shadow: 零反射全动态Android插件框架 (github.com)](https://github.com/Tencent/Shadow)

```shell
#
git clone git@github.com:Tencent/Shadow.git
## 清理项目
./gradlew clean
```

### Gradle升级7.0.2之后发生报错,需要使用java11

![image-20220217182552440](Tencent-Shadow.assets/image-20220217182552440.png)

#### 	IDE settings

![image-20220217182447922](Tencent-Shadow.assets/image-20220217182447922.png)

#### gradle.properties添加配置

```
org.gradle.java.home=/Library/Java/JavaVirtualMachines/temurin-11.jdk/Contents/Home
```

## 二、项目结构
