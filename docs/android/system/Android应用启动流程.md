# Android应用程序启动流程

当我们在Launcher中点击一个应用图标时，Launcher实际是调用了`startActivity()` 来启动应用。所以我们就从这个函数开始分析一个应用是如何被启动的。

| 核心类                         |                                                              |
| ------------------------------ | ------------------------------------------------------------ |
| ActivityThread                 | 应用程序的启动入口；在主线程中初始化消息机制。               |
| ApplicationThread              | 是应用方定义的一个Binder接口，**是AMS、ATMS和应用进程通讯的回调接口**，代表的是应用方。ApplicationThread 收到回调后会生成 Handler消息，发送给 ActivityThread 来处理。 |
| ActivityManager                | 是一个辅助类，提供 **应用进程和AMS进行Binder通讯**功能。内部持有AMS的BinderPrxy |
| **ActivityManagerService**     | 是一个核心服务位于SystemServer进程中，和应用进程间使用Binder进行通讯，负责管理Activity、Service等，后续 Activity相关的逻辑移到了 ActivityTaskManagerService中处理。 |
| ActivityTaskManager            | 是一个辅助类，提供 **应用进程和ATMS进行Binder通讯**功能。内部持有ATMS的BinderProxy |
| **ActivityTaskManagerService** | 是Android 10新增加的系统服务类，位于SystemServer进程中，承接了ActivityManagerService的部分功能（Activity、Task）；应用进程持有Proxy 向ATMS发送消息，ATMS进程实现Stub，负责处理Binder请求。例如内部通过 `startActivityAsUser()` 启动Activity。 |
|                                |                                                              |
| Instrumentation                | 负责Activity、Application生命周期相关的函数调用; 每个应用进程仅有一个Instrumentation，ActivityThread 也是通过它来创建Activity 的 |



## 1. 发起应用启动请求

我绘制了一张 发起应用启动请求的时序图，先放在前面：

![应用启动流程](./Android%E5%BA%94%E7%94%A8%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/%E5%BA%94%E7%94%A8%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.jpg)



### Activity.startActivityForResult()

在Android中启动一个应用 是通过 `Activity.startActivity()` 这个函数，Activity中存在多个 启动Activity 的方法，不过无论调用哪一个，最终都会调用到 `startActivityForResult()` 中。接着就会通过 Instrumentation 向ATMS 发起启动请求。

```java
public void startActivityForResult(@RequiresPermission Intent intent, int requestCode,
                                   @Nullable Bundle options) {
    if (mParent == null) {
        options = transferSpringboardActivityOptions(options);
        // 调用 Instrumentation.execStartActivity 并 获取返回值。
        // 传入了  ApplicationThread，是一个Binder接口，用作回调
        Instrumentation.ActivityResult ar =
            mInstrumentation.execStartActivity(
            this, mMainThread.getApplicationThread(), mToken, this,
            intent, requestCode, options);
        if (ar != null) {
            mMainThread.sendActivityResult(
                mToken, mEmbeddedID, requestCode, ar.getResultCode(),
                ar.getResultData());
        }
        if (requestCode >= 0) {
            mStartedActivity = true;
        }
        cancelInputsAndStartExitTransition(options);
    } else {
        // ...
    }
}
```

### Instrumentation.execStartActivity()

> Instrumentation 可以监控应用，负责Activity、Application生命周期相关的函数调用

`Instrumentation.execStartActivity()` 会向ATMS 发起 Binder调用，请求启动Activity。

[Instrumentation.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/app/Instrumentation.java;l=1797)

```java
	
	public ActivityResult execStartActivity(
            Context who, IBinder contextThread, IBinder token, Activity target,
            Intent intent, int requestCode, Bundle options) {
        // 转为 IApplicationThread，作为回调使用
        IApplicationThread whoThread = (IApplicationThread) contextThread;
        Uri referrer = target != null ? target.onProvideReferrer() : null;
        if (referrer != null) {
            intent.putExtra(Intent.EXTRA_REFERRER, referrer);
        }
        if (mActivityMonitors != null) {
            // 回调给监视器的流程
            // ...
        }
        try {
            intent.migrateExtraStreamToClipData(who);
            intent.prepareToLeaveProcess(who);
            // 调用ATMS的 startActivity()，这里发起的Binder请求
            // whoThread 是作为回调使用，后续ATMS会通过它来回调请求进程中。
            int result = ActivityTaskManager.getService().startActivity(whoThread,
                    who.getOpPackageName(), who.getAttributionTag(), intent,
                    intent.resolveTypeIfNeeded(who.getContentResolver()), token,
                    target != null ? target.mEmbeddedID : null, requestCode, 0, null, options);
            notifyStartActivityResult(result, options);
            checkStartActivityResult(result, intent);
        } catch (RemoteException e) {
            throw new RuntimeException("Failure from system", e);
        }
        return null;
    }

// 从 ServiceManger 中获取ATMS的 IBinder ，用于Binder通讯。
public class ActivityTaskManager {
    
    // 获取ATMS
    public static IActivityTaskManager getService() {
        return IActivityTaskManagerSingleton.get();
    }
	// 单例构造器
    @UnsupportedAppUsage(trackingBug = 129726065)
    private static final Singleton<IActivityTaskManager> IActivityTaskManagerSingleton =
            new Singleton<IActivityTaskManager>() {
                @Override
                protected IActivityTaskManager create() {
                    // 获取ATMS的IBinder
                    final IBinder b = ServiceManager.getService(Context.ACTIVITY_TASK_SERVICE);
                    return IActivityTaskManager.Stub.asInterface(b);
                }
            };
}
```

## 2. 进入ATMS进程

### ActivityTaskManagerService.startActivity()

此时进入到ATMS所在的进程中，ATMS 收到Binder请求后，会调用到内部的 `startActivityAsUser()`。

然后是创建了一个 `ActivityStarter`实例，交由它来处理请求。

> [ActivityTaskManagerService.java - startActivity()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/ActivityTaskManagerService.java;l=1204)

```java
public class ActivityTaskManagerService extends IActivityTaskManager.Stub {
    // 一些重要的成员变量
    final ActivityThread mSystemThread;
    H mH; // 是ATMS 自己内部的Handler
    ActivityTaskSupervisor mTaskSupervisor; // mTaskSupervisor = createTaskSupervisor();
    ActivityClientController mActivityClientController;
    RootWindowContainer mRootWindowContainer;
    WindowManagerService mWindowManager;
    // 后面启动进程会用到, AMS启动时注册到了 LocalService中。 
    ActivityManagerInternal mAmInternal;
    
    // IApplicationThread caller 用于回调回请求进程
    @Override
    public final int startActivity(IApplicationThread caller, String callingPackage,
            String callingFeatureId, Intent intent, String resolvedType, IBinder resultTo,
            String resultWho, int requestCode, int startFlags, ProfilerInfo profilerInfo,
            Bundle bOptions) {
        //
        return startActivityAsUser(caller, callingPackage, callingFeatureId, intent, resolvedType,
                resultTo, resultWho, requestCode, startFlags, profilerInfo, bOptions,
                UserHandle.getCallingUserId());
    }
	// 
	private int startActivityAsUser(IApplicationThread caller, String callingPackage,
            @Nullable String callingFeatureId, Intent intent, String resolvedType,
            IBinder resultTo, String resultWho, int requestCode, int startFlags,
            ProfilerInfo profilerInfo, Bundle bOptions, int userId, boolean validateIncomingUser) {
        final SafeActivityOptions opts = SafeActivityOptions.fromBundle(bOptions);
       	// 构建一个 ActivityStarter 来执行请求。
        return getActivityStartController().obtainStarter(intent, "startActivityAsUser") // 传入intent
                .setCaller(caller)
                .setCallingPackage(callingPackage)
                .setCallingFeatureId(callingFeatureId)
                .setResolvedType(resolvedType)
                .setResultTo(resultTo)
                .setResultWho(resultWho)
                .setRequestCode(requestCode)
                .setStartFlags(startFlags)
                .setProfilerInfo(profilerInfo)
                .setActivityOptions(opts)
                .setUserId(userId)
                .execute(); // 执行
    }

	// Supervisor
    protected ActivityTaskSupervisor createTaskSupervisor() {
        final ActivityTaskSupervisor supervisor = new ActivityTaskSupervisor(this,
                mH.getLooper());
        supervisor.initialize();
        return supervisor;
    }
    
    public void onActivityManagerInternalAdded() {
        synchronized (mGlobalLock) {
            mAmInternal = LocalServices.getService(ActivityManagerInternal.class);
            mUgmInternal = LocalServices.getService(UriGrantsManagerInternal.class);
        }
    }
}    



```

### ActivityStarter

* 根据请求 Intent 解析出 resolveInfo、activityInfo。
* 创建 ActivityRecord。
* 权限校验。
* Task的创建/复用等逻辑。

#### execute()

> [ActivityStarter.java - execute()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java;l=646)

```java
	int execute() {
        try {
            onExecutionStarted();
            // 主要是根据intent 解析出 resolveInfo、activityInfo。
            if (mRequest.activityInfo == null) {
                mRequest.resolveActivity(mSupervisor);
            }
			// ...
            int res;
            synchronized (mService.mGlobalLock) {
                // ...
                // 
                res = resolveToHeavyWeightSwitcherIfNeeded();
                // ...
                // 执行请求
                res = executeRequest(mRequest);
				// ...
                return getExternalResult(res);
            }
        } finally {
            onExecutionComplete();
        }
    }

```

#### executeRequest()

> [ActivityStarter.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java;l=848;)

