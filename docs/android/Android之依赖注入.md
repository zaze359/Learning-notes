# Android中的依赖注入

## 什么是依赖项

一个类 需要引用其他的类才能正常的使用，**这些引用的类称为 【依赖项】**。

```kotlin
class A {
  // A 依赖 B，B是依赖项
  private val b:B = B()
  fun print() {
    b.print();
  }
}
```

## 常见的依赖项获取方式

[Android 中的依赖项注入  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection?hl=zh_cn)

依赖项一般可以通过以下方式来获取：

1. **由类自己来初始化依赖项**：类内部直接new。问题就是两者耦合太深，依赖项不容易替换，且不方便测试。
2. **调用特定的API在需要时主动获取**：需要通过某一个类来获取依赖项，同样不容易替换且不方便测试。

   如 `getter`  、 `Context.getSystemService()`等方式
3. **通过依赖注入的方式**：由外部来完成初始化，例如作为构造函数的参数、函数的参数等方式来提供依赖项。

## 依赖注入

依赖注入的方式有构造函数注入、字段注入，基于控制反转原则，通过通用代码控制特定代码的执行。

* **构造函数注入**：作为构造函数的入参由外部传入依赖项。

* **字段注入**：例如定义 `setter()` 函数来出入依赖项。

### 依赖注入的优点

- **重用代码**
- **易于重构**
- **易于测试**

### 依赖注入存在的问题

依赖注入也带来了一些问题，当依赖项越来越多，层级越来越深，需要注入的参数越多，手动注入依赖十分麻烦。

## 依赖注入框架

为了解决手动依赖注入的繁琐操作，从而就出现了一些**自动依赖项注入的框架**。

自动依赖项注入框架一般可分为两类：

- **基于反射的解决方案**：可在**运行时**连接依赖项。(Guice)
- **静态解决方案**：可生成在**编译时**连接依赖项的代码。(Dagger，Hilt)

---

## Hilt基础概念

[使用 Hilt 实现依赖项注入  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/dependency-injection/hilt-android?hl=zh_cn)

Hilt 是在 Dagger 基础上构建而成的，因而能够受益于 Dagger 提供的编译时正确性、运行时性能、可伸缩性和 Android Studio 支持。

首先需要了解一些Hilt中的概念：

* **绑定(bindings)**：就是指 **将某个类型的实例作为依赖项 提供所需的信息**。提供绑定信息存在三种方式。
  * 构造函数注入
  * @Binds
  * @Provider
* **模块(modules)**：使用@Module定义的Hilt模块。我们可以在**模块内部定义自定义的绑定**。
* **组件(Component)**：**每个 可以执行字段注入的Android 类都会对应一个组件**，且它们的生命周期绑定。模块需要安装到指定的组件上使用，将模块安装到组件后，**每个 Hilt 组件负责将其绑定注入相应的 Android 类中**。
* **组件作用域(Component scopes)**：将绑定的作用域 限定在特定组件中，限定后在对应的**作用域内就仅创建一个实例**。
  * 默认不存在作用域，即每次绑定请求都会创建一个实例。

## Hilt的使用

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

配置 Java 版本

```
android {
  ...
  compileOptions {
    sourceCompatibility JavaVersion.VERSION_1_8
    targetCompatibility JavaVersion.VERSION_1_8
  }
}
```



### 初始化Hilt

所有使用 Hilt 的应用都必须包含一个带有 `@HiltAndroidApp` 注释的 `Application` 类，它作为应用级组件。

* `@HiltAndroidApp` 会触发 Hilt 的代码生成操作，生成的代码包括应用的一个基类，该基类充当应用级依赖项容器
* 这个 Hilt 组件会附加到 `Application` 对象的生命周期，并提供依赖项。
* 是应用的父组件，其他组件可以访问它提供的依赖项

```kotlin
@HiltAndroidApp
class ExampleApplication : Application() { ... }
```

### 注入 Android 类

初始化后，可以使用 `@AndroidEntryPoint` 注释其他 Android 类，Hilt会给这些类提供依赖项。

> `@AndroidEntryPoint` 会为项目中的每个 Android 类生成一个单独的 Hilt 组件。

```kotlin
@AndroidEntryPoint
class ExampleActivity : AppCompatActivity() { ... }
```

#### 字段注入

使用 `@Inject` 执行字段注入, 该字段必须是 `public` 的。

> `@Inject` 还有 定义Hilt 绑定功能

```kotlin
@AndroidEntryPoint
class ExampleActivity : AppCompatActivity() {
  // 绑定字段,该字段必须是public的
  @Inject lateinit var analytics: AnalyticsAdapter
  ...
}
```

