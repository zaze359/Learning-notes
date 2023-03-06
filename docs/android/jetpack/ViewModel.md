# ViewModel

[ViewModel 概览  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/topic/libraries/architecture/viewmodel?hl=zh-cn)

* **可以保存要在界面中显示的数据**。ViewModel 将数据保留在内存中，且系统会自动将 ViewModel 与发生配置更改后产生的新 activity 实例相关联。
* **用于封装相关的业务逻辑**。
* **ViewModel 和 ViewModelStoreOwner.lifecycle 的生命周期绑定**。在owner销毁时会调用`ViewModel.clear()`清理所有缓存的ViewModel，并回调 `ViewModel.onCleared()`。

![说明 ViewModel 随着 activity 状态的改变而经历的生命周期。](./ViewModel.assets/viewmodel-lifecycle.png)

## 如何使用

* 通过 `by viewModels()` 委托的方式构建实例。它是ComponentActivity的扩展函数。

* 通过SavedStateHandle保存数据。

* 在ViewModel 可以通过 `viewModelScope`来使用协程。协程生命周期和ViewModel绑定。

  依赖库：`androidx.lifecycle:lifecycle-viewmodel-ktx:2.4.0`

  

```kotlin
// 在构造函数中声明需要使用SavedStateHandle
class SavedStateViewModel(private val savedStateHandle: SavedStateHandle) : ViewModel() {

}

// ViewModelFactory中会默认提供SavedStateHandle
// 自定义的Factory 可以通过扩展 AbstractSavedStateViewModelFactory 实现。
class MainFragment : Fragment() {
    val vm: SavedStateViewModel by viewModels()

    ...
}
```





## ComponentActivity

在对ViewModel的实现进行分析时，可以先从ComponentActivity看起。

ComponetActivity是一个ViewModelStoreOwner的实现类。同样的还有Fragment、NavBackStackEntry等也都是 ViewModelStoreOwner的实现类。

* **ViewModelStore**：负责**缓存ViewModel的实例化对象**。
* **ViewModelProvider.Factory**：它是**真正创建ViewModel实例的地方**。
  * 内部通过`modelClass.newInstance()/modelClass.getConstructor(Application::class.java).newInstance(app)`的方式创建ViewModel实例。
  * 默认实现为`SavedStateViewModelFactory`，还实现了状态的保存和恢复逻辑。
* **NonConfigurationInstances**：负责保存ViewModelStore

```java
public class ComponentActivity extends androidx.core.app.ComponentActivity implements 
    ...
    LifecycleOwner,
    ViewModelStoreOwner,
    SavedStateRegistryOwner,
    ...
{
    // 此处保存了ViewModelStore
    static final class NonConfigurationInstances {
        Object custom;
        ViewModelStore viewModelStore;
    }
        
    // 生命周期管理
    private final LifecycleRegistry mLifecycleRegistry = new LifecycleRegistry(this);
    // 界面状态的保存
    @SuppressWarnings("WeakerAccess") /* synthetic access */
    final SavedStateRegistryController mSavedStateRegistryController =
            SavedStateRegistryController.create(this);
    
    // ViewModel对象的构建和缓存
    private ViewModelStore mViewModelStore;
    private ViewModelProvider.Factory mDefaultFactory;
    
    // ------------------ SavedRegisterHandle 保存/恢复
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
		// performRestore 恢复 通过SavedRegisterHandle保存的数据
        mSavedStateRegistryController.performRestore(savedInstanceState);
        //
        mContextAwareHelper.dispatchOnContextAvailable(this);
        super.onCreate(savedInstanceState);
        ReportFragment.injectIfNeededIn(this);
        if (mContentLayoutId != 0) {
            setContentView(mContentLayoutId);
        }
    }
        
    @CallSuper
    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        Lifecycle lifecycle = getLifecycle();
        if (lifecycle instanceof LifecycleRegistry) {
            ((LifecycleRegistry) lifecycle).setCurrentState(Lifecycle.State.CREATED);
        }
        super.onSaveInstanceState(outState);
        // performSave 保存数据
        // 这里也包括了ViewModel通过SavedRegisterHandle保存的数据
        mSavedStateRegistryController.performSave(outState);
    } 
    
    
        
        
    // ----------------- 创建ViewModel相关
    // 默认的ViewModelProvider.Factory
    @NonNull
    @Override
    public ViewModelProvider.Factory getDefaultViewModelProviderFactory() {
        if (mDefaultFactory == null) {
            mDefaultFactory = new SavedStateViewModelFactory(
                    getApplication(),
                    this,
                    getIntent() != null ? getIntent().getExtras() : null);
        }
        return mDefaultFactory;
    }
    
        
    // ViewModelStoreOwner.savedStateRegistry返回的是 mSavedStateRegistryController中的 SavedStateRegistry
    @NonNull
    @Override
    public final SavedStateRegistry getSavedStateRegistry() {
        return mSavedStateRegistryController.getSavedStateRegistry();
    }
    
    // 返回ViewModelStore
 	@NonNull
    @Override
    public ViewModelStore getViewModelStore() {
        if (getApplication() == null) {
            throw new IllegalStateException("Your activity is not yet attached to the "
                    + "Application instance. You can't request ViewModel before onCreate call.");
        }
        ensureViewModelStore();
        return mViewModelStore;
    }

    // 读取缓存或新建ViewModelStore
    @SuppressWarnings("WeakerAccess") /* synthetic access */
    void ensureViewModelStore() {
        if (mViewModelStore == null) {
            // 这里会优先尝试获取之前保存在NonConfigurationInstances的ViewModel
            NonConfigurationInstances nc =
                    (NonConfigurationInstances) getLastNonConfigurationInstance();
            if (nc != null) {
                // Restore the ViewModelStore from NonConfigurationInstances
                mViewModelStore = nc.viewModelStore;
            }
            if (mViewModelStore == null) {
                mViewModelStore = new ViewModelStore();
            }
        }
    }
}
```



