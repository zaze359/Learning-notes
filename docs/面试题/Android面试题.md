# Android面试题

## 基础问题

### SharedPreference

* 如何支持跨进程?

### 四大组件

* Activity：活动，存放UI的容器。
* Service：服务
* BroadcastReceiver：广播接收器
* ContentProvider：内容提供者，共享数据。



### Activity 间跳转时的生命周期变化？

#### A Activity打开B Activity

对于 A ：

* 若B是全屏 ： `A.onResume` -> `A.onPause()` -> `A.onStop()`；
* 若B 非全屏： `A.onResume` -> `A.onPause()`；

对于B：`onCreate()` -> `onStart()` -> `onResume()`。

#### B 返回 A

对于B：`B.onPause()` -> `B.onStop()` -> `B.onDestory()`。

对于A：

* 若B是全屏 ：`A.onResart` -> `A.onResume()`；
* 若B 非全屏：`A.onResume()`；

### Fragment

相关问题：

* 你在 Fragment 之间传递数据的时候是怎么做的？为什么不用一个全局的静态变量呢？



## 启动流程

相关问题：

* Activity所在进程是怎么启动的？

  主要是调用`startActivity()` 后会通过ATMS了向zygote发起socket请求来启动应用。

* 讲一下Activity启动流程中与AMS的交互过程。

* 是否了解Activity的onCreate和onAttach的执行顺序？

参考资料：

* [Android应用启动流程](../android/system/Android应用启动流程.md)
* [Android系统启动流程](../android/system/Android系统启动流程.md)



## 框架相关

### 1. MVC、MVP、MVVM、MVI

相关问题：

* 谈谈对MVC、MVP、MVVM、MVI的理解？
* 它们各自的优缺点是什么？
* 它们内部的依赖关系是怎么样的？
* 各个层在 Android 开发中的对应关系？

参考资料：

[Android客户端框架](../android/Android客户端框架.md)



---

## JetPack

### 1. ViewModel

相关问题：

- ViewModel 的作用是什么？
- ViewModel 是如何保持数据的呢？
- ViewModel 是怎么做到在 Activity 销毁重建新实例之后还能保持不变的呢？

参考资料：

* [ViewModel](../android/jetpack/ViewModel.md)

* [Android界面状态保存和恢复](../android/Android界面状态保存和恢复.md)





## 屏幕刷新机制

### Android中说的每16ms刷新屏幕是什么？

[Android图形架构](../android/view/Android的图形架构.md)

* 是指设备屏幕会以固定每16ms一次的频率从Buffer中获取帧数据进行画面更新。
* 屏幕刷新时发送一个VSync信号，通知系统屏幕进行刷新，而Android应用接收到vsync后会开始绘制下一帧的数据。



### 静止页面，会持续收到vsync信号并刷新吗？

只有发起绘制请求时才会收到vsync 并触发刷新。

* vsync信号是由屏幕发送的，**屏幕会一直刷新**只不过显示的画面是同一帧的而已。

* **App界面静止（没有动画，没有用户操作）时，就不会发起vsync请求，所以也就不会接收到vsync信号，CPU也不会计算下一帧数据，View的绘制流程 onMeasure、onDraw、onLayout 也不会执行**。
  * View的绘制流程是在 `ViewRootImpl.scheduleTraversals()` 中通过 向Choreograhper添加 `CALLBACK_TRAVERSAL` 任务触发的，此时Choreograhper会调用JNI函数 进入native层，native层会生成一个VsyncRequest.Single请求，并唤醒线程，获取vsync信息并返回给应用层，这个过程是一次性的，所以Choreograhper 只会接收到一次vsync回调，Choreograhper 收到vsync回调后就会执行绘制流程，同样这个`CALLBACK_TRAVERSAL`也是一次性，执行完就从队列中移除了它。

---

### 谈谈垂直同步和三重缓冲

[Android图形架构](../android/Android图形架构.md)

三重缓冲和垂直同步是Android4.1的黄油计划中引入的，有效的改善了画面撕裂，同时不造成很大的画面延迟。

其中垂直同步主要是为了解决画面撕裂的问题，但是同时带来了帧率降低和延迟的问题。Android4.1之后也用于协调UI绘制，处理掉帧现象, VSync信号到来时开始处理下一帧数据。

* **帧数下降**：GPU性能再高也会被同步成屏幕刷新率。若GPU性能低需要1.5个周期时间完成，由于要等待垂直同步将被拉长为2个周期才输出，本就不高的帧数将进一步降低。
* **延迟**：开启垂直同步期间，GPU已准备好数据后将不再工作，即使周期内剩余的时间够再处理一帧数据，也将等待VSYNC后才准备下一帧。但我们的操作是连续的，所以产生了延迟。