#### 构造函数注入以及定义Hilt 绑定

使用 `@Inject` 注释构造函数，有两个作用：

1. **告知Hilt如何生成该类的实例**：向Hilt 提供绑定信息的方法，这样AnalyticsAdapter 可以使用接口注入的方式提供实例。
2. **自动注入了 构造函数中的参数**：AnalyticsService 会被自动注入。
   * 构造函数的参数就是该类的依赖项，依赖项也需要定义如何提供实例，否则会报错。

> 存在局限，只能用于项目内部的类。

```kotlin
// 构造函数注入
class AnalyticsAdapter @Inject constructor(
   // 此依赖性也需要注入，AnalyticsService可以使用接口注入的方式提供实例
  private val service: AnalyticsService
) { ... }
```

## 使用 Hilt模块 自定义注入

Hilt提供了自定义注入实例的方式，我们可以通过这种方式，注入任意实例。

* **@Module**：**负责定义Hilt模块**，是自定义的入口。类内部来说明如何提供类型的实例。
* **@InstallIn**：**用于指定组件的作用域**，告知Hilt模块应用于哪个 Android 类, 和相关类生命周期绑定。
* **@Binds**：**定义绑定关系，表明一个接口如何注入**。
* **@Provides**：**定义绑定关系，表明如何注入类实例**。一般用于无法修改的外部类，也可用于内部类。

### 定义模块：@Module/@InstallIn

对于一些无法通过构造函数注入的类型，Hilt提供 @Module 的方式定义Hilt模块，来说明如何实例化。

这个模块指定了ActivityComponent组件。将模块安装到组件后，模块内定义的绑定就可以用作该组件或该组件的子组件中其他绑定的依赖项。

```kotlin
@Module
@InstallIn(ActivityComponent::class)
abstract class AnalyticsModule {

}
```

### 使用 Binds 注入实例

由于接口无法通过构造函数注入的方式生成实例，所以 Hilt提供了 `@Binds` 来定义绑定关系，**表明一个接口如何注入**。

这种方式的局限性在于 只能注入我们自己的类，因为是通过构造函数注入的方式实现的。

- **函数返回类型 **：会告知 Hilt 函数**提供哪个接口的实例**。
- **函数参数** ：会告知 Hilt 要**提供接口哪种实现**。

```kotlin
// 定义一个接口
interface AnalyticsService {
  fun analyticsMethods()
}

// 声明构造函数注入
// 后面需要注入 AnalyticsServiceImpl 实例
class AnalyticsServiceImpl @Inject constructor(
  ...
) : AnalyticsService { ... }

@Module
@InstallIn(ActivityComponent::class)
abstract class AnalyticsModule {

  // 将 AnalyticsServiceImpl 和 AnalyticsService 进行绑定
  // 即 需要注入AnalyticsService = 等于注入 AnalyticsServiceImpl
  // 入参：表示AnalyticsService 的实现是 AnalyticsServiceImpl 
  // 返回类型：表示提供的是 AnalyticsService接口实例。
  @Binds
  abstract fun bindAnalyticsService( // 构造函数注入AnalyticsServiceImpl
    analyticsServiceImpl: AnalyticsServiceImpl
  ): AnalyticsService
}
```

### 使用 Provides 注入三方库实例

一般用于返回 **外部库类**，当然也能用于内部类。

- **函数返回类型**：告知 Hilt 函数提供哪个类型的实例。
- **函数参数**：告知 Hilt 相应类型的依赖项，可以没有。
- **函数主体**：告知 Hilt 如何提供相应类型的实例。每次请求该类型的实例时，Hilt 都会重新执行函数主体。

```kotlin
@Module
@InstallIn(ActivityComponent::class)
object AnalyticsModule {

  @Provides
  fun provideAnalyticsService(): AnalyticsService {
      // 构建 AnalyticsService 的实例
      return Retrofit.Builder()
               .baseUrl("https://example.com")
               .build()
               .create(AnalyticsService::class.java)
  }
}
```

### 预定义限定符

Hilt提供了 `@ApplicationContext` 和 `@ActivityContext` 来获取上下文。这两个限定符也可以不写。

```kotlin
class AnalyticsServiceImpl @Inject constructor(
  @ApplicationContext context: Context
) : AnalyticsService { ... }

class AnalyticsAdapter @Inject constructor(
  @ActivityContext context: Context
) { ... }

```

## 当前Hilt支持的Android 类

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

## 在Hilt 不支持的类中注入依赖项

Hilt 对于常见的 Android类都提供了支持，不过对于那些不支持的类也提供了 `@EntryPoint` 来创建入口点，从而支持注入。

