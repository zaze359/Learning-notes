# RecyclerView

RecyclerView 可以实现列表(List)、表格(Grid)、流式布局(StaggeredGrid) 这几种布局效果。

[自定义 RecyclerView  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/ui/layout/recyclerview-custom?hl=zh-cn)

[Recyclerview  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/jetpack/androidx/releases/recyclerview?hl=zh_cn)

## 如何使用

* ViewHolder：表示一个Item的视图。
* Adapter：负责将ViewHolder进行数据绑定。
* LayoutManager：负责视图的测量、布局。

### 1. 创建Adapter 和 ViewHolder

```kotlin
class TestAdapter(private val dataList: List<String>) : RecyclerView.Adapter<TestAdapter.TestViewHolder>() {

    /**
     * 创建 ViewHolder
     */
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TestViewHolder {
        val itemView = LayoutInflater.from(parent.context).inflate(R.layout.item_test, parent,false)
        return TestViewHolder(itemView)
    }

    /**
     * 返回 item数量
     */
    override fun getItemCount(): Int {
        return dataList.size
    }

    /**
     *  ViewHolder进行数据绑定。
     */
    override fun onBindViewHolder(holder: TestViewHolder, position: Int) {
        holder.itemNameTv.text = dataList[position]
    }


    class TestViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val itemNameTv: TextView = itemView.findViewById(R.id.item_name_tv)
    }
}
```

### 2.  绑定 Adapter 和 LayoutManager

```kotlin
val adapter = DemoAdapter(list) // 创建 Adapter 并填充数据
val manager = LinearLayoutManager(context) // 设置布局管理器：列表布局
binding.demoRecyclerView.layoutManager = manager 
binding.demoRecyclerView.adapter = adapter
```



## LayoutManager：布局管理器

*   GridLayoutManager ： 表格布局。

*   LinearLayoutManager ： 线性布局。

*   StaggeredGridLayoutManager：流式布局。

## ItemDecoration：装饰器

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
// 位于内容下层，在内容前绘制
onDraw(Canvas c, RecyclerView parent, State state) 

// 位于内容上层，在内容后绘制
onDrawOver(Canvas c, RecyclerView parent, State state)
```



## 缓存层级

RecyclerView 提供了很强大的缓存机制，**缓存机制的缓存的实际是 ViewHolder**。

通过 Recycler 这个类来负责缓存。

```java
public final class Recycler {
    // Scrap
    final ArrayList<ViewHolder> mAttachedScrap = new ArrayList<>();
    ArrayList<ViewHolder> mChangedScrap = null;

    // CachedView，保存刚移出屏幕的ViewHolder，帮助在来回滚动场景中是实现快速复用。
    final ArrayList<ViewHolder> mCachedViews = new ArrayList<ViewHolder>();
    
    // RecycledViewPool是最后一级缓存，其他缓存不接收时缓存在这里 
    RecycledViewPool mRecyclerPool;
    
	// 供开发者自定义的缓存类
    private ViewCacheExtension mViewCacheExtension;
    
