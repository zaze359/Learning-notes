# CoordinatorLayout



```xml
```





## Behavior

可以使 CoordinatorLayout 的 子 View 间进行一些交互。

```xml
app:layout_behavior="@string/appbar_scrolling_view_behavior"
```



```xml
app:layout_scrollFlags="scroll|enterAlways"
```



scrollView 指 我们在屏幕上实际操作滑动的view。

| flag                 |                                                              |      |
| -------------------- | ------------------------------------------------------------ | ---- |
| scroll               | 必要值，关联滚动事件，滚出或滚进屏幕。需要 scrollView 滑动到边界才会重新滚动进屏幕。 |      |
| enterAlways          | 优先响应向下滚动事件进入屏幕，优先快速拉出的效果。拉出后 scrollView 才会重新滚动。 |      |
| enterAlwaysCollapsed | 需要和 `enterAlways` 一起使用，设定 `minHeight` 指定折叠高度，快速拉出时**会先拉出折叠高度**，其余需要 scrollView 滑动到边界时才会被拉出。 |      |
| exitUntilCollapsed   | 设定 `minHeight` 指定折叠高度，滚动出屏幕时**会保留折叠高度**。 |      |
| snap                 | 吸附效果。滑动结束后，要么全部显示，要么全部隐藏。不设置时是滑动显示多少就是多少。 |      |

```xml
<com.google.android.material.appbar.MaterialToolbar xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/toolbar"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:minHeight="10dp"
    app:layout_scrollFlags="scroll|exitUntilCollapsed"
    app:titleCentered="true"
    style="@style/Toolbar" />
```

