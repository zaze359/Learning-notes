# 从MediaServer分析Binder

MediaServer 是一个由 C++编写的一个可执行程序，它包含了 MediaPlayService(多媒体相关服务)，并以binder机制进行通讯。

查看本篇前可以首先阅读 [Android之Binder机制](./Android之Binder机制.md) 了解一下 binder驱动的具体流程。

## MediaServer程序入口：main()

这个函数是MediaServer程序的入口，它主要做了以下几件事：

* 创建ProcessState对象，并打开了Binder驱动。
* 获取IServiceManager，它实际是一个BpBinder，从而和ServiceManger建立了通信
* 注册服务：包括MediaPlayerService、ResourceManagerService等。
* 创建binder线程池，同时在线程池和主线程中都开启Binder循环处理binder消息。

> [main_mediaserver.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/av/media/mediaserver/main_mediaserver.cpp;l=33?q=MediaServer&ss=android%2Fplatform%2Fsuperproject)

```cpp

int main(int argc __unused, char **argv __unused)
{
    signal(SIGPIPE, SIG_IGN);
	// 创建ProcessState对象，赋值给 proc 变量，同时启动了Binder
    sp<ProcessState> proc(ProcessState::self());
    // 获取servicemanager的代理对象，赋值给 sm
    sp<IServiceManager> sm(defaultServiceManager());
    ALOGI("ServiceManager: %p", sm.get());
    // 运行并注册 MediaPlayerService 服务
    MediaPlayerService::instantiate();
    ResourceManagerService::instantiate();
    // 内部是个空实现
    registerExtensions();
    ::android::hardware::configureRpcThreadpool(16, false);
    
    // 新建并启动binder线程池，
    // 新线程启动后会调用 IPCThreadState::self()->joinThreadPool()，开启循环并检测是否有binder请求
    ProcessState::self()->startThreadPool();
    // 主线程也开启binder循环检测是否有binder消息。
    IPCThreadState::self()->joinThreadPool();
    // 只有当上面主线程的binder looper退出才会执行到这，所以这里正常有2个线程来处理binder请求。
    // rpc线程池，内部直接调用了 IPCThreadState::self()->joinThreadPool()
    ::android::hardware::joinRpcThreadpool();
}
```

---

## 初始化binder

### ProcessState::self()

ProcessState这个类 主要涉及binder的初始化，包括打开binder驱动、分配内存。

这里的流程和 之前分析 [Android之Binder机制](./Android之Binder机制.md) 内的ServiceManager初始化Binder基本是一致的，只不过入口函数不同，这里调用的是`ProcessState::self()`。具体流程可以去那篇文章中看，这里介绍下流程：

`ProcessState::self()` 调用了 `init()` 它是单例模式：

1. 以单例模式 构建ProcessState对象，保证当前的MedisServer进程只有一个ProcessState实例。
2. 在 ProcessState 构造函数 内 通过 `open_driver()` 打开了 Binder设备。
3. 调用 `mmap()` 分配内存，将Binder设备 映射到 进程的地址空间。

>[ProcessState.cpp - self()](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/libs/binder/ProcessState.cpp;l=81)

```cpp
// binder驱动地址
#ifdef __ANDROID_VNDK__
const char* kDefaultDriver = "/dev/vndbinder";  // 这个是给供应商使用的
#else
const char* kDefaultDriver = "/dev/binder";
#endif

// 这是一个全局的静态变量，且init使用了单例模式，保证每个进程仅有一个 ProcessState 实例
[[clang::no_destroy]] static sp<ProcessState> gProcess;

sp<ProcessState> ProcessState::self()
{	// kDefaultDriver = "/dev/binder"
    return init(kDefaultDriver, false /*requireDefault*/);
}
```



## 创建ServiceManager的BpBinder

### IServiceManager.defaultServiceManager()

