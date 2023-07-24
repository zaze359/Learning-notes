# View的事件分发机制

## MotionEvent

Android定义了一些的触摸事件用来表示用户手指在屏幕上的操作。

从触摸屏幕( `ACTION_DOWN` ) 然后到 离开屏幕(`ACTION_UP/ACTION_CANCEL`) 这期间产生的所有事件被归为 一个事件序列，

事件分发就是以 事件序列作为一个基本单位，其中 ACTION_DOWN 由谁消费将决定整个事件序列有谁来消费。

| 触摸事件      |                                          |      |
| ------------- | ---------------------------------------- | ---- |
| ACTION_DOWN   | 刚接触到屏幕                             |      |
| ACTION_UP     | 从触摸状态抬起离开屏幕                   |      |
| ACTION_MOVE   | 在屏幕上移动                             |      |
| ACTION_CANCEL | 手指未抬起，但是移动到了View的方法之外。 |      |

触摸事件发生时，会回调一个 `MotionEvent` ，内部记录的触摸事件的 x/y 位置信息。

它的参考坐标系为触摸的View自身，即**View左上角为原点（0，0）**。

> 若要获取相对于屏幕的坐标，使用 `event.getRawX()`、`event.getRawY()`来获取。
>
> 在处理触摸事件时，还会使用 TouchSlop，它表示系统所能识别的最小滚动距离。
>
> 通过 `ViewConfiguration.get(context).scaledTouchSlop`  来获取。



## 事件分发函数

分发过程主要涉及 `dispatchTouchEvent()`、`onInterceptTouchEvent()` 、`onTouchEvent()` 这三个函数。

* `dispatchTouchEvent()`：事件分发的入口，决定了事件分发的逻辑。其他两个函数都是这个函数中调用的。
* `onInterceptTouchEvent()`：拦截事件，**可以阻止事件向下传递**。
* `onTouchEvent()`：处理事件的地方，也是决定是否消费事件。**返回 true 表示消费事件，事件不会再继续向上传递传播**。

这里先列出一张事件流传图。

> 拦截：`onInterceptTouchEvent()` 返回 true。
>
> 消费：`onTouchEvent()` 返回 true。

![页-10](./View%E7%9A%84%E4%BA%8B%E4%BB%B6%E5%88%86%E5%8F%91%E6%9C%BA%E5%88%B6.assets/%E9%A1%B5-10.jpg)

### dispatchTouchEvent()

事件分发的入口，决定了事件分发的逻辑。一般不会重写这个函数，除非需要处理滑动冲突。

* ViewGroup：会触发，onInterceptTouchEvent()，若不拦截

它的默认实现会调用`onInterceptTouchEvent()` 和 `onTouchEvent()` 这两个函数。

> 如果重写时 去除了默认的实现，那么自身 `onInterceptTouchEvent()` 和 `onTouch()` ，以及子元素的所有事件函数都将不会被自动调用，需要我们手动处理。

* 返回 true：表示消费了这个事件，事件不会再传递给child，由当前的View 来处理事件。
* 返回 false：不消费事件，事件继续往下传递。

```kotlin
    override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
        Log.i("TouchViewFirst", "dispatchTouchEvent: ${ev?.action}")
        return super.dispatchTouchEvent(ev)
    }
```

### onInterceptTouchEvent()

用于拦截事件，可以起到阻止事件向下传递的作用。

> 只有View Group才有这个函数

* 返回 true：表示拦截这个事件，那么会调用`self.onTouchEvent()`，事件也不会继续向下传播。
* 返回 false：表示不拦截，事件会继续向child 传播，会调用 `child.dispatchTouchEvent()`。

> 1. 若当前元素 return ture，后续不会再被调用。
> 2. 若是子元素 return true，作为父元素的自身每次事件来时依然会被调用，触发满足 1。

```kotlin
    override fun onInterceptTouchEvent(ev: MotionEvent?): Boolean {
        Log.i("TouchViewFirst", "onInterceptTouchEvent: ${ev?.action}")
        return super.onInterceptTouchEvent(ev)
    }
```

### onTouchEvent()

真正决定是否消费事件的地方。

* 返回 true： 表示当前View 消费了事件，不会再继续向上传播事件。
* 返回 false：表示不消费，事件会向上传递。

```kotlin
    override fun onTouchEvent(event: MotionEvent?): Boolean {
        Log.i("TouchViewFirst", "onTouchEvent: ${event?.action}")
        return super.onTouchEvent(event)
    }
```

### requestDisallowInterceptTouchEvent()

调用后会添加一个 FLAG_DISALLOW_INTERCEPT，可以禁止 父ViewGroup 拦截事件，不过 对ACTION_DOWN 事件无效。

## 事件分发相关的几个回调接口

### OnTouchListener

这个接口功能和 `onTouchEvent()` 相同，但是优先级更高。

若是设置了 `OnTouchListener`，在 `View.dispatchTouchEvent()` 函数中会先于`onTouchEvent()` 触发这个回调接口。

* 返回true，消费事件，相当于 `onTouchEvent()` 返回true。
  * 需要注意的是，此时`onTouchEvent()` 不会被调用，所以导致 OnClickListener 、OnLongClickListener不会触发。
* 返回false， 继续调用 `onTouchEvent()`。

### OnClickListener

在 `onTouchEvent()` 中 ACTION_UP 事件中会调用 `performClick()`。 这函数会判断是否存在 OnClickListener，存在则回调。