## ViewModel创建流程

* **viewModels()**：它是**创建ViewModel的入口函数**。实际ComponentActivity的扩展函数。
* **ViewModelProvider**：负责**获取ViewModel实例**。
  * 优先从ViewModelStore中根据`viewModelClass.java`查询ViewModel是否存在缓存实例，若存在就之间返回缓存对象。
  * 不存在缓存则调用`ViewModelProvider.Factory`创建ViewModel实例，并将实例缓存到ViewModelStore中。

### viewModels()

在ViewModelLazy内部通过 `ViewModelProvider().get(viewModelClass.java) `来构建ViewModel。

```kotlin
@MainThread
public inline fun <reified VM : ViewModel> ComponentActivity.viewModels(
    noinline extrasProducer: (() -> CreationExtras)? = null,
    noinline factoryProducer: (() -> Factory)? = null
): Lazy<VM> {
    val factoryPromise = factoryProducer ?: {
        // 构建 ComponentActivity.getDefaultViewModelProviderFactory()
        defaultViewModelProviderFactory
    }

    return ViewModelLazy(
        VM::class,
        { viewModelStore }, // 调用 ComponentActivity.getViewModelStore()
        factoryPromise,
        { extrasProducer?.invoke() ?: this.defaultViewModelCreationExtras }
    )
}

public class ViewModelLazy<VM : ViewModel> @JvmOverloads constructor(
    private val viewModelClass: KClass<VM>,
    private val storeProducer: () -> ViewModelStore,
    private val factoryProducer: () -> ViewModelProvider.Factory,
    private val extrasProducer: () -> CreationExtras = { CreationExtras.Empty }
) : Lazy<VM> {
    private var cached: VM? = null

    override val value: VM
        get() {
            val viewModel = cached
            return if (viewModel == null) {
                val factory = factoryProducer()
                val store = storeProducer()
                ViewModelProvider(
                    store, // viewModelStore
                    factory, // defaultViewModelProviderFactory
                    extrasProducer()
                ).get(viewModelClass.java).also {
                    cached = it
                }
            } else {
                viewModel
            }
        }

    override fun isInitialized(): Boolean = cached != null
}
```

### ViewModelProvider

调用`factory.create()`来创建ViewModel。

使用 `"$DEFAULT_KEY:$canonicalName"`作为 ViewModel对象在ViewModelStroe中缓存的默认key。

