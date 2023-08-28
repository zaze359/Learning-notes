# DataBinding

Databinding 是 Android提供的实现数据UI **双向绑定**的组件。

当View发生变化时会自动反映到 ViewModel中并修改数据，当数据发送变化时也会自动反应在View上。

处理双向绑定，还帮助我们节省了 `findViewById()` 的工作。

## 使用

### 开启 DataBinding

```kotlin
android {
    ...
    
    dataBinding {
        enable = true
    }
}
```

### XML布局配置

* `<layout>`：
* `<data>`：定义数据
* `<variable>`：定义在 xml 中使用的变量，可以是其他任意类型。
* `@{}`：将变量和属性绑定。这里使用的变量需要是可观察的，是LiveData、BaseObservable这些。

```xml
<layout>

    <data>

        <variable
            name="viewModel"
            type="com.zaze.demo.component.network.NetworkStatsViewModel" />
    </data>

    <LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:app="http://schemas.android.com/apk/res-auto"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="vertical">

        <androidx.swiperefreshlayout.widget.SwipeRefreshLayout
            android:id="@+id/networkStatsRefreshLayout"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:layout_marginTop="8dp"
            android:orientation="vertical"
            app:layout_constraintBottom_toBottomOf="parent"
            app:layout_constraintEnd_toEndOf="parent"
            app:layout_constraintStart_toStartOf="parent"
            app:layout_constraintTop_toBottomOf="@+id/networkStatsBtn"
            app:refreshing="@{viewModel.dragLoading}">

            <androidx.recyclerview.widget.RecyclerView
                android:id="@+id/networkStatsRecycler"
                android:layout_width="match_parent"
                android:layout_height="match_parent"
                app:items="@{viewModel.networkTraffic}"/>

        </androidx.swiperefreshlayout.widget.SwipeRefreshLayout>

    </LinearLayout>
</layout>
```

### 页面代码

```kotlin
class NetworkStatsActivity : AbsActivity() {
    private var adapter: NetworkStatsAdapter? = null
    private lateinit var viewModel: NetworkStatsViewModel
    private lateinit var databinding: NetworkStatsActBinding


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        //
        databinding = DataBindingUtil.setContentView(this, R.layout.network_stats_act)
        databinding.lifecycleOwner = this
        // 给databinding中定义的变量赋值， viewModel
        // 触发rebinding，最终调用的 executeBindings()
        databinding.viewModel = obtainViewModel(NetworkStatsViewModel::class.java).apply {
            this@NetworkStatsActivity.viewModel = this
        }
        databinding.networkStatsRefreshLayout.setOnRefreshListener {
            viewModel.load()
        }
    }
}
```

```java
class NetworkStatsViewModel(application: Application) : AbsAndroidViewModel(application) {

    val networkTraffic = MutableLiveData<Collection<NetTrafficStats>>()

    fun load() {
        Observable.fromCallable {
            AnalyzeTrafficCompat.getInstance(application).dayNetworkTraffic
        }.subscribeOn(Schedulers.io()).map {
            // 更新数据
            networkTraffic.set(it)
        }.doFinally {
            // 更新状态
            dragLoading.set(false)
        }.subscribe(MyObserver())
    }

}
```





## 数据绑定原理

Databinding 能够自动更新UI 的其实依靠的就是 **调用对应的 set 方法**。

### Databinding初始化

当我们初始赋值 xml中定义的变量 viewModel时，会触发ViewDataBinding 的 mRebindRunnable 事件。mDirtyFlags 是用于判断哪些字段发送了变化，进行差量更新。