下面 演示一下在 ContentProvider 中 通过hilt 自动注入 AnalyticsService

### 定义入口点

推荐定义在需要使用的类中。主要涉及 `@EntryPoint` 和 `@InstallIn` 两个注解

```kotlin
// ContentProvider 默认是不支持，这里通过
class ExampleContentProvider : ContentProvider() {

  @EntryPoint
  @InstallIn(SingletonComponent::class) // 指定作用域
  interface ExampleContentProviderEntryPoint {
    // 定义接口获取 AnalyticsService 实例
    // AnalyticsService 会根据之前定义的 hilt module 注入。
    fun analyticsService(): AnalyticsService
  }

  ...
}
```

### 获取实例

提供了 `EntryPointAccessors` 来获取入口点。

```kotlin
class ExampleContentProvider: ContentProvider() {
    ...
  override fun query(...): Cursor {
    // appContext：需要和 @InstallIn 匹配
    val appContext = context?.applicationContext ?: throw IllegalStateException()
    // 获取自定义的入口：ExampleContentProviderEntryPoint
    val hiltEntryPoint =
      EntryPointAccessors.fromApplication(appContext, ExampleContentProviderEntryPoint::class.java)
		// 通过 hiltEntryPoint 获取实例。
    val analyticsService = hiltEntryPoint.analyticsService()
    ...
  }
}
```



## Hilt的其他特性

### 组件层次结构

将模块安装到组件后，其绑定就可以用作该组件中其他绑定的依赖项，也可以用作组件层次结构中该组件下的任何子组件中其他绑定的依赖项：

![image-20230301160345102](./Android%E7%9A%84%E4%BE%9D%E8%B5%96%E6%B3%A8%E5%85%A5.assets/image-20230301160345102-1677657826203-3.png)



### 组件生命周期

在定义 Hilt模块时，使用 @InstallIn 来指定使用的组件，每个 Hilt 组件负责将模块绑定 注入相应的 Android 类中。

Hilt 会按照相应 Android 类的生命周期自动创建和销毁生成的组件类的实例。

> 以前版本的 @ApplicationComponent 就是 @SingletonComponent。

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
// Singleton 对应 SingletonComponent。
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

此处使用构造函数注入的方式，声明如何创建 ExampleViewModel 实例。

`@HiltViewModel`的作用：表明这个ViewModel需要使用 HiltViewModelFactory 来处理，而不是使用 默认的Factory。

```kotlin
@HiltViewModel
class ExampleViewModel @Inject constructor(
  private val savedStateHandle: SavedStateHandle,
  private val repository: ExampleRepository
) : ViewModel() {
  ...
}

//
@AndroidEntryPoint
class ExampleActivity : AppCompatActivity() {
  // 使用正常的方式构建 viewModel 即可
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

使用 `hiltViewModel()` 构建 ViewModel。

```kotlin
val homeViewModel: HomeViewModel = hiltViewModel()
```

`hiltViewModel()`函数调用后 会创建一个 `HiltViewModelFactory` 实例来处理 hilt 相关的逻辑 。

```kotlin
@Composable
inline fun <reified VM : ViewModel> hiltViewModel(
    viewModelStoreOwner: ViewModelStoreOwner = checkNotNull(LocalViewModelStoreOwner.current) {
        "No ViewModelStoreOwner was provided via LocalViewModelStoreOwner"
    }
): VM {
    val factory = createHiltViewModelFactory(viewModelStoreOwner)
    return viewModel(viewModelStoreOwner, factory = factory)
}
```

### Hilt 原理分析

```kotlin
@AndroidEntryPoint
class MainActivity : AbsActivity() {
    // ...
}
```

使用 `@AndroidEntryPoint` 时会 生成一个Hilt 组件，Gradle插件 会通过字节码转换**设为 MainActivity 的父类**。

* 重写了 `getDefaultViewModelProviderFactory()`，将默认实现替换成了Hilt自己的 ViewModelProvider.Factory。

```java
package com.zaze.demo.compose;
// 会生成一个Hilt类作为 MainActivity的父类，扩展了一些hilt相关的功能
public abstract class Hilt_ComposeActivity extends AbsActivity implements GeneratedComponentManagerHolder {
  private volatile ActivityComponentManager componentManager;

  private final Object componentManagerLock = new Object();

  private boolean injected = false;

  Hilt_ComposeActivity() {
    super();
    _initHiltInternal();
  }

  private void _initHiltInternal() {
    addOnContextAvailableListener(new OnContextAvailableListener() {
      @Override
      public void onContextAvailable(Context context) {
        inject();
      }
    });
  }

