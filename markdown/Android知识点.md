# Android知识点

Tags : zazen android

---

[TOC]

---

## 字体

> 摘自http://www.miui.com/thread-8343134-1-1.html

- NotoSansCJK-Regular.ttc
思源黑体，Android7.0默认的中文字体，负责中文的各种字重显示，主要出现在微信的“微信”界面、朋友圈正文，QQ的“消息”界面，黄页、知乎大部分等地方（包括加粗的标题和常规字重的正文）。

- Roboto-Regular.ttf
思源黑体（英文、数字、符号），Android默认的英文、数字、符号字体，常规字重，在微信的“微信”界面、朋友圈正文，黄页、知乎大部分等地方显示。
注意1：这个字体默认不包含汉字字符，但是字体显示优先级很高。当系统在Roboto-Regular.ttf中找不到汉字字符时，会去NotoSansCJK-Regular.ttc中查找并显示汉字，因此如果Roboto-Regular.ttf被替换成包含汉字的字体，系统会直接显示Roboto-Regular.ttf中的汉字。这个特性我们在替换字体的时候要特别注意。
注意2：当Roboto-Regular.ttf被替换成包含汉字的字体时，系统会直接显示Roboto-Regular.ttf中的汉字，同时，这会造成其它Roboto字体也从自身检索汉字，而不是转向NotoSansCJK-Regular.ttc，如果其它Roboto字体没有被替换成包含汉字的字体，则会因为找不到对应的汉字而显示为口口。这就是为什么很多人在替换了Roboto-Regular.ttf后，微信有些界面的汉字反而变成了口口。

- Roboto-Bold.ttf
思源黑体（英文、数字、符号）的加粗体，在QQ“消息”界面、知乎的加粗标题、微信朋友圈自己头像旁的名字文字等处显示。
注意1：这个字体和Roboto-Regular.ttf一样，不包含汉字，因此在系统找不到汉字时，会去NotoSansCJK-Regular.ttc中查找并显示加粗的汉字。
注意2：当Roboto-Regular.ttf包含汉字时，无论Roboto-Bold.ttf是否包含汉字，系统都会在Roboto-Bold.ttf中检索汉字，如果找不到汉字，则显示为口口。
注意3：若删除Roboto-Bold.ttf，系统会转向Roboto-Medium.ttf查询汉字并加粗显示，若Roboto-Medium.ttf不包含汉字，则继续显示口口，若Roboto-Medium.ttf包含汉字，则显示Roboto-Medium.ttf中的汉字并加粗。
注意4：若系统中存在Bold，系统会直接显示该字体，并认为它是粗体，不会额外加粗。因此不建议用常规字体替换Bold，替换后粗体依然显示常规字重，相当于没有粗体。当Bold不存在时，系统会找其它字体显示并额外加粗。所以推荐删除。

- Roboto-Medium.ttf
Roboto的另一个字重，介于regular和bold之间，出现在微信左上角标题、人名、群名文字处。当Roboto-Bold.ttf被删除时，会替代Roboto-Bold.ttf的位置。
注意1：这个字体和Roboto-Regular.ttf一样，不包含汉字，因此在系统找不到汉字时，会去NotoSansCJK-Regular.ttc中查找并显示加粗的汉字。
注意2：当Roboto-Regular.ttf包含汉字时，无论Roboto-Medium.ttf是否包含汉字，系统都会在Roboto-Medium.ttf中检索汉字，如果找不到汉字，则显示为口口。
注意3：若删除Roboto-Medium.ttf，系统会转向另个字重的Rotobo（猜测是Roboto-MediumItalic.ttf，这里本人没有继续深入测试）,由于转向的这个字重没有汉字，所以显示为口口。因此不建议删除。

------


## 基础篇

### [生命周期][lifecycle]

### 强,软,弱,虚引用

- StrongReference(强引用)
```
如果一个对象是强引用, 即使OOM也不会被回收
当没有任何对象指向它时 会被GC回收
```

- SoftReference(软引用)
```
若一个对象仅具有软引用, 则当内存不足时会被gc回收
用于内存敏感的高速缓存
```

- WeakReference(弱引用)
```
则当gc扫描时发现只具有弱引用的对象, 则会被回收
```

- PhantomReference(虚引用)
```
若一个对象仅具有虚引用,则在任何时候都可能被垃圾回收器回收
```

### 屏幕方向

1. 参数：
```
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

2. 设置屏幕方向
```
setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED)
```

### 休眠

[原文链接][android设备休眠]
```
如果一开始就对Android手机的硬件架构有一定的了解，设计出的应用程序通常不会成为待机电池杀手，而要设计出正确的通信机制与通信协议也并不困难。但如果不去了解而盲目设计，可就没准了。

首先Android手机有两个处理器，一个叫Application Processor（AP），一个叫Baseband Processor（BP）。AP是ARM架构的处理器，用于运行Linux+Android系统；BP用于运行实时操作系统（RTOS），通讯协议栈运行于BP的RTOS之上。非通话时间，BP的能耗基本上在5mA左右，而AP只要处于非休眠状态，能耗至少在50mA以上，执行图形运算时会更高。另外LCD工作时功耗在100mA左右，WIFI也在100mA左右。一般手机待机时，AP、LCD、WIFI均进入休眠状态，这时Android中应用程序的代码也会停止执行。