```kotlin
public open class ViewModelProvider
@JvmOverloads
constructor(
    private val store: ViewModelStore,
    private val factory: Factory,
    private val defaultCreationExtras: CreationExtras = CreationExtras.Empty,
) {
    @MainThread
    public open operator fun <T : ViewModel> get(modelClass: Class<T>): T {
        // 默认使用
        val canonicalName = modelClass.canonicalName
            ?: throw IllegalArgumentException("Local and anonymous classes can not be ViewModels")
        return get("$DEFAULT_KEY:$canonicalName", modelClass)
    }
    
    @Suppress("UNCHECKED_CAST")
    @MainThread
    public open operator fun <T : ViewModel> get(key: String, modelClass: Class<T>): T {
        val viewModel = store[key]
        if (modelClass.isInstance(viewModel)) {
            (factory as? OnRequeryFactory)?.onRequery(viewModel)
            return viewModel as T
        } else {
            @Suppress("ControlFlowWithEmptyBody")
            if (viewModel != null) {
                // TODO: log a warning.
            }
        }
        val extras = MutableCreationExtras(defaultCreationExtras)
        extras[VIEW_MODEL_KEY] = key
        return try {
            factory.create(modelClass, extras)
        } catch (e: AbstractMethodError) {
            factory.create(modelClass)
        }.also { store.put(key, it) }
    }

    @Suppress("SingletonConstructor")
    public open class NewInstanceFactory : Factory {
        @Suppress("DocumentExceptions")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return try {
                modelClass.newInstance()
            } catch (e: InstantiationException) {
                throw RuntimeException("Cannot create an instance of $modelClass", e)
            } catch (e: IllegalAccessException) {
                throw RuntimeException("Cannot create an instance of $modelClass", e)
            }
        }

       // ........
    }
	// .........
}


@MainThread
public inline fun <reified VM : ViewModel> ViewModelProvider.get(): VM = get(VM::class.java)

```

### ViewModelStore

使用一个HashMap缓存了ViewModel实例。

```kotlin
public class ViewModelStore {

    private final HashMap<String, ViewModel> mMap = new HashMap<>();

    final void put(String key, ViewModel viewModel) {
        ViewModel oldViewModel = mMap.put(key, viewModel);
        if (oldViewModel != null) {
            oldViewModel.onCleared();
        }
    }

    final ViewModel get(String key) {
        return mMap.get(key);
    }
	//....
}

```

### SavedStateViewModelFactory

ComponentActivity中ViewModelProvider.Factory的默认实现。

当需要保存状态时会创建带有SavedStateHandle参数的ViewModel/AndroidViewModel。否则调用默认方式创建ViewModel/AndroidVeiwModel。

