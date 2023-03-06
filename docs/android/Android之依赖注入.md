# Android中的依赖注入

[TOC]

## 依赖注入

[Android 中的依赖项注入  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection?hl=zh_cn)

一个类常常会需要引用其他的类才能正常的使用，这些引用的类称为**依赖项**。

这些依赖项一般通过以下方式获取：

* **由类自己来初始化依赖项**：两者耦合太深，依赖项不容易替换，且不方便测试。
* **调用特定的API在需要时主动获取**：需要通过某一个类来获取依赖项，同样不容易替换且不方便测试。（如 `Context` getter 和 `getSystemService()`）
* **通过依赖注入的方式**：作为函数的参数提供依赖项。
  * **构造函数注入**：作为构造函数的入参由外部传入依赖项。
  * **字段注入**：例如定义 `setter()` 函数来出入依赖项。

依赖注入基于控制反转原则，通用代码控制特定代码的执行。使用依赖注入有以下几个优点：

- **重用代码**

- **易于重构**

- **易于测试**

依赖注入也带来了一些问题，当依赖项越来越多，层级越来越深，需要注入的参数越多，手动注入依赖十分麻烦。

从而就出现了一些自动依赖项注入的框架。

自动依赖项注入框架一般可分为两类：

- **基于反射的解决方案**：可在**运行时**连接依赖项。(Guice)
- **静态解决方案**：可生成在**编译时**连接依赖项的代码。(Dagger，Hilt)



## Hilt的使用

[使用 Hilt 实现依赖项注入  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection/hilt-android?hl=zh_cn)

Hilt 是在 Dagger 基础上构建而成的，因而能够受益于 Dagger 提供的编译时正确性、运行时性能、可伸缩性和 Android Studio 支持。

### 基础概念

首先需要了解一些Hilt中的概念：

* **绑定(bindings)**：就是指 **将某个类型的实例作为依赖项 提供所需的信息**。提供绑定信息存在三种方式。
  * 构造函数注入
  * @Binds
  * @Provider
* **模块(modules)**：使用@Module定义的Hilt模块。我们可以在**模块内部定义自定义的绑定**。
* **组件(Component)**：**每个 可以执行字段注入的Android 类都会对应一个组件**，且它们的生命周期绑定。模块需要安装到指定的组件上使用，将模块安装到组件后，**每个 Hilt 组件负责将其绑定注入相应的 Android 类中**。
* **组件作用域(Component scopes)**：将绑定的作用域 限定在特定组件中。默认不存在作用域，即每次绑定请求都会创建一个实例。限定后在对应的作用域内就仅创建一个实例。

### 添加依赖库

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

### Hilt 应用类

所有使用 Hilt 的应用都必须包含一个带有 `@HiltAndroidApp` 注释的 `Application` 类。

`@HiltAndroidApp` 会触发 Hilt 的代码生成操作，生成的代码包括应用的一个基类，该基类充当应用级依赖项容器。

生成的这一 Hilt 组件会附加到 `Application` 对象的生命周期，并为其提供依赖项。此外，它也是应用的父组件，这意味着，其他组件可以访问它提供的依赖项。

```kotlin
@HiltAndroidApp
class ExampleApplication : Application() { ... }
```

### 将依赖项注入 Android 类

在 `Application` 类中设置了 Hilt 且有了应用级组件后，Hilt 可以为带有 `@AndroidEntryPoint` 注解的其他 Android 类提供依赖项。

`@AndroidEntryPoint` 会为项目中的每个 Android 类生成一个单独的 Hilt 组件。这些组件可以从它们各自的父类接收依赖项。

```kotlin
@AndroidEntryPoint
class ExampleActivity : AppCompatActivity() { ... }
```

### 字段注入

使用 `@Inject` 执行字段注入, 该字段必须是public的。

> `@Inject` 还有 定义Hilt 绑定功能

