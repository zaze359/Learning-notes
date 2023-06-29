# Android之Activity启动流程

首先简要概述一下应用的启动流程：

* zygote孵化了应用进程后 调用 `ActivityThread.main()` 来启动应用程序。
* 在 `main()` 函数中 启动了 `mainLooper` 来接收消息。

* 这些消息中就包括了Activity 的创建消息，接收到这个消息后会调用 `handleLaunchActivity()` ，创建并启动Activity。

> 最后的【补充】 中会记录一些 主流程之外的 辅助分析的内容。

## 创建Activity

在`handleLaunchActivity()` 中会调用 `performLaunchActivity()` 函数，由它来创建并启动Activity。

* `performLaunchActivity()` 内部通过反射创建了 Activity。

* 接着调用了 `Activity.attach()`、`Instrumentation.callActivityOnCreate()`等函数启动 Activity

### ActivityThread.handleLaunchActivity()

调用 `performLaunchActivity()`  创建并启动了Activity。

> [ActivityThread.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/ActivityThread.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=3769;)

```java
	/**
     * Extended implementation of activity launch. Used when server requests a launch or relaunch.
     */
    @Override
    public Activity handleLaunchActivity(ActivityClientRecord r,
            PendingTransactionActions pendingActions, Intent customIntent) {
        
        unscheduleGcIdler();
        mSomeActivitiesChanged = true;

        if (r.profilerInfo != null) {
            mProfiler.setProfiler(r.profilerInfo);
            mProfiler.startProfiling();
        }
		
        // Make sure we are running with the most recent config.
        mConfigurationController.handleConfigurationChanged(null, null);

        // Initialize before creating the activity
        if (ThreadedRenderer.sRendererEnabled
                && (r.activityInfo.flags & ActivityInfo.FLAG_HARDWARE_ACCELERATED) != 0) {
            HardwareRenderer.preload();
        }
        WindowManagerGlobal.initialize();

        // Hint the GraphicsEnvironment that an activity is launching on the process.
        GraphicsEnvironment.hintActivityLaunch();
        
        
		// 调用 performLaunchActivity() 返回一个Activity
        final Activity a = performLaunchActivity(r, customIntent);

        if (a != null) {
            // Activity 创建成功，更新配置
            r.createdConfig = new Configuration(mConfigurationController.getConfiguration());
            reportSizeConfigurations(r);
            if (!r.activity.mFinished && pendingActions != null) {
                pendingActions.setOldState(r.state);
                pendingActions.setRestoreInstanceState(true);
                pendingActions.setCallOnPostCreate(true);
            }
        } else { // 创建失败，通知ActivityManager关闭
            // If there was an error, for any reason, tell the activity manager to stop us.
            ActivityClient.getInstance().finishActivity(r.token, Activity.RESULT_CANCELED,
                    null /* resultData */, Activity.DONT_FINISH_TASK_WITH_ACTIVITY);
        }

        return a;
    }
```



### ActivityThread.performLaunchActivity()

在这里通过反射创建了 Activity，接着调用了 `Activity.attach()`、`Instrumentation.callActivityOnCreate()`。

> [ActivityThread.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/ActivityThread.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=3529)

```java
	/**  Core implementation of activity launch. */
    private Activity performLaunchActivity(ActivityClientRecord r, Intent customIntent) {
        // Activity信息
        ActivityInfo aInfo = r.activityInfo;
        if (r.packageInfo == null) {
            r.packageInfo = getPackageInfo(aInfo.applicationInfo, r.compatInfo,
                    Context.CONTEXT_INCLUDE_CODE);
        }
		// Activity 组件信息
        ComponentName component = r.intent.getComponent();
        if (component == null) { // 从intent中解析
            component = r.intent.resolveActivity(
                mInitialApplication.getPackageManager());
            r.intent.setComponent(component);
        }

        if (r.activityInfo.targetActivity != null) {
            component = new ComponentName(r.activityInfo.packageName,
                    r.activityInfo.targetActivity);
        }
		// 创建 baseContext，Activity中的getContext() 就是返回的这个。
        // 
        ContextImpl appContext = createBaseContextForActivity(r);
        Activity activity = null;
        try {
            // 获取classLoader
            java.lang.ClassLoader cl = appContext.getClassLoader();
            // 通过classLoader加载对应类名的activity。内部使用了反射
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
            // 获取 Application
            Application app = r.packageInfo.makeApplicationInner(false, mInstrumentation);
            synchronized (mResourcesManager) {
                mActivities.put(r.token, r);
            }
            if (activity != null) {
                // 获取标题
                CharSequence title = r.activityInfo.loadLabel(appContext.getPackageManager());
                // 配置
                Configuration config =
                        new Configuration(mConfigurationController.getCompatConfiguration());
                if (r.overrideConfig != null) {
                    config.updateFrom(r.overrideConfig);
                }
 
                Window window = null;
                if (r.mPendingRemoveWindow != null && r.mPreserveWindow) {
                    window = r.mPendingRemoveWindow;
                    r.mPendingRemoveWindow = null;
                    r.mPendingRemoveWindowManager = null;
                }

                // 使用 appContext 加载 资源
                appContext.getResources().addLoaders(
                        app.getResources().getLoaders().toArray(new ResourcesLoader[0]));
				
                appContext.setOuterContext(activity);
                // 调用 activity.attach()
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
             
                r.activity = activity;
                // 调用 onCreate()
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
```



### Instrumentation.newActivity()

* 从intent中获取 packageName，构建包名对应的AppComponentFactory。
* 通过 AppComponentFactory，创建Activity实例。内部通过classLoader 来创建 Activity实例。

> [Instrumentation.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/Instrumentation.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1333)

```cpp
	public Activity newActivity(ClassLoader cl, String className,
            Intent intent)
            throws InstantiationException, IllegalAccessException,
            ClassNotFoundException {
        String pkg = intent != null && intent.getComponent() != null
                ? intent.getComponent().getPackageName() : null;
        return getFactory(pkg).instantiateActivity(cl, className, intent);
    }
```

### AppComponentFactory.getFactory()

获取包名对应的  AppComponentFactory，这里类是专门负责创建 应用组件实例，包括Application、 Activity、Service、BroadcastReceiver、ContentProvider。

> [Instrumentation.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/Instrumentation.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1342)

```java
	private AppComponentFactory getFactory(String pkg) {
        if (pkg == null) {
            return AppComponentFactory.DEFAULT;
        }
        if (mThread == null) { // ActivityThread == null
            return AppComponentFactory.DEFAULT;
        }
        // 获取 LoadedApk
        LoadedApk apk = mThread.peekPackageInfo(pkg, true);
        // apk == null 表示 当前是启动 android 这个场景
        if (apk == null) apk = mThread.getSystemContext().mPackageInfo;
        // 获取 AppComponentFactory
        return apk.getAppFactory();
    }
```



### AppComponentFactory.instantiateActivity()

通过 classLoader 创建 Activity实例。

> [AppComponentFactory.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/AppComponentFactory.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=92)

```java
	public @NonNull Activity instantiateActivity(@NonNull ClassLoader cl, @NonNull String className,
            @Nullable Intent intent)
            throws InstantiationException, IllegalAccessException, ClassNotFoundException {
        // newInstance() 创建实例
        return (Activity) cl.loadClass(className).newInstance();
    }
```



## 创建 PhoneWindow

`ActivityThread.performLaunchActivity()` 通过反射创建 Activity后，会调用 `Activity.attach()` 将 Activity 进行初始化关联。并且还创建了 **PhoneWindow**。

### Activity.attach()

* 关联了 Context。

* Activity **创建了PhoneWindow**，并赋值给了 `mWindow`，从而将 Activity 和 Window 关联了起来。
* 给 PhoneWindow 设置了 WindowManager，从而 Activity 、Window、WindowManager建立了关联。 
  * WindowManager 是访问Window的入口，常用的功能包括： 添加View、更新View和删除View。


> [Activity.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/Activity.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=8225)

```java
public class Activity extends ... {

    // 实际是一个 PhoneWindow，docorView 就在这里
    private Window mWindow; 
    
    // 是 WindowManagerImpl，是访问Window的入口。
    private WindowManager mWindowManager;

    private Thread mUiThread; // attach 的调用线程()，即ActivityThread所在线程。
    ActivityThread mMainThread; // 
    
    // context 是 ContextImpl
    @UnsupportedAppUsage(maxTargetSdk = Build.VERSION_CODES.R, trackingBug = 170729553)
    final void attach(Context context, ActivityThread aThread,
            Instrumentation instr, IBinder token, int ident,
            Application application, Intent intent, ActivityInfo info,
            CharSequence title, Activity parent, String id,
            NonConfigurationInstances lastNonConfigurationInstances,
            Configuration config, String referrer, IVoiceInteractor voiceInteractor,
            Window window, ActivityConfigCallback activityConfigCallback, IBinder assistToken,
            IBinder shareableActivityToken) {
        // 关联 baseContext
        attachBaseContext(context);

        mFragments.attachHost(null /*parent*/);
		// 创建 PhoneWindow，承载 view
        // 传入 Activity.this 作为 PhoneWindow的mContext
        mWindow = new PhoneWindow(this, window, activityConfigCallback);
        // 配置window的属性
        mWindow.setWindowControllerCallback(mWindowControllerCallback);
        mWindow.setCallback(this);
        mWindow.setOnWindowDismissedCallback(this);
        mWindow.getLayoutInflater().setPrivateFactory(this);
        if (info.softInputMode != WindowManager.LayoutParams.SOFT_INPUT_STATE_UNSPECIFIED) {
            mWindow.setSoftInputMode(info.softInputMode);
        }
        if (info.uiOptions != 0) {
            mWindow.setUiOptions(info.uiOptions);
        }
        // 指定当前线程是UI线程，后续UI只能在这个线程中更新
        mUiThread = Thread.currentThread();
        // ActivityThread
        mMainThread = aThread;
        
        // 后面基本都是一些 成员变量的赋值
        mInstrumentation = instr;
        mToken = token;
        mAssistToken = assistToken;
        mShareableActivityToken = shareableActivityToken;
        mIdent = ident;
        mApplication = application;
        mIntent = intent;
        mReferrer = referrer;
        mComponent = intent.getComponent();
        mActivityInfo = info;
        mTitle = title;
        mParent = parent;
        mEmbeddedID = id;
        mLastNonConfigurationInstances = lastNonConfigurationInstances;
        if (voiceInteractor != null) {
            if (lastNonConfigurationInstances != null) {
                mVoiceInteractor = lastNonConfigurationInstances.voiceInteractor;
            } else {
                mVoiceInteractor = new VoiceInteractor(voiceInteractor, this, this,
                        Looper.myLooper());
            }
        }
		// 
        // 先从 ContextImpl.getSystemService()中获取 WindowManager, 返回的是WindowManagerImpl
        // 在将 WindowManager 传给 PhoneWindow建立关联。
        mWindow.setWindowManager(
                (WindowManager)context.getSystemService(Context.WINDOW_SERVICE),
                mToken, mComponent.flattenToString(),
                (info.flags & ActivityInfo.FLAG_HARDWARE_ACCELERATED) != 0);
        if (mParent != null) {
            mWindow.setContainer(mParent.getWindow());
        }
        // 从 PhoneWindow 中重新获取，此时PhoneWindow和 WindowManager以及建立关联。
        mWindowManager = mWindow.getWindowManager();
        mCurrentConfig = config;

        mWindow.setColorMode(info.colorMode);
        mWindow.setPreferMinimalPostProcessing(
                (info.flags & ActivityInfo.FLAG_PREFER_MINIMAL_POST_PROCESSING) != 0);

        getAutofillClientController().onActivityAttached(application);
        setContentCaptureOptions(application.getContentCaptureOptions());
    }
    
    @Override
    public Object getSystemService(@ServiceName @NonNull String name) {
        if (getBaseContext() == null) {
            throw new IllegalStateException(
                    "System services not available to Activities before onCreate()");
        }
		// 之间返回 mWindowManager。
        if (WINDOW_SERVICE.equals(name)) {
            return mWindowManager;
        } else if (SEARCH_SERVICE.equals(name)) {
            ensureSearchManager();
            return mSearchManager;
        }
        return super.getSystemService(name);
    }
}
```

