# Android自定义View基础

* **View**：它是 Android中所有UI控件的基类。

* **ViewGroup**：它继承自View，所以ViewGroup也是一个View，常见的`LindearLayout` 就是一个ViewGroup。

  它内部可以包含一组View，也就是说ViewGroup内部还可以包含ViewGroup，通过这样的View树结构，我们可以构建出复杂的UI。



## View的位置参数

而我们的View 位于图层之中，可以由一块矩形框中。矩形的四个点由四个参数：left、top、right、bottom 构成，表示**相对于父控件的原始偏移量，参考坐标系为父控件, 即父控件左上角为原点（0， 0）**。

* 左上顶点：（left，top）。
* 左下顶点：（left，bottom）
* 右上顶点：（right，top）
* 右下顶点：（right，bottom）

这个矩形的宽高就是 view 的宽高。

* width = right - left
* heigh = bottom - top

还可以使用 xy来表示View的位置。

* (x，y)：表示 View左上角的坐标。没发生平移的情况 和 (left, top) 是相同的，发生平移后原始坐标(left, top) 不会发生变化，(x, y) 则会发生变化。参考坐标系也是父控件。![image-20230525160436041](./Android%E8%87%AA%E5%AE%9A%E4%B9%89View%E5%9F%BA%E7%A1%80.assets/image-20230525160436041.png)


> 相对应其他参考系的坐标获取方式。
>
> * `view.getLocationInScreen()`：获取 View在屏幕中的坐标。包括的通知栏这些。
> * `view.getLocationInWindow()`：获取 View在Window中的坐标。

## View的滚动

> View的滚动实际滚动是View中的内容，并不会滚动View自身。

View滚动 修改的是 `mScrollX` 和 `mScrollY`这两个属性，它们表示**View的内容相对于View的原始位置的偏移量**。

* **mScrollX**：`View::content.left` 相对于 `View.left` 的偏移。
  * `>0` 表示内容向上滚动
  * `<0` 表示内容向下滚动。
* **mScrollY**：`View::content.top` 相对于 `View.top` 的偏移。
  * `>0` 表示内容向左滚动。
  * `<0` 表示内容向右滚动。

```java
// 滚动到指定的 x, y 坐标
this.scrollTo(x, y);
```

```java
///
// 相对滚动：滚动指定的距离，
// 沿着x轴滚动 xOffset像素。
// 沿着y轴滚动 yOffset像素。
this.scrollBy(xOffset, yOffset);
```



## View的平移

**translationX/Y**：表示View在发生平移时产生的偏移量。默认情况下为 0。

xy 和 translationX/Y的关系，可以阅读源码理解。

```java
public float getX() {
    // mLeft就是相对应父控件的原始偏移
    // getTranslationX() 就是发生平时的额外偏移量
    return mLeft + getTranslationX();
}

public float getY() {
    return mTop + getTranslationY();
}
```



## View事件处理一些辅助类

### VelocityTracker(速度追踪器)

VelocityTracker 可以追踪手指在滑动过程中的速度，包括水平和竖直方向的速度。

使用方式：

```kotlin
// 获取实例
private val mVelocity: VelocityTracker = VelocityTracker.obtain()

// 使用
override fun onTouch(event: MotionEvent) {
    when (event.action) {
        MotionEvent.ACTION_DOWN -> {
            mVelocity.clear()
        }
        MotionEvent.ACTION_MOVE -> {
            // 添加用户行为
            mVelocity.addMovement(event)
            // 需要先计算速度：1000是采样间隔，表示计算每1000ms内手指划过的像素值。
            mVelocity.computeCurrentVelocity(1000)
            // 获取x 水平速度：返回的是划过的像素值，存在方向，顺坐标系（ltr）滑动为正，逆坐标系为负。
            // mVelocity..getXVelocity();
        }
        MotionEvent.ACTION_CANCEL, MotionEvent.ACTION_UP -> {
        }
    }
}

// 需要注意回收
override fun onDestroy() {
    super.onDestroy()
    mVelocity.recycle()
}
```



### Scroller(滚动器)

Scroller 能帮助我们方便的实现弹性滚动的效果。

创建实例：

```kotlin
val scroller: Scroller by lazy {
    // 线性插值器，
    // 会根据这个插值器来计算每次刷新需要滚动的距离。
    Scroller(context, LinearInterpolator())
}
```

使用：

```kotlin
 	/**
     * 实现 具体的滚动逻辑。
     * View重绘在 draw() 中会调用这个函数
     */
    override fun computeScroll() {
        super.computeScroll()
        // 若滑动已经终止返回false，否则会计算偏移量，并返回ture。
        if(mScroller.computeScrollOffset()) {
            // 获取滑动的位置, 并执行滚动
            scrollTo(mScroller.currX, mScroller.currY)
        }
    }

    /**
     * startScroll() 内部仅仅是一些属性的赋值，并没有滚动逻辑
     * 需要调用 invalidate()，触发重绘。
     * 滚动逻辑在 computeScroll() 中实现。
     * dx, dy: 偏移量
     */
    fun customScrollTo(dx: Int,dy: Int) {
        // 调用startScroll修改属性
        // 开始滚动的起点坐标：从当前位置开始移动。
        // x 右移 100
        // y 下移 100
        // 滚动耗时 1000，默认250ms
        mScroller.startScroll(scrollX, scrollY, -100, -100, 1000)
        // 需要调用 invalidate()，触发重绘，在draw()流程中会调用 computeScroll()
        invalidate()
        //
        // 惯性滚动时 velocityX，velocityY 可以通过使用VelocityTracker获取
		// mScroller.fling(startX, startY, velocityX, velocityY, minX, maxX, minY, maxY)
    }



```

