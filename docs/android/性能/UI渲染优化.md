# UI渲染优化

```shell
# 输出包含各阶段发生的动画以及帧相关的性能信息
adb shell dumpsys gfxinfo 包名
# 获取最近120 帧每个绘制阶段的耗时信息
adb shell dumpsys gfxinfo 包名 framestats


# 拿到系统 SurfaceFlinger 相关的信息：Graphic Buffer内存的占用情况
adb shell dumpsys SurfaceFlinger
```



## 开启硬件加速

部分不能使用硬件加速的场景：渐变、磨砂、圆角、SVG等。

可以使用缓存Bitmap的方式进行优化。提前生成Bitmap，并进行内存管理。

## View 创建优化

> 使用XML创建View的流程中，涉及到了xml的读取、xml解析、生成对象（Framework使用了大量反射）等流程。

### measure/ layout 优化

* 减少层级扁平化处理、
* 使用`ConstraintLayout`布局
* 无效主题背景导致重复绘制

改为使用代码创建：修改不频繁的场景。

异步布局机制。

* 异步创建View

  ```kotlin
  // 异步线程的looper一般为空。需要先调用Looper.prepare()。
  Looper.prepare()
  val looper = Looper.myLooper()
  // 获取MainLooper中的MessageQueue
  val mQueue = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      Looper.getMainLooper().queue
  } else {
      ReflectUtil.executeMethod(Looper.getMainLooper(), "getQueue")
  }
  if(mQueue == null) return
  // 将异步线程中Looper的MessageQueue替换为MainLooper中的MessageQueue， 使用完后需要改回来。
  ReflectUtil.setFieldValue(looper, "mQueue", mQueue)
  ReflectUtil.executeMethod(threadLocal, "set", looper)
  ```

* View重用：放入缓存前，注意View状态的清除，防止状态的错乱



## ViewStub

ViewStub 的作用就是 占位符，它指向一个布局，但是默认不可见，且一开始也不会被 Inflate 。**只有当被设置为可见 或者主动调用 `inflate()`时才会真正的被创建。**

我们在布局中使用 `View.GONE`、`View.VISIBLE` 等来控制布局的显示隐藏时，即使我们一开始设置的是 `GONE` 但是这个布局还是会被Inflate 到内存，此时我们可以使用 `ViewStub` 来代替这些部分。



## Merge

Merge 的作用是会 合并一个层级，也就是说可以减少一个层级。

我们可以把 `<merge>` 当作一个父容器使用，类似 `LinearLayout` 、`RelativeLayout` 等，最终添加这个布局时，`<merge>` 这一层会被合并，也就是直接被子元素合并到 `<merge>`的父容器中。