    static final int DEFAULT_CACHE_SIZE = 2;
    private int mRequestedCacheMax = DEFAULT_CACHE_SIZE; // 2
    // CachedView最大个数
    int mViewCacheMax = DEFAULT_CACHE_SIZE;// 2
}
```

### Scrap

scrap 意为废缓存，是**重新布局期间的临时缓存，缓存的是在重新布局期间位于在屏幕区域的ViewHolder**，布局完成后这层缓存会被清空。它**和滑动时的缓存复用没有关系**。其他的Item是保存在 CachedViews 和 RecyclerViewPool中。

在 Recycler 类中 声明了两个 scrap，mAttachedScrap 和 mChangedScrap，它们都是 ViewHolder列表：`ArrayList<ViewHolder> ` 

* **mAttachedScrap**：重新布局期间那些没有发生变化的 ViewHolder。使用时不必重新进行数据绑定。
  * ViewHolder条件：被移除并且无效的 或 未发生变化的 或 可重用的。
* **mChangedScrap**：重新布局期间发生改变的 ViewHolder。
  * 复用时需要重新调用 `Adapter.onBindViewHolder()` 进行数据绑定。

### CachedViews

> ``final ArrayList<ViewHolder> mCachedViews = new ArrayList<ViewHolder>();``

**CachedView 作用于是RecyclerView滑动期间，会将刚刚离开屏幕的ViewHolder缓存，最多保存2个**。若超出限制，则会将最早缓存的ViewHolder加入到 RecyclerViewPool中，然后从CachedViews中移除，最后将再将刚离开屏幕的ViewHolder加入到CachedViews 中。

这个缓存是用于优化的经常来回滑动的场景：

* 首先屏幕向上滑动，itemA 移动到了屏幕外，那么 itemA 加入到CacheView中。
* 接着我们向下滑动，itemA 重新进入屏幕中，此时会根据 position 进行比对，若符合则会直接从CacheView中得到itemA 来进行复用，且不用重新进行数据绑定。
  * `getScrapOrHiddenOrCachedHolderForPosition()`

### ViewCacheExtension

这个类是扩展给我们开发者使用的缓存类，默认为 null，它位于 CachedView 和 RecyclerViewPool之间。

### RecyclerViewPool

这是最后一级的缓存，在上述缓存都不接收时，会被加入到 RecyclerViewPool 中。当然 这层缓存也是存在容量限制的。

* 缓存时会根据 itemType 来将 ViewHolder进行分组。
* 仅保存了ViewHolder对象，并没有保存数据。复用时需要重新调用 `Adapter.onBindViewHolder()` 进行数据绑定

```java
public static class RecycledViewPool {
    // 每个 ScrapData 的大小，即每种ItemType分别可以缓存5个。
    private static final int DEFAULT_MAX_SCRAP = 5;
    // 以itemType来区分。
    SparseArray<ScrapData> mScrap = new SparseArray<>();
    //
    static class ScrapData {
        // itemType下的ViewHolder
        final ArrayList<ViewHolder> mScrapHeap = new ArrayList<>();
        int mMaxScrap = DEFAULT_MAX_SCRAP;
        long mCreateRunningAverageNs = 0;
        long mBindRunningAverageNs = 0;
    }
}
```

## 数据更新

### notifyDataSetChanged()

**调用这个函数后 会导致所有子View刷新**。

这个函数调用后会**将所有已知的视图标记为Invalid**，最后会被**回收到RecyclerViewPoll中**，复用时需要重新进程数据绑定。由于RecyclerViewPoll容量是存在上限的，每种ItemType 5个，所以超出的ViewHolder就需要重新创建。

```java
    void markKnownViewsInvalid() {
        final int childCount = mChildHelper.getUnfilteredChildCount();
        for (int i = 0; i < childCount; i++) {
            final ViewHolder holder = getChildViewHolderInt(mChildHelper.getUnfilteredChildAt(i));
            if (holder != null && !holder.shouldIgnore()) {
                holder.addFlags(ViewHolder.FLAG_UPDATE | ViewHolder.FLAG_INVALID);
            }
        }
        markItemDecorInsetsDirty();
        mRecycler.markKnownViewsInvalid();
    }
