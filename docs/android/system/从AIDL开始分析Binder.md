# 从AIDL开始分析Binder

Binder是Android提供的一种进行间通信的框架，它贯穿整个Android系统，整个流程比较复杂。因此我考虑先从上层如何使用Binder开始分析进而理解Binder。

Android提供了AIDL工具 帮我们快速构建一套基于Binder的跨进程通信架构。我们可以从AIDL生成的java类中来了解Binder的使用方式、基本结构以及关键的函数。

本文中AIDL案例是基于[Android进程间通信](../Android进程间通信.md) 一文中的 `IRemoteService.aidl` 案例来分析的。

## 分析IRemoteService.java

我们先从 `IRemoteService.java` 来开始分析Binder在Java层的实现机制。

> in：表示输入参数
>
> out：表示输出参数，它会在binder调用的返回过程中新建一个对象，并写入到 reply 中返回给我们。

```java
// IRemoteService.aidl
package com.zaze.demo;
interface IRemoteService {
    /**
     * Demonstrates some basic types that you can use as parameters
     * and return values in AIDL.
     */
    void basicTypes(int anInt, long aLong, boolean aBoolean, float aFloat,
            double aDouble, String aString);
	
    // 定义一个接口
    String getMessage();
    
    // out 会被服务端更新，然后返回给我们
    void testMessage(out IpcMessage outMessage);
}
```

.aidl 编译后会在 `app/generated/aidl_source_output_dir/debug or release/out/`目录下会自动生成 `IRemoteService.java`。

内部提供了一套默认的Binder架构。

> 在C/S架构中，Proxy负责提供访问服务的接口，Stub负责处理请求提供服务。可以通过断点来观察该类是如何工作的。
>
> 但我们发起接口调用时会发现 Proxy的断点在Client进程中执行，而Stud 中的断点在Service进程中被触发。

* **IBinder**：binder通讯接口，描述如何和服务进行交互
* **Binder**：继承自IBinder，实现了binder通讯相关的逻辑。
* **IRemoteService**：继承自IInterface，定义了业务接口，同时提供`asBinder()` 函数来 返回远程对象接口IBinder。
* **IRemoteService.Stud**：**主要供服务端使用，负责处理Client端的请求**，将接口和Binder进行绑定，具体服务会继承此类来实现功能。它屏蔽了Proxy和Service端通信的细节。
  * `onTransact()`：负责处理Client请求，将请求数据反序列化，并调用相应的接口功能的具体实现。
  * `asInterface()`：返回一个访问服务接口 IRemoteService。
    * 客户端：**由于客户端没有实现Stub，所以会返回Proxy 来进行远程访问。**Client在连接上Service后可以调用这个函数来获取对应访问接口。
    * 服务端：由于服务端实现了Stub，所以能够查询到，这样**服务端实际是本地直接调用**。
* **IRemoteService.Stub.Proxy**：**供客户端使用，继承内部持有负责访问服务接口的IBinder**。屏蔽了客户端和Server端通讯的细节。
  * 首先会将请求参数序列化到_data中。
  * 通过`mRemote.transact()` 发送_data 和 _reply，并获取到接口调用结果。
  * 若远程调用成功则从_reply中将数据反序列化处理并返回，失败则会调用`getDefaultImpl()`来处理。

```java
public interface IRemoteService extends android.os.IInterface {
   
    // ------------ Stub start -------------------------
    /**
     * 服务端中会继承Stub来实现服务的具体功能。
     */
    public static abstract class Stub extends android.os.Binder implements com.zaze.demo.IRemoteService {
        // 描述符，可以通过描述符来查询对应接口
        private static final java.lang.String DESCRIPTOR = "com.zaze.demo.IRemoteService";

        public Stub() {
            // 服务端将接口和Binder进行关联,
            // 后续queryLocalInterface(DESCRIPTOR)来查询IRemoteService接口。
            this.attachInterface(this, DESCRIPTOR);
        }

        /**
         * 客户端连接上服务后调用这个函数来，获取到Proxy对象。
         */
        public static com.zaze.demo.IRemoteService asInterface(android.os.IBinder obj) {
            if ((obj == null)) {
                return null;
            }
            // 通过描述符查询是否存在本地接口实例。
            android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
            if (((iin != null) && (iin instanceof com.zaze.demo.IRemoteService))) {
                // 服务端实现了Stub，所以能够查询到，这样服务端实际使用的就是本地调用。
                return ((com.zaze.demo.IRemoteService) iin);
            }
			// 客户端没有实现Stub，所以会返回Proxy 来远程访问服务。
            return new com.zaze.demo.IRemoteService.Stub.Proxy(obj);
        }

        @Override
        public android.os.IBinder asBinder() {
            return this;
        }

        @Override
        public boolean onTransact(int code, android.os.Parcel data, android.os.Parcel reply, int flags) throws android.os.RemoteException {
            // 1. 从data中读取数据进行反序列化
            // 2. 将反序列化后的数据传给具体的实现函数，并获取返回值
            // 3. 将返回值序列化 写入reply
            java.lang.String descriptor = DESCRIPTOR;
            switch (code) {
                case INTERFACE_TRANSACTION: {
                    reply.writeString(descriptor);
                    return true;
                }
                case TRANSACTION_basicTypes: {
                    data.enforceInterface(descriptor);
                    int _arg0;
                    _arg0 = data.readInt();
                    long _arg1;
                    _arg1 = data.readLong();
                    boolean _arg2;
                    _arg2 = (0 != data.readInt());
                    float _arg3;
                    _arg3 = data.readFloat();
                    double _arg4;
                    _arg4 = data.readDouble();
                    java.lang.String _arg5;
                    _arg5 = data.readString();
                    this.basicTypes(_arg0, _arg1, _arg2, _arg3, _arg4, _arg5);
                    reply.writeNoException();
                    return true;
                }
                case TRANSACTION_getMessage: {
                    data.enforceInterface(descriptor);
                    java.lang.String _result = this.getMessage();
                    reply.writeNoException();
                    reply.writeString(_result);
                    return true;
                }
                default: {
                    return super.onTransact(code, data, reply, flags);
                }
            }
        }

        
        // ------------------------------------------------
        // ------------ Proxy start -----------------------
        // 客户端获取该实例来访问服务端
        // 1. 数据序列化到_data中
        // 2. 通过mRemote.transact() 发送_data 和 _reply。
        // 3. 获取_reply调用结果。
        // 4. 从_reply中将数据反序列化处理
        private static class Proxy implements com.zaze.demo.IRemoteService {
            private android.os.IBinder mRemote;

            Proxy(android.os.IBinder remote) {
                mRemote = remote;
            }

            @Override
            public android.os.IBinder asBinder() {
                return mRemote;
            }

            public java.lang.String getInterfaceDescriptor() {
                return DESCRIPTOR;
            }

            @Override
            public void basicTypes(int anInt, long aLong, boolean aBoolean, float aFloat, double aDouble, java.lang.String aString) throws android.os.RemoteException {
                // ......
            }

            @Override
            public java.lang.String getMessage() throws android.os.RemoteException {
                android.os.Parcel _data = android.os.Parcel.obtain();
                android.os.Parcel _reply = android.os.Parcel.obtain();
                java.lang.String _result;
                try {
                    _data.writeInterfaceToken(DESCRIPTOR);
                    // mRemote 是远程调用对象IBinder
                    // 通过 IBinder.transact() 发送消息
                    boolean _status = mRemote.transact(Stub.TRANSACTION_getMessage, _data, _reply, 0);
                    if (!_status && getDefaultImpl() != null) {
                        // 远程调用失败，使用默认实现来处理。
                        return getDefaultImpl().getMessage();
                    }
                    _reply.readException();
                    // 将_reply数据反序列化
                    _result = _reply.readString();
                } finally {
                    _reply.recycle();
                    _data.recycle();
                }
                // 返回
                return _result;
            }

            public static com.zaze.demo.IRemoteService sDefaultImpl;
        }
        
        // ------------ Proxy end ------------------------
        // -----------------------------------------------
        
        
		// 接口的调用ID是按照定义顺序来定义的
        // 所以AIDL中定义的函数不能变更位置，会导致函数调用错乱。
        static final int TRANSACTION_basicTypes = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
        static final int TRANSACTION_getMessage = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
		
        // 设置一个默认实现，当远程调用失败时会使用这个默认实现来处理。
        public static boolean setDefaultImpl(com.zaze.demo.IRemoteService impl) {
            if (Stub.Proxy.sDefaultImpl != null) {
                throw new IllegalStateException("setDefaultImpl() called twice");
            }
            if (impl != null) {
                Stub.Proxy.sDefaultImpl = impl;
                return true;
            }
            return false;
        }

        public static com.zaze.demo.IRemoteService getDefaultImpl() {
            return Stub.Proxy.sDefaultImpl;
        }
    }
    
    // ------------ Stub end -------------------------
    // -----------------------------------------------

    /**
     * Demonstrates some basic types that you can use as parameters
     * and return values in AIDL.
     */
    public void basicTypes(int anInt, long aLong, boolean aBoolean, float aFloat, double aDouble, java.lang.String aString) throws android.os.RemoteException;

    public java.lang.String getMessage() throws android.os.RemoteException;
}

```