### ContextImpl.getSystemService()

 从 SystemServiceRegistry 中获取一个 SystemService，这里其实是直接创建了一个 WindowManagerImpl对象返回。

> [ContextImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/app/ContextImpl.java;l=2103)

```java
class ContextImpl ... {

	@Override
    public Object getSystemService(String name) {
        // ...
        // 从 SystemServiceRegistry 中获取一个 SystemService， 其实是直接创建了一个 WindowManagerImpl对象返回。
        return SystemServiceRegistry.getSystemService(this, name);
    }
}
```

### Window.setWindowManager()

在这里 PhoneWindow 和 WindowManager 将建立关联。

> [Window.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/Window.java;l=860;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=1;bpt=1)

```java
public abstract class Window {
    
	public void setWindowManager(WindowManager wm, IBinder appToken, String appName,
            boolean hardwareAccelerated) {
        mAppToken = appToken;
        mAppName = appName;
        mHardwareAccelerated = hardwareAccelerated;
        // 传入null 则从 PhoneWindow.mContext 也就是 Activity 中获取。
        if (wm == null) {
            //  Activity 重写了getSystemService， 其实就是获取Activity.mWindowManager，此时是null
            wm = (WindowManager)mContext.getSystemService(Context.WINDOW_SERVICE);
        }
        // 传入自身，并重新创建一个 WindowManagerImpl
        mWindowManager = ((WindowManagerImpl)wm).createLocalWindowManager(this);
    }
}
```

### WindowManagerImpl.createLocalWindowManager()

创建一个 WindowManagerImpl，用于访问 Window。内部包含一个WindowManagerGlobal，最终都是调用的 mGlobal来实现功能。

> [WindowManagerImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/WindowManagerImpl.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=1;bpt=1;l=121)

```java
public final class WindowManagerImpl implements WindowManager {
    // 
    private final WindowManagerGlobal mGlobal = WindowManagerGlobal.getInstance();
    // parentWindow 就是 phoneWindow
    // mWindowContextToken 是 IBinder
	public WindowManagerImpl createLocalWindowManager(Window parentWindow) {
        return new WindowManagerImpl(mContext, parentWindow, mWindowContextToken);
    }
}
```

## 启动Activity

### Instrumentation.callActivityOnCreate()

> [Instrumentation.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/Instrumentation.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1415)

```java
    public void callActivityOnCreate(Activity activity, Bundle icicle) {
        prePerformCreate(activity);
        // 调用 performCreate
        activity.performCreate(icicle);
        postPerformCreate(activity);
    }
```

### Activity.performCreate()

这里调用了 `Activity.onCreate()` 

> [Activity.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/Activity.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=8319)

```java
    final void performCreate(Bundle icicle) {
        performCreate(icicle, null);
    }

	@UnsupportedAppUsage(maxTargetSdk = Build.VERSION_CODES.R, trackingBug = 170729553)
    final void performCreate(Bundle icicle, PersistableBundle persistentState) {

        dispatchActivityPreCreated(icicle);
        mCanEnterPictureInPicture = true;
        // initialize mIsInMultiWindowMode and mIsInPictureInPictureMode before onCreate
        final int windowingMode = getResources().getConfiguration().windowConfiguration
                .getWindowingMode();
        mIsInMultiWindowMode = inMultiWindowMode(windowingMode);
        mIsInPictureInPictureMode = windowingMode == WINDOWING_MODE_PINNED;
        mShouldDockBigOverlays = getResources().getBoolean(R.bool.config_dockBigOverlayWindows);
        restoreHasCurrentPermissionRequest(icicle);
        // 这里调用我们熟悉的 onCreate()，在这个函数内部我们 通过setContentView() 来设置UI。
        if (persistentState != null) {
            onCreate(icicle, persistentState);
        } else {
            onCreate(icicle);
        }

        mActivityTransitionState.readState(icicle);

        mVisibleFromClient = !mWindow.getWindowStyle().getBoolean(
                com.android.internal.R.styleable.Window_windowNoDisplay, false);
        mFragments.dispatchActivityCreated();
        mActivityTransitionState.setEnterActivityOptions(this, getActivityOptions());
        dispatchActivityPostCreated(icicle);
    }
```





## 创建DecorView和自定义布局

在 `performCreate()` 中 会调用我们熟悉的 `onCreate()`。在这个函数中我们会通过 `setContentView()` 来设置UI。

### Activity.setContentView()

* 无论是调用哪个 `setContentView()` 都是调用的 `mWindow.setContentView()`。而这个 `mWindow` 我们从上面已经知道实际是PhoneWindow。
* 创建了  `PhoneWindow.mDecor`。此时 `Activity.mDecor` 还并没有被赋值，等到后面`ActivityThread.handleResumeActivity()` 函数被调用时中会将 `PhoneWindow.mDecor`赋值给它。

在这个函数中，而是。

> [Activity.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/Activity.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=3600)

```java
class Activity ... {
    
    // PhoneWindow
    private Window mWindow;
    
    // 在 ActivityThread.handleResumeActivity() 中会将 PhoneWindow.mDecor赋值给它。
    View mDecor = null;
    
    public void setContentView(@LayoutRes int layoutResID) {
        getWindow().setContentView(layoutResID);
        initWindowDecorActionBar();
    }

 	public void setContentView(View view) {
        getWindow().setContentView(view);
        initWindowDecorActionBar();
    }

	public void setContentView(View view, ViewGroup.LayoutParams params) {
        getWindow().setContentView(view, params);
        initWindowDecorActionBar();
    }
	// mWindow 在 attach()被赋值，是一个 PhoneWindow
    public Window getWindow() {
        return mWindow;
    }
}
```

### PhoneWindow.setContentView()

源码中的的多个 `setContentView()` 逻辑是类似的，挑选一个分析。

* 通过 `installDecor()` 创建了 `decorView`和它的child `mContentParent`。
* 构建我们传入的布局。并将 `mContentParent` 作为 parent。

> [PhoneWindow.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/com/android/internal/policy/PhoneWindow.java;l=454)

```java
public class PhoneWindow extends Window ... {
    
    ViewGroup mContentParent; // mContentParent 是我们传入的视图的 parent。
    
	@Override
    public void setContentView(int layoutResID) {
        if (mContentParent == null) {
            // 创建了 mContentParent和DecorView，DecorView是mContentParent的根视图
            installDecor();
        } else if (!hasFeature(FEATURE_CONTENT_TRANSITIONS)) {
            mContentParent.removeAllViews();
        }
		// 使用mContentParent作为root构建了我们传入的布局视图。
        // 由此可知DecorView是最顶层视图。
        if (hasFeature(FEATURE_CONTENT_TRANSITIONS)) {
            // 此处是转场动画，不过最终还是在scene.enter方法中使用 mContentParent 作为 Parent构建了视图。
            // 和else 是相同的。
            final Scene newScene = Scene.getSceneForLayout(mContentParent, layoutResID,
                    getContext());
            transitionTo(newScene);
        } else {
            // 使用 mContentParent作为 布局的Parent构建 我们传入的视图。
            mLayoutInflater.inflate(layoutResID, mContentParent);
        }
        mContentParent.requestApplyInsets();
        final Callback cb = getCallback();
        if (cb != null && !isDestroyed()) {
            cb.onContentChanged();
        }
        mContentParentExplicitlySet = true;
    }
}
```

### PhoneWindow.installDecor()

这里主要涉及两个关键函数：

* `generateDecor(-1)`：仅创建了 DecorView 实例，并没加载实际的布局。
* `generateLayout(mDecor)`：在这个函数中 `mDecor` 加载了相应的布局，并返回mContentParent。mContentParent是mDecor内部的其中一个child。

> [PhoneWindow.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/com/android/internal/policy/PhoneWindow.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=2730)

```java
public class PhoneWindow extends Window ... {
    
    ViewGroup mContentParent;
    private DecorView mDecor;
    
    private void installDecor() {
        mForceDecorInstall = false;
        
        // mDecor 不存在则创建一个
        if (mDecor == null) {
            // 创建 DecorView 实例，这里仅创建了实例，还没加载实际的布局资源。
            mDecor = generateDecor(-1);
            mDecor.setDescendantFocusability(ViewGroup.FOCUS_AFTER_DESCENDANTS);
            mDecor.setIsRootNamespace(true);
            if (!mInvalidatePanelMenuPosted && mInvalidatePanelMenuFeatures != 0) {
                mDecor.postOnAnimation(mInvalidatePanelMenuRunnable);
            }
        } else {
            mDecor.setWindow(this);
        }
        // mContentParent 不存在 则创建一个
        if (mContentParent == null) {
            // 在这里decorview加载了布局文件，并返回mContentParent
            mContentParent = generateLayout(mDecor);
			// ... 一些 decorview的配置
            if (hasFeature(FEATURE_ACTIVITY_TRANSITIONS)) {
                // ... 处理转场动画
            }
        }
    }
    
	// 创建 DecorView
    protected DecorView generateDecor(int featureId) {
        Context context;
        if (mUseDecorContext) {
            Context applicationContext = getContext().getApplicationContext();
            if (applicationContext == null) {
                context = getContext();
            } else {
                context = new DecorContext(applicationContext, this);
                if (mTheme != -1) {
                    context.setTheme(mTheme);
                }
            }
        } else {
            context = getContext();
        }
        // new DecorView
        return new DecorView(context, featureId, this, getAttributes());
    }
    
    
    protected ViewGroup generateLayout(DecorView decor) {

        TypedArray a = getWindowStyle();
        // ... 这里省略一些主题风格相关的设置 
        decor.setSystemUiVisibility(
                (sysUiVis & ~(statusLightFlag | navLightFlag)) | (statusFlag | navFlag));
		
        // 
        // Inflate the window decor.
        int layoutResource;
        int features = getLocalFeatures();
        // ... 一些layoutResource 的赋值逻辑。主要是根据不同的 features 加载不同的布局。
        // mDecor 加载layoutResource布局
        mDecor.onResourcesLoaded(mLayoutInflater, layoutResource);
		// 创建 contentParent
        ViewGroup contentParent = (ViewGroup)findViewById(ID_ANDROID_CONTENT);
        // ...
        return contentParent;
    }
}
```



## 创建ViewRootImpl

```java
public final class ViewRootImpl implements ViewParent ... {
    // 处理自身的消息，requsetLayout()等操作就是向这里发送消息
	final ViewRootHandler mHandler = new ViewRootHandler();
    
    // ViewRootImpl内部定义的一个Binder服务，类似于回调。
    final W mWindow;
    // decorview
    View mView;
}
```

### ActivitThread.handleResumeActivity()

* **DecorView赋值关联**：将 `PhoneWindow.decorView `赋值给 `Activity.mDecor`。
* **添加Window**：将 `PhoneWindow.decorView` 添加到 WindowManagerImpl 中，实际是添加到了 `WindowManagerGlobal` 中。
* **创建 ViewRootImpl**：WindowManagerGlobal 创建了 `ViewRootImpl`，并通过 `ViewRootImpl.setView(decorView )` 将 decorView 放入到 ViewRootImpl中。
* **开始绘制**：ViewRootImpl 调用 `requestLayout()` 开始第一次 UI 绘制。
  * 这个也是为什么我们至少要在 resume之后才能获取到view宽高的原因（不过view的测量和生命周期并不是同步执行的，onResume()时不一定测量完成了）。


> [ActivityThread.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/ActivityThread.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=4814)