```java
	private int executeRequest(Request request) {
		// ...
        final IApplicationThread caller = request.caller;
        Intent intent = request.intent;
        ActivityInfo aInfo = request.activityInfo;
        // inTask = null, 若它有值则表示activity所在task。会影响 task的复用,在创建task时也会优先使用它。
        Task inTask = request.inTask; 
        // inTaskFragment = null， 它在后面会被赋值。
        TaskFragment inTaskFragment = request.inTaskFragment;
		// 各种判断
		// ...
        if (aInfo != null) { // 检查是否有需要审查的权限, 需要就启动审查页，
            if (mService.getPackageManagerInternalLocked().isPermissionsReviewRequired(
                    aInfo.packageName, userId)) {
                 final IIntentSender target = mService.getIntentSenderLocked(
                        ActivityManager.INTENT_SENDER_ACTIVITY, callingPackage, callingFeatureId,
                        callingUid, userId, null, null, 0, new Intent[]{intent},
                        new String[]{resolvedType}, PendingIntent.FLAG_CANCEL_CURRENT
                                | PendingIntent.FLAG_ONE_SHOT, null);

                Intent newIntent = new Intent(Intent.ACTION_REVIEW_PERMISSIONS);
                // ...
                // 改为启动 ACTION_REVIEW_PERMISSIONS
                intent = newIntent;
                // ...
            }
        }
        
		// ...
        // 创建 目标ActivityRecord
        final ActivityRecord r = new ActivityRecord.Builder(mService)
                .setCaller(callerApp)
                .setLaunchedFromPid(callingPid)
                .setLaunchedFromUid(callingUid)
                .setLaunchedFromPackage(callingPackage)
                .setLaunchedFromFeature(callingFeatureId)
                .setIntent(intent)
                .setResolvedType(resolvedType)
                .setActivityInfo(aInfo)
                .setConfiguration(mService.getGlobalConfiguration())
                .setResultTo(resultRecord)
                .setResultWho(resultWho)
                .setRequestCode(requestCode)
                .setComponentSpecified(request.componentSpecified)
                .setRootVoiceInteraction(voiceSession != null)
                .setActivityOptions(checkedOptions)
                .setSourceRecord(sourceRecord)
                .build();

        mLastStartActivityRecord = r;
		// ...
        // 调用 startActivityUnchecked() 继续, doResume = true
        mLastStartActivityResult = startActivityUnchecked(r, sourceRecord, voiceSession,
                request.voiceInteractor, startFlags, true /* doResume */, checkedOptions,
                inTask, inTaskFragment, restrictedBgActivity, intentGrants);
        if (request.outActivity != null) {
            request.outActivity[0] = mLastStartActivityRecord;
        }
        return mLastStartActivityResult;
    }
```

#### startActivityUnchecked()

> [ActivityStarter.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java;l=1375;)

```java

	// doResume = true
	private int startActivityUnchecked(final ActivityRecord r, ActivityRecord sourceRecord,
            IVoiceInteractionSession voiceSession, IVoiceInteractor voiceInteractor,
            int startFlags, boolean doResume, ActivityOptions options, Task inTask,
            TaskFragment inTaskFragment, boolean restrictedBgActivity,
            NeededUriGrants intentGrants) {
		...
        try {
            mService.deferWindowLayout();
            try {
                // 调用 startActivityInner() 
                result = startActivityInner(r, sourceRecord, voiceSession, voiceInteractor,
                        startFlags, doResume, options, inTask, inTaskFragment, restrictedBgActivity,
                        intentGrants);
            } finally {
                Trace.traceEnd(Trace.TRACE_TAG_WINDOW_MANAGER);
                startedActivityRootTask = handleStartResult(r, options, result, newTransition,
                        remoteTransition);
            }
        } finally {
            mService.continueWindowLayout();
        }
        //
        postStartActivityProcessing(r, result, startedActivityRootTask);

        return result;
    }
```

#### startActivityInner()

> task相关内容可以通过 ``adb shell dumpsys activity -p com.xx.xx activities``来观察。
>
> * Task：就是ActivityTask。
> * TaskDisplayArea：用于存放 ActivityTask的区域。它的最顶部就是当前显示的应用ActivityTask。

获取/创建RootTask，并将 activityTask 放到的 RootTask的顶部，

* 调用`mTargetRootTask.startActivityLocked()` 将 activityTask 放到的 rootTask的顶部，这样后续就能通过 `topRunningActivity()`来获取目标ActivityRecord。这里面并不是启动Activity。
* 调用 `RootWindowContainer.resumeFocusedTasksTopActivities()` 恢复最顶部的 Activity，也就是启动 目标Activity。

> [ActivityStarter.java - startActivityInner()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/ActivityStarter.java;l=1542)

```java
	@VisibleForTesting
    int startActivityInner(final ActivityRecord r, ActivityRecord sourceRecord,
            IVoiceInteractionSession voiceSession, IVoiceInteractor voiceInteractor,
            int startFlags, boolean doResume, ActivityOptions options, Task inTask,
            TaskFragment inTaskFragment, boolean restrictedBgActivity,
            NeededUriGrants intentGrants) {
        // 初始化 starter 内部状态。
        // mDoResume = doResume = true。
        // inTaskFragment = null 时会创建一个。
        setInitialState(r, options, inTask, inTaskFragment, doResume, startFlags, sourceRecord,
                voiceSession, voiceInteractor, restrictedBgActivity);

        computeLaunchingTaskFlags();
        computeSourceRootTask();
		
        // 设置 启动标识
        mIntent.setFlags(mLaunchFlags);
        // 获取可复用的task, 处理 LAUNCH_SINGLE_INSTANCE, LAUNCH_SINGLE_TASK 等标识
        final Task reusedTask = getReusableTask();
        
		// ...
        // Compute if there is an existing task that should be used for.
        // 看看是否存在可用的task, 会优先复用task，没有返回null
        final Task targetTask = reusedTask != null ? reusedTask : computeTargetTask();
        // 标识 是否是新建task
        final boolean newTask = targetTask == null;
        mTargetTask = targetTask;
        
        computeLaunchParams(r, sourceRecord, targetTask);

        // Check if starting activity on given task or on a new task is allowed.
        // 检查activity 是否能启动，例如 不允许后台应用启动 activity。
        int startResult = isAllowedToStart(r, newTask, targetTask);
        // ...
		//
        final ActivityRecord targetTaskTop = newTask
                ? null : targetTask.getTopNonFinishingActivity();
        if (targetTaskTop != null) {
            // Recycle the target task for this launch.
            startResult = recycleTask(targetTask, targetTaskTop, reusedTask, intentGrants);
            if (startResult != START_SUCCESS) {
                return startResult;
            }
        } else {
            mAddingToTask = true;
        }
		// 获取 topRootTask，用于比对
        final Task topRootTask = mPreferredTaskDisplayArea.getFocusedRootTask();
        if (topRootTask != null) {
            // 判断被启动的activity 与当前在顶部的activity 是否相同
            // 若是同一个activity则判断是否需要新建，例如FLAG_ACTIVITY_SINGLE_TOP则不新建
            // 需要新建时则返回START_SUCCESS
            startResult = deliverToCurrentTopIfNeeded(topRootTask, intentGrants);
            if (startResult != START_SUCCESS) {
                return startResult;
            }
        }
        // 获取/创建 mTargetRootTask
        if (mTargetRootTask == null) {
            mTargetRootTask = getOrCreateRootTask(mStartActivity, mLaunchFlags, targetTask,
                    mOptions);
        }
        // 需要新建一个task
        if (newTask) {
            final Task taskToAffiliate = (mLaunchTaskBehind && mSourceRecord != null)
                    ? mSourceRecord.getTask() : null;
            // 内部通过mTargetRootTask新建了一个task
            setNewTask(taskToAffiliate);
        } else if (mAddingToTask) {
            addOrReparentStartingActivity(targetTask, "adding to task");
        }
		// ...
        //
        final Task startedTask = mStartActivity.getTask();
        // ...
        // 这里面并不是启动Activity，而是负责将 activityTask 放到的 rootTask的顶部。
        // 这样后续就能通过topRunningActivity 获取目标ActivityRecord
        mTargetRootTask.startActivityLocked(mStartActivity, topRootTask, newTask, isTaskSwitch,
                mOptions, sourceRecord);
        // mDoResume 是 true，在setInitialState() 时被修改
        if (mDoResume) {
            final ActivityRecord topTaskActivity = startedTask.topRunningActivityLocked();
            if (!mTargetRootTask.isTopActivityFocusable()
                    || (topTaskActivity != null && topTaskActivity.isTaskOverlay()
                    && mStartActivity != topTaskActivity)) {
                // 即使未获取焦点，也依然需要确保可见。例如PIP（画中画）
                mTargetRootTask.ensureActivitiesVisible(null /* starting */,
                        0 /* configChanges */, !PRESERVE_WINDOWS);
                mTargetRootTask.mDisplayContent.executeAppTransition();
            } else {
                if (mTargetRootTask.isTopActivityFocusable()
                        && !mRootWindowContainer.isTopDisplayFocusedRootTask(mTargetRootTask)) {
                    mTargetRootTask.moveToFront("startActivityInner");
                }
                // 主要流程
                mRootWindowContainer.resumeFocusedTasksTopActivities(
                        mTargetRootTask, mStartActivity, mOptions, mTransientLaunch);
            }
        }
        // ...
        return START_SUCCESS;
    }
```



### RootWindowContainer.resumeFocusedTasksTopActivities()

恢复 top activity 。

> [RootWindowContainer.java - resumeFocusedTasksTopActivities()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/RootWindowContainer.java;l=2248)

