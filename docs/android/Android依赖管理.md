# Android依赖管理

## 依赖版本管理

### Gradle 文件管理

本质是 ext 管理，只不过是将所有版本定义到一个 `versions.gradle` 文件中，然后依赖这个gradle。

#### 定义Version文件

```groovy
def build_versions = [:]
ext.build_versions = build_versions

def versions = [:]
versions.lifecycle = "2.5.1"
versions.core_ktx = "1.9.0"
versions.coroutines = "1.4.1"
versions.annotations = "1.5.0"
versions.appcompat = "1.5.1"
versions.activity = '1.6.0'
versions.fragment = "1.5.3"
versions.recyclerview = "1.2.1"
versions.constraint_layout = "2.1.4"
versions.arch_core = "2.1.0"

versions.atsl_core = "1.5.0-alpha02"
versions.atsl_junit = "1.1.3"
versions.atsl_rules = "1.2.0"
versions.atsl_runner = "1.4.0"
versions.espresso = "3.4.0"

versions.truth = "1.1.3"
versions.ext_truth = "1.5.0-rc01"
versions.junit = "4.12"
versions.robolectric = "4.9"

ext.versions = versions

def deps = [:]
ext.deps = [:]

def lifecycle = [:]
lifecycle.process = "androidx.lifecycle:lifecycle-process:$versions.lifecycle"
lifecycle.runtime = "androidx.lifecycle:lifecycle-runtime:$versions.lifecycle"
lifecycle.java8 = "androidx.lifecycle:lifecycle-common-java8:$versions.lifecycle"
lifecycle.compiler = "androidx.lifecycle:lifecycle-compiler:$versions.lifecycle"
lifecycle.viewmodel_ktx = "androidx.lifecycle:lifecycle-viewmodel-ktx:$versions.lifecycle"
lifecycle.livedata_ktx = "androidx.lifecycle:lifecycle-livedata-ktx:$versions.lifecycle"

deps.lifecycle = lifecycle

deps.core_ktx = "androidx.core:core-ktx:$versions.core_ktx"
deps.app_compat = "androidx.appcompat:appcompat:$versions.appcompat"
deps.recyclerview = "androidx.recyclerview:recyclerview:$versions.recyclerview"
deps.annotations = "androidx.annotation:annotation:$versions.annotations"
deps.constraint_layout = "androidx.constraintlayout:constraintlayout:$versions.constraint_layout"

deps.truth = "com.google.truth:truth:$versions.truth"
deps.ext_truth = "androidx.test.ext:truth:$versions.ext_truth"

deps.junit = "junit:junit:$versions.junit"
deps.robolectric = "org.robolectric:robolectric:$versions.robolectric"


def coroutines = [:]
coroutines.android = "org.jetbrains.kotlinx:kotlinx-coroutines-android:$versions.coroutines"
coroutines.test = "org.jetbrains.kotlinx:kotlinx-coroutines-test:$versions.coroutines"
deps.coroutines = coroutines

def activity = [:]
activity.activity_ktx = "androidx.activity:activity-ktx:$versions.activity"
deps.activity = activity

def fragment = [:]
fragment.runtime = "androidx.fragment:fragment:${versions.fragment}"
fragment.runtime_ktx = "androidx.fragment:fragment-ktx:${versions.fragment}"
fragment.testing = "androidx.fragment:fragment-testing:${versions.fragment}"
deps.fragment = fragment

// 单元测试
def atsl = [:]
atsl.core = "androidx.test:core:$versions.atsl_core"
atsl.core_ktx = "androidx.test:core-ktx:$versions.atsl_core"

atsl.ext_junit = "androidx.test.ext:junit:$versions.atsl_junit"
atsl.ext_junit_ktx = "androidx.test.ext:junit-ktx:$versions.atsl_junit"

atsl.runner = "androidx.test:runner:$versions.atsl_runner"
atsl.rules = "androidx.test:rules:$versions.atsl_rules"
deps.atsl = atsl

def espresso = [:]
espresso.core = "androidx.test.espresso:espresso-core:$versions.espresso"
espresso.contrib = "androidx.test.espresso:espresso-contrib:$versions.espresso"
espresso.intents = "androidx.test.espresso:espresso-intents:$versions.espresso"
espresso.remote = "androidx.test.espresso:espresso-remote:$versions.espresso"

deps.espresso = espresso

ext.deps = deps
```

#### 使用方式

1. 通过 apply 导入  versions.gradle。
2. 根据定义的 参数名导入，例如 `deps.atsl.runner`。 **输入时没有自动提示**。