### OnLongClickListener

在 `onTouchEvent()` 中 ACTION_DOWN 事件中会发送一个 `CheckForLongPress` 延迟事件，若在指定事件内没有触发ACTION_UP、ACTION_CANCLE，或未达到判断为MOVE的距离 就会回调这个接口。



## 源码分析

这里先做一个总结：

事件序列是从 `ACTION_DOWN` 开始的，会先调用 ViewGroup自身的`onInterceptTouchEvent()` 检查是否需要拦截。

此时存在2种情况：

1. 若 ViewGroup自身拦截了 `ACTION_DOWN` 事件：那么最终会调用 `super.dispatchTouchEvent()` 然后调用自身`onTouchEvent()`，事件不会在向下传递。
   * 若 `onTouchEvent() return true`：那么后续的事件都将会被ViewGroup拦截。
   * 若 `onTouchEvent() return false`：那么会将事件向上传递回去，由上层处理。
2. 若 ViewGroup 不拦截 `ACTION_DOWN` 事件：继续分发流程。

ViewGroup不拦截 `ACTION_DOWN` 时，那么会遍历所有的child，并判断是否存在子元素消费事件。

此时又将存在2种情况：

1. 若存在子元素消费事件：mFirstTouchTarget 将被赋值，指向这个子元素，会将事件分发给这个子元素。
2. 若子元素 也不消费事件：由于没人处理事件，所有这个事件又会向上传递，最终会回调到 `Activity.onTouchEvent()` 由 Activity处理。

从上面对ACTION_DOWN事件的处理可以看出：**ACTION_DOWN 事件的作用就是用来决定由谁来处理后续的事件序列**。事件序列中后续的 ACTION_MOVE、ACTION_UP等事件的分发，是根据ACTION_DOWN 的处理流程决定的，可以概括为一下三种情况：

1. ViewGroup拦截了事件：这些后续事件由ViewGroup 处理。
2. 子元素 mFirstTouchTarget 拦截了事件：此时事件并不是无条件的都交给子元素，而是会先调用父元素的 `ViewGroup.onInterceptTouchEvent()` 来检测ViewGroup 是否需要拦截，若依然不拦截才会将事件转给子元素处理。即父控件依然可以拦截事件。
3. 没有View处理事件：事件都由 `Activity.onTouchEvent()` 来处理。



### Activity.dispatchTouchEvent()

Activity 默认会交给 PhoneWindow 来分发，若没人处理事件，则最终会交由自身的 `onTouchEvent()` 来处理。

```java
 	public boolean dispatchTouchEvent(MotionEvent ev) {
        if (ev.getAction() == MotionEvent.ACTION_DOWN) {
            // 
            onUserInteraction();
        }
        // 交由 PhoneWindow 来分发
        if (getWindow().superDispatchTouchEvent(ev)) {
            return true;
        }
        // 没人处理，则由自身处理。
        return onTouchEvent(ev);
    }
```

### ViewGroup.dispatchTouchEvent()

ViewGroup 重写了 View的 `dispatchTouchEvent()` 函数，用于处理事件分发，决定给子View还是自身。

* 首先判断父容器自身是否拦截事件。若事件是 ACTION_DOWN 或者 已经有子元素处理事件，则会调用`onInterceptTouchEvent()` 检查是否需要拦截。否则父容器不拦截。
  * 这里会受到 FLAG_DISALLOW_INTERCEPT 这个标记的影响，作用是禁止父容器拦截事件，是子View通过 `requestDisallowInterceptTouchEvent()`这个函数设置的。
* 若父容器拦截事件，则 `mFirstTouchTarget` 一定是 Null，不再分发给子View。后续事件由父容器自身处理。
* 若检测后 父容器不拦截，则会遍历子View，一个个来检测子View是否处理事件，若有则 `mFirstTouchTarget` 会被赋值，并交由这个子元素来处理事件， 且后续也不需要再遍历了。