三重缓冲是人主要是为了优化掉帧的问题。在Android4.1之前，Android使用的是双缓冲技术，那时VSYNC并不会协调UI绘制，仅用于最后的缓冲区交换防止画面撕裂。

那时CPU何时处理UI绘制的时间是不确定的。可能CPU/GPU仅需要5ms就能处理完的帧数据，却因为是在VSYNC周期末尾执行导致要到下一个周期才能处理完，产生掉帧。Android4.1之后引入VSYNC用于协调UI绘制，处理这种高帧率下依然出现掉帧的情况。不过如果仅仅引入VSYNC协调UI绘制，在低帧率的场景下依然存在严重的掉帧现象，即当CPU + GPU处理时间大于一帧时，需要多等一个周期屏幕才显示，且期间CPU/GPU空闲，为了优化这种低帧率下的场景。引入了三重缓冲，使得VSYNC到来时即使GPU仍在处理，CPU也不会去GPU不再争抢同一个Buffer，而是使用新增Buffer去处理数据。

### 丢帧是说 这一帧延迟显示 还是 丢弃不再显示 ？

丢帧（掉帧）并没有丢弃不再显示只是延迟显示。丢弃不再显示是叫跳帧。



---

## View相关

### View的事件传递机制主要涉及哪些回调？

主要涉及三个函数：

* `dispatchTouchEvent()`：这个函数整个是否分发的核心，后续的 onInterceptTouchEvent() 和 onTouchEvent() 都是在这里调用。
* `onInterceptTouchEvent()` ：这里处理ViewGroup 事件拦截逻辑。需要拦截 返回true，这样就不会分发给子View。
  * 需要注意的是，若拦截了ACTION_DOWN的话，后续所有事件就没法传递给子View了。
* `onTouchEvent() `：负责处理事件。返回 true表示消费这个事件，这样事件就不会再向上传递。
* `requestDisallowInterceptTouchEvent(true)`：这个函数的作用是由子类来控制父类的事件分发。在 调用 `onInterceptTouchEvent()` 之前会判断 FLAG_DISALLOW_INTERCEPT这个标识，不过这个对于ACTION_DOWN事件是无效的。



### View的三种测量模式及使用场景

* **EXACTLY**：父容器计算出了子View的精确大小，子View的大小就是给定的SpecSize。对应布局文件中设置 `math_parent` 或者 固定值(10dp) 。
* **AT_MOST**：父容器给定一个 大小，子View不能超过这个大小。对应布局文件中的`wrap_content`。
* **UNSPECIFIED**：父容器没有给定限制，子View多大都可以。用于这种子布局超出父容器的场景。

### View的渲染流程 需要经过哪几个步骤呢？

主要涉及三个流程：measure测量、layout布局、draw绘制。

这个三个过程分别对应三个函数：

* onMeasure()：自定义控件 处理测量逻辑时 需要重写这个函数。
* onLayout()：自定义控件处理子元素布局时需要重写这个函数。
* onDraw()：自定义View 想要实现特定的图形效果时 需要重写这个函数。



### View和ViewGroup的draw()流程

两者整体流程相同：

1. **绘制背景**：`drawBackground(canvas)`。
2. （可选）保存图层。
3. **绘制View自身内容**：` onDraw(canvas)`。
4. **绘制 子元素**：`dispatchDraw(canvas)`。在View中是个空实现，若是ViewGroup 则会重写这个函数
5. （可选）绘制渐变效果并恢复保存的图层。
6. **绘制装饰（foreground、scrollbars）**：`onDrawForeground()`。
7. （可选）绘制高亮

**两者区别：**

* ViewGroup重写了 `dispatchDraw()`，在内部会先将对child根据 Z值从大到小进行排序，最后 遍历排序后的列表，一次绘制子元素。

### ViewGroup 中的 onDraw 是否每次都会执行？

**ViewGroup的 onDraw() 不一定每次都执行**。

ViewGroup 默认不会执行绘制， 它在 `initViewGroup()` 流程中会设置 WILL_NOT_DRAW，如果没有背景图就会设置 PFLAG_SKIP_DRAW，从而直接调用dispatchDraw() 绘制子View，不调用自身的draw()。所以 onDraw() 也就不会被调用。

如何清除 PFLAG_SKIP_DRAW？

1.  `setWillNotDraw(false)` ：可以强制开启自身的绘制。
2. 设置背景/前景：添加背景/前景 时这个标记会被清除。

### 如何修改ViewGroup绘制子View的顺序

ViewGroup 中的 mPreSortedChildren 会保持排序后的子元素，默认是按照z 值 从大到小进行排序。Z值相同时默认按照child的添加顺序来排序。

我们想要修改绘制顺序时可以通过两个方式：

