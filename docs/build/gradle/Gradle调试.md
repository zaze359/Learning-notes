## Gradle Debug

## 1. 创建`buildSrc`目录

在 项目根目录创建`buildSrc`目录。

## 2. 新建`build.gradle`

在 `buildSrc`下新建`build.gradle` 文件。

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

## 3. 新建`Remote`

在 IDEA 中新建`Remote`，默认配置即可。

## 4. 启动调试

```shell
./gradlew clean xxxx -Dorg.gradle.daemon=false -Dorg.gradle.debug=true
```



## 查看Gradle Plugin源码

新建一个module，添加gradle依赖：

```groovy
implementation 'com.android.tools.build:gradle:4.2.2'
```

|           |                                               |                                                              |
| --------- | --------------------------------------------- | ------------------------------------------------------------ |
| dependsOn | generateAssetsTask.dependsOn createCopyTask() | 表示在``generateAssetsTask.dependsOn``之前先执行``createCopyTask`` |
|           |                                               |                                                              |
|           |                                               |                                                              |