```kotlin
// SavedStateViewModel
class SavedStateViewModelFactory : ViewModelProvider.OnRequeryFactory, ViewModelProvider.Factory {
    private var application: Application? = null
    private val factory: ViewModelProvider.Factory
    private var defaultArgs: Bundle? = null
    private var lifecycle: Lifecycle? = null
    private var savedStateRegistry: SavedStateRegistry? = null

    @SuppressLint("LambdaLast")
    constructor(application: Application?, owner: SavedStateRegistryOwner, defaultArgs: Bundle?) {
        savedStateRegistry = owner.savedStateRegistry
        lifecycle = owner.lifecycle
        this.defaultArgs = defaultArgs
        this.application = application
        //
        factory = if (application != null) getInstance(application)
            else ViewModelProvider.AndroidViewModelFactory()
    }
    
    fun <T : ViewModel> create(key: String, modelClass: Class<T>): T {
        .....
        // doesn't need SavedStateHandle
        if (constructor == null) {
            return if (application != null) factory.create(modelClass)
                else instance.create(modelClass)
        }
        .....
        val viewModel: T = if (isAndroidViewModel && application != null) {
            newInstance(modelClass, constructor, application!!, controller.handle)
        } else {
            newInstance(modelClass, constructor, controller.handle)
        }
        .....
        return viewModel
    }
}

// 创建ViewModel实例
internal fun <T : ViewModel?> newInstance(
    modelClass: Class<T>,
    constructor: Constructor<T>,
    vararg params: Any
): T {
    return try {
        constructor.newInstance(*params)
    } catch (e: IllegalAccessException) {
        throw RuntimeException("Failed to access $modelClass", e)
    } catch (e: InstantiationException) {
        throw RuntimeException("A $modelClass cannot be instantiated.", e)
    } catch (e: InvocationTargetException) {
        throw RuntimeException(
            "An exception happened in constructor of $modelClass", e.cause
        )
    }
}

// ViewModel
public open class NewInstanceFactory : Factory {
    @Suppress("DocumentExceptions")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return try {
            modelClass.newInstance()
        } catch (e: InstantiationException) {
            throw RuntimeException("Cannot create an instance of $modelClass", e)
        } catch (e: IllegalAccessException) {
            throw RuntimeException("Cannot create an instance of $modelClass", e)
        }
    }
}

// AndroidViewModel
public open class AndroidViewModelFactory private constructor(
    private val application: Application?,
    @Suppress("UNUSED_PARAMETER") unused: Int,
) : NewInstanceFactory() {

    @Suppress("DocumentExceptions")
    private fun <T : ViewModel> create(modelClass: Class<T>, app: Application): T {
        return if (AndroidViewModel::class.java.isAssignableFrom(modelClass)) {
            try {
                modelClass.getConstructor(Application::class.java).newInstance(app)
            } catch (e: NoSuchMethodException) {
                throw RuntimeException("Cannot create an instance of $modelClass", e)
            } catch (e: IllegalAccessException) {
                throw RuntimeException("Cannot create an instance of $modelClass", e)
            } catch (e: InstantiationException) {
                throw RuntimeException("Cannot create an instance of $modelClass", e)
            } catch (e: InvocationTargetException) {
                throw RuntimeException("Cannot create an instance of $modelClass", e)
            }
        } else super.create(modelClass)
    }
}
```



## 状态保存和恢复流程

此处涉及两块：一是Activity配置发生变化（如旋转）后的状态恢复。二是进程意外终止后的状态恢复。

* 配置发生变化场景的状态保存/恢复系统已经自动处理，不需要我们参与。

* 进程意外终止的场景则是提供了 SavedStateHandle 来供我们保存ViewModel中的数据。

### 配置变更后ViewModel的恢复流程

[保存界面状态  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/topic/libraries/architecture/saving-states?hl=zh-cn)

* 
* 通过`getLastNonConfigurationInstance()`，获取到ComponentActivity中的 mLastNonConfigurationInstances。
* `ComponentActivity.mLastNonConfigurationInstances` 中包含了之前的ViewModelStore，ViewModelStore中缓存了之前的ViewModel实例。这样ViewModel就会恢复了。

分析此流程时，先从`ComponentActivity.ensureViewModelStore()` 看起，因为这里是 `mViewModelStore`赋值的地方。

```kotlin
public class ComponentActivity extends androidx.core.app.ComponentActivity implements 
    ...
    LifecycleOwner,
    ViewModelStoreOwner,
    SavedStateRegistryOwner,
    ...
{
    // 此处保存了ViewModelStore
    static final class NonConfigurationInstances {
        Object custom;
        ViewModelStore viewModelStore;
    }

    // 读取缓存或新建ViewModelStore
    @SuppressWarnings("WeakerAccess") /* synthetic access */
    void ensureViewModelStore() {
        // 一开始是Null
        if (mViewModelStore == null) {
            // 这里会先调用 Activity.getLastNonConfigurationInstance()，获取上一个NonConfigurationInstances
            NonConfigurationInstances nc =
                    (NonConfigurationInstances) getLastNonConfigurationInstance();
            if (nc != null) {
                // Restore the ViewModelStore from NonConfigurationInstances
                // 从NonConfigurationInstances中可以恢复ViewModelStore
                mViewModelStore = nc.viewModelStore;
            }
            // 没有就重新创建一个
            if (mViewModelStore == null) {
                mViewModelStore = new ViewModelStore();
            }
        }
    }
}
```

接着就可以来看看Activity中`getLastNonConfigurationInstance()`的实现，发现是获取的就是 `Activity.mLastNonConfigurationInstances.activity`，它的赋值在`retainNonConfigurationInstances()`中，发现这个函数的作用就是构建NonConfigurationInstances对象来保存数据。然后接着找mLastNonConfigurationInstances赋值的地方，发现是在`attach()`中通过参数赋值的。