> 停止滑动动画，直接滚动到最终位置

```kotlin
if (!mScroller.isFinished) {
    mScroller.abortAnimation()
}
```

---

### GestureDetector（手势检测）

可以检测用户的单击、滑动、长按、双击等操作。



## View的绘制流程

Canvas包含一个Bitmap，并使用Paint在这个Bitmap上作图。

|        |                                          |      |
| ------ | ---------------------------------------- | ---- |
| Canvas | 画图的动作。提供了基础的绘画函数。       |      |
| Bitmap | 画布。是一块存储图像像素的数据存储区域。 |      |
| Paint  | 画笔。表述绘制时的风格、颜色等。         |      |

View的显示主要涉及三个流程：测量（measure）、布局（layout）、绘制（draw）。

这三个过程依次对应三个回调函数：

* `onMeasure()`：执行测量逻辑，**确定绘制的大小**。
* `onLayout()`：处理子元素布局，**确定绘制在哪里**。
* `onDraw()`：确定自定义View 自身**绘制什么内容**。想要实现特定的图形效果时 可以重写这个函数。

> View 和 ViewGroup 区别就是 ViewGroup 多了几个处理子元素的流程。

整个绘制流程是**自顶向下**进行的。ViewRootImpl 从 根节点 DecorView 开始执行这三个流程，层层往下进行调用。

父控件的测量在子控件之后，布局和绘制则是在子控件之前。

![performTraversals流程](./Android%E8%87%AA%E5%AE%9A%E4%B9%89View%E5%9F%BA%E7%A1%80.assets/performTraversals%E6%B5%81%E7%A8%8B.jpg)

### 测量（measure）

View的测量流程主要是 **确定View的测量宽高**。需要注意的是**父控件的测量在子控件测量之后进行的**。

> 获取**测量宽高** 和 获取**View的宽高** 两者是不同的函数，不过正常情况下是两者的值是相同的。
>

 测量宽高

> 测量阶段决定 View的测量宽高，表示View的原始大小，xml或代码指定的大小

 ```java
 public final int getMeasuredWidth() {
  return mMeasuredWidth & MEASURED_SIZE_MASK;
 }
 ```

 View的宽高

> View的宽高是在 layout 阶段决定的。表示View的显示大小，

 ```java
 public final int getWidth() { // 根据 layout阶段赋值的 left、top、right、bottm计算得到
  return mRight - mLeft;
 }
 ```

#### 测量模式：MeasureSpec

Android提供了三种View的测量方式，并通过 `MeasureSpec` 类提供给我们使用。

* MeasureSpec **高2位**：表示 SpecMode。指**测量模式**。
* MeasureSpec **低30位**：表示 SpecSize。即在某种测量模式下的规格**尺寸大小**。

当然MeasureSpec 也提供了方便的API 供我们来获取对应的值。

| 测量模式                  | 说明                                                         | LayoutParams           |
| ------------------------- | ------------------------------------------------------------ | ---------------------- |
| `MeasureSpec.UNSPECIFIED` | 父容器**没有指定任何限制, 想多大多大**。系统内部多次Measure 时会使用到，自定义View时也会使用。ScrollView 测量子View高度时有使用。 |                        |
| `MeasureSpec.EXACTLY`     | **精确模式**。父容器**指定了子View 一个精确的大小**。此时子View的最终大小就是SpecSize。 | match_parent或固定数值 |
| `MeasureSpec.AT_MOST`     | **最大模式**。父容器**指定子View的最大尺寸**。子View的大小不能超过 SpecSize | wrap_content           |

View 的 MeasureSpec 由  父容器的MeasureSpec  以及  自身的LayoutParams 共同决定。对于 DecorView 则是 由Window的尺寸 以及 自身的LayoutParams共同决定。

View的创建规则 和 父容器MeasureSpec 间的关系如下：

| Child.LayoutParams \ Parent.MeasureSpec | EXACTLY | AT_MOST | UNSPECIFIED |                                  |
| --------------------------------------- | ------- | ------- | ----------- | -------------------------------- |
| dp                                      | EXACTLY | EXACTLY | EXACTLY     | 不受父容器影响                   |
| match_parent                            | EXACTLY | AT_MOST | UNSPECIFIED | 父容器是模式，子View就是什么模式 |
| wrap_content                            | AT_MOST | AT_MOST | UNSPECIFIED | 一般情况下就是 AT_MOST           |

* View是固定数值：此时不受父容器的MeasureSpec  影响，固定为 EXACTLY 精确模式，View的大小为给定的大小。
* View是match_parent：此时View的MeasureSpec  由父容器的MeasureSpec 决定，View的大小为父控件剩余空间` (parsent.size - parent.padding - view.margin)`
* View是wrap_content：固定为 AT_MOST 最大模式（除UNSPECIFIED外），View的大小不会超过父容器的剩余空间。