```java
 	@Override
    public void handleResumeActivity(ActivityClientRecord r, boolean finalStateRequest,
            boolean isForward, boolean shouldSendCompatFakeFocus, String reason) {
        // If we are getting ready to gc after going to the background, well
        // we are back active so skip it.
        unscheduleGcIdler();
        mSomeActivitiesChanged = true;
        //
        final Activity a = r.activity;
		//
        final int forwardBit = isForward
                ? WindowManager.LayoutParams.SOFT_INPUT_IS_FORWARD_NAVIGATION : 0;

        // willBeVisible 表示 activity将可见
        boolean willBeVisible = !a.mStartedActivity;
        if (!willBeVisible) {
            willBeVisible = ActivityClient.getInstance().willActivityBeVisible(
                    a.getActivityToken());
        }
        // activity 存活并且将要可见，但是 decorView还未添加到 window中，则添加到window中
        if (r.window == null && !a.mFinished && willBeVisible) {
            r.window = r.activity.getWindow();
            // 获取window中的 Decorview
            View decor = r.window.getDecorView();
            // 设置 decor view 不可见
            decor.setVisibility(View.INVISIBLE);
            // 获取 ViewManager
            ViewManager wm = a.getWindowManager();
            WindowManager.LayoutParams l = r.window.getAttributes();
            // 将这个window的decorView 设置为 activity的 decorView
            a.mDecor = decor;
            l.type = WindowManager.LayoutParams.TYPE_BASE_APPLICATION;
            l.softInputMode |= forwardBit;
            
            if (r.mPreserveWindow) { // 这里是 复用decorView流程
                a.mWindowAdded = true;
                r.mPreserveWindow = false;
                ViewRootImpl impl = decor.getViewRootImpl();
                if (impl != null) {
                    impl.notifyChildRebuilt();
                }
            }
            if (a.mVisibleFromClient) { // 客户端可见时
                if (!a.mWindowAdded) { 
                    a.mWindowAdded = true;
                    // 将 decorview 添加到 wm：WindowManagerImpl中
                    wm.addView(decor, l);
                } else { // 以添加则回调发送变化。
                    a.onWindowAttributesChanged(l);
                }
            }
        } else if (!willBeVisible) {
            r.hideForNow = true;
        }

        if (!r.activity.mFinished && willBeVisible && r.activity.mDecor != null && !r.hideForNow) {
            //
            ViewRootImpl impl = r.window.getDecorView().getViewRootImpl();
            WindowManager.LayoutParams l = impl != null
                    ? impl.mWindowAttributes : r.window.getAttributes();
            if ((l.softInputMode
                    & WindowManager.LayoutParams.SOFT_INPUT_IS_FORWARD_NAVIGATION)
                    != forwardBit) {
                l.softInputMode = (l.softInputMode
                        & (~WindowManager.LayoutParams.SOFT_INPUT_IS_FORWARD_NAVIGATION))
                        | forwardBit;
                if (r.activity.mVisibleFromClient) {
                    ViewManager wm = a.getWindowManager();
                    View decor = r.window.getDecorView();
                    wm.updateViewLayout(decor, l);
                }
            }
            // ...
        }

        r.nextIdle = mNewActivities;
        mNewActivities = r;
        Looper.myQueue().addIdleHandler(new Idler());
    }

```



### WindowManagerImpl.addView()

 `wm.addView()` 中的 vm 是 `WindowManagerImpl`。

WindowManagerImpl 使用的是桥接模式，内部包含 WindowManagerGlobal，最终调用了 `mGlobal.addView()`。

[WindowManagerImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/view/WindowManagerImpl.java;l=146)

```java
public final class WindowManagerImpl implements WindowManager {
    //
    private final WindowManagerGlobal mGlobal = WindowManagerGlobal.getInstance();
    
    @Override
    public void addView(@NonNull View view, @NonNull ViewGroup.LayoutParams params) {
        applyTokens(params);
        //
        mGlobal.addView(view, params, mContext.getDisplayNoVerify(), mParentWindow,
                mContext.getUserId());
    }
}
```



### WindowManagerGlobal.addView()

WindowManagerGlobal是一个单例，它创建了 `ViewRootImpl`，同时缓存了所有的 ViewRootImpl 和 DecorView，用于检索。

* **创建ViewRootImpl**：同时缓存了 ViewRootImpl 和 DecorView。
* **将 ViewRootImpl 和 DecorView 关联**：通过 `root.setView()` 将传入的 DecorView 设置到 ViewRootImpl中。
* **开始布局绘制**：ViewRootImpl 会处理传入的view， 调用 `requestLayout()` 开始进行布局绘制。

[WindowManagerGlobal.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/WindowManagerGlobal.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=309)

```java
public final class WindowManagerGlobal {	

	private final ArrayList<View> mViews = new ArrayList<View>();
    private final ArrayList<ViewRootImpl> mRoots = new ArrayList<ViewRootImpl>();
    
    
	public void addView(View view, ViewGroup.LayoutParams params,
            Display display, Window parentWindow, int userId) {
        // ... 一些空校验

        final WindowManager.LayoutParams wparams = (WindowManager.LayoutParams) params;
        if (parentWindow != null) {
            parentWindow.adjustLayoutParamsForSubWindow(wparams);
        } else {
            // If there's no parent, then hardware acceleration for this view is
            // set from the application's hardware acceleration setting.
            final Context context = view.getContext();
            if (context != null
                    && (context.getApplicationInfo().flags
                            & ApplicationInfo.FLAG_HARDWARE_ACCELERATED) != 0) {
                wparams.flags |= WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED;
            }
        }

        ViewRootImpl root;
        View panelParentView = null;

        synchronized (mLock) {
            // ... 省略
			// 创建 ViewRoot	
            if (windowlessSession == null) {
                // 这个
                root = new ViewRootImpl(view.getContext(), display);
            } else {
                root = new ViewRootImpl(view.getContext(), display,
                        windowlessSession, new WindowlessWindowLayout());
            }
			// 
            view.setLayoutParams(wparams);
			// 保存 传入的DecorView
            mViews.add(view);
            // 保存 ViewRoot
            mRoots.add(root);
            mParams.add(wparams);

            // do this last because it fires off messages to start doing things
            try {
                // 将传入的DecorView，设置给 ViewRootImpl
                root.setView(view, wparams, panelParentView, userId);
            } catch (RuntimeException e) {
                final int viewIndex = (index >= 0) ? index : (mViews.size() - 1);
                // BadTokenException or InvalidDisplayException, clean up.
                if (viewIndex >= 0) {
                    removeViewLocked(viewIndex, true);
                }
                throw e;
            }
        }
    }
}
```



### ViewRootImpl.setView()

* 将传入的 `PhoneWindow.DecorView` 保存到 成员变量 mView中。
* 调用 `requestLayout()`，这里进行布局绘制 。
* 调用 `mWindowSession.addToDisplayAsUser()` ，将 mWindow 传给 WMS, 用于接收事件通知。
* 将自身作为 DecorView的 ViewParent。

[ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;l=1141)

```java
public final class ViewRootImpl implements ViewParent ... {
    
    // mView 就是 DocorView
    View mView;
    
    // view -> DocorView
    public void setView(View view, WindowManager.LayoutParams attrs, View panelParentView,
            int userId) {
        synchronized (this) {
            if (mView == null) {
                // 保存 DecorView
                mView = view;

               	// ...........

                // Schedule the first layout -before- adding to the window
                // manager, to make sure we do the relayout before receiving
                // any other events from the system.
                
                // 第一次 layout，这个也是为什么我们在 resume之后才能获取到view的宽高。
                requestLayout();
                // ......
                try {
                    mOrigWindowType = mWindowAttributes.type;
                    mAttachInfo.mRecomputeGlobalAttributes = true;
                    collectViewAttributes();
                    adjustLayoutParamsForCompatibility(mWindowAttributes);
                    controlInsetsForCompatibility(mWindowAttributes);

                    Rect attachedFrame = new Rect();
                    final float[] compatScale = { 1f };
                    // 在这里将 mWindow 传给 WMS, 用于接收事件通知
                    res = mWindowSession.addToDisplayAsUser(mWindow, mWindowAttributes,
                            getHostVisibility(), mDisplay.getDisplayId(), userId,
                            mInsetsController.getRequestedVisibilities(), inputChannel, mTempInsets,
                            mTempControls, attachedFrame, compatScale);
                    if (!attachedFrame.isValid()) {
                        attachedFrame = null;
                    }
                    if (mTranslator != null) {
                        mTranslator.translateInsetsStateInScreenToAppWindow(mTempInsets);
                        mTranslator.translateSourceControlsInScreenToAppWindow(mTempControls);
                        mTranslator.translateRectInScreenToAppWindow(attachedFrame);
                    }
                    mTmpFrames.attachedFrame = attachedFrame;
                    mTmpFrames.compatScale = compatScale[0];
                    mInvCompatScale = 1f / compatScale[0];
                } catch (RemoteException e) {
                    // 异常
                    mAdded = false;
                    mView = null;
                    mAttachInfo.mRootView = null;
                    mFallbackEventHandler.setView(null);
                    // 移除Choreographer的CALLBACK_TRAVERSAL回调
                    unscheduleTraversals();
                    setAccessibilityFocus(null, null);
                    throw new RuntimeException("Adding window failed", e);
                } finally {
                    if (restore) {
                        attrs.restore();
                    }
                }
                // ...
                // 将ViewRootImpl 作为 DocorView的 ViewParent。
                view.assignParent(this);
                // ....
            }
        }
    }
}
```



## 开始UI渲染

### ViewRootImpl.requestLayout()

* 检测是不是 original thread，即UI线程。
* 发送同步屏障 并 监听`mChoreographer`回调。

[ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;l=1981)

```java
public final class ViewRootImpl implements ViewParent ... {    
	@Override
    public void requestLayout() {
        if (!mHandlingLayoutInLayoutRequest) {
            // 这里检测是不是 original thread，即UI线程。
            // 我们常见的子线程更新UI异常： Only the original thread that created a view hierarchy can touch its views 就是这里抛出的。
            checkThread(); 
            // mLayoutRequested 标记为true，允许View的measure 和 layout
            mLayoutRequested = true;
            // 在这个赋值发送消息
            scheduleTraversals();
        }
    }
}
```

### ViewRootImpl.scheduleTraversals()

> 无论是属性动画还是 主动调用 `view.invalidate()`，但凡涉及View的重绘，最后都会执行这个方法。

* **请求去重**：首先会根据 `mTraversalScheduled` 字段来对请求进行去重，避免在同一个VSYNC周期内的触发多次刷新。
* **设置同步屏障**：发送一个同步屏障消息，保证UI绘制消息能被优先处理。
* **发送绘制请求**：通过 mChoreographer 发送一个 mTraversalRunnable 回调消息。Choreographer 是一个单例，内部维护了一个使用 mainLooper的Handler，同时它还能接收VSYNC。
* **开始绘制**：mChoreographer 收到vsync后会执行 mTraversalRunnable 这个 Runnable，执行完毕后会移除 Runnable。
  * 所以仅有当我们发起了绘制请求时，才会执行view的绘制流程。


[ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;l=1981)

```java
public final class ViewRootImpl implements ViewParent ... {
    // 这是一个 自定义的Handler，处理了一些特殊消息
    final ViewRootHandler mHandler = new ViewRootHandler();
    
	@UnsupportedAppUsage(maxTargetSdk = Build.VERSION_CODES.R, trackingBug = 170729553)
    void scheduleTraversals() {
        // 这个判断是为了避免多次刷新
        if (!mTraversalScheduled) {
            mTraversalScheduled = true;
            // 发送一个同步屏障消息。优先处理UI消息
            mTraversalBarrier = mHandler.getLooper().getQueue().postSyncBarrier();
            // mChoreographer 接收到vsync后会执行mTraversalRunnable，这个Runnable调用了 doTraversal()
            mChoreographer.postCallback(
                    Choreographer.CALLBACK_TRAVERSAL, mTraversalRunnable, null);
            notifyRendererOfFramePending();
            pokeDrawLockIfNeeded();
        }
    }
}
```

### ViewRootImpl.doTraversal()

mTraversalRunnable 这个 Runnable中会调用 `doTraversal()`。

> [ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=2343)

```java
	void doTraversal() {
        if (mTraversalScheduled) {
            // 重置，这样后续就能继续触发刷新
            mTraversalScheduled = false;
            // 移除同步屏障
            mHandler.getLooper().getQueue().removeSyncBarrier(mTraversalBarrier);
			// 创建了 Surface并开始绘制
            performTraversals();
            if (mProfile) {
                Debug.stopMethodTracing();
                mProfile = false;
            }
        }
    }
```

### ViewRootImpl.performTraversals()

简直了，太长了。

这个方法开始真正的绘制流程，包含了 measure、layout和draw三个过程。