```java
	@Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
        
        boolean handled = false;
        if (onFilterTouchEventForSecurity(ev)) {
            final int action = ev.getAction();
            final int actionMasked = action & MotionEvent.ACTION_MASK;

            // Handle an initial down.
            if (actionMasked == MotionEvent.ACTION_DOWN) {
                cancelAndClearTouchTargets(ev);
                // 这里会重置 FLAG_DISALLOW_INTERCEPT 这个标记
                // 所以 ACTION_DOWN 是一定会处理的
                resetTouchState();
            }

            // Check for interception.
            // 1. 当事件是 ACTION_DOWN
            // 2. 或者 已经有子元素处理事件。
            // 满足其中一个条件时 会调用 onInterceptTouchEvent() 检查是否需要拦截
            final boolean intercepted;
            if (actionMasked == MotionEvent.ACTION_DOWN
                    || mFirstTouchTarget != null) {
                // 判断子View是否禁用了父控件拦截, 对于 ACTION_DOWN 是拦截不了的，上面会重置state。
                final boolean disallowIntercept = (mGroupFlags & FLAG_DISALLOW_INTERCEPT) != 0;
                if (!disallowIntercept) {
                    // 允许父容器拦截，检测一下
                    intercepted = onInterceptTouchEvent(ev);
                    ev.setAction(action); // restore action in case it was changed
                } else { // 不允许
                    intercepted = false;
                }
            } else {
                // 默认为拦截，由ViewGroup处理
                intercepted = true;
            }

            if (intercepted || mFirstTouchTarget != null) {
                ev.setTargetAccessibilityFocus(false);
            }

            // Check for cancelation.
            final boolean canceled = resetCancelNextUpFlag(this)
                    || actionMasked == MotionEvent.ACTION_CANCEL;

            // Update list of touch targets for pointer down, if needed.
            final boolean isMouseEvent = ev.getSource() == InputDevice.SOURCE_MOUSE;
            final boolean split = (mGroupFlags & FLAG_SPLIT_MOTION_EVENTS) != 0
                    && !isMouseEvent;
            TouchTarget newTouchTarget = null;
            boolean alreadyDispatchedToNewTouchTarget = false;
            
            //
            if (!canceled && !intercepted) {
                // 不拦截时
                View childWithAccessibilityFocus = ev.isTargetAccessibilityFocus()
                        ? findChildWithAccessibilityFocus() : null;

                if (actionMasked == MotionEvent.ACTION_DOWN
                        || (split && actionMasked == MotionEvent.ACTION_POINTER_DOWN)
                        || actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
                    final int actionIndex = ev.getActionIndex(); // always 0 for down
                    final int idBitsToAssign = split ? 1 << ev.getPointerId(actionIndex)
                            : TouchTarget.ALL_POINTER_IDS;

                    // Clean up earlier touch targets for this pointer id in case they
                    // have become out of sync.
                    removePointersFromTouchTargets(idBitsToAssign);

                    final int childrenCount = mChildrenCount;
                    if (newTouchTarget == null && childrenCount != 0) {
                        final float x =
                                isMouseEvent ? ev.getXCursorPosition() : ev.getX(actionIndex);
                        final float y =
                                isMouseEvent ? ev.getYCursorPosition() : ev.getY(actionIndex);
                        // Find a child that can receive the event.
                        // Scan children from front to back.
                        final ArrayList<View> preorderedList = buildTouchDispatchChildList();
                        final boolean customOrder = preorderedList == null
                                && isChildrenDrawingOrderEnabled();
                        final View[] children = mChildren;
                        
                        // 这里开始遍历所有的 子元素
                        for (int i = childrenCount - 1; i >= 0; i--) {
                            final int childIndex = getAndVerifyPreorderedIndex(
                                    childrenCount, i, customOrder);
                            final View child = getAndVerifyPreorderedView(
                                    preorderedList, children, childIndex);
                            if (childWithAccessibilityFocus != null) {
                                if (childWithAccessibilityFocus != child) {
                                    continue;
                                }
                                childWithAccessibilityFocus = null;
                                i = childrenCount;
                            }
							// child是否能接收事件, 不能就直接跳过
                            if (!child.canReceivePointerEvents()
                                    || !isTransformedTouchPointInView(x, y, child, null)) {
                                ev.setTargetAccessibilityFocus(false);
                                continue;
                            }
							// 先看看是否已经存在消费事件的View。找不到就是 Null
                            newTouchTarget = getTouchTarget(child);
                            if (newTouchTarget != null) { // 找到了就直接跳出循环。
                                // Child is already receiving touch within its bounds.
                                // Give it the new pointer in addition to the ones it is handling.
                                newTouchTarget.pointerIdBits |= idBitsToAssign;
                                break;
                            }
                            resetCancelNextUpFlag(child);
                            
                            // 不存在已消费事件的View，将事件传给child，判断一下child是否消费事件。
                            if (dispatchTransformedTouchEvent(ev, false, child, idBitsToAssign)) {
                                // Child wants to receive touch within its bounds.
                                mLastTouchDownTime = ev.getDownTime();
                                if (preorderedList != null) {
                                    // childIndex points into presorted list, find original index
                                    for (int j = 0; j < childrenCount; j++) {
                                        if (children[childIndex] == mChildren[j]) {
                                            mLastTouchDownIndex = j;
                                            break;
                                        }
                                    }
                                } else {
                                    mLastTouchDownIndex = childIndex;
                                }
                                mLastTouchDownX = ev.getX();
                                mLastTouchDownY = ev.getY();
                                // addTouchTarget()内部会将 Child 赋值给 mFirstTouchTarget.child
                                newTouchTarget = addTouchTarget(child, idBitsToAssign);
                                alreadyDispatchedToNewTouchTarget = true;
                                break;
                            }

                            // The accessibility focus didn't handle the event, so clear
                            // the flag and do a normal dispatch to all children.
                            ev.setTargetAccessibilityFocus(false);
                        }
                        if (preorderedList != null) preorderedList.clear();
                    }

                    if (newTouchTarget == null && mFirstTouchTarget != null) {
                        // Did not find a child to receive the event.
                        // Assign the pointer to the least recently added target.
                        newTouchTarget = mFirstTouchTarget;
                        while (newTouchTarget.next != null) {
                            newTouchTarget = newTouchTarget.next;
                        }
                        newTouchTarget.pointerIdBits |= idBitsToAssign;
                    }
                }
            }
			
            // Dispatch to touch targets.
            // mFirstTouchTarget为空的场景，表示没有子View消费事件 或者 父容器拦截了事件
            if (mFirstTouchTarget == null) {
                // No touch targets so treat this as an ordinary view.
                // 调用 dispatchTransformedTouchEvent()
                handled = dispatchTransformedTouchEvent(ev, canceled, null,
                        TouchTarget.ALL_POINTER_IDS);
            } else {
                TouchTarget predecessor = null;
                TouchTarget target = mFirstTouchTarget;
                while (target != null) {
                    final TouchTarget next = target.next;
                    if (alreadyDispatchedToNewTouchTarget && target == newTouchTarget) {
                        handled = true;
                    } else {
                        final boolean cancelChild = resetCancelNextUpFlag(target.child)
                                || intercepted;
                        if (dispatchTransformedTouchEvent(ev, cancelChild,
                                target.child, target.pointerIdBits)) {
                            handled = true;
                        }
                        if (cancelChild) {
                            if (predecessor == null) {
                                mFirstTouchTarget = next;
                            } else {
                                predecessor.next = next;
                            }
                            target.recycle();
                            target = next;
                            continue;
                        }
                    }
                    predecessor = target;
                    target = next;
                }
            }

            // Update list of touch targets for pointer up or cancel, if needed.
            if (canceled
                    || actionMasked == MotionEvent.ACTION_UP
                    || actionMasked == MotionEvent.ACTION_HOVER_MOVE) {
                resetTouchState();
            } else if (split && actionMasked == MotionEvent.ACTION_POINTER_UP) {
                final int actionIndex = ev.getActionIndex();
                final int idBitsToRemove = 1 << ev.getPointerId(actionIndex);
                removePointersFromTouchTargets(idBitsToRemove);
            }
        }

        if (!handled && mInputEventConsistencyVerifier != null) {
            mInputEventConsistencyVerifier.onUnhandledEvent(ev, 1);
        }
        return handled;
    }
```