```kotlin
@AndroidEntryPoint
class ExampleActivity : AppCompatActivity() {
  // 绑定字段,该字段必须是public的
  @Inject lateinit var analytics: AnalyticsAdapter
  ...
}
```

### 定义Hilt 绑定（构造函数注入）

**使用 @Inject 构造函数注入是向 Hilt 提供绑定信息的一种方法，告知Hilt如何生成该类的实例**。但是它存在局限，只能用于内部类。

构造函数的参数就是该类的依赖项，依赖项也需要定义如何提供实例。

这里定义了AnalyticsAdapter实例应该如何构造。AnalyticsService可以使用接口注入的方式提供实例。

```kotlin
// 构造函数注入
class AnalyticsAdapter @Inject constructor(
   // 此依赖性也需要注入，AnalyticsService可以使用接口注入的方式提供实例
  private val service: AnalyticsService
) { ... }
```

### 自定义Hilt模块

Hilt提供了自定义注入实例的方式。

* **@Module**：**负责定义Hilt模块**，是自定义的入口。类内部来说明如何提供类型的实例。
* **@InstallIn**：**用于指定组件**，告知Hilt模块应用于哪个 Android 类, 和相关类生命周期绑定。
* **@Binds**：**定义绑定关系，表明一个接口如何注入**。
* **@Provides**：**定义绑定关系，表明如何注入类实例**。一般用于无法修改的外部类，也可用于内部类。

#### @Module/@InstallIn

对于一些无法通过构造函数注入的类型，Hilt提供 @Module 的方式定义Hilt模块，来说明如何实例化。

这个模块指定了ActivityComponent组件。将模块安装到组件后，模块内定义的绑定就可以用作该组件或该组件的子组件中其他绑定的依赖项。

```kotlin
@Module
@InstallIn(ActivityComponent::class)
abstract class AnalyticsModule {

}
```

#### @Binds

接口无法通过构造函数注入的方式生成实例。Hilt提供了 **@Binds方式来定义绑定关系，表明一个接口如何注入**。

- **函数返回类型 **：会告知 Hilt 函数**提供哪个接口的实例**。
- **函数参数** ：会告知 Hilt 要**提供哪种实现**。

```kotlin
// 定义一个接口
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

  // 入参：表示AnalyticsService的实现是AnalyticsServiceImpl 
  // 返回类型：表示提供的是 AnalyticsService接口实例。
  @Binds
  abstract fun bindAnalyticsService(
    analyticsServiceImpl: AnalyticsServiceImpl
  ): AnalyticsService
}
```

#### @Provides

一般用于外部库类的构造，也能用于内部类的构造。

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



## Hile的其他特性

### Hilt支持的Android类

| 支持的Android 类  | 使用               |      |
| ----------------- | ------------------ | ---- |
| Application       | @HiltAndroidApp    |      |
| ViewModel         | @HiltViewModel     |      |
| Activity          | @AndroidEntryPoint |      |
| Fragment          | @AndroidEntryPoint |      |
| View              | @AndroidEntryPoint |      |
| Service           | @AndroidEntryPoint |      |
| BroadcastReceiver | @AndroidEntryPoint |      |
|                   |                    |      |



### 组件层次结构

将模块安装到组件后，其绑定就可以用作该组件中其他绑定的依赖项，也可以用作组件层次结构中该组件下的任何子组件中其他绑定的依赖项：

![image-20230301160345102](./Android%E7%9A%84%E4%BE%9D%E8%B5%96%E6%B3%A8%E5%85%A5.assets/image-20230301160345102-1677657826203-3.png)



### 组件生命周期

在定义 Hilt模块时，使用 @InstallIn 来指定使用的组件，每个 Hilt 组件负责将模块绑定 注入相应的 Android 类中。

