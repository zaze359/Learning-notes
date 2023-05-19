# Android之Intent

[Intent 和 Intent 过滤器  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/components/intents-filters?hl=zh-cn)

Intent 是一个消息传递对象，常用于组件间互相传递数据或者启动组件。包括以下几个使用场景：

* 启动Activity：`startActivity()`。
* 启动Service：`startService()`、`bindService()`。
* 传递广播：`sendBoradcast()`、`sendOrdedBroadcast()`



## Intent

### Action

* Intent.ACTION_VIEW：Android内置的action，对应可向用户显示的信息。（例如，要使用图库应用查看的照片；或者要使用地图应用查看的地址）
* Intent.ACTION_SEND：共享Intent，和其他应用共享的数据。（例如，电子邮件应用或社交共享应用）

```kotlin
val intent = Intent(Intent.ACTION_VIEW)
```

### Data

引用待操作数据和/或该数据 MIME 类型的 URI。

定义：

```xml
<data
      android:host="www.example.com"
      android:path="/entrance"
      android:port="80"
      android:scheme="https" />
```

使用：

```kotlin
val intent = Intent(Intent.ACTION_VIEW).apply {
    data = Uri.parse("https://www.example.com:80/entrance")
    setPackage(context.packageName)
}
```

### Category

一个包含应处理 Intent 组件类型的附加信息的字符串。可以将任意数量的类别描述放入一个 Intent 中。

* CATEGORY_LAUNCHER

  表示初始 Activity，会在系统的应用启动器中显示这个应用。

* CATEGORY_BROWSABLE

  允许Activity通过网络浏览器启动，显示链接引用的数据，如图像或电子邮件。

### Extra

携带的附加信息。

```kotlin
intent.putExtra("key", "value")
```

### Flag

指示 Android 系统如何启动 Activity。

## Intent类型

### 显示Intent

提供**目标应用的软件包名称**或**完全限定的组件类名**来指定可处理 Intent 的应用。

```kotlin
// 明确指定Activity类
val intent = Intent(context, EntranceActivity::class.java)
// 设置指定packageName 的classname。
intent.setClassName("com.aaa", className)
// 设置 class类
intent.setClass(context, targetClass);
// 设置组件
intent.setComponent()
```

### 隐式Intent

不会指定特定的组件，而是声明要执行的常规操作，从而允许其他应用中的组件来处理。

```kotlin
// 指定 Action
val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
```



## 一些常用的Intent跳转

### 应用详情界面

打开**设置中的应用详情页**。

常用于权限被永久拒绝时，引导用户打开权限。

```kotlin
val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
intent.data = Uri.fromParts("package", context.packageName, null)
```

### 应用使用量

打开 **使用情况访问权限** 配置界面。

```kotlin
val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
```

### 浏览器打开指定网页

```kotlin
val intent = Intent(Intent.ACTION_VIEW)
intent.data = Uri.parse("https://www.baidu.com")
context.startActivity(intent)
```