以单例模式在MediaServer进程中创建ServiceManager的BpBinder，它是客户端 和 SericeManager 进行交互的关键。

* 通过 `ProcessState::getContextObject()` 来获取 `BpBinder(0)`。
* 然后 `interface_cast()` 又通过这个 `BpBinder(0)` 创建一个 `BpServiceManager`。
* 最终 将返回给我们 IServiceManager的实现 BpServiceManager 返回给我们。

> [IServiceManager.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IServiceManager.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=142)

```cpp
[[clang::no_destroy]] static std::once_flag gSmOnce;
[[clang::no_destroy]] static sp<IServiceManager> gDefaultServiceManager;

sp<IServiceManager> defaultServiceManager()
{
    // 仅执行一次，也是一个单例模式
    std::call_once(gSmOnce, []() {
        sp<AidlServiceManager> sm = nullptr;
        while (sm == nullptr) {
            
            // using AidlServiceManager = android::os::IServiceManager;
            // interface_cast是模板函数，相当于 AidlServiceManager::asInterface(obj)
            // 这里面其实还包含了BpBinder、BBinder以及业务接口关联的逻辑，主要涉及几个重要的宏。后面单独列出。
            
			// 通过 getContextObject() 来获取 BpBinder(0)。
            // 然后 interface_cast() 会通过这个BpBinder创建一个 IServiceManger
            // IServiceManger sm 实际时一个 ServiceManagerShim
            sm = interface_cast<AidlServiceManager>(ProcessState::self()->getContextObject(nullptr));
            if (sm == nullptr) {
                ALOGE("Waiting 1s on context object on %s.", ProcessState::self()->getDriverName().c_str());
                sleep(1);
            }
        }
		// ServiceManagerShim 相当于 sm 的一个代理类,具体功能还是在sm中
        gDefaultServiceManager = sp<ServiceManagerShim>::make(sm);
    });

    return gDefaultServiceManager;
}
```



### ProcessState::getContextObject()

这个函数主要就是 通过 `getStrongProxyForHandle(0)` 来获取 IBinder，实际就是 `BpBinder(0)`。

> [ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=160)

```cpp
// 入参是nullptr，而且其实上也压根没有使用
sp<IBinder> ProcessState::getContextObject(const sp<IBinder>& /*caller*/)
{
	// 这里查找 0 对应的 资源项。
    sp<IBinder> context = getStrongProxyForHandle(0);
    // ...
    return context;
}
```

### ProcessState::getStrongProxyForHandle()

这个方法主要调用 `lookupHandleLocked(handle)`来查找 0 对应的资源。如果没有对应的资源项，则会创建一个新的项并初始化后返回。这个资源项就是指 ServiceManager的 BpBinder。

> [ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=315)
>
> 这里的 `handle` 类似Windows中的句柄，它的值就是一个资源项在资源组中的索引。BpBinder对应的BBinder也是通过 handle来查找的。
>
> 其中 `handle: 0` 是有特殊含义的，0 表示 ServiceManager对应的BBinder