### ViewGroup.dispatchTransformedTouchEvent()

* 若 `child != null` 表示**存在子View消费事件，则首先会将事件进行xy坐标转换，然后发送给子View处理**。。
* 若 `child == null`，表示 **ViewGroup自身拦截事件或没有子View消费事件，由ViewGroup自身处理事件**，调用ViewGroup自身的`super.dispatchTouchEvent()`来分发事件，内部会调用 父容器自身的 `super.onTouchEvent() `来继续处理事件。

> 这里函数中存在 坐标转换的逻辑：即存在子View消费事件时 会将 MotionEvent的x,y进行转换，转换到以child左上角为原点(0, 0)的坐标系上
>
> 关于child参数的取值：
>
> * `ViewGroup.onInterceptTouchEvent() return true` 时：child == null。
> * 不存在子View消费事件时：child == null。
> * 存在子View消费事件时：child == `mFirstTouchTarget.child` 即消费事件的子View 。

```java
private boolean dispatchTransformedTouchEvent(MotionEvent event, boolean cancel,
            View child, int desiredPointerIdBits) {
        final boolean handled;

        final int oldAction = event.getAction();
		// 发送 ACTION_CANCEL 事件
        if (cancel || oldAction == MotionEvent.ACTION_CANCEL) {
            event.setAction(MotionEvent.ACTION_CANCEL);
            if (child == null) {
                handled = super.dispatchTouchEvent(event);
            } else {
                handled = child.dispatchTouchEvent(event);
            }
            event.setAction(oldAction);
            return handled;
        }
        final int oldPointerIdBits = event.getPointerIdBits();
        final int newPointerIdBits = oldPointerIdBits & desiredPointerIdBits;
        if (newPointerIdBits == 0) {
            return false;
        }

        final MotionEvent transformedEvent;
        if (newPointerIdBits == oldPointerIdBits) {
            if (child == null || child.hasIdentityMatrix()) {
                if (child == null) {
                    handled = super.dispatchTouchEvent(event);
                } else {
                    final float offsetX = mScrollX - child.mLeft;
                    final float offsetY = mScrollY - child.mTop;
                    event.offsetLocation(offsetX, offsetY);
                    handled = child.dispatchTouchEvent(event);
                    event.offsetLocation(-offsetX, -offsetY);
                }
                return handled;
            }
            transformedEvent = MotionEvent.obtain(event);
        } else {
            transformedEvent = event.split(newPointerIdBits);
        }

        // Perform any necessary transformations and dispatch.
        if (child == null) {
            // child==null表示 View Group自身拦截事件，或没有子View消费事件。
            // 调用父容器的 view.dispatchTouchEvent()，内部会调用 onTouchEvent() 来判断是否处理事件。
            handled = super.dispatchTouchEvent(transformedEvent);
        } else {
            // child!=null，表示View不拦截，child就是遍历到的子View
            // 这里转换了坐标, 减去了 scroll偏移
            // 即转换到了 child左上角为原点(0, 0)的坐标系上。
            final float offsetX = mScrollX - child.mLeft;
            final float offsetY = mScrollY - child.mTop;
            transformedEvent.offsetLocation(offsetX, offsetY);
            if (! child.hasIdentityMatrix()) {
                transformedEvent.transform(child.getInverseMatrix());
            }
            // 分发给子元素，判断子元素是否处理事件。
            handled = child.dispatchTouchEvent(transformedEvent);
        }

        // Done.
        transformedEvent.recycle();
        return handled;
    }
```



### View.dispatchTouchEvent()

View的 `dispatchTouchEvent()` 是处理View自身处理事件分发的入口：

* 优先处理 `onTouchListener` 监听，若返回 true 则会消费事件，那么后面的 `onTouchEvent()` 不会被触发。
* 若事件未被消费则会调用 `onTouchEvent()`。