```java
	boolean resumeFocusedTasksTopActivities(
            Task targetRootTask, ActivityRecord target, ActivityOptions targetOptions,
            boolean deferPause) {
        if (!mTaskSupervisor.readyToResume()) {
            return false;
        }

        boolean result = false;
        if (targetRootTask != null && (targetRootTask.isTopRootTaskInDisplayArea()
                || getTopDisplayFocusedRootTask() == targetRootTask)) {
            result = targetRootTask.resumeTopActivityUncheckedLocked(target, targetOptions,
                    deferPause);
        }

        // ...
        return result;
    }
```

### Task

```java
class Task extends TaskFragment {}
```

#### resumeTopActivityUncheckedLocked()

确保 top activity 被恢复。

> [Task.java - resumeTopActivityUncheckedLocked()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/Task.java;l=4965)

```java
	boolean resumeTopActivityUncheckedLocked(ActivityRecord prev, ActivityOptions options,
            boolean deferPause) {
        if (mInResumeTopActivity) {
            // Don't even start recursing.
            // 防止自身递归的
            return false;
        }
        boolean someActivityResumed = false;
        try {
            // Protect against recursion.
            mInResumeTopActivity = true;
            if (isLeafTask()) {
                if (isFocusableAndVisible()) {
                    // 这里继续
                    someActivityResumed = resumeTopActivityInnerLocked(prev, options, deferPause);
                }
            } else {
                // 这里是遍历child，找出 isTopActivityFocusable && getVisibility 的task，然后递归调用
                // ... 
            }
			// 
            final ActivityRecord next = topRunningActivity(true /* focusableOnly */);
            if (next == null || !next.canTurnScreenOn()) {
                checkReadyForSleep();
            }
        } finally {
            mInResumeTopActivity = false;
        }
        return someActivityResumed;
    }
```

#### resumeTopActivityInnerLocked()

> [Task.java - resumeTopActivityInnerLocked](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/Task.java;l=5034)

```java
	@GuardedBy("mService")
    private boolean resumeTopActivityInnerLocked(ActivityRecord prev, ActivityOptions options,
            boolean deferPause) {
        if (!mAtmService.isBooting() && !mAtmService.isBooted()) {
            // Not ready yet!
            return false;
        }

        final ActivityRecord topActivity = topRunningActivity(true /* focusableOnly */);
        if (topActivity == null) {
            // There are no activities left in this task, let's look somewhere else.
            return resumeNextFocusableActivityWhenRootTaskIsEmpty(prev, options);
        }

        final boolean[] resumed = new boolean[1];
        final TaskFragment topFragment = topActivity.getTaskFragment();
        // 调用 topFragment.resumeTopActivity
        resumed[0] = topFragment.resumeTopActivity(prev, options, deferPause);
        forAllLeafTaskFragments(f -> {
            if (topFragment == f) {
                return;
            }
            if (!f.canBeResumed(null /* starting */)) {
                return;
            }
            resumed[0] |= f.resumeTopActivity(prev, options, deferPause);
        }, true);
        return resumed[0];
    }
```

### TaskFragment.resumeTopActivity()

在这里 判断了 **Activity是否已经和 app进程关联**，即是否已经在应用进程中存在了：

* Activity已关联进程：则将activity 设为可见，并且同时生命周期变更为 RESUMED 等。然后ATMS 通过 IApplicationThread这个IBinder 回调给给 目标Activity 所在的进程。
  * 最终调用的是 `ActivityThread.scheduleTransaction()`，发送 `EXECUTE_TRANSACTION` 消息。从而根据不同生命周期做不同的处理。就是（handleLaunchActivity、handleResumeActivity等函数）

* Activity未关联进程：调用  `mTaskSupervisor.startSpecificActivity()` 继续启动流程。

> [TaskFragment.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/TaskFragment.java?l=1172)

```java
	final boolean resumeTopActivity(ActivityRecord prev, ActivityOptions options,
            boolean deferPause) {
        // 取出顶部的 ActivityRecord
        ActivityRecord next = topRunningActivity(true /* focusableOnly */);

       	// ...
        // 判断是否已经和app进程关联
        if (next.attachedToProcess()) {
           	// 此处目标Activity进程已启动后的流程。
            // 将activity 设为可见, 更新为 RESUMED 状态等。
            next.setState(RESUMED, "resumeTopActivity");
			// ...
            //  next.app.getThread(), 目标Activity所在进程的
            final ClientTransaction transaction =
                        ClientTransaction.obtain(next.app.getThread(), next.token);
            // ...
            // ATMS 通过IApplicationThread这个IBinder 回调给目标Activity所在进程
            // 最终就是回触发 ActivityThread.scheduleTransaction
            mAtmService.getLifecycleManager().scheduleTransaction(transaction);
        } else {
            // Whoops, need to restart this activity!
            if (!next.hasBeenLaunched) {
                next.hasBeenLaunched = true;
            } else {
                if (SHOW_APP_STARTING_PREVIEW) {
                    next.showStartingWindow(false /* taskSwich */);
                }
                if (DEBUG_SWITCH) Slog.v(TAG_SWITCH, "Restarting: " + next);
            }
            ProtoLog.d(WM_DEBUG_STATES, "resumeTopActivity: Restarting %s", next);
            // 调用 startSpecificActivity() 继续
            // mTaskSupervisor 是在 ATMS中创建的。
            mTaskSupervisor.startSpecificActivity(next, true, true);
        }

        return true;
    }
```

## 3. 准备创建应用进程

### ActivityTaskSupervisor.startSpecificActivity()

> ActivityTaskSupervisor 是负责 管理 Task的 

这里判断了  activity所属的应用进程是否已启动。

* 若应用进程已死或未启动过：调用`mService.startProcessAsync()` 来**启动进程**。mService 是 ATMS。
  * 不过一开始应用一定是未启动的，先看这个流程。

* 应用进程已启动：调用 `realStartActivityLocked()` **创建并启动Activity** 并结束流程。
  * 最终通过 IApplicationThread这个IBinder回调给 Activity所在进程，触发`ActivityThread.scheduleTransaction()`，发送 `EXECUTE_TRANSACTION` 消息。


> [ActivityTaskSupervisor.java - startSpecificActivity()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/ActivityTaskSupervisor.java;l=1036)

```java
	void startSpecificActivity(ActivityRecord r, boolean andResume, boolean checkConfig) {
        // Is this activity's application already running?
        // 用来判断 activity所属的应用是否已启动
        // 通过进程名查询 wpc，进程名默认时 packageName。
        // 这个类允许AM 中的ProcessRecord对象将其状态的重要变化传达给WM。
        final WindowProcessController wpc =
                mService.getProcessController(r.processName, r.info.applicationInfo.uid);

        boolean knownToBeDead = false;
        if (wpc != null && wpc.hasThread()) {
            // 这里是app已启动流程
            try {
                // 正在启动Activity的地方，启动后结束流程。
                realStartActivityLocked(r, wpc, andResume, checkConfig);
                return;
            } catch (RemoteException e) {
                Slog.w(TAG, "Exception when starting activity "
                        + r.intent.getComponent().flattenToShortString(), e);
            }
            // If a dead object exception was thrown -- fall through to
            // restart the application.
            // 进程已死，删除对应的process record，并重启
            knownToBeDead = true;
            // Remove the process record so it won't be considered as alive.
            mService.mProcessNames.remove(wpc.mName, wpc.mUid);
            mService.mProcessMap.remove(wpc.getPid());
        }
		
        r.notifyUnknownVisibilityLaunchedForKeyguardTransition();

        final boolean isTop = andResume && r.isTopRunningActivity();
        // 启动对应进程。主要看这个流程
        // HostingRecord.HOSTING_TYPE_TOP_ACTIVITY 后面有用
        mService.startProcessAsync(r, knownToBeDead, isTop,
                isTop ? HostingRecord.HOSTING_TYPE_TOP_ACTIVITY
                        : HostingRecord.HOSTING_TYPE_ACTIVITY);
    }

```



### ActivityTaskManagerService.startProcessAsync()

通过 `PooledLambda` 构建了一个 Message 消息， `ActivityManagerInternal::startProcess()` 作为 callback，具体实例是 `mAmInternal`，然后通过Handler发送并执行消息。最终回调`mAmInternal.startProcess()`

> [ActivityTaskManagerService.java - startProcessAsync()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/ActivityTaskManagerService.java;l=4876)

```java
	void startProcessAsync(ActivityRecord activity, boolean knownToBeDead, boolean isTop,
            String hostingType) {
        try {
            // callback:ActivityManagerInternal::startProcess
            // mAmInternal 是 callback的具体实例。是在AMS启动时 注册到 LocalServices中的。
            // PooledLambda返回的 message内部设置了 callback。最终会调用 mAmInternal.startProcess()
            final Message m = PooledLambda.obtainMessage(ActivityManagerInternal::startProcess,
                    mAmInternal, activity.processName, activity.info.applicationInfo, knownToBeDead,
                    isTop, hostingType, activity.intent.getComponent());
            // 发送消息，
            mH.sendMessage(m);
        } finally {
            Trace.traceEnd(TRACE_TAG_WINDOW_MANAGER);
        }
    }
```

### PooledLambda

它的实现类是 PooledLambdaImpl，把它们放一起了。它的作用是构建一个Message 并将传入的 function 及 参数 通过`setCallback()`的方式执行。

> [PooledLambdaImpl.java - doInvoke()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/util/function/pooled/PooledLambdaImpl.java;l=237)