* 调用 `view.dispatchAttachedToWindow()` 将 DecorView 和 ViewRootImpl 关联起来。
  * 后续可用通过 `View.getViewRootImpl()` 函数之间获取 对应的ViewRootImpl 。

* **Surface 创建**：调用 `relayoutWindow()` 向WMS发起Binder请求，由WMS创建了Surface。
* 调用 `performMeasure()`  测量View的宽和高。
* 调用 `performLayout()` 进行布局，确定View在父容器中的放置位置。
* 调用 `performDraw()` 进行渲染。

![image-20230527213710778](./Android%E4%B9%8BActivity%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/image-20230527213710778.png)

> [ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=2787)

```java
 	private void performTraversals() {
        mLastPerformTraversalsSkipDrawReason = null;
        // cache mView since it is used so much below...
        
     	// mView 就是DocorView
        final View host = mView;
		// .... 省略

        WindowManager.LayoutParams params = null;

        Rect frame = mWinFrame;
        if (mFirst) {
            mFullRedrawNeeded = true;
            mLayoutRequested = true;
            final Configuration config = getConfiguration();
			// ...
            // host是DecorView,
            // 在这里将 mAttachInfo 传给了 DecorView，后续就能从这获取到 ViewRootImpl
            // mAttachInfo 中保存了window相关信息，以及viewRootImpl中的Handler。
            host.dispatchAttachedToWindow(mAttachInfo, 0);
            mAttachInfo.mTreeObserver.dispatchOnWindowAttachedChange(true);
            dispatchApplyInsets(host);
        } else {
            desiredWindowWidth = frame.width();
            desiredWindowHeight = frame.height();
        }


        // Execute enqueued actions on every traversal in case a detached view enqueued an action
        getRunQueue().executeActions(mAttachInfo.mHandler);



        if (mFirst || windowShouldResize || viewVisibilityChanged || params != null
                || mForceNextWindowRelayout) {

			// ....
            try {
                if (mFirst || viewVisibilityChanged) {
                    mViewFrameInfo.flags |= FrameInfo.FLAG_WINDOW_VISIBILITY_CHANGED;
                }
                
                // 调用relayoutWindow， 
                relayoutResult = relayoutWindow(params, viewVisibility, insetsPending);
                
                cancelDraw = (relayoutResult & RELAYOUT_RES_CANCEL_AND_REDRAW)
                        == RELAYOUT_RES_CANCEL_AND_REDRAW;
                cancelReason = "relayout";
                final boolean dragResizing = mPendingDragResizing;
                if (mSyncSeqId > mLastSyncSeqId) {
                    mLastSyncSeqId = mSyncSeqId;
                    if (DEBUG_BLAST) {
                        Log.d(mTag, "Relayout called with blastSync");
                    }
                    reportNextDraw("relayout");
                    mSyncBuffer = true;
                    isSyncRequest = true;
                    if (!cancelDraw) {
                        mDrewOnceForSync = false;
                    }
                }
                
                // ...
            } catch (RemoteException e) {
            } finally {
            }


            if (mSurfaceHolder != null) {
                // The app owns the surface; tell it about what is going on.
                if (mSurface.isValid()) {
                    // XXX .copyFrom() doesn't work!
                    //mSurfaceHolder.mSurface.copyFrom(mSurface);
                    mSurfaceHolder.mSurface = mSurface;
                }
                
                mSurfaceHolder.setSurfaceFrameSize(mWidth, mHeight);
                mSurfaceHolder.mSurfaceLock.unlock();
                if (surfaceCreated) {
                    mSurfaceHolder.ungetCallbacks();

                    mIsCreating = true;
                    SurfaceHolder.Callback[] callbacks = mSurfaceHolder.getCallbacks();
                    if (callbacks != null) {
                        for (SurfaceHolder.Callback c : callbacks) {
                            c.surfaceCreated(mSurfaceHolder);
                        }
                    }
                }

                if ((surfaceCreated || surfaceReplaced || surfaceSizeChanged
                        || windowAttributesChanged) && mSurface.isValid()) {
                    SurfaceHolder.Callback[] callbacks = mSurfaceHolder.getCallbacks();
                    if (callbacks != null) {
                        for (SurfaceHolder.Callback c : callbacks) {
                            c.surfaceChanged(mSurfaceHolder, lp.format,
                                    mWidth, mHeight);
                        }
                    }
                    mIsCreating = false;
                }

                if (surfaceDestroyed) {
                    notifyHolderSurfaceDestroyed();
                    mSurfaceHolder.mSurfaceLock.lock();
                    try {
                        mSurfaceHolder.mSurface = new Surface();
                    } finally {
                        mSurfaceHolder.mSurfaceLock.unlock();
                    }
                }
            }

            final ThreadedRenderer threadedRenderer = mAttachInfo.mThreadedRenderer;
            if (threadedRenderer != null && threadedRenderer.isEnabled()) {
                if (hwInitialized
                        || mWidth != threadedRenderer.getWidth()
                        || mHeight != threadedRenderer.getHeight()
                        || mNeedsRendererSetup) {
                    threadedRenderer.setup(mWidth, mHeight, mAttachInfo,
                            mWindowAttributes.surfaceInsets);
                    mNeedsRendererSetup = false;
                }
            }


            if (!mStopped || mReportNextDraw) {
                if (mWidth != host.getMeasuredWidth() || mHeight != host.getMeasuredHeight()
                        || dispatchApplyInsets || updatedConfiguration) {
                    int childWidthMeasureSpec = getRootMeasureSpec(mWidth, lp.width,
                            lp.privateFlags);
                    int childHeightMeasureSpec = getRootMeasureSpec(mHeight, lp.height,
                            lp.privateFlags);

                     // Ask host how big it wants to be
                    performMeasure(childWidthMeasureSpec, childHeightMeasureSpec);

                    // Implementation of weights from WindowManager.LayoutParams
                    // We just grow the dimensions as needed and re-measure if
                    // needs be
                    int width = host.getMeasuredWidth();
                    int height = host.getMeasuredHeight();
                    boolean measureAgain = false;

                    if (lp.horizontalWeight > 0.0f) {
                        width += (int) ((mWidth - width) * lp.horizontalWeight);
                        childWidthMeasureSpec = MeasureSpec.makeMeasureSpec(width,
                                MeasureSpec.EXACTLY);
                        measureAgain = true;
                    }
                    if (lp.verticalWeight > 0.0f) {
                        height += (int) ((mHeight - height) * lp.verticalWeight);
                        childHeightMeasureSpec = MeasureSpec.makeMeasureSpec(height,
                                MeasureSpec.EXACTLY);
                        measureAgain = true;
                    }

                    if (measureAgain) {
                        performMeasure(childWidthMeasureSpec, childHeightMeasureSpec);
                    }
                    layoutRequested = true;
                }
            }
        } else {
            maybeHandleWindowMove(frame);
        }

        if (mViewMeasureDeferred) {
            // It's time to measure the views since we are going to layout them.
            // 测量
            performMeasure(
                    MeasureSpec.makeMeasureSpec(frame.width(), MeasureSpec.EXACTLY),
                    MeasureSpec.makeMeasureSpec(frame.height(), MeasureSpec.EXACTLY));
        }

        // ...

        final boolean didLayout = layoutRequested && (!mStopped || mReportNextDraw);
        boolean triggerGlobalLayoutListener = didLayout
                || mAttachInfo.mRecomputeGlobalAttributes;
        if (didLayout) {
            // 布局
            performLayout(lp, mWidth, mHeight);
			// .....
        }
        // .....
        if (!isViewVisible) {
            mLastPerformTraversalsSkipDrawReason = "view_not_visible";
            if (mPendingTransitions != null && mPendingTransitions.size() > 0) {
                for (int i = 0; i < mPendingTransitions.size(); ++i) {
                    mPendingTransitions.get(i).endChangingAnimations();
                }
                mPendingTransitions.clear();
            }

            if (mSyncBufferCallback != null) {
                mSyncBufferCallback.onBufferReady(null);
            }
        } else if (cancelAndRedraw) {
            mLastPerformTraversalsSkipDrawReason = cancelDueToPreDrawListener
                ? "predraw_" + mAttachInfo.mTreeObserver.getLastDispatchOnPreDrawCanceledReason()
                : "cancel_" + cancelReason;
            // Try again
            scheduleTraversals();
        } else {
            if (mPendingTransitions != null && mPendingTransitions.size() > 0) {
                for (int i = 0; i < mPendingTransitions.size(); ++i) {
                    mPendingTransitions.get(i).startChangingAnimations();
                }
                mPendingTransitions.clear();
            }
            // 绘制
            if (!performDraw() && mSyncBufferCallback != null) {
                mSyncBufferCallback.onBufferReady(null);
            }
        }

        if (mAttachInfo.mContentCaptureEvents != null) {
            notifyContentCatpureEvents();
        }

        mIsInTraversal = false;
        mRelayoutRequested = false;

        if (!cancelAndRedraw) {
            mReportNextDraw = false;
            mLastReportNextDrawReason = null;
            mSyncBufferCallback = null;
            mSyncBuffer = false;
            if (isInLocalSync()) {
                mSurfaceSyncer.markSyncReady(mSyncId);
                mSyncId = UNSET_SYNC_ID;
                mLocalSyncState = LOCAL_SYNC_NONE;
            }
        }
    }
```

### ViewRootImpl.performDraw()

> [ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=4451)

```java
	private boolean performDraw() {
        mLastPerformDrawSkippedReason = null;
        if (mAttachInfo.mDisplayState == Display.STATE_OFF && !mReportNextDraw) {
            mLastPerformDrawSkippedReason = "screen_off";
            return false;
        } else if (mView == null) {
            mLastPerformDrawSkippedReason = "no_root_view";
            return false;
        }

        final boolean fullRedrawNeeded = mFullRedrawNeeded || mSyncBufferCallback != null;
        mFullRedrawNeeded = false;

        mIsDrawing = true;
        Trace.traceBegin(Trace.TRACE_TAG_VIEW, "draw");

        addFrameCommitCallbackIfNeeded();

        boolean usingAsyncReport = isHardwareEnabled() && mSyncBufferCallback != null;
        if (usingAsyncReport) {
            registerCallbacksForSync(mSyncBuffer, mSyncBufferCallback);
        } else if (mHasPendingTransactions) {
            // These callbacks are only needed if there's no sync involved and there were calls to
            // applyTransactionOnDraw. These callbacks check if the draw failed for any reason and
            // apply those transactions directly so they don't get stuck forever.
            registerCallbackForPendingTransactions();
        }
        mHasPendingTransactions = false;

        try {
            // draw
            boolean canUseAsync = draw(fullRedrawNeeded, usingAsyncReport && mSyncBuffer);
            if (usingAsyncReport && !canUseAsync) {
                mAttachInfo.mThreadedRenderer.setFrameCallback(null);
                usingAsyncReport = false;
            }
        } finally {
            mIsDrawing = false;
            Trace.traceEnd(Trace.TRACE_TAG_VIEW);
        }

        // For whatever reason we didn't create a HardwareRenderer, end any
        // hardware animations that are now dangling
        if (mAttachInfo.mPendingAnimatingRenderNodes != null) {
            final int count = mAttachInfo.mPendingAnimatingRenderNodes.size();
            for (int i = 0; i < count; i++) {
                mAttachInfo.mPendingAnimatingRenderNodes.get(i).endAllAnimators();
            }
            mAttachInfo.mPendingAnimatingRenderNodes.clear();
        }

        if (mReportNextDraw) {
            // if we're using multi-thread renderer, wait for the window frame draws
            if (mWindowDrawCountDown != null) {
                try {
                    mWindowDrawCountDown.await();
                } catch (InterruptedException e) {
                    Log.e(mTag, "Window redraw count down interrupted!");
                }
                mWindowDrawCountDown = null;
            }

            if (mAttachInfo.mThreadedRenderer != null) {
                mAttachInfo.mThreadedRenderer.setStopped(mStopped);
            }

            if (LOCAL_LOGV) {
                Log.v(mTag, "FINISHED DRAWING: " + mWindowAttributes.getTitle());
            }

            if (mSurfaceHolder != null && mSurface.isValid()) {
                final SurfaceSyncer.SyncBufferCallback syncBufferCallback = mSyncBufferCallback;
                SurfaceCallbackHelper sch = new SurfaceCallbackHelper(() ->
                        mHandler.post(() -> syncBufferCallback.onBufferReady(null)));
                mSyncBufferCallback = null;

                SurfaceHolder.Callback callbacks[] = mSurfaceHolder.getCallbacks();

                sch.dispatchSurfaceRedrawNeededAsync(mSurfaceHolder, callbacks);
            } else if (!usingAsyncReport) {
                if (mAttachInfo.mThreadedRenderer != null) {
                    mAttachInfo.mThreadedRenderer.fence();
                }
            }
        }
        if (mSyncBufferCallback != null && !usingAsyncReport) {
            mSyncBufferCallback.onBufferReady(null);
        }
        if (mPerformContentCapture) {
            performContentCaptureInitialReport();
        }
        return true;
    }
```