```groovy
// 
apply from: "$project.rootDir/buildscripts/old/versions.gradle"

subprojects {
    if (project.name == 'util') {
        return
    }
    if (project.name == 'app') {
        apply plugin: 'com.android.application'
    } else {
        apply plugin: 'com.android.library'
    }
    apply plugin: 'kotlin-android'
    apply plugin: 'kotlin-kapt'

    android {
        compileSdkVersion Integer.valueOf(libs.versions.compileSdk.get())

        defaultConfig {
           // 获取定义的 minSdk
            minSdkVersion Integer.valueOf(libs.versions.minSdk.get())
            targetSdkVersion rootProject.ext.targetSdkVersion
            versionCode rootProject.ext.versionCode
            versionName rootProject.ext.versionName
            testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        }
    }

    dependencies {
        testImplementation deps.junit
        // Testing-only dependencies
        androidTestImplementation deps.atsl.runner
        androidTestImplementation deps.atsl.core
        androidTestImplementation deps.atsl.core_ktx
        androidTestImplementation deps.atsl.ext_junit
        androidTestImplementation deps.atsl.ext_junit_ktx
        androidTestImplementation deps.espresso.core

        implementation 'io.reactivex.rxjava2:rxandroid:2.1.1'
        implementation 'io.reactivex.rxjava2:rxjava:2.2.21'

        implementation deps.constraint_layout
    }
}


```





### Version Catalog 管理

[将 build 迁移到版本目录  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/studio/build/migrate-to-catalogs?hl=zh-cn)

#### 配置 Version Catalog

> settings.gradle.kts

```kotlin
// 启用
enableFeaturePreview("VERSION_CATALOGS")
// 定义 catalog
dependencyResolutionManagement {
    versionCatalogs {
        create("libs") {
            library(
                "androidx-activity-compose",    // alias
                "androidx.activity",    // group
                "activity-compose"      // artifact
            ).version("1.6.1")
        }
    }
}
```



#### 在 TOML文件中定义

在 项目的 `gradle` 目录中定义 `libs.versions.toml` 文件，将会自动声明 `Catalog` 。

| 配置          | 说明                           |
| ------------- | ------------------------------ |
| `[versions]`  | 用于声明可以被依赖项引用的版本 |
| `[libraries]` | 用于声明`Library`的别名        |
| `[bundles]`   | 用于声明依赖包                 |
| `[plugins]`   | 用于声明插件                   |

| 富版本       |                                                        |                                           |
| ------------ | ------------------------------------------------------ | ----------------------------------------- |
| **strictly** | 严格限制版本，不能超出指定的范围                       | `[3.8, 4.0[` ：表示 3.8 ~ 4.0版本，闭区间 |
| **require**  | 不能低于指定的版本范围，但是可以高于                   |                                           |
| **prefer**   | 偏向于某个版本，没有指定时使用这个版本，即为默认版本。 |                                           |
| **reject**   | 指定需要排除的版本                                     |                                           |

```toml
[versions]
groovy = "3.0.5"
checkstyle = "8.37"

[libraries]
# 引用 groovy 参数
groovy-core = { module = "org.codehaus.groovy:groovy", version.ref = "groovy" }
groovy-json = { module = "org.codehaus.groovy:groovy-json", version.ref = "groovy" }
groovy-nio = { module = "org.codehaus.groovy:groovy-nio", version.ref = "groovy" }
# 
commons-lang3 = { group = "org.apache.commons", name = "commons-lang3", version = { strictly = "[3.8, 4.0[", prefer="3.9" } }

[bundles]
groovy = ["groovy-core", "groovy-json", "groovy-nio"]

[plugins]
jmh = { id = "me.champeau.jmh", version = "0.6.5" }
```



> 完整的 libs.versions.toml 样例