* **调整 View的Z 值**：使用`setZ() `、`setElevation()`、`etTranslationZ()` 这三个函数都可以做到。
* **开启 customOrder**：调用 `setChildrenDrawingOrderEnabled(true)` 可以开启 customOrder，然后通过重写  `getChildDrawingOrder()` 的返回值来决定child的绘制顺序。



### 实现view的更新方法有哪几种？

* requestLayout()
* invalidate()：这个函数必须在UI线程中调用。
* postInvalidate()：支持在非UI线程中调用。

#### invalidate() 和 postInvalidate() 的区别

* invalidate()：这个函数必须在UI线程中调用。
* postInvalidate()：支持在非UI线程中调用。

postInvalidate() 其实就是通过 mHandler发送了一个了消息，从而转到了UI线程调用 invalidate()

#### invalidate() 和requestLayout() 的区别

* invalidate()：适用于布局不变，刷新内容的场景。会导致 `View.onDraw()` 被调用。
* requestLayout()：适用于需要当前布局发生变化 需要重新测量的场景。会导致View的 `onMeasure()`、`onLayout()`被调用，但是`onDraw()` 可能不会调用，只有当布局发生变化时才会调用，所以若是一定要重绘内容，最好手动调用一下 `invalidate()`。

### View渲染流程的触发时机

1. 在Activity 创建流程中的 `handleResumeActivity()`  时期会创建 ViewRootImpl，并开始通过`ViewRootImpl.requestLayout()` 开始执行渲染流程。
2. 直接调用 `requestLayout()` 和 `invalidate()` 来触发。
3. 调用 `view.setForeground()` 、`view.setBackgroundDrawable()` 会触发 `requestLayout()` 和 `invalidate()` 。
4. View的布局属性发生变化：修改 LayoutParams，会触发 `requestLayout()` 。

### 如何正确的获取View的宽高

1. **`View.post()`**：通过这个函数投递的消息会在View 初始化完毕并关联到window后执行。
2. **`onWindowFocusChanged()` **：此时View已经初始化完毕，我可以在获取到焦点时去获取View到宽高。不过这个函数调用非常频繁，Activity的Window每次获取/失去焦点都会被调用。
3. **ViewTreeObserver**：可以添加一个 `addOnGlobalLayoutListener()`，当View树的状态发生改变或者View树内部的View的可见性发现改变时，会回调给我们，我可以在回调中去获取view的宽高。



### 有听说过“过度绘制”吗？

过度绘制（Overdraw） 就是值存在像素区域在同一帧时间内被多次绘制。主要就是重叠布局引起的。

具体的场景比如：多层次叠加的UI，上下两层都设置了背景，不过下层被上层挡住，但是下层不可见的部分还是执行绘制操作，这样就会导致这部分区域发生多次绘制，此时就是过度绘制。

* 重叠的View、重叠的背景。
  * 布局层级优化。
  * 去除window的默认背景。
  * 使用ViewStub
* 自定义View 在 `onDraw()` 中对同一区域的执行了多次绘制。
  * 使用 `canvas.clipRect()` 指定绘制的区域。

### 如何实现 圆形头像？

* **使用 `canvas.clipPath()` 裁剪图像**。不过会有毛边，因为是裁剪的画布，没有抗锯齿

  * 首先生成一个圆形的path。

  * 根据path裁剪 canvas。

  * 最后将图像绘制到 Canvas上。


  ```kotlin
  private val circlePath = Path()
  fun innerRound(bitmap: Bitmap): Bitmap {
      val paint = Paint(Paint.ANTI_ALIAS_FLAG)
      val radius = bitmap.width / 2F
      val cy = bitmap.height / 2F
      val cx = bitmap.width / 2F
      circlePath.reset()
      // 构建一个内切圆的path
      circlePath.addCircle(cx, cy, radius, Path.Direction.CW)
      val bm = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
      val canvas = Canvas(bm)
      // 裁剪一个圆形范围
      canvas.clipPath(circlePath)
      paint.reset()
      // 绘制上去
      canvas.drawBitmap(bitmap, 0F, 0F, paint)
      return bm
  }
  ```

* **设置图像合成模式：PorterDuffXfermode**

  * 首先创建一个bitmap然后绘制一个圆。

  * 通过xfermode 将 圆形bmp和 图片bmp 混合得到 圆形图像。


  ```kotlin
  private fun innerRound(bitmap: Bitmap): Bitmap {
      // 前面同上，绘制图像分别需要bitmap，canvas，paint对象
      val paint = Paint(Paint.ANTI_ALIAS_FLAG)
      val radius = bitmap.width / 2F
      val cy = bitmap.height / 2F
      val cx = bitmap.width / 2F
      
      val bm = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
      ZLog.i(ZTag.TAG, "toRoundBitmap bm : ${bm.width}, ${bm.height} ->${radius * 2} ")
      val canvas = Canvas(bm)
      canvas.drawCircle(cx, cy, radius, paint)
      paint.reset()
      // 设置图像合成模式，该模式为只在源图像和目标图像相交的地方绘制源图像
      paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
      canvas.drawBitmap(bitmap, 0F, 0F, paint)
      return bm
  }
  ```