Hilt 会按照相应 Android 类的生命周期自动创建和销毁生成的组件类的实例。

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
// 指定了 ActivityComponent 模块，该模块下才允许绑定
@Module
@InstallIn(ActivityComponent::class)
abstract class AnalyticsModule {

}
```



### 组件作用域

Hilt 中的所有绑定 都未限定作用域。**每当应用请求绑定时，Hilt 都会创建所需类型的一个新实例**。

可以**使用作用域来限定绑定**，使用作用域限定之后，在**该作用域下将会共享同一个实例**。

> 组件、作用域、Android类的对应关系

| Android 类                                 | 生成的组件                  | 作用域                    |
| ------------------------------------------ | --------------------------- | ------------------------- |
| `Application`                              | `SingletonComponent`        | `@Singleton`              |
| `Activity`                                 | `ActivityRetainedComponent` | `@ActivityRetainedScoped` |
| `ViewModel`                                | `ViewModelComponent`        | `@ViewModelScoped`        |
| `Activity`                                 | `ActivityComponent`         | `@ActivityScoped`         |
| `Fragment`                                 | `FragmentComponent`         | `@FragmentScoped`         |
| `View`                                     | `ViewComponent`             | `@ViewScoped`             |
| 带有 `@WithFragmentBindings` 注解的 `View` | `ViewWithFragmentComponent` | `@ViewScoped`             |
| `Service`                                  | `ServiceComponent`          | `@ServiceScoped`          |
|                                            |                             |                           |

```kotlin
// If AnalyticsService is an interface.

// 绑定的作用域必须与其安装到的组件的作用域一致
// 所以AnalyticsModule 需要安装在 SingletonComponent 中。
@Module
@InstallIn(SingletonComponent::class)
abstract class AnalyticsModule {

  // 这里限定了作用域，每次都使用同一实例
  @Singleton
  @Binds
  abstract fun bindAnalyticsService(
    analyticsServiceImpl: AnalyticsServiceImpl
  ): AnalyticsService
}
```



### 组件默认绑定

[使用 Hilt 实现依赖项注入  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection/hilt-android?hl=zh_cn#component-default)



### 定义多绑定

使同一类型能提供多个绑定

* **定义注解**：表明用途。
* **注解绑定**：在  `@Binds` 或 `Provides` 中添加注解限定符，和对应注解绑定。
* **注解使用**：在注入字段时 声明注解，注入对应的实例。

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

[将 Hilt 和其他 Jetpack 库一起使用  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection/hilt-jetpack?hl=zh-cn#kotlin)

### 使用 Hilt 注入 ViewModel 对象

> `@ViewModelInject` 已废弃，替换为`@HiltViewModel`

```groovy

dependencies {
  implementation 'androidx.hilt:hilt-lifecycle-viewmodel:1.0.0'
  // When using Kotlin.
  kapt 'androidx.hilt:hilt-compiler:1.0.0-alpha01'
  // When using Java.
  annotationProcessor 'androidx.hilt:hilt-compiler:1.0.0-alpha01'
}
```

```kotlin
@HiltViewModel
class ExampleViewModel @Inject constructor(
  private val savedStateHandle: SavedStateHandle,
  private val repository: ExampleRepository
) : ViewModel() {
  ...
}

@AndroidEntryPoint
class ExampleActivity : AppCompatActivity() {
  private val exampleViewModel: ExampleViewModel by viewModels()
  ...
}
```

### Compose 中使用 hilt 构造viewModel

添加依赖：

```kotlin
dependencies {
  implementation("androidx.hilt:hilt-navigation-compose:1.0.0")
  implementation("com.google.dagger:hilt-android:2.43.2")
  kapt("com.google.dagger:hilt-android-compiler:2.43.2")
  kapt("androidx.hilt:hilt-compiler:1.0.0")
}
```

使用 `hiltViewModel()` 构建 ViewModel

> 此函数调用后 会生成 `HiltViewModelFactory` 处理 hilt 逻辑 ，并保存在 `ComponentActivity.mDefaultFactory` 中 ，
>
> 从而在同一个 activity 中，即使后续调用的是 `viewModel()`， 能正常构建。

```kotlin
val homeViewModel: HomeViewModel = hiltViewModel()
```