```



### notifyItemChanged(int position)

**指定更新某一个Item刷新**。

这里涉及的缓存是scrap 缓存：mAttachedScrap，mChangedScrap，分别对应没变化和变化。前者复用时不需要重新绑定，后者需要重新绑定。



---

## 添加布局管理器源码分析

通过 `RecyclerView.setLayoutManager()` 来设置布局管理，它内部流程如下：

* 判断是否和之前的布局管理器一致，是就直接返回，不必处理。是新的布局管理器就继续往下。
* 若已经存在布局管理器，会先进行初始化重置操作，并且解绑。
  * 将所有的View解绑(detach)并移除(remove)，然后利用缓存机制回收。
  * 移除所有 Scrap View 并且清空 mAttachedScrap 和 mChangedScrap 缓存。
  * 清空 mAttachedScrap和CachedViews 缓存。
  * 将 当前的LayoutManager 和 RecyclerView 的解绑。
* 将新的LayoutManager 和 RecyclerView 进行关联。唯一绑定。
* 调用 `requestLayout()` 重新布局绘制。

```java

	// 当前布局管理器
	LayoutManager mLayout;
	// 
	final Recycler mRecycler = new Recycler();

	public void setLayoutManager(@Nullable LayoutManager layout) {
        // 相同的布局管理器 直接返回
        if (layout == mLayout) {
            return;
        }
        // 停止滚动
        stopScroll();
        
        if (mLayout != null) {
            // 已存在布局管理器，执行一些状态重置的操作
            // end all running animations，结束所有动画
            if (mItemAnimator != null) {
                mItemAnimator.endAnimations();
            }
            // RecyclerView 解绑并移除所有View，然后使用mRecycler回收到缓存中
            mLayout.removeAndRecycleAllViews(mRecycler);
            // 移除所有Scrap View并且清空 Scrap缓存：mAttachedScrap 和 mChangedScrap
            mLayout.removeAndRecycleScrapInt(mRecycler);
            // 清空 mAttachedScrap和CachedViews 缓存
            mRecycler.clear();
			
            if (mIsAttached) {
                mLayout.dispatchDetachedFromWindow(this, mRecycler);
            }
            // 取消LayoutManager 和 RecyclerView 的关联。
            mLayout.setRecyclerView(null);
            mLayout = null;
        } else {
            // 当前不存在布局管理，直接清空 Recycler缓存即可。
            mRecycler.clear();
        }
        // this is just a defensive measure for faulty item animators.
        mChildHelper.removeAllViewsUnfiltered();
        // 设置新的布局管理器
        mLayout = layout;
        if (layout != null) {
            // 一个LayoutManager 只能关联一个 RecyclerView，若已关联则报错
            if (layout.mRecyclerView != null) {
                throw new IllegalArgumentException("LayoutManager " + layout
                        + " is already attached to a RecyclerView:"
                        + layout.mRecyclerView.exceptionLabel());
            }
            // 未关联则关联。
            mLayout.setRecyclerView(this);
            if (mIsAttached) {
                mLayout.dispatchAttachedToWindow(this);
            }
        }
        // 更新缓存大小
        mRecycler.updateViewCacheSize();
        // 和新的LayoutManager关联后 重新请求绘制。
        requestLayout();
    }