```java
public boolean dispatchTouchEvent(MotionEvent event) {
        // If the event should be handled by accessibility focus first.
        if (event.isTargetAccessibilityFocus()) {
            // We don't have focus or no virtual descendant has it, do not handle the event.
            if (!isAccessibilityFocusedViewOrHost()) {
                return false;
            }
            // We have focus and got the event, then use normal event dispatch.
            event.setTargetAccessibilityFocus(false);
        }
        boolean result = false;

        if (mInputEventConsistencyVerifier != null) {
            mInputEventConsistencyVerifier.onTouchEvent(event, 0);
        }

        final int actionMasked = event.getActionMasked();
        if (actionMasked == MotionEvent.ACTION_DOWN) {
            // Defensive cleanup for new gesture
            stopNestedScroll();
        }

        if (onFilterTouchEventForSecurity(event)) {
            if ((mViewFlags & ENABLED_MASK) == ENABLED && handleScrollBarDragging(event)) {
                result = true;
            }
            //noinspection SimplifiableIfStatement
            ListenerInfo li = mListenerInfo;
            // 优先处理 onTouchListener。
            // 若返回 true 则会消费事件，那么后面的 onTouchEvent() 不会被触发
            if (li != null && li.mOnTouchListener != null
                    && (mViewFlags & ENABLED_MASK) == ENABLED
                    && li.mOnTouchListener.onTouch(this, event)) {
                result = true;
            }
			// 调用 onTouchEvent().
            if (!result && onTouchEvent(event)) {
                result = true;
            }
        }

        if (!result && mInputEventConsistencyVerifier != null) {
            mInputEventConsistencyVerifier.onUnhandledEvent(event, 0);
        }

        // Clean up after nested scrolls if this is the end of a gesture;
        // also cancel it if we tried an ACTION_DOWN but we didn't want the rest
        // of the gesture.
        if (actionMasked == MotionEvent.ACTION_UP ||
                actionMasked == MotionEvent.ACTION_CANCEL ||
                (actionMasked == MotionEvent.ACTION_DOWN && !result)) {
            stopNestedScroll();
        }

        return result;
    }
```



### View.onTouchEvent()

View自身真正消费事件地方：

* 首先判断View是否可点击、可用等状态。
* 根据 MotionEvent，来处理 单击和 长按。
  * 长按：会 postDelayed一个 longClick的事件。一定事件内未抬起或滑动 则会被触发。