此时得到了2个关键信息：

* **保存数据的时机**：寻找 retainNonConfigurationInstances() 调用处。
* **恢复数据的时机**：寻找 attach() 的调用处。

```java
public class Activity ... {
    
    static final class NonConfigurationInstances {
        Object activity; // 此处存储的是ComponentActivity中的 NonConfigurationInstances
        HashMap<String, Object> children;
        FragmentManagerNonConfig fragments;
        ArrayMap<String, LoaderManager> loaders;
        VoiceInteractor voiceInteractor;
    }
    
    NonConfigurationInstances mLastNonConfigurationInstances;
    
    // 将 mLastNonConfigurationInstances.activity 取出
    // 它就是ComponentActivity中的mLastNonConfigurationInstances
    public Object getLastNonConfigurationInstance() {
        return mLastNonConfigurationInstances != null
                ? mLastNonConfigurationInstances.activity : null;
    }
    
    // 这里是mLastNonConfigurationInstances赋值的地方
    // attach()的调用处就是恢复数据的触发点。
    @UnsupportedAppUsage(maxTargetSdk = Build.VERSION_CODES.R, trackingBug = 170729553)
    final void attach(Context context, ActivityThread aThread,
            ....
            NonConfigurationInstances lastNonConfigurationInstances, // 
            ....) {
        
       	// ....
        // 将之前的lastNonConfigurationInstances赋值给当前的使用。
        mLastNonConfigurationInstances = lastNonConfigurationInstances;
        if (voiceInteractor != null) {
            if (lastNonConfigurationInstances != null) {
                mVoiceInteractor = lastNonConfigurationInstances.voiceInteractor;
            } else {
                mVoiceInteractor = new VoiceInteractor(voiceInteractor, this, this,
                        Looper.myLooper());
            }
        }
		// ......
    }

    // 这里创建了NonConfigurationInstances，并将一些数据保存在对象中。
    // 它的调用处就是保存数据的触发点。
    NonConfigurationInstances retainNonConfigurationInstances() {
        Object activity = onRetainNonConfigurationInstance();
        HashMap<String, Object> children = onRetainNonConfigurationChildInstances();
        FragmentManagerNonConfig fragments = mFragments.retainNestedNonConfig();
        mFragments.doLoaderStart();
        mFragments.doLoaderStop(true);
        ArrayMap<String, LoaderManager> loaders = mFragments.retainLoaderNonConfig();
        if (activity == null && children == null && fragments == null && loaders == null
                && mVoiceInteractor == null) {
            return null;
        }
        NonConfigurationInstances nci = new NonConfigurationInstances();
        nci.activity = activity;
        nci.children = children;
        nci.fragments = fragments;
        nci.loaders = loaders;
        // ......
        return nci;
    }

}
```

先从`attach()`的调用处找起，它是在 `ActivityThread`中被调用的，这里涉及到了[Android的启动流程](../system/Android启动流程.md)。

搜索发现 `retainNonConfigurationInstances()` 的调用处也在 ActivityThread中。