```

## RecyclerView 测量和布局

### RecyclerView.onMeasure

RecyclerView的测量过程 最终都是通过 LayoutManager 来进行测量的（一般会测量2次），并且不仅仅只有测量的功能，还包括布局相关的功能。

* 若 LayoutManager 为空，执行默认测量方式，就是常见的利用测量模式来获取宽高。
* 开启了自动测量，默认是开启的。
  * 首先测量一下RecyclerView 自身的宽高。
  * 若处理 `State.STEP_START` 阶段则 执行 dispatchLayoutStep1。
  * 接着执行 dispatchLayoutStep2。
  * 判断是否需要二次测量，需要就重新执行一次 dispatchLayoutStep2， 并开始测量子元素。
* 自动测量未开启。
  * 若是固定尺寸，调用 `mLayout.onMeasure()` 进行测量。
  * 处理数据更新后，也是调用 `mLayout.onMeasure()` 进行测量。

涉及到 LayoutStep 函数，这里先列一下作用，后面单独分析：

* **dispatchLayoutStep1**：更新Adapter，决定运行哪些动画（只是决定但是并不执行），保存视图信息，尝试执行预测动画等。将 mLayoutState更新为 STEP_LAYOUT。
* **dispatchLayoutStep2**：这里真正执行了子View的布局，会调用 `LayoutManager.onLayoutChildren()` 执行子View的布局。

> 二次测量的条件：RecyclerView 自身宽高不是 精确模式，或者存在至少一个子元素不是精确模式，也就是自身或者子元素存在 wrap_parent。

| 布局阶段              |                                     |                                                              |
| --------------------- | ----------------------------------- | ------------------------------------------------------------ |
| State.STEP_START      | 默认值，开始阶段，还未执行布局。    | 此阶段触发 dispatchLayoutStep1。                             |
| State.STEP_LAYOUT     | 布局阶段，将要准备开始进行 layout。 | dispatchLayoutStep1阶段结束后会更新为这个值。对应执行dispatchLayoutStep2。 |
| State.STEP_ANIMATIONS | 动画阶段，将要开始处理动画。        | dispatchLayoutStep2阶段结束后会更新为这个值。对应执行dispatchLayoutStep3。 |

```java
	@Override
    protected void onMeasure(int widthSpec, int heightSpec) {
        if (mLayout == null) { // 布局管理器为空，执行默认测量方式，就是常见的利用测量模式来获取宽高。
            defaultOnMeasure(widthSpec, heightSpec);
            return;
        }
        // 开启了自动测量，默认是开启的。
        if (mLayout.isAutoMeasureEnabled()) {
            final int widthMode = MeasureSpec.getMode(widthSpec);
            final int heightMode = MeasureSpec.getMode(heightSpec);
            // 通过 LayoutManager 测量一下自身的宽高。
            mLayout.onMeasure(mRecycler, mState, widthSpec, heightSpec);
            final boolean measureSpecModeIsExactly =
                    widthMode == MeasureSpec.EXACTLY && heightMode == MeasureSpec.EXACTLY;
            if (measureSpecModeIsExactly || mAdapter == null) {
                return;
            }
			// 执行第一步布局，包括 更新Adapter，决定运行哪些动画，保存视图信息，尝试执行预测动画
            if (mState.mLayoutStep == State.STEP_START) {
                dispatchLayoutStep1();
            }
            // set dimensions in 2nd step. Pre-layout should happen with old dimensions for
            // consistency
            // 为了保持一致性，应该使用旧尺寸进行布局
            mLayout.setMeasureSpecs(widthSpec, heightSpec);
            mState.mIsMeasuring = true;
            // 
            dispatchLayoutStep2();
			
            // now we can get the width and height from the children.
            mLayout.setMeasuredDimensionFromChildren(widthSpec, heightSpec);

            // if RecyclerView has non-exact width and height and if there is at least one child
            // which also has non-exact width & height, we have to re-measure.
            // 二次测量：RecyclerView 自身宽高不是 或者存在至少一个子元素 不是精确模式，存在 wrap_parent。
            if (mLayout.shouldMeasureTwice()) { 
                mLayout.setMeasureSpecs(
                        MeasureSpec.makeMeasureSpec(getMeasuredWidth(), MeasureSpec.EXACTLY),
                        MeasureSpec.makeMeasureSpec(getMeasuredHeight(), MeasureSpec.EXACTLY));
                mState.mIsMeasuring = true;
                dispatchLayoutStep2();
                // now we can get the width and height from the children.
                mLayout.setMeasuredDimensionFromChildren(widthSpec, heightSpec);
            }
        } else { // 关闭自动测量
            if (mHasFixedSize) { // 固定尺寸直接测量。
                mLayout.onMeasure(mRecycler, mState, widthSpec, heightSpec);
                return;
            }
            // custom onMeasure
            // ...
            // 这里也是通过  mLayout.onMeasure 进行测量
        }
    }
```

### RecyclerView.onLayout()

这里的布局流程和之前分析 `onMeasure()` 时执行的布局调用的是相同几个函数。

* Adapter 或者 LayoutManager为空时，不执行布局。
* **dispatchLayoutStep1**：更新适配器，决定运行哪些动画，保存视图信息等。
* **dispatchLayoutStep2**：View的实际布局，会调用 `LayoutManager.onLayoutChildren()` 执行子View的布局。
* **dispatchLayoutStep3**：布局的最后一步。保存动画视图的信息，触发动画并做一些清理工作。

```java
	@Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        TraceCompat.beginSection(TRACE_ON_LAYOUT_TAG);
        // 调用 dispatchLayout()
        dispatchLayout();
        TraceCompat.endSection();
        mFirstLayoutComplete = true;
    }

	void dispatchLayout() {
        if (mAdapter == null) { // 若没有 adapter 跳过布局流程，就是什么都不显示
            Log.e(TAG, "No adapter attached; skipping layout");
            // leave the state in START
            return;
        }
        if (mLayout == null) { // 没有布局管理器 也跳过，就是什么都不显示
            Log.e(TAG, "No layout manager attached; skipping layout");
            // leave the state in START
            return;
        }
        mState.mIsMeasuring = false;
        if (mState.mLayoutStep == State.STEP_START) {
            // 1
            dispatchLayoutStep1();
            mLayout.setExactMeasureSpecsFrom(this);
            // 2
            dispatchLayoutStep2();
        } else if (mAdapterHelper.hasUpdates() || mLayout.getWidth() != getWidth()
                || mLayout.getHeight() != getHeight()) {
            // First 2 steps are done in onMeasure but looks like we have to run again due to
            // changed size.
            mLayout.setExactMeasureSpecsFrom(this);
            // 2
            dispatchLayoutStep2();
        } else {
            // always make sure we sync them (to ensure mode is exact)
            mLayout.setExactMeasureSpecsFrom(this);
        }
        // 3
        dispatchLayoutStep3();
    }
