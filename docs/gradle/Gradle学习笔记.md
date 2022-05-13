# Gradle学习笔记

## Gradle For Android

### 了解Gradle

Gradle是一种基于Groovy的动态DSL，而Groovy语言是一种基于jvm的动态语言。
所有我们可以使用java语言来开发

### Project And Tasks

每一个build.grade文件代表着一个project.
tasks在build.gradle中定义

### The Build Lifecycle(构建过程)


## Gradle Debug

- 项目根目录创建buildSrc目录

- buildSrc下新建build.gradle

  ```
  repositories {
      mavenLocal()
      jcenter()
      google()
  }
  
  dependencies {
      implementation('com.android.tools.build:gradle:3.2.1')
      implementation('对应的插件')
  }
  ```

- IDEA新建Remote,默认配置即可

- 执行gradle

  ```
  ./gradlew clean xxxx -Dorg.gradle.daemon=false -Dorg.gradle.debug=true
  ```

  

|           |                                               |                                                              |
| --------- | --------------------------------------------- | ------------------------------------------------------------ |
| dependsOn | generateAssetsTask.dependsOn createCopyTask() | 表示在``generateAssetsTask.dependsOn``之前先执行``createCopyTask`` |
|           |                                               |                                                              |
|           |                                               |                                                              |

