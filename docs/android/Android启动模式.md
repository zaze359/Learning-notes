---
title: Android启动模式
date: 2020-08-12 09:38
---

# Android中的启动模式

[了解任务和返回堆栈  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/components/activities/tasks-and-back-stack#ManagingTasks)

* task：任务。
* back stack：task中的堆栈。
* LuanchMode: 启动模式。
* taskAffinity：亲和性，表明该 Activity 倾向于哪个task，默认值是应用的包名。

## TaskAffinity：任务亲和性

亲和性表示Activity 倾向于哪个task，它的默认值是应用的包名。可以使用`taskAffinity`属性指定 Activity 的亲和性。

若设置了Activity的启动模式，在不违背Activity启动模式规则的情况下，会优先使用相同亲和性的`task`。

* 即**最后这个Activity是否在会相同亲和性的栈中还和它的启动模式有关**。

* 若两个Activity`taskAffinity`不同将可以在最近任务栏看到两个Activity分别占一栏。

* **两个Activity的 `task` 可能不同，但是`taskAffinity`可能相同**。 启动`singleInstance/singleTask`的Activity时，会新建一个`taskAffinity`相同的 task，除非特意指定了不同的`taskAffinity`。

> 同一应用中的所有 Activity 默认情况彼此具有亲和性。

```xml
<activity
	android:name=".component.lifecycle.LifecycleActivity"
	android:screenOrientation="fullSensor"
	android:taskAffinity="com.zaze.demo.lifecycle"
	android:theme="@style/AppTheme.NoActionBar" />
```

## 默认启动模式

在Android 中默认情况下，同一应用中的所有 Activity 彼此具有亲和性，位于同一个`task`中。一个`task`中包含一个`back stack`。

系统管理 `task` 和 `back stack`的默认方式是 将所有接连启动的 Activity 都会在同一个 `task` 和 `back stack`中。不管是否是同一个应用的Activity，只要是默认的方式就在一起。

堆栈中的Activity永远不会重排序，依照后进先出的方式运作。



## 如何设置启动模式

> 官方推荐 只有当 Activity 具有 `ACTION_MAIN` 和 `CATEGORY_LAUNCHER` 过滤器时，才应使用 `"singleTask"` 和 `"singleInstance"` 这两种启动模式，它们会将 Activity 标记为始终启动任务。
>
> 存在的问题就是，应用退到后台，然后再从桌面点击应用打开时，并不会返回到`singleTask/singleInstance`的Activity。
>
> [“最近使用的应用”屏幕](https://developer.android.google.cn/guide/components/activities/recents)

不过Android也支持我们自己定义启动模式。

* 设置`luanchMode`属性指定启动模式：在`AndroidManifest.xml`中声明Activity时配置。
* 设置`Intent`的`flag`属性来指定启动模式：在`startActivity()`时的`Intent`中设置，可以替换Activity 声明时`launchMode`。

### 使用`launchMode`声明启动模式

`launchMode`存在以下几种启动模式：

> [activity-element  | Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/manifest/activity-element)
>
> `android:launchMode=["standard" | "singleTop" | "singleTask" | "singleInstance" | "singleInstancePerTask"]`
>
> Android 12新增了 `singleInstancePerTask`变为5种，之前的版本只有前四种。

#### standard ：标准模式

> Android中**默认**就是此模式。

每次启动都会在启动该 Activity 的Task中创建一个Activity 的新实例，并置于栈顶。适用于相互独立的页面。

* 栈内新建。
* Activity 可以多次实例化。
* 每个task中都可以存在多个相同Activity的实例。

![standard](./Android%E5%90%AF%E5%8A%A8%E6%A8%A1%E5%BC%8F.assets/standard.jpg)

#### singleTop：栈顶复用

若当前`task`的顶部已存在所需的Activity实例，将会复用这个实例并调用`onNewIntent()`方法。若所需的Activity实例不在堆栈顶部，则也会创建一个新的实例。即仅位于顶部时和`standard`存在差异。

* 栈顶复用，其他情况新建。
* Activity 可以多次实例化。
* 每个task中都可以存在多个相同Activity的实例。

![singleTop](./Android%E5%90%AF%E5%8A%A8%E6%A8%A1%E5%BC%8F.assets/singleTop-1679839413476-5.jpg)

#### singleTask：栈内复用（栈内唯一）

> **singleTask 一般用于应用内仅存在一个实例时的场景。**

若不存在亲和性相同的任务栈则会新建一个栈。若在亲和性相同的任务栈中已存在Activity实例，则会在这个栈中直接复用已存在的实例，不过需要注意的是原先堆栈中位于其上方的Activity都将出栈。

* Activity 实例有且仅有一个，存在则复用，不存在则新建。
* 复用时，原先堆栈中位于其上方的Activity都将出栈。

![singleTask](./Android%E5%90%AF%E5%8A%A8%E6%A8%A1%E5%BC%8F.assets/singleTask.jpg)

#### singleInstance：单实例（独占一个栈）

> **singleInstance一般用于需要和其他应用共享某个页面的场景。即多个应用共用一个实例。**
>
> 测试时发现 使用startActivityForResult()启动一个 singleInstance的Activity，并不会在一个单独的栈中。未找到原因不知道是否是bug。
>
> 使用startActivity()则是正常的。

和singleTask类似，在单独的堆栈中,且存在时会复用。不同点在于singleInstance中**目标 Activity 始终是其task唯一的成员**；由该 Activity 启动的任何 Activity 都会在其他的task中打开。

* 位于单独的task中，存在则复用。
* task中仅有该Activity 实例，且仅有一个。
* 由该 Activity启动的任何 Activity 都会在其他的task中。

![singleInstance](./Android%E5%90%AF%E5%8A%A8%E6%A8%A1%E5%BC%8F.assets/singleInstance.jpg)

#### singleInstancePerTask

> Android 12 新增，

 `singleInstancePerTask`activity 在 `FLAG_ACTIVITY_MULTIPLE_TASK` 或 `FLAG_ACTIVITY_NEW_DOCUMENT` 已设置的情况下，在不同的任务中可以多次实例化。

---



### LaunchMode

> **假设堆栈中已存在 A-B-C-D 四个Activity实例，D为栈顶**。
>
> 不同启动模式的下对执行相同操作的结果如下表所示：
>
> * ABE这三个Activity都是standard模式。
> * C和D启动模式相同，根据情况变化。
> * Tn表示不同的栈

| C和D的启动模式               | 启动一个D                     | 启动一个C                     | 启动一个E                                |
| ---------------------------- | ----------------------------- | ----------------------------- | ---------------------------------------- |
| standard                     | T1：A-B-C-D-D                 | T1：A-B-C-D-D-C               | T1：A-B-C-D-D-C-E                        |
| singleTop                    | T1：A-B-C-D                   | T1：A-B-C-D-C                 | T1：A-B-C-D-C-E                          |
| singleTask，taskAffinity相同 | T1：A-B-C-D                   | T1：A-B-C                     | T1：A-B-C-E                              |
| singleTask，taskAffinity不同 | T1：A-B<br />T2：C<br />T3：D | T1：A-B<br />T2：C<br />T3：D | T1：A-B<br />T2：C-E<br />T3：D          |
| singleInstance               | T1：A-B-C<br />T2：D          | T1：A-B<br />T2：D<br />T3：C | T1：A-B<br />T2：D<br />T3：C<br />T4：E |

### 通过Intent中的Flag设置启动模式

> [Intent  | Android Developers (google.cn)](https://developer.android.google.cn/reference/android/content/Intent#FLAG_ACTIVITY_NEW_TASK)

| Flag                     | 说明                                                         |      |
| ------------------------ | ------------------------------------------------------------ | ---- |
| FLAG_ACTIVITY_NEW_TASK   | 同`singleTask`                                               |      |
| FLAG_ACTIVITY_SINGLE_TOP | 同`singleTop`                                                |      |
| FLAG_ACTIVITY_CLEAR_TOP  | **会销毁位于它之上的所有其他 Activity**。<br />1. 和`FLAG_ACTIVITY_NEW_TASK`一起使用时，会查找在其他task中是否已存在指定Activity的实例，存在则会复用它，否则就创建一个。<br />2. 在`standerd模式`下，不仅会清空位于此Activity 上方的其他Activity，同时也会将自身销毁。但是会再重新创建一个Activity 实例。 |      |
|                          |                                                              |      |



## 如何观察Activity所处的任务栈

```shell
# 查看当前的activity状态 -p 指定包名
adb shell dumpsys activity activities
adb shell dumpsys activity -p com.zaze.demo activities
```







## 参考资料

[Activity的五种启动模式 (qq.com)](https://mp.weixin.qq.com/s/uiAOYOQu7ZM3jrPYuv6cPg)

[了解任务和返回堆栈  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/components/activities/tasks-and-back-stack#ManagingTasks)

[activity 清单元素 activity-element  | Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/manifest/activity-element)

[(8条消息) Android 的singleTask和singleInstance的一点思考_好人静的博客-CSDN博客_singletask和singleinstance](https://blog.csdn.net/nihaomabmt/article/details/86490090)
