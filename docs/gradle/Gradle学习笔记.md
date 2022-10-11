# Gradle学习笔记

> 参考资料：
>
> [关于 Gradle 你应该知道的知识点 - 掘金 (juejin.cn)](https://juejin.cn/post/7064350945756332040)
>
> [The Apache Groovy programming language - Download](https://groovy.apache.org/download.html)
>
> [深度探索 Gradle 自动化构建技术（二、Groovy 筑基篇） - 掘金 (juejin.cn)](https://juejin.cn/post/6844904128594853902)

`Gradle`是一种基于Groovy的一款强大的构建工具。而`Groovy`语言是一种基于jvm的动态DSL。
所有我们也可以使用java、kotin来开发。

|                   |                                                              |                                |
| ----------------- | ------------------------------------------------------------ | ------------------------------ |
| gradlew           | 对gradle脚本的封装，执行对于版本的gradle命令                 |                                |
| gradle-wapper     | 读取gradle配置文件，自动进行下载和配置gradle                 |                                |
| gradle.properties | 参数配置文件, gradle启动时默认会读取并加载其中的参数。等同命令行传参，但是优先级较低 |                                |
| settings.gradle   | 描述构建所需的模块。                                         | 分隔符`:`类似`/`，表示目录层级 |
| build.gradle      | 配置当前模块的构建信息。                                     |                                |

## 常用命令

```shell

# 清除、构建、日志输出
# --info 打印info日志
# --debug 调试模式 
# --stacktrace 打印堆栈信息
./gradlew clean build --info --debug --stacktrace

# -p 指定模块操作
./gradlew -p moduleName

# debug打包
./gradlew assembleDebug
# Release打包
./gradlew assembleRelease


# 查看依赖
./gradlew dependencies

# 查看gradle版本
./gradlew -v

# 编译并安装debug包。
./gradlew installDebug
# 编译并安装Release包。
./gradlew installRelease

# 性能报告: build/reports/profile
./gradlew build --profile


# 查看主要的task任务
./gradlew tasks
# 查看所有任务
./gradlew tasks --all
```

## 注意事项

Groovy中的 `==` 等同java的`equals()`,  比较对象是否为同一个应该用 `.is()`

## Gradle For Android

### Project And Tasks

每一个待编译的工程都包含一个`build.grade`文件，表示一个`Project`。
每个Project包含一系列的tasks，在build.gradle中定义。例如编译源码Task, 资源编译Task, lint task, 打包task、签名task等

### 依赖管理

| 依赖模式       |                                                              |                                                              |
| -------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| implementation | 该依赖方式所依赖的库不会传递(只会在当前module中生效)。远程库依赖时依然存在依赖传递 |                                                              |
| api            | 该依赖方式会传递所依赖的库。                                 |                                                              |
| compileOnly    | 只在编译时有效，不参与打包。                                 | 使用场景:<br/>- 单模块调试时, 将其他模块标志为compileOnly<br/>- 处理依赖冲突<br/>- 动态加载jar? |
| runtimeOnly    | 编译时不参与, 只参与apk打包                                  |                                                              |

添加依赖：

```groovy
// 仅单元测试依赖 
testImplementation 'junit:junit:4.13.2'
// 仅 android Test依赖
androidTestImplementation 'androidx.test.ext:junit:1.1.2'
// 模块内依赖
implementation 'androidx.core:core-ktx:1.3.1'
// 依赖 util 模块
implementation project(':util')
// debugImplementation 仅在Debug依赖
```

排除某些不需要的依赖：

```groovy
implementation project(':util') {
    // 排除util中的 support依赖
    exclude group: 'com.android.support'
}
```

### gradle.properties相关配置

```properties

# 仅第一次编译时会开启开启线程守护（Gradle 3.0版本以后默认支持）
org.gradle.daemon=true 
# 开启并行编译
org.gradle.parallel=true
# 需选择进行编译，仅编译相关的 Module
org.gradle.configureondemand=true  
# 配置虚拟机大小，
# -Xmx2048m ：JVM 最大允许分配的堆内存2048MB
# -XX:MaxPermSize=512m：JVM 最大允许分配的非堆内存为 512MB
org.gradle.jvmargs=-Xmx2048m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8 
# 开启构建缓存
org.gradle.caching=true
```

### Gradle的生命周期

> 生命周期：

初始化阶段`Initialization` -> 配置阶段`Configuration` -> 执行阶段`Execution`

1. 初始化阶段：决定哪些项目模块（Project）要参与构建。
2. 配置阶段：配置每个项目的模块，执行其中配置脚本。
3. 执行阶段：执行每个参与构建过程的Gradle task。

> 构建过程：

`init script` -> `setting script` -> `root build script` -> `build script` 。

#### Initialization阶段

初始化阶段执行了`init script`和`settings script`。

* `init script`读取全局脚本，初始化一些全局属性，例如gradle version、gradle user home等。
* `settings script`则是执行`settings.gradle`文件。

#### Configuration阶段

初始化阶段后，进入配置阶段，开始加载项目中所有的`build scripte`, 创建对应的task, 构造出任务依赖图。

* `build script`就是执行`build.gradle`创建任务。

#### Execution阶段

真正执行编译和打包的阶段。执行所有task。

#### Gradle Hook点

![img](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/428ff3d7635e4dc8b16fbdca8e60e9d6~tplv-k3u1fbpfcp-zoom-in-crop-mark:3024:0:0:0.awebp)

| Hook点            | 说明                                                         |
| ----------------- | ------------------------------------------------------------ |
| settingsEvaluated | 在 `setting script` 被执行完毕后回调。                       |
| projectsLoaded    | 回调时各个模块的project对象已被创建，但是`build script`仍未执行，所以无法获取到配置信息。 |
| afterEvaluate     | `build.gradle`执行完毕后回调。此时当前`build.gradle`中的所有配置项都能够被访问到。 |
| projectsEvaluated | 所有的project配置结束后回调。                                |
| graphPopulated    | task graph生成后回调。                                       |
| buildFinished     | 所有的task执行完毕后回调。                                   |



## 查看Gradle Plugin源码

新建一个module，添加gradle依赖：

```groovy
implementation 'com.android.tools.build:gradle:4.2.2'
```

### 

## Gradle Debug

- 项目根目录创建`buildSrc`目录

- `buildSrc`下新建`build.gradle`

  ```groovy
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

- IDEA新建`Remote`,默认配置即可

- 执行gradle

  ```shell
  ./gradlew clean xxxx -Dorg.gradle.daemon=false -Dorg.gradle.debug=true
  ```

  

|           |                                               |                                                              |
| --------- | --------------------------------------------- | ------------------------------------------------------------ |
| dependsOn | generateAssetsTask.dependsOn createCopyTask() | 表示在``generateAssetsTask.dependsOn``之前先执行``createCopyTask`` |
|           |                                               |                                                              |
|           |                                               |                                                              |