```java
public final class ActivityThread ... {
    
    private Activity performLaunchActivity(ActivityClientRecord r, Intent customIntent) {
        ActivityInfo aInfo = r.activityInfo;
        if (r.packageInfo == null) {
            r.packageInfo = getPackageInfo(aInfo.applicationInfo, r.compatInfo,
                    Context.CONTEXT_INCLUDE_CODE);
        }

        ComponentName component = r.intent.getComponent();
        if (component == null) {
            component = r.intent.resolveActivity(
                mInitialApplication.getPackageManager());
            r.intent.setComponent(component);
        }

        if (r.activityInfo.targetActivity != null) {
            component = new ComponentName(r.activityInfo.packageName,
                    r.activityInfo.targetActivity);
        }

        ContextImpl appContext = createBaseContextForActivity(r);
        Activity activity = null;
        try {
            java.lang.ClassLoader cl = appContext.getClassLoader();
            activity = mInstrumentation.newActivity(
                    cl, component.getClassName(), r.intent);
            StrictMode.incrementExpectedActivityCount(activity.getClass());
            r.intent.setExtrasClassLoader(cl);
            r.intent.prepareToEnterProcess(isProtectedComponent(r.activityInfo),
                    appContext.getAttributionSource());
            if (r.state != null) {
                r.state.setClassLoader(cl);
            }
        } catch (Exception e) {
            if (!mInstrumentation.onException(activity, e)) {
                throw new RuntimeException(
                    "Unable to instantiate activity " + component
                    + ": " + e.toString(), e);
            }
        }

        try {
            Application app = r.packageInfo.makeApplicationInner(false, mInstrumentation);

            if (localLOGV) Slog.v(TAG, "Performing launch of " + r);
            if (localLOGV) Slog.v(
                    TAG, r + ": app=" + app
                    + ", appName=" + app.getPackageName()
                    + ", pkg=" + r.packageInfo.getPackageName()
                    + ", comp=" + r.intent.getComponent().toShortString()
                    + ", dir=" + r.packageInfo.getAppDir());

            // updatePendingActivityConfiguration() reads from mActivities to update
            // ActivityClientRecord which runs in a different thread. Protect modifications to
            // mActivities to avoid race.
            synchronized (mResourcesManager) {
                mActivities.put(r.token, r);
            }

            if (activity != null) {
                CharSequence title = r.activityInfo.loadLabel(appContext.getPackageManager());
                Configuration config =
                        new Configuration(mConfigurationController.getCompatConfiguration());
                if (r.overrideConfig != null) {
                    config.updateFrom(r.overrideConfig);
                }
                if (DEBUG_CONFIGURATION) Slog.v(TAG, "Launching activity "
                        + r.activityInfo.name + " with config " + config);
                Window window = null;
                if (r.mPendingRemoveWindow != null && r.mPreserveWindow) {
                    window = r.mPendingRemoveWindow;
                    r.mPendingRemoveWindow = null;
                    r.mPendingRemoveWindowManager = null;
                }

                // Activity resources must be initialized with the same loaders as the
                // application context.
                appContext.getResources().addLoaders(
                        app.getResources().getLoaders().toArray(new ResourcesLoader[0]));

                appContext.setOuterContext(activity);
                activity.attach(appContext, this, getInstrumentation(), r.token,
                        r.ident, app, r.intent, r.activityInfo, title, r.parent,
                        r.embeddedID, r.lastNonConfigurationInstances, config,
                        r.referrer, r.voiceInteractor, window, r.activityConfigCallback,
                        r.assistToken, r.shareableActivityToken);

                if (customIntent != null) {
                    activity.mIntent = customIntent;
                }
                r.lastNonConfigurationInstances = null;
                checkAndBlockForNetworkAccess();
                activity.mStartedActivity = false;
                int theme = r.activityInfo.getThemeResource();
                if (theme != 0) {
                    activity.setTheme(theme);
                }

                if (r.mActivityOptions != null) {
                    activity.mPendingOptions = r.mActivityOptions;
                    r.mActivityOptions = null;
                }
                activity.mLaunchedFromBubble = r.mLaunchedFromBubble;
                activity.mCalled = false;
                // Assigning the activity to the record before calling onCreate() allows
                // ActivityThread#getActivity() lookup for the callbacks triggered from
                // ActivityLifecycleCallbacks#onActivityCreated() or
                // ActivityLifecycleCallback#onActivityPostCreated().
                r.activity = activity;
                if (r.isPersistable()) {
                    mInstrumentation.callActivityOnCreate(activity, r.state, r.persistentState);
                } else {
                    mInstrumentation.callActivityOnCreate(activity, r.state);
                }
                if (!activity.mCalled) {
                    throw new SuperNotCalledException(
                        "Activity " + r.intent.getComponent().toShortString() +
                        " did not call through to super.onCreate()");
                }
                mLastReportedWindowingMode.put(activity.getActivityToken(),
                        config.windowConfiguration.getWindowingMode());
            }
            r.setState(ON_CREATE);

        } catch (SuperNotCalledException e) {
            throw e;

        } catch (Exception e) {
            if (!mInstrumentation.onException(activity, e)) {
                throw new RuntimeException(
                    "Unable to start activity " + component
                    + ": " + e.toString(), e);
            }
        }

        return activity;
    }
    
}
```









### SavedStateHandle 保存恢复流程