```CPP
struct handle_entry {
        IBinder* binder;
        RefBase::weakref_type* refs;
};

sp<IBinder> ProcessState::getStrongProxyForHandle(int32_t handle)
{
    sp<IBinder> result;
	// 上锁
    AutoMutex _l(mLock);
    if (handle == 0 && the_context_object != nullptr) return the_context_object;
	// 查找是否存在 0 对应的 handle_entry，不存在时内部会创建一个并返回这个新建的资源空资源。
    // 一开始没有
    handle_entry* e = lookupHandleLocked(handle);

    if (e != nullptr) {
        IBinder* b = e->binder;
        // 这个if判断 handle_entry 是不是刚创建的一个新的BpBinder
        if (b == nullptr || !e->refs->attemptIncWeak(this)) {
            if (handle == 0) { 
                // 特殊情况，0 表示 ServiceManager这个上下文管理器
                // IPCThreadState 是实际执行Binder通信的地方
                // 关于它的具体实现放到后面再分析。
                IPCThreadState* ipc = IPCThreadState::self();
                CallRestriction originalCallRestriction = ipc->getCallRestriction();
                ipc->setCallRestriction(CallRestriction::NONE);
                Parcel data;
                // 执行transact 发送一个 PING_TRANSACTION，检测一下。
                // 确保在创建第一个本地引用之前(在创建BpBinder时将会发生) 上下文管理器被注册。
                // 如果在不存在上下文管理器时为 BpBinder创建了本地引用，那么驱动程序将无法提供对上下文管理器的引用。
                // 但是 驱动程序API 又不返回状态，所以需要先注册。
                status_t status = ipc->transact(
                        0, IBinder::PING_TRANSACTION, data, nullptr, 0);
                ipc->setCallRestriction(originalCallRestriction);
                if (status == DEAD_OBJECT)
                   return nullptr;
            }
			// 创建 BpBinder，并赋值给 handle_entry
            sp<BpBinder> b = BpBinder::PrivateAccessor::create(handle);
            // 赋值binder = BpBinder
            e->binder = b.get();
            // 赋值 refs = BpBinder的影子对象
            if (b) e->refs = b->getWeakRefs();
            // 返回的实际是 BpBinder
            result = b;
        } else {
            // force_set 强/弱引用计数 + 1
            result.force_set(b);
            // 弱引用计数 - 1
            e->refs->decWeak(this);
        }
    }

    return result;
}
```

### ProcessState::lookupHandleLocked()

查找是否存在 handle，若不存在则创建一个空资源项（handle_entry ）并插入到资源组末尾。

> [ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=299)

```cpp
ProcessState::handle_entry* ProcessState::lookupHandleLocked(int32_t handle)
{
    const size_t N=mHandleToObject.size();
    if (N <= (size_t)handle) {
        // 新建一个
        handle_entry e;
        // binder
        e.binder = nullptr;
        // binder的影子对象
        e.refs = nullptr;
        // 插入到末尾
        status_t err = mHandleToObject.insertAt(e, N, handle+1-N);
        if (err < NO_ERROR) return nullptr;
    }
    // 存在，直接读取返回
    return &mHandleToObject.editItemAt(handle);
}
```

---

## 服务注册

服务注册的流程都是类似的，挑选一个分析即可。

### MediaPlayerService::instantiate()

将自身注册到ServiceManger中，`defaultServiceManager()` 获取到的实际就是 BpServiceManager。

> [MediaPlayerService.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/av/media/libmediaplayerservice/MediaPlayerService.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=441)

```cpp
void MediaPlayerService::instantiate() {
    // "media.player" 是服务名
    // MediaPlayerService 是具体的服务IBinder。
    defaultServiceManager()->addService(
            String16("media.player"), new MediaPlayerService());
}
```

### BpServiceManager::addService()

`defaultServiceManager()` 获取到的是 `BpServiceManager`。

* 使用Parcel 序列化请求数据.
* 通过 `remote()->transact(TRANSACTION_addService)` 来进行Binder通信，其中`remote()` 就是BpBinder。最后会在对应的BBinder的 `onTransact()`中来执行id对应的函数，这里和Java层的逻辑是相同的。
* 解析 binder驱动返回的Parcel数据并返回。

> [IServiceManager.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/IServiceManager.cpp;l=96)