```

---

## LinearLayoutManager执行子布局流程

### LinearLayoutManager.onLayoutChildren()

* 找到一个锚坐标（coordinate）和一个锚位置（position）。后续填充时使用，表示填充的开始位置。
* 先将当前存在的子View都分离，然后缓存到 Scrap 中。
* 根据布局方向来重新填充（fill）布局，其实就是重新 add 子View的过程。以常见的 垂直布局为例。
  * LayoutFromEnd：以下方为基准，从下向上填充布局。
  * LayoutFromStart：以上方为基准，从上往下填充布局。


```java
	@Override
    public void onLayoutChildren(RecyclerView.Recycler recycler, RecyclerView.State state) {
        // layout algorithm:
        // 1) by checking children and other variables, find an anchor coordinate and an anchor
        //  item position.
        // 2) fill towards start, stacking from bottom
        // 3) fill towards end, stacking from top
        // 4) scroll to fulfill requirements like stack from bottom.
        // create layout state

        if (mPendingSavedState != null || mPendingScrollPosition != RecyclerView.NO_POSITION) {
            if (state.getItemCount() == 0) {
                removeAndRecycleAllViews(recycler);
                return;
            }
        }
        if (mPendingSavedState != null && mPendingSavedState.hasValidAnchor()) {
            mPendingScrollPosition = mPendingSavedState.mAnchorPosition;
        }

        ensureLayoutState();
        mLayoutState.mRecycle = false;
        // resolve layout direction
        resolveShouldLayoutReverse();
		// ... 找到一个锚坐标和锚项位置。
        onAnchorReady(recycler, state, mAnchorInfo, firstLayoutDirection);
        
        // 先将视图分离，并缓存到 Scrap中。
        detachAndScrapAttachedViews(recycler);
        
        mLayoutState.mInfinite = resolveIsInfinite();
        mLayoutState.mIsPreLayout = state.isPreLayout();
        mLayoutState.mNoRecycleSpace = 0;
        // 重新填充布局
        if (mAnchorInfo.mLayoutFromEnd) {
            // fill towards start
            // 向开始方向填充，从下网上堆叠
            updateLayoutStateToFillStart(mAnchorInfo);
            mLayoutState.mExtraFillSpace = extraForStart;
            // 调用 fill() 填充Item填充
            fill(recycler, mLayoutState, state, false);
            startOffset = mLayoutState.mOffset;
            // ...
            // fill towards end
            // 向末端填充，从上往下堆叠
            updateLayoutStateToFillEnd(mAnchorInfo);
            mLayoutState.mExtraFillSpace = extraForEnd;
            mLayoutState.mCurrentPosition += mLayoutState.mItemDirection;
            fill(recycler, mLayoutState, state, false);
            endOffset = mLayoutState.mOffset;
			// ...
        } else {
            // fill towards end  向末端填充，从上往下堆叠
            updateLayoutStateToFillEnd(mAnchorInfo);
            mLayoutState.mExtraFillSpace = extraForEnd;
            fill(recycler, mLayoutState, state, false);
            endOffset = mLayoutState.mOffset;
            // ...
            // fill towards start 向开始方向填充，从下网上堆叠
            updateLayoutStateToFillStart(mAnchorInfo);
            mLayoutState.mExtraFillSpace = extraForStart;
            mLayoutState.mCurrentPosition += mLayoutState.mItemDirection;
            fill(recycler, mLayoutState, state, false);
            startOffset = mLayoutState.mOffset;
			// ...
        }
		// ...
    }