### ViewRootImpl.draw()

分为 **软件绘制** 和 **硬件绘制** 两个流程，这里不展开，可以参考 [Android的图形架构](../Android的图形架构.md) 一文来了解相关的信息。

[ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=4630)

```java
	private boolean draw(boolean fullRedrawNeeded, boolean forceDraw) {
        // 获取 surface
        Surface surface = mSurface;
        if (!surface.isValid()) {
            return false;
        }

        if (!sFirstDrawComplete) {
            synchronized (sFirstDrawHandlers) {
                sFirstDrawComplete = true;
                final int count = sFirstDrawHandlers.size();
                for (int i = 0; i< count; i++) {
                    mHandler.post(sFirstDrawHandlers.get(i));
                }
            }
        }

        scrollToRectOrFocus(null, false);

        if (mAttachInfo.mViewScrollChanged) {
            mAttachInfo.mViewScrollChanged = false;
            mAttachInfo.mTreeObserver.dispatchOnScrollChanged();
        }

        boolean animating = mScroller != null && mScroller.computeScrollOffset();
        final int curScrollY;
        if (animating) {
            curScrollY = mScroller.getCurrY();
        } else {
            curScrollY = mScrollY;
        }
        if (mCurScrollY != curScrollY) {
            mCurScrollY = curScrollY;
            fullRedrawNeeded = true;
            if (mView instanceof RootViewSurfaceTaker) {
                ((RootViewSurfaceTaker) mView).onRootViewScrollYChanged(mCurScrollY);
            }
        }

        final float appScale = mAttachInfo.mApplicationScale;
        final boolean scalingRequired = mAttachInfo.mScalingRequired;

        final Rect dirty = mDirty;
        if (mSurfaceHolder != null) {
            // The app owns the surface, we won't draw.
            dirty.setEmpty();
            if (animating && mScroller != null) {
                mScroller.abortAnimation();
            }
            return false;
        }

        if (fullRedrawNeeded) {
            dirty.set(0, 0, (int) (mWidth * appScale + 0.5f), (int) (mHeight * appScale + 0.5f));
        }

        
        mAttachInfo.mTreeObserver.dispatchOnDraw();

        int xOffset = -mCanvasOffsetX;
        int yOffset = -mCanvasOffsetY + curScrollY;
        final WindowManager.LayoutParams params = mWindowAttributes;
        final Rect surfaceInsets = params != null ? params.surfaceInsets : null;
        if (surfaceInsets != null) {
            xOffset -= surfaceInsets.left;
            yOffset -= surfaceInsets.top;

            // Offset dirty rect for surface insets.
            dirty.offset(surfaceInsets.left, surfaceInsets.top);
        }

        boolean accessibilityFocusDirty = false;
        final Drawable drawable = mAttachInfo.mAccessibilityFocusDrawable;
        if (drawable != null) {
            final Rect bounds = mAttachInfo.mTmpInvalRect;
            final boolean hasFocus = getAccessibilityFocusedRect(bounds);
            if (!hasFocus) {
                bounds.setEmpty();
            }
            if (!bounds.equals(drawable.getBounds())) {
                accessibilityFocusDirty = true;
            }
        }

        mAttachInfo.mDrawingTime =
                mChoreographer.getFrameTimeNanos() / TimeUtils.NANOS_PER_MS;

        boolean useAsyncReport = false;
        if (!dirty.isEmpty() || mIsAnimating || accessibilityFocusDirty) {
            if (isHardwareEnabled()) { // 硬件绘制可用
                // If accessibility focus moved, always invalidate the root.
                boolean invalidateRoot = accessibilityFocusDirty || mInvalidateRootRequested;
                mInvalidateRootRequested = false;

                // Draw with hardware renderer.
                mIsAnimating = false;

                if (mHardwareYOffset != yOffset || mHardwareXOffset != xOffset) {
                    mHardwareYOffset = yOffset;
                    mHardwareXOffset = xOffset;
                    invalidateRoot = true;
                }

                if (invalidateRoot) {
                    mAttachInfo.mThreadedRenderer.invalidateRoot();
                }

                dirty.setEmpty();

                final boolean updated = updateContentDrawBounds();

                if (mReportNextDraw) {
                    mAttachInfo.mThreadedRenderer.setStopped(false);
                }

                if (updated) {
                    requestDrawWindow();
                }

                useAsyncReport = true;

                if (forceDraw) {
                    mAttachInfo.mThreadedRenderer.forceDrawNextFrame();
                }
                // draw()
                mAttachInfo.mThreadedRenderer.draw(mView, mAttachInfo, this);
            } else {
                if (mAttachInfo.mThreadedRenderer != null &&
                        !mAttachInfo.mThreadedRenderer.isEnabled() &&
                        mAttachInfo.mThreadedRenderer.isRequested() &&
                        mSurface.isValid()) {

                    try {
                        mAttachInfo.mThreadedRenderer.initializeIfNeeded(
                                mWidth, mHeight, mAttachInfo, mSurface, surfaceInsets);
                    } catch (OutOfResourcesException e) {
                        handleOutOfResourcesException(e);
                        return false;
                    }

                    mFullRedrawNeeded = true;
                    scheduleTraversals();
                    return false;
                }
				// 软件绘制
                if (!drawSoftware(surface, mAttachInfo, xOffset, yOffset,
                        scalingRequired, dirty, surfaceInsets)) {
                    return false;
                }
            }
        }
		
        if (animating) {
            mFullRedrawNeeded = true;
            scheduleTraversals();
        }
        return useAsyncReport;
    }
```



### ThreadedRenderer.draw()

```java
void draw(View view, AttachInfo attachInfo, DrawCallbacks callbacks) {
    attachInfo.mViewRootImpl.mViewFrameInfo.markDrawStart();

    updateRootDisplayList(view, callbacks);

    // register animating rendernodes which started animating prior to renderer
    // creation, which is typical for animators started prior to first draw
    if (attachInfo.mPendingAnimatingRenderNodes != null) {
        final int count = attachInfo.mPendingAnimatingRenderNodes.size();
        for (int i = 0; i < count; i++) {
            registerAnimatingRenderNode(
                attachInfo.mPendingAnimatingRenderNodes.get(i));
        }
        attachInfo.mPendingAnimatingRenderNodes.clear();
        // We don't need this anymore as subsequent calls to
        // ViewRootImpl#attachRenderNodeAnimator will go directly to us.
        attachInfo.mPendingAnimatingRenderNodes = null;
    }

    final FrameInfo frameInfo = attachInfo.mViewRootImpl.getUpdatedFrameInfo();

    int syncResult = syncAndDrawFrame(frameInfo);
    if ((syncResult & SYNC_LOST_SURFACE_REWARD_IF_FOUND) != 0) {
        Log.w("OpenGLRenderer", "Surface lost, forcing relayout");
        // We lost our surface. For a relayout next frame which should give us a new
        // surface from WindowManager, which hopefully will work.
        attachInfo.mViewRootImpl.mForceNextWindowRelayout = true;
        attachInfo.mViewRootImpl.requestLayout();
    }
    if ((syncResult & SYNC_REDRAW_REQUESTED) != 0) {
        attachInfo.mViewRootImpl.invalidate();
    }
}
```





---

## 补充

### ActivityClientRecord

这个类的作用是为 Activity记账用的，记录了Activity的一些状态以及配置信息。例如 NonConfigurationInstances，它记录ViewModelStroe，所以在Activity重建时可以恢复ViewModel。

```java
 public static final class ActivityClientRecord {
     
     @UnsupportedAppUsage
     Intent intent;
     
     // activity 实例
     @UnsupportedAppUsage
     Activity activity;
     Window window;
     Activity parent;
     
     @UnsupportedAppUsage
     public IBinder token;
     public IBinder assistToken;
     // A reusable token for other purposes, e.g. content capture, translation. It shouldn't be
     // used without security checks
     public IBinder shareableActivityToken;
     // The token of the TaskFragment that embedded this activity.
     @Nullable public IBinder mTaskFragmentToken;
     int ident;

     
     String referrer;
     IVoiceInteractor voiceInteractor;
     Bundle state;
     PersistableBundle persistentState;
     
     String embeddedID;
     // 记录配置， 例如 ViewModelStore
     Activity.NonConfigurationInstances lastNonConfigurationInstances;
     // TODO(lifecycler): Use mLifecycleState instead.
     @UnsupportedAppUsage
     boolean paused;
     @UnsupportedAppUsage
     boolean stopped;
     boolean hideForNow;
     Configuration createdConfig;
     Configuration overrideConfig;
     // Used for consolidating configs before sending on to Activity.
     private Configuration tmpConfig = new Configuration();
     // Callback used for updating activity override config and camera compat control state.
     ViewRootImpl.ActivityConfigCallback activityConfigCallback;
     ActivityClientRecord nextIdle;

     // Indicates whether this activity is currently the topmost resumed one in the system.
     // This holds the last reported value from server.
     boolean isTopResumedActivity;
     // This holds the value last sent to the activity. This is needed, because an update from
     // server may come at random time, but we always need to report changes between ON_RESUME
     // and ON_PAUSE to the app.
     boolean lastReportedTopResumedState;

     ProfilerInfo profilerInfo;

     @UnsupportedAppUsage
     ActivityInfo activityInfo;
     @UnsupportedAppUsage
     CompatibilityInfo compatInfo;
     @UnsupportedAppUsage
     public LoadedApk packageInfo;

     List<ResultInfo> pendingResults;
     List<ReferrerIntent> pendingIntents;

     boolean startsNotResumed;
     public final boolean isForward;
     int pendingConfigChanges;
     // Whether we are in the process of performing on user leaving.
     boolean mIsUserLeaving;

     Window mPendingRemoveWindow;
     WindowManager mPendingRemoveWindowManager;
     @UnsupportedAppUsage
     boolean mPreserveWindow;

     /** The options for scene transition. */
     ActivityOptions mActivityOptions;

     /** Whether this activiy was launched from a bubble. */
     boolean mLaunchedFromBubble;

     @LifecycleState
     private int mLifecycleState = PRE_ON_CREATE;

     private SizeConfigurationBuckets mSizeConfigurations;
 }
```

### DecorView

DecorView 继承自 FrameLayout，它包含了我们传入的customView，关系是 `decorView -> mContentParent -> customView`

* `decorView`是 `mContentParent`的 parent。
* `mContentParent` 是我们传入的 View 的 parent。



[DecorView.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/com/android/internal/policy/DecorView.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=299)

```java
public class DecorView extends FrameLayout implements RootViewSurfaceTaker, WindowCallbacks {
    
    @UnsupportedAppUsage
    private PhoneWindow mWindow;
	// 这个 ViewGroup 包含了我们通过setContentView()传入的布局。
    ViewGroup mContentRoot;

}
```



### ViewRootImpl 结构

ViewRootImpl 内部持有了 Decor ，是连接 WindowManager 和 DecorView的纽带，它会和WMS、Surface等交互。

涉及 和 WMS 间的Binder通信：

* 内部持有一个`W mWindow`，它是ViewRootImpl内部的一个Binder服务，后续会传给WMS 供它来**向ViewRootImpl发送事件通知，类似于一个回调接口**。
* ViewRootImpl 向 WMS发送 `IWindowManager.openSession() `请求 获取另一个Binder： `IWindowSession`，从而和WMS建立了一个Session，后续**使用Session来向WMS 发起请求**。

