# Android中的依赖注入

[TOC]

[Android 中的依赖项注入  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection?hl=zh_cn)

- 重用代码

- 易于重构

- 易于测试

主要的依赖项注入方式

- 构造函数注入
- 字段注入（或setter注入）

自动依赖项注入

- 基于反射的解决方案，可在运行时连接依赖项。(Guice)
- 静态解决方案，可生成在编译时连接依赖项的代码。(Dagger)

## 自动依赖注入

### Hilt接入

[使用 Hilt 实现依赖项注入  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection/hilt-android?hl=zh_cn)

#### 添加依赖项

项目根目录build.gradle

```
buildscript {
    ...
    dependencies {
        ...
        classpath 'com.google.dagger:hilt-android-gradle-plugin:2.33-beta'
    }
}
```

app/build.gradle

```
...
apply plugin: 'kotlin-kapt'
apply plugin: 'dagger.hilt.android.plugin'

android {
    ...
}

dependencies {
    implementation "com.google.dagger:hilt-android:2.33-beta"
    kapt "com.google.dagger:hilt-android-compiler:2.33-beta"
}
```

需使用Java8

```
android {
  ...
  compileOptions {
    sourceCompatibility JavaVersion.VERSION_1_8
    targetCompatibility JavaVersion.VERSION_1_8
  }
}
```

#### @HiltAndroidApp

所有使用 Hilt 的应用都必须包含一个带有 `@HiltAndroidApp` 注释的 `Application` 类。

`@HiltAndroidApp` 会触发 Hilt 的代码生成操作，生成的代码包括应用的一个基类，该基类充当应用级依赖项容器。

```kotlin
@HiltAndroidApp
class ExampleApplication : Application() { ... }
```

#### @AndroidEntryPoint

- `Application`（通过使用 `@HiltAndroidApp`）
- `Activity`
- `Fragment`
- `View`
- `Service`
- `BroadcastReceiver`

```kotlin
@AndroidEntryPoint
class ExampleActivity : AppCompatActivity() { ... }
```

### Hilt注入

如需从组件获取依赖项，请使用 `@Inject` 注释执行字段注入

```kotlin
@AndroidEntryPoint
class ExampleActivity : AppCompatActivity() {
  @Inject lateinit var analytics: AnalyticsAdapter
  ...
}
```

#### 构造函数注入

```kotlin
class AnalyticsAdapter @Inject constructor(
  private val service: AnalyticsService
) { ... }
```

#### Hilt模块

##### @InstallIn: 告知用于哪里

##### @Binds 注入接口实例

- **函数返回类型 **：会告知 Hilt 函数提供**哪个接口**的实例。
- **函数参数** ：会告知 Hilt 要提供**哪种实现**。

```kotlin
interface AnalyticsService {
  fun analyticsMethods()
}

// Constructor-injected, because Hilt needs to know how to
// provide instances of AnalyticsServiceImpl, too.
class AnalyticsServiceImpl @Inject constructor(
  ...
) : AnalyticsService { ... }

@Module
@InstallIn(ActivityComponent::class)
abstract class AnalyticsModule {

  @Binds
  abstract fun bindAnalyticsService(
    analyticsServiceImpl: AnalyticsServiceImpl
  ): AnalyticsService
}
```

##### @Provides 注入实例(用于注入外部库中的类)

- 函数返回类型会告知 Hilt 函数提供哪个类型的实例。
- 函数参数会告知 Hilt 相应类型的依赖项。
- 函数主体会告知 Hilt 如何提供相应类型的实例。每当需要提供该类型的实例时，Hilt 都会执行函数主体。

```kotlin
@Module
@InstallIn(ActivityComponent::class)
object AnalyticsModule {

  @Provides
  fun provideAnalyticsService(
    // Potential dependencies of this type
  ): AnalyticsService {
      return Retrofit.Builder()
               .baseUrl("https://example.com")
               .build()
               .create(AnalyticsService::class.java)
  }
}
```

##### 组件作用域

- Hilt中的所有绑定默认都未限定作用域



### Hilt 和Jetpack集成

#### 使用 Hilt 注入 ViewModel 对象

```groovy
...
dependencies {
  ...
  implementation 'androidx.hilt:hilt-lifecycle-viewmodel:1.0.0-alpha01'
  // When using Kotlin.
  kapt 'androidx.hilt:hilt-compiler:1.0.0-alpha01'
  // When using Java.
  annotationProcessor 'androidx.hilt:hilt-compiler:1.0.0-alpha01'
}
```

```kotlin
class ExampleViewModel @ViewModelInject constructor(
  private val repository: ExampleRepository,
  @Assisted private val savedStateHandle: SavedStateHandle
) : ViewModel() {
  ...
}
```

