# Compose配置

[将 Jetpack Compose 添加到应用中  | Android Developers (google.cn)](https://developer.android.google.cn/jetpack/compose/interop/adding)

[快速入门  | Jetpack Compose  | Android Developers](https://developer.android.com/jetpack/compose/setup)

[Jetpack Compose 基础知识  | Android Developers](https://developer.android.com/codelabs/jetpack-compose-basics?continue=https%3A%2F%2Fdeveloper.android.com%2Fcourses%2Fpathways%2Fcompose%23codelab-https%3A%2F%2Fdeveloper.android.com%2Fcodelabs%2Fjetpack-compose-basics#0)

## 配置Android Gradle插件版本

配置``root/build.gradle``

```groovy
buildscript {
    ...
    dependencies {
        classpath "com.android.tools.build:gradle:7.2.2"
        ...
    }
}
```

## 配置Kotlin版本

配置``app/build.gradle``

```groovy
buildscript {
		ext {
        kotlin_version = '1.7.20'
    }
    ...
    dependencies {
				classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        ...
    }
}
```

添加kotlin插件

```groovy
plugins {
    id 'kotlin-android'
}
```

## Gradle参数配置

最低 API 级别设置为 21 或更高级别，并且开启 Jetpack Compose

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
        kotlinCompilerExtensionVersion '1.3.2'
    }
}
```

## 添加依赖项

> 使用 `activity-compose` 依赖项时，`androidx.activity` 也必须位于 1.3.0 版中。

```groovy
dependencies {
    // Integration with activities
    implementation 'androidx.activity:activity-compose:1.5.1'
    // Compose Material Design
    implementation 'androidx.compose.material:material:1.2.1'
    // Animations
    implementation 'androidx.compose.animation:animation:1.2.1'
    // Tooling support (Previews, etc.)
    implementation 'androidx.compose.ui:ui-tooling:1.2.1'
    // Integration with ViewModels
    implementation 'androidx.lifecycle:lifecycle-viewmodel-compose:2.5.1'
    // UI Tests
    androidTestImplementation 'androidx.compose.ui:ui-test-junit4:1.2.1'
}
```



## 其他配置

### 需要Java 11



![image-20220428133332778](Compose配置.assets/image-20220428133332778.png)

### Gradle

```
compileSdkVersion = 31
minSdkVersion = 21
```