ViewRootImpl 和 Surface 以及 SurfaceFlinger之间的交互：

Surface 就是一块画布它包含一个RawBuffer，ViewRoot的子View都是在这上面绘制，也就是往RawBuffer上填充数据。最后Surface 会和 SurfaceFlinger 进行交互。

* ViewRootImpl：提供 Surface 给子View绘制。
* Surface：操作RawBuffer
* SurfaceFlinger：管理RawBuffer

[ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=920)

```java
public final class ViewRootImpl implements ViewParent ... {
    // 处理自身的消息，requsetLayout()等操作就是向这里发送消息
	final ViewRootHandler mHandler = new ViewRootHandler();
    
    // ViewRootImpl内部的一个Binder服务，类似于回调。
    final W mWindow;
    // decorview
    View mView;
    
    // 用于协调绘制请求、接收Vsync
    final Choreographer mChoreographer;
    // 创建了一个 Surface
    public final Surface mSurface = new Surface();
    private final SurfaceControl mSurfaceControl = new SurfaceControl();
    private final SurfaceSession mSurfaceSession = new SurfaceSession();
	// 
    private BLASTBufferQueue mBlastBufferQueue;
    //
    public ViewRootImpl(Context context, Display display) {
        this(context, display, WindowManagerGlobal.getWindowSession(), new WindowLayout());
    }
    
    // IWindowSession 用于向WMS中的WindowSession发送请求。
    // IWindowSession 是通过IWindowManager.openSession() 获得的。IWindowManager 和 IWindowSession，是两个不同的Binder接口。
    public ViewRootImpl(@UiContext Context context, Display display, IWindowSession session,
            boolean useSfChoreographer) {
        mContext = context;
        mWindowSession = session;
        mDisplay = display;
        mBasePackageName = context.getBasePackageName();
        // 获取当前线程
        mThread = Thread.currentThread();
        mLocation = new WindowLeaked(null);
        mLocation.fillInStackTrace();
        mWidth = -1;
        mHeight = -1;
        mDirty = new Rect();
        mWinFrame = new Rect();
        mWindow = new W(this);
        mLeashToken = new Binder();
        mTargetSdkVersion = context.getApplicationInfo().targetSdkVersion;
        mViewVisibility = View.GONE;
        mTransparentRegion = new Region();
        mPreviousTransparentRegion = new Region();
        mFirst = true; // true for the first time the view is added
        mPerformContentCapture = true; // also true for the first time the view is added
        mAdded = false;
        mAttachInfo = new View.AttachInfo(mWindowSession, mWindow, display, this, mHandler, this,
                context);
        mCompatibleVisibilityInfo = new SystemUiVisibilityInfo();
        mAccessibilityManager = AccessibilityManager.getInstance(context);
        mHighContrastTextManager = new HighContrastTextManager();
        mViewConfiguration = ViewConfiguration.get(context);
        mDensity = context.getResources().getDisplayMetrics().densityDpi;
        mNoncompatDensity = context.getResources().getDisplayMetrics().noncompatDensityDpi;
        mFallbackEventHandler = new PhoneFallbackEventHandler(context);
        // TODO(b/222696368): remove getSfInstance usage and use vsyncId for transactions
        // 初始化 mChoreographer。
        mChoreographer = useSfChoreographer
                ? Choreographer.getSfInstance() : Choreographer.getInstance();
        mDisplayManager = (DisplayManager)context.getSystemService(Context.DISPLAY_SERVICE);
        mInsetsController = new InsetsController(new ViewRootInsetsControllerHost(this));
        mHandwritingInitiator = new HandwritingInitiator(mViewConfiguration,
                mContext.getSystemService(InputMethodManager.class));

        String processorOverrideName = context.getResources().getString(
                                    R.string.config_inputEventCompatProcessorOverrideClassName);
        if (processorOverrideName.isEmpty()) {
            // No compatibility processor override, using default.
            mInputCompatProcessor = new InputEventCompatProcessor(context);
        } else {
            InputEventCompatProcessor compatProcessor = null;
            try {
                final Class<? extends InputEventCompatProcessor> klass =
                        (Class<? extends InputEventCompatProcessor>) Class.forName(
                                processorOverrideName);
                compatProcessor = klass.getConstructor(Context.class).newInstance(context);
            } catch (Exception e) {
                Log.e(TAG, "Unable to create the InputEventCompatProcessor. ", e);
            } finally {
                mInputCompatProcessor = compatProcessor;
            }
        }

        if (!sCompatibilityDone) {
            sAlwaysAssignFocus = mTargetSdkVersion < Build.VERSION_CODES.P;

            sCompatibilityDone = true;
        }

        loadSystemProperties();
        mImeFocusController = new ImeFocusController(this);
        AudioManager audioManager = mContext.getSystemService(AudioManager.class);
        mFastScrollSoundEffectsEnabled = audioManager.areNavigationRepeatSoundEffectsEnabled();

        mScrollCaptureRequestTimeout = SCROLL_CAPTURE_REQUEST_TIMEOUT_MILLIS;
        mOnBackInvokedDispatcher = new WindowOnBackInvokedDispatcher(
                context.getApplicationInfo().isOnBackInvokedCallbackEnabled());
    }
    
    // 继承自IWindow.Stub，是ViewRootImpl内部的一个Binder服务。
    // wms 会使用它来向 ViewRootImpl发送事件通知。类似于回调
    static class W extends IWindow.Stub {
        @Override
        public void dispatchDragEvent(DragEvent event) {
            // drag
        }

        @Override
        public void moved(int newX, int newY) {
            // move
        }
        @Override
        public void updatePointerIcon(float x, float y) {
            // ACTION_HOVER_MOVE
        }
        // ...
    }
}
```



### ViewRoot和 WMS间的交互

* ViewRootImpl 通过Binder 通信向 WMS 获取到一个 IWindowSession，并将自身的 IWindow 传给了WMS，用于接收事件回调。
* WMS所在的system_server进程收到按键事件。
* WMS找到当前位于屏幕顶端的UI的所在进程，获取对应 IWindow 对象。
* WMS调用 IWindow 进行Binder通信，将事件发送给ViewRootImpl。
* ViewRootImpl 根据位置信息发送给具体的View。

> WindowManagerService 继承自 IWindowManger.Stub，自身就能进行Binder通信，那么为什么还需要一个 IWindowSession呢？
>
> 有很多应用进程会和 WMS进行通信，定义一个Session 来表示WMS和一个应用进程的通信会话，更加方便管理。

> [WindowManagerGlobal.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/WindowManagerGlobal.java;l=182;)

```java
class WindowManagerGlobal ... {
    
	@UnsupportedAppUsage
    public static IWindowSession getWindowSession() {
        synchronized (WindowManagerGlobal.class) {
            if (sWindowSession == null) {
                try {
                    // Emulate the legacy behavior.  The global instance of InputMethodManager
                    // was instantiated here.
                    // TODO(b/116157766): Remove this hack after cleaning up @UnsupportedAppUsage
                    InputMethodManager.ensureDefaultInstanceForDefaultDisplayIfNecessary();
                    // 获取 IWindowManager 和 WMS 进行binder通信。
                    IWindowManager windowManager = getWindowManagerService();
                    // 通过binder请求获取 IWindowSession
                    sWindowSession = windowManager.openSession(
                            new IWindowSessionCallback.Stub() {
                                @Override
                                public void onAnimatorScaleChanged(float scale) {
                                    ValueAnimator.setDurationScale(scale);
                                }
                            });
                } catch (RemoteException e) {
                    throw e.rethrowFromSystemServer();
                }
            }
            return sWindowSession;
        }
    } 	


	@UnsupportedAppUsage
    public static IWindowManager getWindowManagerService() {
        synchronized (WindowManagerGlobal.class) {
            if (sWindowManagerService == null) {
                // ServiceManager 内部持有IServiceManger 和 ServiceManger通信
                // 它的主要作用是对获取到IBinder根据name做了一个缓存，从而避免频繁binder通信。
                sWindowManagerService = IWindowManager.Stub.asInterface(
                        ServiceManager.getService("window"));
                try {
                    if (sWindowManagerService != null) {
                        ValueAnimator.setDurationScale(
                                sWindowManagerService.getCurrentAnimatorScale());
                        sUseBLASTAdapter = sWindowManagerService.useBLAST();
                    }
                } catch (RemoteException e) {
                    throw e.rethrowFromSystemServer();
                }
            }
            return sWindowManagerService;
        }
    }
}
```





#### 【WindowManagerService.openSession()】

这是一个Binder请求，WMS会将一个 IWindowSession(也是一个Binder) 返回给ViewRootImpl使用。然后ViewRootImpl 可以后续会通过这个 IWindowSession 向 WMS中发送Binder请求。

> [WindowManagerService.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java;l=357)

```java
public class WindowManagerService extends IWindowManager.Stub
        implements Watchdog.Monitor, WindowManagerPolicy.WindowManagerFuncs {

    // 返回 IWindowSession
    @Override
    public IWindowSession openSession(IWindowSessionCallback callback) {
        return new Session(this, callback);
    }
    
}
```



#### 【Session.addToDisplayAsUser()】

ViewRootImpl 将 IWindow 传给了 IWindowSession， 这样WMS 就能通过 IWindow向 ViewRootImpl发送回调事件。

[Session.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/Session.java;l=198)

```java
class Session extends IWindowSession.Stub implements IBinder.DeathRecipient {	
    final WindowManagerService mService;
    
	@Override
    public int addToDisplayAsUser(IWindow window, WindowManager.LayoutParams attrs,
            int viewVisibility, int displayId, int userId, InsetsVisibilities requestedVisibilities,
            InputChannel outInputChannel, InsetsState outInsetsState,
            InsetsSourceControl[] outActiveControls) {
        // 调用 WMS的 addWindow。
        return mService.addWindow(this, window, attrs, viewVisibility, displayId, userId,
                requestedVisibilities, outInputChannel, outInsetsState, outActiveControls);
    }
}
```



#### 【WindowManagerService.addWindow()】

在这里创建了一个 `WindowState`。

[WindowManagerService.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java;l=1452)

```java
public int addWindow(Session session, IWindow client, LayoutParams attrs, int viewVisibility,
            int displayId, int requestUserId, InsetsVisibilities requestedVisibilities,
            InputChannel outInputChannel, InsetsState outInsetsState,
            InsetsSourceControl[] outActiveControls, Rect outAttachedFrame,
            float[] outSizeCompatScale) {
		// parentWindow
        WindowState parentWindow = null;

		// ....
        synchronized (mGlobalLock) {
            if (!mDisplayReady) {
                throw new IllegalStateException("Display has not been initialialized");
            }

            final DisplayContent displayContent = getDisplayContentOrCreate(displayId, attrs.token);
            ActivityRecord activity = null;
            final boolean hasParent = parentWindow != null;
            
            WindowToken token = displayContent.getWindowToken(
                    hasParent ? parentWindow.mAttrs.token : attrs.token);
            // ... 
			// 创建一个 WindowState
            final WindowState win = new WindowState(this, session, client, token, parentWindow,
                    appOp[0], attrs, viewVisibility, session.mUid, userId,
                    session.mCanAddInternalSystemWindow);
            // ...
            final boolean openInputChannels = (outInputChannel != null
                    && (attrs.inputFeatures & INPUT_FEATURE_NO_INPUT_CHANNEL) == 0);
            if  (openInputChannels) {
                win.openInputChannel(outInputChannel);
            }

            // From now on, no exceptions or errors allowed!
            res = ADD_OKAY;
			// 调用 attach
            win.attach();
            mWindowMap.put(client.asBinder(), win);
            //
            win.initAppOpsState();

            final boolean suspended = mPmInternal.isPackageSuspended(win.getOwningPackage(),
                    UserHandle.getUserId(win.getOwningUid()));
            win.setHiddenWhileSuspended(suspended);

            final boolean hideSystemAlertWindows = !mHidingNonSystemOverlayWindows.isEmpty();
            win.setForceHideNonSystemOverlayWindowIfNeeded(hideSystemAlertWindows);

            boolean imMayMove = true;

            
            win.mToken.addWindow(win);
			//
            final WindowStateAnimator winAnimator = win.mWinAnimator;
            winAnimator.mEnterAnimationPending = true;
            winAnimator.mEnteringAnimation = true;
            // Check if we need to prepare a transition for replacing window first.
            // ...
        }

        Binder.restoreCallingIdentity(origId);

        return res;
    }

```



