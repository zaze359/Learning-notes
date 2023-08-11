# Android界面状态保存和恢复

## 为什么要保存界面状态？

在Android使用过程中，如果我们常常会遇到横竖屏的切换，而有些应用由于没有做好状态的保存和恢复的流程，在发生切换后页面被重新创建，导致我们之前输入的内容消失了，所有的操作都需要重新来一遍。

还有就是我们常常将一个应用放到了后台，然后去打开使用其他应用，过会切回来时，发现之前的应用被杀死了需要重新打开，之前所有的操作都消失了。凡此种种情况在用户体验方面是极差的。

## 什么情况下界面状态会丢失？

Activity状态丢失的场景主要有以下两个：

* 配置变更（旋转、切换到[多窗口模式](https://developer.android.google.cn/guide/components/activities/state-changes)）。

  > 默认情况下系统会在配置变更时销毁 Activity。
  >
  > 虽然可以通过[配置`android:configChanges`](https://developer.android.google.cn/guide/topics/resources/runtime-changes#HandlingTheChange)，使得配置变化时Activity不被销毁，但是官方不推荐这么做。

  ```shell
  # 横竖屏切换
  MainActivity@cb6fcdc onPause
  MainActivity@cb6fcdc onStop
  MainActivity@cb6fcdc onDestroy
  # 重新创建了Activity
  MainActivity@efb5403 onCreate
  MainActivity@efb5403 onStart
  MainActivity@efb5403 onResume
  ```

* 进入后台进程被销毁

  官方提供了进程生命周期和 Activity 状态之间的关系：

  > 系统需要释放 RAM 时，会终止 Activity 所在的进程，尤其是后台应用。
  >
  > **被系统销毁的导致退出这一情况会调用`onSaveInstanceState()`**。正常退出不会调用。

  ![image-20221026212439404](./Android%E7%95%8C%E9%9D%A2%E7%8A%B6%E6%80%81%E4%BF%9D%E5%AD%98%E5%92%8C%E6%81%A2%E5%A4%8D.assets/image-20221026212439404-1666790680792-3.png)



## 如何保存和恢复界面状态？

当Activity 由于一些系统限制（配置变更或内存压力）导致被而销毁时，系统会保存一组描述 Activity 销毁时状态的数据（这些数据称为**实例状态**，是存储在 **Bundle** 对象中的键值对集合）。

用户尝试回退到该 Activity，系统将使用该数据新建Activity，尝试自动恢复到之前的状态。

> 系统保存的是每个View对象的相关信息，不过不包括我们的成员变量。
>
> 视图必须具有 `android:id` 属性提供的唯一 ID才能被系统恢复。
>
> **正常用户操作不会触发此系统恢复流程**。例如按返回按钮、调用`finish()`、设置或最近任务栏中关闭应用。

当系统的默认行为和我们的需求预期不同时，则需要我们自己保存一些页面状态， 官方建议  组合使用 `ViewModel`和`onSaveInstanceState()` ，对于需要持久化的复杂数据则还需要结合本地存储的方式。

* `ViewModel`：允许进程终止后丢失的数据，**一般应用操作过程中的数据都可存储在这，当缓存使用**。访问速度快。
* `onSaveInstanceState()`：**简单轻量的数据**，一般存储一些简单变量和view的状态。访问速度慢。
* 本地存储：**重要的数据**。访问速度慢。

详情可以参考官方提供的文档：[保存界面状态  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/topic/libraries/architecture/saving-states)

![image-20221027114108213](./Android%E7%95%8C%E9%9D%A2%E7%8A%B6%E6%80%81%E4%BF%9D%E5%AD%98%E5%92%8C%E6%81%A2%E5%A4%8D.assets/image-20221027114108213.png)



### 使用`onSaveInstanceState()`保存简单数据

保存简单轻量的数据时使用， 因为它是使用Bundle存储数据的，会产生序列化/反序列化的性能损耗。

当用户显式关闭 Activity 时，或者在其他情况下调用 `finish()` 时，系统不会调用 `onSaveInstanceState()`。

> 何时被调用？
>
> If called, this method will occur after onStop() for applications targeting platforms starting with Build.VERSION_CODES.P.  For applications targeting earlier platform versions this method will occur before onStop() and there are no guarantees about whether it will occur before or after onPause().
>
> **在Android P(9.0)之后是在`onStop()`之后调用。Android 9.0 之前则是在`onStop()`之前，但不保证在`onPause()`之前还是之后。**

```kotlin
override fun onSaveInstanceState(outState: Bundle?) {
    // Save the user's current game state
    outState?.run {
        putInt(STATE_SCORE, currentScore)
        putInt(STATE_LEVEL, currentLevel)
    }

    // Always call the superclass so it can save the view hierarchy state
    super.onSaveInstanceState(outState)
}

companion object {
    val STATE_SCORE = "playerScore"
    val STATE_LEVEL = "playerLevel"
}
```

**恢复Activity 界面状态**

> Activity重建时，在`onCreate()`和 `onRestoreInstanceState()` 中均会收到包含实例状态的Bundle。
>
> `onRestoreInstanceState()`在 `onStart() `之后

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState) // Always call the superclass first

    // Check whether we're recreating a previously destroyed instance
    if (savedInstanceState != null) {
        with(savedInstanceState) {
            // Restore value of members from saved state
            currentScore = getInt(STATE_SCORE)
            currentLevel = getInt(STATE_LEVEL)
        }
    } else {
        // Probably initialize members with default values for a new instance
    }
    // ...
}