```java
public boolean onTouchEvent(MotionEvent event) {
    final float x = event.getX();
    final float y = event.getY();
    final int viewFlags = mViewFlags;
    final int action = event.getAction();

    // 判断View是否可以点击
    final boolean clickable = ((viewFlags & CLICKABLE) == CLICKABLE
                               || (viewFlags & LONG_CLICKABLE) == LONG_CLICKABLE)
        || (viewFlags & CONTEXT_CLICKABLE) == CONTEXT_CLICKABLE;
	// 判断View是否可用
    if ((viewFlags & ENABLED_MASK) == DISABLED
        && (mPrivateFlags4 & PFLAG4_ALLOW_CLICK_WHEN_DISABLED) == 0) {
        if (action == MotionEvent.ACTION_UP && (mPrivateFlags & PFLAG_PRESSED) != 0) {
            setPressed(false);
        }
        mPrivateFlags3 &= ~PFLAG3_FINGER_DOWN;
        return clickable;
    }
    if (mTouchDelegate != null) {
        if (mTouchDelegate.onTouchEvent(event)) {
            return true;
        }
    }

    // 处理 点击事件
    if (clickable || (viewFlags & TOOLTIP) == TOOLTIP) {
        switch (action) {
            case MotionEvent.ACTION_UP:
                mPrivateFlags3 &= ~PFLAG3_FINGER_DOWN;
                if ((viewFlags & TOOLTIP) == TOOLTIP) {
                    handleTooltipUp();
                }
                if (!clickable) { // 不可点击移除回调
                    removeTapCallback();
                    removeLongPressCallback();
                    mInContextButtonPress = false;
                    mHasPerformedLongPress = false;
                    mIgnoreNextUpEvent = false;
                    break;
                }
                boolean prepressed = (mPrivateFlags & PFLAG_PREPRESSED) != 0;
                if ((mPrivateFlags & PFLAG_PRESSED) != 0 || prepressed) {
                    // take focus if we don't have it already and we should in
                    // touch mode.
                    boolean focusTaken = false;
                    if (isFocusable() && isFocusableInTouchMode() && !isFocused()) {
                        focusTaken = requestFocus();
                    }

                    if (prepressed) {
                        // The button is being released before we actually
                        // showed it as pressed.  Make it show the pressed
                        // state now (before scheduling the click) to ensure
                        // the user sees it.
                        setPressed(true, x, y);
                    }

                    if (!mHasPerformedLongPress && !mIgnoreNextUpEvent) {
                        // This is a tap, so remove the longpress check
                        // 是点击事件则将长按事件移除
                        removeLongPressCallback();

                        // Only perform take click actions if we were in the pressed state
                        if (!focusTaken) {
                            // Use a Runnable and post this rather than calling
                            // performClick directly. This lets other visual state
                            // of the view update before click actions start.
                            if (mPerformClick == null) {
                                mPerformClick = new PerformClick();
                            }
                            if (!post(mPerformClick)) {
                                performClickInternal();
                            }
                        }
                    }

                    if (mUnsetPressedState == null) {
                        mUnsetPressedState = new UnsetPressedState();
                    }

                    if (prepressed) {
                        postDelayed(mUnsetPressedState,
                                    ViewConfiguration.getPressedStateDuration());
                    } else if (!post(mUnsetPressedState)) {
                        // If the post failed, unpress right now
                        mUnsetPressedState.run();
                    }

                    removeTapCallback();
                }
                mIgnoreNextUpEvent = false;
                break;

            case MotionEvent.ACTION_DOWN:
                // 这里会 postDelayed一个 longClick的事件。
                // 一定事件内未抬起或滑动 则会被触发
                if (event.getSource() == InputDevice.SOURCE_TOUCHSCREEN) {
                    mPrivateFlags3 |= PFLAG3_FINGER_DOWN;
                }
                mHasPerformedLongPress = false;

                if (!clickable) {
                    checkForLongClick(
                        ViewConfiguration.getLongPressTimeout(),
                        x,
                        y,
                        TOUCH_GESTURE_CLASSIFIED__CLASSIFICATION__LONG_PRESS);
                    break;
                }

                if (performButtonActionOnTouchDown(event)) {
                    break;
                }

                // Walk up the hierarchy to determine if we're inside a scrolling container.
                boolean isInScrollingContainer = isInScrollingContainer();

                // For views inside a scrolling container, delay the pressed feedback for
                // a short period in case this is a scroll.
                if (isInScrollingContainer) {
                    mPrivateFlags |= PFLAG_PREPRESSED;
                    if (mPendingCheckForTap == null) {
                        mPendingCheckForTap = new CheckForTap();
                    }
                    mPendingCheckForTap.x = event.getX();
                    mPendingCheckForTap.y = event.getY();
                    postDelayed(mPendingCheckForTap, ViewConfiguration.getTapTimeout());
                } else {
                    // Not inside a scrolling container, so show the feedback right away
                    setPressed(true, x, y);
                    checkForLongClick(
                        ViewConfiguration.getLongPressTimeout(),
                        x,
                        y,
                        TOUCH_GESTURE_CLASSIFIED__CLASSIFICATION__LONG_PRESS);
                }
                break;

            case MotionEvent.ACTION_CANCEL:
                if (clickable) {
                    setPressed(false);
                }
                removeTapCallback();
                removeLongPressCallback();
                mInContextButtonPress = false;
                mHasPerformedLongPress = false;
                mIgnoreNextUpEvent = false;
                mPrivateFlags3 &= ~PFLAG3_FINGER_DOWN;
                break;

            case MotionEvent.ACTION_MOVE:
                if (clickable) {
                    drawableHotspotChanged(x, y);
                }

                final int motionClassification = event.getClassification();
                final boolean ambiguousGesture =
                    motionClassification == MotionEvent.CLASSIFICATION_AMBIGUOUS_GESTURE;
                int touchSlop = mTouchSlop;
                if (ambiguousGesture && hasPendingLongPressCallback()) {
                    if (!pointInView(x, y, touchSlop)) {
                        // The default action here is to cancel long press. But instead, we
                        // just extend the timeout here, in case the classification
                        // stays ambiguous.
                        removeLongPressCallback();
                        long delay = (long) (ViewConfiguration.getLongPressTimeout()
                                             * mAmbiguousGestureMultiplier);
                        // Subtract the time already spent
                        delay -= event.getEventTime() - event.getDownTime();
                        checkForLongClick(
                            delay,
                            x,
                            y,
                            TOUCH_GESTURE_CLASSIFIED__CLASSIFICATION__LONG_PRESS);
                    }
                    touchSlop *= mAmbiguousGestureMultiplier;
                }

                // Be lenient about moving outside of buttons
                if (!pointInView(x, y, touchSlop)) {
                    // Outside button
                    // Remove any future long press/tap checks
                    removeTapCallback();
                    removeLongPressCallback();
                    if ((mPrivateFlags & PFLAG_PRESSED) != 0) {
                        setPressed(false);
                    }
                    mPrivateFlags3 &= ~PFLAG3_FINGER_DOWN;
                }

                final boolean deepPress =
                    motionClassification == MotionEvent.CLASSIFICATION_DEEP_PRESS;
                if (deepPress && hasPendingLongPressCallback()) {
                    // process the long click action immediately
                    removeLongPressCallback();
                    checkForLongClick(
                        0 /* send immediately */,
                        x,
                        y,
                        TOUCH_GESTURE_CLASSIFIED__CLASSIFICATION__DEEP_PRESS);
                }

                break;
        }

        return true;
    }

    return false;
}
```





## 事件分发场景分析

存在三个View：`TouchViewFirst`、`TouchViewSecond`、`TouchViewThird`。

`TouchViewFirst` 是最外层，`TouchViewThird` 在最里层。

```xml
	<com.zaze.demo.component.customview.TouchViewFirst
        android:layout_width="match_parent"
        android:layout_height="200dp"
        android:padding="10dp"
        android:background="@color/red"
        android:gravity="center"
        android:orientation="vertical">

        <com.zaze.demo.component.customview.TouchViewSecond
            android:layout_width="300dp"
            android:layout_height="match_parent"
            android:gravity="center"
            android:padding="10dp"
            android:background="@color/yellow"
            android:orientation="vertical">

            <com.zaze.demo.component.customview.TouchViewThird
                android:layout_width="200dp"
                android:layout_height="match_parent"
                android:background="@color/blue"
                android:orientation="vertical" />
            
        </com.zaze.demo.component.customview.TouchViewSecond>

    </com.zaze.demo.component.customview.TouchViewFirst>
```