#### onMeasure()

View的测量过程最终会调用 `onMeasure()` ，在这个函数中决定了View的测量大小。系统提供的布局控件一般都重写了这个方法，根据不同的布局特性实现特定的测量逻辑。

View提供了默认的测量方式，测量后会通过 `setMeasuredDimension()`  保存到  mMeasuredWidth、mMeasuredHeight中。

* UNSPECIFIED：0 或者 背景图大小。
* AT_MOST、EXACTLY：父容器剩余空间大小。

> 自定义控件 处理测量逻辑时 需要重写这个函数。

```java
// widthMeasureSpec、heightMeasureSpec 是由 getChildMeasureSpec() 处理后得到的。
// 已经经过了转换
protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
    // 测量后的结果会保存在 mMeasuredWidth、mMeasuredHeight中
    setMeasuredDimension(getDefaultSize(getSuggestedMinimumWidth(), widthMeasureSpec),
                         getDefaultSize(getSuggestedMinimumHeight(), heightMeasureSpec));
}

// 默认是0，但会根据背景drawable的大小改变
protected int getSuggestedMinimumHeight() {
    return (mBackground == null) ? mMinHeight : max(mMinHeight, mBackground.getMinimumHeight());
}

// 处理不同的测量模式
public static int getDefaultSize(int size, int measureSpec) {
    int result = size;
    // 解析父容器的MeasureSpec
    int specMode = MeasureSpec.getMode(measureSpec);
    int specSize = MeasureSpec.getSize(measureSpec);
	//
    switch (specMode) {
        case MeasureSpec.UNSPECIFIED:
            // 使用传入的大小
            result = size;
            break;
        case MeasureSpec.AT_MOST:
        case MeasureSpec.EXACTLY:
            // 父容器的剩余空间
            result = specSize;
            break;
    }
    return result;
}
```



#### 获取测量大小

测量完成后会通过 `setMeasuredDimension()`  保存到  mMeasuredWidth、mMeasuredHeight中。

我们可以通过下面的API来获取测量后的大小：

* `getMeasuredWidth()`：获取View测量后的宽度。

* `getMeasuredHeight()`：获取View测量后的高度。

> 有时可能需要多次 `onMeasure()` 才能确定最终的宽、高。所以在 `onMeasure()` 中获取到的测量大小可能会不准确。可以在`onLayout()` 中去获取。

如何在Activity中获取：

1. **`View.post()`**：通过这个函数投递的消息会在View 初始化完毕并关联到window后执行。
2. **`onWindowFocusChanged()` **：此时View已经初始化完毕，我可以在获取到焦点时去获取View到宽高。不过这个函数调用非常频繁，Activity的Window每次获取/失去焦点都会被调用。
3. **ViewTreeObserver**：可以添加一个 `addOnGlobalLayoutListener()`，当View树的状态发生改变或者View树内部的View的可见性发现改变时，会回调给我们，我可以在回调中去获取view的宽高。



### 布局（layout）

View的 布局流程 主要是为了确定ViewGroup以及子元素的位置。

#### layout()

在 `layout()` 函数中 ViewGroup 的left、top、right、bottom这四个值会被赋值，最终通过 `setFrame()`确定了ViewGroup自身的位置，接着就会调用 `onLayout()`  来确定子元素的位置，也决定了 View的最终宽高。

```java
// 正常情况下 layout的参数 ltrb 是根据测量得到的宽高得到的
public void layout(int l, int t, int r, int b) {
    int oldL = mLeft;
    int oldT = mTop;
    int oldB = mBottom;
    int oldR = mRight;

    // 调用 setFrame() 确定自身位置 
    boolean changed = isLayoutModeOptical(mParent) ?
        setOpticalFrame(l, t, r, b) : setFrame(l, t, r, b);
    // ...
    if (changed || (mPrivateFlags & PFLAG_LAYOUT_REQUIRED) == PFLAG_LAYOUT_REQUIRED) {
        // 确定子元素的位置，这里也决定了View的最终宽高
        onLayout(changed, l, t, r, b);
        // ...
    }
    // ...
}
```

#### onLayout()

布局流程的最后会调用 `onLayout()`  函数来确定子元素的位置。系统提供的不同布局控件一般都重写了这个方法，来实现不同布局逻辑。

> 自定义控件处理子元素布局时需要重写这个函数。

### 绘制（draw）

View在经过 measure 和 layout过程后，以及确定了大小和位置，最后就是调用 `draw()` 将View绘制到屏幕上。

#### draw()

1. 绘制**背景 `drawBackground(canvas)`**。
2. （可选）保存图层：为后续的 fading 淡入淡出效果做准备。
3. 绘制 **View自身内容` onDraw(canvas)`**：View/ViewGroup默认为空实现。一个基础控件的样貌基本是这里处理的。
4. 绘制 **子元素`dispatchDraw(canvas)`**：ViewGroup 会重写这个函数，在内部遍历调用所有 `child.draw()`。
5. （可选）绘制 fading 效果并恢复保存的图层。
6. 绘制**装饰`onDrawForeground()`**：包括 foreground、scrollbars等。
7. （可选）绘制高亮