```cpp
// allowIsolated 默认false
// dumpPriority 默认0
::android::binder::Status BpServiceManager::addService(const ::std::string& name, const ::android::sp<::android::IBinder>& service, bool allowIsolated, int32_t dumpPriority) {
  // _aidl_data 是需要传输的数据
  ::android::Parcel _aidl_data;
  _aidl_data.markForBinder(remoteStrong());
  // _aidl_reply 用于接收返回结果
  ::android::Parcel _aidl_reply;
  ::android::status_t _aidl_ret_status = ::android::OK;
  ::android::binder::Status _aidl_status;
  ::android::binder::ScopedTrace _aidl_trace(ATRACE_TAG_AIDL, "AIDL::cpp::IServiceManager::addService::cppClient");
    
  // 开始写 Parcel数据
  // 描述符
  _aidl_ret_status = _aidl_data.writeInterfaceToken(getInterfaceDescriptor());
  if (((_aidl_ret_status) != (::android::OK))) {
    goto _aidl_error;
  }
  // 写入服务名
  _aidl_ret_status = _aidl_data.writeUtf8AsUtf16(name);
  if (((_aidl_ret_status) != (::android::OK))) {
    goto _aidl_error;
  }
  // 写入服务IBinder对象
  _aidl_ret_status = _aidl_data.writeStrongBinder(service);
  if (((_aidl_ret_status) != (::android::OK))) {
    goto _aidl_error;
  }
  //
  _aidl_ret_status = _aidl_data.writeBool(allowIsolated);
  if (((_aidl_ret_status) != (::android::OK))) {
    goto _aidl_error;
  }
  _aidl_ret_status = _aidl_data.writeInt32(dumpPriority);
  if (((_aidl_ret_status) != (::android::OK))) {
    goto _aidl_error;
  }
  // 调用 remote():BpBinder 执行事务，也就是这里进行了Binder通信。
  // BnServiceManager::TRANSACTION_addService 就是 addService函数的id索引，接口的调用id是按照定义顺序来定义的
  // 最后会在对应的BBinder的onTransact()中来执行id对应的函数，这里和Java层的逻辑是相同的。
  _aidl_ret_status = remote()->transact(BnServiceManager::TRANSACTION_addService, _aidl_data, &_aidl_reply, 0);
  // 
  if (UNLIKELY(_aidl_ret_status == ::android::UNKNOWN_TRANSACTION && IServiceManager::getDefaultImpl())) {
     return IServiceManager::getDefaultImpl()->addService(name, service, allowIsolated, dumpPriority);
  }
  if (((_aidl_ret_status) != (::android::OK))) {
    goto _aidl_error;
  }
  _aidl_ret_status = _aidl_status.readFromParcel(_aidl_reply);
  if (((_aidl_ret_status) != (::android::OK))) {
    goto _aidl_error;
  }
  if (!_aidl_status.isOk()) {
    return _aidl_status;
  }
  _aidl_error:
  _aidl_status.setFromStatusT(_aidl_ret_status);
  return _aidl_status;
}
```

### BpBinder::transact()

内部调用了 `IPCThreadState::self()->transact(0, TRANSACTION_addService)` 来发送服务注册请求，IPCThreadState中处理的就是Binder的通信逻辑。

> [BpBinder.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/BpBinder.cpp;l=333;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1)

```cpp
status_t BpBinder::transact(
    uint32_t code, const Parcel& data, Parcel* reply, uint32_t flags)
{
    if (mAlive) {
        bool privateVendor = flags & FLAG_PRIVATE_VENDOR;
        flags = flags & ~static_cast<uint32_t>(FLAG_PRIVATE_VENDOR);
        if (code >= FIRST_CALL_TRANSACTION && code <= LAST_CALL_TRANSACTION) {
            using android::internal::Stability;
            int16_t stability = Stability::getRepr(this);
            Stability::Level required = privateVendor ? Stability::VENDOR
                : Stability::getLocalLevel();
            if (CC_UNLIKELY(!Stability::check(stability, required))) {
                return BAD_TYPE;
            }
        }

        status_t status;
        if (CC_UNLIKELY(isRpcBinder())) { // 这是处理 RpcBinder的
            status = rpcSession()->transact(sp<IBinder>::fromExisting(this), code, data, reply,
                                            flags);
        } else {
            // 这里是本地Binder的通信。
            if constexpr (!kEnableKernelIpc) {
                LOG_ALWAYS_FATAL("Binder kernel driver disabled at build time");
                return INVALID_OPERATION;
            }
            // 调用了 IPCThreadState->transact()
            status = IPCThreadState::self()->transact(binderHandle(), code, data, reply, flags);
        }
        if (data.dataSize() > LOG_TRANSACTIONS_OVER_SIZE) {
            Mutex::Autolock _l(mLock);
            ALOGW("Large outgoing transaction of %zu bytes, interface descriptor %s, code %d",
                  data.dataSize(), String8(mDescriptorCache).c_str(), code);
        }
        if (status == DEAD_OBJECT) mAlive = 0;
        return status;
    }
    return DEAD_OBJECT;
}

```