```java
public interface PooledLambda {
    // 有很多参数不同的同名函数，随便找了个。
    // 它的作用是相同的，都是用于 创建Message。
    // 参数 function 是对应执行的函数。后面的是它的入参和返回值类型。
    static <A, B, C, D, E, F, G, H, I, J, K, L> Message obtainMessage(
            DodecConsumer<? super A, ? super B, ? super C, ? super D, ? super E, ? super F,
                    ? super G, ? super H, ? super I, ? super J, ? super K, ? super L> function,
            A arg1, B arg2, C arg3, D arg4, E arg5, F arg6, G arg7, H arg8, I arg9, J arg10,
            K arg11, L arg12) {
        synchronized (Message.sPoolSync) {
            // callback 的方式执行 function
            PooledRunnable callback = acquire(PooledLambdaImpl.sMessageCallbacksPool,
                    function, 11, 0, ReturnType.VOID, arg1, arg2, arg3, arg4, arg5, arg6, arg7,
                    arg8, arg9, arg10, arg11, arg12);
            // setCallback，实际就是调用 PooledRunnable。
            return Message.obtain().setCallback(callback.recycleOnUse());
        }
    }
}


//  PooledLambdaImpl 也实现了 PooledRunnable
final class PooledLambdaImpl<R> extends OmniFunction<Object, Object, Object, Object, Object, Object, Object, 				Object, Object, Object, Object, R> {
	//
    Object mFunc;
    @Nullable Object[] mArgs = null;
   	static final Pool sMessageCallbacksPool = new Pool(Message.sPoolSync);
            
    static PooledLambdaImpl acquire(Pool pool) {
        PooledLambdaImpl r = pool.acquire();
        if (r == null) r = new PooledLambdaImpl();
        r.mFlags &= ~FLAG_RECYCLED;
        r.setFlags(FLAG_ACQUIRED_FROM_MESSAGE_CALLBACKS_POOL,
                pool == sMessageCallbacksPool ? 1 : 0);
        return r;
    }
    
    // recycleOnUse() 返回自身
    @Override
    public OmniFunction<Object, Object, Object, Object, Object, Object, Object, Object, Object,
            Object, Object, R> recycleOnUse() {
        if (DEBUG) Log.i(LOG_TAG, this + ".recycleOnUse()");
        mFlags |= FLAG_RECYCLE_ON_USE;
        return this;
    }
     
	static <E extends PooledLambda> E acquire(Pool pool, Object func,
            int fNumArgs, int numPlaceholders, int fReturnType, Object a, Object b, Object c,
            Object d, Object e, Object f, Object g, Object h, Object i, Object j, Object k,
            Object l) {
        PooledLambdaImpl r = acquire(pool);
   		//
        r.mFunc = Objects.requireNonNull(func);
        r.setFlags(MASK_FUNC_TYPE, LambdaType.encode(fNumArgs, fReturnType));
        r.setFlags(MASK_EXPOSED_AS, LambdaType.encode(numPlaceholders, fReturnType));
        if (ArrayUtils.size(r.mArgs) < fNumArgs) r.mArgs = new Object[fNumArgs];
        setIfInBounds(r.mArgs, 0, a);
        setIfInBounds(r.mArgs, 1, b);
        setIfInBounds(r.mArgs, 2, c);
        setIfInBounds(r.mArgs, 3, d);
        setIfInBounds(r.mArgs, 4, e);
        setIfInBounds(r.mArgs, 5, f);
        setIfInBounds(r.mArgs, 6, g);
        setIfInBounds(r.mArgs, 7, h);
        setIfInBounds(r.mArgs, 8, i);
        setIfInBounds(r.mArgs, 9, j);
        setIfInBounds(r.mArgs, 10, k);
        setIfInBounds(r.mArgs, 11, l);
        return (E) r;
    }
    
    private static void setIfInBounds(Object[] array, int i, Object a) {
        if (i < ArrayUtils.size(array)) array[i] = a;
    }
    
    @Override
    public void run() {
        invoke(null, null, null, null, null, null, null, null, null, null, null);
    }
    
    @Override
    R invoke(Object a1, Object a2, Object a3, Object a4, Object a5, Object a6, Object a7,
            Object a8, Object a9, Object a10, Object a11) {
        // ...
        try {
            // 内部执行 mFunc
            return doInvoke();
        } finally {
           // ... 
        }
    }
}
```

### ActivityManagerInternal.startProcess()

位于 `ActivityManagerService.LocalService`中

> [ActivityManagerService.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/am/ActivityManagerService.java;l=17311)

```java
public class ActivityManagerService extends IActivityManager.Stub
        implements Watchdog.Monitor, BatteryStatsImpl.BatteryCallback, ActivityManagerGlobalLock {
    //
	public final ActivityManagerInternal mInternal;
    
    public ActivityManagerService(Injector injector, ServiceThread handlerThread) {
        // ...
        // 构造函数中创建 ActivityManagerInternal 实例, 也是ATMS中的mAmInternal
        mInternal = new LocalService();
     	// ...   
    }
    
    private void start() {
        mBatteryStatsService.publish();
        mAppOpsService.publish();
        mProcessStats.publish();
        Slog.d("AppOps", "AppOpsService published");
        // 将 ActivityManagerInternal 注册到 LocalServices 中，供其他地方获取使用。例如ATMS
        LocalServices.addService(ActivityManagerInternal.class, mInternal);
        LocalManagerRegistry.addManager(ActivityManagerLocal.class,
                                        (ActivityManagerLocal) mInternal);
        mActivityTaskManager.onActivityManagerInternalAdded();
        mPendingIntentController.onActivityManagerInternalAdded();
        mAppProfiler.onActivityManagerInternalAdded();
        CriticalEventLog.init();
    }
    
    @GuardedBy("this")
    final ProcessRecord startProcessLocked(String processName,
            ApplicationInfo info, boolean knownToBeDead, int intentFlags,
            HostingRecord hostingRecord, int zygotePolicyFlags, boolean allowWhileBooting,
            boolean isolated) {
        // 调用 ProcessList.startProcessLocked()
        return mProcessList.startProcessLocked(processName, info, knownToBeDead, intentFlags,
                hostingRecord, zygotePolicyFlags, allowWhileBooting, isolated, 0 /* isolatedUid */,
                false /* isSdkSandbox */, 0 /* sdkSandboxClientAppUid */,
                null /* sdkSandboxClientAppPackage */,
                null /* ABI override */, null /* entryPoint */,
                null /* entryPointArgs */, null /* crashHandler */);
    }
    
    // ActivityManagerInternal 的实现类
    public final class LocalService extends ActivityManagerInternal implements ActivityManagerLocal {

         @Override
         public void startProcess(String processName, ApplicationInfo info, boolean knownToBeDead,
                                  boolean isTop, String hostingType, ComponentName hostingName) {
             try {
                 if (Trace.isTagEnabled(Trace.TRACE_TAG_ACTIVITY_MANAGER)) {
                     Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "startProcess:"
                                      + processName);
                 }
                 synchronized (ActivityManagerService.this) {
                     // 创建了 HostingRecord
                     // 调用AMS的 startProcessLocked()
                     startProcessLocked(processName, info, knownToBeDead, 0 /* intentFlags */,
                                        new HostingRecord(hostingType, hostingName, isTop),
                                        ZYGOTE_POLICY_FLAG_LATENCY_SENSITIVE, false /* allowWhileBooting */,
                                        false /* isolated */);
                 }
             } finally {
                 Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);
             }
         }
     }
}
```

### ProcessList

这里主要是处理进程信息的代码，它内部维护了一个进程映射表，结构是：`[processName][uid][ProcessRecord]`。

#### startProcessLocked()

* 创建一份ProcessRecord。首先会从进程映射表中查询对应进程记录，满足复用条件则直接使用，否则会创建一个新的ProcessRecord。并添加到映射表中。

* 设置应用入口：`android.app.ActivityThread`

* 调用`handleProcessStart()` 异步启动进程。

> [ProcessList.java - startProcessLocked()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/am/ProcessList.java;l=2376)