> ViewGroup 默认不会执行绘制， 它在 `initViewGroup()` 流程中会设置 **WILL_NOT_DRAW**，如果没有背景图就会设置 **PFLAG_SKIP_DRAW**，从而直接调用 `dispatchDraw()` 绘制子View，不调用自身的 `draw()`。所以 onDraw() 也就不会被调用。
>
> 如何清除 PFLAG_SKIP_DRAW？
>
> 1.  `setWillNotDraw(false)` ：可以强制开启ViewGroup自身的绘制。
> 2. 设置背景/前景：添加背景/前景时 这个标记会被清除。

```java
// 这个函数会被 ViewGroup.drawChild() 调用 
// 其中包含了是否跳过自身的绘制直接绘制子元素，mPrivateFlags & PFLAG_SKIP_DRAW
boolean draw(Canvas canvas, ViewGroup parent, long drawingTime) {
    final Animation a = getAnimation();
    if (a != null) {
        // 处理动画。
        more = applyLegacyAnimation(parent, drawingTime, a, scalingRequired);
        concatMatrix = a.willChangeTransformationMatrix();
        if (concatMatrix) {
            mPrivateFlags3 |= PFLAG3_VIEW_IS_ANIMATING_TRANSFORM;
        }
        transformToApply = parent.getChildTransformation();
    } else {
        // ...
    }
    // ...
    int sx = 0;
    int sy = 0;
    if (!drawingWithRenderNode) {
        // 处理滑动
        computeScroll();
        sx = mScrollX;
        sy = mScrollY;
    }
    // ...
    if (!drawingWithDrawingCache) {
        if (drawingWithRenderNode) {
            mPrivateFlags &= ~PFLAG_DIRTY_MASK;
            ((RecordingCanvas) canvas).drawRenderNode(renderNode);
        } else {
            // Fast path for layouts with no backgrounds
            // ViewGroup 默认存在 PFLAG_SKIP_DRAW，直接调用dispatchDraw() 绘制子View，不调用draw()。
            if ((mPrivateFlags & PFLAG_SKIP_DRAW) == PFLAG_SKIP_DRAW) {
                mPrivateFlags &= ~PFLAG_DIRTY_MASK;
                // 绘制子View
                dispatchDraw(canvas);
            } else {
                // 绘制自身及子View
                draw(canvas);
            }
        }
    } else ...
    return more;
}

// 执行绘制
public void draw(Canvas canvas) {
    final int privateFlags = mPrivateFlags;
    mPrivateFlags = (privateFlags & ~PFLAG_DIRTY_MASK) | PFLAG_DRAWN;

    /*
     * Draw traversal performs several drawing steps which must be executed
     * in the appropriate order:
     *
     *      1. Draw the background
     *      2. If necessary, save the canvas' layers to prepare for fading
     *      3. Draw view's content
     *      4. Draw children
     *      5. If necessary, draw the fading edges and restore layers
     *      6. Draw decorations (scrollbars for instance)
     *      7. If necessary, draw the default focus highlight
     */

    // Step 1, draw the background, if needed
    int saveCount;

    drawBackground(canvas);

    boolean drawTop = false;
    boolean drawBottom = false;
    boolean drawLeft = false;
    boolean drawRight = false;

    float topFadeStrength = 0.0f;
    float bottomFadeStrength = 0.0f;
    float leftFadeStrength = 0.0f;
    float rightFadeStrength = 0.0f;

    // Step 2, save the canvas' layers
    saveCount = canvas.getSaveCount();
    canvas.saveUnclippedLayer(,,,)
    // ...

    // Step 3, draw the content
    onDraw(canvas);

    // Step 4, draw the children
    // 这里会遍历调用所有的child.draw()
    dispatchDraw(canvas);

    // Step 5, draw the fade effect and restore layers
    final Paint p = scrollabilityCache.paint;
    final Matrix matrix = scrollabilityCache.matrix;
    final Shader fade = scrollabilityCache.shader;

    // must be restored in the reverse order that they were saved
    if (drawRight) {
        matrix.setScale(1, fadeHeight * rightFadeStrength);
        matrix.postRotate(90);
        matrix.postTranslate(right, top);
        fade.setLocalMatrix(matrix);
        p.setShader(fade);
        if (solidColor == 0) {
            canvas.restoreUnclippedLayer(rightSaveCount, p);

        } else {
            canvas.drawRect(right - length, top, right, bottom, p);
        }
    }
    // ....

    canvas.restoreToCount(saveCount);
    drawAutofilledHighlight(canvas);

    // Overlay is part of the content and draws beneath Foreground
    if (mOverlay != null && !mOverlay.isEmpty()) {
        mOverlay.getOverlayView().dispatchDraw(canvas);
    }

    // Step 6, draw decorations (foreground, scrollbars)
    onDrawForeground(canvas);

    // Step 7, draw the default focus highlight
    drawDefaultFocusHighlight(canvas);

    if (isShowingLayoutBounds()) {
        debugDrawFocus(canvas);
    }
}
```



#### onDraw()

默认是空实现，没有做什么处理。

> 自定义View 想要实现特定的图形效果时 需要重写这个函数。



#### ViewGroup.dispatchDraw()

ViewGroup重写了 `dispatchDraw()`，在内部会先将**对child根据 Z值从大到小进行排序**，最后遍历排序后的列表依次**绘制子元素**。