```toml
#####
# This file is duplicated to individual samples from the global scripts/libs.versions.toml
# Do not add a dependency to an individual sample, edit the global version instead.
#####
[versions]
accompanist = "0.27.0"
androidGradlePlugin = "7.3.1"
androidx-activity-compose = "1.6.1"
androidx-appcompat = "1.5.1"
androidx-benchmark = "1.1.0"
androidx-benchmark-junit4 = "1.1.0-beta04"
androidx-compose-bom = "2022.11.00"
androidx-constraintlayout = "1.0.1"
androidx-corektx = "1.9.0"
androidx-lifecycle-compose = "2.5.1"
androidx-lifecycle-runtime-compose = "2.6.0-alpha03"
androidx-navigation = "2.5.3"
androidx-palette = "1.0.0"
androidx-test = "1.5.0"
androidx-test-espresso = "3.5.0"
androidx-test-ext-junit = "1.1.4"
androidx-test-ext-truth = "1.4.0"
androidx-window = "1.1.0-alpha04"
androidxHiltNavigationCompose = "1.0.0"
androix-test-uiautomator = "2.2.0"
coil = "2.2.0"
# @keep
compileSdk = "33"
compose-compiler = "1.3.2"
compose-snapshot = "-"
coroutines = "1.6.4"
google-maps = "18.1.0"
hilt = "2.43.2"
hiltExt = "1.0.0"
# @pin When updating to AGP 7.3.0-beta03 and up we can update this https://developer.android.com/studio/write/java8-support#library-desugaring-versions
jdkDesugar = "1.1.5"
junit = "4.13.2"
# @pin update when updating Compose Compiler
kotlin = "1.7.20"
maps-compose = "2.5.3"
material = "1.8.0-alpha02"
# @keep
minSdk = "21"
okhttp = "4.10.0"
# @pin Bump to latest after Espresso 3.5.0 goes stable (due to https://github.com/robolectric/robolectric/issues/6593)
robolectric = "4.5.1"
rome = "1.18.0"
room = "2.5.0-alpha02"
secrets = "2.0.1"
# @keep
targetSdk = "33"

[libraries]
accompanist-flowlayout = { module = "com.google.accompanist:accompanist-flowlayout", version.ref = "accompanist" }
accompanist-pager = { module = "com.google.accompanist:accompanist-pager", version.ref = "accompanist" }
accompanist-permissions = { module = "com.google.accompanist:accompanist-permissions", version.ref = "accompanist" }
accompanist-swiperefresh = { module = "com.google.accompanist:accompanist-swiperefresh", version.ref = "accompanist" }
accompanist-systemuicontroller = { module = "com.google.accompanist:accompanist-systemuicontroller", version.ref = "accompanist" }
android-gradlePlugin = { module = "com.android.tools.build:gradle", version.ref = "androidGradlePlugin" }
androidx-activity-compose = { module = "androidx.activity:activity-compose", version.ref = "androidx-activity-compose" }
androidx-activity-ktx = { module = "androidx.activity:activity-ktx", version.ref = "androidx-activity-compose" }
androidx-appcompat = { module = "androidx.appcompat:appcompat", version.ref = "androidx-appcompat" }
androidx-benchmark-macrobenchmark = { module = "androidx.benchmark:benchmark-macro", version.ref = "androidx-benchmark" }
androidx-benchmark-macrobenchmark-junit4 = { module = "androidx.benchmark:benchmark-macro-junit4", version.ref = "androidx-benchmark-junit4" }
androidx-compose-animation = { module = "androidx.compose.animation:animation" }
androidx-compose-bom = { module = "androidx.compose:compose-bom", version.ref = "androidx-compose-bom" }
androidx-compose-foundation = { module = "androidx.compose.foundation:foundation" }
androidx-compose-foundation-layout = { module = "androidx.compose.foundation:foundation-layout" }
androidx-compose-material = { module = "androidx.compose.material:material" }
androidx-compose-material-iconsExtended = { module = "androidx.compose.material:material-icons-extended" }
androidx-compose-material3 = { module = "androidx.compose.material3:material3" }
androidx-compose-materialWindow = { module = "androidx.compose.material3:material3-window-size-class" }
androidx-compose-runtime = { module = "androidx.compose.runtime:runtime" }
androidx-compose-runtime-livedata = { module = "androidx.compose.runtime:runtime-livedata" }
androidx-compose-ui = { module = "androidx.compose.ui:ui" }
androidx-compose-ui-googlefonts = { module = "androidx.compose.ui:ui-text-google-fonts" }
androidx-compose-ui-test = { module = "androidx.compose.ui:ui-test" }
androidx-compose-ui-test-junit4 = { module = "androidx.compose.ui:ui-test-junit4" }
androidx-compose-ui-test-manifest = { module = "androidx.compose.ui:ui-test-manifest" }
androidx-compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling" }
androidx-compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview" }
androidx-compose-ui-util = { module = "androidx.compose.ui:ui-util" }
androidx-compose-ui-viewbinding = { module = "androidx.compose.ui:ui-viewbinding" }
androidx-constraintlayout-compose = { module = "androidx.constraintlayout:constraintlayout-compose", version.ref = "androidx-constraintlayout" }
androidx-core-ktx = { module = "androidx.core:core-ktx", version.ref = "androidx-corektx" }
androidx-hilt-navigation-compose = { module = "androidx.hilt:hilt-navigation-compose", version.ref = "androidxHiltNavigationCompose" }
androidx-lifecycle-livedata-ktx = { module = "androidx.lifecycle:lifecycle-viewmodel-ktx", version.ref = "androidx-lifecycle-compose" }
androidx-lifecycle-runtime = { module = "androidx.lifecycle:lifecycle-runtime-ktx", version.ref = "androidx-lifecycle-compose" }
androidx-lifecycle-runtime-compose = { module = "androidx.lifecycle:lifecycle-runtime-compose", version.ref = "androidx-lifecycle-runtime-compose" }
androidx-lifecycle-viewModelCompose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "androidx-lifecycle-compose" }
androidx-lifecycle-viewmodel-ktx = { module = "androidx.lifecycle:lifecycle-viewmodel-ktx", version.ref = "androidx-lifecycle-compose" }
androidx-lifecycle-viewmodel-savedstate = { module = "androidx.lifecycle:lifecycle-viewmodel-savedstate", version.ref = "androidx-lifecycle-compose" }
androidx-navigation-compose = { module = "androidx.navigation:navigation-compose", version.ref = "androidx-navigation" }
androidx-navigation-fragment = { module = "androidx.navigation:navigation-fragment-ktx", version.ref = "androidx-navigation" }
androidx-navigation-ui-ktx = { module = "androidx.navigation:navigation-ui-ktx", version.ref = "androidx-navigation" }
androidx-palette = { module = "androidx.palette:palette", version.ref = "androidx-palette" }
androidx-room-compiler = { module = "androidx.room:room-compiler", version.ref = "room" }
androidx-room-ktx = { module = "androidx.room:room-ktx", version.ref = "room" }
androidx-room-runtime = { module = "androidx.room:room-runtime", version.ref = "room" }
androidx-test-core = { module = "androidx.test:core", version.ref = "androidx-test" }
androidx-test-espresso-core = { module = "androidx.test.espresso:espresso-core", version.ref = "androidx-test-espresso" }
androidx-test-ext-junit = { module = "androidx.test.ext:junit", version.ref = "androidx-test-ext-junit" }
androidx-test-ext-truth = { module = "androidx.test.ext:truth", version.ref = "androidx-test-ext-truth" }
androidx-test-rules = { module = "androidx.test:rules", version.ref = "androidx-test" }
androidx-test-runner = "androidx.test:runner:1.5.1"
androidx-test-uiautomator = { module = "androidx.test.uiautomator:uiautomator", version.ref = "androix-test-uiautomator" }
androidx-window = { module = "androidx.window:window", version.ref = "androidx-window" }
coil-kt-compose = { module = "io.coil-kt:coil-compose", version.ref = "coil" }
core-jdk-desugaring = { module = "com.android.tools:desugar_jdk_libs", version.ref = "jdkDesugar" }
google-android-material = { module = "com.google.android.material:material", version.ref = "material" }
googlemaps-compose = { module = "com.google.maps.android:maps-compose", version.ref = "maps-compose" }
googlemaps-maps = { module = "com.google.android.gms:play-services-maps", version.ref = "google-maps" }
hilt-android = { module = "com.google.dagger:hilt-android", version.ref = "hilt" }
hilt-android-testing = { module = "com.google.dagger:hilt-android-testing", version.ref = "hilt" }
hilt-compiler = { module = "com.google.dagger:hilt-android-compiler", version.ref = "hilt" }
hilt-ext-compiler = { module = "androidx.hilt:hilt-compiler", version.ref = "hiltExt" }
hilt-gradlePlugin = { module = "com.google.dagger:hilt-android-gradle-plugin", version.ref = "hilt" }
junit = { module = "junit:junit", version.ref = "junit" }
kotlin-gradlePlugin = { module = "org.jetbrains.kotlin:kotlin-gradle-plugin", version.ref = "kotlin" }
kotlin-stdlib = { module = "org.jetbrains.kotlin:kotlin-stdlib-jdk8", version.ref = "kotlin" }
kotlinx-coroutines-android = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "coroutines" }
okhttp-logging = { module = "com.squareup.okhttp3:logging-interceptor", version.ref = "okhttp" }
okhttp3 = { module = "com.squareup.okhttp3:okhttp", version.ref = "okhttp" }
robolectric = { module = "org.robolectric:robolectric", version.ref = "robolectric" }
rometools-modules = { module = "com.rometools:rome-modules", version.ref = "rome" }
rometools-rome = { module = "com.rometools:rome", version.ref = "rome" }
secrets-gradlePlugin = { module = "com.google.android.libraries.mapsplatform.secrets-gradle-plugin:secrets-gradle-plugin", version.ref = "secrets" }

```