### IPCThreadState

IPCThreadState 负责处理IPC通信相关的逻辑，即Binder机制的通信部分是在这里实现的，在这里会和binder驱动进行通信。每一个线程都一个独立的IPCThreadState实例。这块和binder驱动通讯的相关逻辑在 [Android之Binder机制](./Android之Binder机制.md) 一文中有详细的分析。

#### IPCThreadState::self()

是一个单例模式，在构造函数中会通过 `pthread_setspecific()` 将自身保存到 TLS中。

* pthread_getspecific：从TLS 中根据 key查找对应的数据。
* pthread_setspecific：将对应数据以 kv 格式保存到 TLS中。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=295)

```cpp
static pthread_mutex_t gTLSMutex = PTHREAD_MUTEX_INITIALIZER;
static std::atomic<bool> gHaveTLS(false);
// 保存在 tls中的key
static pthread_key_t gTLS = 0;
static std::atomic<bool> gShutdown = false;
static std::atomic<bool> gDisableBackgroundScheduling = false;


IPCThreadState* IPCThreadState::self()
{
    // 默认 gHaveTLS = false
    if (gHaveTLS.load(std::memory_order_acquire)) {
// 后续会goto到这
restart:
        // 
        const pthread_key_t k = gTLS;
        // 获取 gTLS 对应的IPCThreadState
        IPCThreadState* st = (IPCThreadState*)pthread_getspecific(k);
        // 存在之间返回
        if (st) return st;
        // 不存在 new一个IPCThreadState 对象
        // 构造函数内调用了 pthread_setspecific(gTLs, this) 将自身保存到TLS中
        return new IPCThreadState;
    }
    // gShutdown = false
    if (gShutdown.load(std::memory_order_relaxed)) {
        ALOGW("Calling IPCThreadState::self() during shutdown is dangerous, expect a crash.\n");
        return nullptr;
    }
	
    // 上锁
    pthread_mutex_lock(&gTLSMutex);
    // TLS 不存时，先创建一个 TLS Key, 然后跳转到restart处 获取TLS
    if (!gHaveTLS.load(std::memory_order_relaxed)) {
        // 创建一个 TLS Key，赋值给gTLS，用于检索
        int key_create_value = pthread_key_create(&gTLS, threadDestructor);
        if (key_create_value != 0) {
            // 创建失败
            pthread_mutex_unlock(&gTLSMutex);
            ALOGW("IPCThreadState::self() unable to create TLS key, expect a crash: %s\n",
                    strerror(key_create_value));
            return nullptr;
        }
        // gHaveTLS 更新为 true
        gHaveTLS.store(true, std::memory_order_release);
    }
    // 解锁
    pthread_mutex_unlock(&gTLSMutex);
    // 跳转到 restart
    goto restart;
}
```

#### IPCThreadState::transact()

这里有两个重要的函数：

* `writeTransactionData(BC_TRANSACTION)`：将请求数据写入mOut中。这里写入的是 BC_TRANSACTION 这个二级消息码。
* `waitForResponse()`：这个方法内部才真正和Binder驱动进行交互，会调用`talkWithDriver()` 和binder驱动通讯并获取到返回数据。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=807)

