# Compose

[Jetpack Compose  | Android Developers (google.cn)](https://developer.android.google.cn/jetpack/compose/interop)

- Compose 编程思想

  https://developer.android.google.cn/jetpack/compose/mental-model

- GitHub repo 模板

  https://github.com/android/android-dev-challenge-compose

- Compose 中的布局

  https://developer.android.google.cn/jetpack/compose/layout

- Compose 文档: 列表

  https://youtu.be/BhqPpUYJYeQ

- Compose pathway

  https://developer.android.google.cn/courses/pathways/compose

- 提交作品

  https://developer.android.google.cn/dev-challenge#the-latest-challenge



## 设置开发环境

[将 Jetpack Compose 添加到应用中  | Android Developers (google.cn)](https://developer.android.google.cn/jetpack/compose/interop/adding)

### 1. 配置Android Gradle插件版本

配置``项目/build.gradle``, 需要 gradle版本``7.0.0``及以上。

```groovy
buildscript {
    ...
    dependencies {
        classpath "com.android.tools.build:gradle:7.0.0"
        ...
    }
}
```

### 2. 配置Kotlin

配置``项目/build.gradle``， 需要kotlin版本``1.6.10``及以上。

```groovy
buildscript {
		ext {
        kotlin_version = '1.6.10'
    }
    ...
    dependencies {
				classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        ...
    }
}
```

添加kotlin插件

```
plugins {
    id 'kotlin-android'
}
```

### 3. 配置Gradle

```groovy
android {
    defaultConfig {
        ...
        minSdkVersion 21
    }

    buildFeatures {
        // Enables Jetpack Compose for this module
        compose true
    }
    ...

    // Set both the Java and Kotlin compilers to target Java 8.
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }

    composeOptions {
        kotlinCompilerExtensionVersion '1.1.1'
    }
}
```



### 4. 其他配置

#### 需要Java 11



![image-20220428133332778](Compose资料.assets/image-20220428133332778.png)

#### Gradle

```
compileSdkVersion = 31
minSdkVersion = 21

```