[ViewModel 的已保存状态模块  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/topic/libraries/architecture/viewmodel/viewmodel-savedstate?hl=zh-cn)

#### SavedStateViewModelFactory

> 可以通过扩展 AbstractSavedStateViewModelFactory 自定义Factory 。

ComponentActivity中ViewModelProvider.Factory的默认实现。它**实现了状态的保存和恢复相关逻辑**。

* 查询ViewModel是否存在包含SavedStateHandle的构造函数。
* 若存在则通过 savedStateRegistry 构造一个 LegacySavedStateHandleController实例 controller。
* 将controller.handle(SavedStateHandle)， 传给我们需要构造的ViewModel实例。
* Component会在 `onSaveInstanceState()` 中调用`controller.performSave()` 保存，在 `onCreate()` 中调用`controller.performRestore()` 恢复。

```kotlin
class SavedStateViewModelFactory : ViewModelProvider.OnRequeryFactory, ViewModelProvider.Factory {
    private var application: Application? = null
    private val factory: ViewModelProvider.Factory
    private var defaultArgs: Bundle? = null
    private var lifecycle: Lifecycle? = null
    private var savedStateRegistry: SavedStateRegistry? = null

    private val VIEWMODEL_SIGNATURE = listOf<Class<*>>(SavedStateHandle::class.java)
    private val ANDROID_VIEWMODEL_SIGNATURE = listOf<Class<*>>(
        Application::class.java,
        SavedStateHandle::class.java
	)
    fun <T : ViewModel> create(key: String, modelClass: Class<T>): T {
        val isAndroidViewModel = AndroidViewModel::class.java.isAssignableFrom(modelClass)
        // 查询是否存在包含SavedStateHandle的构造函数。
        val constructor: Constructor<T>? = if (isAndroidViewModel && application != null) {
            findMatchingConstructor(modelClass, ANDROID_VIEWMODEL_SIGNATURE)
        } else {
            findMatchingConstructor(modelClass, VIEWMODEL_SIGNATURE)
        }
        // 不存在表示不需要保存数据
        // doesn't need SavedStateHandle
        if (constructor == null) {
            return if (application != null) factory.create(modelClass)
                else instance.create(modelClass)
        }
        // 存在表示需要保存数据
        // 将defaultArgs(Activity的Bundle)保存到了savedStateRegistry中。
        val controller = LegacySavedStateHandleController.create(
            savedStateRegistry, lifecycle, key, defaultArgs
        )
        // 将 SavedStateHandle 传给ViewModel。
        val viewModel: T = if (isAndroidViewModel && application != null) {
            newInstance(modelClass, constructor, application!!, controller.handle)
        } else {
            newInstance(modelClass, constructor, controller.handle)
        }
        viewModel.setTagIfAbsent(
            AbstractSavedStateViewModelFactory.TAG_SAVED_STATE_HANDLE_CONTROLLER, controller
        )
        return viewModel
    }
}

// 创建ViewModel实例
internal fun <T : ViewModel?> newInstance(
    modelClass: Class<T>,
    constructor: Constructor<T>,
    vararg params: Any
): T {
    return try {
        constructor.newInstance(*params)
    } catch (e: IllegalAccessException) {
        throw RuntimeException("Failed to access $modelClass", e)
    } catch (e: InstantiationException) {
        throw RuntimeException("A $modelClass cannot be instantiated.", e)
    } catch (e: InvocationTargetException) {
        throw RuntimeException(
            "An exception happened in constructor of $modelClass", e.cause
        )
    }
}
```



#### SavedStateHandle

SavedStateHandle 供我们**在ViewModel中保存/恢复数据使用**。

* 它是一个键值对映射，用于通过 `set()` 和 `get()` 方法向已保存的状态写入数据以及从中检索数据。
* 支持LiveData和StateFlow
  * `savedStateHandle.getLiveData<String>("query")`
  * `savedStateHandle.getStateFlow<String>("query")`

