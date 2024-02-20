# Android性能分析

* Java：常用的 Android Profiler、 Allocation Tracker 和 MAT 这几个工具。

* Native：使用 [AddressSanitize](https://github.com/google/sanitizers) 分析。

## 性能分析工具

### Android Profiler

Android Studio 提供了 Android Profiler 性能分析器来帮助我们进行性能分析。它通过图表的方式展示一个应用CPU、内存、电量等信息的实时状态。可以点击进入单独的操作视图。

[分析应用性能  | Android Studio  | Android Developers (google.cn)](https://developer.android.google.cn/studio/profile?hl=zh-cn)

![image-20230726194049895](./Android%E6%80%A7%E8%83%BD%E5%88%86%E6%9E%90.assets/image-20230726194049895.png)



```
绿色: 线程处于活动状态或准备好使用CPU。也就是说，它处于”运行”或”可运行”状态。
黄色： 线程处于活动状态，但是在完成其工作之前，它正在等待I / O操作（如文件或网络I / O）。
灰色： 线程正在睡眠，不会消耗任何CPU时间，当线程需要访问尚未可用的资源时，有时会发生这种情况。要么线程进入自愿性睡眠，要么内核使线程休眠，直到所需的资源可用。
```

这个视图还提供了一些功能：

* 垃圾桶图标：强制执行GC。
* Capture heap dump：生成堆转储 `.hprof` 文件，生成视图中也会提示内存泄露情况。
* Record native allocations：记录 native 内存分配情况。
* Record Java/Kotlin allocations：记录 Java/Kotlin 对象的内存分配情况

![image-20230726194204477](./Android%E6%80%A7%E8%83%BD%E5%88%86%E6%9E%90.assets/image-20230726194204477.png)

> Capture heap dump

![image-20230726214028422](./Android%E6%80%A7%E8%83%BD%E5%88%86%E6%9E%90.assets/image-20230726214028422.png)

> Record Java/Kotlin allocations

![image-20230726214217192](./Android%E6%80%A7%E8%83%BD%E5%88%86%E6%9E%90.assets/image-20230726214217192.png)

### MAT（Memory Analyzer Tool）

MAT 是一个功能丰富的Java堆分析器。

下载地址：[Eclipse Memory Analyzer Open Source Project | The Eclipse Foundation](https://eclipse.dev/mat/downloads.php)

#### 使用方式

我们通过 Android Profiler 生成堆转储文件需要先经过转换后才能使用MAT打开。

通过 `/Android/sdk/platform-tools/hprof-conv.exe` 程序将内容格式转换成MAT可用的格式。

```shell
# 可以将hprof-conv 配置到环境变量，方便使用
# 执行转换
hprof-conv xx.hprof xx-conv.hprof
```

转换后就可以启动 MAT 来打开文件：

![image-20230804153621640](./Android%E6%80%A7%E8%83%BD%E5%88%86%E6%9E%90.assets/image-20230804153621640.png)

打开文件 `xx-conv.hprof` 文件：

![image-20230804153714444](./Android%E6%80%A7%E8%83%BD%E5%88%86%E6%9E%90.assets/image-20230804153714444.png)



生成Histogram 查看：

![image-20230804154451851](./Android%E6%80%A7%E8%83%BD%E5%88%86%E6%9E%90.assets/image-20230804154451851.png)



#### 内存快照对比

MAT 还支持内存快照对比，帮助我们差量分析内存泄露问题。

主要就是通过MAT来对比两个 `.hprof`文件 ，从而定位内存泄露问题。当然这两个文件也不是随便选的，需要根据场景来选择生成。

例如 在页面跳转前先生成一个堆转储文件，然后一顿操作后，重新回到这个页面后再捕获一个文件。此时就可以对比两个文件，看看多出了那些对象，从而判断操作过程中是否发生了内存泄露。



## 性能分析框架

### LeakCanary(检测内存泄露)

[square/leakcanary: A memory leak detection library for Android. (github.com)](https://github.com/square/leakcanary)

Square 提供的内存泄露检测工具开源库， 能够在应用运行时检测是否发生了内存泄露，若发生了，会通过系统通知通知给我们，并且可以捕获堆转储，**生成泄露对象的引用链**。一般用于线下开发、测试环境。

* 检测未被GC的对象
* 生成堆转储文件
* 分析堆转储文件
* 分析泄露对象并分类（Activity、Fragment、Fragment View、ViewModel）

#### 实现原理简介

通过监听 Android 各个组件的生命周期，在这些组件实例 destory、clear等不可用时传递给 `ObjectWatcher`，ObjectWatcher会以弱引用的方式持有，最后 上面介绍过的  弱引用 + 引用队列 结合的方式 来判断是否发生了泄露。

#### 初始化

LeakCanary 利用 ContentProvider 来进行自动初始化，所有我们并不需要手动的进行注册操作，直接添加完依赖库即可使用。

##### AppWatcherInstaller

默认是 MainProcess 运行在 主进程，源码中可以看出也支持运行在单独进程中。

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.squareup.leakcanary.objectwatcher" >

    <uses-sdk android:minSdkVersion="14" />

    <application>
        <provider
            android:name="leakcanary.internal.AppWatcherInstaller$MainProcess"
            android:authorities="${applicationId}.leakcanary-installer"
            android:enabled="@bool/leak_canary_watcher_auto_install"
            android:exported="false" />
    </application>

</manifest>
```

```kotlin
internal sealed class AppWatcherInstaller : ContentProvider() {
  /**
   * [MainProcess] automatically sets up the LeakCanary code that runs in the main app process.
   */
  internal class MainProcess : AppWatcherInstaller()

  /**
   * When using the `leakcanary-android-process` artifact instead of `leakcanary-android`,
   * [LeakCanaryProcess] automatically sets up the LeakCanary code
   */
  internal class LeakCanaryProcess : AppWatcherInstaller()

  override fun onCreate(): Boolean {
    val application = context!!.applicationContext as Application
    // 执行安装
    AppWatcher.manualInstall(application)
    return true
  }

}
```

##### AppWatcher

这里注册监听了 Android中各种组件的生命周期，Activity、Fragment、Service、ViewModel等。

```kotlin
object AppWatcher {
    
  // 创建ObjectWatcher，这个类是负责检测对象是否发生内存泄露的。
  val objectWatcher = ObjectWatcher(
    clock = { SystemClock.uptimeMillis() },
    checkRetainedExecutor = {
      check(isInstalled) {
        "AppWatcher not installed"
      }
      // 延迟消息
      mainHandler.postDelayed(it, retainedDelayMillis)
    },
    isEnabled = { true }
  )
    
  @JvmOverloads
  fun manualInstall(
    application: Application,
    retainedDelayMillis: Long = TimeUnit.SECONDS.toMillis(5),
    watchersToInstall: List<InstallableWatcher> = appDefaultWatchers(application)
  ) {
    // 检测是否允许在 主线程中。
    checkMainThread()
    if (isInstalled) {
      throw IllegalStateException(
        "AppWatcher already installed, see exception cause for prior install call", installCause
      )
    }
    check(retainedDelayMillis >= 0) {
      "retainedDelayMillis $retainedDelayMillis must be at least 0 ms"
    }
    installCause = RuntimeException("manualInstall() first called here")
    this.retainedDelayMillis = retainedDelayMillis
    if (application.isDebuggableBuild) {
      LogcatSharkLog.install()
    }
    // Requires AppWatcher.objectWatcher to be set
    LeakCanaryDelegate.loadLeakCanary(application)
	// 安装各种组件的生命周期监听类
    watchersToInstall.forEach {
      it.install()
    }
  }
    
  // 这里列举了 默认监听的类型
  fun appDefaultWatchers(
    application: Application,
    reachabilityWatcher: ReachabilityWatcher = objectWatcher
  ): List<InstallableWatcher> {
    // 传入了 objectWatcher
    return listOf(
      ActivityWatcher(application, reachabilityWatcher),
      FragmentAndViewModelWatcher(application, reachabilityWatcher),
      RootViewWatcher(reachabilityWatcher),
      ServiceWatcher(reachabilityWatcher)
    )
  }
}
```



#### 生命周期监听

生命周期监听主要涉及几个关键的Watcher类：

* ActivityWatcher：监控 Activity 生命周期。
* FragmentAndViewModelWatcher：监控 Fragment、ViewModel生命周期。
  * AndroidXFragmentDestroyWatcher：适配Androidx
  * ViewModelClearedWatcher：监听ViewModel生命周期，被AndroidXFragmentDestroyWatcher 调用安装。
* RootViewWatcher：监控 View 生命周期
* ServiceWatcher：监控 Service 生命周期



##### ActivityWatchers

核心是通过向 Application 注册 `registerActivityLifecycleCallbacks()` 监听生命周期，当监听到 Activity 销毁时，通过 ObjectWatcher 检测是否发生内存泄露。

```kotlin
// reachabilityWatcher 是 objectWatcher
class ActivityWatcher(
  private val application: Application,
  private val reachabilityWatcher: ReachabilityWatcher
) : InstallableWatcher {

  private val lifecycleCallbacks =
    object : Application.ActivityLifecycleCallbacks by noOpDelegate() {
      override fun onActivityDestroyed(activity: Activity) {
        // 在Activity destroy时，通过 objectWatcher 检测内存泄露
        reachabilityWatcher.expectWeaklyReachable(
          activity, "${activity::class.java.name} received Activity#onDestroy() callback"
        )
      }
    }
  // 注册生命周期监听
  override fun install() {
    application.registerActivityLifecycleCallbacks(lifecycleCallbacks)
  }

  override fun uninstall() {
    application.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
  }
}
```

##### FragmentAndViewModelWatcher

首先监听 Activity 的 生命周期，在`onCreate()` 中根据不同的 Fragment 生成不同Watcher，并监听 destroy 事件。

最终是 通过 `fragmentManager.registerFragmentLifecycleCallbacks()` 来监听 所有 fragment 的生命周期。

```kotlin
class FragmentAndViewModelWatcher(
  private val application: Application,
  private val reachabilityWatcher: ReachabilityWatcher
) : InstallableWatcher {
    private val fragmentDestroyWatchers: List<(Activity) -> Unit> = run {
    val fragmentDestroyWatchers = mutableListOf<(Activity) -> Unit>()

    // 根据不同的 Fragment 生成不同 Watcher
    if (SDK_INT >= O) {
      fragmentDestroyWatchers.add(
        AndroidOFragmentDestroyWatcher(reachabilityWatcher)
      )
    }
	// ....
    fragmentDestroyWatchers
  }
    
    private val lifecycleCallbacks =
    object : Application.ActivityLifecycleCallbacks by noOpDelegate() {
      override fun onActivityCreated(
        activity: Activity,
        savedInstanceState: Bundle?
      ) {
        // 在 Activity create 时开始监听 fragment的destroy 事件
        for (watcher in fragmentDestroyWatchers) {
          watcher(activity)
        }
      }
    }

  override fun install() {
    // 先监听 Activity 生命周期
    application.registerActivityLifecycleCallbacks(lifecycleCallbacks)
  }
    
  override fun uninstall() {
    application.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
  }
    
  companion object {
    private const val ANDROIDX_FRAGMENT_CLASS_NAME = "androidx.fragment.app.Fragment"
    private const val ANDROIDX_FRAGMENT_DESTROY_WATCHER_CLASS_NAME =
      "leakcanary.internal.AndroidXFragmentDestroyWatcher"
    @Suppress("VariableNaming", "PropertyName")
    private val ANDROID_SUPPORT_FRAGMENT_CLASS_NAME =
      StringBuilder("android.").append("support.v4.app.Fragment")
        .toString()
    private const val ANDROID_SUPPORT_FRAGMENT_DESTROY_WATCHER_CLASS_NAME =
      "leakcanary.internal.AndroidSupportFragmentDestroyWatcher"
  }
}
```

AndroidXFragmentDestroyWatcher

```kotlin
internal class AndroidXFragmentDestroyWatcher (
  private val reachabilityWatcher: ReachabilityWatcher
) : (Activity) -> Unit {

  private val fragmentLifecycleCallbacks = object : FragmentManager.FragmentLifecycleCallbacks() {

    override fun onFragmentCreated(
      fm: FragmentManager,
      fragment: Fragment,
      savedInstanceState: Bundle?
    ) {
      ViewModelClearedWatcher.install(fragment, reachabilityWatcher)
    }

    override fun onFragmentViewDestroyed(
      fm: FragmentManager,
      fragment: Fragment
    ) {
      val view = fragment.view
      if (view != null) {
        reachabilityWatcher.expectWeaklyReachable(
          view, "${fragment::class.java.name} received Fragment#onDestroyView() callback " +
          "(references to its views should be cleared to prevent leaks)"
        )
      }
    }

    override fun onFragmentDestroyed(
      fm: FragmentManager,
      fragment: Fragment
    ) {
      reachabilityWatcher.expectWeaklyReachable(
        fragment, "${fragment::class.java.name} received Fragment#onDestroy() callback"
      )
    }
  }

  override fun invoke(activity: Activity) {
    if (activity is FragmentActivity) {
      // 监听 fragment
      val supportFragmentManager = activity.supportFragmentManager
      supportFragmentManager.registerFragmentLifecycleCallbacks(fragmentLifecycleCallbacks, true)
      // 监听ViewModel
      ViewModelClearedWatcher.install(activity, reachabilityWatcher)
    }
  }
}
```

##### ViewModelClearedWatcher

ViewModel 的监听 是在 处理 AndroidXFragmentDestroyWatcher 是被安装的。

主要流程是 创建一个 ViewModelClearedWatcher 塞到 Activity 的 ViewModelStore 中，同时还获取到了 ViewModelStore中存储 ViewModel 的 mMap，最后在 `onCleared()` 回调时去判断ViewModel 是否发送泄露。

> 因为 Activity ON_DESTROY 时会 一次性清空 ViewModelStore中的 ViewModel。

```kotlin
internal class ViewModelClearedWatcher(
  storeOwner: ViewModelStoreOwner,
  private val reachabilityWatcher: ReachabilityWatcher
) : ViewModel() {

  private val viewModelMap: Map<String, ViewModel>?

  init {
    // We could call ViewModelStore#keys with a package spy in androidx.lifecycle instead,
    // however that was added in 2.1.0 and we support AndroidX first stable release. viewmodel-2.0.0
    // does not have ViewModelStore#keys. All versions currently have the mMap field.
    viewModelMap = try {
      val mMapField = ViewModelStore::class.java.getDeclaredField("mMap")
      mMapField.isAccessible = true
      @Suppress("UNCHECKED_CAST")
      mMapField[storeOwner.viewModelStore] as Map<String, ViewModel>
    } catch (ignored: Exception) {
      null
    }
  }

  override fun onCleared() {
    viewModelMap?.values?.forEach { viewModel ->
      reachabilityWatcher.expectWeaklyReachable(
        viewModel, "${viewModel::class.java.name} received ViewModel#onCleared() callback"
      )
    }
  }

  companion object {
    fun install(
      storeOwner: ViewModelStoreOwner,
      reachabilityWatcher: ReachabilityWatcher
    ) {
      val provider = ViewModelProvider(storeOwner, object : Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel?> create(modelClass: Class<T>): T =
          ViewModelClearedWatcher(storeOwner, reachabilityWatcher) as T
      })
      // 创建一个 ViewModelClearedWatcher 塞到 Activity 的 ViewModelStore 中
      provider.get(ViewModelClearedWatcher::class.java)
    }
  }
}
```

##### ServiceWatcher

通过 Hook的方式来监听生命周期。

* 反射获取ActivityThread中的 Handler 并替换它的 mCallback，监听 STOP_SERVICE，并将 Service添加到 servicesToBeDestroyed中暂存，此时Service 若能销毁则会调用 `serviceDoneExecuting()`。
* 动态代理 activityManager，处理 `serviceDoneExecuting()`，此时表示 有Service 真正被销毁了。

为什么需要做这两步监听？

首先监听到 STOP_SERVICE 消息后，并不一定会销毁Service，`serviceDoneExecuting()` 才是真正销毁Service的地方。

但是仅动态代理 `serviceDoneExecuting()`，也存在问题，因为这里可以接收到所有的 Service，包括其他进程的，所以需要第一步监听来确认哪些是当前应用的Service的。

```kotlin
class ServiceWatcher(private val reachabilityWatcher: ReachabilityWatcher) : InstallableWatcher {

  private val servicesToBeDestroyed = WeakHashMap<IBinder, WeakReference<Service>>()

  private val activityThreadClass by lazy { Class.forName("android.app.ActivityThread") }

  private val activityThreadInstance by lazy {
    activityThreadClass.getDeclaredMethod("currentActivityThread").invoke(null)!!
  }

  private val activityThreadServices by lazy {
    val mServicesField =
      activityThreadClass.getDeclaredField("mServices").apply { isAccessible = true }

    @Suppress("UNCHECKED_CAST")
    mServicesField[activityThreadInstance] as Map<IBinder, Service>
  }

  private var uninstallActivityThreadHandlerCallback: (() -> Unit)? = null
  private var uninstallActivityManager: (() -> Unit)? = null

  override fun install() {
    checkMainThread()
    check(uninstallActivityThreadHandlerCallback == null) {
      "ServiceWatcher already installed"
    }
    check(uninstallActivityManager == null) {
      "ServiceWatcher already installed"
    }
    try {
      // 
      swapActivityThreadHandlerCallback { mCallback ->
        uninstallActivityThreadHandlerCallback = {
          swapActivityThreadHandlerCallback {
            mCallback
          }
        }
        Handler.Callback { msg ->
          if (msg.what == STOP_SERVICE) {
            val key = msg.obj as IBinder
            activityThreadServices[key]?.let {
              onServicePreDestroy(key, it)
            }
          }
          mCallback?.handleMessage(msg) ?: false
        }
      }
      swapActivityManager { activityManagerInterface, activityManagerInstance ->
        uninstallActivityManager = {
          swapActivityManager { _, _ ->
            activityManagerInstance
          }
        }
        // 动态代理  activityManager,处理 onServiceDestroyed
        Proxy.newProxyInstance(
          activityManagerInterface.classLoader, arrayOf(activityManagerInterface)
        ) { _, method, args ->
          if (METHOD_SERVICE_DONE_EXECUTING == method.name) {
            val token = args!![0] as IBinder
            if (servicesToBeDestroyed.containsKey(token)) {
              onServiceDestroyed(token)
            }
          }
          try {
            if (args == null) {
              method.invoke(activityManagerInstance)
            } else {
              method.invoke(activityManagerInstance, *args)
            }
          } catch (invocationException: InvocationTargetException) {
            throw invocationException.targetException
          }
        }
      }
    } catch (ignored: Throwable) {
      SharkLog.d(ignored) { "Could not watch destroyed services" }
    }
  }

  override fun uninstall() {
    checkMainThread()
    uninstallActivityManager?.invoke()
    uninstallActivityThreadHandlerCallback?.invoke()
    uninstallActivityManager = null
    uninstallActivityThreadHandlerCallback = null
  }

  private fun onServicePreDestroy(
    token: IBinder,
    service: Service
  ) {
    servicesToBeDestroyed[token] = WeakReference(service)
  }

  private fun onServiceDestroyed(token: IBinder) {
    // 筛选出本应用的 Service。
    servicesToBeDestroyed.remove(token)?.also { serviceWeakReference ->
      serviceWeakReference.get()?.let { service ->
        reachabilityWatcher.expectWeaklyReachable(
          service, "${service::class.java.name} received Service#onDestroy() callback"
        )
      }
    }
  }

  // 反射获取ActivityThread中的 Handler 并替换它的 mCallback，从而监听所有消息
  private fun swapActivityThreadHandlerCallback(swap: (Handler.Callback?) -> Handler.Callback?) {
    val mHField =
      activityThreadClass.getDeclaredField("mH").apply { isAccessible = true }
    val mH = mHField[activityThreadInstance] as Handler

    val mCallbackField =
      Handler::class.java.getDeclaredField("mCallback").apply { isAccessible = true }
    val mCallback = mCallbackField[mH] as Handler.Callback?
    // 替换callback
    mCallbackField[mH] = swap(mCallback)
  }

  @SuppressLint("PrivateApi")
  private fun swapActivityManager(swap: (Class<*>, Any) -> Any) {
    val singletonClass = Class.forName("android.util.Singleton")
    val mInstanceField =
      singletonClass.getDeclaredField("mInstance").apply { isAccessible = true }

    val singletonGetMethod = singletonClass.getDeclaredMethod("get")

    val (className, fieldName) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      "android.app.ActivityManager" to "IActivityManagerSingleton"
    } else {
      "android.app.ActivityManagerNative" to "gDefault"
    }

    val activityManagerClass = Class.forName(className)
    val activityManagerSingletonField =
      activityManagerClass.getDeclaredField(fieldName).apply { isAccessible = true }
    val activityManagerSingletonInstance = activityManagerSingletonField[activityManagerClass]

    // Calling get() instead of reading from the field directly to ensure the singleton is
    // created.
    val activityManagerInstance = singletonGetMethod.invoke(activityManagerSingletonInstance)

    val iActivityManagerInterface = Class.forName("android.app.IActivityManager")
    mInstanceField[activityManagerSingletonInstance] =
      swap(iActivityManagerInterface, activityManagerInstance!!)
  }

  companion object {
    private const val STOP_SERVICE = 116

    private const val METHOD_SERVICE_DONE_EXECUTING = "serviceDoneExecuting"
  }
}
```





#### 内存泄露检测

##### ObjectWatcher

通过 监控队列 和 引用队列 进行比较差异，来判断是否发生了内存泄露。

* 泄露对象 = 监控队列 - 引用队列

```kotlin
class ObjectWatcher constructor(
  private val clock: Clock,
  private val checkRetainedExecutor: Executor,
  private val isEnabled: () -> Boolean = { true }
) : ReachabilityWatcher {
    
  // 检测到保留对象时的回调，即发生内存泄露回调
  private val onObjectRetainedListeners = mutableSetOf<OnObjectRetainedListener>()

  // 监控队列：是一个 持有监控泄露的对象的弱引用表
  private val watchedObjects = mutableMapOf<String, KeyedWeakReference>()
  // 引用队列，用于 和 watchedObjects 判断内存泄露
  private val queue = ReferenceQueue<Any>()
    
  // 生成一个传入对象的弱引用，并放到监控队列中。
  // 同时触发检测是否发生内存泄露
  @Synchronized override fun expectWeaklyReachable(
    watchedObject: Any,
    description: String
  ) {
    if (!isEnabled()) {
      return
    }
    // 先从监控队列中去除去除已被GC回收的对象
    removeWeaklyReachableObjects()
    // 创建一个Key
    val key = UUID.randomUUID()
      .toString()
    val watchUptimeMillis = clock.uptimeMillis()
    // 创建
    val reference =
      KeyedWeakReference(watchedObject, key, description, watchUptimeMillis, queue)
	// 放到监控队列中
    watchedObjects[key] = reference
    // 发送延迟消息，等待destory 结束
    // 因为这里时在 onDestroy中调用的，同步检测 Activity必然还是存在的
    checkRetainedExecutor.execute {
      // 检测是否发生内存泄露
      moveToRetained(key)
    }
  }
    
  @Synchronized private fun moveToRetained(key: String) {
    // 从监控队列中去除已被GC回收的
    removeWeaklyReachableObjects()
    // 检测一下 key对应的对象是否还在监控队列中。
    val retainedRef = watchedObjects[key]
    if (retainedRef != null) {
      // 记录检测到泄露的时间，时间 >0 表示是保留对象，可能存在泄露。
      retainedRef.retainedUptimeMillis = clock.uptimeMillis()
      // 回调给监听方，存在保留（泄露）对象。
      onObjectRetainedListeners.forEach { it.onObjectRetained() }
    }
  }
  // 从监控队列中去除引用队列中存在的对象。即去除已被GC回收的对象
  private fun removeWeaklyReachableObjects() {
    var ref: KeyedWeakReference?
    do {
      ref = queue.poll() as KeyedWeakReference?
      if (ref != null) {
        // 去除已被GC回收的对象
        watchedObjects.remove(ref.key)
      }
    } while (ref != null)
  }
}
```

##### InternalLeakCanary

```kotlin
internal object InternalLeakCanary : (Application) -> Unit, OnObjectRetainedListener {
  override fun onObjectRetained() = scheduleRetainedObjectCheck()
  // 
  fun scheduleRetainedObjectCheck() {
    if (this::heapDumpTrigger.isInitialized) {
      // 重新调用GC并检测泄露，同时也执行了堆转储
      heapDumpTrigger.scheduleRetainedObjectCheck()
    }
  }
}
```

##### HeapDumpTrigger

* 重新调用GC并检测是否存在内存泄露。
* 存在内存泄露会发送内存泄露通知。
* 执行堆转储。

```kotlin
internal class HeapDumpTrigger {
    
  // 这里会调用GC 并重新检测一下
  private fun checkRetainedObjects() {
    val iCanHasHeap = HeapDumpControl.iCanHasHeap()

    val config = configProvider()
	// 先不执行堆转储，而是发送通知
    if (iCanHasHeap is Nope) {
      if (iCanHasHeap is NotifyingNope) {
        // Before notifying that we can't dump heap, let's check if we still have retained object.
        var retainedReferenceCount = objectWatcher.retainedObjectCount
        if (retainedReferenceCount > 0) {
          // 调用一下GC
          gcTrigger.runGc()
          // 重新获取保留对象，此时 count > 0 表示存在泄露
          retainedReferenceCount = objectWatcher.retainedObjectCount
        }
        val nopeReason = iCanHasHeap.reason()
        val wouldDump = !checkRetainedCount(
          retainedReferenceCount, config.retainedVisibleThreshold, nopeReason
        )
		// 显示 内存泄露 通知
        if (wouldDump) {
          val uppercaseReason = nopeReason[0].toUpperCase() + nopeReason.substring(1)
          onRetainInstanceListener.onEvent(DumpingDisabled(uppercaseReason))
          showRetainedCountNotification(
            objectCount = retainedReferenceCount,
            contentText = uppercaseReason
          )
        }
      } else {
        SharkLog.d {
          application.getString(
            R.string.leak_canary_heap_dump_disabled_text, iCanHasHeap.reason()
          )
        }
      }
      return
    }
	// 这里就是 执行堆转储时的流程
    var retainedReferenceCount = objectWatcher.retainedObjectCount

    if (retainedReferenceCount > 0) {
      gcTrigger.runGc()
      retainedReferenceCount = objectWatcher.retainedObjectCount
    }

    if (checkRetainedCount(retainedReferenceCount, config.retainedVisibleThreshold)) return

    val now = SystemClock.uptimeMillis()
    val elapsedSinceLastDumpMillis = now - lastHeapDumpUptimeMillis
    if (elapsedSinceLastDumpMillis < WAIT_BETWEEN_HEAP_DUMPS_MILLIS) {
      onRetainInstanceListener.onEvent(DumpHappenedRecently)
      showRetainedCountNotification(
        objectCount = retainedReferenceCount,
        contentText = application.getString(R.string.leak_canary_notification_retained_dump_wait)
      )
      scheduleRetainedObjectCheck(
        delayMillis = WAIT_BETWEEN_HEAP_DUMPS_MILLIS - elapsedSinceLastDumpMillis
      )
      return
    }

    dismissRetainedCountNotification()
    val visibility = if (applicationVisible) "visible" else "not visible"
    dumpHeap(
      retainedReferenceCount = retainedReferenceCount,
      retry = true,
      reason = "$retainedReferenceCount retained objects, app is $visibility"
    )
  }
}
```



### JVM TI

[JVM(TM) Tool Interface 1.2.1 (oracle.com)](https://docs.oracle.com/javase/7/docs/platform/jvmti/jvmti.html)

我们可以通过这套接口定制的性能监控、数据采集、行为修改等工具。

例如抖音的 Kenzo 内存监控框架：[抖音 Android 性能优化系列：Java 内存优化篇_语言 & 开发_字节跳动技术团队_InfoQ精选文章](https://www.infoq.cn/article/b9SidcmWrZqYYjSzKbdf)

#### 获取JVM TI 相关文件

相关文件 在JDK的安装目录中：

*  ``D:\Java\jdk1.8.0_291\include`` 包含 `jni.h`、`jvmti.h`。
* ``D:\Java\jdk1.8.0_291\include\win32`` 包含 `jni_md.h`。不同平台目录不同。

| 支持的功能              |                                                             |          |
| ----------------------- | ----------------------------------------------------------- | -------- |
| VMObjectAlloc           | 虚拟机分配对象时                                            | 对象监控 |
| ObjectFree              | GC 释放对象时                                               |          |
| -                       |                                                             |          |
| MethodEntry             | 开始执行方法时                                              |          |
| MethodExit              | 方法执行完，异常退出时                                      |          |
| FramePop                | 方法return时，或发生异常时。手动调用 `NofityFramePop`函数。 |          |
| -                       |                                                             |          |
| Exception               | 有异常抛出时                                                |          |
| ExceptionCatch          | 异常被捕获时                                                |          |
| -                       |                                                             |          |
| SetFieldAccessWatch     | 设置观察点属性。                                            |          |
| FieldAccess             | 访问了观察的属性时。                                        |          |
| FieldModification       | 观察属性被修改时                                            |          |
| -                       |                                                             |          |
| GarbageCollectionStart  | 开始GC。                                                    |          |
| GarbageCollectionFinish | GC结束。                                                    |          |
|                         |                                                             |          |

#### 线程相关事件

* 监控对象的分配 和 回收。
* 获取 Java堆栈。
* 根据对象的引用树（引用链），可以遍历查看堆中的所有对象。
* 监听类加载修改类：监听 类加载时机，根据回调 来修改类信息。也可以对加密的Class进行解密。
* 暂停/恢复 线程。

### ART TI

ART TI  是 Android 中的 ART 虚拟机 提供的一套类似 JVM TI 的接口。

[ART TI  | Android 开源项目  | Android Open Source Project (google.cn)](https://source.android.google.cn/docs/core/runtime/art-ti?hl=zh-cn)







---

## 性能分析常用脚本

### 查看内存使用情况

[使用内存分析器查看应用的内存使用情况  | Android 开发者  | Android Developers](https://developer.android.com/studio/profile/memory-profiler?hl=zh-cn)

```
adb shell dumpsys meminfo <package_name|pid> [-d]
```

### 获取ANR 转储信息以及 GC 的详细性能信息

> 发送 SIGQUIT 信号获得 ANR 日志。

```
adb shell kill -S QUIT PID
adb pull /data/anr/traces.txt
```

使用 systrace 来观察 GC 的性能耗时



### dmtracedump

dmtracedump 是 一种用于从跟踪日志文件**生成图形化调用堆栈图**的工具。

#### 接入方式 

```java
	@Override
    protected void onCreate(Bundle savedInstanceState) {
    	// 默认输出 /sdcard/Android/data/com.xx.xx/files/dmtrace.trace
        Debug.startMethodTracing();
        // 变更输出到 /sdcard/dmtrace.trace
        // Debug.startMethodTracing("dmtrace"); 
        super.onCreate(savedInstanceState);
        ....
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Debug.stopMethodTracing();
    }
```


#### 查看dmtrace.trace文件

- 拷贝到电脑上
  ``adb pull /sdcard/Android/data/com.xx.xx/files .``

- 将dmtrace.trace转换成html输出
  ``dmtracedump -h dmtrace.trace > aa.html``

### Perfetto

[perfetto  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/studio/command-line/perfetto?hl=zh_cn)

#### 抓取方式

> 直接跳转到设置中的页面操作跟踪

```shell
adb shell am start com.android.traceur/com.android.traceur.MainActivity
```

> 命令行方式

```shell
adb shell perfetto --config CONFIG-FIle --out FILE
```

#### 将trace文件导入到perfetto中

打开https://ui.perfetto.dev/网页。选择`Open trace file`。



### UI渲染性能测量

#### gfxinfo

输出包含各阶段发生的动画以及帧相关的性能信息

```shell
# 输出包含各阶段发生的动画以及帧相关的性能信息
adb shell dumpsys gfxinfo [包名]
# 获取最近120 帧每个绘制阶段的耗时信息
adb shell dumpsys gfxinfo [包名] framestats
```

#### SurfaceFlinger

拿到系统 SurfaceFlinger 相关的信息：Graphic Buffer内存的占用情况

```shell
adb shell dumpsys SurfaceFlinger
```

---