```java
protected void dispatchDraw(Canvas canvas) {
    final int childrenCount = mChildrenCount;
    final View[] children = mChildren;
    int flags = mGroupFlags;

    if ((flags & FLAG_RUN_ANIMATION) != 0 && canAnimate()) {
        for (int i = 0; i < childrenCount; i++) {
            final View child = children[i];
            if ((child.mViewFlags & VISIBILITY_MASK) == VISIBLE) {
                final LayoutParams params = child.getLayoutParams();
                attachLayoutAnimationParameters(child, params, i, childrenCount);
                bindLayoutAnimation(child);
            }
        }

        final LayoutAnimationController controller = mLayoutAnimationController;
        if (controller.willOverlap()) {
            mGroupFlags |= FLAG_OPTIMIZE_INVALIDATE;
        }

        controller.start();

        mGroupFlags &= ~FLAG_RUN_ANIMATION;
        mGroupFlags &= ~FLAG_ANIMATION_DONE;

        if (mAnimationListener != null) {
            mAnimationListener.onAnimationStart(controller.getAnimation());
        }
    }

    int clipSaveCount = 0;
    final boolean clipToPadding = (flags & CLIP_TO_PADDING_MASK) == CLIP_TO_PADDING_MASK;
    if (clipToPadding) {
        clipSaveCount = canvas.save(Canvas.CLIP_SAVE_FLAG);
        canvas.clipRect(mScrollX + mPaddingLeft, mScrollY + mPaddingTop,
                        mScrollX + mRight - mLeft - mPaddingRight,
                        mScrollY + mBottom - mTop - mPaddingBottom);
    }

    // We will draw our child's animation, let's reset the flag
    mPrivateFlags &= ~PFLAG_DRAW_ANIMATION;
    mGroupFlags &= ~FLAG_INVALIDATE_REQUIRED;

    boolean more = false;
    final long drawingTime = getDrawingTime();

    canvas.enableZ();
    final int transientCount = mTransientIndices == null ? 0 : mTransientIndices.size();
    int transientIndex = transientCount != 0 ? 0 : -1;
    // Only use the preordered list if not HW accelerated, since the HW pipeline will do the
    // draw reordering internally
    // 若是硬件加速 则使用硬件加速内部会进行排序。
    // 否则调用 buildOrderedChildList(), 内部根据View的Z值从大到小排序
    final ArrayList<View> preorderedList = drawsWithRenderNode(canvas)
        ? null : buildOrderedChildList();
    final boolean customOrder = preorderedList == null
        && isChildrenDrawingOrderEnabled();
    
    // 遍历child 进行绘制
    for (int i = 0; i < childrenCount; i++) {
        while (transientIndex >= 0 && mTransientIndices.get(transientIndex) == i) {
            final View transientChild = mTransientViews.get(transientIndex);
            if ((transientChild.mViewFlags & VISIBILITY_MASK) == VISIBLE ||
                transientChild.getAnimation() != null) {
                // 调用的是 三个参数的 draw()
                more |= drawChild(canvas, transientChild, drawingTime);
            }
            transientIndex++;
            if (transientIndex >= transientCount) {
                transientIndex = -1;
            }
        }
		// 从 按Z从大到小 排序后的列表中取出 child，进行绘制
        final int childIndex = getAndVerifyPreorderedIndex(childrenCount, i, customOrder);
        final View child = getAndVerifyPreorderedView(preorderedList, children, childIndex);
        if ((child.mViewFlags & VISIBILITY_MASK) == VISIBLE || child.getAnimation() != null) {
            more |= drawChild(canvas, child, drawingTime);
        }
    }
    while (transientIndex >= 0) {
        // there may be additional transient views after the normal views
        final View transientChild = mTransientViews.get(transientIndex);
        if ((transientChild.mViewFlags & VISIBILITY_MASK) == VISIBLE ||
            transientChild.getAnimation() != null) {
            more |= drawChild(canvas, transientChild, drawingTime);
        }
        transientIndex++;
        if (transientIndex >= transientCount) {
            break;
        }
    }
    if (preorderedList != null) preorderedList.clear();

    // Draw any disappearing views that have animations
    if (mDisappearingChildren != null) {
        final ArrayList<View> disappearingChildren = mDisappearingChildren;
        final int disappearingCount = disappearingChildren.size() - 1;
        // Go backwards -- we may delete as animations finish
        for (int i = disappearingCount; i >= 0; i--) {
            final View child = disappearingChildren.get(i);
            more |= drawChild(canvas, child, drawingTime);
        }
    }
    canvas.disableZ();

    if (isShowingLayoutBounds()) {
        onDebugDraw(canvas);
    }

    if (clipToPadding) {
        canvas.restoreToCount(clipSaveCount);
    }

    // mGroupFlags might have been updated by drawChild()
    flags = mGroupFlags;

    if ((flags & FLAG_INVALIDATE_REQUIRED) == FLAG_INVALIDATE_REQUIRED) {
        invalidate(true);
    }

    if ((flags & FLAG_ANIMATION_DONE) == 0 && (flags & FLAG_NOTIFY_ANIMATION_LISTENER) == 0 &&
        mLayoutAnimationController.isDone() && !more) {
        // We want to erase the drawing cache and notify the listener after the
        // next frame is drawn because one extra invalidate() is caused by
        // drawChild() after the animation is over
        mGroupFlags |= FLAG_NOTIFY_ANIMATION_LISTENER;
        final Runnable end = new Runnable() {
            @Override
            public void run() {
                notifyAnimationListener();
            }
        };
        post(end);
    }
}
```

