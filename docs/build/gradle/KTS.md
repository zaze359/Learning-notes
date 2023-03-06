# KTS

[将 build 配置从 Groovy 迁移到 KTS  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/studio/build/migrate-to-kts?hl=zh-cn)

Android Gradle 插件 4.0 支持在 Gradle build 配置中使用 Kotlin 脚本 (KTS)，用于替代 Groovy（过去在 Gradle 配置文件中使用的编程语言），KTS 比 Groovy 更适合用于编写 Gradle 脚本。

### Groovy 和 KTS 对比

优点：

* Kotlin 编写的代码可读性更高。
* Kotlin 提供了更好的编译时检查和 IDE 支持。

缺点：

* 采用 KTS 的构建速度往往比采用 Groovy 慢。

### 脚本文件命名

脚本文件扩展名取决于编写 build 文件所用的语言：

- 用 Groovy 编写的 Gradle build 文件使用 `.gradle` 文件扩展名。
- 用 Kotlin 编写的 Gradle build 文件使用 `.gradle.kts` 文件扩展名。



---

## Android Groovy 迁移到 KTS

### 字符串定义

迁移时将 单引号 转为 双引号 即可。

> Groovy：允许单引号

```groovy
// 方式一
applicationId 'com.zaze.demo'
// 方式二
applicationId "com.zaze.demo"
```

> KTS：Kotlin 要求**使用双引号定义字符串**

```kotlin
applicationId = "com.zaze.demo"
```

### 字符串插值

Kotlin 中 对于 **基于句点表达式的字符串插值**要求 `${}` 的形式。

```kotlin
myRootDirectory = "${project.rootDir}/tools/proguard-rules-debug.pro"
```

Groovy：以 `$` 为前缀即可

```groovy
myRootDirectory = "$project.rootDir/tools/proguard-rules-debug.pro"
```

### 赋值

> Groovy
>
> 
>
> 

```groovy
// 可以省略 =
applicationId "com.zaze.demo"
applicationId = "com.zaze.demo"
// 命名参数使用 :，可以省略 () 包裹
apply from: "../maven-publish.gradle"
apply(from: "../maven-publish.gradle")
```

> KTS
>
> 必须使用 `=` 赋值
>
> 命名参数也使用 `=`，且需要 `()` 包裹

```kotlin
applicationId = "com.zaze.demo"
apply(from = "../maven-publish.gradle")
```



### 一些参数的命名

在 kotlin 中 对于一些 Boolean的参数 一般为 `is*` 的格式，不同于 Groovy 中并不是 `is` 开头。 所以在迁移过程中碰到此类参数报错时可以直接尝试 添加 `is`。

例如：

> Groovy

```groovy
lintOptions {
  abortOnError false
}
dataBinding {
  enabled = true
}
```

> KTS

```kotlin
lintOptions {
  isAbortOnError = false
}
dataBinding {
  isEnabled = true
}
```

### properties

> grade.properties

```properties
APP_VERSION=1.0.1
```

>  Groovy

```groovy
// 可以直接获取
APP_VERSION
```

```kotlin
// 
val APP_VERSION: String by extra
// 或
val APP_VERSION: String by rootProject.extra
// 以下等同
// val APP_VERSION: String by rootProject.ext
```

### ext

> Groovy 

```groovy
// 定义扩展参数
ext {
  compileSdkVersion = 33
  minSdkVersion = 21
  targetSdkVersion = 33
}

// 获取参数 方式一
compileSdkVersion
// 获取参数 方式二
rootProject.ext.compileSdkVersion
```

> KTS
>
> [ExtraPropertiesExtension - Gradle DSL Version 7.6](https://docs.gradle.org/current/dsl/org.gradle.api.plugins.ExtraPropertiesExtension.html#N1B44A)
>
> 在 kts 的  buildscript  中是无法访问到 ext 的。

```kotlin
// 1 设置 参数
rootProject.ext.set("compileSdkVersion", 33)
// 2
ext {
	set("junitVersion", "4.13.2")
  versionName = "1.0"
}
// 3
project.ext.set("myProp", "myValue")

// 获取 方式一 
// 对于获取的参数 需要进行类型转换
rootProject.ext["compileSdkVersion"] as Int
// 委托获取
val compileSdkVersion: Int by rootProject.ext

// 获取 方式二
project.ext.get("myProp")
```



### signingConfigs

> Groovy

```groovy
signingConfigs {
  debug {
    storeFile file('android_zaze.keystore')
    storePassword 'xxxxx'
    keyAlias 'android'
    keyPassword 'xxxxx'
  }
  release {
    storeFile file('android_zaze.keystore')
    storePassword 'xxxxx
    keyAlias 'android'
    keyPassword 'xxxxx'
  }
}
```

> KTS

```kotlin
signingConfigs {
  named("debug") {
    storeFile = file("android_zaze.keystore")
    storePassword = "xxxxx"
    keyAlias = "android"
    keyPassword = "xxxxx"
  }
  // 需要自己创建 release， buildType中对应即可
  create("release") {
    storeFile = file("android_zaze.keystore")
    storePassword = "xxxxx"
    keyAlias = "android"
    keyPassword = "xxxxx"
  }
}
```



### buildTypes

> Groovy
>
> 提供了 `debug`、`release`、`staging` 。

```groovy
buildTypes {
 debug {
   ...
 }
  release {
    minifyEnabled false
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    signingConfig signingConfigs.release
  }
 staging {
   ...
 }
}
```

> KTS
>
> 仅 `debug` 和 `release` 是隐式提供的，`staging` 必须手动创建。

```kotlin
buildTypes {
 debug {
   ...
 }
 
 release {
   isMinifyEnabled = false
   proguardFiles(
     getDefaultProguardFile("proguard-android-optimize.txt"),
     "proguard-rules.pro"
   )
   // 此处的 release 需要和 signingConfigs 中 create 的对应
   signingConfig = signingConfigs.getByName("release")
 }
  
 // 需要我们自己创建
 create("staging") {
   ...
 }
}
```

也可以使用以下方式

```kotlin
buildTypes {
 getByName("debug") {
   ...
 }
 
 getByName("release") {
   isMinifyEnabled = false
   proguardFiles(
     getDefaultProguardFile("proguard-android-optimize.txt"),
     "proguard-rules.pro"
   )
   // 此处的 release 需要和 signingConfigs 中 create 的对应
   signingConfig = signingConfigs.getByName("release")
 }
  
 // 需要我们自己创建
 create("staging") {
   ...
 }
}
```

### 插件的应用（plugins）

两者同样适用 `plugins` 代码块添加插件，不同点在于 kotlin 需要使用 `()` 包裹，且字符串为双引号。

> Groovy

```groovy
plugins {
   id 'com.android.application'
   id 'kotlin-android'
   id 'kotlin-kapt'
   id 'androidx.navigation.safeargs.kotlin'
 }

apply from : "../maven-publish.gradle"

```

> KTS

```kotlin
plugins {
   id("com.android.application")
   id("kotlin-android")
   id("kotlin-kapt")
   id("androidx.navigation.safeargs.kotlin")
}

apply(from = "../maven-publish.gradle")
```