```cpp
status_t IPCThreadState::transact(int32_t handle,uint32_t code, const Parcel& data,Parcel* reply, uint32_t flags)
{
    status_t err;
    flags |= TF_ACCEPT_FDS;

	// 将 BC_TRANSACTION 二级消息码写入mOut中，表示应用程序向Binder设备发送消息。
    // 注册服务时code=TRANSACTION_addService。
    // 此处并没有真正的发送，仅仅是将数据写入到 mOut中
    err = writeTransactionData(BC_TRANSACTION, flags, handle, code, data, nullptr);
    if (err != NO_ERROR) {
        // 出错
        if (reply) reply->setError(err);
        return (mLastError = err);
    }
	
    if ((flags & TF_ONE_WAY) == 0) {
        if (reply) {
            err = waitForResponse(reply);
        } else {
            Parcel fakeReply;
            err = waitForResponse(&fakeReply);
        }
    } else {
        // 内部调用talkWithDriver()，通过 ioctl() 向binder驱动 发送 BINDER_WRITE_READ 指令
        // 驱动会根据write_size ,  read_size 的值来判断是读取数据还是写入数据.
        // 
        err = waitForResponse(nullptr, nullptr);
    }

    return err;
}
```

### ServiceManager接收并处理请求

我们之前发送的是 `BC_TRANSACTION` ，binder驱动会向 对应的服务端ServiceManager 发送 `BR_TRANSACTION` ，此时ServiceManager进程中的looper会被唤醒，最终调用`IPCThreadState::executeCommand()`。

#### IPCThreadState::executeCommand()

ServiceManager接收到 `BR_TRANSACTION`消息后也是通过这个函数来处理请求，最终调用 `BBinder.transact()` 来执行code对应的函数，处理完后调用 `sendReply()`发送回执。

当然后续若有发送到MediaPlayerService的请求最终也是调用这个函数来处理消息。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1274)

```cpp
// 一个全局的 BBinder，其实就是servicemanager
sp<BBinder> the_context_object;
// 这个函数会在 serviceManager启动时被调用
void IPCThreadState::setTheContextObject(const sp<BBinder>& obj)
{
    the_context_object = obj;
}
status_t IPCThreadState::executeCommand(int32_t cmd)
{
    BBinder* obj;
    RefBase::weakref_type* refs;
    status_t result = NO_ERROR;


    switch ((uint32_t)cmd) {
    case BR_ERROR:
        result = mIn.readInt32();
        break;

    case BR_OK: // 成功
        break;
    // ...
    case BR_TRANSACTION_SEC_CTX:
    case BR_TRANSACTION: // 对应 BC_TRANSACTION。
        { // 这里是对应服务所在进程，此时是注册服务所以是在ServiceManger进程中
            binder_transaction_data_secctx tr_secctx;
            binder_transaction_data& tr = tr_secctx.transaction_data;
			// 从mIn读取 binder_transaction_data 
            if (cmd == (int) BR_TRANSACTION_SEC_CTX) {
                result = mIn.read(&tr_secctx, sizeof(tr_secctx));
            } else {
                result = mIn.read(&tr, sizeof(tr));
                tr_secctx.secctx = 0;
            }
            if (result != NO_ERROR) break;
            Parcel buffer;
            buffer.ipcSetDataReference(
                reinterpret_cast<const uint8_t*>(tr.data.ptr.buffer),
                tr.data_size,
                reinterpret_cast<const binder_size_t*>(tr.data.ptr.offsets),
                tr.offsets_size/sizeof(binder_size_t), freeBuffer);

            // ....
            Parcel reply;
            status_t error;
            
            // 之前传过来的 ptr = 0
            if (tr.target.ptr) { // ptr != 0, 表示其他服务
                // 当前只有弱引用，使用前先通过wp生成一个sp
                if (reinterpret_cast<RefBase::weakref_type*>(tr.target.ptr)->attemptIncStrong(this)) {
                    // 调用BBinder的 transact
                    error = reinterpret_cast<BBinder*>(tr.cookie)->transact(tr.code, buffer,
                            &reply, tr.flags);
                    reinterpret_cast<BBinder*>(tr.cookie)->decStrong(this);
                } else {
                    error = UNKNOWN_TRANSACTION;
                }
            } else { // ptr = 0
                // the_context_object，ServiceManger进程会在启动是赋值。
                error = the_context_object->transact(tr.code, buffer, &reply, tr.flags);
            }

            if ((tr.flags & TF_ONE_WAY) == 0) {
                LOG_ONEWAY("Sending reply to %d!", mCallingPid);
                if (error < NO_ERROR) reply.setError(error);

                buffer.setDataSize(0);
                constexpr uint32_t kForwardReplyFlags = TF_CLEAR_BUF;
                // 回复
                sendReply(reply, (tr.flags & kForwardReplyFlags));
            } else {
                if (error != OK) {
                    //
                }
            }
        }
        break;
    // ....

    return result;
}
```