## 阶段总结一

通过阅读AIDL生成的java类，我们大致了解到了几个重要的类和接口，以及几个重要的函数。

### UML类图

以下是我们的`IRemoteService.aidl`涉及的相关类和接口。

![Binder](./%E4%BB%8EAIDL%E5%BC%80%E5%A7%8B%E5%88%86%E6%9E%90Binder.assets/Binder.jpg)

我们不妨猜测所有**基于Binder的Service在Java层中应该大致都是这样的结构**。抱着这样的想法可以去看看AMS在Java层的实现。通过阅读源码发现它们的结构是一致的。

### 重要的类/接口

> AMS就是基于 IActivityManager.aidl 实现的。
>
> [IActivityManager.aidl - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/app/IActivityManager.aidl;bpv=0;bpt=0)

只需将UML图中的IRemoteService替换成IActivityManager, 自定义Service替换成ActivityManagerService，完全就变成了AMS相关的UML类图。

下面的表格展示了重要的类和接口，以及和AMS的对照：

| 类/接口                        |                                                              | IRemoteService.aidl       | IActivityManager.aidl       |
| ------------------------------ | ------------------------------------------------------------ | ------------------------- | --------------------------- |
| IInterface                     | 用于表示是Binder接口，所有的Binder接口都需要实现这个接口。它提供了返回远程调用接口IBinder的能力。 | IRemoteService.java       | IActivityManager.java       |
| IBinder                        | 远程对象的基础接口， 接口描述了与远程对象交互的抽象协议。    | IRemoteService.Stub       | IActivityManager.Stub       |
| Binder: IBinder                | 一般都是基于它来实现远程调用服务。                           | IRemoteService.Stub       | IActivityManager.Stub       |
| -                              |                                                              |                           |                             |
| IXXXService: IInterface        | 用于定义业务逻辑相关接口。                                   |                           |                             |
| Stub: Binder, IXXXService      | 供服务端使用来实现服务，这里将服务业务和Binder通讯相结合。   | IRemoteService.Stub       | IActivityManager.Stub       |
| Proxy: IXXXService, IInterface | 供客户端使用，负责调用远程服务。                             | IRemoteService.Stub.Proxy | IActivityManager.Stub.Proxy |
| XXXService: Stub               | 服务端来实现服务功能的实现类。                               | 案例中采用的是匿名内部类  | ActivityManagerService.java |
|                                |                                                              |                           |                             |

### 重要的函数

| 函数                              |                                                              |      |
| --------------------------------- | ------------------------------------------------------------ | ---- |
| IInterface.**asBinder()**         | 返回远程对象接口IBinder，它描述如何和远程对象进行交互。      |      |
| IBinder.**transact()**            | Client调用对应API时 内部最终都会通过这个函数来发送消息。     |      |
| IBinder.**onTransact()**          | Service接收到消息时回调。                                    |      |
| IBinder.**queryLocalInterface()** | 它的作用是查询是否存在本地接口实现，保证Service调用自身时直接走本地调用。 |      |

到此我们通过分析自定义的 IRemoteService.aidl 这一个简单的案例，了解了Binder在Java层中的结构。从而能够相对容易的去分析系统的AMS乃至其他系统Service在Java层的实现。

Android设计的Binder架构包括了Java层和Native层两套，它们的实现是类似的，因而后面分析Native层时也可以按照这个模板来进行分析，只不过是在语法和类名上存在一定的差异而已。

在看Native层Binder机制之前我们需要先了解Client消息是如何发送给Service的，即Binder通信过程，这样我们就能先对Binder机制的整体有一个概念。

## 分析Client消息是如何发送给Service的

