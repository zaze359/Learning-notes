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

## 

## Hilt配置

[使用 Hilt 实现依赖项注入  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection/hilt-android?hl=zh_cn)

### 添加依赖项

项目根目录build.gradle

```groovy
buildscript {
    ext {
        hiltVersion = '2.44'
    }
    ...
    dependencies {
        ...
        classpath "com.google.dagger:hilt-android-gradle-plugin:$hiltVersion"
    }
}
```

app/build.gradle

```groovy
...

plugins {
    id 'kotlin-kapt'
    id 'com.google.dagger.hilt.android'
//    id 'dagger.hilt.android.plugin'
}

android {
    ...
        
    kapt {
        correctErrorTypes true
    }
}

dependencies {
    implementation "com.google.dagger:hilt-android:$hiltVersion"
    kapt "com.google.dagger:hilt-android-compiler:$hiltVersion"
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



## 使用Hilt

### 初始化应用：@HiltAndroidApp

所有使用 Hilt 的应用都必须包含一个带有 `@HiltAndroidApp` 注释的 `Application` 类。

`@HiltAndroidApp` 会触发 Hilt 的代码生成操作，生成的代码包括应用的一个基类，该基类充当应用级依赖项容器。

```kotlin
@HiltAndroidApp
class ExampleApplication : Application() { ... }
```

### 添加注入入口：@AndroidEntryPoint

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

### 注入和绑定：@Inject

#### 字段注入

```kotlin
@AndroidEntryPoint
class ExampleActivity : AppCompatActivity() {
  // 绑定字段
  @Inject lateinit var analytics: AnalyticsAdapter
  ...
}
```

#### 构造函数注入定义 Hilt 绑定

通过构造函数注入的方式，告知如何提供该类的实例。

```kotlin
// 构造函数注入
class AnalyticsAdapter @Inject constructor(
  private val service: AnalyticsService // 此依赖性也需要注入，通过接口注入的方式。这里字段不必再使用@Inject
) { ... }
```

### 定义Hilt模块：@Module

`@Module`：定义 Hilt 模块。**说明如何提供类型的实例**。

`@InstallIn`：告知应用于哪里 Android 类。即和相关类生命周期绑定。

| Hilt 组件                 | 注入器面向的对象                           | 创建时机                         | 销毁时机                                   |
| ------------------------- | ------------------------------------------ | -------------------------------- | ------------------------------------------ |
| SingletonComponent        | Application                                | Application#onCreate()           | `Application` 已销毁                       |
| ActivityRetainedComponent |                                            | 第一次调用 `Activity#onCreate()` | 最后一次调用 `Activity#onDestroy()` 时销毁 |
| ViewModelComponent        | ViewModel                                  | `ViewModel` 已创建               | `ViewModel` 已销毁                         |
| ActivityComponent         | Activity                                   | Activity#onCreate()              | Activity#onDestroy()                       |
| FragmentComponent         | Fragment                                   | Fragment#onAttach()              | Fragment#onDestroy()                       |
| ViewComponent             | View                                       | View#super()                     | `View` 已销毁                              |
| ViewWithFragmentComponent | 带有 `@WithFragmentBindings` 注解的 `View` | View#super()                     | `View` 已销毁                              |
| ServiceComponent          | Service                                    | Service#onCreate()               | Service#onDestroy()                        |

```kotlin
@Module
@InstallIn(ActivityComponent::class)
abstract class AnalyticsModule {

}
```

### 接口注入：@Binds

- **函数返回类型 **：会告知 Hilt 函数**提供哪个接口的实例**。
- **函数参数** ：会告知 Hilt 要**提供哪种实现**。

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

  // AnalyticsService 接口的实现为 AnalyticsServiceImpl
  @Binds
  abstract fun bindAnalyticsService(
    analyticsServiceImpl: AnalyticsServiceImpl
  ): AnalyticsService
}
```

### 外部库类注入：@Provides

> 也能用于内部类的构造。

- **函数返回类型**：告知 Hilt 函数提供哪个类型的实例。
- **函数参数**：告知 Hilt 相应类型的依赖项。
- **函数主体**：告知 Hilt 如何提供相应类型的实例。每当需要提供该类型的实例时，Hilt 都会执行函数主体。

```kotlin
@Module
@InstallIn(ActivityComponent::class)
object AnalyticsModule {

  @Provides
  fun provideAnalyticsService(
    // Potential dependencies of this type
  ): AnalyticsService {
      // 构建 AnalyticsService 的实例
      return Retrofit.Builder()
               .baseUrl("https://example.com")
               .build()
               .create(AnalyticsService::class.java)
  }
}
```

### 组件作用域

- Hilt中的所有绑定默认都未限定作用域



## 同一类型 提供多个绑定

* 定义注解：表明用途。
* 在  `@Binds` 或 `Provides` 中添加注解限定符，和对于注解绑定。
* 在注入字段时 声明注解，注入对应的实例。

```kotlin
// 定义注解
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class AuthInterceptorOkHttpClient

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class OtherInterceptorOkHttpClient


@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

  // 声明 使用 AuthInterceptorOkHttpClient 注解 时如何提供实例
  @AuthInterceptorOkHttpClient
  @Provides
  fun provideAuthInterceptorOkHttpClient(
    authInterceptor: AuthInterceptor
  ): OkHttpClient {
      return OkHttpClient.Builder()
               .addInterceptor(authInterceptor)
               .build()
  }

  @OtherInterceptorOkHttpClient
  @Provides
  fun provideOtherInterceptorOkHttpClient(
    otherInterceptor: OtherInterceptor
  ): OkHttpClient {
      return OkHttpClient.Builder()
               .addInterceptor(otherInterceptor)
               .build()
  }
}


// 使用注解 注入对应的实例
class ExampleServiceImpl @Inject constructor(
  @AuthInterceptorOkHttpClient private val okHttpClient: OkHttpClient
) : ...
```



## Hilt 和Jetpack集成

### 使用 Hilt 注入 ViewModel 对象

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

> Compose 中使用 hilt 构造viewModel

```kotlin
dependencies {
  implementation("androidx.hilt:hilt-navigation-compose:1.0.0")
  implementation("com.google.dagger:hilt-android:2.43.2")
  kapt("com.google.dagger:hilt-android-compiler:2.43.2")
  kapt("androidx.hilt:hilt-compiler:1.0.0")
}
```

使用 `hiltViewModel` 构建 ViewModel

> 此函数调用后 会生成 `HiltViewModelFactory` 处理 hilt 逻辑 ，并保存在 `ComponentActivity.mDefaultFactory` 中 ，
>
> 从而在同一个 activity 中，即使后续调用的是 `viewModel()`， 能正常构建。

```kotlin
val homeViewModel: HomeViewModel = hiltViewModel()
```