* **使用 BitmapShader 图像渲染器 绘制**，可以在绘制某一图像的时候，把另一图像同时渲染上去。

  * 将图像bmp 赋值给paint.shader 作为渲染器，这样画笔刷出来的就是这个图像。
  * 利用这个画笔在 canvas上直接画圆即可。

  ```kotlin
  fun innerRound2(bitmap: Bitmap): Bitmap {
      val paint = Paint(Paint.ANTI_ALIAS_FLAG)
      paint.reset()
      // 添加渲染器。相当于用 bitmap当笔刷
      paint.shader  = BitmapShader(
          bitmap, Shader.TileMode.CLAMP,
          Shader.TileMode.CLAMP
      )
      val bm = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
      val canvas = Canvas(bm)
      val radius = bitmap.width / 2F
      val cy = bitmap.height / 2F
      val cx = bitmap.width / 2F
      // 使用这个bitmap 来绘制圆形
      canvas.drawCircle(cx, cy, radius, paint)
      return bm
  }
  ```





---

### ScrollView

#### ScrollView在子View测量使用那种模式？

ScrollView 重写了 `measureChildWithMargins()` ，在测量 childView的高度时使用了UNSPECIFIED。

#### ScrollView 的onMeasure()

* fillViewport 是 false时：此时ScrollView 不会执行测量。是指 childView 无法填充满 ScrollView的情况。
* MesaureSpec = UNSPECIFIED时：此时也不测量。这种情况是子View 大于了 ScrollView。
* 
* 执行测量：这时仅会测量 第一个 childView。

```java
protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
    // 首先执行正常的 FrameLayout测量流程，即所有的 childView都会测量一遍。
    super.onMeasure(widthMeasureSpec, heightMeasureSpec);

    // fillViewport == false，不再继续
    if (!mFillViewport) {
        return;
    }
	// MesaureSpec == UNSPECIFIED，不再继续
    final int heightMode = MeasureSpec.getMode(heightMeasureSpec);
    if (heightMode == MeasureSpec.UNSPECIFIED) {
        return;
    }

    if (getChildCount() > 0) {
        // 获取第一个child，尝试测量
        final View child = getChildAt(0);
        final int widthPadding;
        final int heightPadding;
        final int targetSdkVersion = getContext().getApplicationInfo().targetSdkVersion;
        final FrameLayout.LayoutParams lp = (LayoutParams) child.getLayoutParams();
        if (targetSdkVersion >= VERSION_CODES.M) {
            widthPadding = mPaddingLeft + mPaddingRight + lp.leftMargin + lp.rightMargin;
            heightPadding = mPaddingTop + mPaddingBottom + lp.topMargin + lp.bottomMargin;
        } else {
            widthPadding = mPaddingLeft + mPaddingRight;
            heightPadding = mPaddingTop + mPaddingBottom;
        }

        // desiredHeight 是测量了所有 childView得到的。
        final int desiredHeight = getMeasuredHeight() - heightPadding;
        
        if (child.getMeasuredHeight() < desiredHeight) {
            // 子View的高度小于需求的高度。
            final int childWidthMeasureSpec = getChildMeasureSpec(
                widthMeasureSpec, widthPadding, lp.width);
            // 此时使用 传入了desiredHeight 并使用 MeasureSpec.EXACTLY 重新测量一遍child高度。
            final int childHeightMeasureSpec = MeasureSpec.makeMeasureSpec(
                desiredHeight, MeasureSpec.EXACTLY);
            child.measure(childWidthMeasureSpec, childHeightMeasureSpec);
        }
    }
}
```



### LayoutInflater

#### root、attachToRoot参数的作用？

root 会影响 创建的布局最外层的LayoutParams：

* root == null：被创建View的**最外层的LayoutParams将失效**，设置的宽高并不会生效，变为 wrap_content。
* root != null：被创建View的**最外层的LayoutParams生效**。

attachToRoot 表示是否和root关联：

* attachToRoot  == true：**被创建View会作为 root的子布局**，且`inflater()`**返回给我们的是root**。
* attachToRoot == false：被创建的View不会和root关联，`inflater()`返回给我们的就是创建的View。
  * root为空时 attachToRoot这个属性就没什么用了，`inflater()`返回的也是创建的View。

#### setFactory和setFactory2有什么区别？

它们都是供开发者来设置自定义加载布局的接口。

Factory2 继承子 Factory，factory2提供的接口多了一个parent参数，LayoutInflater 在加载布局过程中，会优先使用Factory2 来加载布局，然后才使用Factrory，这两个都没有设置时 会使用 privateFactory，一般来自使用LayoutInflater创建的LayoutInflater。若都没有则会使用反射的方式构建View。

