# ViewPager2

ViewPager2 是 Google 提供的用于取代 ViewPager的新控件。

ViewPager2 继承自ViewGroup 内部包含一个 RecyclerView，功能都是基于 RecyclerView实现的，也就继承了 RecyclerView的高性能。

实现原理可以简单概括为 将 RecyclerView 的滑动逻辑 转换成了 ViewPager的页面切换逻辑。

* `ScrollEventAdapter: RecyclerView.OnScrollListener`：监听RecyclerView滑动事件。
* `PagerSnapHelper: SnapHelper`：实现页面切换。

## ViewPager存在的问题

### 预加载问题

ViewPager的预加载无法关闭，它的 `mOffscreenPageLimit` 不能小于 1，默认会缓存前后两页，有时会造成资源浪费。

所以使用时需要和 `fragment.setUserVisibleHint()` 结合来实现数据的懒加载。

### 刷新问题

我们修改数据后调用 `Adapter.notifyDataSetChanged()` 来刷新数据时，常常发现页面并没有发生变化，往往需要往后滑再滑回来才会刷新，这其实也是由于 mOffscreenPageLimit 这个缓存引起，在滑动时会使用这些旧数据缓存页面。

一般处理方式：

> 优化思路：通过 View的tag 来进行状态控制， `notifyDataSetChanged()` 时 置为需要强制重建，在`instantiateItem()` 时去除这个标志。

```java
class MyPagerAdapter(fm: FragmentManager, list: ArrayList<AbsFragment>?) :
        FragmentStatePagerAdapter(fm) {
    override fun getItemPosition(`object`: Any): Int {
         // 返回POSITION_NONE 每次会重新调用 instantiateItem()
         return POSITION_NONE
     }
}
```



## ViewPager2

ViewPager2 基于 RecyclerView 实现，内部包含了一个 RecyclerView。

* 需要Androidx。
* 支持垂直方向。
* 支持从右到左（RTL）。
* 适配器使用 `FragmentStateAdapter` 或 `RecyclerView.Adapter`。



## setMaxLifecycle 限制生命周期



##  FragmentPagerAdapter 中的 behavior 字段

 behavior  字段可以控制Fragment的生命周期，例如 设置了 `BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT`，那么仅当前的Fragment 会进入 `onResume()`，其他的 新加载的Fragment 会被限制在 `onStart()`。

内部实现原理就是利用的 `FragmentTransaction.setMaxLifecycle()` 来实现的。它可以限制 Fragment的最大生命周期，从而帮助我们实现懒加载。上述的 behavior  就是会将其他不可见的 Fragment 的生命周期限制在了 START。



## 问题处理记录

FragmentStateAdapter 刷新问题

调用 `adapter.notifyDataSetChanged()` 有时会出现页面并没有变化的问题，主要是由于 FragmentStateAdapter 中的 `ensureFragment()` 函数导致，内部根据 itemId 来进行缓存复用判断，所以我们只需要重写 `getItemId()` 并给每一个数据分配一个唯一的id即可。

```java
	private void ensureFragment(int position) {
        // getItemId 默认返回的是 position
        long itemId = getItemId(position);
        if (!mFragments.containsKey(itemId)) {
            // TODO(133419201): check if a Fragment provided here is a new Fragment
            Fragment newFragment = createFragment(position);
            newFragment.setInitialSavedState(mSavedStates.get(itemId));
            mFragments.put(itemId, newFragment);
        }
    }
```