```java

public void setViewModel(@Nullable com.zaze.demo.component.network.NetworkStatsViewModel ViewModel) {
    this.mViewModel = ViewModel;
    synchronized(this) {
        mDirtyFlags |= 0x4L;
    }
    // 通知属性变化
    notifyPropertyChanged(BR.viewModel);
    // 触发 mRebindRunnable，进行数据绑定。
    super.requestRebind();
}
protected void requestRebind() {
    if (mContainingBinding != null) {
        mContainingBinding.requestRebind();
    } else {
        final LifecycleOwner owner = this.mLifecycleOwner;
        if (owner != null) {
            Lifecycle.State state = owner.getLifecycle().getCurrentState();
            if (!state.isAtLeast(Lifecycle.State.STARTED)) {
                return; // wait until lifecycle owner is started
            }
        }
        synchronized (this) {
            if (mPendingRebind) {
                return;
            }
            mPendingRebind = true;
        }
        if (USE_CHOREOGRAPHER) {
            mChoreographer.postFrameCallback(mFrameCallback);
        } else {
            mUIThreadHandler.post(mRebindRunnable);
        }
    }
}

private final Runnable mRebindRunnable = new Runnable() {
    @Override
    public void run() {
        synchronized (this) {
            mPendingRebind = false;
        }
        processReferenceQueue();
        if (VERSION.SDK_INT >= VERSION_CODES.KITKAT) {
            // Nested so that we don't get a lint warning in IntelliJ
            if (!mRoot.isAttachedToWindow()) {
                // Don't execute the pending bindings until the View
                // is attached again.
                mRoot.removeOnAttachStateChangeListener(ROOT_REATTACHED_LISTENER);
                mRoot.addOnAttachStateChangeListener(ROOT_REATTACHED_LISTENER);
                return;
            }
        }
        executePendingBindings();
    }
};
```

### 数据读取并绑定

最终调用到 `NetworkStatsActBindingImpl.executeBindings()`。

这里会先读取对应LiveData的值，并且注册监听LiveData，并且根据 dirtyFlags 进行字段对应更新操作。

> 例如 `app:refreshing="@{viewModel.dragLoading}"` ，首先读取 dragLoading 的值然后监听这个LiveData， 并自动调用了 `setRefreshing(dragLoading.getValue())` ` 。

```java
private  long mDirtyFlags = 0xffffffffffffffffL;
/* flag mapping
        flag 0 (0x1L): viewModel.networkTraffic
        flag 1 (0x2L): viewModel.dragLoading
        flag 2 (0x3L): viewModel
        flag 3 (0x4L): null
    flag mapping end*/
//end

@Override
protected void executeBindings() {
    long dirtyFlags = 0;
    synchronized(this) {
        dirtyFlags = mDirtyFlags;
        mDirtyFlags = 0;
    }
    androidx.lifecycle.MutableLiveData<java.util.Collection<com.zaze.demo.debug.NetTrafficStats>> viewModelNetworkTraffic = null;
    boolean androidxDatabindingViewDataBindingSafeUnboxViewModelDragLoadingGetValue = false;
    androidx.lifecycle.MutableLiveData<java.lang.Boolean> viewModelDragLoading = null;
    java.util.Collection<com.zaze.demo.debug.NetTrafficStats> viewModelNetworkTrafficGetValue = null;
    com.zaze.demo.component.network.NetworkStatsViewModel viewModel = mViewModel;
    java.lang.Boolean viewModelDragLoadingGetValue = null;

    if ((dirtyFlags & 0xfL) != 0) {


        if ((dirtyFlags & 0xdL) != 0) {

            if (viewModel != null) {
                // read viewModel.networkTraffic
                viewModelNetworkTraffic = viewModel.getNetworkTraffic();
            }
            // 更新注册
            updateLiveDataRegistration(0, viewModelNetworkTraffic);


            if (viewModelNetworkTraffic != null) {
                // read viewModel.networkTraffic.getValue()
                viewModelNetworkTrafficGetValue = viewModelNetworkTraffic.getValue();
            }
        }
        if ((dirtyFlags & 0xeL) != 0) {

            if (viewModel != null) {
                // read viewModel.dragLoading
                viewModelDragLoading = viewModel.getDragLoading();
            }
            updateLiveDataRegistration(1, viewModelDragLoading);


            if (viewModelDragLoading != null) {
                // read viewModel.dragLoading.getValue()
                viewModelDragLoadingGetValue = viewModelDragLoading.getValue();
            }


            // read androidx.databinding.ViewDataBinding.safeUnbox(viewModel.dragLoading.getValue())
            androidxDatabindingViewDataBindingSafeUnboxViewModelDragLoadingGetValue = androidx.databinding.ViewDataBinding.safeUnbox(viewModelDragLoadingGetValue);
        }
    }
    // batch finished
    if ((dirtyFlags & 0xdL) != 0) {
        // api target 1

        com.zaze.demo.util.MyExtKt.setData(this.networkStatsRecycler, viewModelNetworkTrafficGetValue);
    }
    if ((dirtyFlags & 0xeL) != 0) {
        // api target 1

        this.networkStatsRefreshLayout.setRefreshing(androidxDatabindingViewDataBindingSafeUnboxViewModelDragLoadingGetValue);
    }
}
```

### 注册监听LiveData

这里是LiveData类型，所有 使用 CREATE_LIVE_DATA_LISTENER 创建 LiveDataListener。

```java
private static final CreateWeakListener CREATE_LIVE_DATA_LISTENER = new CreateWeakListener() {
    @Override
    public WeakListener create(
        ViewDataBinding viewDataBinding,
        int localFieldId,
        ReferenceQueue<ViewDataBinding> referenceQueue
    ) {
        return new LiveDataListener(viewDataBinding, localFieldId, referenceQueue)
            .getListener();
    }
};