```

### LinearLayoutManager.detachAndScrapAttachedViews()

遍历所有attaced child，然后调用 `scrapOrRecycleView()` 将child分离并缓存到 Scrap中。

```java
        public void detachAndScrapAttachedViews(@NonNull Recycler recycler) {
            final int childCount = getChildCount();
            for (int i = childCount - 1; i >= 0; i--) {
                final View v = getChildAt(i);
                scrapOrRecycleView(recycler, i, v);
            }
        }
```

```java
	private void scrapOrRecycleView(Recycler recycler, int index, View view) {
        	// 获取View对于的ViewHolder
            final ViewHolder viewHolder = getChildViewHolderInt(view);
            if (viewHolder.shouldIgnore()) {
                if (DEBUG) {
                    Log.d(TAG, "ignoring view " + viewHolder);
                }
                return;
            }
            if (viewHolder.isInvalid() && !viewHolder.isRemoved()
                    && !mRecyclerView.mAdapter.hasStableIds()) {
                removeViewAt(index);
                recycler.recycleViewHolderInternal(viewHolder);
            } else {
                // detach
                detachViewAt(index);
                // 加入到 scrap缓存中
                recycler.scrapView(view);
                mRecyclerView.mViewInfoStore.onViewDetached(viewHolder);
            }
        }
```



### LinearLayoutManager.fill()

* 当处理滚动中时，会将刚移出屏幕外的View缓存到 CachedViews 中。
* 循环判断当前可见区域是否存在剩余空间以及存在数据，满足条件就调用layoutChunk填充布局。也就是重新添加一个childView。

```java
int fill(RecyclerView.Recycler recycler, LayoutState layoutState,
            RecyclerView.State state, boolean stopOnFocusable) {
        final int start = layoutState.mAvailable;
    	// 判断当前是否处于滚动中，
        if (layoutState.mScrollingOffset != LayoutState.SCROLLING_OFFSET_NaN) {
            // TODO ugly bug fix. should not happen
            if (layoutState.mAvailable < 0) {
                layoutState.mScrollingOffset += layoutState.mAvailable;
            }
            // 处于滚动中，缓存移出屏幕外的View
            recycleByLayoutState(recycler, layoutState);
        }
    
    	int remainingSpace = layoutState.mAvailable + layoutState.mExtraFillSpace;
        LayoutChunkResult layoutChunkResult = mLayoutChunkResult;
    	// 循环判断当前可见区域是否存在剩余空间以及存在数据，满足条件就调用layoutChunk填充布局。
        while ((layoutState.mInfinite || remainingSpace > 0) && layoutState.hasMore(state)) {
            layoutChunkResult.resetInternal();
            if (RecyclerView.VERBOSE_TRACING) {
                TraceCompat.beginSection("LLM LayoutChunk");
            }
            // 重新添加一个childView
            layoutChunk(recycler, state, layoutState, layoutChunkResult);
            // ...
        }
        return start - layoutState.mAvailable;
    }
```

### LinearLayoutManager.layoutChunk()

在这个函数中 将View重新添加到了 RecyclerView中。

* **从recycler中重新获取View**：`layoutState.next(recycler)`，这个获取流程其实就是缓存复用流程。
* **重新add到RecyclerView中**：`addView()`

```java
	void layoutChunk(RecyclerView.Recycler recycler, RecyclerView.State state,
            LayoutState layoutState, LayoutChunkResult result) {
    	// 重新获取View，
        View view = layoutState.next(recycler);
        if (view == null) {
            if (DEBUG && layoutState.mScrapList == null) {
                throw new RuntimeException("received null view when unexpected");
            }
            // if we are laying out views in scrap, this may return null which means there is
            // no more items to layout.
            result.mFinished = true;
            return;
        }
        RecyclerView.LayoutParams params = (RecyclerView.LayoutParams) view.getLayoutParams();
        // mScrapList 一般都是空，仅当开启预测动画才会被赋值
        if (layoutState.mScrapList == null) {
            // 调用 recyclerView.addView
            if (mShouldReverseLayout == (layoutState.mLayoutDirection
                    == LayoutState.LAYOUT_START)) {
                addView(view);
            } else {
                addView(view, 0);
            }
        } else {
            if (mShouldReverseLayout == (layoutState.mLayoutDirection
                    == LayoutState.LAYOUT_START)) {
                addDisappearingView(view);
            } else {
                addDisappearingView(view, 0);
            }
        }
        measureChildWithMargins(view, 0, 0);
        // ..
    }
