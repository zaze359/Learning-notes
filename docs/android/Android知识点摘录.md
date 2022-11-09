# Android知识点摘录

## 常用链接

[Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/?hl=zh-cn)

[查看版本变更：Android Releases | Android Developers (google.cn](https://developer.android.google.cn/about/versions)

[开发者指南  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide)

[Android Jetpack 开发资源 - Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/jetpack?hl=zh-cn)

[Android 开源项目  | Android Open Source Project](https://source.android.com/)




## 自定义View相关

View\.post()

### MeasureSpecMode(测量模式)

```java
/**
 * 没有任何限制, 想多大多大
 */
public static final int UNSPECIFIED = 0 << MODE_SHIFT;

/**
 * 父容器已经精确的计算出子View的大小SpecSize, 此时子View的实际大小就是SpecSize, 忽略子View要的大小
 */
public static final int EXACTLY     = 1 << MODE_SHIFT;

/**
 * 父容器指定了一个大小SpecSize, 子View的大小 <= SpecSize
 */
public static final int AT_MOST     = 2 << MODE_SHIFT;
```

## VelocityTracker(速度追踪器)

声明:

```kotlin
private val mVelocity: VelocityTracker = VelocityTracker.obtain()
```

使用

```kotlin
override fun onTouch(event: MotionEvent) {
    when (event.action) {
        MotionEvent.ACTION_DOWN -> {
            mVelocity.clear()
        }
        MotionEvent.ACTION_MOVE -> {
            // 添加用户行为
            mVelocity.addMovement(event)
            // 1000：表示每秒的像素值。
            mVelocity.computeCurrentVelocity(1000)
        }
        MotionEvent.ACTION_CANCEL, MotionEvent.ACTION_UP -> {
        }
    }
}
```

回收:

```kotlin
override fun onDestroy() {
    super.onDestroy()
    mVelocity.recycle()
}
```


### Scroller(滚动器)

创建实例：
```kotlin
val scroller: Scroller by lazy {
    Scroller(context, LinearInterpolator())
}
```

设置滚动：
```kotlin
// startX, startY: 开始滚动的起点坐标
// dx, dy: 偏移量
// duration: 滚动耗时，默认250ms
scroller.startScroll(startX, startY, dx, dy, duration)
// 惯性滚动时 velocityX，velocityY 可以通过使用VelocityTracker获取
scroller.fling(startX, startY, velocityX, velocityY, minX, maxX, minY, maxY)
```

获取滑动信息：
```kotlin

override fun computeScroll() {
    // 若滑动已经终止返回false，否则会计算偏移量，并返回ture。
    if(scroller.computeScrollOffset()) {
        // 获取滑动的位置
        var x = scroller.getCurrX()
        var y = scroller.getCurrY()
    }
}
```

> 停止滑动动画，直接滚动到最终位置
```kotlin
if (!scroller.isFinished) {
    scroller.abortAnimation()
}
```

***


## 一些view控件等使用

### RecyclerView(列表、表格)

#### 1. LayoutManager

*   GridLayoutManager ： 表格布局

*   LinearLayoutManager ： 线性布局

#### 2. ItemDecoration(装饰)

可以装饰RecyclerView的子item，例如绘制分割线等。

```java
getItemOffsets(Rect outRect, View view, RecyclerView parent, State state) 
```

设置边距：

*   outRect : 设置padding, 可以理解为Item包含在这个矩形中

*   view  : itemView

*   parent : RecyclerView

*   state : RecyclerView的状态 但并不包含滑动状态

```java
onDraw(Canvas c, RecyclerView parent, State state) 

onDrawOver(Canvas c, RecyclerView parent, State state)
```

### SwipeRefreshLayout(刷新)

*   setRefreshing(boolean)

<!---->

    true  : 显示刷新UI
    false : 关闭刷新UI

*   setOnRefreshListener(..)

<!---->

    刷新监听事件

***




## 屏幕方向

1.  参数：

```java
//未指定，此为默认值。由Android系统自己选择合适的方向。
ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
//横屏
ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE
//用户当前的首选方向
ActivityInfo.SCREEN_ORIENTATION_USER
//继承Activity堆栈中当前Activity下面的那个Activity的方向
ActivityInfo.SCREEN_ORIENTATION_BEHIND
//由物理感应器决定显示方向
ActivityInfo.SCREEN_ORIENTATION_SENSOR
ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT
//忽略物理感应器——即显示方向与物理感应器无关
ActivityInfo.SCREEN_ORIENTATION_NOSENSOR
//
ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE
ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT
ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR
```

1.  设置屏幕方向

```java
setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED)
```



## 字体

> 摘自<http://www.miui.com/thread-8343134-1-1.html>

*   NotoSansCJK-Regular.ttc
    思源黑体，Android7.0默认的中文字体，负责中文的各种字重显示，主要出现在微信的“微信”界面、朋友圈正文，QQ的“消息”界面，黄页、知乎大部分等地方（包括加粗的标题和常规字重的正文）。

*   Roboto-Regular.ttf
    思源黑体（英文、数字、符号），Android默认的英文、数字、符号字体，常规字重，在微信的“微信”界面、朋友圈正文，黄页、知乎大部分等地方显示。
    注意1：这个字体默认不包含汉字字符，但是字体显示优先级很高。当系统在Roboto-Regular.ttf中找不到汉字字符时，会去NotoSansCJK-Regular.ttc中查找并显示汉字，因此如果Roboto-Regular.ttf被替换成包含汉字的字体，系统会直接显示Roboto-Regular.ttf中的汉字。这个特性我们在替换字体的时候要特别注意。
    注意2：当Roboto-Regular.ttf被替换成包含汉字的字体时，系统会直接显示Roboto-Regular.ttf中的汉字，同时，这会造成其它Roboto字体也从自身检索汉字，而不是转向NotoSansCJK-Regular.ttc，如果其它Roboto字体没有被替换成包含汉字的字体，则会因为找不到对应的汉字而显示为口口。这就是为什么很多人在替换了Roboto-Regular.ttf后，微信有些界面的汉字反而变成了口口。

*   Roboto-Bold.ttf
    思源黑体（英文、数字、符号）的加粗体，在QQ“消息”界面、知乎的加粗标题、微信朋友圈自己头像旁的名字文字等处显示。
    注意1：这个字体和Roboto-Regular.ttf一样，不包含汉字，因此在系统找不到汉字时，会去NotoSansCJK-Regular.ttc中查找并显示加粗的汉字。
    注意2：当Roboto-Regular.ttf包含汉字时，无论Roboto-Bold.ttf是否包含汉字，系统都会在Roboto-Bold.ttf中检索汉字，如果找不到汉字，则显示为口口。
    注意3：若删除Roboto-Bold.ttf，系统会转向Roboto-Medium.ttf查询汉字并加粗显示，若Roboto-Medium.ttf不包含汉字，则继续显示口口，若Roboto-Medium.ttf包含汉字，则显示Roboto-Medium.ttf中的汉字并加粗。
    注意4：若系统中存在Bold，系统会直接显示该字体，并认为它是粗体，不会额外加粗。因此不建议用常规字体替换Bold，替换后粗体依然显示常规字重，相当于没有粗体。当Bold不存在时，系统会找其它字体显示并额外加粗。所以推荐删除。

*   Roboto-Medium.ttf
    Roboto的另一个字重，介于regular和bold之间，出现在微信左上角标题、人名、群名文字处。当Roboto-Bold.ttf被删除时，会替代Roboto-Bold.ttf的位置。
    注意1：这个字体和Roboto-Regular.ttf一样，不包含汉字，因此在系统找不到汉字时，会去NotoSansCJK-Regular.ttc中查找并显示加粗的汉字。
    注意2：当Roboto-Regular.ttf包含汉字时，无论Roboto-Medium.ttf是否包含汉字，系统都会在Roboto-Medium.ttf中检索汉字，如果找不到汉字，则显示为口口。
    注意3：若删除Roboto-Medium.ttf，系统会转向另个字重的Rotobo（猜测是Roboto-MediumItalic.ttf，这里本人没有继续深入测试）,由于转向的这个字重没有汉字，所以显示为口口。因此不建议删除。

***

## 设备休眠

[android设备休眠](http://www.cnblogs.com/kobe8/p/3819305.html)

```txt
如果一开始就对Android手机的硬件架构有一定的了解，设计出的应用程序通常不会成为待机电池杀手，而要设计出正确的通信机制与通信协议也并不困难。但如果不去了解而盲目设计，可就没准了。

首先Android手机有两个处理器，一个叫Application Processor（AP），一个叫Baseband Processor（BP）。AP是ARM架构的处理器，用于运行Linux+Android系统；BP用于运行实时操作系统（RTOS），通讯协议栈运行于BP的RTOS之上。非通话时间，BP的能耗基本上在5mA左右，而AP只要处于非休眠状态，能耗至少在50mA以上，执行图形运算时会更高。另外LCD工作时功耗在100mA左右，WIFI也在100mA左右。一般手机待机时，AP、LCD、WIFI均进入休眠状态，这时Android中应用程序的代码也会停止执行。

Android为了确保应用程序中关键代码的正确执行，提供了Wake Lock的API，使得应用程序有权限通过代码阻止AP进入休眠状态。但如果不领会Android设计者的意图而滥用Wake Lock API，为了自身程序在后台的正常工作而长时间阻止AP进入休眠状态，就会成为待机电池杀手。比如前段时间的某应用，比如现在仍然干着这事的某应用。

首先，完全没必要担心AP休眠会导致收不到消息推送。通讯协议栈运行于BP，一旦收到数据包，BP会将AP唤醒，唤醒的时间足够AP执行代码完成对收到的数据包的处理过程。其它的如Connectivity事件触发时AP同样会被唤醒。那么唯一的问题就是程序如何执行向服务器发送心跳包的逻辑。你显然不能靠AP来做心跳计时。Android提供的Alarm Manager就是来解决这个问题的。Alarm应该是BP计时（或其它某个带石英钟的芯片，不太确定，但绝对不是AP），触发时唤醒AP执行程序代码。那么Wake Lock API有啥用呢？比如心跳包从请求到应答，比如断线重连重新登陆这些关键逻辑的执行过程，就需要Wake Lock来保护。而一旦一个关键逻辑执行成功，就应该立即释放掉Wake Lock了。两次心跳请求间隔5到10分钟，基本不会怎么耗电。除非网络不稳定，频繁断线重连，那种情况办法不多。

网上有说使用AlarmManager，因为AlarmManager 是Android 系统封装的用于管理 RTC 的模块，RTC (Real Time Clock) 是一个独立的硬件时钟，可以在 CPU 休眠时正常运行，在预设的时间到达时，通过中断唤醒 CPU。
```


***





## R.java 和 Resource.arsc

* `R.java`是一个资源索引文件，可以通过`R.`的方式应用资源的id。

* `Resources.arsc`是一个资源索引表，在运行时通过id找到具体对应的资源文件。

`AssetManager`在初始化时将`Resources.arsc`加载进了内存，应用运行时通过将资源id传给Resources类，Resources将id传给`AssetManager`,然后调用jni中的android_util_AssetManager.cpp文件，在资源索引表查找文件的路径，从而加载对应的资源。