### 通过 onInterceptTouchEvent() 拦截事件

#### onTouchEvent() return false

我们测试 `TouchViewSecond` 拦截了事件，但是在 `onTouchEvent()` 中不消费这个事件的场景：

![image_1e49320151m5r1g9l16kg2076k9.png-16.7kB][3]

```kotlin
class TouchViewSecond : LinearLayout {
    override fun onInterceptTouchEvent(ev: MotionEvent?): Boolean {
        Log.d("TouchViewSecond", "onInterceptTouchEvent: ${ev?.action}")
        // 拦截
        return true
    }

    override fun onTouchEvent(event: MotionEvent?): Boolean {
        Log.d("TouchViewSecond", "onTouchEvent: ${event?.action}")
        // 不消费事件
        return super.onTouchEvent(event)
    }
}
```





#### onTouchEvent() return true

![image_1e493diofg821ovf18o21lcg15p5m.png-24.2kB][4]

```kotlin
    override fun onInterceptTouchEvent(ev: MotionEvent?): Boolean {
        Log.d("TouchViewSecond", "onInterceptTouchEvent: ${ev?.action}")
        return true
    }

    override fun onTouchEvent(event: MotionEvent?): Boolean {
        Log.d("TouchViewSecond", "onTouchEvent: ${event?.action}")
        return true
    }
```



### 仅重写OnTouchEvent() 

这里分析子元素仅重写了 `onTouchEenet()` 函数的场景，即 onInterceptTouchEvent() 返回 false 不拦截。

#### child.OnTouchEvent() 返回 false

由于所有的child的都不处理事件，那么 `DecorView` 将由于不存在 `mFirstTouchTarget` 而不再分发事件序列的后续事件，后续的所有事件都将只回调给 `Activity.onTouchEvent()`。



![image_1e4959pb5fkgtmf1e17cev16js1g.png-27.2kB][1]



```sequence
Activiy->Activiy: dispatchTouchEvent() : MotionEvent.ACTION_xx
Activiy->PhoneWindow:
PhoneWindow->PhoneWindow: superDispatchTouchEvent()
PhoneWindow->DecorView:
DecorView->DecorView: superDispatchTouchEvent()
DecorView->ViewGroup:
ViewGroup->ViewGroup: dispatchTouchEvent()
ViewGroup-->ViewGroup: onInterceptTouchEvent()
ViewGroup->ViewGroup: dispatchTransformedTouchEvent()
ViewGroup->ViewGroup N: 调用child.dispatchTouchEvent()
ViewGroup N->ViewGroup N: dispatchTouchEvent()
ViewGroup N-->ViewGroup N: onInterceptTouchEvent()
ViewGroup N->ViewGroup N: dispatchTransformedTouchEvent()
ViewGroup N->View: 调用child.dispatchTouchEvent()
View->View: dispatchTouchEvent()
View->View: onTouchEvent()
View-->ViewGroup N: return false mFirstTouchTargetis null
ViewGroup N->ViewGroup N: dispatchTransformedTouchEvent() child is null
ViewGroup N->ViewGroup N: super.dispatchTouchEvent()
ViewGroup N->ViewGroup N: onTouchEvent()
ViewGroup N-->ViewGroup: return false
ViewGroup->ViewGroup: dispatchTransformedTouchEvent() child is null
ViewGroup->ViewGroup: super.dispatchTouchEvent()
ViewGroup->ViewGroup: onTouchEvent()
ViewGroup-->DecorView:return false
DecorView-->PhoneWindow:return false
PhoneWindow-->Activiy:return false
Activiy->Activiy:onTouchEvent()
```

#### child.OnTouchEvent() 消费 ACTION_DOWN

存在条件：`child.OnTouchEvent()` 接收到 ACTION_DONW 时 返回 true。

- 此时 child 将被赋值给 mFirstTouchTarget ， alreadyDispatchedToNewTouchTarget = true。后续将由 mFirstTouchTarget 来分发事件。
- 即使 childView 对事件序列的后续事件 不消费, `parentView.onTouchEvent()`也不会被执行

![image_1e493ogb01bem1eds1b88nn1vts13.png-33.8kB][2]

源码中相关的逻辑

```java
public boolean dispatchTouchEvent(MotionEvent ev) {
    // ...........
    
    // 一开始没有 mFirstTouchTarget
    if (mFirstTouchTarget == null) {
        // child == null
        handled = dispatchTransformedTouchEvent(ev, canceled, null,
                TouchTarget.ALL_POINTER_IDS);
    } else {
        // Dispatch to touch targets, excluding the new touch target if we already
        // dispatched to it.  Cancel touch targets if necessary.
        TouchTarget predecessor = null;
        TouchTarget target = mFirstTouchTarget;
        while (target != null) {
            final TouchTarget next = target.next;
            if (alreadyDispatchedToNewTouchTarget && target == newTouchTarget) {
                // 被消费时执行
                handled = true;
            } else {
                final boolean cancelChild = resetCancelNextUpFlag(target.child)
                        || intercepted;
                // 若intercepted 将走这边
                if (dispatchTransformedTouchEvent(ev, cancelChild,
                        target.child, target.pointerIdBits)) {
                    handled = true;
                }
                if (cancelChild) {
                    if (predecessor == null) {
                        mFirstTouchTarget = next;
                    } else {
                        predecessor.next = next;
                    }
                    target.recycle();
                    target = next;
                    continue;
                }
            }
            predecessor = target;
            target = next;
        }
    }
}
```