#### View的绘制顺序

这个函数根据 **Z 值从大到小，也就是 对child 进行排序**。

我们想要修改绘制顺序时可以通过两个方式：

* **调整 View的Z 值**：使用`setZ() `、`setElevation()`、`etTranslationZ()` 这三个函数都可以做到。
* **开启 customOrder**：调用 `setChildrenDrawingOrderEnabled(true)` 可以开启 customOrder，然后通过重写  `getChildDrawingOrder()` 的返回值来决定child的绘制顺序。

```java
ArrayList<View> buildOrderedChildList() {
    final int childrenCount = mChildrenCount;
    if (childrenCount <= 1 || !hasChildWithZ()) return null;

    if (mPreSortedChildren == null) {
        mPreSortedChildren = new ArrayList<>(childrenCount);
    } else {
        // callers should clear, so clear shouldn't be necessary, but for safety...
        mPreSortedChildren.clear();
        mPreSortedChildren.ensureCapacity(childrenCount);
    }
	// 是否使用自定义排序
    final boolean customOrder = isChildrenDrawingOrderEnabled();
    for (int i = 0; i < childrenCount; i++) {
        // add next child (in child order) to end of list
        // 默认是按照遍历属性取出，启动 customOrder 时按照 getChildDrawingOrder() 的返回值取出child
        // 决定的是Z相同时的默认排序
        final int childIndex = getAndVerifyPreorderedIndex(childrenCount, i, customOrder);
        final View nextChild = mChildren[childIndex];
        final float currentZ = nextChild.getZ();

        // insert ahead of any Views with greater Z
        int insertIndex = i;
        // Z值从大到小的顺序放入列表中。
        while (insertIndex > 0 && mPreSortedChildren.get(insertIndex - 1).getZ() > currentZ) {
            insertIndex--;
        }
        mPreSortedChildren.add(insertIndex, nextChild);
    }
    return mPreSortedChildren;
}
```

```java
public float getZ() {
    return getElevation() + getTranslationZ();
}
public void setZ(float z) {
    setTranslationZ(z - getElevation());
}
```



## invalidate() 和 requestLayout()

* invalidate()：会导致 `View.onDraw()` 被调用。适用于布局不变，刷新内容的场景。
* requestLayout()：会导致View的 `onMeasure()`、`onLayout()`被调用，但是`onDraw()` 可能不会调用，只有当布局发生变化时才会调用，所以若是一定要重绘内容，则需要手动调用一下 `invalidate()`。适用于需要当前布局发送变化需要重新测量的场景。

### requestLayout() 流程

* 给所有的View 设置了 `PFLAG_FORCE_LAYOUT(强制重新测量和布局)` 和 `PFLAG_INVALIDATED(允许重绘)` 这两个 flag。
* 层层向上调用 `mParent.requestLayout()` ，最终调用到 `ViewRootImpl.requestLayout()`，将 `mLayoutRequested` 置为true，接着ViewRootImpl 内部调用了 `performTraversals()` ，重新触发了View的渲染流程。
  * mParent 在addView()时被赋值，指向 父容器，层层向上传递到DecorView，而DecorView的 parent是 ViewRootImpl。

* `measure()`：由于 `PFLAG_FORCE_LAYOUT`  这个标志，重新执行了 `onMeasure()`。同时又 添加了 `PFLAG_LAYOUT_REQUIRED`这个标记。
* `layout()`：由于 `mLayoutRequested == true` 并且 `PFLAG_LAYOUT_REQUIRED` 标记，重写执行了 `onLayout()`。
* `onDraw()` 不一定会被调用。只有在布局发生变化，即 layout的结果和上次之前不同，才会触发 `invalidate()` 从而调用 onDraw()。

```java
public void requestLayout() {
    if (mMeasureCache != null) mMeasureCache.clear();

    if (mAttachInfo != null && mAttachInfo.mViewRequestingLayout == null) {
        // Only trigger request-during-layout logic if this is the view requesting it,
        // not the views in its parent hierarchy
        ViewRootImpl viewRoot = getViewRootImpl();
        if (viewRoot != null && viewRoot.isInLayout()) {
            if (!viewRoot.requestLayoutDuringLayout(this)) {
                return;
            }
        }
        mAttachInfo.mViewRequestingLayout = this;
    }
	// 添加 PFLAG_FORCE_LAYOUT 
    // 这个标志位会强制重新测量和布局
    mPrivateFlags |= PFLAG_FORCE_LAYOUT;
    // 添加 PFLAG_INVALIDATED
    // 这个标志位会允许重绘
    mPrivateFlags |= PFLAG_INVALIDATED;
	// 等于将三个流程的标志都重置了。
    
    if (mParent != null && !mParent.isLayoutRequested()) {
        // 是正常流程的逆向过程。
        // mParent 在addView时被赋值，指向 父容器，层层向上传递到DecorView，而DecorView的 parent是 ViewRootImpl
        // 所以最终会调用 ViewRootImpl.requestLayout()，内部调用了 performTraversals()
        // 也就是执行渲染流程的入口，所以三个流程都会被调用。
        mParent.requestLayout();
    }
    if (mAttachInfo != null && mAttachInfo.mViewRequestingLayout == this) {
        mAttachInfo.mViewRequestingLayout = null;
    }
}
```