```java
class ProcessList {
    // 这里维护了一个进程映射表。

    // 第一个 startProcessLocked
    // 这里主要是创建 ProcessRecord
 	@GuardedBy("mService")
    ProcessRecord startProcessLocked(String processName, ApplicationInfo info,
            boolean knownToBeDead, int intentFlags, HostingRecord hostingRecord,
            int zygotePolicyFlags, boolean allowWhileBooting, boolean isolated, int isolatedUid,
            boolean isSdkSandbox, int sdkSandboxUid, String sdkSandboxClientAppPackage,
            String abiOverride, String entryPoint, String[] entryPointArgs, Runnable crashHandler) {
        long startTime = SystemClock.uptimeMillis();
        ProcessRecord app;
        // isolated = false
        if (!isolated) {
            // 从映射表中查询进程
            app = getProcessRecordLocked(processName, info.uid);
          	// ...
        } else {
            // If this is an isolated process, it can't re-use an existing process.
            // 独立进程则不复用。
            app = null;
        }

		//
        ProcessRecord predecessor = null;
        // 复用条件：进程正在启动或已启动。
        // 1. 存在进程记录，并且已分配 pid
        // 2. 知道进程不会死 && 进程未被kill
        // 3. 进程不包含任何线程，所以不会崩溃
        if (app != null && app.getPid() > 0) { // 
            if ((!knownToBeDead && !app.isKilled()) || app.getThread() == null) {
                // 可以直接复用进程：
                // 将这个运行的package添加到进程信息中，里面维护了进程中运行的package列表。
                app.addPackage(info.packageName, info.longVersionCode, mService.mProcessStats);
                return app;
            }
			// 不满足复用条件，杀死进程组。
            ProcessList.killProcessGroup(app.uid, app.getPid());
            // 将它设置 新进程的 前身。
            predecessor = app;
            app = null;
        } else if (!isolated) {
            // 没找到，再尝试从垂死进程中查找一下(一个进程被杀死但还没有完全死亡时会存在)。
            // 作为predecessor 
            predecessor = mDyingProcesses.get(processName, info.uid);
            if (predecessor != null) {
                if (app != null) {
                    app.mPredecessor = predecessor;
                    predecessor.mSuccessor = app;
                }
            }
        }
		
        if (app == null) {
            // 没有可用的进程，创建一个新ProcessRecord，并添加到 mProcessNames 中。
            app = newProcessRecordLocked(info, processName, isolated, isolatedUid, isSdkSandbox,
                    sdkSandboxUid, sdkSandboxClientAppPackage, hostingRecord);
            if (app == null) {
                Slog.w(TAG, "Failed making new process record for "
                        + processName + "/" + info.uid + " isolated=" + isolated);
                return null;
            }
            // 都是null
            app.mErrorState.setCrashHandler(crashHandler);
            app.setIsolatedEntryPoint(entryPoint);
            app.setIsolatedEntryPointArgs(entryPointArgs);
            // 设置前身
            if (predecessor != null) {
                app.mPredecessor = predecessor;
                predecessor.mSuccessor = app;
            }
            checkSlow(startTime, "startProcess: done creating new process record");
        } else {
            // If this is a new package in the process, add the package to the list
            // 将package添加到进程信息中
            app.addPackage(info.packageName, info.longVersionCode, mService.mProcessStats);
            checkSlow(startTime, "startProcess: added package to existing proc");
        }

        checkSlow(startTime, "startProcess: stepping in to startProcess");
        final boolean success =
                startProcessLocked(app, hostingRecord, zygotePolicyFlags, abiOverride);
        checkSlow(startTime, "startProcess: done starting proc!");
        return success ? app : null;
    }
    
    // 第二个 startProcessLocked
    // 这里主要是处理一些参数
    @GuardedBy("mService")
    boolean startProcessLocked(ProcessRecord app, HostingRecord hostingRecord,
            int zygotePolicyFlags, boolean disableHiddenApiChecks, boolean disableTestApiChecks,
            String abiOverride) {
    
        // ...
        String requiredAbi = (abiOverride != null) ? abiOverride : app.info.primaryCpuAbi;
        if (requiredAbi == null) {
            requiredAbi = Build.SUPPORTED_ABIS[0];
        }
        // ...
  		try {
            // Start the process.  It will either succeed and return a result containing
            // the PID of the new process, or else throw a RuntimeException.
            
            // 设置应用的入口： ActivityThread 
            final String entryPoint = "android.app.ActivityThread";
            // invokeWith 只有在 应用设置了 debuggableFlag才有值: ApplicationInfo.FLAG_DEBUGGABLE
            return startProcessLocked(hostingRecord, entryPoint, app, uid, gids,
                    runtimeFlags, zygotePolicyFlags, mountExternal, seInfo, requiredAbi,
                    instructionSet, invokeWith, startUptime, startElapsedTime);
        } catch (RuntimeException e) {
            mService.forceStopPackageLocked(app.info.packageName, UserHandle.getAppId(app.uid),
                    false, false, true, false, false, app.userId, "start failure");
            return false;
        }
    }

    // 第三个 startProcessLocked
    // 这里开始启动进程，异步/同步最终都是调用了startProcess()
    @GuardedBy("mService")
    boolean startProcessLocked(HostingRecord hostingRecord, String entryPoint, ProcessRecord app,
            int uid, int[] gids, int runtimeFlags, int zygotePolicyFlags, int mountExternal,
            String seInfo, String requiredAbi, String instructionSet, String invokeWith,
            long startUptime, long startElapsedTime) {
       	// ...
        // FLAG_PROCESS_START_ASYNC 默认是true
        if (mService.mConstants.FLAG_PROCESS_START_ASYNC) {
            // 异步启动进程
            mService.mProcStartHandler.post(() -> handleProcessStart(
                    app, entryPoint, gids, runtimeFlags, zygotePolicyFlags, mountExternal,
                    requiredAbi, instructionSet, invokeWith, startSeq));
            return true;
        } else {
            try {
                // 同步启动进程
                final Process.ProcessStartResult startResult = startProcess(hostingRecord,
                        entryPoint, app,
                        uid, gids, runtimeFlags, zygotePolicyFlags, mountExternal, seInfo,
                        requiredAbi, instructionSet, invokeWith, startUptime);
                handleProcessStartedLocked(app, startResult.pid, startResult.usingWrapper,
                        startSeq, false);
            } catch (RuntimeException e) {
                Slog.e(ActivityManagerService.TAG, "Failure starting process "
                        + app.processName, e);
                app.setPendingStart(false);
                mService.forceStopPackageLocked(app.info.packageName, UserHandle.getAppId(app.uid),
                        false, false, true, false, false, app.userId, "start failure");
            }
            return app.getPid() > 0;
        }
    }

}

```



#### handleProcessStart()

调用 `startProcess()` 启动进程并获取结果。

> [ProcessList.java - handleProcessStart()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/am/ProcessList.java;l=1968)

```JAVA
	private void handleProcessStart(final ProcessRecord app, final String entryPoint,
            final int[] gids, final int runtimeFlags, int zygotePolicyFlags,
            final int mountExternal, final String requiredAbi, final String instructionSet,
            final String invokeWith, final long startSeq) {
        final Runnable startRunnable = () -> {
            try {
                // 启动进程
                final Process.ProcessStartResult startResult = startProcess(app.getHostingRecord(),
                        entryPoint, app, app.getStartUid(), gids, runtimeFlags, zygotePolicyFlags,
                        mountExternal, app.getSeInfo(), requiredAbi, instructionSet, invokeWith,
                        app.getStartTime());
				// 处理启动结果，会将 pid 存入到 app进程信息中。
                synchronized (mService) {
                    handleProcessStartedLocked(app, startResult, startSeq);
                }
            } catch (RuntimeException e) {
                synchronized (mService) {
                    Slog.e(ActivityManagerService.TAG, "Failure starting process "
                            + app.processName, e);
                    mPendingStarts.remove(startSeq);
                    app.setPendingStart(false);
                    mService.forceStopPackageLocked(app.info.packageName,
                            UserHandle.getAppId(app.uid),
                            false, false, true, false, false, app.userId, "start failure");
                }
            }
        };
        // Use local reference since we are not using locks here
        final ProcessRecord predecessor = app.mPredecessor;
        if (predecessor != null && predecessor.getDyingPid() > 0) { // 存在前身
            handleProcessStartWithPredecessor(predecessor, startRunnable);
        } else {
            // Kick off the process start for real.
            // 不存在前身，从这里启动
            startRunnable.run();
        }
    }
```

#### startProcess()

调用 `Process.start()` 来启动进程

> [ProcessList.java - startProcess()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/am/ProcessList.java;l=2192)

```java
	private Process.ProcessStartResult startProcess(HostingRecord hostingRecord, String entryPoint,
            ProcessRecord app, int uid, int[] gids, int runtimeFlags, int zygotePolicyFlags,
            int mountExternal, String seInfo, String requiredAbi, String instructionSet,
            String invokeWith, long startTime) {
        try {
            Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "Start proc: " +
                    app.processName);
            // ...
            final Process.ProcessStartResult startResult;
            boolean regularZygote = false;
            if (hostingRecord.usesWebviewZygote()) {
               // ...
            } else if (hostingRecord.usesAppZygote()) {
               // ...
            } else {
                // 启动进程
                regularZygote = true;
                startResult = Process.start(entryPoint,
                        app.processName, uid, uid, gids, runtimeFlags, mountExternal,
                        app.info.targetSdkVersion, seInfo, requiredAbi, instructionSet,
                        app.info.dataDir, invokeWith, app.info.packageName, zygotePolicyFlags,
                        isTopApp, app.getDisabledCompatChanges(), pkgDataInfoMap,
                        allowlistedAppDataInfoMap, bindMountAppsData, bindMountAppStorageDirs,
                        new String[]{PROC_START_SEQ_IDENT + app.getStartSeq()});
            }
			// ...
            checkSlow(startTime, "startProcess: returned from zygote!");
            return startResult;
        } finally {
            Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);
        }
    }
```



### Process.start()	

从这里开始主要就是创建进程的流程。

> [Process.java - start()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/os/Process.java;l=713)

```java
class Process {
    public static final ZygoteProcess ZYGOTE_PROCESS = new ZygoteProcess();
	
    // processClass = android.app.ActivityThread
	public static ProcessStartResult start(@NonNull final String processClass,...) {
        // 启动参数
        return ZYGOTE_PROCESS.start(processClass, niceName, uid, gid, gids,
                    runtimeFlags, mountExternal, targetSdkVersion, seInfo,
                    abi, instructionSet, appDataDir, invokeWith, packageName,
                    zygotePolicyFlags, isTopApp, disabledCompatChanges,
                    pkgDataInfoMap, whitelistedDataInfoMap, bindMountAppsData,
                    bindMountAppStorageDirs, zygoteArgs);
    }
}
```

### ZygoteProcess

* 填充应用启动参数。
* 首先和 zygote进程建立 socket连接。
* 向zygote 发起socket请求，请求创建应用进程。
* 获取创建结果，读取进程pid，若pid > 0 表示创建成功。

#### start()

> [ZygoteProcess.java - start()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/os/ZygoteProcess.java;drc=45d16720f61c1ae1815e47d8c4712a1403f7c66a;l=338)

```java
 public final Process.ProcessStartResult start(@NonNull final String processClass,...) {
		// ...
        try {
            // 
            return startViaZygote(processClass, niceName, uid, gid, gids,
                    runtimeFlags, mountExternal, targetSdkVersion, seInfo,
                    abi, instructionSet, appDataDir, invokeWith, /*startChildZygote=*/ false,
                    packageName, zygotePolicyFlags, isTopApp, disabledCompatChanges,
                    pkgDataInfoMap, allowlistedDataInfoList, bindMountAppsData,
                    bindMountAppStorageDirs, zygoteArgs);
        } catch (ZygoteStartFailedEx ex) {
            Log.e(LOG_TAG, "Starting VM process through Zygote failed");
            throw new RuntimeException( "Starting VM process through Zygote failed", ex);
        }
    }
```