/**
     * @hide
     */
protected boolean updateLiveDataRegistration(int localFieldId, LiveData<?> observable) {
    mInLiveDataRegisterObserver = true;
    try {
        // 注册LiveData监听 
        return updateRegistration(localFieldId, observable, CREATE_LIVE_DATA_LISTENER);
    } finally {
        mInLiveDataRegisterObserver = false;
    }
}

@RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
protected boolean updateRegistration(int localFieldId, Object observable,
                                     CreateWeakListener listenerCreator) {
    if (observable == null) {
        return unregisterFrom(localFieldId);
    }
    WeakListener listener = mLocalFieldObservers[localFieldId];
    if (listener == null) {
        registerTo(localFieldId, observable, listenerCreator);
        return true;
    }
    if (listener.getTarget() == observable) {
        return false;//nothing to do, same object
    }
    unregisterFrom(localFieldId);
    registerTo(localFieldId, observable, listenerCreator);
    return true;
}

```

### 字段变化通知 + rebind

注册LiveData监听后，若后续数据发送了变化，则会更新 mDirtyFlags 标注哪个字段发生了变化 并 重新触发 rebind 流程。

> 例如后续用户操作下拉时，触发SwipeRefreshLayout 执行刷新，从而触发 `viewModel.load()`，数据加载完毕后我们调用了 `dragLoading.set(false)` ，此时 DataBinding监听到数据变化，就会 更新 dragLoading 的flag 并 触发 rebind。

```java
private static class LiveDataListener implements Observer,
            ObservableReference<LiveData<?>> {
        final WeakListener<LiveData<?>> mListener;
        @Nullable
        WeakReference<LifecycleOwner> mLifecycleOwnerRef = null;

        @Override
        public void onChanged(@Nullable Object o) {
            ViewDataBinding binder = mListener.getBinder();
            if (binder != null) {
                binder.handleFieldChange(mListener.mLocalFieldId, mListener.getTarget(), 0);
            }
        }
    }
```

```java
@RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
protected void handleFieldChange(int mLocalFieldId, Object object, int fieldId) {
    if (mInLiveDataRegisterObserver || mInStateFlowRegisterObserver) {
        return;
    }
    // 通知 字段 发送变化
    boolean result = onFieldChange(mLocalFieldId, object, fieldId);
    if (result) {
        // 触发rebind。  读取数据 + 进行数据绑定
        requestRebind();
    }
}
```

最终回调到 `NetworkStatsActBindingImpl.onFieldChange()`，这里更新了数据 `mDirtyFlags`，进行差量更新

```java

@Override
protected boolean onFieldChange(int localFieldId, Object object, int fieldId) {
        switch (localFieldId) {
            case 0 :
                return onChangeViewModelNetworkTraffic((androidx.lifecycle.MutableLiveData<java.util.Collection<com.zaze.demo.debug.NetTrafficStats>>) object, fieldId);
            case 1 :
                return onChangeViewModelDragLoading((androidx.lifecycle.MutableLiveData<java.lang.Boolean>) object, fieldId);
        }
        return false;
    }
