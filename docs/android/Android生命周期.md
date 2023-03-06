# Android生命周期

一个应用内的启动、跳转、退出以及应用间的跳转返回等等都涉及到了生命周期相关知识。所以了解Android的生命周期可以说是作为Android开发的基础。

本文从以下几个部分来学习Android的生命周期：

* Activity的生命周期
* Fragment的生命周期
* 和生命周期相关的组件

## Activity的生命周期

[了解 Activity 生命周期  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/components/activities/activity-lifecycle)

### 生命周期流程

首先通过Google提供的Activity生命周期图例来大致了解流程：

![img](./Android%E7%94%9F%E5%91%BD%E5%91%A8%E6%9C%9F.assets/activity_lifecycle.png)



| 回调                                  | 调用时机                                                     | Activity状态                                     | Lifecycle事件 | 说明                                                         |
| ------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------ | ------------- | ------------------------------------------------------------ |
| `onCreate(Bundle savedInstanceState)` | **Activity创建时触发**                                       | Created：**不可见**                              |               | 可以在此方法中做一些初始化操作。如：调用`setContentView()`设置页面布局或`databinding`绑定视图、成员变量的初始化、`ViewModel`的关联等。紧接着调用`onStart()` |
| `onStart()`                           | `onCreate()`调用后被调用。`onRestart()`后也会被调用          | Started：**可见**                                | ON_START      | 调用使 Activity 对用户可见，紧接着调用`onResume()`。<br />一般于`onStop()`对应。 |
| `onRestart()`                         | 从`ON_STOP`状态恢复为`ON_START`过程中会先调用此方法然后紧接着调用`onStart`。 |                                                  |               |                                                              |
| `onResume`                            | `onStart()`调用后会调用；从Paused状态变为Resumed状态时也会调用 | Resumed：**可见可交互**                          | ON_RESUME     | Activity处于前台可见且获取到焦点。<br />一般和`onPause()`对应。 |
| `onPause()`                           | 半透明 Activity或者外部弹窗打开时。多窗口切换。触发`onStop()`之前会先调用`onPause()` | **部分可见**。在多窗口时Activity还是全部可见的。 | ON_PAUSE      | Activity部分可见时调用，比如触发了外部弹窗。可以在此时暂停一些非必要的操作和释放一些资源。比如停止相机的预览。但是不能做耗时操作，会影响跳转页面的显示。 |
| `onStop()`                            | Activity完全不可见时调用。例如跳转到新的界面，退到后台等。   | **完全不可见**                                   | ON_STOP       | Activity完全不可见时会调用。此时可以释放一些无用资源。例如暂停动画等。也可以此时持久化一些数据（但不太推荐这么做）。 |
| `onDestory()`                         | 调用了`finish()`或者被进程被kill等原因导致Activity销毁时会调用 | **不可见且被销毁**                               | ON_DESTORY    | 会此时应当释放所有资源。                                     |

### Activity状态的变化场景分析

> [状态的保存和恢复](./Android界面状态保存和恢复.md)
>

**Activity新建**

```shell
LifecycleActivity onCreate
LifecycleActivity onStart
LifecycleActivity onResume
```
**Activity退出**

> 用户点击返回等操作。

```shell
LifecycleActivity onPause
LifecycleActivity onStop
LifecycleActivity onDestory
```

**Activity 或对话框显示在前台**

> 完全遮罩场景。（设备锁屏/解锁也是此场景）

```shell
# 开启遮罩
LifecycleActivity onPause
LifecycleActivity onStop
# 关闭前台遮罩
LifecycleActivity onRestart
LifecycleActivity onStart
LifecycleActivity onResume
```
> 局部覆盖

```shell
# 开启遮罩
LifecycleActivity onPause
# 关闭前台遮罩
LifecycleActivity onResume
```

**Activity页面跳转（完全遮罩）**