```

### LinearLayoutManager.next()

从 recycler 中获取 ViewHolder中的 View。

```java
        View next(RecyclerView.Recycler recycler) {
            if (mScrapList != null) {
                return nextViewFromScrapList();
            }
            // 这里就是ViewHolder缓存复用相关逻辑
            final View view = recycler.getViewForPosition(mCurrentPosition);
            mCurrentPosition += mItemDirection;
            return view;
        }
```

## 缓存机制分析

### 缓存复用(获取)

#### RecyclerView.getViewForPosition()

```java
        @NonNull
        public View getViewForPosition(int position) {
            return getViewForPosition(position, false);
        }

        View getViewForPosition(int position, boolean dryRun) {
            // 获取缓存的ViewHolder，再从中取出View
            return tryGetViewHolderForPositionByDeadline(position, dryRun, FOREVER_NS).itemView;
        }
```

#### RecyclerView.tryGetViewHolderForPositionByDeadline()

0. 若当前是预加载布局，通过 **position** 从 `mChangedScrap` 中查询。若没获取到则继续下一步。
1. 通过 **position** 从 scrap/hidden list/cache 这些缓存中查询
   * 先查询 `mAttachedScrap`
   * 再考虑从 `ChildHelper.mHiddenViews`中查询。
   * 最后考虑从`mCachedViews`中查询。
2. 通过 **ItemId** 从 scrap/cache 中查找。
   * 先查询 `mAttachedScrap`。
   * 再考虑从`mCachedViews`中查询。
3. 从用户自定义缓存 `mViewCacheExtension` 总查询。这层缓存默认没有。
4. 根据 type 从 `RecycledViewPool` 中查询。
5. 到这里表示缓存不存在，调用 `adapter.createViewHodler()` 来创建一个ViewHolder。这个就是我们在定义Adapter时需要实现的方法。

```java
ViewHolder tryGetViewHolderForPositionByDeadline(int position,
                boolean dryRun, long deadlineNs) {
			// ...
            boolean fromScrapOrHiddenOrCache = false;
            ViewHolder holder = null;
            // 0) If there is a changed scrap, try to find from there
            if (mState.isPreLayout()) {
                holder = getChangedScrapViewForPosition(position);
                fromScrapOrHiddenOrCache = holder != null;
            }
            // 1) Find by position from scrap/hidden list/cache
            if (holder == null) {
                // 使用position查询，查询顺序：mAttachedScrap -> mHiddenViews -> mCachedViews
                holder = getScrapOrHiddenOrCachedHolderForPosition(position, dryRun);
                // ...
            }
            if (holder == null) {
                final int offsetPosition = mAdapterHelper.findPositionOffset(position);
                final int type = mAdapter.getItemViewType(offsetPosition);
                // 2) Find from scrap/cache via stable ids, if exists
                if (mAdapter.hasStableIds()) {
                    // 使用itemId查询，查询顺序：mAttachedScrap -> mCachedViews
                    holder = getScrapOrCachedViewForId(mAdapter.getItemId(offsetPosition),
                            type, dryRun);
                    // ...
                }
                // 存在自定义缓存mViewCacheExtension，就从 mViewCacheExtension 中查询
                if (holder == null && mViewCacheExtension != null) {
                    // We are NOT sending the offsetPosition because LayoutManager does not
                    // know it.
                    final View view = mViewCacheExtension
                            .getViewForPositionAndType(this, position, type);
                    if (view != null) {
                        holder = getChildViewHolder(view);
                        // ...
                    }
                }
                if (holder == null) { // fallback to pool
                    // 根据 type 从 RecycledViewPool 中查询
                    holder = getRecycledViewPool().getRecycledView(type);
                    // ...
                }
                if (holder == null) {
                    long start = getNanoTime();
                    // 创建 ViewHolder
                    holder = mAdapter.createViewHolder(RecyclerView.this, type);
                    // ...
                }
            }
            // ...
            return holder;
        }