Android为了确保应用程序中关键代码的正确执行，提供了Wake Lock的API，使得应用程序有权限通过代码阻止AP进入休眠状态。但如果不领会Android设计者的意图而滥用Wake Lock API，为了自身程序在后台的正常工作而长时间阻止AP进入休眠状态，就会成为待机电池杀手。比如前段时间的某应用，比如现在仍然干着这事的某应用。

首先，完全没必要担心AP休眠会导致收不到消息推送。通讯协议栈运行于BP，一旦收到数据包，BP会将AP唤醒，唤醒的时间足够AP执行代码完成对收到的数据包的处理过程。其它的如Connectivity事件触发时AP同样会被唤醒。那么唯一的问题就是程序如何执行向服务器发送心跳包的逻辑。你显然不能靠AP来做心跳计时。Android提供的Alarm Manager就是来解决这个问题的。Alarm应该是BP计时（或其它某个带石英钟的芯片，不太确定，但绝对不是AP），触发时唤醒AP执行程序代码。那么Wake Lock API有啥用呢？比如心跳包从请求到应答，比如断线重连重新登陆这些关键逻辑的执行过程，就需要Wake Lock来保护。而一旦一个关键逻辑执行成功，就应该立即释放掉Wake Lock了。两次心跳请求间隔5到10分钟，基本不会怎么耗电。除非网络不稳定，频繁断线重连，那种情况办法不多。

网上有说使用AlarmManager，因为AlarmManager 是Android 系统封装的用于管理 RTC 的模块，RTC (Real Time Clock) 是一个独立的硬件时钟，可以在 CPU 休眠时正常运行，在预设的时间到达时，通过中断唤醒 CPU。
```

## View篇

### 1. View.post()


------

### MeasureSpecMode

```
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

------

### 2. BottomNavigationBar(导航栏)

#### 2.1. 依赖
```
compile 'com.ashokvarma.android:bottom-navigation-bar:1.4.1'
```

#### 2.2. Mode

|类型 |说明|
|:--- |:--- |
|MODE_DEFAUL|Item <=3 就会使用MODE_FIXED模式，否则使用MODE_SHIFTING模式|
|MODE_FIXED|固定大小;<br/>未选中的Item会显示文字，没有切换动画;<br/>宽度=总宽度/action个数;<br/>最大宽度: 168dp;<br/>最小宽度: 80dp;<br/>Padding：6dp（8dp）、10dp、12dp;<br/>字体大小：12sp、14sp|
|MODE_SHIFTING|不固定大小;<br/>有切换动画;<br/>选中的会显示文字,未选中的Item不会显示文字|

#### 2.3. Background Style

- 修改背景色
```
bottomNavigationBar.setMode(BottomNavigationBar.MODE_FIXED);
bottomNavigationBar.setBackgroundStyle(BottomNavigationBar.BACKGROUND_STYLE_STATIC);
bottomNavigationBar.setBarBackgroundColor(R.color.black);
```

- BACKGROUND_STYLE_DEFAULT
```
MODE_FIXED : BACKGROUND_STYLE_STATIC
MODE_SHIFTING : BACKGROUND_STYLE_RIPPLE
```

- BACKGROUND_STYLE_STATIC
```
- 点击的时候没有水波纹效果
- 背景色默认是白色 : setBarBackgroundColor() 修改背景色
```

- BACKGROUND_STYLE_RIPPLE
```
- 点击的时候有水波纹效果
- 背景色 : setActiveColorResource()
```

#### 2.4. Badge

``` 
一般用作消息提醒
BottomNavigationItem 添加 Badge
```

------

### 3. RecyclerView

#### 3.1. LayoutManager
```
- GridLayoutManager ： 表格布局
- LinearLayoutManager ： 线性布局
```

#### 3.2. ItemDecoration(装饰)

可以装饰RecyclerView的子item(绘制分割线), 当然功能不止这些后续学习补充。
主要方法有以下三个(总共6个废弃3个):

- getItemOffsets(Rect outRect, View view, RecyclerView parent, State state) 
```
设置边距
- outRect : 设置padding, 可以理解为Item包含在这个矩形中。
- view  : itemView。
- parent : RecyclerView。
- state : RecyclerView的状态，但并不包含滑动状态

```
- onDraw(Canvas c, RecyclerView parent, State state) 
```

```
- onDrawOver(Canvas c, RecyclerView parent, State state)
```
遮罩
```

### 4. SwipeRefreshLayout(刷新)

- setRefreshing(boolean)
```
true  : 显示刷新UI
false : 关闭刷新UI

```

- setOnRefreshListener(..)
```
刷新监听事件
```








------
作者 : [口戛口崩月危.Z][author]

[author]: https://zaze359.github.io
[lifecycle]:https://www.cnblogs.com/mukekeheart/p/5662747.html
[android设备休眠]:http://www.cnblogs.com/kobe8/p/3819305.html