#### startViaZygote()

这里主要就是创建并填充了指令参数 `argsForZygote`，然后调用 `zygoteSendArgsAndGetResult()` 获取进程启动结果。

和 zygote fork system_server时硬编码的启动参数格式类似。

> [ZygoteProcess.java - startViaZygote()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/os/ZygoteProcess.java;drc=45d16720f61c1ae1815e47d8c4712a1403f7c66a;l=619)

```java
private Process.ProcessStartResult startViaZygote(@NonNull final String processClass,...)
                                                      throws ZygoteStartFailedEx {
        ArrayList<String> argsForZygote = new ArrayList<>();
		// 填充指令参数 argsForZygote。
        // --runtime-args, --setuid=, --setgid=,
        // and --setgroups= must go first
        argsForZygote.add("--runtime-args");
        argsForZygote.add("--setuid=" + uid);
        argsForZygote.add("--setgid=" + gid);
        argsForZygote.add("--runtime-flags=" + runtimeFlags);
		// ....
    	// 最后添加启动目标： android.app.ActivityThread
        argsForZygote.add(processClass);
        if (extraArgs != null) {
            Collections.addAll(argsForZygote, extraArgs);
        }

        synchronized(mLock) {
            // The USAP pool can not be used if the application will not use the systems graphics
            // driver.  If that driver is requested use the Zygote application start path.
            // 打开zygoteSocket用于和zygote通讯
            return zygoteSendArgsAndGetResult(openZygoteSocketIfNeeded(abi),
                                              zygotePolicyFlags,
                                              argsForZygote);
        }
    }

```

##### openZygoteSocketIfNeeded()：建立socket连接

**在这里于zygote 建立 socket 连接**。

```java
 	// 
	@GuardedBy("mLock")
    private ZygoteState openZygoteSocketIfNeeded(String abi) throws ZygoteStartFailedEx {
        try {
            // 建立socket连接，并将socket通讯状态保持在primaryZygoteState中
            attemptConnectionToPrimaryZygote();

            if (primaryZygoteState.matches(abi)) {
                // 匹配则返回，一般这里是 64位
                return primaryZygoteState;
            }
			// 一般这里是 32位。
            if (mZygoteSecondarySocketAddress != null) {
                // The primary zygote didn't match. Try the secondary.
                attemptConnectionToSecondaryZygote();
                if (secondaryZygoteState.matches(abi)) {
                    return secondaryZygoteState;
                }
            }
        } catch (IOException ioe) {
            throw new ZygoteStartFailedEx("Error connecting to zygote", ioe);
        }
        throw new ZygoteStartFailedEx("Unsupported zygote ABI: " + abi);
    }
	

	//   mZygoteSocketAddress =  new LocalSocketAddress(Zygote.PRIMARY_SOCKET_NAME,  LocalSocketAddress.Namespace.RESERVED);
    //    mUsapPoolSocketAddress = new LocalSocketAddress(Zygote.USAP_POOL_PRIMARY_SOCKET_NAME, LocalSocketAddress.Namespace.RESERVED);
	// 
 	@GuardedBy("mLock")
    private void attemptConnectionToPrimaryZygote() throws IOException {
        if (primaryZygoteState == null || primaryZygoteState.isClosed()) {
            // 建立 socket连接，连接到 mZygoteSocketAddress 中
            // 并将socket通讯状态保持在primaryZygoteState中
            primaryZygoteState =
                    ZygoteState.connect(mZygoteSocketAddress, mUsapPoolSocketAddress);

            maybeSetApiDenylistExemptions(primaryZygoteState, false);
            maybeSetHiddenApiAccessLogSampleRate(primaryZygoteState);
        }
    }
```



#### zygoteSendArgsAndGetResult()

> [ZygoteProcess.java - zygoteSendArgsAndGetResult()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/os/ZygoteProcess.java;drc=45d16720f61c1ae1815e47d8c4712a1403f7c66a;l=415)

```java
	private Process.ProcessStartResult zygoteSendArgsAndGetResult(
            ZygoteState zygoteState, int zygotePolicyFlags, @NonNull ArrayList<String> args)
            throws ZygoteStartFailedEx {
        // 提前校验参数
        // ...
        String msgStr = args.size() + "\n" + String.join("\n", args) + "\n";
        // 尝试使用usap启动，默认false，实际上是什么还得看看系统到底是否开启。忽略
		// ...
        return attemptZygoteSendArgsAndGetResult(zygoteState, msgStr);
    }
```

#### attemptZygoteSendArgsAndGetResult()：发起请求

**在这里 通过socket 和zygote进行通信。**

* 将指令信息写入socket 中，请求启动应用。阻塞读取结果。

* zygote接收到后会创建进程，创建成功后将新进程的 pid 写入socket。
* 接着我们就能读取到结果，若获取到的pid > 0 表示进程启动成功。

> [ZygoteProcess.java - attemptZygoteSendArgsAndGetResult()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/os/ZygoteProcess.java;drc=45d16720f61c1ae1815e47d8c4712a1403f7c66a;l=456)

```java
 	private Process.ProcessStartResult attemptZygoteSendArgsAndGetResult(
            ZygoteState zygoteState, String msgStr) throws ZygoteStartFailedEx {
        try {
            final BufferedWriter zygoteWriter = zygoteState.mZygoteOutputWriter;
            final DataInputStream zygoteInputStream = zygoteState.mZygoteInputStream;
			// 将指令信息写入socket
            zygoteWriter.write(msgStr);
            zygoteWriter.flush();

            // Always read the entire result from the input stream to avoid leaving
            // bytes in the stream for future process starts to accidentally stumble
            // upon.
            Process.ProcessStartResult result = new Process.ProcessStartResult();
            // 阻塞等待结果。zygote创建了子进程后，在父进程中会通过socket 返回给我们
            // 获取 子进程的pid
            result.pid = zygoteInputStream.readInt();
            result.usingWrapper = zygoteInputStream.readBoolean();

            if (result.pid < 0) {
                throw new ZygoteStartFailedEx("fork() failed");
            }

            return result;
        } catch (IOException ex) {
            zygoteState.close();
            Log.e(LOG_TAG, "IO Exception while communicating with Zygote - "
                    + ex.toString());
            throw new ZygoteStartFailedEx(ex);
        }
    }

```

---

## 4. zygote孵化应用进程

在上面梳理了 发起一个应用启动请求的完整流程，从调用 `startActivity()`开始 到最后通过 socket 向 zygote发送请求。

我们知道zygote启动后会注册了一个 socket，接着进入 select loop循环，内部通过poll机制等待 socket请求，当消息来时会被唤醒，并做相应的处理。关于这一块在[Android系统启动流程](./Android系统启动流程.md) 一文中有详细介绍。其中就包括了 AMS的应用启动请求，zygote收到请求后会创建应用进程。

接着就来看看应用进程孵化的流程。

* ATMS 向zygote 发起socket连接请求，之后两者建立连接。
* ATMS 向zygote发送应用启动指令，zygote接收并解析指令。SystemServer 是硬编码的指令参数，而应用启动则是从socket中获取指令参数。
* zygote 孵化应用进程。
  * 父进程：将子进程 Pid写入socket，会被ATMS读取。
  * 子进程：将参数传给`ZygoteInit.zygoteInit()` 函数来初始化应用程序、创建Binder线程池，并返回 `ActivityThread.main()`函数。
* 在子进程中启动对应程序。

![zygote孵化应用进程](./Android%E5%BA%94%E7%94%A8%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/zygote%E5%AD%B5%E5%8C%96%E5%BA%94%E7%94%A8%E8%BF%9B%E7%A8%8B-1678982454165-8.jpg)

### ZygoteServer.runSelectLoop()

这个函数开启了 select loop 来监听 socket请求，并做相应的处理。例如 AMS的应用启动请求。

* 开启一个无限循环，循环内使用 poll 机制监听所有fd。
* 当有事件触发时会遍历所有的socketfd，并执行相应的逻辑。其中主要包含2个socketfd。
  * mZygoteSocke：负责接收新连接。通过它来创建 ZygoteConnection。
  * ZygoteConnection：连接建立后，就将由`connection.processCommand()`函数来处理 sokcet 请求，并返回一个Command。
* 将command返回交由 ZygoteInit.main()执行。

> [ZygoteServer.java - runSelectLoop()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/ZygoteServer.java;drc=a88d63279834b0e5d67683b0949c594fd7dc376b;l=394)