```



### 缓存回收

#### Recycler.scrapView()：布局期间缓存

这些缓存仅在布局期间存在。将View对应的ViewHolder 缓存到 Scrap 中。

```java
	void scrapView(View view) {
            final ViewHolder holder = getChildViewHolderInt(view);
        	// 被移除并且无效的 | 未发生变化的 | 可重用
            if (holder.hasAnyOfTheFlags(ViewHolder.FLAG_REMOVED | ViewHolder.FLAG_INVALID)
                    || !holder.isUpdated() || canReuseUpdatedViewHolder(holder)) {
                // 无效但未被remove 抛出异常
                if (holder.isInvalid() && !holder.isRemoved() && !mAdapter.hasStableIds()) {
                    throw new IllegalArgumentException("Called scrap view with an invalid view."
                            + " Invalid views cannot be reused from scrap, they should rebound from"
                            + " recycler pool." + exceptionLabel());
                }
                holder.setScrapContainer(this, false);
                // 加入到 mAttachedScrap
                mAttachedScrap.add(holder);
            } else { // 其他的加入到  mChangedScrap
                if (mChangedScrap == null) {
                    mChangedScrap = new ArrayList<ViewHolder>();
                }
                holder.setScrapContainer(this, true);
                mChangedScrap.add(holder);
            }
        }
```



#### RecyclerView.recycleViewHolderInternal()：滑动缓存

滑动缓存最终走的是这个流程。

* 符合 加入 `CachedViews` 的条件。
  * 若CachedViews 未满，就直接加入到缓存中。
  * 若CachedViews 已满则将最老的缓存加入到 RecycledViewPool中并从CachedViews中移除，最后将新的ViewHolder加入到缓存中。
* 不满足加入到 CachedViews 时则添加到 `RecycledViewPool` 中。

```java
	void recycleViewHolderInternal(ViewHolder holder) {
            // ... 异常判断
            if (forceRecycle || holder.isRecyclable()) {
                if (mViewCacheMax > 0
                        && !holder.hasAnyOfTheFlags(ViewHolder.FLAG_INVALID
                        | ViewHolder.FLAG_REMOVED
                        | ViewHolder.FLAG_UPDATE
                        | ViewHolder.FLAG_ADAPTER_POSITION_UNKNOWN)) {
                    // Retire oldest cached view
                    int cachedViewSize = mCachedViews.size();
                    if (cachedViewSize >= mViewCacheMax && cachedViewSize > 0) {
                        // CachedViews 超出上限
                        // 将最老的缓存加入到 RecycledViewPool中并从CachedViews中踢出
                        recycleCachedViewAt(0);
                        cachedViewSize--;
                    }

                    int targetCacheIndex = cachedViewSize;
                    // 添加新的数据到 CachedViews缓存中
                    mCachedViews.add(targetCacheIndex, holder);
                    // 置为已缓存
                    cached = true;
                }
                if (!cached) {
                    // 不满足CachedViews 加入到 RecycledViewPool中
                    addViewHolderToRecycledViewPool(holder, true);
                    recycled = true;
                }
            } else {
                //
            }
            // even if the holder is not removed, we still call this method so that it is removed
            // from view holder lists.
            mViewInfoStore.removeViewHolder(holder);
            if (!cached && !recycled && transientStatePreventsRecycling) {
                holder.mOwnerRecyclerView = null;
            }
        }
```



## SnapHelper

## 补充

### 预测Item动画：PredictiveItemAnimations

[RecyclerView animations - AndroidDevSummit write-up – froger_mcs dev blog – Coding with love {❤️} (frogermcs.github.io)](http://frogermcs.github.io/recyclerview-animations-androiddevsummit-write-up/)

这篇文章介绍了这个预测动画的效果，正常情况下，我们删除一个元素时，最底部这个新显示的元素是从屏幕单独顶上来的，并不是和前面的元素一起移动的，而是单独出现，因为最后这个元素之前时不可见的。

开启预测动画后，就会预测这个元素，这样最底部这个新显示的元素会和前面的元素一起移动。