```kotlin
class SavedStateHandle {
    private val regular = mutableMapOf<String, Any?>()
    private val savedStateProviders = mutableMapOf<String, SavedStateRegistry.SavedStateProvider>()
    private val liveDatas = mutableMapOf<String, SavingStateLiveData<*>>()
    private val flows = mutableMapOf<String, MutableStateFlow<Any?>>()
    private val savedStateProvider =
        SavedStateRegistry.SavedStateProvider {
            // Get the saved state from each SavedStateProvider registered with this
            // SavedStateHandle, iterating through a copy to avoid re-entrance
            val map = savedStateProviders.toMap()
            for ((key, value) in map) {
                val savedState = value.saveState()
                set(key, savedState)
            }
            // Convert the Map of current values into a Bundle
            val keySet: Set<String> = regular.keys
            val keys: ArrayList<String> = ArrayList(keySet.size)
            val value: ArrayList<Any?> = ArrayList(keys.size)
            for (key in keySet) {
                keys.add(key)
                value.add(regular[key])
            }
            bundleOf(KEYS to keys, VALUES to value)
        }

    @RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
    fun savedStateProvider(): SavedStateRegistry.SavedStateProvider {
        return savedStateProvider
    }



    @MainThread
    operator fun <T> get(key: String): T? {
        @Suppress("UNCHECKED_CAST")
        return regular[key] as T?
    }

}

```

#### SavedStateRegistryController

负责创建一个SavedStateRegistry。

#### SavedStateRegistryOwner

继承自`LifecycleOwner`，持有一个`savedStateRegistry`成员变量。**ComponentActivity实现了整个接口**。

```kotlin
interface SavedStateRegistryOwner : LifecycleOwner {
    val savedStateRegistry: SavedStateRegistry
}
```

#### SavedStateRegistry

**以Bundle的方式保存状态数据**。支持将其他Bundle汇总到自身的Bundle对象中，以及再从中读取出所需的Bundle。

```kotlin
@SuppressLint("RestrictedApi")
class SavedStateRegistry internal constructor() {
    private val components = SafeIterableMap<String, SavedStateProvider>()
    private var attached = false
    private var restoredState: Bundle? = null

    @MainThread
    internal fun performRestore(savedState: Bundle?) {
        restoredState = savedState?.getBundle(SAVED_COMPONENTS_KEY)
    }

    @MainThread
    @Suppress("INACCESSIBLE_TYPE")
    fun performSave(outBundle: Bundle) {
        val components = Bundle()
        if (restoredState != null) {
            components.putAll(restoredState)
        }
        val it: Iterator<Map.Entry<String, SavedStateProvider>> =
            this.components.iteratorWithAdditions()
        while (it.hasNext()) {
            val (key, value) = it.next()
            components.putBundle(key, value.saveState())
        }
        if (!components.isEmpty) {
            outBundle.putBundle(SAVED_COMPONENTS_KEY, components)
        }
    }

   	// 保存数据的接口
    fun interface SavedStateProvider {
        fun saveState(): Bundle
    }

    private companion object {
        private const val SAVED_COMPONENTS_KEY =
            "androidx.lifecycle.BundlableSavedStateRegistry.key"
    }
}
```

#### SavedStateHandleController

**负责将ViewModel中Bundle保存到SavedStateRegistry中**。内部持有一个SavedStateHandle供外部使用。

```java
final class SavedStateHandleController implements LifecycleEventObserver {
    private final String mKey;
    private boolean mIsAttached = false;
    private final SavedStateHandle mHandle;

    SavedStateHandleController(String key, SavedStateHandle handle) {
        mKey = key;
        mHandle = handle;
    }
}

// create() 返回一个SavedStateHandleController
class LegacySavedStateHandleController {
    private LegacySavedStateHandleController() {}

    static final String TAG_SAVED_STATE_HANDLE_CONTROLLER = "androidx.lifecycle.savedstate.vm.tag";

    static SavedStateHandleController create(SavedStateRegistry registry, Lifecycle lifecycle,
            String key, Bundle defaultArgs) {
        Bundle restoredState = registry.consumeRestoredStateForKey(key);
        // 构建一个 SavedStateHandle
        SavedStateHandle handle = SavedStateHandle.createHandle(restoredState, defaultArgs);
        // 
        SavedStateHandleController controller = new SavedStateHandleController(key, handle);
        // 关联Lifecycle
        controller.attachToLifecycle(registry, lifecycle);
        tryToAddRecreator(registry, lifecycle);
        return controller;
    }
}

```