```sequence
Activiy->Activiy: dispatchTouchEvent() MotionEvent.ACTION_DOWN
Activiy->PhoneWindow:
PhoneWindow->PhoneWindow: superDispatchTouchEvent()
PhoneWindow->DecorView:
DecorView->DecorView: superDispatchTouchEvent()
DecorView->ViewGroup:
ViewGroup->ViewGroup: dispatchTouchEvent()
ViewGroup-->ViewGroup: onInterceptTouchEvent()
ViewGroup->ViewGroup: dispatchTransformedTouchEvent()
ViewGroup->ViewGroup N: 调用child.dispatchTouchEvent()
ViewGroup N->ViewGroup N: dispatchTouchEvent()
ViewGroup N-->ViewGroup N: onInterceptTouchEvent()
ViewGroup N->ViewGroup N: dispatchTransformedTouchEvent()
ViewGroup N->View: 调用child.dispatchTouchEvent()
View->View: dispatchTouchEvent()
View->View: onTouchEvent()
View-->ViewGroup N: return true
ViewGroup N->ViewGroup N: addTouchTarget() 
Note right of ViewGroup N: mFirstTouchTarget = child
Note right of ViewGroup N: alreadyDispatchedToNewTouchTarget = true
ViewGroup N-->ViewGroup: return true
ViewGroup->ViewGroup: addTouchTarget()  mFirstTouchTarget = child
Note right of ViewGroup: mFirstTouchTarget = child
Note right of ViewGroup: alreadyDispatchedToNewTouchTarget = true
ViewGroup-->DecorView:return true
DecorView-->PhoneWindow:return true
PhoneWindow-->Activiy:return true

Activiy->Activiy: dispatchTouchEvent()  MotionEvent.ACTION_UP
Activiy->PhoneWindow:
PhoneWindow->PhoneWindow: superDispatchTouchEvent()
PhoneWindow->DecorView:
DecorView->DecorView: superDispatchTouchEvent()
DecorView->ViewGroup:
ViewGroup->ViewGroup: dispatchTouchEvent()
ViewGroup-->ViewGroup: onInterceptTouchEvent()
ViewGroup->ViewGroup: dispatchTransformedTouchEvent()
ViewGroup->ViewGroup N: 调用target.child.dispatchTouchEvent()
Note right of ViewGroup: target = mFirstTouchTarget
ViewGroup N->ViewGroup N: dispatchTouchEvent()
ViewGroup N-->ViewGroup N: onInterceptTouchEvent()
ViewGroup N->ViewGroup N: dispatchTransformedTouchEvent()
ViewGroup N->View: 调用target.child.dispatchTouchEvent()
Note right of ViewGroup N: target = mFirstTouchTarget
View->View: dispatchTouchEvent()
View->View: onTouchEvent()
View-->ViewGroup N: return
ViewGroup N-->ViewGroup: return
ViewGroup-->DecorView:return
DecorView-->PhoneWindow:return
PhoneWindow-->Activiy:return
```



### 重写dispatchTouchEvent()

如果重写时去除了默认的实现，无论返回的时 true 或者 false，所有的child 包括自己 的事件分发流程都将被拦截中断。即自身的 `onInterceptTouchEvent()` 和 `onTouch()` ，以及子元素的所有事件函数都将不会被自动调用，需要我们手动处理。

```kotlin
override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
    // onInterceptTouchEvent 不执行
    // onTouchEvent 不执行
    // 需要自己写分发逻辑
    return true or false
}
```

### 

## Activity接收Event事件

Activity 会首先收到 事件，然后 调用 `dispatchTouchEvent()` 开始分发事件。

```sequence
WindowInputEventReceiver->WindowInputEventReceiver:dispatchInputEvent()
WindowInputEventReceiver->WindowInputEventReceiver:onInputEvent()
WindowInputEventReceiver->ViewRootImpl:enqueueInputEvent()
ViewRootImpl->ViewRootImpl:doProcessInputEvents()
ViewRootImpl->...:
...->ViewPostImeInputStage:
ViewPostImeInputStage->ViewPostImeInputStage:processPointerEvent
ViewPostImeInputStage->DecorView:mView.dispatchPointerEvent(event)
DecorView->DecorView:dispatchPointerEvent()
DecorView->DecorView:dispatchTouchEvent()
DecorView->WindowCallbackWrapper: mWindow.getCallback()dispatchTouchEvent(ev)
WindowCallbackWrapper->Activiy: mWrapped.dispatchTouchEvent(event)
Activiy->Activiy:dispatchTouchEvent()
```




[1]: http://static.zybuluo.com/zaze/1aoi79uy3piot55tzrs8lvpv/image_1e4959pb5fkgtmf1e17cev16js1g.png
[2]: http://static.zybuluo.com/zaze/24m7ey1edqwcb6vgf3rg8t0d/image_1e493ogb01bem1eds1b88nn1vts13.png
[3]: http://static.zybuluo.com/zaze/cw156c193y0996g0qi8u94my/image_1e49320151m5r1g9l16kg2076k9.png
[4]: http://static.zybuluo.com/zaze/k1s58codza8190kywwqj3zgb/image_1e493diofg821ovf18o21lcg15p5m.png