---

## Binder线程池

在`mian()` 函数最后 通过`ProcessState::startThreadPool()` 开启了Binder线程池，这个线程会接收处理发送到MediaPlayerService的请求。

### ProcessState::startThreadPool()

这里负责启动 Binder线程池

> [ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=197)

```cpp
void ProcessState::startThreadPool()
{
    AutoMutex _l(mLock);
    // 当前线程池未启动则去启动。保证每个进程只有一个binder线程池
    if (!mThreadPoolStarted) {
        if (mMaxThreads == 0) {
            ALOGW("Extra binder thread started, but 0 threads requested. Do not use "
                  "*startThreadPool when zero threads are requested.");
        }
        mThreadPoolStarted = true;
        // 生成一个线程池，true表示 主线程。
        spawnPooledThread(true);
    }
}
```

### ProcessState::spawnPooledThread()

> [ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=406)

```cpp
void ProcessState::spawnPooledThread(bool isMain)
{
    // 以启动则跳过
    if (mThreadPoolStarted) {
        // binder线程池名
        String8 name = makeBinderThreadName();
        ALOGV("Spawning new pooled thread, name=%s\n", name.string());
        // 创建了一个PoolThread
        sp<Thread> t = sp<PoolThread>::make(isMain);
        // 开启线程池，run中执行了 threadLoop()
        t->run(name.string());
        pthread_mutex_lock(&mThreadCountLock);
        mKernelStartedThreads++;
        pthread_mutex_unlock(&mThreadCountLock);
    }
}
// 从驱动中获取binder name
String8 ProcessState::makeBinderThreadName() {
    int32_t s = android_atomic_add(1, &mThreadPoolSeq);
    pid_t pid = getpid();
	// binder驱动名 /dev/binder
    std::string_view driverName = mDriverName.c_str();
    // 去除前缀，binder
    android::base::ConsumePrefix(&driverName, "/dev/");
    String8 name;
    name.appendFormat("%.*s:%d_%X", static_cast<int>(driverName.length()), driverName.data(), pid,
                      s);
    return name;
}
```



### PoolThread

构造函数中什么都没干，就赋值了 `mIsMain = true`。而在`threadLoop()` 中调用了 `IPCThreadState::self()->joinThreadPool()`

> [ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=78)

```cpp
class PoolThread : public Thread
{
public:
    explicit PoolThread(bool isMain)
        : mIsMain(isMain)
    {
    }

protected: // 在run时会被调用
    virtual bool threadLoop()
    {
        // 在新建的线程中创建了一个 IPCThreadState
        IPCThreadState::self()->joinThreadPool(mIsMain);
        return false;
    }

    const bool mIsMain;
};

```



### IPCThreadState::joinThreadPool(true)

这个函数会在当前线程内部开启一个循环，并通过 `isMain` 来控制线程的生命周期。

