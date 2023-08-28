# View的滑动冲突

当多个可滚动的View嵌套使用时，若使用的控件没有帮我们处理滑动冲突，那么们就需要自己手动来处理出现滑动冲突问题。

滑动冲突主要是由于系统无法判断我们需要滑动的是外部的View还是内部的View。所以解决滑动冲突的核心思想就是补充这部分逻辑，让系统能够判断事件应该交由哪个View来消费。

## 滑动冲突的类型

滑动冲突大体可以分为两类：

**1. 内外滑动方向不一致。**

**2. 内部滑动方向一致。**

> 当存在 2层以上的嵌套时，只需要依次将相邻层级间的冲突处理了即可，基本单位还是 这两大类。

### 内外滑动方向不一致

这个情况的处理方式比较简单，我们只需要先**判断一下滑动的方向，然后分发给对应的View**即可。

例如 外部水平滑动， 内部垂直滑动：

此时我们可以通过 两个（或多个）Move事件间坐标的间距来判断，若 x差量 > y 差量，则表示水平滑动，分发给外部的View。相反则是垂直方向滑动，分发给内部的View。

### 内外滑动方向一致

此时一般的处理方式是**当内部View 滑动到边界时 就交由外部View来滑动**。

当然业务上若有特殊的规则，可以根据业务来调整。



## 滑动冲突的解决方式

### 外部拦截法

**外部拦截法是父控件优先处理，由父控件来负责拦截并分发事件**。若父控件需要则拦截事件，否则就不拦截，交由子View来处理事件。

重写父控件的 `onInterceptTouchEvent()`：

> 注意 ACTION_DOWN 需要返回false, 否则会导致 子元素接收不到事件。

```kotlin
override fun onInterceptTouchEvent(ev: MotionEvent): Boolean {
    Log.i("TouchViewFirst", "onInterceptTouchEvent: ${ev.action}")
	when(ev.action) {
        MotionEvent.ACTION_DOWN -> {
            touchX = ev.x
            touchY = ev.y
            // ACTION_DOWN 需要返回false，保证子元素能接收到事件。
            return false
        }
        MotionEvent.ACTION_MOVE -> {
            offsetX = ev.x - touchX
            offsetY = ev.y - touchY
            // 这里处理move事件, 添加拦截逻辑。
            return if() { // 需要拦截
                true
            } else { // 不需要拦截
                false
            }
        }
        else -> {
            return false
        }
    }
}
```

### 内部拦截法

内部拦截法是**子元素优先处理**，一般需要配合 `requestDisallowInterceptTouchEvent()` 来使用，由子元素来控制父控件是否能够拦截事件，这样所有的事件都将传递到子元素，若子元素需要就消费事件，不需要则向上传递。

重写父控件 `onInterceptTouchEvent()`，模拟父控件拦截事件的场景：

> 注意 ACTION_DOWN 需要返回false, 否则会导致 子元素接收不到事件。

```kotlin
override fun onInterceptTouchEvent(ev: MotionEvent): Boolean {
	when(ev.action) {
        MotionEvent.ACTION_DOWN -> {
            // ACTION_DOWN 需要返回false，保证子元素能接收到事件。
            return false
        }
        else -> { // 默认无脑拦截可以
            // 具体是否能够获取到事件则是由子元素调用requestDisallowInterceptTouchEvent() 来控制
            return true
        }
    }
}
```

重写子控件的 `dispatchTouchEvent()`：

```kotlin
    override fun dispatchTouchEvent(ev: MotionEvent): Boolean {
        Log.i("TouchViewFirst", "dispatchTouchEvent: ${ev.action}")
        when (ev.action) {
            MotionEvent.ACTION_DOWN -> { // 预先置为不允许父容器拦截
                parent.requestDisallowInterceptTouchEvent(true)
            }

            MotionEvent.ACTION_MOVE -> {
                if (canChildScroll) { // 子元素需要，不允许父容器拦截
                    parent.requestDisallowInterceptTouchEvent(true)
                } else {  // 子元素不需要，交给父元素处理
                    parent.requestDisallowInterceptTouchEvent(false)
                }
            }
            else -> {
            }
        }
        return super.dispatchTouchEvent(ev)
    }

```



## 嵌套滑动的处理

核心思想是 **child 将滑动过程的不同阶段中通过接口回调给 parent** ，包括开始滑动、滑动前、滑动后、fling等接口。

* 子View 实现 `NestedScrollingChild` 接口，然后将View的触摸事件进行处理，转换为对应的接口调用。
* 一般在 `NestedScrollingChild` 接口的实现中会调用 `NestedScrollingChildHelper` 来处理嵌套滑动事件。
* `NestedScrollingChildHelper` 内部会查找对应的 `NestedScrollingParent`，并调用对应的接口将事件传递给 parent。
* parent 根据 NestedScrollingParent 中的接口来做对应的处理，一般会调用 NestedScrollingParentHelper 来辅助处理。

| 类                          |                                                            |                                         |
| --------------------------- | ---------------------------------------------------------- | --------------------------------------- |
| NestedScrollingChild        | 用于嵌套滑动中的子View。例如RecyclerView就实现了这个接口。 | 用于产生嵌套滑动事件。                  |
| NestedScrollingParent       | 用于嵌套滑动中的父容器。                                   | 可以接收child的嵌套滑动事件。           |
| NestedScrollingChildHelper  | 嵌套滑动中的子View使用，用于事件传递。                     | 负责将child的嵌套滑动事件发送给parent。 |
| NestedScrollingParentHelper | 嵌套滑动中的父容器使用，辅助处理嵌套事件。                 |                                         |



## 场景的滑动冲突场景记录

### ViewPager2 嵌套 ViewPager、RecyclerView

> ViewPager2 基于 RecyclerView，所以等同 RecyclerView嵌套 ViewPager、RecyclerView

处理方式：自定义一个 `NestedScrollViewHost` 类，并采用内部拦截法处理滑动冲突。

类似Google提供的 `NestedScrollView`，将 ViewPager、RecyclerView 等作为 NestedScrollViewHost 的子元素即可。不必修改原先的控件。