```java
    // 表示 Usap 默认是关闭的,可以不管
    private boolean mUsapPoolEnabled = false;
    /**
     * Listening socket that accepts new server connections.
     * 用于接收新服务器连接的 socket
     */
    private LocalServerSocket mZygoteSocket;
    Runnable runSelectLoop(String abiList) {
        ArrayList<FileDescriptor> socketFDs = new ArrayList<>();
        ArrayList<ZygoteConnection> peers = new ArrayList<>();
		// 添加mZygoteSocket，用于监听新服务连接
        socketFDs.add(mZygoteSocket.getFileDescriptor());
    	// 添加一个空connection来占位，真正的连接是从index=1 开始。
        peers.add(null);

        mUsapPoolRefillTriggerTimestamp = INVALID_TIMESTAMP;
		// 开启无限循环
        while (true) {
            fetchUsapPoolPolicyPropsWithMinInterval();
            mUsapPoolRefillAction = UsapPoolRefillAction.NONE;
            int[] usapPipeFDs = null;
            StructPollfd[] pollFDs;
            // 分配足够的空间给poll structs, StructPollfd 是作为 os.poll的输入输出参数使用。
            if (mUsapPoolEnabled) {
                usapPipeFDs = Zygote.getUsapPipeFDs();
                pollFDs = new StructPollfd[socketFDs.size() + 1 + usapPipeFDs.length];
            } else {
                // 此处
                pollFDs = new StructPollfd[socketFDs.size()];
            }
            
            int pollIndex = 0;
            // 遍历所有socketFd 添加 pollFDs中传给 poll.
            for (FileDescriptor socketFD : socketFDs) {
                pollFDs[pollIndex] = new StructPollfd();
                pollFDs[pollIndex].fd = socketFD;
                pollFDs[pollIndex].events = (short) POLLIN;
                ++pollIndex; 
            }
            ...
 			int pollReturnValue;
            try {
                // 使用poll机制监听所有fd，阻塞。当事件时将被唤醒。
                pollReturnValue = Os.poll(pollFDs, pollTimeoutMs);
            } catch (ErrnoException ex) {
                throw new RuntimeException("poll failed", ex);
            }
            if (pollReturnValue == 0) {
                // timeout或者fd未准备就绪时 返回 0，避免 else流程执行
             	mUsapPoolRefillTriggerTimestamp = INVALID_TIMESTAMP;
                mUsapPoolRefillAction = UsapPoolRefillAction.DELAYED;
            } else {
                // 主要看这里，表示有socket请求
                boolean usapPoolFDRead = false;
                // 开始轮询所有的socket，一开始就一个。
                while (--pollIndex >= 0) {
                    if ((pollFDs[pollIndex].revents & POLLIN) == 0) {
                        continue;
                    }

                    if (pollIndex == 0) {
                        // Zygote server socket
                        // 一开始会执行到这, 去创建一个连接，后续用于处理Command。
                        ZygoteConnection newPeer = acceptCommandPeer(abiList);
                        peers.add(newPeer);
                        socketFDs.add(newPeer.getFileDescriptor());
                    } else if (pollIndex < usapPoolEventFDIndex) {
                        // CommandPeer创建后 就会在此处处理。例如 AMS 的请求。
                        // Session socket accepted from the Zygote server socket
                        try {
                            ZygoteConnection connection = peers.get(pollIndex);
                            boolean multipleForksOK = !isUsapPoolEnabled()
                                    && ZygoteHooks.isIndefiniteThreadSuspensionSafe();
                            final Runnable command =
                                    connection.processCommand(this, multipleForksOK);
                            // mIsForkChild默认false, 
                            // 在创建的子进程中会赋值为true。
							if (mIsForkChild) { // 
                                if (command == null) {
                                    throw new IllegalStateException("command == null");
                                }
                                // 
                                return command;
                            } else { // 主进程中是一些检测操作，忽略
                                ...
                            }
                           ...
                        } catch (Exception e) {
                           if (!mIsForkChild) { 
                                // zygote 进程中发生异常，则将当前的socket关闭，后续流程中会重新创建。
                                Slog.e(TAG, "Exception executing zygote command: ", e);
                                ZygoteConnection conn = peers.remove(pollIndex);
                                conn.closeSocket();
                                socketFDs.remove(pollIndex);
                            } else {
                                // 子进程中发生异常，直接抛出
                                Log.e(TAG, "Caught post-fork exception in child process.", e);
                                throw e;
                            }
                        } finally {
                            // Reset the child flag, in the event that the child process is a child-
                            // zygote. The flag will not be consulted this loop pass after the
                            // Runnable is returned.
                            mIsForkChild = false;
                        }
                    } else {
                        // Either the USAP pool event FD or a USAP reporting pipe.
						...
                    }
                }
                ...
            }
			...
        }
    }
```

### ZygoteConnection.processCommand()

负责处理指令并fork进程。

* 从socket中读取指令，并解析参数。
* fork 一个子进程。
* 根据指令参数 找到程序的main()函数。
* 返回一个执行main()函数的Runnable，最终会在ZygoteInit.main() 中被执行。

流程和 forkSystemServer() 中 处理systemServer的流程基本上一致，区别是这里从socket中获取指令，而systemServer是硬编码的指令参数。

> [ZygoteConnection.java - processCommand](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/ZygoteConnection.java;drc=a88d63279834b0e5d67683b0949c594fd7dc376b;bpv=0;bpt=1;l=117)

```cpp
Runnable processCommand(ZygoteServer zygoteServer, boolean multipleOK) {
    ZygoteArguments parsedArgs;
	// 从socket中读取指令数据
    try (ZygoteCommandBuffer argBuffer = new ZygoteCommandBuffer(mSocket)) {
        while (true) {
            try {
                // 解析args到 ZygoteArguments 中。
                parsedArgs = ZygoteArguments.getInstance(argBuffer);
            } catch (IOException ex) {
                throw new IllegalStateException("IOException on command socket", ex);
            }
            
            // 根据 parsedArgs 做了一些判断，这里略过
            if (parsedArgs == null) {
                isEof = true;
                return null;
            }
            int pid;
           	...
        	if (parsedArgs.mInvokeWith != null || parsedArgs.mStartChildZygote
                    || !multipleOK || peer.getUid() != Process.SYSTEM_UID) {
                // Continue using old code for now. TODO: Handle these cases in the other path.
                pid = Zygote.forkAndSpecialize(parsedArgs.mUid, parsedArgs.mGid,
                        parsedArgs.mGids, parsedArgs.mRuntimeFlags, rlimits,
                        parsedArgs.mMountExternal, parsedArgs.mSeInfo, parsedArgs.mNiceName,
                        fdsToClose, fdsToIgnore, parsedArgs.mStartChildZygote,
                        parsedArgs.mInstructionSet, parsedArgs.mAppDataDir,
                        parsedArgs.mIsTopApp, parsedArgs.mPkgDataInfoList,
                        parsedArgs.mAllowlistedDataInfoList, parsedArgs.mBindMountAppDataDirs,
                        parsedArgs.mBindMountAppStorageDirs);

                try {
                    if (pid == 0) {
                        // in child 位于子进程
                        // 将 mIsForkChild 置为true
                        zygoteServer.setForkChild();
						// 关闭复制过来的zygoteServer.socket连接
                        zygoteServer.closeServerSocket();
                        IoUtils.closeQuietly(serverPipeFd);
                        serverPipeFd = null;
						// 处理子进程流程
                        return handleChildProc(parsedArgs, childPipeFd,
                                parsedArgs.mStartChildZygote);
                    } else {
                        childPipeFd = null;
                        // 处理父进程流程
                        handleParentProc(pid, serverPipeFd);
                        return null;
                    }
                } finally {
                    IoUtils.closeQuietly(childPipeFd);
                    IoUtils.closeQuietly(serverPipeFd);
                }
            } else {
                // ...
            }
        }
    }
    // ...
}
```

#### forkAndSpecialize()

```java
	static int forkAndSpecialize(int uid, int gid, int[] gids, int runtimeFlags,
            int[][] rlimits, int mountExternal, String seInfo, String niceName, int[] fdsToClose,
            int[] fdsToIgnore, boolean startChildZygote, String instructionSet, String appDataDir,
            boolean isTopApp, String[] pkgDataInfoList, String[] allowlistedDataInfoList,
            boolean bindMountAppDataDirs, boolean bindMountAppStorageDirs) {
        ZygoteHooks.preFork();
		// 调用 nativeForkAndSpecialize() fork一个进程
        int pid = nativeForkAndSpecialize(
                uid, gid, gids, runtimeFlags, rlimits, mountExternal, seInfo, niceName, fdsToClose,
                fdsToIgnore, startChildZygote, instructionSet, appDataDir, isTopApp,
                pkgDataInfoList, allowlistedDataInfoList, bindMountAppDataDirs,
                bindMountAppStorageDirs);
		// 返回pid ，父进程中返回的是子进程ID，子进程中返回0
        return pid;
    }

```

### ZygoteConnection.handleChildProc()

处理新创建的子进程的后续流程。

这里会调用和之前分析SystemServer 时一样的 `ZygoteInit.zygoteInit()`函数，它创建了Binder线程池并返回一个执行 main()函数的 Runnable。详细流程可以在[Android系统启动流程](./Android系统启动流程.md) 中查看。

> [ZygoteConnection.java - handleChildProc()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/ZygoteConnection.java;drc=34eaab3ec69d395be6577c208ac0c725b404c5b2;l=514)

```java
	private Runnable handleChildProc(ZygoteArguments parsedArgs,
            FileDescriptor pipeFd, boolean isZygote) {
		// 关闭自身这个连接的socket
        closeSocket();
		// 设置进程名
        Zygote.setAppProcessName(parsedArgs, TAG);

        if (parsedArgs.mInvokeWith != null) { // 不是这
           // ...
        } else {
            if (!isZygote) {
                // 调用了 ZygoteInit.zygoteInit() 返回 应用的main()函数
                return ZygoteInit.zygoteInit(parsedArgs.mTargetSdkVersion,
                        parsedArgs.mDisabledCompatChanges,
                        parsedArgs.mRemainingArgs, null /* classLoader */);
            } else {
                return ZygoteInit.childZygoteInit(
                        parsedArgs.mRemainingArgs  /* classLoader */);
            }
        }
    }
```

### ZygoteConnection.handleParentProc()

处理父进程的后续流程。

> [ZygoteConnection.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/com/android/internal/os/ZygoteConnection.java;drc=34eaab3ec69d395be6577c208ac0c725b404c5b2;l=555)

```java
	private void handleParentProc(int pid, FileDescriptor pipeFd) {
        if (pid > 0) {
            setChildPgid(pid);
        }

        boolean usingWrapper = false;
        if (pipeFd != null && pid > 0) {
            // 这里是使用 pipe 和 Child通讯。
            // 执行了 poll() 等待 child消息
            // 应该是当 app debuggable 或 SystemProperties.get("wrap." + appName) 存在时，才会进入这里。暂时忽略
        }

        try {
            // 将 pid 和 usingWrapper 返回给socket请求方。
            mSocketOutStream.writeInt(pid);
            mSocketOutStream.writeBoolean(usingWrapper);
        } catch (IOException ex) {
            throw new IllegalStateException("Error writing to command socket", ex);
        }
    }

```