*  `isMain=true`：会向binder驱动发送 `BC_ENTER_LOOPER` 指令，标记当前线程进入Binder Looper状态，并且在正常情况下不会退出循环，所以当前线程一直在运行，主要是用来接收并处理Binder请求的。

* `isMain=false`：此时发送的是 `BC_REGISTER_LOOPER`，处理完binder请求后就会退出循环，然后当前线程的就完成任务结束了。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=727)

```cpp
// isMain=true
void IPCThreadState::joinThreadPool(bool isMain)
{
    pthread_mutex_lock(&mProcess->mThreadCountLock);
    mProcess->mCurrentThreads++;
    pthread_mutex_unlock(&mProcess->mThreadCountLock);
    // BC_ENTER_LOOPER，标记当前线程进入Binder Looper状态
    mOut.writeInt32(isMain ? BC_ENTER_LOOPER : BC_REGISTER_LOOPER);
    mIsLooper = true;
    status_t result;
    do {
        processPendingDerefs();
        // now get the next command to be processed, waiting if necessary
        result = getAndExecuteCommand();
		// 超时 && isMain=false 则退出循环。
        // 也就是说正常情况下，isMain=true 时是不退出的
        if(result == TIMED_OUT && !isMain) { 
            break;
        }
    } while (result != -ECONNREFUSED && result != -EBADF);
	// 退出了循环
    mOut.writeInt32(BC_EXIT_LOOPER);
    mIsLooper = false;
    talkWithDriver(false);
    pthread_mutex_lock(&mProcess->mThreadCountLock);
   	
    mProcess->mCurrentThreads--;
    pthread_mutex_unlock(&mProcess->mThreadCountLock);
}
```

### IPCThreadState::getAndExecuteCommand()

这里主要就是处理binder请求，流程和 `waitForResponse()` 类似，也是向binder驱动读/写数据，最后调用`IPCThreadState::executeCommand()`来处理返回结果。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=627)

```cpp
status_t IPCThreadState::getAndExecuteCommand()
{
    status_t result;
    int32_t cmd;
	// 和binder驱动通讯。
    result = talkWithDriver();
    if (result >= NO_ERROR) {
        size_t IN = mIn.dataAvail();
        if (IN < sizeof(int32_t)) return result;
        // 获取返回值
        cmd = mIn.readInt32();

        pthread_mutex_lock(&mProcess->mThreadCountLock);
        mProcess->mExecutingThreadsCount++;
        if (mProcess->mExecutingThreadsCount >= mProcess->mMaxThreads &&
                mProcess->mStarvationStartTimeMs == 0) {
            mProcess->mStarvationStartTimeMs = uptimeMillis();
        }
        pthread_mutex_unlock(&mProcess->mThreadCountLock);
		// 调用executeCommand(), 根据返回的cmd 执行对应操作
        result = executeCommand(cmd);

        pthread_mutex_lock(&mProcess->mThreadCountLock);
        mProcess->mExecutingThreadsCount--;
        if (mProcess->mExecutingThreadsCount < mProcess->mMaxThreads &&
                mProcess->mStarvationStartTimeMs != 0) {
            int64_t starvationTimeMs = uptimeMillis() - mProcess->mStarvationStartTimeMs;
            if (starvationTimeMs > 100) {
                ALOGE("binder thread pool (%zu threads) starved for %" PRId64 " ms",
                      mProcess->mMaxThreads, starvationTimeMs);
            }
            mProcess->mStarvationStartTimeMs = 0;
        }

        if (mProcess->mWaitingForThreads > 0) {
            pthread_cond_broadcast(&mProcess->mThreadCountDecrement);
        }
        pthread_mutex_unlock(&mProcess->mThreadCountLock);
    }

    return result;
}

```

## MediaPlayerService

这个就是MediaServer提供的服务，它被注册到了ServiceManager中。