```kotlin
targetSdk = libs.versions.targetSdk.get().toInt()
```

#### 使用方式

之前：

```kotlin
// Top-level build.gradle.kts file
plugins {
   id("com.android.application") version '7.3.0' apply false
   ...
}

// Module-level build.gradle.kts file
plugins {
   id("com.android.application")
   ...
}
```

使用 Version Catalog 后：

```kotlin
// Top-level build.gradle.kts file
plugins {
   // 在 catalog 内部包含了版本
   alias(libs.plugins.android.application) apply false
   ...
}

// Module-level build.gradle.kts file
@Suppress("DSL_SCOPE_VIOLATION") // 低于 8.1 的 Gradle 版本，需要添加此注解
plugins {
   alias(libs.plugins.android.application)
   // 由于在Top-level中已经声明过插件，所以也可以之间使用id
   // id("com.android.application")
   ...
}


dependencies {
  // 访问 androidx-activity-compose，输入时是有提示的。
	implementation(libs.androidx.activity.compose)
	// 直接访问返回的是一个 provider，需要调用 get() 获取具体的值
	println("libs.androidx.activity.aaaa: ${libs.androidx.activity.aaaa.get()}")
}


```

## 公共依赖管理方式

定义 common 模块，然后通过 api的方式进行依赖，那么所有依赖这个 project。