/// 仅当存在要恢复的已保存状态时，系统才会调用
override fun onRestoreInstanceState(savedInstanceState: Bundle?) {
    // Always call the superclass so it can restore the view hierarchy
    super.onRestoreInstanceState(savedInstanceState)

    // Restore state members from saved instance
    savedInstanceState?.run {
        currentScore = getInt(STATE_SCORE)
        currentLevel = getInt(STATE_LEVEL)
    }
}
```



### 使用`ViewModel`保存状态数据

`ViewModel`会在内存中保存我们的数据，但是当进程被终止时，数据会丢失。所以我们可以结合使用`onSaveInstanceState()`来保存状态，使用本地存储（如SQLite）来保存重要数据。

`Android Jetapck`通过提供了[`SavedStateHandle`]()，让我们能够方便的结合`onSaveInstanceState()`来保存轻量数据。

```kotlin
// 在构造函数中声明需要使用SavedStateHandle
class SavedStateViewModel(private val savedStateHandle: SavedStateHandle) : ViewModel() {
    // SavedStateHandle类是一个键值对映射，用于通过 set() 和 get() 方法向已保存的状态写入数据以及从中检索数据。
    // savedStateHandle支持LiveData和StateFlow
    // savedStateHandle.getLiveData<String>("query")
    // savedStateHandle.getStateFlow<String>("query")
}

// ViewModelFactory中会默认提供SavedStateHandle
// 自定义的Factory 可以通过扩展 AbstractSavedStateViewModelFactory 实现。
class MainFragment : Fragment() {
    val vm: SavedStateViewModel by viewModels()

    ...
}
```

> 我们可以使用 `SavedStateRegistry` 处理状态数据。`SavedStateHandle`也是基于`SavedStateRegistry`创建的。

## Bundle 数据保存

Android 会在应用进程之外 将 Bundle数据的序列化副本保留在内存中，若使用的是 PersistableBundle，则将保存在磁盘中（不过一般不推荐使用）。

Bundle 对象并不适合保留大量数据，因为它需要在主线程上进行序列化处理并占用系统进程内存。

如需保存大量数据，需要使用其他持久性本地存储方式。

## 如何测试

官方提供了Activity测试方式([`ActivityScenario`](https://developer.android.google.cn/guide/components/activities/testing))。当然我们也可以直接编写代码输出日志来一边开发一边测试。