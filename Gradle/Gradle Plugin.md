---
title: Gradle Plugin
date: 2020-07-24 18:11
---

# Gradle Plugin
[TOC]
## 1. 项目结构
![](./_image/2020-07-24/2020-07-31-16-39-12.png)
- 创建module
- 删除文件, 仅保留build.gradle
- 新建文件夹src/main/groovy
- 新建resources/META-INF/gradle-plugins文件夹
- 创建 xxx.properties文件
```properties
// 指向插件入口
// xxx即为插件id (com.zaze.plugin)
implementation-class=com.zaze.plugin.PluginLauncher
```
## 2.  plugin 项目gradle 配置
- 修改build.gradle
```groovy
apply plugin: 'groovy'
dependencies {
    implementation gradleApi()
    implementation localGroovy()
    implementation fileTree(dir: 'libs', include: ['*.jar'])
}
apply from: '../gradle-mvn-push.gradle'
```
- gradle-mvn-push.gradle
```groovy
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
## 3. 基于groovy开发，创建groovy文件
...
## 4. 项目配置依赖
- 项目 build.gradle
```groovy
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
- app build.gradle
```groovy
apply plugin: 'com.zaze.plugin'
```