### invalidate()

invalidate() 会调用 `p.invalidateChild()` ，ViewGroup重写了这个函数，内部会递归调用了 `parent.invalidateChildInParent()`，最终调用到 `ViewRootImpl.invalidateChildParent()`，从而触发了 `performTraversals()`函数，进而View被重绘。

不过由于调用的不是 `ViewRootImpl.requestLayout()` 因此 `mLayoutRequested == false` ，那么 也就不会触发 layout流程。

```java
// invalidateCache 默认 true
public void invalidate(boolean invalidateCache) {
    invalidateInternal(0, 0, mRight - mLeft, mBottom - mTop, invalidateCache, true);
}

void invalidateInternal(int l, int t, int r, int b, boolean invalidateCache,
                        boolean fullInvalidate) {
    if (mGhostView != null) {
        mGhostView.invalidate(true);
        return;
    }

    if (skipInvalidate()) {
        return;
    }

    // Reset content capture caches
    mPrivateFlags4 &= ~PFLAG4_CONTENT_CAPTURE_IMPORTANCE_MASK;
    mContentCaptureSessionCached = false;

    if ((mPrivateFlags & (PFLAG_DRAWN | PFLAG_HAS_BOUNDS)) == (PFLAG_DRAWN | PFLAG_HAS_BOUNDS)
        || (invalidateCache && (mPrivateFlags & PFLAG_DRAWING_CACHE_VALID) == PFLAG_DRAWING_CACHE_VALID)
        || (mPrivateFlags & PFLAG_INVALIDATED) != PFLAG_INVALIDATED
        || (fullInvalidate && isOpaque() != mLastIsOpaque)) {
        if (fullInvalidate) {
            mLastIsOpaque = isOpaque();
            mPrivateFlags &= ~PFLAG_DRAWN;
        }

        // 添加 PFLAG_DIRTY
        mPrivateFlags |= PFLAG_DIRTY;

        // 添加 PFLAG_INVALIDATED
        // 这个标志位会强制进程重绘
        if (invalidateCache) { 
            mPrivateFlags |= PFLAG_INVALIDATED;
            // 去除缓存标记
            mPrivateFlags &= ~PFLAG_DRAWING_CACHE_VALID;
        }

        // Propagate the damage rectangle to the parent view.
        final AttachInfo ai = mAttachInfo;
        final ViewParent p = mParent;
        if (p != null && ai != null && l < r && t < b) {
            final Rect damage = ai.mTmpInvalRect;
            damage.set(l, t, r, b);
            // 调用 p.invalidateChild()
            p.invalidateChild(this, damage);
        }

        // Damage the entire projection receiver, if necessary. 
        if (mBackground != null && mBackground.isProjected()) {
            final View receiver = getProjectionReceiver();
            if (receiver != null) {
                receiver.damageInParent();
            }
        }
    }
}

```





---

## 自定义属性

我们可以给View添加一些自定义属性，然后像 `android:layout_width` 等属性一样使用。

### 定义自定义属性

定义文件：`values/attrs.xml`。

```xml
<resources>
    <!-- 声明一个属性集合：AddImageLayout -->
    <declare-styleable name="AddImageLayout">
        <!-- 定义一个属性hSpace，类型是 dimension -->
        <attr name="hSpace" format="dimension" />
        <attr name="vSpace" format="dimension" />
    </declare-styleable>
</resources>
```

| 属性类型                       |                                                   |      |
| ------------------------------ | ------------------------------------------------- | ---- |
| dimension                      | 尺寸，100dp、18sp等                               |      |
| color                          | 颜色，`@color/black`                              |      |
| reference                      | 任意类型的资源，`@color/blue` 、`@string/play` 等 |      |
| string、integer、boolean等类型 | 对应基础类型的值。                                |      |

### 使用自定义属性

* 添加 schemas：`xmlns:app="http://schemas.android.com/apk/res-auto"`
* 使用属性 ：`app:hSpace` 。

```xml
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical">

    <com.zaze.common.widget.AddImageLayout
        android:id="@+id/custom_add_image_layout"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:hSpace="20dp"
        app:vSpace="20dp" />

</LinearLayout>

```



### 获取自定义属性

```java
public AddImageLayout(Context context, AttributeSet attrs, int defStyleAttr) {
    super(context, attrs, defStyleAttr);
    // 获取到 AddImageLayout 这个属性集合
    TypedArray typedArray = context.obtainStyledAttributes(attrs, R.styleable.AddImageLayout, 0, 0);
    // 获取对应的属性值
    hSpace = typedArray.getDimensionPixelSize(R.styleable.AddImageLayout_hSpace, hSpace);
    vSpace = typedArray.getDimensionPixelSize(R.styleable.AddImageLayout_vSpace, vSpace);
    // 释放
    typedArray.recycle();
}
```



