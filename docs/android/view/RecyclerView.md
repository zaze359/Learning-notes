# RecyclerView

RecyclerView 可以实现列表(List)、表格(Grid)、流式布局(StaggeredGrid) 这几种布局效果。

[自定义 RecyclerView  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/ui/layout/recyclerview-custom?hl=zh-cn)

[Recyclerview  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/jetpack/androidx/releases/recyclerview?hl=zh_cn)

## 如何使用

### 1. 创建Adapter

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

### 2.  配置RecyclerView

```kotlin
val adapter = DemoAdapter(list) // 创建Adapter并填充数据
val manager = LinearLayoutManager(context) // 列表布局
binding.demoRecyclerView.layoutManager = manager 
binding.demoRecyclerView.adapter = adapter
```



## LayoutManager

*   GridLayoutManager ： 表格布局。

*   LinearLayoutManager ： 线性布局。

*   StaggeredGridLayoutManager：流式布局。

## ItemDecoration(装饰)

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









## 缓存机制

RecyclerView 提供了很强大的缓存机制，**缓存机制的核心是 ViewHolder**。

### 缓存层级



```java
public final class Recycler {
    //
    final ArrayList<ViewHolder> mAttachedScrap = new ArrayList<>();
    ArrayList<ViewHolder> mChangedScrap = null;

    // CachedView
    // 一级缓存，保存刚从屏幕移除的ViewHolder，帮助在来回滚动场景中是实现快速复用。
    final ArrayList<ViewHolder> mCachedViews = new ArrayList<ViewHolder>();

    private final List<ViewHolder>
                mUnmodifiableAttachedScrap = Collections.unmodifiableList(mAttachedScrap);
    
    RecycledViewPool mRecyclerPool;
	// 供开发者使用的缓存类
    private ViewCacheExtension mViewCacheExtension;
    
    static final int DEFAULT_CACHE_SIZE = 2;
    private int mRequestedCacheMax = DEFAULT_CACHE_SIZE; // 2
    int mViewCacheMax = DEFAULT_CACHE_SIZE;// 2
}
```





#### Scrap

scrap 意为废缓存、临时缓存，缓存的是重新布局期间出现过的ViewHolder，它们仅存在于重新布局过程中，布局完成后就不存在了，会被清空。它和滑动时的缓存复用没有关系。

* `ArrayList<ViewHolder> mAttachedScrap`：重新布局期间那些没有发生变化的 ViewHolder。
* `ArrayList<ViewHolder> mChangedScrap`：重新布局期间发生改变的 ViewHolder。



#### CachedView

> ``final ArrayList<ViewHolder> mCachedViews = new ArrayList<ViewHolder>();``

CachedView作用于是RecyclerView滑动期间，会将刚刚离开屏幕的ViewHolder缓存，最多保存2个。若超出限制，则会将最早的加入到 RecyclerViewPool中，然后移除，最后将新的加入到CacheView 中。

这个缓存是用于优化的经常来回滑动的场景：

* 首先屏幕向上滑动，itemA 移动到了屏幕外，那么 itemA 加入到CacheView中。
* 接着我们向下滑动，itemA 重新进入屏幕中，此时会根据 position 进行比对，若符合则会直接从CacheView中得到itemA 来进行复用，且不用重新进行数据绑定。
  * `getScrapOrHiddenOrCachedHolderForPosition()`

#### ViewCacheExtension

这个类是扩展给我们开发者使用的缓存类，默认为 null，它位于 CachedView 和 RecyclerViewPool之间。

#### RecyclerViewPool

这是最后一级的缓存池，在上述缓存都不接收时，会被加入到 RecyclerViewPool 中。

* 缓存时会根据 itemType 来将 ViewHolder进行分组。
* 仅保存了ViewHolder对象，并没有保存数据，复用时需要重新调用 `onBindViewHolder()` 绑定数据。

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

