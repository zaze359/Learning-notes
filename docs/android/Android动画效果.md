# Android 动画效果

---

## 复古风格

``overridePendingTransition(enterAnim, exitAnim);``



## Activity间跳转动画

1. 平移

```
跟overridePendingTransition效果是一样的
ActivityOptionsCompat.makeCustomAnimation(Context context, int enterResId, int exitResId)
```

2. 放大过渡

```
将一个控件平滑的放大过渡到第二个activity，一般用于相册的具体照片的查看
ActivityOptionsCompat.makeScaleUpAnimation(View source,int startX, int startY, int startWidth, int startHeight)
```

3. makeThumbnailScaleUpAnimation

```
ActivityOptionsCompat.makeThumbnailScaleUpAnimation(View source,Bitmap thumbnail, int startX, int startY)
```

4. 平移过渡

```
平滑的将一个控件平移的过渡到第二个activity
ActivityOptionsCompat.makeSceneTransitionAnimation(Activity activity, View sharedElement, String sharedElementName)
```

5. 多个控件平移过渡

```
平滑的将多个控件平移的过渡到第二个activity
ActivityOptionsCompat.makeSceneTransitionAnimation(Activity activity,Pair<View, String>… sharedElements)
```

## 补间动画（View Animation）

补间动画也就是View动画，主要就是通过**图像不断进行变换**的方式来实现动画效果，仅支持四种：**平移、缩放、旋转、透明度**。

* 执行补间动画时，View其实并没有移动，只是重绘改变了显示内容而已，所以**点击事件还是在原来的位置，新位置无法响应**。因此**不适合做具有交互的动画效果**。需要交换的动画应该使用属性动画。
* 由于支持的效果有限，所以在一些场景下效果并不理想，例如增大View的宽高，虽然能通过缩放实现，但是会导致内容也缩放，当我们不想缩放内容时，补间动画就不满足需求了。

> 原理： 
>
> 补间动画修改的 Matrix 是 `parent.mChildTransformation`，它是所有childView共用的，记录的是变换后的结果。
>
> 通过修改 这个共用Matrix，然后不断调用`onDraw()` ，从而实现动画效果。比较耗费GPU资源。

### TranslateAnimation：平移动画

x、y 分别平移100px，动画持续时间 1000ms

```xml
<?xml version="1.0" encoding="utf-8"?>
<set xmlns:android="http://schemas.android.com/apk/res/android"
    android:fillAfter="false" 
    android:zAdjustment="normal">
    <translate
        android:duration="1000"
        android:fromXDelta="0"
        android:fromYDelta="0"
        android:interpolator="@android:anim/linear_interpolator"
        android:toXDelta="100"
        android:toYDelta="100" />
</set>
```



````java
binding.animationTestBtn.setOnClickListener(v -> {
    Animation animation = AnimationUtils.loadAnimation(this, R.anim.test_anim);
    binding.animationTestBtn.startAnimation(animation);
});

binding.animationTestBtn.setOnClickListener(v -> {
    // 纯代码实现，两者效果是等效的
    TranslateAnimation translateAnimation = new TranslateAnimation(0, 100, 0, 100);
    translateAnimation.setInterpolator(new LinearInterpolator());
    translateAnimation.setDuration(1000);
    binding.animationTestBtn.startAnimation(translateAnimation);
});
````







### ScaleAnimation：缩放动画

### RotateAnimation：旋转动画

### AlphaAnimation：透明度动画

### AnimationSet：动画集合

```xml
```



## 逐帧动画（Drawable Animation）

逐帧动画就是**依次播放一组图像**从而形成动画效果。往往会占用大量内存，需要注意避免发生OOM。

> 放在 `drawable` 文件夹下 `test_anim_list.xml`

```xml
<animation-list xmlns:android="http://schemas.android.com/apk/res/android"
    android:oneshot="false">

    <item
        android:drawable="@drawable/ic_looks_1"
        android:duration="1000" />
    <item
        android:drawable="@drawable/ic_looks_2"
        android:duration="1000" />
</animation-list>
```

> 像正常的 图片使用即可，不过默认显示第一张图片，且没有动画。

```xml
    <ImageView
        android:layout_width="100dp"
        android:id="@+id/animation_list_iv"
        android:layout_height="100dp"
        app:tint="@color/black"
        android:src="@drawable/test_anim_list" />
```

> 启动动画

```java
binding.animationListIv.setOnClickListener( v -> {
    ((AnimationDrawable)binding.animationListIv.getDrawable()).start();
});
```





## 属性动画（Property Animation）

属性动画可以是通过不断的**改变控件的属性**从而实现动画效果。它可以修改任意对象的属性不仅仅是View。同时属性动画导致View位置发生变化后，View新的位置能够响应点击事件，**适合做具有交互的动画效果**。

使用属性动画时需要在Activity退出时及时停止，防止出现内存泄露问题。

### 如何使用

#### 使用属性动画的条件