#### 【WindowState.attach()】

内部调用`Session.windowAddedLocked()` 函数 创建一个 `SurfaceSession`。

[WindowState.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/WindowState.java;l=1252)

```java
class WindowState ... { 	

	void attach() {
        if (DEBUG) Slog.v(TAG, "Attaching " + this + " token=" + mToken);
        mSession.windowAddedLocked();
    }
}
```

#### 【Session.windowAddedLocked()】

这里创建了 一个 SurfaceSession。

> [Session.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/Session.java;l=198)

```java
class Session ... {

	void windowAddedLocked() {
        if (mPackageName == null) {
            final WindowProcessController wpc = mService.mAtmService.mProcessMap.getProcess(mPid);
            if (wpc != null) {
                mPackageName = wpc.mInfo.packageName;
                mRelayoutTag = "relayoutWindow: " + mPackageName;
            } else {
                Slog.e(TAG_WM, "Unknown process pid=" + mPid);
            }
        }
        if (mSurfaceSession == null) {
			// 创建了一个 SurfaceSession
            mSurfaceSession = new SurfaceSession();
            ProtoLog.i(WM_SHOW_TRANSACTIONS, "  NEW SURFACE SESSION %s", mSurfaceSession);
            mService.mSessions.add(this);
            if (mLastReportedAnimatorScale != mService.getCurrentAnimatorScale()) {
                mService.dispatchNewAnimatorScaleLocked(this);
            }
        }
        mNumWindow++;
    }
}
```



### 【ServiceManager.java/SystemServiceRegistry.java】

* ServiceManager：负责和 servicemanager 进程通信，并缓存获取到IBinder。
* SystemServiceRegistry：应用端都是从这里获取的，它将这些binder服务接口重新包装后返回给上层使用。

#### 【ServiceManager.java】

ServiceManager 中管理的都是Binder服务，它内部持有IServiceManger 用于和 servicemanager进程通信,  同时对获取过的IBinder 根据name做了一个缓存，从而避免频繁binder通信。。

```java
public final class ServiceManager {
    // 用于和 servicemanager进程通信的biner接口
    private static IServiceManager sServiceManager;

    /**
     * Cache for the "well known" services, such as WM and AM.
     * 缓存
     */
    private static Map<String, IBinder> sCache = new ArrayMap<String, IBinder>();
    
    public static IBinder getService(String name) {
        try {
            // 首先从缓存中读取
            IBinder service = sCache.get(name);
            if (service != null) {
                return service;
            } else {
                // 没有再去获取
                return Binder.allowBlocking(rawGetService(name));
            }
        } catch (RemoteException e) {
            Log.e(TAG, "error in getService", e);
        }
        return null;
    }
    
    private static IBinder rawGetService(String name) throws RemoteException {
        final long start = sStatLogger.getTime();
        // 向 servicemanager进程 发送Binder请求获取服务。
        final IBinder binder = getIServiceManager().getService(name);
        // .....
        return binder;
    }
}
```





#### 【SystemServiceRegistry.java】

SystemServiceRegistry 通过静态方法块注册了很多 ServiceFetcher，会返回一个binder服务的代理类给上层使用操作。

> [SystemServiceRegistry.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/SystemServiceRegistry.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1560)

```java
class SystemServiceRegistry  {
    static {
        // ... 还有很多
        registerService(Context.WINDOW_SERVICE, WindowManager.class,
                new CachedServiceFetcher<WindowManager>() {
            @Override
            public WindowManager createService(ContextImpl ctx) {
                // 其实就是之间创建一个 WindowManagerImpl
                return new WindowManagerImpl(ctx); 
            }});
        // 例如 LOCATION_SERVICE 这个就是获取的Binder通信对象，只不过包装了一层。
        registerService(Context.LOCATION_SERVICE, LocationManager.class,
                new CachedServiceFetcher<LocationManager>() {
            @Override
            public LocationManager createService(ContextImpl ctx) throws ServiceNotFoundException {
                IBinder b = ServiceManager.getServiceOrThrow(Context.LOCATION_SERVICE);
                return new LocationManager(ctx, ILocationManager.Stub.asInterface(b));
            }});
    }
    
    // 注册
    private static <T> void registerService(@NonNull String serviceName,
            @NonNull Class<T> serviceClass, @NonNull ServiceFetcher<T> serviceFetcher) {
        SYSTEM_SERVICE_NAMES.put(serviceClass, serviceName);
        SYSTEM_SERVICE_FETCHERS.put(serviceName, serviceFetcher);
        SYSTEM_SERVICE_CLASS_NAMES.put(serviceName, serviceClass.getSimpleName());
    }
    
	// 获取服务。
    public static Object getSystemService(ContextImpl ctx, String name) {
        if (name == null) {
            return null;
        }
        // 查询 fetcher
        final ServiceFetcher<?> fetcher = SYSTEM_SERVICE_FETCHERS.get(name);
        if (fetcher == null) {
            if (sEnableServiceNotFoundWtf) {
                Slog.wtf(TAG, "Unknown manager requested: " + name);
            }
            return null;
        }
		// 从 fetcher 中获取 service
        final Object ret = fetcher.getService(ctx);
        if (sEnableServiceNotFoundWtf && ret == null) {
            // Some services do return null in certain situations, so don't do WTF for them.
            switch (name) {
                case Context.CONTENT_CAPTURE_MANAGER_SERVICE:
                case Context.APP_PREDICTION_SERVICE:
                case Context.INCREMENTAL_SERVICE:
                case Context.ETHERNET_SERVICE:
                case Context.VIRTUALIZATION_SERVICE:
                    return null;
            }
            Slog.wtf(TAG, "Manager wrapper not available: " + name);
            return null;
        }
        return ret;
    }
}
```

### Choreographer

Choreographer 字面意思是编舞者，负责协调绘制，保证vsync到来时立即执行绘制。

它是一个单例，内部维护了一个使用 mainLooper的Handler。同时它还能接收VSYNC。

Choreographer在ViewRootImpl中被使用，ViewRootImpl 会在构造函数中调用 `Choreographer.getInstance()` 来创建实例。

* **发送请求任务**：在渲染流程中的 `viewRootImpl.scheduleTraversals()` 方法中会通过  `Choreographer.postCallback()` 发送绘制请求 `CALLBACK_TRAVERSAL`。
* **监听vsync**：Choreographer 接收到请求后会将 callback保存在 callbakc队列中，接着通过 FrameHandler 来发送异步消息，协调执行绘制请求。
  * 4.1后默认开启vsync，此时会调用 `scheduleVsyncLocked()` ，通过 FrameDisplayEventReceiver 注册监听vsync，接收到vsync后会调用 `doFrame()`。
  * 不开启vsync时，则是手动模拟vsync，通过计算得到下一帧时间，不过最终调用的也是 `doFrame()`。
* **vsync回调执行任务**：`doFrame()` 中会按照一定顺序执行callback队列中的任务，也就是调用了 `callback.run()`，执行完毕后就从callback队列中移除

```java
class Choreographer {
    // 默认true，开始vsync
    private static final boolean USE_VSYNC = SystemProperties.getBoolean(
        "debug.choreographer.vsync", true);
    //
    private final FrameDisplayEventReceiver mDisplayEventReceiver;
    
    private static final ThreadLocal<Choreographer> sThreadInstance =
            new ThreadLocal<Choreographer>() {
        // 重写了 initialValue()，使用当前线程的looper 创建 Choreographer。
        @Override
        protected Choreographer initialValue() {
            Looper looper = Looper.myLooper();
            if (looper == null) {
                throw new IllegalStateException("The current thread must have a looper!");
            }
            Choreographer choreographer = new Choreographer(looper, VSYNC_SOURCE_APP);
            if (looper == Looper.getMainLooper()) {
                mMainInstance = choreographer;
            }
            return choreographer;
        }
    };
    
    public static Choreographer getInstance() {
        // 从TLS中获取
        return sThreadInstance.get();
    }
    
    private Choreographer(Looper looper, int vsyncSource) {
        mLooper = looper;
        // 创建了一个Handler 传入的是当前线程的Looper，也就是mainLooper
        mHandler = new FrameHandler(looper);
        // USE_VSYNC默认ture，所以直这里会注册监听vsync
        mDisplayEventReceiver = USE_VSYNC
                ? new FrameDisplayEventReceiver(looper, vsyncSource)
                : null;
        mLastFrameTimeNanos = Long.MIN_VALUE;
		// 计算每一帧的时间周期。不同设备不同，例如60hz就是 16ms。
        mFrameIntervalNanos = (long)(1000000000 / getRefreshRate());
		// 创建回调队列，保存的就是我们 调用 postCallback 发送的任务。
        mCallbackQueues = new CallbackQueue[CALLBACK_LAST + 1];
        for (int i = 0; i <= CALLBACK_LAST; i++) {
            mCallbackQueues[i] = new CallbackQueue();
        }
        // b/68769804: For low FPS experiments.
        setFPSDivisor(SystemProperties.getInt(ThreadedRenderer.DEBUG_FPS_DIVISOR, 1));
    }
    
    // 所有的postCallback api 最终都是调用的这个。
    // token 一般都是null, 仅当 CALLBACK_ANIMATION 时有值，会在最终执行callback存在差异，不过不影响分析流程。
    private void postCallbackDelayedInternal(int callbackType,
            Object action, Object token, long delayMillis) {
        synchronized (mLock) {
            final long now = SystemClock.uptimeMillis();
            final long dueTime = now + delayMillis;
            // 加入到队列中
            mCallbackQueues[callbackType].addCallbackLocked(dueTime, action, token);

            if (dueTime <= now) { // 立即执行
                scheduleFrameLocked(now);
            } else { // 发送了一个异步延迟消息
                Message msg = mHandler.obtainMessage(MSG_DO_SCHEDULE_CALLBACK, action);
                msg.arg1 = callbackType;
                msg.setAsynchronous(true);
                mHandler.sendMessageAtTime(msg, dueTime);
            }
        }
    }
    
    private void scheduleFrameLocked(long now) {
        // 过滤去重
        if (!mFrameScheduled) {
            mFrameScheduled = true;
            if (USE_VSYNC) { // 4.1后就默认开启 vsync了
                // 判断了一下是不是在looperThread 同一线程内调用，是的话就直接执行。
                if (isRunningOnLooperThreadLocked()) {
                    scheduleVsyncLocked();
                } else {
                    // 不是同一个线程就发送一个 MSG_DO_SCHEDULE_VSYNC 异步消息，插入到消息队头
                    // 这个消息是用于获取vsync时间的。最终调用的还是 scheduleVsyncLocked()
                    Message msg = mHandler.obtainMessage(MSG_DO_SCHEDULE_VSYNC);
                    msg.setAsynchronous(true);
                    mHandler.sendMessageAtFrontOfQueue(msg);
                }
            } else {
                // 不管vsync 时，通过手动计算下一帧的时间。sFrameDelay = 10
                final long nextFrameTime = Math.max(
                        mLastFrameTimeNanos / TimeUtils.NANOS_PER_MS + sFrameDelay, now);
                // 发送一个 MSG_DO_FRAME 异步消息
                Message msg = mHandler.obtainMessage(MSG_DO_FRAME);
                msg.setAsynchronous(true);
                mHandler.sendMessageAtTime(msg, nextFrameTime);
            }
        }
    }
    
    @UnsupportedAppUsage(maxTargetSdk = Build.VERSION_CODES.R, trackingBug = 170729553)
    private void scheduleVsyncLocked() {
        try {
            Trace.traceBegin(Trace.TRACE_TAG_VIEW, "Choreographer#scheduleVsyncLocked");
            //
            mDisplayEventReceiver.scheduleVsync();
        } finally {
            Trace.traceEnd(Trace.TRACE_TAG_VIEW);
        }
    }
    
    
    // 处理帧
    void doFrame(long frameTimeNanos, int frame,
            DisplayEventReceiver.VsyncEventData vsyncEventData) {
        final long startNanos;
        final long frameIntervalNanos = vsyncEventData.frameInterval;
        try {
            FrameData frameData = new FrameData(frameTimeNanos, vsyncEventData);
            synchronized (mLock) {
                if (!mFrameScheduled) {
                    traceMessage("Frame not scheduled");
                    return; // no work to do
                }

                long intendedFrameTimeNanos = frameTimeNanos;
                startNanos = System.nanoTime();
                // 计算时差
                final long jitterNanos = startNanos - frameTimeNanos;
                // 判断间隔是否大于了一帧的时间
                if (jitterNanos >= frameIntervalNanos) {
                    long lastFrameOffset = 0;
                    if (frameIntervalNanos == 0) {
                        Log.i(TAG, "Vsync data empty due to timeout");
                    } else {
                        // 掉帧数
                        lastFrameOffset = jitterNanos % frameIntervalNanos;
                        final long skippedFrames = jitterNanos / frameIntervalNanos;
                        // 打印掉帧信息
                        if (skippedFrames >= SKIPPED_FRAME_WARNING_LIMIT) {
                            Log.i(TAG, "Skipped " + skippedFrames + " frames!  "
                                    + "The application may be doing too much work on its main "
                                    + "thread.");
                        }
                    }
                    frameTimeNanos = startNanos - lastFrameOffset;
                    frameData.updateFrameData(frameTimeNanos);
                }
				// 回调的vsync时间小于最近一帧的时间，过滤不执行，等下一个vysnc信号
                if (frameTimeNanos < mLastFrameTimeNanos) {
                    if (DEBUG_JANK) {
                        Log.d(TAG, "Frame time appears to be going backwards.  May be due to a "
                                + "previously skipped frame.  Waiting for next vsync.");
                    }
                    traceMessage("Frame time goes backward");
                    scheduleVsyncLocked();
                    return;
                }

                if (mFPSDivisor > 1) {
                    long timeSinceVsync = frameTimeNanos - mLastFrameTimeNanos;
                    if (timeSinceVsync < (frameIntervalNanos * mFPSDivisor) && timeSinceVsync > 0) {
                        traceMessage("Frame skipped due to FPSDivisor");
                        scheduleVsyncLocked();
                        return;
                    }
                }

                mFrameInfo.setVsync(intendedFrameTimeNanos, frameTimeNanos,
                        vsyncEventData.preferredFrameTimeline().vsyncId,
                        vsyncEventData.preferredFrameTimeline().deadline, startNanos,
                        vsyncEventData.frameInterval);
                // 当前帧执行完毕，重置
                mFrameScheduled = false;
                // 保存最近一帧的相关信息
                mLastFrameTimeNanos = frameTimeNanos; // 时间
                mLastFrameIntervalNanos = frameIntervalNanos; // 时长
                mLastVsyncEventData = vsyncEventData; //vsync event
            }

            AnimationUtils.lockAnimationClock(frameTimeNanos / TimeUtils.NANOS_PER_MS);

            mFrameInfo.markInputHandlingStart();
            // 依次执行 callback
            doCallbacks(Choreographer.CALLBACK_INPUT, frameData, frameIntervalNanos);

            mFrameInfo.markAnimationsStart();
            doCallbacks(Choreographer.CALLBACK_ANIMATION, frameData, frameIntervalNanos);
            doCallbacks(Choreographer.CALLBACK_INSETS_ANIMATION, frameData,
                    frameIntervalNanos);

            mFrameInfo.markPerformTraversalsStart();
            doCallbacks(Choreographer.CALLBACK_TRAVERSAL, frameData, frameIntervalNanos);
			
            doCallbacks(Choreographer.CALLBACK_COMMIT, frameData, frameIntervalNanos);
        } finally {
            AnimationUtils.unlockAnimationClock();
            Trace.traceEnd(Trace.TRACE_TAG_VIEW);
        }
    }
}    
```