### 怎么优化xml inflate的时间？

* 使用ViewStub：它默认是不可见的，且一开始也不会被inflate，直到需要时才会被 inflate。避免一次性加载所有布局。

### LinearLayout

#### LinearLayout如何测量自己的child

| Child \ Parent | EXACTLY | AT_MOST | UNSPECIFIED |                                  |
| -------------- | ------- | ------- | ----------- | -------------------------------- |
| dp             | EXACTLY | EXACTLY | EXACTLY     | 不受父容器影响                   |
| match_parent   | EXACTLY | AT_MOST | UNSPECIFIED | 父容器是模式，子View就是什么模式 |
| wrap_content   | AT_MOST | AT_MOST | UNSPECIFIED | 一般情况下就是 AT_MOST           |

LinearLayout会在 onMeasure() 中遍历所有子View，依次进行测量，以纵向为例

正常的布局流程，没有weiget权重布局：

* 计算出当前已使用的高度空间 mTotalLength，子View占用高度，以及padding、margining等。
* 测量子View,根据不同的测量模式处理，获取到子View的宽高。会将mTotalLength传入进去，再测量时使用。
* 将子View占用的空间，更新到 mTotalLength。

子View设置了 weiget，通过权重来进行布局。

* 每一个子View的 weiget 都被会记录。
* weiget>0 && height == 0，表示高度占满空闲空间。
  * LinearLayout 的heightMode 是MeasureSpec.EXACTLY，即 match_parent，此时会先标记 skippedMeasure，最后再重新测量。
  * LinearLayout heightMode 不是MeasureSpec.EXACTLY, 此时child 会按照 WRAP_CONTENT 来进行测量。并记录占用的高度。
* weiget>0 && height !=0，表示按照权重来分配高度。
* 重新遍历一遍child，根据所占的权重，重新分配空间。

### ViewPager2中嵌套ViewPager怎么处理滑动冲突

ViewPager2 基于 RecyclerView，所以等同 RecyclerView嵌套 ViewPager、RecyclerView

处理方式：自定义一个 `NestedScrollViewHost` 类，类似Google提供的 `NestedScrollView`，将 ViewPager、RecyclerView 等作为 NestedScrollViewHost 的子元素即可。不必修改原先的控件.

NestedScrollViewHost 采用内部拦截法处理滑动冲突。

重写 `dispatchTouchEvent()` 或者 `onInterceptTouchEvent()`来处理事件分发逻辑，并结合 `requestDisallowInterceptTouchEvent()`来控制父容器。

需要事件时禁用 父容器的拦截，并将事件继续向下分发，不需要时则允许父容器拦截。

### ViewPager切换掉帧如何优化？

ViewPager结合Fragment使用时，常常会碰到滑动切换时掉帧的问题。

* 考虑优化 Fragment 中的布局，精简布局永远是最直接有效的方式。
* 在内存允许的情况下，考虑通过 `setOffScreenPageLimit()`多缓存几个页面。需要结合懒加载使用，用户可见才加载数据，否则一开始加载过多Fragment 也会发生卡顿。懒加载则可以利用 Adapter的 behavior 字段。
* **延迟加载，优化迅速切换的场景**，切换Fragment时，不立即去加载内容，而是启动延迟任务去加载，若是停留达到指定时间则表示用户想要看当前页面的内容，然后将内容加载处理。若是快速切换了页面则取消这个延迟加载任务。可以通过 `OnPageChangeListener` 来监听页面变化。
* 利用 FragmentPagerAdapter 中的 behavior  字段进行控制，例如 设置 BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT。仅当前的Fragment 会进入到 RESUME 生命周期，其他的 Fragment 会被限制在 START。



### TextView



### WebView

WebView性能优化有哪些？

* 硬件加速：

---

## Drawable

### Drawable有哪些子类？

BitmapDrawable、ShapeDrawable、LayerListDrawable、StateListDrawable、ScaleDrawable、ClipDrawable、TransitionDrawable、LevelListDrawable等。

### Drawable中 level 的作用？

Drawable `drawable.setLevel()` 来修改等级，level 主要是起到一个控制的作用，在不同的drawable中存在不同效果：

* LevelListDrawable：通过修改level 切换到对应等级的Drawable，和Log中的Level 类似。
* ScaleDrawable：level 起到的是控制缩放的作用。0 不可见；10000 不缩放；其他：越小越接近配置的缩放比例，越大缩放越不明显。
* ClipDrawable：level 控制 裁剪比例。0 完全裁剪，不可见；10000 不裁剪；其他：越小裁剪的越多，越大裁剪越少。



### Drawable、View、Bitmap有什么区别？