> 启动第二个 Activity 的过程与停止第一个 Activity 的**生命周期过程是重叠的**。
>
> 当第二个 Activity 共享了第一个 Activity 的某些数据时，如果跟新数据时在第一个Activity 的`onStop()`中处理，
>
> 那么第二个Activity 在获取到的数据可能就会存在偏差（例如在`onCreate()`中获取）。

```shell
MainActivity onPause
# 注意此处：跳转页面是在onPause后启动的，所以在onPause中不能处理耗时操作。
BitmapActivity onCreate
BitmapActivity onStart
BitmapActivity onResume
MainActivity onStop
```
**Activity状态丢失的场景**：

> **被系统销毁的导致退出这一情况会调用`onSaveInstanceState()`**。正常退出不会调用。

* **配置变更（旋转、切换到[多窗口模式](https://developer.android.google.cn/guide/components/activities/state-changes)）：**默认情况下系统会在配置变更时销毁 Activity。

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

* **进入后台进程被销毁**

  系统需要释放 RAM 时，会终止 Activity 所在的进程，尤其是后台应用。

  

## Fragment的生命周期

> Fragment的生命周期受Activity生命周期的影响，且依附于Activity。
>
> `FragmentManager` 管理了 Fragment的生命周期状态。



![fragment lifecycle states and their relation both the fragment's             lifecycle callbacks and the fragment's view lifecycle](./Android%E7%94%9F%E5%91%BD%E5%91%A8%E6%9C%9F.assets/fragment-view-lifecycle.png)

> 摘选部分生命周期回调函数，其他函数和Activity类似。

| 回调                      |                                                              |
| ------------------------- | ------------------------------------------------------------ |
| ~~`onAttach()`~~          | 已废弃。和Context（Activity）关联时调用。之后会调用`onCreate()` |
| `onCreate()`              | `onAttach()`之后被调用。                                     |
| `onCreateView()`          | 可以在这里构建View。                                         |
| `onViewCreate()`          | 可以在这里对View进行一些初始化操作。和`onDestoryView()`对应  |
| ~~`onActivityCreated()`~~ | 已废弃。使用`onViewCreate()`。                               |
| `onViewStateRestored()`   | 在`onViewCreate()`之后，`onStart()`之前调用。状态恢复时调用，相当于Activity中的`onRestoreInstanceState()` |
| `onDestoryView()`         | 准备销毁view。和`onViewCreate()`对应。                       |
| `onDestory()`             | 准备销毁fragment。                                           |
| `onDetach()`              | 不再和Activity绑定时调用。                                   |



## 进程和生命周期间的联系

[进程和应用生命周期  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/components/activities/process-lifecycle)

> **以下进程的优先级 从高到低。越低越容易被回收。**

### 前台进程

> 仅当设备内存过低，无法维持前台进程时才会被回收。

用户执行交互的应用进程。

* Activity处于`onResume()`状态下，能和用户交互。
* `BroadcastReceiver.onReceive()` 方法正在执行。
*  有一个`Service` 目前正在执行其某个回调。

### 可见进程

> 服务进程回收完后 依然不够维持 前台 时，才会回收此类进程。

用户能看见知晓的应用进程。

* Activity处于`onPause()`状态下，用户可见，但是并不和它交互。
*  `Service`作为前台服务运行，调用了`Service.startForeground()`。
* 系统在使用应用进程提供的特定服务，并且用户知晓。例如动态壁纸、输入法服务等。

### 服务进程

> 运行时间过久（> 30min）会降级为缓存进程。
>
> 缓存进程回收完后 依然不够维持 前台和可见进程时，才会回收此类进程。

* 存在一个已使用 `startService()` 方法启动的 `Service`。可能在进行数据下载。

### 缓存进程

缓存进程是为了能够高效切换应用而提供的机制，是当前我们并不需要使用的应用进程，所有在**内存有需要时会被优先回收**。



## 生命周期相关组件

[使用生命周期感知型组件处理生命周期  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/topic/libraries/architecture/lifecycle)

>  `@OnLifecycleEvent`注解遭废弃后，官方建议使用`LifecycleEventObserver `

### Lifecycle

*   用于存储有关组件（如 activity 或 fragment）的生命周期状态的信息，并允许其他对象观察此状态。
*   定义了Events和Steates来表示生命周期变化事件以及当前的生命周期状态。
*   用于感知LifecycleOwner的生命周期
*    `Fragment` 和 `SupportActivity` 中实现Lifecycle。Activity并没有实现。

![image-20230228131329406](./Android%E7%94%9F%E5%91%BD%E5%91%A8%E6%9C%9F.assets/image-20230228131329406.png)

使用方式

```java
// 继承 DefaultLifecycleObserver 来监控组件的生命周期状态
class MyObserver : DefaultLifecycleObserver {
    override fun onResume(owner: LifecycleOwner) {
        connect()
    }

    override fun onPause(owner: LifecycleOwner) {
        disconnect()
    }
}

public class MainActivity extends AppCompatActivity {
    MyObserver myObserver;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // ....
        myObserver = new MyObserver();
        // 注册监听
        getLifecycle().addObserver(myObserver);
    }
}
```

### LiveData

*   能够感知实现了`LifecycleOwner`接口的组件生命周期。

*   可以监听数据变化进行实时更新

```java
public class MainActivity extends AppCompatActivity {
    private MutableLiveData<String> mLiveData;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // ....
        mLiveData = new MutableLiveData<>();
        // 转入LifecycleOwner 监听生命周期
        mLiveData.observer(this, new Observer<String>() {
            @Override
            public void onChanged(@Nullable String s) {
                // 数据发生变化
            }
        });
    }
    
    private void a() {
        // 更新数据
        // post 走的 消息机制 = handler.post({setValue()})
        mLiveData.postValue("post");
        mLiveData.setValue("set");
    }
}
```

```java
public class MyLiveData extends LiveData<String> {
    // ....
    @Override
    protected void onActive() {
        super.onActive();
        // 接收到状态变更检测到存在active状态observer
    }

    @Override
    protected void onInactive() {
        super.onInactive();
        // 接收到状态变更检测到不存在active状态observer
    }
}

```



### ViewModelScope

>  `ViewModel` 和 `kotlin协程` 结合使用。协程生命周期和`ViewModel`绑定。
>
> `androidx.lifecycle:lifecycle-viewmodel-ktx:2.4.0`

```kotlin
class MyViewModel: ViewModel() {
    init {
        viewModelScope.launch {
            // Coroutine that will be canceled when the ViewModel is cleared.
        }
    }
}
```

### LifecycleScope

> `Activity/Fragment`结合 `kotlin协程`使用。协程生命周期和`Activity/Fragment`绑定。
>
> `androidx.lifecycle:lifecycle-viewmodel-ktx:2.4.0`

```kotlin
class MyFragment : Fragment() {

    val viewModel: MyViewModel by viewModel()

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        viewLifecycleOwner.lifecycleScope.launch {
            // Lifecycle 至少处于 STARTED 状态时运行，并且会在 Lifecycle 处于 STOPPED 状态时取消运行
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.someDataFlow.collect {
                    // Process item
                }
            }
        }
    }
}
```



## 测试生命周期

```kotlin
@RunWith(AndroidJUnit4::class)
class MyTestSuite {

    //  activityScenarioRule在 androidx.test.ext:junit-ktx 库中
    @get:Rule
    var activityScenarioRule = activityScenarioRule<LifecycleActivity>()
//    var activityScenarioRule = ActivityScenarioRule(LifecycleActivity::class.java)
    
    @Test
    fun testEvent() {
        val scenario = activityScenarioRule.scenario
        // scenario.moveToState(Lifecycle.State.CREATED)
        scenario.recreate()
    }
}

```

### 遇到的问题

```shell
# 异常：
android.content.ActivityNotFoundException: Unable to find explicit activity class {com.zaze.demo.test/androidx.test.core.app.InstrumentationActivityInvoker$BootstrapActivity}

# android 13
# target 33
```

处理方式：

````groovy
// 1.5.0-alpha02 修复了这个问题
androidx.test:core:1.5.0-alpha02
````