> 此处需要深入到Binder、IBinder、IInterface、ActivityManagerService等类/接口的源码中来进行分析。
>
> 可以在Android Studio中或者[Android Code Search)](https://cs.android.com/)中查看源码

在上面分析过程中我们知道了Client最终是调用了 `mRemote.transact()`来发送给Service，而最终的结果是Service进程中`Stub.onTransact()` 被调用。 `mRemote`就是远程对象的本地代理 IBinder，也是这个通信流程的关键。

我们来回忆一下`mRemote`是怎么被赋值的：

* 首先客户端通过通过`bindService()`获取到一个IBinder。
* 然后我们调用``IRemoteService.Stub.asInterface(IBinder)`` 来获取到Proxy。
* Proxy在构造函数中将传入的IBinder 赋值给mRemote。

所以`mRemote`就是我们 `bindService()`时获取的`IBinder`实例，因此这个我们需要了解一下 `bindService()`这个过程，

> 我将部分重要源码摘录在此处，并将阅读源码过程的个人理解以注解的形式附加在源码内。

### ContextImpl

Context的实现类，和AMS通讯来启动Service。

```java
class ContextImpl extends Context {
    @UnsupportedAppUsage
    final @NonNull ActivityThread mMainThread;
    @UnsupportedAppUsage
    final @NonNull LoadedApk mPackageInfo;
    @UnsupportedAppUsage
    private @Nullable ClassLoader mClassLoader;

    static ContextImpl createAppContext(ActivityThread mainThread, LoadedApk packageInfo,
            String opPackageName) {
        if (packageInfo == null) throw new IllegalArgumentException("packageInfo");
        ContextImpl context = new ContextImpl(null, mainThread, packageInfo,
            ContextParams.EMPTY, null, null, null, null, null, 0, null, opPackageName);
        context.setResources(packageInfo.getResources());
        context.mContextType = isSystemOrSystemUI(context) ? CONTEXT_TYPE_SYSTEM_OR_SYSTEM_UI
                : CONTEXT_TYPE_NON_UI;
        return context;
    }
    
    @Override
    public boolean bindService(Intent service, ServiceConnection conn, int flags) {
        warnIfCallingFromSystemProcess();
        return bindServiceCommon(service, conn, flags, null, mMainThread.getHandler(), null,
                getUser());
    }
    
    private boolean bindServiceCommon(Intent service, ServiceConnection conn, int flags,
            String instanceName, Handler handler, Executor executor, UserHandle user) {
        // 构建一个Binder 接口，作为回调使用。
        IServiceConnection sd;
		// 包装一下
        if (mPackageInfo != null) {
            if (executor != null) {
                sd = mPackageInfo.getServiceDispatcher(conn, getOuterContext(), executor, flags);
            } else {
                // 默认使用的 handler
                sd = mPackageInfo.getServiceDispatcher(conn, getOuterContext(), handler, flags);
            }
        } else {
            throw new RuntimeException("Not supported in system context");
        }
        validateServiceIntent(service);
        try {
            IBinder token = getActivityToken();
            if (token == null && (flags&BIND_AUTO_CREATE) == 0 && mPackageInfo != null
                    && mPackageInfo.getApplicationInfo().targetSdkVersion
                    < android.os.Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
                flags |= BIND_WAIVE_PRIORITY;
            }
            service.prepareToLeaveProcess(this);
            // 向 AMS 发送 bindService 请求，这是Binder通讯。
            int res = ActivityManager.getService().bindServiceInstance(
                    mMainThread.getApplicationThread(), getActivityToken(), service,
                    service.resolveTypeIfNeeded(getContentResolver()),
                    sd, flags, instanceName, getOpPackageName(), user.getIdentifier());
            if (res < 0) {
                throw new SecurityException(
                        "Not allowed to bind to service " + service);
            }
            return res != 0;
        } catch (RemoteException e) {
            throw e.rethrowFromSystemServer();
        }
    }

}
```



### ActivityManagerService.java

此时进入到了 AMS 所在的进程。

```java
public class ActivityManagerService extends IActivityManager.Stub
        implements Watchdog.Monitor, BatteryStatsImpl.BatteryCallback, ActivityManagerGlobalLock {
    
    /**
     * The list of bind service event listeners.
     * 绑定服务事件的监听器
     * AMS中有很多类似结构类型的监听，它们都负责某处理某一类事件，例如还有广播事件监听器BroadcastEventListener
     */
    final CopyOnWriteArrayList<BindServiceEventListener> mBindServiceEventListeners =
            new CopyOnWriteArrayList<>();
	// 负责 Activity 相关的逻辑
    public ActivityTaskManagerService mActivityTaskManager;
    
    // 负责 Service 相关的逻辑
    final ActiveServices mServices;

    
    // AMS中处理Handler消息逻辑都在这个类中
	final class MainHandler extends Handler {
        public MainHandler(Looper looper) {
            super(looper, null, true);
        }

        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
            case GC_BACKGROUND_PROCESSES_MSG: {
                synchronized (ActivityManagerService.this) {
                    mAppProfiler.performAppGcsIfAppropriateLocked();
                }
            } break;
            case SERVICE_TIMEOUT_MSG: {
                mServices.serviceTimeout((ProcessRecord) msg.obj);
            } break;
            case SERVICE_FOREGROUND_TIMEOUT_MSG: {
                mServices.serviceForegroundTimeout((ServiceRecord) msg.obj);
            } break;
            case SERVICE_FOREGROUND_TIMEOUT_ANR_MSG: {
                SomeArgs args = (SomeArgs) msg.obj;
                mServices.serviceForegroundTimeoutANR((ProcessRecord) args.arg1,
                        (String) args.arg2);
                args.recycle();
            } break;
            case SERVICE_FOREGROUND_CRASH_MSG: {
                SomeArgs args = (SomeArgs) msg.obj;
                mServices.serviceForegroundCrash(
                        (ProcessRecord) args.arg1,
                        (String) args.arg2,
                        (ComponentName) args.arg3);
                args.recycle();
            } break;
        }
    }
    
    // 这个类负责添加各种服务的监听器
    // 包括但不限于BindServiceEvent，
    public final class LocalService extends ActivityManagerInternal
            implements ActivityManagerLocal {
        @Override
        public void addBindServiceEventListener(@NonNull BindServiceEventListener listener) {
            // It's a CopyOnWriteArrayList, so no lock is needed.
            mBindServiceEventListeners.add(listener);
        }
    }
        
	/**
     * Binds to a service with a given instanceName, creating it if it does not already exist.
     * If the instanceName field is not supplied, binding to the service occurs as usual.
     */
    public int bindServiceInstance(IApplicationThread caller, IBinder token, Intent service,
            String resolvedType, IServiceConnection connection, int flags, String instanceName,
            String callingPackage, int userId) throws TransactionTooLargeException {
        return bindServiceInstance(caller, token, service, resolvedType, connection, flags,
                instanceName, false, 0, null, callingPackage, userId);
    }

    private int bindServiceInstance(IApplicationThread caller, IBinder token, Intent service,
            String resolvedType, IServiceConnection connection, int flags, String instanceName,
            boolean isSdkSandboxService, int sdkSandboxClientAppUid,
            String sdkSandboxClientAppPackage, String callingPackage, int userId)
            throws TransactionTooLargeException {
        try {
            synchronized (this) {
                // 调用 ActiveServices 来处理 
                return mServices.bindServiceLocked(caller, token, service, resolvedType, connection,
                        flags, instanceName, isSdkSandboxService, sdkSandboxClientAppUid,
                        sdkSandboxClientAppPackage, callingPackage, userId);
            }
        } finally {
        }
    }
}
```



### ActiveServices.java

Service相关逻辑基本都在这个类中实现，内部缓存了服务信息，并提供了服务绑定、启动、关闭等功能。

```java
public final class ActiveServices {
    // 
    final ActivityManagerService mAm;
    // 保存主服务，key是uId
    final SparseArray<ServiceMap> mServiceMap = new SparseArray<>();
    // 保存所有当前绑定的服务连接。 key是 客户的IServiceConnection的IBinder。
    final ArrayMap<IBinder, ArrayList<ConnectionRecord>> mServiceConnections = new ArrayMap<>();
    // 保存需要启动但还未启动的服务的启动请求。等待对应线程启动。
    final ArrayList<ServiceRecord> mPendingServices = new ArrayList<>();
    // 保存在崩溃后需要重启的服务
    final ArrayList<ServiceRecord> mRestartingServices = new ArrayList<>();

	
    @GuardedBy("mAm")
    private void notifyBindingServiceEventLocked(ProcessRecord callerApp, String callingPackage) {
        final ApplicationInfo ai = callerApp.info;
        final String callerPackage = ai != null ? ai.packageName : callingPackage;
        // 通过AMS的Handler发送 DISPATCH_BINDING_SERVICE_EVENT 消息。
        // 发送服务绑定事件
        if (callerPackage != null) {
            mAm.mHandler.obtainMessage(ActivityManagerService.DISPATCH_BINDING_SERVICE_EVENT,
                                       callerApp.uid, 0, callerPackage).sendToTarget();
        }
    }
    
}
```

#### bindServiceLocked()

```java

    int bindServiceLocked(IApplicationThread caller, IBinder token, Intent service,
                      String resolvedType, final IServiceConnection connection, int flags,
                      String instanceName, boolean isSdkSandboxService, int sdkSandboxClientAppUid,
                      String sdkSandboxClientAppPackage, String callingPackage, final int userId)
        throws TransactionTooLargeException {

        final int callingPid = Binder.getCallingPid();
        final int callingUid = Binder.getCallingUid();
        // 从AMS中查询 启动方的进程信息：ProcessRecord
        final ProcessRecord callerApp = mAm.getRecordForAppLOSP(caller);
        // 用于追踪与AM端的服务的连接，后面流程中会 记录和Activity相连接的服务的 ConnectionRecord
        ActivityServiceConnectionsHolder<ConnectionRecord> activity = null;
        if (token != null) {
            activity = mAm.mAtmInternal.getServiceConnectionsHolder(token);
            if (activity == null) {
                Slog.w(TAG, "Binding with unknown activity: " + token);
                return 0;
            }
        }

        ...
        // 查询服务信息：ServiceLookupResult 中包含了需要启动的服务信息 ServiceRecord，以及调用方的信息callingPackage
        ServiceLookupResult res = retrieveServiceLocked(service, instanceName, isSdkSandboxService, sdkSandboxClientAppUid, sdkSandboxClientAppPackage, resolvedType, callingPackage, callingPid, callingUid, userId, true, callerFg, isBindExternal, allowInstant);
        ...
        // 提取 ServiceRecord
        ServiceRecord s = res.record;
        ...
        // 这里存在一个请求权限的流程，此时暂不启动服务，等权限审核通过后在启动服务。
        // 内部通过RemoteCallback接收回调，最终还是通过 bringUpServiceLocked()来启动服务。
        boolean permissionsReviewRequired = !packageFrozen
                && !requestStartTargetPermissionsReviewIfNeededLocked(s, callingPackage, null,
                        callingUid, service, callerFg, userId, true, connection);
        final long origId = Binder.clearCallingIdentity();

        try {
            // 从 Service 记录信息中 检索出服务和应用的绑定信息，包括了是Service的IBinder。
            AppBindRecord b = s.retrieveAppBindingLocked(service, callerApp);
            // 创建连接信息
            ConnectionRecord c = new ConnectionRecord(b, activity,
                                                      connection, flags, clientLabel, clientIntent,
                                                      callerApp.uid, callerApp.processName, callingPackage, res.aliasComponent);
            // 获取将 IServiceConnection 回调接口转为 IBinder
            IBinder binder = connection.asBinder();
            // 往 s:ServiceRecord 中添加 IServiceConnection 和 ConnectionRecord
            s.addConnection(binder, c);
            // 往 b:AppBindRecord 中添加 ConnectionRecord
            b.connections.add(c);
            if (activity != null) {
                // 记录和 Activity相关联的服务的 ConnectionRecord
                activity.addConnection(c);
            }
            // 用于记录进程中所有的服务的状态信息
            final ProcessServiceRecord clientPsr = b.client.mServices;
            clientPsr.addConnection(c);
            c.startAssociationIfNeeded();
            
			........
            //
            if (s.app != null) {
                updateServiceClientActivitiesLocked(s.app.mServices, c, true);
            }
            // 查询 mServiceConnections 中是否已存在此 binder服务对应的连接记录。
            ArrayList<ConnectionRecord> clist = mServiceConnections.get(binder);
            if (clist == null) {
                // 没有则新建一个连接队列 clist，并保存到mServiceConnections中，和binder进行关联
                clist = new ArrayList<>();
                mServiceConnections.put(binder, clist);
            }
            // 添加 当前的连接信息 保存在binder对应的连接缓存列表中
            clist.add(c);
            
            boolean needOomAdj = false;
            if ((flags&Context.BIND_AUTO_CREATE) != 0) {
                s.lastActivity = SystemClock.uptimeMillis();
                needOomAdj = true;
                // ***********************************
            	// 启动服务入口, 调用来此函数来带起服务
            	// ***********************************
                if (bringUpServiceLocked(s, service.getFlags(), callerFg, false,
                                         permissionsReviewRequired, packageFrozen, true) != null) {
                    mAm.updateOomAdjPendingTargetsLocked(OomAdjuster.OOM_ADJ_REASON_BIND_SERVICE);
                    return 0;
                }
            }
            setFgsRestrictionLocked(callingPackage, callingPid, callingUid, service, s, userId,
                                    false);

            if (s.app != null) {
                ProcessServiceRecord servicePsr = s.app.mServices;
                if ((flags&Context.BIND_TREAT_LIKE_ACTIVITY) != 0) {
                    servicePsr.setTreatLikeActivity(true);
                }
                if (s.allowlistManager) {
                    servicePsr.mAllowlistManager = true;
                }
                // This could have made the service more important.
                mAm.updateLruProcessLocked(s.app, (callerApp.hasActivitiesOrRecentTasks()
                                                   && servicePsr.hasClientActivities())
                                           || (callerApp.mState.getCurProcState() <= PROCESS_STATE_TOP
                                               && (flags & Context.BIND_TREAT_LIKE_ACTIVITY) != 0),
                                           b.client);
                needOomAdj = true;
                mAm.enqueueOomAdjTargetLocked(s.app);
            }

            if (s.app != null && b.intent.received) {
                // Service is already running, so we can immediately
                // publish the connection.

                // If what the client try to start/connect was an alias, then we need to
                // pass the alias component name instead to the client.

				// 服务已经启动了
                final ComponentName clientSideComponentName =
                    res.aliasComponent != null ? res.aliasComponent : s.name;
                try {
                    // 回调已连接，在这里回调给应用进程 Service的 IBinder
                    c.conn.connected(clientSideComponentName, b.intent.binder, false);
                } catch (Exception e) {
                    Slog.w(TAG, "Failure sending service " + s.shortInstanceName
                           + " to connection " + c.conn.asBinder()
                           + " (in " + c.binding.client.processName + ")", e);
                }

                // If this is the first app connected back to this binding,
                // and the service had previously asked to be told when
                // rebound, then do so.
                if (b.intent.apps.size() == 1 && b.intent.doRebind) {
                    // 第一个绑定到Service，触发 BindService
                    requestServiceBindingLocked(s, b.intent, callerFg, true);
                }
            } else if (!b.intent.requested) {
                requestServiceBindingLocked(s, b.intent, callerFg, false);
            }

            maybeLogBindCrossProfileService(userId, callingPackage, callerApp.info.uid);

            getServiceMapLocked(s.userId).ensureNotStartingBackgroundLocked(s);

        } finally {
            Binder.restoreCallingIdentity(origId);
        }
        // 以阻塞的方式通知 绑定服务事件
        notifyBindingServiceEventLocked(callerApp, callingPackage);

        return 1;
    }

```





#### bringUpServiceLocked()

* 若服务已经启动过，会通过 `sendServiceArgsLocked()` 触发 `onStartCommand()`。
* 服务未启动，会判断是否位于独立进程，服务所在进程是否已启动等。
* 服务进程已启动：调用`realStartServiceLocked()` 开始启动服务。
* 服务所在进程未启动：调用 `startProcessLocked()` 去通过zygote fork 一个进程。同时将这次服务请求加入到待启动队列中，这些待启动服务会在应用启动的 `attachApplication()` 流程中被触发。最终也是调用的 `realStartServiceLocked()`。

```java
	// 负责启动服务
    private String bringUpServiceLocked(ServiceRecord r, int intentFlags, boolean execInFg,
            boolean whileRestarting, boolean permissionsReviewRequired, boolean packageFrozen,
            boolean enqueueOomAdj)
            throws TransactionTooLargeException {
        // 有关联的进程信息表示 Service 已启动过
        if (r.app != null && r.app.getThread() != null) {
            // **************************************************************
            // 内部会通过IApplicationThread 回调给应用进程
            // 触发 onStartCommand()
            // **************************************************************
            sendServiceArgsLocked(r, execInFg, false);
            return null;
        }
		// Service 未启动过
        if (!whileRestarting && mRestartingServices.contains(r)) {
            // If waiting for a restart, then do nothing.
            // 不是在重启流程中调用，且包含在重启列表中，那么此时直接跳过不处理。
            return null;
        }

        // We are now bringing the service up, so no longer in the
        // restarting state.
        // 准备启动服务，将重启状态移除
        if (mRestartingServices.remove(r)) {
            clearRestartingIfNeededLocked(r);
        }

        // Make sure this service is no longer considered delayed, we are starting it now.
        // 从延迟启动列表中移除，并标记为不延迟。
        if (r.delayed) {
            if (DEBUG_DELAYED_STARTS) Slog.v(TAG_SERVICE, "REM FR DELAY LIST (bring up): " + r);
            getServiceMapLocked(r.userId).mDelayedStartList.remove(r);
            r.delayed = false;
        }

        // Make sure that the user who owns this service is started.  If not,
        // we don't want to allow it to run.
        // 检测服务对应的app已经启动，没启动就不允许继续
        if (!mAm.mUserController.hasStartedUserState(r.userId)) {
            String msg = "Unable to launch app "
                    + r.appInfo.packageName + "/"
                    + r.appInfo.uid + " for service "
                    + r.intent.getIntent() + ": user " + r.userId + " is stopped";
            Slog.w(TAG, msg);
            bringDownServiceLocked(r, enqueueOomAdj);
            return msg;
        }

        // Report usage if binding is from a different package except for explicitly exempted
        // bindings
        // 服务所在 packageName 和当前调用启动服务的packageName 不同时上报信息。
        if (!r.appInfo.packageName.equals(r.mRecentCallingPackage)
                && !r.isNotAppComponentUsage) {
            mAm.mUsageStatsService.reportEvent(
                    r.packageName, r.userId, UsageEvents.Event.APP_COMPONENT_USED);
        }

        // Service is now being launched, its package can't be stopped.
        // 准备启动服务，保证所在应用不能被stop
        try {
            AppGlobals.getPackageManager().setPackageStoppedState(
                    r.packageName, false, r.userId);
        } catch (RemoteException e) {
        } catch (IllegalArgumentException e) {
            Slog.w(TAG, "Failed trying to unstop package "
                    + r.packageName + ": " + e);
        }
		
        // isolated = true 表示Service运行在独立的进程中。
        final boolean isolated = (r.serviceInfo.flags&ServiceInfo.FLAG_ISOLATED_PROCESS) != 0;
        final String procName = r.processName;
        // HostingRecord 描述启动进行需要的各种信息。
        HostingRecord hostingRecord = new HostingRecord(
                HostingRecord.HOSTING_TYPE_SERVICE, r.instanceName,
                r.definingPackageName, r.definingUid, r.serviceInfo.processName);
        // Service 所在进程的信息
        ProcessRecord app;

        if (!isolated) {
            // **************************************************************
            // Service 非单独进程走此流程
            // 了解服务启动流程直接看此处即可
            // **************************************************************
            app = mAm.getProcessRecordLocked(procName, r.appInfo.uid);
			// 判断服务所在进程是否已经启动，
            if (app != null) { // 启动
                final IApplicationThread thread = app.getThread();
                final int pid = app.getPid();
                final UidRecord uidRecord = app.getUidRecord();
                if (thread != null) {
                    try {
                        app.addPackage(r.appInfo.packageName, r.appInfo.longVersionCode,
                                mAm.mProcessStats);
                        // **************************************************************
                        // 真正启动服务的流程
                        // **************************************************************
                        realStartServiceLocked(r, app, thread, pid, uidRecord, execInFg,
                                enqueueOomAdj);
                        // 启动成功则 流程结束
                        return null;
                    } catch (TransactionTooLargeException e) {
                        throw e;
                    } catch (RemoteException e) {
                        Slog.w(TAG, "Exception when starting service " + r.shortInstanceName, e);
                    }

                    // If a dead object exception was thrown -- fall through to
                    // restart the application.	
                }
            }
        } else {
            // If this service runs in an isolated process, then each time
            // we call startProcessLocked() we will get a new isolated
            // process, starting another process if we are currently waiting
            // for a previous process to come up.  To deal with this, we store
            // in the service any current isolated process it is running in or
            // waiting to have come up.
            // Service位于独立进程 走此流程，此处仅对app和hostingRecord进程了赋值。
            // 服务中已经保存了服务进程的信息。
            app = r.isolationHostProc;
            if (WebViewZygote.isMultiprocessEnabled()
                    && r.serviceInfo.packageName.equals(WebViewZygote.getPackageName())) {
                hostingRecord = HostingRecord.byWebviewZygote(r.instanceName, r.definingPackageName,
                        r.definingUid, r.serviceInfo.processName);
            }
            if ((r.serviceInfo.flags & ServiceInfo.FLAG_USE_APP_ZYGOTE) != 0) {
                hostingRecord = HostingRecord.byAppZygote(r.instanceName, r.definingPackageName,
                        r.definingUid, r.serviceInfo.processName);
            }
        }
        
        // Not running -- get it started, and enqueue this service record
        // to be executed when the app comes up.
        // **************************************************************
        // 服务所在进程未启动 或者 服务位于独立进程时 走此流程
        // 会先启动服务所在进程，然后保存启动服务请求到 mPendingServices
        // **************************************************************
        if (app == null && !permissionsReviewRequired && !packageFrozen) {
            // TODO (chriswailes): Change the Zygote policy flags based on if the launch-for-service
            //  was initiated from a notification tap or not.
            if (r.isSdkSandbox) {
                final int uid = Process.toSdkSandboxUid(r.sdkSandboxClientAppUid);
                app = mAm.startSdkSandboxProcessLocked(procName, r.appInfo, true, intentFlags,
                        hostingRecord, ZYGOTE_POLICY_FLAG_EMPTY, uid, r.sdkSandboxClientAppPackage);
                r.isolationHostProc = app;
            } else {
                // **************************************************************
                // 启动服务所在进程
                // **************************************************************
                app = mAm.startProcessLocked(procName, r.appInfo, true, intentFlags,
                        hostingRecord, ZYGOTE_POLICY_FLAG_EMPTY, false, isolated);
            }
            if (app == null) {
                // 启动进程失败。
                bringDownServiceLocked(r, enqueueOomAdj);
                return msg;
            }
            if (isolated) {
                r.isolationHostProc = app;
            }
        }

        if (r.fgRequired) {
            mAm.tempAllowlistUidLocked(r.appInfo.uid,
                    mAm.mConstants.mServiceStartForegroundTimeoutMs, REASON_SERVICE_LAUNCH,
                    "fg-service-launch",
                    TEMPORARY_ALLOW_LIST_TYPE_FOREGROUND_SERVICE_ALLOWED,
                    r.mRecentCallingUid);
        }
		// 将此次请求加入到 待启动服务列表中。
        // 它们会在应用启动的 `attachApplication()` 中被启动。
        if (!mPendingServices.contains(r)) {
            mPendingServices.add(r);
        }

        if (r.delayedStop) {
            // 服务被标记未关闭
            // Oh and hey we've already been asked to stop!
            r.delayedStop = false;
            if (r.startRequested) {
                if (DEBUG_DELAYED_STARTS) Slog.v(TAG_SERVICE,
                        "Applying delayed stop (in bring up): " + r);
                stopServiceLocked(r, enqueueOomAdj);
            }
        }

        return null;
    }
```



#### realStartServiceLocked()

真正创建服务的地方

```java
	private void realStartServiceLocked(ServiceRecord r, ProcessRecord app,
            IApplicationThread thread, int pid, UidRecord uidRecord, boolean execInFg,
            boolean enqueueOomAdj) throws RemoteException {
        if (thread == null) {
            throw new RemoteException();
        }

        r.setProcess(app, thread, pid, uidRecord);
        r.restartTime = r.lastActivity = SystemClock.uptimeMillis();

        final ProcessServiceRecord psr = app.mServices;
        // 这个方法并没有实际启动服务，只是通过ProcessServiceRecord来记录该服务被启动。
        // 并告诉我们这个服务是不是新起的服务。
        final boolean newService = psr.startService(r);
        // 将Service的状态提升到 executing
        bumpServiceExecutingLocked(r, execInFg, "create", null /* oomAdjReason */);
        mAm.updateLruProcessLocked(app, false, null);
        updateServiceForegroundLocked(psr, /* oomAdj= */ false);
        // Force an immediate oomAdjUpdate, so the client app could be in the correct process state
        // before doing any service related transactions
        mAm.enqueueOomAdjTargetLocked(app);
        mAm.updateOomAdjLocked(app, OomAdjuster.OOM_ADJ_REASON_START_SERVICE);

        boolean created = false;
        try {
			...
            
            final int uid = r.appInfo.uid;
            final String packageName = r.name.getPackageName();
            final String serviceName = r.name.getClassName();
            FrameworkStatsLog.write(FrameworkStatsLog.SERVICE_LAUNCH_REPORTED, uid, packageName,
                    serviceName);
            mAm.mBatteryStatsService.noteServiceStartLaunch(uid, packageName, serviceName);
            // 通知Package使用，会更新package的最后使用时间。
            mAm.notifyPackageUse(r.serviceInfo.packageName,
                                 PackageManager.NOTIFY_PACKAGE_USE_SERVICE);
            // **************************************************************
            // 安排创建服务，这里触发 onCreate()
            // 这个thread就是ActivityThread中的ApplicationThread mAppThread.
            // **************************************************************
            thread.scheduleCreateService(r, r.serviceInfo,
                    mAm.compatibilityInfoForPackage(r.serviceInfo.applicationInfo),
                    app.mState.getReportedProcState());
            r.postNotification();
            // 标记为已创建
            created = true;
        } catch (DeadObjectException e) {
            Slog.w(TAG, "Application dead when creating service " + r);
            mAm.appDiedLocked(app, "Died when creating service");
            throw e;
        } finally {
            if (!created) {
                // Keep the executeNesting count accurate.
                final boolean inDestroying = mDestroyingServices.contains(r);
                // **************************************************************
                // 触发 onDestroy()
                // **************************************************************
                serviceDoneExecutingLocked(r, inDestroying, inDestroying, false);

                // Cleanup.
                if (newService) {
                    // 这里并不是真正的关闭服务，而是在psr中记录 该服务被关闭。
                    psr.stopService(r);
                    r.setProcess(null, null, 0, null);
                }
                // Retry.
                if (!inDestroying) {
                    // 计划重启服务
                    scheduleServiceRestartLocked(r, false);
                }
            }
        }

        if (r.allowlistManager) {
            psr.mAllowlistManager = true;
        }

        requestServiceBindingsLocked(r, execInFg);

        updateServiceClientActivitiesLocked(psr, null, true);

        if (newService && created) {
            psr.addBoundClientUidsOfNewService(r);
        }

        // If the service is in the started state, and there are no
        // pending arguments, then fake up one so its onStartCommand() will
        // be called.
        
        // Service已经被启动，并且客户端端没有设置参数，此处伪造了参数，保证onStartCommand()能被调用。
        if (r.startRequested && r.callStart && r.pendingStarts.size() == 0) {
            r.pendingStarts.add(new ServiceRecord.StartItem(r, false, r.makeNextStartId(),
                    null, null, 0));
        }
        
        // **************************************************************
		// 发送服务参数 触发 onStartCommand()
        // **************************************************************
        sendServiceArgsLocked(r, execInFg, true);
		
        if (r.delayed) {
            // 去除延迟启动标记
            if (DEBUG_DELAYED_STARTS) Slog.v(TAG_SERVICE, "REM FR DELAY LIST (new proc): " + r);
            getServiceMapLocked(r.userId).mDelayedStartList.remove(r);
            r.delayed = false;
        }
		
        if (r.delayedStop) {
            // 发现服务被关闭，去关闭服务
            // Oh and hey we've already been asked to stop!
            r.delayedStop = false;
            if (r.startRequested) {
                if (DEBUG_DELAYED_STARTS) Slog.v(TAG_SERVICE,
                        "Applying delayed stop (from start): " + r);
                stopServiceLocked(r, enqueueOomAdj);
            }
        }
    }
```

#### requestServiceBindingLocked()

触发 `onBind()`。

```java
	private final boolean requestServiceBindingLocked(ServiceRecord r, IntentBindRecord i,
            boolean execInFg, boolean rebind) throws TransactionTooLargeException {
        if (r.app == null || r.app.getThread() == null) {
            // If service is not currently running, can't yet bind.
            return false;
        }
        if (DEBUG_SERVICE) Slog.d(TAG_SERVICE, "requestBind " + i + ": requested=" + i.requested
                + " rebind=" + rebind);
        if ((!i.requested || rebind) && i.apps.size() > 0) {
            try {
                bumpServiceExecutingLocked(r, execInFg, "bind",
                        OomAdjuster.OOM_ADJ_REASON_BIND_SERVICE);
                // 触发 onBind()
                r.app.getThread().scheduleBindService(r, i.intent.getIntent(), rebind,
                        r.app.mState.getReportedProcState());
                if (!rebind) {
                    i.requested = true;
                }
                i.hasBound = true;
                i.doRebind = false;
            } catch (TransactionTooLargeException e) {
                // Keep the executeNesting count accurate.
                if (DEBUG_SERVICE) Slog.v(TAG_SERVICE, "Crashed while binding " + r, e);
                final boolean inDestroying = mDestroyingServices.contains(r);
                serviceDoneExecutingLocked(r, inDestroying, inDestroying, false);
                throw e;
            } catch (RemoteException e) {
                if (DEBUG_SERVICE) Slog.v(TAG_SERVICE, "Crashed while binding " + r);
                // Keep the executeNesting count accurate.
                final boolean inDestroying = mDestroyingServices.contains(r);
                serviceDoneExecutingLocked(r, inDestroying, inDestroying, false);
                return false;
            }
        }
        return true;
    }
```





### ServiceManager

```java
public final class ServiceManager {
    
    private static IServiceManager sServiceManager;
    private static Map<String, IBinder> sCache = new ArrayMap<String, IBinder>();
    
    public static void initServiceCache(Map<String, IBinder> cache) {
        if (sCache.size() != 0) {
            throw new IllegalStateException("setServiceCache may only be called once");
        }
        sCache.putAll(cache);
    }

    
    public static IBinder getService(String name) {
        try {
            IBinder service = sCache.get(name);
            if (service != null) {
                return service;
            } else {
                return Binder.allowBlocking(rawGetService(name));
            }
        } catch (RemoteException e) {
            Log.e(TAG, "error in getService", e);
        }
        return null;
    }
    
    public static void addService(String name, IBinder service, boolean allowIsolated,
            int dumpPriority) {
        try {
            getIServiceManager().addService(name, service, allowIsolated, dumpPriority);
        } catch (RemoteException e) {
            Log.e(TAG, "error in addService", e);
        }
    }
    
    private static IServiceManager getIServiceManager() {
        if (sServiceManager != null) {
            return sServiceManager;
        }

        // Find the service manager
        sServiceManager = ServiceManagerNative
                .asInterface(Binder.allowBlocking(BinderInternal.getContextObject()));
        return sServiceManager;
    }
}    


```



### BinderInternal

```java
public class BinderInternal {
    /**
     * Return the global "context object" of the system.  This is usually
     * an implementation of IServiceManager, which you can use to find
     * other services.
     */
    @UnsupportedAppUsage
    public static final native IBinder getContextObject();
}
```

### ApplicationThread

它是 ActivityThread的内部类，是一个Binder接口，AMS通过它将消息回调给应用进程。

```java
private class ApplicationThread extends IApplicationThread.Stub {
    // AMS 回调创建Service
    public final void scheduleCreateService(IBinder token,
                                            ServiceInfo info, CompatibilityInfo compatInfo, int processState) {
        updateProcessState(processState, false);
        CreateServiceData s = new CreateServiceData();
        s.token = token;
        s.info = info;
        s.compatInfo = compatInfo;

        sendMessage(H.CREATE_SERVICE, s);
    }
    // AMS 回调 bind Service
    public final void scheduleBindService(IBinder token, Intent intent,
                                          boolean rebind, int processState) {
        updateProcessState(processState, false);
        BindServiceData s = new BindServiceData();
        s.token = token;
        s.intent = intent;
        s.rebind = rebind;

        if (DEBUG_SERVICE)
            Slog.v(TAG, "scheduleBindService token=" + token + " intent=" + intent + " uid="
                   + Binder.getCallingUid() + " pid=" + Binder.getCallingPid());
        sendMessage(H.BIND_SERVICE, s);
    }

    // AMS 回调 服务被触发启动，调用 onStartCommand()
    public final void scheduleServiceArgs(IBinder token, ParceledListSlice args) {
        List<ServiceStartArgs> list = args.getList();

        for (int i = 0; i < list.size(); i++) {
            ServiceStartArgs ssa = list.get(i);
            ServiceArgsData s = new ServiceArgsData();
            s.token = token;
            s.taskRemoved = ssa.taskRemoved;
            s.startId = ssa.startId;
            s.flags = ssa.flags;
            s.args = ssa.args;

            sendMessage(H.SERVICE_ARGS, s);
        }
    }
}
```





### ActivityThread.java

```java
package android.app;

public final class ActivityThread extends ClientTransactionHandler
        implements ActivityThreadInternal {
    final ApplicationThread mAppThread = new ApplicationThread();
	
    class H extends Handler {
        public static final int CREATE_SERVICE          = 114;
        public static final int BIND_SERVICE            = 121;
        public static final int EXECUTE_TRANSACTION = 159;

        public void handleMessage(Message msg) {
            if (DEBUG_MESSAGES) Slog.v(TAG, ">>> handling: " + codeToString(msg.what));
            switch (msg.what) {
                ....
                case CREATE_SERVICE:
                    if (Trace.isTagEnabled(Trace.TRACE_TAG_ACTIVITY_MANAGER)) {
                        Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER,
                                ("serviceCreate: " + String.valueOf(msg.obj)));
                    }
                    // 创建服务
                    handleCreateService((CreateServiceData)msg.obj);
                    Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);
                    break;
                case BIND_SERVICE:
                    Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "serviceBind");
                    // 绑定服务
                    handleBindService((BindServiceData)msg.obj);
                    Trace.traceEnd(Trace.TRACE_TAG_ACTIVITY_MANAGER);
                    break;
                ....
 				case EXECUTE_TRANSACTION:
                    final ClientTransaction transaction = (ClientTransaction) msg.obj;
                    mTransactionExecutor.execute(transaction);
                    if (isSystem()) {
                        // Client transactions inside system process are recycled on the client side
                        // instead of ClientLifecycleManager to avoid being cleared before this
                        // message is handled.
                        transaction.recycle();
                    }
                    // TODO(lifecycler): Recycle locally scheduled transactions.
                    break;
				....
            }
        }
    }
    
    public final void bindApplication(String processName, ApplicationInfo appInfo,
                String sdkSandboxClientAppVolumeUuid, String sdkSandboxClientAppPackage,
                ProviderInfoList providerList, ComponentName instrumentationName,
                ProfilerInfo profilerInfo, Bundle instrumentationArgs,
                IInstrumentationWatcher instrumentationWatcher,
                IUiAutomationConnection instrumentationUiConnection, int debugMode,
                boolean enableBinderTracking, boolean trackAllocation,
                boolean isRestrictedBackupMode, boolean persistent, Configuration config,
                CompatibilityInfo compatInfo, Map services, Bundle coreSettings,
                String buildSerial, AutofillOptions autofillOptions,
                ContentCaptureOptions contentCaptureOptions, long[] disabledCompatChanges,
                SharedMemory serializedSystemFontMap,
                long startRequestedElapsedTime, long startRequestedUptime) {
            if (services != null) {
                if (false) {
                    // Test code to make sure the app could see the passed-in services.
                    for (Object oname : services.keySet()) {
                        if (services.get(oname) == null) {
                            continue; // AM just passed in a null service.
                        }
                        String name = (String) oname;

                        // See b/79378449 about the following exemption.
                        switch (name) {
                            case "package":
                            case Context.WINDOW_SERVICE:
                                continue;
                        }

                        if (ServiceManager.getService(name) == null) {
                            Log.wtf(TAG, "Service " + name + " should be accessible by this app");
                        }
                    }
                }

                // Setup the service cache in the ServiceManager
                ServiceManager.initServiceCache(services);
            }

            setCoreSettings(coreSettings);

            AppBindData data = new AppBindData();
            data.processName = processName;
            data.appInfo = appInfo;
            data.sdkSandboxClientAppVolumeUuid = sdkSandboxClientAppVolumeUuid;
            data.sdkSandboxClientAppPackage = sdkSandboxClientAppPackage;
            data.providers = providerList.getList();
            data.instrumentationName = instrumentationName;
            data.instrumentationArgs = instrumentationArgs;
            data.instrumentationWatcher = instrumentationWatcher;
            data.instrumentationUiAutomationConnection = instrumentationUiConnection;
            data.debugMode = debugMode;
            data.enableBinderTracking = enableBinderTracking;
            data.trackAllocation = trackAllocation;
            data.restrictedBackupMode = isRestrictedBackupMode;
            data.persistent = persistent;
            data.config = config;
            data.compatInfo = compatInfo;
            data.initProfilerInfo = profilerInfo;
            data.buildSerial = buildSerial;
            data.autofillOptions = autofillOptions;
            data.contentCaptureOptions = contentCaptureOptions;
            data.disabledCompatChanges = disabledCompatChanges;
            data.mSerializedSystemFontMap = serializedSystemFontMap;
            data.startRequestedElapsedTime = startRequestedElapsedTime;
            data.startRequestedUptime = startRequestedUptime;
            sendMessage(H.BIND_APPLICATION, data);
        }
    
}

public abstract class ClientTransactionHandler {
    
    void scheduleTransaction(ClientTransaction transaction) {
        transaction.preExecute(this);
        sendMessage(ActivityThread.H.EXECUTE_TRANSACTION, transaction);
    } 
}

```

#### handleCreateService()

```java
private void handleCreateService(CreateServiceData data) {
        // If we are getting ready to gc after going to the background, well
        // we are back active so skip it.
        unscheduleGcIdler();
		// 通过 LoadedApk 获取服务所在包信息
        LoadedApk packageInfo = getPackageInfoNoCheck(
                data.info.applicationInfo, data.compatInfo);
        Service service = null;
        try {
            if (localLOGV) Slog.v(TAG, "Creating service " + data.info.name);
			// 构建 Application
            Application app = packageInfo.makeApplicationInner(false, mInstrumentation);
			// 获取ClassLoader
            final java.lang.ClassLoader cl;
            if (data.info.splitName != null) {
                cl = packageInfo.getSplitClassLoader(data.info.splitName);
            } else {
                cl = packageInfo.getClassLoader();
            }
            // 通过ClassLoader 实例化 Service
            service = packageInfo.getAppFactory()
                    .instantiateService(cl, data.info.name, data.intent);
            // 构建 Service使用的 context 
            ContextImpl context = ContextImpl.getImpl(service
                    .createServiceBaseContext(this, packageInfo));
            if (data.info.splitName != null) {
                context = (ContextImpl) context.createContextForSplit(data.info.splitName);
            }
            if (data.info.attributionTags != null && data.info.attributionTags.length > 0) {
                final String attributionTag = data.info.attributionTags[0];
                context = (ContextImpl) context.createAttributionContext(attributionTag);
            }
            // Service resources must be initialized with the same loaders as the application
            // context.
            // 将Service对应的 Application的 ResourceLoader 放入到Service的Context中
            context.getResources().addLoaders(
                    app.getResources().getLoaders().toArray(new ResourcesLoader[0]));
			//
            context.setOuterContext(service);
            service.attach(context, this, data.info.name, data.token, app,
                    ActivityManager.getService());
            service.onCreate();
            mServicesData.put(data.token, data);
            mServices.put(data.token, service);
            try {
                ActivityManager.getService().serviceDoneExecuting(
                        data.token, SERVICE_DONE_EXECUTING_ANON, 0, 0);
            } catch (RemoteException e) {
                throw e.rethrowFromSystemServer();
            }
        } catch (Exception e) {
            if (!mInstrumentation.onException(service, e)) {
                throw new RuntimeException(
                    "Unable to create service " + data.info.name
                    + ": " + e.toString(), e);
            }
        }
    }

    
```

#### handleBindService()

这里调用 `onBind()`。

```java
	private void handleBindService(BindServiceData data) {
        CreateServiceData createData = mServicesData.get(data.token);
        Service s = mServices.get(data.token);
        if (DEBUG_SERVICE)
            Slog.v(TAG, "handleBindService s=" + s + " rebind=" + data.rebind);
        if (s != null) {
            try {
                data.intent.setExtrasClassLoader(s.getClassLoader());
                data.intent.prepareToEnterProcess(isProtectedComponent(createData.info),
                        s.getAttributionSource());
                try {
                    if (!data.rebind) {
                        // 调用 onBind
                        IBinder binder = s.onBind(data.intent);
                        //
                        ActivityManager.getService().publishService(
                                data.token, data.intent, binder);
                    } else {
                        // 调用 onRebind
                        s.onRebind(data.intent);
                        ActivityManager.getService().serviceDoneExecuting(
                                data.token, SERVICE_DONE_EXECUTING_ANON, 0, 0);
                    }
                } catch (RemoteException ex) {
                    throw ex.rethrowFromSystemServer();
                }
            } catch (Exception e) {
                if (!mInstrumentation.onException(s, e)) {
                    throw new RuntimeException(
                            "Unable to bind to service " + s
                            + " with " + data.intent + ": " + e.toString(), e);
                }
            }
        }
    }
```



#### handleServiceArgs()

这里触发 `onStartCommand()` 。

```java
	private void handleServiceArgs(ServiceArgsData data) {
        CreateServiceData createData = mServicesData.get(data.token);
        Service s = mServices.get(data.token);
        if (s != null) {
            try {
                if (data.args != null) {
                    data.args.setExtrasClassLoader(s.getClassLoader());
                    data.args.prepareToEnterProcess(isProtectedComponent(createData.info),
                            s.getAttributionSource());
                }
                int res;
                if (!data.taskRemoved) {
                    // 调用 onStartCommand
                    res = s.onStartCommand(data.args, data.flags, data.startId);
                } else {
                    s.onTaskRemoved(data.args);
                    res = Service.START_TASK_REMOVED_COMPLETE;
                }

                QueuedWork.waitToFinish();
				// 回调给 AMS
                try {
                    ActivityManager.getService().serviceDoneExecuting(
                            data.token, SERVICE_DONE_EXECUTING_START, data.startId, res);
                } catch (RemoteException e) {
                    throw e.rethrowFromSystemServer();
                }
            } catch (Exception e) {
                if (!mInstrumentation.onException(s, e)) {
                    throw new RuntimeException(
                            "Unable to start service " + s
                            + " with " + data.args + ": " + e.toString(), e);
                }
            }
        }
    }
```











### Service

```java
package android.app;

public abstract class Service extends ContextWrapper implements ComponentCallbacks2,
        ContentCaptureManager.ContentCaptureClient {
    private static final String TAG = "Service";


    @Override
    protected void attachBaseContext(Context newBase) {
        super.attachBaseContext(newBase);
        if (newBase != null) {
            newBase.setContentCaptureOptions(getContentCaptureOptions());
        }
    }

    // ------------------ Internal API ------------------
    
    /**
     * @hide
     */
    @UnsupportedAppUsage
    public final void attach(
            Context context,
            ActivityThread thread, String className, IBinder token,
            Application application, Object activityManager) {
        attachBaseContext(context);
        mThread = thread;           // NOTE:  unused - remove?
        mClassName = className;
        mToken = token;
        mApplication = application;
        mActivityManager = (IActivityManager)activityManager;
        mStartCompatibility = getApplicationInfo().targetSdkVersion
                < Build.VERSION_CODES.ECLAIR;

        setContentCaptureOptions(application.getContentCaptureOptions());
    }

    /**
     * Creates the base {@link Context} of this {@link Service}.
     * Users may override this API to create customized base context.
     *
     * @see android.window.WindowProviderService WindowProviderService class for example
     * @see ContextWrapper#attachBaseContext(Context)
     *
     * @hide
     */
    public Context createServiceBaseContext(ActivityThread mainThread, LoadedApk packageInfo) {
        return ContextImpl.createAppContext(mainThread, packageInfo);
    }


    // set by the thread after the constructor and before onCreate(Bundle icicle) is called.
    @UnsupportedAppUsage
    private ActivityThread mThread = null;
    @UnsupportedAppUsage
    private String mClassName = null;
    @UnsupportedAppUsage
    private IBinder mToken = null;
    @UnsupportedAppUsage
    private Application mApplication = null;
    @UnsupportedAppUsage
    private IActivityManager mActivityManager = null;
    @UnsupportedAppUsage
    private boolean mStartCompatibility = false;


}

```

















而最终的结果是Service进程中`Stub.onTransact()` 被调用，在此处我们借助断点调试的功能来找到最初的调用点是 `execTransact()`。

![image-20230303162306901](./%E4%BB%8EAIDL%E5%BC%80%E5%A7%8B%E5%88%86%E6%9E%90Binder.assets/image-20230303162306901.png)

```java
// Entry point from android_util_Binder.cpp's onTransact.
@UnsupportedAppUsage
private boolean execTransact(int code, long dataObj, long replyObj,
                             int flags) {
    // At that point, the parcel request headers haven't been parsed so we do not know what
    // {@link WorkSource} the caller has set. Use calling UID as the default.
    final int callingUid = Binder.getCallingUid();
    final long origWorkSource = ThreadLocalWorkSource.setUid(callingUid);
    try {
        return execTransactInternal(code, dataObj, replyObj, flags, callingUid);
    } finally {
        ThreadLocalWorkSource.restore(origWorkSource);
    }
}
```

从注释中我们可以知道它的调用入口是 `android_util_Binder.cpp`的 `onTransact()`函数。那么我就来看看它源码：

> [android_util_Binder.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/jni/android_util_Binder.cpp;l=21;bpv=0;bpt=0?q=android_util_Binder&sq=&ss=android%2Fplatform%2Fsuperproject)

```cpp
status_t onTransact(
    uint32_t code, const Parcel& data, Parcel* reply, uint32_t flags = 0) override
{
    JNIEnv* env = javavm_to_jnienv(mVM);

    LOG_ALWAYS_FATAL_IF(env == nullptr,
                        "Binder thread started or Java binder used, but env null. Attach JVM?");

    ALOGV("onTransact() on %p calling object %p in env %p vm %p\n", this, mObject, env, mVM);

    IPCThreadState* thread_state = IPCThreadState::self();
    const int32_t strict_policy_before = thread_state->getStrictModePolicy();

    //printf("Transact from %p to Java code sending: ", this);
    //data.print();
    //printf("\n");
    // 此处调用了Java层 Binder.execTransact() 函数
    jboolean res = env->CallBooleanMethod(mObject, gBinderOffsets.mExecTransact,
                                          code, reinterpret_cast<jlong>(&data), reinterpret_cast<jlong>(reply), flags);

    if (env->ExceptionCheck()) {
        ScopedLocalRef<jthrowable> excep(env, env->ExceptionOccurred());
        binder_report_exception(env, excep.get(),
                                "*** Uncaught remote exception!  "
                                "(Exceptions are not yet supported across processes.)");
        res = JNI_FALSE;
    }

    // Check if the strict mode state changed while processing the
    // call.  The Binder state will be restored by the underlying
    // Binder system in IPCThreadState, however we need to take care
    // of the parallel Java state as well.
    if (thread_state->getStrictModePolicy() != strict_policy_before) {
        set_dalvik_blockguard_policy(env, strict_policy_before);
    }

    if (env->ExceptionCheck()) {
        ScopedLocalRef<jthrowable> excep(env, env->ExceptionOccurred());
        binder_report_exception(env, excep.get(),
                                "*** Uncaught exception in onBinderStrictModePolicyChange");
    }

    // Need to always call through the native implementation of
    // SYSPROPS_TRANSACTION.
    if (code == SYSPROPS_TRANSACTION) {
        BBinder::onTransact(code, data, reply, flags);
    }

    //aout << "onTransact to Java code; result=" << res << endl
    //    << "Transact from " << this << " to Java code returning "
    //    << reply << ": " << *reply << endl;
    return res != JNI_FALSE ? NO_ERROR : UNKNOWN_TRANSACTION;
}

```