```

同理 `app:items="@{viewModel.networkTraffic}"` 实现了自动更新页面数据， 它是自定义的 数据绑定。

```kotlin
@BindingAdapter("items")
fun <V> RecyclerView.setData(items: Collection<V>?) {
    // 自定义处理逻辑
    // 这里更新数据 并 notify
    adapter?.let {
        if (adapter is BaseRecyclerAdapter<*, *>) {
            (it as BaseRecyclerAdapter<V, *>).setDataList(items)
        }
    }
}
```



## ViewBinding

若仅仅只是需要省略 `findViewById()` 的操作，而不需要数据绑定的的功能，我们可以使用 ViewBinding。

* 算是 DataBinding的子集，包含 DataBinding 中的 view绑定 相关功能，但是效率更高，因为不需要数据绑定。
* 不需要在 xml 布局文件中添加 `<layout>` 。
* 功能 和 ButterKinfe、`kotlin-android-extensions`插件（废弃）。

### 开启 ViewBinding

```java
android {
	...
    buildFeatures {
        viewBinding = true
    }

}
```

### XML布局配置

xml 不需要额外的配置， 正常写即可

```xml
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:app="http://schemas.android.com/apk/res-auto"
        android:layout_width="match_parent"
        android:layout_height="match_parent">

        <androidx.appcompat.widget.Toolbar
            android:id="@+id/toolbar"
            style="@style/Toolbar"
            app:layout_constraintLeft_toLeftOf="parent"
            app:layout_constraintRight_toRightOf="parent"
            app:layout_constraintTop_toTopOf="parent" />

        <ScrollView
            android:layout_width="match_parent"
            android:layout_height="0dp"
            app:layout_constraintBottom_toBottomOf="parent"
            app:layout_constraintTop_toBottomOf="@id/toolbar">

            <TextView
                android:id="@+id/lifecycleMessageTv"
                android:layout_width="match_parent"
                android:layout_height="wrap_content" />
        </ScrollView>

    </androidx.constraintlayout.widget.ConstraintLayout>
```

### 页面代码

调用对应 布局的 `Binding.inflate()` 来构建布局， 然后调用 `setContentView()` 即可。

```kotlin
class LifecycleActivity : AbsActivity() {
    private lateinit var binding: ActivityLifecycleBinding
    private val viewModel: MyLifecycleViewModel by myViewModels()
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 构建view
        binding = ActivityLifecycleBinding.inflate(layoutInflater)
        // setContentView
        setContentView(binding.root)
        setupActionBar(binding.toolbar) { toolbar ->
            title = "生命周期观测"
            setDisplayHomeAsUpEnabled(true)
            setHomeButtonEnabled(true)
            toolbar.setNavigationOnClickListener {
                finish()
            }
        }
        val logViewWrapper = LogViewWrapper(binding.lifecycleMessageTv)
    }
}
```

## 内存泄露问题

一般发生在 Fragment 复用的场景下。

Fragment 在会被复用时，生命周期 走到 `onDestoryView()`，此时正常来说 fragment 中的View 将被被销毁，fragment实例会被保存等待复用。

不过由于 fragment持有 binding，binding又持有 view，所以导致 view并没有被销毁，导致了泄露。

```kotlin
class MainSettingsFragment : AbsFragment() {
    // binding 持有了 所有的View
    private lateinit var binding: SettingsFragmentMainBinding
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        binding = SettingsFragmentMainBinding.inflate(layoutInflater, container, false)
        return binding.root
    }
}
```

处理方式一：就是将 **binding 置空**。

```kotlin
class MainSettingsFragment : Fragment() {
    private var _binding: SettingsFragmentMainBinding? = null
    val binding get() = _binding!!

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = SettingsFragmentMainBinding.inflate(layoutInflater, container, false)
        return binding.root
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        // 置空
        _binding = null
    }
}
```

处理方式二：**作为 临时变量**。 

```kotlin
class MainSettingsFragment : Fragment(R.layout.settings_fragment_main) {

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val binding = SettingsFragmentMainBinding.bind(view)
        // 处理 view
    }
}
```

或者：

```kotlin
class MainSettingsFragment : Fragment(R.layout.settings_fragment_main) {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val binding = SettingsFragmentMainBinding.inflate(inflater, container, false)
		// 处理 view
        return binding.root
    }
}
```