* **必须具备属性对应的 get/set 方法**。没有时会导致崩溃。属性动画就是通过不断调用set方法来修改属性实现的动画效果的。
* **修改的这个属性会导致View发生变化**。如果UI不会发生变化，那么虽然设置成功，但是我们也看不到动画效果。

对于不满足上述条件而导致属性动画无法生效的场景，官方提供了几种解决思路：

* 考虑给直接对象添加 set/get方法，无法直接添加则通过 Wrap 的方式，在包装类中添加get/set，然后使用这个包装类来执行动画。
* 直接通过使用 ValueAnimator  来自己实现动画效果。

属性动画的实现一般使用 `ValueAnimator` 和 `ObjectAnimator` 。

* ValueAnimator：本质就是一个动画数值生成器并没有动画效果，根据插值器和估值器计算出结果返回给我们。
* ObjectAnimator：ObjectAnimator基于 ValueAnimator的封装，关联了View的属性，会帮助我们自动修改属性。

#### 使用 ObjectAnimator 类来实现属性动画

修改ProgressBar的进度

```kotlin
// 改变 ProgressBar 的 progress 属性的指
val animation = ObjectAnimator.ofInt(musicMiniPlayerProgressBar, "progress", progress)
// 动画持续时间
animation.duration = 1000L
// 线性插值器
animation.interpolator = LinearInterpolator()
animation.start()
```

#### 使用 ValueAnimator 来实现属性动画

```java
// 
ValueAnimator valueAnimator = ValueAnimator.ofInt(0, progress);
valueAnimator.setInterpolator(new LinearInterpolator());
valueAnimator.setDuration(1000L);

valueAnimator.addUpdateListener(animation -> {
    // 获得当前动画的进度值，一半就是 (progress - 0) / 2
    int value = (int) animation.getAnimatedValue();
    // 当前动画执行的比例。一半就是0.5
    // float fraction = animator.getAnimatedFraction();
    // 直接作为进度使用
    musicMiniPlayerProgressBar.setProgress(value);
});
```









### 时间插值器（TimeInterpolater）

> 插值器的作用就是根据流逝的时间百分比**计算出属性变化的百分比**。
>
> 插值器**决定的是动画变化的快慢**。

常见的插值器有：

| 插值器                           | 说明           |                        |
| -------------------------------- | -------------- | ---------------------- |
| LinearInterpolater               | 线性插值器     | 匀速动画效果           |
| AccelerateDecelerateInterpolator | 加速减速插值器 | 两头慢中间快的动画效果 |
| DecelerateInterpolator           | 减速插值器     | 减速动画效果。         |



### 类型估值器（TypeEvaluator）

> 估值器的作用就是根据插值器计算得到的属性变化百分比**计算出具体的属性值**。
>
> 估值器决定的是属性值，也就是**动画的运行轨迹**。
>
> 估值器计算公式：`value = start + fraction * (end - start)`
>
> * start：开始值
> * end：结束值，就是最终值
> * fraction：插值器计算得到的变化百分比

| 估值器         | 说明               |      |
| -------------- | ------------------ | ---- |
| IntEvaluator   | 对应 int           |      |
| FloatEvaluator | 对应 float         |      |
| ArgbEvaluator  | 对应 color 的 argb |      |

### 原理分析

属性动画其实就是调用对应属性的 `setter` 方法来修改值，它是真正的修改了View的值。不同于补间动画，当view 通过属性动画 发生位置变化时，新的位置能够响应触摸事件。

不过需要注意的是，View的 ltrb 属性实际上并没有发生改变，之所以新的位置能够响应点击事件是因为内部会通过`view.mTransformationInfo` 这个属性来回溯变换前的位置。mTransformationInfo 记录的就是 View 经过属性动画变换的信息。

#### ObjectAnimator.start()

```java
public final class ObjectAnimator extends ValueAnimator {
    public void start() {
        // 若存在和this相同动画就先去除。
        AnimationHandler.getInstance().autoCancelBasedOn(this);
        // ...
        // 直接调用 super，也就是 ValueAnimator.start()
        super.start();
    }
    
    boolean shouldAutoCancel(AnimationHandler.AnimationFrameCallback anim) {
        if (anim == null) {
            return false;
        }

        if (anim instanceof ObjectAnimator) {
            ObjectAnimator objAnim = (ObjectAnimator) anim;
            if (objAnim.mAutoCancel && hasSameTargetAndProperties(objAnim)) {
                return true;
            }
        }
        return false;
    }
}

public class AnimationHandler {
    
    void autoCancelBasedOn(ObjectAnimator objectAnimator) {
        for (int i = mAnimationCallbacks.size() - 1; i >= 0; i--) {
            AnimationFrameCallback cb = mAnimationCallbacks.get(i);
            if (cb == null) {
                continue;
            }
            // 取消动画
            if (objectAnimator.shouldAutoCancel(cb)) {
                ((Animator) mAnimationCallbacks.get(i)).cancel();
            }
        }
    }
}
```



## 动画优化