---

## 5. 启动应用程序

zygote 孵化了应用进程之后，最终会调用 `ActivityThread.main()`，这样我们的应用程序就正式启动了。

> [ActivityThread.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/app/ActivityThread.java;l=264)
>
> 摘录一些重要的成员变量和内部类

```java
public final class ActivityThread extends ClientTransactionHandler
        implements ActivityThreadInternal {
    private static volatile ActivityThread sCurrentActivityThread;
    // 系统于应用的访问
    Instrumentation mInstrumentation;
    //
    ActivityThread() {
        mResourcesManager = ResourcesManager.getInstance();
    }
    //
    final ApplicationThread mAppThread = new ApplicationThread();
    
    // --------------------------------
    // mainLooper
    final Looper mLooper = Looper.myLooper();
    final H mH = new H();
    // sMainThreadHandler 就是 mH
    static volatile Handler sMainThreadHandler;  // set once in main()
    public Handler getHandler() {
        return mH;
    }
    
   
    // ----------------------------
    class H extends Handler {
        // ...
    }
    
    // ApplicationThread，ATMS 会通过它回调到对应应用进程
    private class ApplicationThread extends IApplicationThread.Stub {
        // ..
	}
}
```

### ActivityThread.main()

Android应用程序执行的入口。

* 在当前线程创建一个Looper，并作为 `mainLooper`。
* 调用`attach()` 创建上下文。
* 开启Looper 处理Android中的消息。

> [ActivityThread.java - main()](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/app/ActivityThread.java;l=7871)

```java
// main入口
public static void main(String[] args) {
    Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "ActivityThreadMain");

    // Install selective syscall interception
    AndroidOs.install();
    CloseGuard.setEnabled(false);

    Environment.initForCurrentUser();

    // Make sure TrustedCertificateStore looks in the right place for CA certificates
    final File configDir = Environment.getUserConfigDirectory(UserHandle.myUserId());
    TrustedCertificateStore.setDefaultUserDirectory(configDir);

    // Call per-process mainline module initialization.
    initializeMainlineModules();
    Process.setArgV0("<pre-initialized>");
    // 将当前线程的Looper作为mainLooper。
    Looper.prepareMainLooper();

    // Find the value for {@link #PROC_START_SEQ_IDENT} if provided on the command line.
    // It will be in the format "seq=114"
    long startSeq = 0;
    if (args != null) {
        for (int i = args.length - 1; i >= 0; --i) {
            if (args[i] != null && args[i].startsWith(PROC_START_SEQ_IDENT)) {
                startSeq = Long.parseLong(
                    args[i].substring(PROC_START_SEQ_IDENT.length()));
            }
        }
    }
    // 创建 ActivityThread 对象。
    ActivityThread thread = new ActivityThread();
    // 构建上下文
    thread.attach(false, startSeq);
    //
    if (sMainThreadHandler == null) {
        // 将ActivityThread.mH 作为 sMainThreadHandler
        sMainThreadHandler = thread.getHandler();
    }
    // 开启 Loop 循环,阻塞当前线程
    Looper.loop();
    throw new RuntimeException("Main thread loop unexpectedly exited");
}
```

### ActivityThread.attach()

* 将 `ApplicationThread` 和 AMS绑定。
* 观察GC，内存不足时会释放一些Activity。
* 监听配置变化

> [ActivityThread.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/ActivityThread.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=7601)

```java
// system = false
private void attach(boolean system, long startSeq) {
    sCurrentActivityThread = this;
    mConfigurationController = new ConfigurationController(this);
    mSystemThread = system;
    if (!system) {
        android.ddm.DdmHandleAppName.setAppName("<pre-initialized>",UserHandle.myUserId());
        // 虚拟机错误相关
        RuntimeInit.setApplicationObject(mAppThread.asBinder());
        // 获取 AMS
        final IActivityManager mgr = ActivityManager.getService();
        try {
            // 将 ApplicationThread 和 AMS绑定。
            // 这里还会将一些 待启动的服务启动。
            mgr.attachApplication(mAppThread, startSeq);
        } catch (RemoteException ex) {
            throw ex.rethrowFromSystemServer();
        }
        // Watch for getting close to heap limit.
        // 观察GC
        BinderInternal.addGcWatcher(new Runnable() {
            @Override public void run() {
                if (!mSomeActivitiesChanged) {
                    // 在 handleStartActivity() 会置为true
                    return;
                }
                Runtime runtime = Runtime.getRuntime();
                long dalvikMax = runtime.maxMemory();
                long dalvikUsed = runtime.totalMemory() - runtime.freeMemory();
                if (dalvikUsed > ((3*dalvikMax)/4)) {
                    if (DEBUG_MEMORY_TRIM) Slog.d(TAG, "Dalvik max=" + (dalvikMax/1024)
                                                  + " total=" + (runtime.totalMemory()/1024)
                                                  + " used=" + (dalvikUsed/1024));
                    mSomeActivitiesChanged = false;
                    try {
                        // 内存不足时 释放一些Activity
                        ActivityTaskManager.getService().releaseSomeActivities(mAppThread);
                    } catch (RemoteException e) {
                        throw e.rethrowFromSystemServer();
                    }
                }
            }
        });
        // ...
    } else {
        // 这部分是在系统应用构建上下文时调用，例如 SystemServer。
        // ...
    }

    // 监听配置变化
    ViewRootImpl.ConfigChangedCallback configChangedCallback = (Configuration globalConfig) -> {
        synchronized (mResourcesManager) {
            // We need to apply this change to the resources immediately, because upon returning
            // the view hierarchy will be informed about it.
            if (mResourcesManager.applyConfigurationToResources(globalConfig,
                                                                null /* compat */)) {
                mConfigurationController.updateLocaleListFromAppContext(
                    mInitialApplication.getApplicationContext());

                // This actually changed the resources! Tell everyone about it.
                final Configuration updatedConfig =
                    mConfigurationController.updatePendingConfiguration(globalConfig);
                if (updatedConfig != null) {
                    // 将变更后的配置通过Handler发送出去
                    sendMessage(H.CONFIGURATION_CHANGED, globalConfig);
                    mPendingConfiguration = updatedConfig;
                }
            }
        }
    };
    ViewRootImpl.addConfigCallback(configChangedCallback);
}
```



## 启动Activity

### ActivityTaskSupervisor.realStartActivityLocked()

*  创建 启动 activity的事务 clientTransaction。
  * 触发 `handleLaunchActivity()`
* 添加了一个后续期望变成的 resume状态的请求，在启动事务执行完成后被会调用。这样生命周期就能自动变为 Resume。
  * 触发 `handleResumeActivity()`

```java
	boolean realStartActivityLocked(ActivityRecord r, WindowProcessController proc,
            boolean andResume, boolean checkConfig) throws RemoteException {
		//
        try {
            // ...
            try {
                // 创建 启动 activity的事务 clientTransaction
                // Create activity launch transaction.
                // 
                final ClientTransaction clientTransaction = ClientTransaction.obtain(
                        proc.getThread(), r.token);

                final boolean isTransitionForward = r.isTransitionForward();
                final IBinder fragmentToken = r.getTaskFragment().getFragmentToken();
                clientTransaction.addCallback(LaunchActivityItem.obtain(new Intent(r.intent),
                        System.identityHashCode(r), r.info,
                        // TODO: Have this take the merged configuration instead of separate global
                        // and override configs.
                        mergedConfiguration.getGlobalConfiguration(),
                        mergedConfiguration.getOverrideConfiguration(), r.compat,
                        r.getFilteredReferrer(r.launchedFromPackage), task.voiceInteractor,
                        proc.getReportedProcState(), r.getSavedState(), r.getPersistentSavedState(),
                        results, newIntents, r.takeOptions(), isTransitionForward,
                        proc.createProfilerInfoIfNeeded(), r.assistToken, activityClientController,
                        r.shareableActivityToken, r.getLaunchedFromBubble(), fragmentToken));
				// 设置后续期望变成的状态，后续变为resume
                // Set desired final state.
                final ActivityLifecycleItem lifecycleItem;
                if (andResume) {
                    lifecycleItem = ResumeActivityItem.obtain(isTransitionForward);
                } else {
                    lifecycleItem = PauseActivityItem.obtain();
                }
                // 这个请求会在事务执行后被调用，这样 Activity启动之后就能继续后续的生命周期，变为 Resume。
                clientTransaction.setLifecycleStateRequest(lifecycleItem);
				// 发送事务
                // Schedule transaction.
                mService.getLifecycleManager().scheduleTransaction(clientTransaction);
				// ...

            } catch (RemoteException e) {
               // ...
            }
        } finally {
            endDeferResume();
            proc.resumeConfigurationDispatch();
        }
		// ...
        return true;
    }
```





## ActivityManager

```java
@SystemService(Context.ACTIVITY_SERVICE)
public class ActivityManager {
    // Singleton是一个单例构造器
    @UnsupportedAppUsage
    private static final Singleton<IActivityManager> IActivityManagerSingleton =
            new Singleton<IActivityManager>() {
                @Override
                protected IActivityManager create() {
                    // 
                    final IBinder b = ServiceManager.getService(Context.ACTIVITY_SERVICE);
                    final IActivityManager am = IActivityManager.Stub.asInterface(b);
                    return am;
                }
            };
    
    @UnsupportedAppUsage
    public static IActivityManager getService() {
        return IActivityManagerSingleton.get();
    }
}
```