#### FrameHandler

负责发送异步消息，协调执行绘制。

```java
	private final class FrameHandler extends Handler {
        public FrameHandler(Looper looper) {
            super(looper);
        }

        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case MSG_DO_FRAME:
                    // 不开启vsync时发送的消息，直接执行绘制
                    doFrame(System.nanoTime(), 0, new DisplayEventReceiver.VsyncEventData());
                    break;
                case MSG_DO_SCHEDULE_VSYNC:
                    // 调用的是 scheduleVsyncLocked()
                    doScheduleVsync();
                    break;
                case MSG_DO_SCHEDULE_CALLBACK:
                    doScheduleCallback(msg.arg1);
                    break;
            }
        }
    }
```

#### FrameDisplayEventReceiver

负责注册监听 vsync 信号，FrameDisplayEventReceiver主要就是实现了vsync回调后的逻辑，其他的实现都在 父类 `DisplayEventReceiver` 中。

* vsync 信号会导致 `onVsync()` 被调用。此时又会发送一个异步消息，这个消息会调用自身的 `run()`函数。
* 在 `run()` 中会调用 `doFrame()` 执行绘制。

```java
private final class FrameDisplayEventReceiver extends DisplayEventReceiver
            implements Runnable {
    private boolean mHavePendingVsync;
    private long mTimestampNanos;
    private int mFrame;
    private VsyncEventData mLastVsyncEventData = new VsyncEventData();

    public FrameDisplayEventReceiver(Looper looper, int vsyncSource) {
        super(looper, vsyncSource, 0);
    }

    // vsync 回调
    // timestampNanos：vsync信号时间
    // physicalDisplayId：displayId
    // frame：帧id，
    @Override
    public void onVsync(long timestampNanos, long physicalDisplayId, int frame,
                        VsyncEventData vsyncEventData) {
        try {

            long now = System.nanoTime();
            if (timestampNanos > now) {
                timestampNanos = now;
            }

            if (mHavePendingVsync) {
                Log.w(TAG, "Already have a pending vsync event.  There should only be "
                      + "one at a time.");
            } else {
                mHavePendingVsync = true;
            }

            mTimestampNanos = timestampNanos;
            mFrame = frame;
            mLastVsyncEventData = vsyncEventData;
            // callback 是自身，调用 run()
            Message msg = Message.obtain(mHandler, this);
            msg.setAsynchronous(true);
            mHandler.sendMessageAtTime(msg, timestampNanos / TimeUtils.NANOS_PER_MS);
        } finally {
            Trace.traceEnd(Trace.TRACE_TAG_VIEW);
        }
    }

    // 执行 绘制
    @Override
    public void run() {
        mHavePendingVsync = false;
        doFrame(mTimestampNanos, mFrame, mLastVsyncEventData);
    }
}
```

##### DisplayEventReceiver

```java
public abstract class DisplayEventReceiver {   
	public DisplayEventReceiver(Looper looper, int vsyncSource, int eventRegistration) {
        if (looper == null) {
            throw new IllegalArgumentException("looper must not be null");
        }

        mMessageQueue = looper.getQueue();
        // 这里初始化传入了自身，其实就是将自身作为回调使用，会调用自身的 onVsync() 函数。
        mReceiverPtr = nativeInit(new WeakReference<DisplayEventReceiver>(this), mMessageQueue,
                vsyncSource, eventRegistration);
    }
    
    @UnsupportedAppUsage
    public void scheduleVsync() {
        if (mReceiverPtr == 0) {
            Log.w(TAG, "Attempted to schedule a vertical sync pulse but the display event "
                    + "receiver has already been disposed.");
        } else {
            // 调用JNI
            nativeScheduleVsync(mReceiverPtr);
        }
    }

    @FastNative
    private static native void nativeScheduleVsync(long receiverPtr);
}
```



#### android_view_DisplayEventReceiver.cpp

> [android_view_DisplayEventReceiver.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/jni/android_view_DisplayEventReceiver.cpp;drc=9c4ad291f012ed5f9ee9b131106e9732a848740f;l=245?q=nativeScheduleVsync)

```cpp
static void nativeScheduleVsync(JNIEnv* env, jclass clazz, jlong receiverPtr) {
    sp<NativeDisplayEventReceiver> receiver =
            reinterpret_cast<NativeDisplayEventReceiver*>(receiverPtr);
    // 调用 scheduleVsync()
    status_t status = receiver->scheduleVsync();
    if (status) {
        String8 message;
        message.appendFormat("Failed to schedule next vertical sync pulse.  status=%d", status);
        jniThrowRuntimeException(env, message.string());
    }
}


status_t DisplayEventDispatcher::scheduleVsync() {
    // mWaitingForVsync 是为了过滤重复调用
    if (!mWaitingForVsync) {
        // Drain all pending events.
        nsecs_t vsyncTimestamp;
        PhysicalDisplayId vsyncDisplayId;
        uint32_t vsyncCount;
        VsyncEventData vsyncEventData;
        // processPendingEvents 这个函数用于获取 最近的 vsync 事件
        if (processPendingEvents(&vsyncTimestamp, &vsyncDisplayId, &vsyncCount, &vsyncEventData)) {
            ALOGE("dispatcher %p ~ last event processed while scheduling was for %" PRId64 "", this,
                  ns2ms(static_cast<nsecs_t>(vsyncTimestamp)));
        }
		// 请求下一个vsync
        status_t status = mReceiver.requestNextVsync();
        if (status) {
            ALOGW("Failed to request next vsync, status=%d", status);
            return status;
        }

        mWaitingForVsync = true;
        mLastScheduleVsyncTime = systemTime(SYSTEM_TIME_MONOTONIC);
    }
    return OK;
}

```



#### DisplayEventReceiver.cpp

```cpp
// 和surfaceFlinger 通讯的一个binder接口，对应EventThreadConnection
sp<IDisplayEventConnection> mEventConnection;
status_t DisplayEventReceiver::requestNextVsync() {
    if (mEventConnection != nullptr) {
        // 发起 binder 请求
        mEventConnection->requestNextVsync();
        return NO_ERROR;
    }
    return mInitError.has_value() ? mInitError.value() : NO_INIT;
}
```



#### EventThread.cpp

这里会根据 VSyncRequest的值 来做不同的处理

[EventThread.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/services/surfaceflinger/Scheduler/EventThread.cpp)

```cpp
binder::Status EventThreadConnection::requestNextVsync() {
    ATRACE_CALL();
    mEventThread->requestNextVsync(this);
    return binder::Status::ok();
}

void EventThread::requestNextVsync(const sp<EventThreadConnection>& connection) {
    if (connection->resyncCallback) {
        connection->resyncCallback();
    }

    std::lock_guard<std::mutex> lock(mMutex);

    if (connection->vsyncRequest == VSyncRequest::None) {
        // 默认先走这
        connection->vsyncRequest = VSyncRequest::Single;
        // 唤醒所有 mCondition.wait() 的地方
        // 这里对应threadMain()函数，唤醒后会发送 vsync事件, 最终回调到应用层, 发送后会将事件移除
        mCondition.notify_all();
    } else if (connection->vsyncRequest == VSyncRequest::SingleSuppressCallback) {
        connection->vsyncRequest = VSyncRequest::Single;
    }
}

enum class VSyncRequest {
    // 默认值
    None = -2,
    // Single wakes up for the next two frames to avoid scheduler overhead
    // 请求一次，回调一次
    Single = -1,
    // SingleSuppressCallback only wakes up for the next frame
    SingleSuppressCallback = 0,
    // 周期循环
    Periodic = 1,
    // Subsequent values are periods.
};
```







#### Callback事件类型

收到vsync信号时，这些事件执行的优先级为： 1 最高，5最低。

| 事件                      | 优先级 | 说明           |
| ------------------------- | ------ | -------------- |
| CALLBACK_INPUT            | 1      | 输入事件       |
| CALLBACK_ANIMATION        | 2      | 动画           |
| CALLBACK_INSETS_ANIMATION | 3      | 插入更新的动画 |
| CALLBACK_TRAVERSAL        | 4      | 绘制           |
| CALLBACK_COMMIT           | 5      | 提交           |