## LayoutInflater

LayoutInflater 是一个系统服务，用于加载布局，我们 xml 中定义的布局最终都是通过它来加载的。

我们一般会调用 `inflate()`来加载布局：

```java
LayoutInflater.from(parent.context).inflate(R.layout.item_test, parent, false)
```

内部经历 xml加载、解析后最终会调用到 `tryCreateView()` 来创建View，具体的创建实现则是交给了 Factory/Factory2 来实现，不过默认都是通过反射的方式创建View的。

```java
	public final View tryCreateView(@Nullable View parent, @NonNull String name,
        @NonNull Context context,
        @NonNull AttributeSet attrs) {
        if (name.equals(TAG_1995)) {
            // Let's party like it's 1995!
            return new BlinkLayout(context, attrs);
        }

        View view;
        // 布局创建优先级：mFactory2 > mFactory > mPrivateFactory
        if (mFactory2 != null) {
            view = mFactory2.onCreateView(parent, name, context, attrs);
        } else if (mFactory != null) {
            view = mFactory.onCreateView(name, context, attrs);
        } else {
            view = null;
        }

        if (view == null && mPrivateFactory != null) {
            view = mPrivateFactory.onCreateView(parent, name, context, attrs);
        }

        return view;
    }
```

#### root、attachToRoot参数的作用

root 会影响 创建的布局最外层的LayoutParams：

* root == null：被创建View的**最外层的LayoutParams将失效**，设置的宽高并不会生效，变为 wrap_content。
* root != null：被创建View的**最外层的LayoutParams生效**。

attachToRoot 表示是否和root关联：

* attachToRoot  == true：**被创建View会作为 root的子布局**，且`inflater()`**返回给我们的是root**。
* attachToRoot == false：被创建的View不会和root关联，`inflater()`返回给我们的就是创建的View。
  * root为空时 attachToRoot这个属性就没什么用了，`inflater()`返回的也是创建的View。

###  Factory/Factory2

> 一般使用Factory2 它继承子 Factory。需要注意的是 **factory2 只能设置一次**，反复添加会报错。

提供给我们开发者使用的自定义加载View的接口。

我们可以通过 设置 Factory2 来 **统一配置（字体、背景等）**，或者将 TextView **统一替换**成 我们增强过的一个 CustomTextView等。

> Android提供的 `AppCompatActivity `就会通过设置 Factory的方式来统一将空间替换成 AppCompatXXX （AppCompatButton）这些控件。

```java
// AppCompatActivity 源码
@ContentView
    public AppCompatActivity(@LayoutRes int contentLayoutId) {
        super(contentLayoutId);
        initDelegate();
    }

    private void initDelegate() {
        // TODO: Directly connect AppCompatDelegate to SavedStateRegistry
        getSavedStateRegistry().registerSavedStateProvider(DELEGATE_TAG,
                new SavedStateRegistry.SavedStateProvider() {
                    @NonNull
                    @Override
                    public Bundle saveState() {
                        Bundle outState = new Bundle();
                        getDelegate().onSaveInstanceState(outState);
                        return outState;
                    }
                });
        // 设置监听，会在 onCreate() 中被调用。
        addOnContextAvailableListener(new OnContextAvailableListener() {
            @Override
            public void onContextAvailable(@NonNull Context context) {
                final AppCompatDelegate delegate = getDelegate();
                // AppCompatDelegate 自身就是 Factory2
                // 设置 Factory2，已存在Factory2时内部无法再添加
                delegate.installViewFactory();
                delegate.onCreate(getSavedStateRegistry()
                        .consumeRestoredStateForKey(DELEGATE_TAG));
            }
        });
    }
```

需要注意：

* 若我们先设置了自定义 Factory后，AppCompatActivity 的Factory 就不生效了。

* 若我们后设置 Factory，那么就会报错，我们的就无法使用了。

`addOnContextAvailableListener` 在`onCreate()` 中被调用，所有我们需要在 `onCreate()` 之前设置自定义的Factory，并且兼容 AppCompatDelegate。

方法很简单：

* 我们直接获取到 delegate，然后主动调用它即可。
* 还有一种方式就是设置 `AppCompatDelegate.mAppCompatViewInflater` ，它是 AppCompatDelegate 提供的给我们自定义用的。

```java
	@Override
    protected void onCreate(Bundle savedInstanceState) {
        getLayoutInflater().setFactory2(new LayoutInflater.Factory2() {
            @Nullable
            @Override
            public View onCreateView(@Nullable View parent, @NonNull String name, @NonNull Context context, @NonNull AttributeSet attrs) {
                // 做一些我们自己的配置
                // 不需要处理时传给 delegate 处理
                return getDelegate().createView(parent, name, context, attrs);
            }

            @Nullable
            @Override
            public View onCreateView(@NonNull String name, @NonNull Context context, @NonNull AttributeSet attrs) {
                return onCreateView(null, name, context, attrs);
            }
        });
		// 在
        super.onCreate(savedInstanceState);
    }
```



## 自定义View优化

### 及时停止线程和动画

在  `onDetachedFromWindow()` 中 这里停止线程和动画，防止发生内存泄露。这个函数会在当前View被remove时 或者 包含此View的Activity退出时被调用。