  // 创建一个组件 
  @Override
  public final Object generatedComponent() {
    return this.componentManager().generatedComponent();
  }

  protected ActivityComponentManager createComponentManager() {
    return new ActivityComponentManager(this);
  }

  @Override
  public final ActivityComponentManager componentManager() {
    if (componentManager == null) {
      synchronized (componentManagerLock) {
        if (componentManager == null) {
          componentManager = createComponentManager();
        }
      }
    }
    return componentManager;
  }

  protected void inject() {
    if (!injected) {
      injected = true;
      ((ComposeActivity_GeneratedInjector) this.generatedComponent()).injectComposeActivity(UnsafeCasts.<ComposeActivity>unsafeCast(this));
    }
  }

  // 重写了 getDefaultViewModelProviderFactory()
  @Override
  public ViewModelProvider.Factory getDefaultViewModelProviderFactory() {
    return DefaultViewModelFactories.getActivityFactory(this, super.getDefaultViewModelProviderFactory());
  }
}
```

自定义ViewModel的创建，内部生成了 `HiltViewModelFactory`。

```java
public final class DefaultViewModelFactories {  
    //
      public static ViewModelProvider.Factory getActivityFactory(ComponentActivity activity,
          ViewModelProvider.Factory delegateFactory) {
        return EntryPoints.get(activity, ActivityEntryPoint.class)
            .getHiltInternalFactoryFactory()
            .fromActivity(activity, delegateFactory);
      }
    //
    ViewModelProvider.Factory fromActivity(
        ComponentActivity activity, ViewModelProvider.Factory delegateFactory) {
      return getHiltViewModelFactory(
          activity,
          activity.getIntent() != null ? activity.getIntent().getExtras() : null,
          delegateFactory);
    }
    //
    private ViewModelProvider.Factory getHiltViewModelFactory(
        SavedStateRegistryOwner owner,
        @Nullable Bundle defaultArgs,
        ViewModelProvider.Factory delegate) {
        // HiltViewModelFactory
      return new HiltViewModelFactory(
          owner, defaultArgs, keySet, checkNotNull(delegate), viewModelComponentBuilder);
    }
}
```

HiltViewModelFactory 最终会从 hilt组件中获取ViewModel。

```java
public HiltViewModelFactory {
    
	public HiltViewModelFactory(@NonNull SavedStateRegistryOwner owner, @Nullable Bundle defaultArgs, @NonNull Set<String> hiltViewModelKeys, @NonNull ViewModelProvider.Factory delegateFactory, @NonNull final ViewModelComponentBuilder viewModelComponentBuilder) {
        this.hiltViewModelKeys = hiltViewModelKeys;
        this.delegateFactory = delegateFactory;
        // 初始化hiltViewModelFactory，最终都是调用这里来创建ViewModel
        this.hiltViewModelFactory = new AbstractSavedStateViewModelFactory() {
            @NonNull
            protected <T extends ViewModel> T create(@NonNull String key, @NonNull Class<T> modelClass, @NonNull SavedStateHandle handle) {
                RetainedLifecycleImpl lifecycle = new RetainedLifecycleImpl();
                //
                ViewModelComponent component = viewModelComponentBuilder.savedStateHandle(handle).viewModelLifecycle(lifecycle).build();
                // 从 HiltViewModel 组件中获取ViewModel
                Provider<? extends ViewModel> provider = (Provider)((ViewModelFactoriesEntryPoint)EntryPoints.get(component, ViewModelFactoriesEntryPoint.class)).getHiltViewModelMap().get(modelClass.getName());
                if (provider == null) {
                    throw new IllegalStateException("Expected the @HiltViewModel-annotated class '" + modelClass.getName() + "' to be available in the multi-binding of @HiltViewModelMap but none was found.");
                } else {
                    ViewModel viewModel = (ViewModel)provider.get();
                    Objects.requireNonNull(lifecycle);
                    viewModel.addCloseable(lifecycle::dispatchOnCleared);
                    return viewModel;
                }
            }
        };
    }
    
    public <T extends ViewModel> T create(@NonNull Class<T> modelClass, @NonNull CreationExtras extras) {
        // hiltViewModelKeys 中保存了 使用 @HiltViewModel注释的ViewModel。
        if (hiltViewModelKeys.contains(modelClass.getName())) {
            // 处理 HiltViewModel
            return hiltViewModelFactory.create(modelClass, extras);
        } else {
            // 按照正常的ViewModel逻辑处理，
            return delegateFactory.create(modelClass, extras);
        }
	}
}
```