### 全局Gradle

#### 配置方式

一般会定一个 `Common.gradle` 内部 统一写公共的基础依赖，然后各个模块 apply 这个文件。
有时候可能会直接在根目录下的 `build.gradle`中配置。这样所有的模块都会依赖这个gradle（此时可能需要针对不同的模块的做一些特殊处理，例如下面的util）。

```groovy
apply from: "$project.rootDir/buildscripts/versions.gradle"

// 对所有的模块配置
subprojects {
    println("project.name:  ${project.name}")
    // util 模块 并不想 配置下面这些
    if (project.name == 'util') {
        return
    }
    if (project.name == 'app') { // main app
        apply plugin: 'com.android.application'
    } else {
        apply plugin: 'com.android.library'
    }
    apply plugin: 'kotlin-android'
    apply plugin: 'kotlin-kapt'

    android {
        compileSdkVersion Integer.valueOf(libs.versions.compileSdk.get())

        defaultConfig {
            minSdkVersion Integer.valueOf(libs.versions.minSdk.get())
            targetSdkVersion rootProject.ext.targetSdkVersion
            versionCode rootProject.ext.versionCode
            versionName rootProject.ext.versionName
//            flavorDimensions "$rootProject.ext.versionCode"
            testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
            // 仅中文
//            resConfigs "zh"
        }
        lintOptions {
            abortOnError false
        }

        buildFeatures {
            dataBinding true
        }

    }

    dependencies {
        testImplementation deps.junit
        androidTestImplementation deps.atsl.runner
        androidTestImplementation deps.atsl.core
        androidTestImplementation deps.atsl.core_ktx
        androidTestImplementation deps.atsl.ext_junit
        androidTestImplementation deps.atsl.ext_junit_ktx
        androidTestImplementation deps.espresso.core
        implementation "org.jetbrains.kotlin:kotlin-stdlib:$kotlin_version"
        implementation deps.coroutines.android

        implementation 'com.google.code.gson:gson:2.8.6'
        implementation 'com.google.android.material:material:1.6.1'
        implementation 'com.squareup.okhttp3:okhttp:5.0.0-alpha.2'

        implementation 'io.reactivex.rxjava2:rxandroid:2.1.1'
        implementation 'io.reactivex.rxjava2:rxjava:2.2.21'

        implementation deps.constraint_layout
        implementation deps.annotations
        implementation deps.recyclerview
        implementation deps.core_ktx
        implementation deps.app_compat
        implementation deps.fragment.runtime_ktx
        implementation deps.lifecycle.runtime
        implementation deps.lifecycle.service
        implementation deps.lifecycle.process
        implementation deps.lifecycle.viewmodel_ktx
        implementation deps.lifecycle.livedata_ktx
    }
}

```

#### 存在的问题

1. 这个配置对项目下的所有模块都会生效