* **Bitmap**：表示一个图像，它对应图像的像素数据存储的内存空间。

* **Drawable**：表示一个支持绘制的组件工具类，并不是一个UI控件，也不可以交互，仅仅是支持Canvas绘制。一般作为ImageView的图像 或者 View的背景使用。

* **View**：是一个UI控件，表示一块屏幕上的区域，不仅可以绘制还可以接收处理交互事件。

#### Drawable绘制与View绘制有什么区别？

* Drawable 仅仅是支持绘制，一般需要外部提供Bounds，并没有布局、测量等功能。所以和View 绘制流程上的主要区别就是 View还会进行测量和布局这两个流程。
* Drawable 专注于绘制，相比 View功能更加独立单一，便于复用。一般也是 View组合使用的。



### 不同的`getDrawable()` 方法的区别？

* `context.getResource().getDrawable()`：最终调用的是 `ResourceImpl.loadDrawable()`，这里涉及到 Drawable的缓存机制，会从 DrawableCache 中复用已存在 ConstantState 然后 生成新Drawable实例。
* `ImageView.getDrawable()`：这个函数返回的是成员变量 `mDrawable`，它是在 `setImageDrawable()`、`setImageBitmap()` 时赋值的。

### Drawable的缓存机制

Drawable的缓存机制缓存的是Drawable的状态（ConstantState），加载同一个资源生成Drawable对象时，都是基于同一个State实例创建的。

* ColorDrawable和非ColorDrawable的是分开管理的，不过机制还是相同的。

### Drawable.mutate()的作用

由于Drawable缓存机制，同一个资源创建的Drawable共享同一个状态，但是也导致了一些问题，那就是修改Drawable的状态时，那么后续创建的同资源的Drawable实例也会受到影响。而 `mutate()` 的作用就是使当前的Drawable重新创建一个State对象，这样修改当前Drawable对象时，就不会影响到其他实例。

---

## Android动画

### 动画有哪些分类？

* **补间动画（View Animation）**：通过**图像不断进行变换**（平移、缩放、旋转等）方式来实现动画效果。此时 `onDraw()` 会不断被调用，比较耗费GPU资源。不过改变只是View的显示内容，View的位置并没有发生变化。
* **逐帧动画（Drawable Animation）**：**依次播放一组图像**从而形成动画效果。往往会占用大量内存。
* **属性动画（Property Animation）**：通过不断的**改变控件的属性**从而实现动画效果。View的属性是真实发生了改变的。

### Drawable动画与View动画的区别?

Drawable 逐帧动画主要是根据一组图像依次切换的方式实现动画，会占用大量内存。

View动画则是会不断进行重绘，对GPU资源消耗比较大。

### 属性动画与补间动画的区别？哪个效率更高？

* **补间动画**（View Animation）： 实质就是通过不断重绘来实现动画。View自身的属性并没有发生变化。
  * **View的位置并没有发生变化**，点击事件还是在原来的位置，并不是动画结束后内容显示的位置。

* **属性动画**（Property Animation）：是通过调用对应属性的 `setter` 方法真正的改变了View的属性。然后再重写执行绘制流程。
  * 若是改变View的位置，它是**会真正发生改变的**。并且新的位置能够响应点击事件。

**补间动画的效率更高**。

补间动画 View自身是并没有发生变化的，只是在不断的重绘。而属性动画则首先会通过反射修改属性的值，然后再执行重绘。

### 属性动画插值器原理

插值器的作用就是根据时间流逝的百分比来计算出属性变化的百分比。反映的是动画运行的速度。

例如 将ProgressBar 进度 在 100ms 内从0 变为100，使用的是LinearInterpolater 线性插值器。

那么过去 10ms，插值器就是返回 0.1，接着这个值会返回给估值器，估值器就会根据 `0 + (100 - 0) * 0.1` 计算得到当前需要将进度变化到 10。

### 属性动画更新回调onDraw()



## Handler消息机制

### Handler是什么？有什么用?

Handler 是Android提供的一种用于线程间通讯的消息传递机制，常用于子线程和主线程进行消息传递。

### Handler.post() 与 View.post() 的 区别?

我们一般使用的 `Handler.post()` 就是向 mainLooper 直接发送消息，若是自定义了线程则是向我们自定义线程的Looper发送。

View.post() 调用的 handler 来自 ViewRootImpl 它将消息发送到 创建ViewRootImpl 线程，一般就是主线程，使用的就是mainLooper。

大致流程其实和 普通的 Handler.post() 区别不大。

**两者主要区别：**

**当这个View的 attachInfo 未赋值时，即还没有和Window关联时，会先将 runnable 保存到 HandlerActionQueue中，待后续关联后 会将这些暂存的消息都发送到对应UI线程的looper中执行，保证消息不会丢失。**

