---
title: Gradle Plugin
date: 2020-07-24 18:11
---

# Gradle Plugin

## 1. 开发
### 1.1. 项目配置
1. 新建项目PluginDemo
2. 创建module: z-plugin
3. 删除文件, 仅保留build.gradle
4. 新建文件夹src/main/groovy
5. 新建resources/META-INF/gradle-plugins文件夹
6. 创建 xxx.properties文件
```properties
// 此文件内声明插件入口
// xxx即为插件id (com.zaze.plugin)
implementation-class=com.zaze.plugin.PluginLauncher
```
处理后的项目结构大体如下
![](./_image/2020-07-24/2020-07-31-16-39-12.png)


### 1.2. 开始基于groovy开发

---
## 2. 插件打包上传
创建 **gradle-mvn-push.gradle文件** , 用于将插件打包上传

```
apply plugin: 'maven'
def userHome = System.getProperty("user.home")
uploadArchives {
    repositories.mavenDeployer {
        repository(url: "file:" + userHome + "/.m2/repository/") {
            snapshots(updatePolicy: 'always', enabled: true)
        }
        pom.groupId = "com.zaze.plugin"
        pom.artifactId = "z-plugin"
        pom.version = "1.0.0-SNAPSHOT"
    }
}
```

修改plugin模块中的 **build.gradle** 文件
```
apply plugin: 'groovy'
dependencies {
    implementation gradleApi()
    implementation localGroovy()
    implementation fileTree(dir: 'libs', include: ['*.jar'])
}
apply from: '../gradle-mvn-push.gradle'
```

## 3. App依赖插件

修改项目更目录下的 **build.gradle** 配置插件仓库和版本

```
buildscript {
    repositories {
        // ...
        mavenLocal()
    }
    dependencies {
      classpath "com.zaze.plugin:z-plugin:1.0.0-SNAPSHOT"}
}

allprojects {
    repositories {
        // ...
        mavenLocal()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
```
修改app下的 **build.gradle** 应用插件
```groovy
apply plugin: 'com.zaze.plugin'
```