```java
public boolean post(Runnable action) {
    final AttachInfo attachInfo = mAttachInfo;
    // attachInfo 是在 resume 生命周期时RootViewImple 调用 view.dispatchAttachedToWindow() 传递给 view的。
    if (attachInfo != null) {
        return attachInfo.mHandler.post(action);
    }

    // 当还未存在 attachInfo 时会先暂存到 RunQueue中， 保证消息不丢失。
    // 后续将queue中的消息向 view创建的线程的looper 发送，一般为mainLooper。
    getRunQueue().post(action);
    return true;
}
```

> mAttachInfo 是在 ViewRootImpl 的构造函数中创建的实例，保存了一些 window、handler相关的信息。
>
> 它会在 ViewRootImpl.performTraversals() 函数中通过 `view.dispatchAttachedToWindow()` 传递给 view的。需要在生命周期到 resume 时才触发。

```java
 mAttachInfo = new View.AttachInfo(mWindowSession, mWindow, display, this, mHandler, this,
                context);
```

### Handler休眠是怎样的？

1.  当Looper被创建后，MessageQueue也会被创建，同时会MQ会调用 `nativeInit()` 创建NativeMessageQueue，同时也初始化了 Native层的Looper，这样 Java层和Native层的消息机制就初始化完毕了。
2. 启动Looper循环，在Java层调用 `Looper.loop()`，启动循环后，会调用 `MQ.next()`来获取消息，此时若没有需要处理的消息就会调用 `nativePollOnce()` 是当前线程进入休眠，直到有新的消息或者超时时才会被唤醒，这里底层使用的是epoll机制。
3. 若我们通过 Handler 发送了消息，那么这个消息最终会通过 `MQ.enqueueMessage()` 加入到消息队列中。
   * 若新加入的消息在队列头部且当前线程处于阻塞状态那么还会 通过 `nativeWake()` 唤醒 epoll。

### epoll机制的原理是什么？

epoll 是 select和poll的增强机制，是Linux下的一项多路复用技术。

* select和poll 是基于文件流IO的监听，空闲时会阻塞线程，发生IO事件时则会唤醒线程，不过响应事件采用的是轮询遍历的方式，效率比较低。
* epoll 就是为了优化 select/poll的性能问题，它仅处理发生IO的文件流，不需要进行遍历。原理是使用红黑树维护了一张事件和文件流的注册表。

在Android的Handler消息机制中使用到了 epoll机制。

1. 首先Looper会创建一个 pipe 实例，内核分配了一块缓冲区，同时返回了用于操作的pipeFd。
2. 接着创建了一个 epoll对象并且得到了一个epollFd，epollFd监听了 pipeFd的读事件，用于唤醒。
3. `messageQueue.nativePollOnce()`  会调用`Looper.pollOnce()`，内部通过 epoll_wait() 进入休眠，直到事件发送或者超时被才会被唤醒。epoll被唤醒后 会先判断fd和事件类型，符合条件后会从管道中读取数据进行处理。
4. `messageQueue.nativeWake()` 实际上就是向pipe中写入数据从而唤醒 epoll。

epoll阻塞会什么不占用CPU资源？



### IdleHandler使用过吗？

ActivityThread 中的空闲时执行gc流程就是使用的 IdleHandler。

- 主线程加载完页面之后，去加载一些二级界面;
- WebView 预加载
- 管理一些任务, 空闲时触发执行队列。

使用方式：

```java
// 实现 IdleHandler 接口
class Idler implements MessageQueue.IdleHandler {

    @Override
    public boolean queueIdle() {
        Log.d("", "IdlerIdlerIdlerIdler");
        // false：表示仅执行一次，执行后就会remove掉
        // true：表示一直存在，空闲时就会被调用。
        return false;
    }
}
private  MessageQueue.IdleHandler idler = new Idler();
// 添加 IdleHandler
Looper.myQueue().addIdleHandler(idler);
// 移除 IdleHandler
Looper.myQueue().removeIdleHandler(idler);
```



### Handler 内存泄露问题

在Activity 中使用 Handler 时，如果 Handler 作为匿名内部类使用，那么这个Hander就会持有外部类Activity的实例对象。

而真正导致泄露的原因是因为使用 Handler 发送了消息。

当我们 通过 Handler发送消息时 **Message 会持有 Handler**，Message属于Looper中的MessageQueue，而Looper存储在线程的TLS中的，所以Handler是被线程持有的，无论是主线程还是自定义线程生命周期都比Activity长，也就导致Activity发送了内存泄露。

``Activity -> Handler -> Message -> MessageQueue -> Looper -> TLS``

可以将这个Handler 定义成 静态内部类，若是需要使用外部的Activity，则应用通过弱引用的方式持有Activity。

也可以在 `onDestory()` 时将消息及时的移除来防止内存泄露。

> 注意慎用 `removeCallbacksAndMessages(null)`，它会将所有消息队列中的消息移除。仅当自定义Looper时可以考虑使用。

## 跨进程通讯

[Android进程间通信](../android/Android进程间通信.md)

### 跨进程通信了解多少？

| IPC                     |                                                              | 存在问题                                                     |
| ----------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Bundle                  | 常用于四大组件间的进程间通信。主要是通过Intent来传递Bundle数据。 | 不适用大数据的传递，                                         |
| ContentProvider         |                                                              |                                                              |
| Messenger               | 基于Handler、Service、Binder。                               | 它是**以串行的方式处理请求**，**不适用于需要处理多线程的高并发IPC通信场景**。 |
| AIDL                    | Android接口定义语言，它是基于Binder的一套封装。支持一对多的并发实时通信同时也支持RPC。适用于存在多应用访问服务，并在服务中需要多线程处理的场景。 | 实现也比较复杂。                                             |
| 文件共享                |                                                              | **存在并发读写的同步问题**                                   |
| -                       |                                                              |                                                              |
| Pipe(管道)              | 会在创建时分配一个page大小的内存。并提供两个文件描述符，一个读一个写。 | 缓存区大小比较有限，数据需要拷贝两次。                       |
| Socket(套接字)          | 一种通用接口，主要是用于不同机器或跨网络的通信。以字节流方式传输，对于读写的大小没有限制。 | 数据需要拷贝两次，传输效率低。(Android 中使用的LocalSocket 传输效率其实很高)，不支持RPC |
| Signal(信号)            | 适用于进程中断控制，比如非法内存访问，杀死某个进程等。Android中也使用了signal机制，如Kill Process时。 | 不适用于信息交换                                             |
| Semaphore(信号量)       | 常作为一种锁机制，防止某进程正在访问共享资源时，其他进程也访问该资源。 |                                                              |
| Message Queue(消息队列) |                                                              | 不合适频繁或信息量大的通信。数据需要拷贝两次。               |
| Shared Memory(共享内存) | 共享缓冲区直接附加到进程虚拟地址空间。Ashem                  | **数据无需拷贝,速度快,但是实现方式复杂。**需要考虑到访问临界资源的并发同步问题。所以各进程需要利用同步工具解决**进程间的同步问题**。 |



### AIDL 中的in out oneway代表什么意思？

* **in**：默认，表示输入参数，会将客户端的数据读取并传给服务端。服务端修改后不会影响客户端
* **out**：表示输出参数，服务端修改后可以将新数据返回给客户端。
  * 客户端发送时并不会读取数据，服务端会在binder调用的返回过程中新建一个对象并写入数据，最后通过 reply 返回给我们
* inout：同时具备in、out的特性
* **oneway**：表示这个接口异步调用，oneway修饰后的接口不可以使用 in、out，并且也不能有返回值。常用于不关心binder状态和返回的接口。
  * 由于没有返回值，所以通讯过程中不会生成 reply 局部变量。
  * 异步调用，调用oneway修饰的方法不会发生阻塞。

### zygote为什么使用socket 而不是Binder

* **LocalSocket 的传输效率很高效(略低于Binder)，使用简单**。

  LocalSocket是专用于本地进程间通信机制，相比于普通的Socket，不用经过网络协议栈所以也就不用处理相关协议的编解码，同时不受限于网络带宽。虽然需要两次拷贝，由于Binder传输存在大小限制，数据量并不多，此时两者的差距并不明显。

* **zygote是专用于 fork 其他的进程的，所以自身应当轻便简单且尽量不依赖外部**。若使用 Binder，则zygote需要先等待ServiceManger启动，然后将自身注册到ServiceManger后才能去fork其他进程。而其他服务需要和zygote通信时又需要从serviceManger中来查询，调用流程比较繁琐且因此耦合了ServiceManager。而Socket使用很简单并且技术成熟。

* **fork机制仅会拷贝当前线程，并不支持多线程，而Binder机制恰恰是多线程的**。当然zygote中也存在很多线程，但是zygote会将这些线程管理起来，在fork前将所有线程停止，fork完后再重新启动。

* Binder的阻塞调用会导致另一边也阻塞。会导致很多不必要的线程开销



## OkHttp

### OkHttp的连接池？

什么样的连接可以复用？怎么实现连接池？

### OkHttp怎么处理SSL？

### OkHttp里面用到了什么设计模式？

### OKHttp有哪些拦截器，分别起什么作用？

OkHttp网络拦截器，应用拦截器

## 组件化

### ARouter的原理？

ARouter怎么实现接口调用？ARouter怎么实现页面拦截？

### 注解处理器是处理java还是字节码？

### 组件化的接口下沉方案，接口膨胀问题怎么解决 ?

## 网络流量统计怎么做？
