---
layout: post
title: "Binder篇"
date: 2018-04-17
categories: android
---


---

# Binder篇

## 前言

本文中的部分图片和解读说明摘自以下参考资料。

- **<< Android的设计与实现：卷I >> 杨云君　著**
- **<< 深入理解Android: 卷I >>**

* [Android系统开篇][Android系统开篇]
* [为什么Android要采用Binder作为IPC机制][为什么Android要采用Binder作为IPC机制]
* [图解Android - Binder 和 Service][图解Android - Binder 和 Service]

在开始阅读Binder源码实现的过程中可能还会涉及一些Linux或者其他一些概念，我把其中一些概念罗列到了 [Android系统分析预备知识](./Android系统分析预备知识.md) 一文中，有需要时可以查看，其中的知识点也会在后续分析Android系统的过程中慢慢补充。

这里主要通过 ServiceManger来了解Binder机制。因为ServiceManger是Android binder框架中的大管家，所有的service都有它来管理。所以无论是客户端还是服务端都需要和ServiceManager通讯，而且它们实际使用也是binder通讯。

Android中Binder的体系结构：

| C/S体系结构术语   | Android层 | Native层 |                                 |
| ----------------- | --------- | -------- | ------------------------------- |
| 通信协议          | Binder    | Binder   |                                 |
| Client（客户端）  |           |          |                                 |
| Server（服务端）  |           |          | 一个Server 可以包含多个 Service |
| Proxy（服务代理） | BpBinder  | Proxy    |                                 |
| Stub（服务存根）  | BBinder   | Stub     |                                 |
| Service（服务）   |           |          |                                 |
|                   |           |          |                                 |

## 一、 什么是Binder

Android使用的是Linux的进程管理机制，以进程为单位分配虚拟地址空间。为了安全考虑，不同进程之间是相互隔离的，这时候如果需要进行通信，必须使用进程间通讯 。常见的IPC方式以及存在的问题 我罗列在了 [Android系统分析预备知识](./Android系统分析预备知识.md) 一文中。

这些IPC 大多存在要么效率低下，要么不适合封装给上层使用等问题, 所以在Android 中并没有大规模使用，取而代之的使用 **Binder**。

- Binder 基于开源的OpenBinder，**是一种 IPC 通讯机制**。
- Binder是Android对Linux内核层的一个扩展，属于字符设备驱动。主要包括以下操作：
  - `binder_init`：初始化驱动设备。
  - `binder_open`：打开驱动设备。
  - `binder_mmap`：映射内存。
  - `binder_ioctl`：数据操作。
- Binder的C/S框架：它是为了便于上层使用，Android对Binder进行封装后提供的一套框架，Native层 和 Java层各一套。
  - Java层：`Binder(ActivityManagerService.java)`作为Server，`BinderProxy(ActivityManager.java)`作为Client。
  - Native层：`BBinder(MediaPlayService.cpp)`作为Server，`BpBinder(MediaPlay.cpp`作为Client。
- **Binder使用了mmap内存映射，仅需要一次数据拷贝**，仅次于共享内存。

## 二、 ServiceManager

在 Binder 的 C/S 架构中，除了的 Server 和 Client 之外，还有一个额外的组件**ServiceManager**。

ServiceManager 是Android binder框架中的大管家，主要负责管理系统中的各种服务，并提供了**Service注册**和**Service检索**等功能。无论是客户端还是服务端都需要和ServiceManager通讯。

* **ServiceManager 是由 init 启动的进程**：它优先于其他服务启动，相当于C/S体系结构中的Server。
  * 对应可执行程序名为`/system/bin/servicemanager`。
* **ServiceManager 中维护了一个Service信息的列表(`svclist`)**：Service在启动过程中将自身信息注册到ServiceManager中。当Client要使用服务时，只需向ServiceManager提供所需Service的名字便可获取Service信息。
* **ServiceManager 将自身注册为Binder通讯的上下文管理者(context manager)**。
* **ServiceManager  也是使用binder机制和外部交互的**。

|                |                                                              |
| -------------- | ------------------------------------------------------------ |
| ServiceManager | 负责管理系统中的各种Service。                                |
| Server         | 表示服务端，是一个程序，会将Service注册到ServiceManager中，一个Server可以包含多个Service。 |
| Client         | 表示客户端，从ServiceManager中获取Service。接着和 Service所在的Server建立通信。 |
| Binder         | Binder是ServiceManager、Server、Client 之间的通讯机制。      |
| -              |                                                              |
| Service        | 表示具体的某一服务功能。例如 MediaPlayService等              |



![image_1cbjv1brnoa21sc21coacpb1rtrm.png-187.2kB][C/S和ServiceManager]

### ServiceManager中的binder结构

| 类/接口                                                      | 说明                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [IBinder](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/IBinder.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=51) | Binder通讯接口，描述如何进行binder通讯。BBinder和BpBinder 都是它的基类。 |
| [BBinder](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/Binder.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=30) | 用于服务端，继承自IBinder，在binder通讯环节中负责处理Client的请求，它和BpBinder是一一对应的，即BpBinder 只能和对应的BBinder通信。 |
| [BpBinder](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/BpBinder.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=39) | 用于客户端，继承自IBinder，主要负责处理binder通讯相关的逻辑。 |
| -                                                            |                                                              |
| [IInterface](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/IInterface.h;l=27;) | 用于表明是一个 binder 接口。                                 |
| [IServiceManager](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/IServiceManager.h;bpv=0;bpt=1) | 定义了 ServiceManger 的业务接口。例如`addService()`等        |
| -                                                            |                                                              |
| [BnInterface](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/IInterface.h;l=70;) | 是一个类模板，负责将binder通讯接口BBinder和业务接口结合在一起。它必然存在子类 `BnXXX`服务类来作为实现。 |
| [BnServiceManager](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/BnServiceManager.h) | 它是`BnInterface<IServiceManager>`的实现，供服务端实现服务时使用。相当于Java层的 `IXXX.Stub` 类似。 |
| [ServiceManager](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/cmds/servicemanager/ServiceManager.h;l=32) | 继承自BnServiceManager，在这里真正实现了binder通讯相关接口以及具体的服务业务功能接口。实质是一个BBinder。 |
| -                                                            |                                                              |
| [BpInterface](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/IInterface.h;l=84;) | 是一个类模板，客户端访问服务的代理对象接口。它必然存在子类 `BpXXX`代理类来作为实现。它并没有继承BpBinder，而是将BpBinder作为成员变量。 |
| [BpServiceManager](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/BpServiceManager.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=10) | 继承自 `BpInterface<IServiceManager>` ，是客户端访问服务的代理对象，BpBinder是它的一个成员变量。 |

- **Binder通信相关接口**： 提供了binder通信协议的实现，由有`IBinder`, `BBinder`, `BpBinder`三个类组成。
  - **IBinder**：定义了Binder通信的接口。**描述如何服务进行交互**。
  - **BBinder**：它是Service 对应的Binder对象**，描述如何处理Client的请求**。
  - **BpBinder**：它是**Client端访问BBinder的代理对象**，负责打开Binder设备与服务端通信。

- **Binder服务接口**:  `IServiceManager`定义了Client端可以访问Server端提供的哪些服务。
- **Proxy**: 供客户端使用的代理对象，主要包括`BpInterface` 和 `BpServiceManager` 。
  - `mRemote` 成员变量中存储了Client端创建的`BpBinder`对象，可以用它访问服务。
  - 提供了服务的业务访问接口。

- **Stub**: 服务端使用，主要由`BnInterface` 和 `BnServiceManger`组成。

![UML-Binder-Native](./Android%E4%B9%8BBinder%E6%9C%BA%E5%88%B6.assets/UML-Binder-Native-1682328292003-3.jpg)

### servicemanager.rc

> [servicemanager.rc - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/cmds/servicemanager/servicemanager.rc)


```shell
# args[0] = service，按空格分割，依次类推
# 可执行文件 /system/bin/servicemanager
service servicemanager /system/bin/servicemanager
    class core animation	# 类型为core，将由boot Action启动
    user system				# 属于system用户
    group system readproc	# 属于system组
    critical				# critical服务, 异常退出后盖服务需要重启
    file /dev/kmsg w
    
    # servicemanager 重启会导致以下服务重启
    onrestart setprop servicemanager.ready false
    onrestart restart --only-if-running apexd
    onrestart restart audioserver
    onrestart restart gatekeeperd
    onrestart class_restart --only-enabled main
    onrestart class_restart --only-enabled hal
    onrestart class_restart --only-enabled early_hal
    task_profiles ServiceCapacityLow
    shutdown critical
```
## 三、ServiceManager 中的Binder流程

### ServiceManager 程序入口

`main()` 是 ServiceManager 程序入口。

1. 初始化Binder通信环境，打开Binder设备并映射共享内存。
2. 将自身注册为上下文管理者
3. 进入无限循环等待接收并处理IPC通信请求

> [main.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/cmds/servicemanager/main.cpp;l=113;)

```cpp
int main(int argc, char** argv) {
    android::base::InitLogging(argv, android::base::KernelLogger);
	// rc中没有启动参数，所以使用的是 "/dev/binder"
    const char* driver = argc == 2 ? argv[1] : "/dev/binder";
	// 初始化binder
    sp<ProcessState> ps = ProcessState::initWithDriver(driver);
    // 设置最大线程数为0
    ps->setThreadPoolMaxThreadCount(0);
    // 设置策略 FATAL_IF_NOT_ONEWAY
    ps->setCallRestriction(ProcessState::CallRestriction::FATAL_IF_NOT_ONEWAY);
    
	// 创建ServiceManager实例，它是一个BBinder，具体的业务功能和binder通信都由它实现。
    // 这里使用了智能指针 unique_ptr，构造函数中没做什么特别的事情
    sp<ServiceManager> manager = sp<ServiceManager>::make(std::make_unique<Access>());
    // 将自身作为 manager 添加到服务列表中
    if (!manager->addService("manager", manager, false /*allowIsolated*/, IServiceManager::DUMP_FLAG_PRIORITY_DEFAULT).isOk()) {
        LOG(ERROR) << "Could not self register servicemanager";
    }

	// 添加上下文，赋值给了一个全局变量sp<BBinder> the_context_object; 
    // 后续和serviceManger进行binder通讯时会使用到它。
    IPCThreadState::self()->setTheContextObject(manager);
    
    // 将ServiceManager设置为上下文管理者，这里把自己的handle设置为0
    ps->becomeContextManager();
    
    
	// 创建looper
    sp<Looper> looper = Looper::prepare(false /*allowNonCallbacks*/);

    // 注册 BinderCallback
    BinderCallback::setupTo(looper);
    // 注册 ClientCallbackCallback
    ClientCallbackCallback::setupTo(looper, manager);

	// 开启无限循环等待IPC通信数据
    while(true) {
        // 
        looper->pollAll(-1);
    }

    // should not be reached
    return EXIT_FAILURE;
}
```

### binder初始化

1. 打开Binder设备驱动 并获取到 Binder驱动的 `fd`。
2. 通过`mmap()`将 fd 映射到进程的内存空间用于接收IPC通信数据。

#### ProcessState::initWithDriver()

这个函数调用 `init()` 以单例模式构建一个 ProcessState实例，保证当前进程唯一，并初始化了Binder通信环境。

> [ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=86)

```cpp
// driver = "/dev/binder"
sp<ProcessState> ProcessState::initWithDriver(const char* driver)
{
    // init 中以单例模式创建ProcessState实例并初始化binder。
    // 和 ProcessState::self() 的区别是入参不同，此处传入的了具体的 driver，以及requireDefault =true。
    return init(driver, true /*requireDefault*/);
}
```

#### ProcessState::init()

以单例模式 构建ProcessState对象，保证当前的ServiceManger进程只有一个ProcessState实例。主要的逻辑都在构造函数中，内部初始化了Binder通信环境。

>[ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=107)
>
>android 8后供应商进程无法访问 `/dev/binder`，而是应该访问 `/dev/vndbinder`。

```cpp
// Binder线程池最大线程数
#define DEFAULT_MAX_BINDER_THREADS 15
#define DEFAULT_ENABLE_ONEWAY_SPAM_DETECTION 1

// binder驱动地址
#ifdef __ANDROID_VNDK__
const char* kDefaultDriver = "/dev/vndbinder";  // 这个是给供应商使用的
#else
const char* kDefaultDriver = "/dev/binder";
#endif

// 这是一个全局的静态变量，且init使用了单例模式，保证每个进程仅有一个 ProcessState 实例
[[clang::no_destroy]] static sp<ProcessState> gProcess;

/**
 * init() 是单例模式
 * 保证当前进程只有一个ProcessState 实例。
 */
sp<ProcessState> ProcessState::init(const char *driver, bool requireDefault)
{
    [[clang::no_destroy]] static std::once_flag gProcessOnce;
    // 仅执行一次,单例模式
    std::call_once(gProcessOnce, [&](){
		// ...
        int ret = pthread_atfork(ProcessState::onFork, ProcessState::parentPostFork,
                                 ProcessState::childPostFork);
        std::lock_guard<std::mutex> l(gProcessMutex);
        // sp::make,创建了 ProcessState(driver)实例，并将实例sp化
        gProcess = sp<ProcessState>::make(driver);
    });
	
    if (requireDefault) {
        // requireDefault=true时就记录下异常日志
    }
    verifyNotForked(gProcess->mForked);
    return gProcess;
}

```

> 这里介绍一个多种不同的Binder驱动
>
> 简单来说就是 Android 8 之后 供应商进程无法再访问`/dev/binder`这个设备节点，而是提供了 `/dev/hwbinder` 给供应商进程访问，不过提供的是HIDL接口而不是AIDL接口，所以如果想继续使用AIDL，不想进行转换，则应该使用 `/dev/vndbinder`节点。
>
> [使用 Binder IPC  | Android 开源项目  | Android Open Source Project](https://source.android.com/docs/core/architecture/hidl/binder-ipc?hl=zh-cn)
>
> ![image-20230318221353753](./Android%E4%B9%8BBinder%E6%9C%BA%E5%88%B6.assets/image-20230318221353753.png)

#### ProcessState的构造函数

在这里 打开了binder驱动并分配内存，从而和内核中的Binder驱动建立了交互通道。

> 由于进程的地址空间是彼此的隔离的，但是内核空间是可以共享的，因此通过`mmap`在内核中开辟缓冲区来保存进程间通信的数据，以**共享内存的方式实现进程间通信**。

1. 首先通过 `open_drive()` 函数打开Binder设备，并返回了一个Binder驱动的 `fd`。
2. 设备打开成功则 通过`mmap()`系统调用将 fd 映射到进程的地址空间，后续Binder就使用这块内存来共享数据。
3. 设备打开成功则 初始化mDriverFD，记录fd。

[ProcessState.cpp - ProcessState(driver)](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/libs/binder/ProcessState.cpp;l=529;drc=3a7ad36d2815b7b3ecc930c6b94b6be0e62fbce7;bpv=0;bpt=1)

```cpp
// binder驱动大小，不超过1MB，可以看出Binder不支持大数据的传输
#define BINDER_VM_SIZE ((1 * 1024 * 1024) - sysconf(_SC_PAGE_SIZE) * 2)
ProcessState::ProcessState(const char* driver)
      : mDriverName(String8(driver)),
        mDriverFD(-1),
        mVMStart(MAP_FAILED),
        mThreadCountLock(PTHREAD_MUTEX_INITIALIZER),
        mThreadCountDecrement(PTHREAD_COND_INITIALIZER),
        mExecutingThreadsCount(0),
        mWaitingForThreads(0),
        mMaxThreads(DEFAULT_MAX_BINDER_THREADS),
        mCurrentThreads(0),
        mKernelStartedThreads(0),
        mStarvationStartTimeMs(0),
        mForked(false),
        mThreadPoolStarted(false),
        mThreadPoolSeq(1),
        mCallRestriction(CallRestriction::NONE) {
    // 打开binder驱动, 返回的result中其实是一个fd
    base::Result<int> opened = open_driver(driver);

    if (opened.ok()) {
        // mmap the binder, providing a chunk of virtual address space to receive transactions.
        // 分配内存：映射共享内存用于接收IPC通信数据, 申请的内存为 1MB
        mVMStart = mmap(nullptr, BINDER_VM_SIZE, PROT_READ, MAP_PRIVATE | MAP_NORESERVE, opened.value(), 0);
        if (mVMStart == MAP_FAILED) {
            close(opened.value());
            // *sigh*
            opened = base::Error()
                    << "Using " << driver << " failed: unable to mmap transaction memory.";
            mDriverName.clear();
        }
    }
    // 打开成功则 更新mDriverFD 记录fd
    if (opened.ok()) {
        mDriverFD = opened.value();
    }
}
```

#### ProcessState.open_device()

1. 通过系统调用 `open()` 打开binder设备, 返回文件描述符用于调用ioctl指令。会使Binder驱动的`binder_open`函数被调用
2. BINDER_VERSION命令获取Binder协议版本号。
3. BINDER_SET_MAX_THREADS设置当前server线程池上线。

> [ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=496)

```cpp
static base::Result<int> open_driver(const char* driver) {
    // 通过open()系统调用 以读写的方式打开/dev/binder设备节点来用于Binder驱动程序,返回文件描述符
    int fd = open(driver, O_RDWR | O_CLOEXEC);
    if (fd < 0) {
        return base::ErrnoError() << "Opening '" << driver << "' failed";
    }
    int vers = 0;
    // 通过fd 向Binder驱动发送 BINDER_VERSION 命令获取Binder协议版本号,存入&vers
    status_t result = ioctl(fd, BINDER_VERSION, &vers);
    // ...
    //
    // 向Binder驱动发送BINDER_SET_MAX_THREADS命令来设置当前Binder线程池上线。
    // 这线程池就是当前服务支持的客户端最大并发访问数，为15。
    size_t maxThreads = DEFAULT_MAX_BINDER_THREADS;
    result = ioctl(fd, BINDER_SET_MAX_THREADS, &maxThreads);
	// ...
    uint32_t enable = DEFAULT_ENABLE_ONEWAY_SPAM_DETECTION;
    result = ioctl(fd, BINDER_ENABLE_ONEWAY_SPAM_DETECTION, &enable);
    // ...
    return fd;
}
```

### 构建ServiceManager实例

ServiceManager继承了BnServiceManager，实际是一个BBinder，**实现了binder通讯相关接口以及具体的服务业务功能接口**。

#### ServiceManager

> [ServiceManager.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/cmds/servicemanager/ServiceManager.cpp;l=237;bpv=0;bpt=1)
>
> [ServiceManager.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/cmds/servicemanager/ServiceManager.h;l=32;)

```cpp
 // 构造函数中没做什么特别的事情。赋值 mAccess
ServiceManager::ServiceManager(std::unique_ptr<Access>&& access) : mAccess(std::move(access)) {

}
// BnServiceManager 实际继承自 BBinder
// IBinder::DeathRecipient 也是一个重要的接口，它会在BnXXX 死亡时回调
class ServiceManager : public os::BnServiceManager, public IBinder::DeathRecipient {
    
}
```

#### BnServiceManager

这个类和Java层的 IxxService.Stub 类似，**将通讯和业务结合，定义了binder通讯接口 和 业务接口**。

它的实现在 `IServiceManager.cpp` 中，是代理模式，

> [BnServiceManager.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/BnServiceManager.h)
>
> [BnServiceManager实现](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/IServiceManager.cpp;l=569;)

```cpp
namespace android {
namespace os {
// BnInterface 继承自BBinder
class BnServiceManager : public ::android::BnInterface<IServiceManager> {
public:
  static constexpr uint32_t TRANSACTION_getService = ::android::IBinder::FIRST_CALL_TRANSACTION + 0;
  static constexpr uint32_t TRANSACTION_checkService = ::android::IBinder::FIRST_CALL_TRANSACTION + 1;
  static constexpr uint32_t TRANSACTION_addService = ::android::IBinder::FIRST_CALL_TRANSACTION + 2;
  // .... 接口对应的索引
  explicit BnServiceManager();
  // onTransact()
  ::android::status_t onTransact(uint32_t _aidl_code, const ::android::Parcel& _aidl_data, ::android::Parcel* _aidl_reply, uint32_t _aidl_flags) override;
};  // class BnServiceManager
}  // namespace os
}  // namespace android
```

### 注册自身作为上下文管理者

打开Binder设备并映射内存后， servicemanage会将自身注册为Binder通信的上下文管理者。

#### ProcessState::becomeContextManager()

调用`ioctl()`，向Binder设备发送 `BINDER_SET_CONTEXT_MGR_EXT或者BINDER_SET_CONTEXT_MGR`

> [ProcessState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/ProcessState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=210)

```cpp
bool ProcessState::becomeContextManager()
{
    AutoMutex _l(mLock);

    // flat_binder_object 基本都没赋值，内部的handle = 0
    flat_binder_object obj {
        .flags = FLAT_BINDER_FLAG_TXN_SECURITY_CTX,
    };

    // 发送 BINDER_SET_CONTEXT_MGR_EXT 请求
    int result = ioctl(mDriverFD, BINDER_SET_CONTEXT_MGR_EXT, &obj);

    // fallback to original method
    if (result != 0) {
        android_errorWriteLog(0x534e4554, "121035042");
		// 失败调用原先的方法,发送 BINDER_SET_CONTEXT_MGR
        int unused = 0; // 0
        result = ioctl(mDriverFD, BINDER_SET_CONTEXT_MGR, &unused);
    }

    if (result == -1) {
        ALOGE("Binder ioctl to become context manager failed: %s\n", strerror(errno));
    }

    return result == 0;
}

```

### 创建Looper

Native层的Looper 和Java层的Looper逻辑是类似的。作用也是类似，内部通过 `epoll` 机制来处理消息，具体分析可以看[Android消息机制之Native篇](./Android消息机制之Native篇) 一文。

```cpp
sp<Looper> looper = Looper::prepare(false /*allowNonCallbacks*/);
```



### 注册BinderCallback

#### BinderCallback

> [main.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/cmds/servicemanager/main.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=39)

```cpp
class BinderCallback : public LooperCallback {
public:
    static sp<BinderCallback> setupTo(const sp<Looper>& looper) {
        sp<BinderCallback> cb = sp<BinderCallback>::make();

        int binder_fd = -1;
        // 内部会建之前创建的Binder fd 赋值给 binder_fd
        // 
        IPCThreadState::self()->setupPolling(&binder_fd);
		
        // 将binder_fd 添加到 looper中，当fd中有数据写入时会回调给cb。
        int ret = looper->addFd(binder_fd,
                                Looper::POLL_CALLBACK,
                                Looper::EVENT_INPUT,
                                cb,
                                nullptr /*data*/);
        return cb;
    }

    // 处理接收到的Binder消息
    int handleEvent(int /* fd */, int /* events */, void* /* data */) override {
        IPCThreadState::self()->handlePolledCommands();
        return 1;  // Continue receiving callbacks.
    }
};

```

#### IPCThreadState::setupPolling()

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=769)

```cpp
status_t IPCThreadState::setupPolling(int* fd)
{
    if (mProcess->mDriverFD < 0) {	
        return -EBADF;
    }
	// 标记binder 进入 looper状态。
    mOut.writeInt32(BC_ENTER_LOOPER);
    // 这里内部会调用 talkWithDriver()和binder驱动进行通信。
    flushCommands();
    // 赋值 mDriverFD
    *fd = mProcess->mDriverFD;
    pthread_mutex_lock(&mProcess->mThreadCountLock);
    mProcess->mCurrentThreads++;
    pthread_mutex_unlock(&mProcess->mThreadCountLock);
    return 0;
}
```

#### IPCThreadState::flushCommands()

将请求发送给binder驱动。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;l=586;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176)

```cpp
void IPCThreadState::flushCommands()
{
    if (mProcess->mDriverFD < 0)
        return;
    // 和binder驱动通信，这个后面再分析,false表示不接收数据仅发送
    talkWithDriver(false);
    // flush 可能会导致 BC_RELEASE/BC_DECREFS 会写入到mOut中，所以在指向一次。
    if (mOut.dataSize() > 0) {
        talkWithDriver(false);
    }
    if (mOut.dataSize() > 0) {
        ALOGW("mOut.dataSize() > 0 after flushCommands()");
    }
}

```

####  Looper::addFd()

将binder fd添加到了 Looper中，并注册epoll 事件，会被保存在 `Looper.mRequests` 中。

> [Looper.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/Looper.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=440)

```cpp
int Looper::addFd(int fd, int ident, int events, const sp<LooperCallback>& callback, void* data) {
    if (!callback.get()) {
        if (! mAllowNonCallbacks) {
            ALOGE("Invalid attempt to set NULL callback but not allowed for this looper.");
            return -1;
        }

        if (ident < 0) {
            ALOGE("Invalid attempt to set NULL callback with ident < 0.");
            return -1;
        }
    } else {
        ident = POLL_CALLBACK;
    }

    { // acquire lock
        AutoMutex _l(mLock);
        if (mNextRequestSeq == WAKE_EVENT_FD_SEQ) mNextRequestSeq++;
        const SequenceNumber seq = mNextRequestSeq++;

        Request request;
        // binder的fd
        request.fd = fd;
        request.ident = ident;
        request.events = events;
        request.callback = callback;
        request.data = data;
		// 创建一个epoll事件
        epoll_event eventItem = createEpollEvent(request.getEpollEvents(), seq);
        // 查询fd是否已经存在
        auto seq_it = mSequenceNumberByFd.find(fd);
        if (seq_it == mSequenceNumberByFd.end()) {
            // 不存在, fd注册监听事件
            int epollResult = epoll_ctl(mEpollFd.get(), EPOLL_CTL_ADD, fd, &eventItem);
            if (epollResult < 0) {
                ALOGE("Error adding epoll events for fd %d: %s", fd, strerror(errno));
                return -1;
            }
            // 将 request 保存到了 mRequests
            mRequests.emplace(seq, request);
            mSequenceNumberByFd.emplace(fd, seq);
        } else { // 存在, fd注册监听事件
            int epollResult = epoll_ctl(mEpollFd.get(), EPOLL_CTL_MOD, fd, &eventItem);
            if (epollResult < 0) {
                if (errno == ENOENT) {
                    epollResult = epoll_ctl(mEpollFd.get(), EPOLL_CTL_ADD, fd, &eventItem);
                    if (epollResult < 0) {
                        ALOGE("Error modifying or adding epoll events for fd %d: %s",
                                fd, strerror(errno));
                        return -1;
                    }
                    // 唤醒并重新创建epoll
                    scheduleEpollRebuildLocked();
                } else {
                    ALOGE("Error modifying epoll events for fd %d: %s", fd, strerror(errno));
                    return -1;
                }
            }
            const SequenceNumber oldSeq = seq_it->second;
            mRequests.erase(oldSeq);
            // 将 request 保存到了 mRequests
            mRequests.emplace(seq, request);
            seq_it->second = seq;
        }
    } // release lock
    return 1;
}
```



### 开启Looper接收并处理消息

这里开启了looper循环，通过 epoll 机制处理消息。

> [main.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/cmds/servicemanager/main.cpp;l=147)

```cpp
// 开启无限循环等待IPC通信数据
while(true) {
    // 拉取消息
    looper->pollAll(-1);
}
```

#### Looper::pollAll()

内部循环调用了 `pollOnce()`，它会在有请求消息时被唤醒处理消息。

* Callback消息：会回调 `handleEvent()` 来处理。Binder是通过注册callback的方式来处理消息。
* Message消息：会回调 `handleMessage()`来处理。

Looper消息机制相关内容可以看[Android消息机制之Native篇](./Android消息机制之Native篇) 一文。

> [Looper.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/include/utils/Looper.h;l=280;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176)

```cpp
inline int pollAll(int timeoutMillis) {
    return pollAll(timeoutMillis, nullptr, nullptr, nullptr);
}

int Looper::pollAll(int timeoutMillis, int* outFd, int* outEvents, void** outData) {
    if (timeoutMillis <= 0) {
        int result;
        do {
            // poll 机制，有消息时会被唤醒，并处理消息
            result = pollOnce(timeoutMillis, outFd, outEvents, outData);
        } while (result == POLL_CALLBACK);
        return result;
    } else {
        nsecs_t endTime = systemTime(SYSTEM_TIME_MONOTONIC)
                + milliseconds_to_nanoseconds(timeoutMillis);

        for (;;) {
            int result = pollOnce(timeoutMillis, outFd, outEvents, outData);
            if (result != POLL_CALLBACK) {
                return result;
            }

            nsecs_t now = systemTime(SYSTEM_TIME_MONOTONIC);
            timeoutMillis = toMillisecondTimeoutDelay(now, endTime);
            if (timeoutMillis == 0) {
                return POLL_TIMEOUT;
            }
        }
    }
}


int Looper::pollOnce(int timeoutMillis, int* outFd, int* outEvents, void** outData) {
    for (;;) {
		// 调用 pollInner(), 内部会创建Response 并添加到 mResponses中
        result = pollInner(timeoutMillis);
    }
}

int Looper::pollInner(int timeoutMillis) {
    // Handle all events.
    // 处理所有事件
    for (int i = 0; i < eventCount; i++) {
        const SequenceNumber seq = eventItems[i].data.u64;
        uint32_t epollEvents = eventItems[i].events;
        if (seq == WAKE_EVENT_FD_SEQ) {
            if (epollEvents & EPOLLIN) {
                // 唤醒epoll
                awoken();
            } else {
                ALOGW("Ignoring unexpected epoll events 0x%x on wake event fd.", epollEvents);
            }
        } else {
            // 监听到其他文件描述符所发出的请求
            const auto& request_it = mRequests.find(seq);
            if (request_it != mRequests.end()) {
                const auto& request = request_it->second;
                int events = 0;
                if (epollEvents & EPOLLIN) events |= EVENT_INPUT;
                if (epollEvents & EPOLLOUT) events |= EVENT_OUTPUT;
                if (epollEvents & EPOLLERR) events |= EVENT_ERROR;
                if (epollEvents & EPOLLHUP) events |= EVENT_HANGUP;
                // 先不处理, 放入到mResponse中
                mResponses.push({.seq = seq, .events = events, .request = request});
            } else {
                ALOGW("Ignoring unexpected epoll events 0x%x for sequence number %" PRIu64
                      " that is no longer registered.",
                      epollEvents, seq);
            }
        }
    }
Done: ;
    // 处理 callback
    for (size_t i = 0; i < mResponses.size(); i++) {
        Response& response = mResponses.editItemAt(i);
        if (response.request.ident == POLL_CALLBACK) {
            int fd = response.request.fd;
            int events = response.events;
            void* data = response.request.data;
			// 回调 callback.handleEvent()
            int callbackResult = response.request.callback->handleEvent(fd, events, data);
            if (callbackResult == 0) {
                AutoMutex _l(mLock);
                removeSequenceNumberLocked(response.seq);
            }
            response.request.callback.clear();
            result = POLL_CALLBACK;
        }
    }
    return result;
}
```

#### BinderCallback.handleEvent()

处理接收到的Binder消息

> [main.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/cmds/servicemanager/main.cpp;l=58;)

```cpp
// 处理接收到的Binder消息
int handleEvent(int /* fd */, int /* events */, void* /* data */) override {
    IPCThreadState::self()->handlePolledCommands();
    return 1;  // Continue receiving callbacks.
}
```

#### IPCThreadState::self()

IPCThreadState 负责处理IPC通信相关的逻辑，即Binder机制的通信部分是在这里实现的，在这里会和binder驱动进行通信。每一个线程都一个独立的IPCThreadState实例。

> IPCThreadState对象的管理 涉及到了 TLS：Thread Local Storage（线程本地存储空间）这一概念，它主要是用于 存储线程私有的变量，每个线程都有这样一块私有空间。`IPCThreadState` 就存储在了 TLS中。 关于TLS具体的介绍放在了 [Android系统分析预备知识](./Android系统分析预备知识.md)中。

`self()`是单例模式

* pthread_getspecific()：从TLS 中根据 key查找对应的数据。
* pthread_setspecific(：将对应数据以 kv 格式保存到 TLS中。

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

#### IPCThreadState的构造函数

在构造函数中通过 `pthread_setspecific()` 将自身保存到 TLS中

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=972)

```cpp
IPCThreadState::IPCThreadState()
      : mProcess(ProcessState::self()),
        mServingStackPointer(nullptr),
        mServingStackPointerGuard(nullptr),
        mWorkSource(kUnsetWorkSource),
        mPropagateWorkSource(false),
        mIsLooper(false),
        mIsFlushing(false),
        mStrictModePolicy(0),
        mLastTransactionBinderFlags(0),
        mCallRestriction(mProcess->mCallRestriction) {
    // 将自己设置到 TLS(线程本地存储) 中去。
    pthread_setspecific(gTLS, this);
    clearCaller();
    mHasExplicitIdentity = false;
	// mIn是一个Parcel，用于存储 来自Binder的输入数据
    mIn.setDataCapacity(256);
    // mOut也是一个Parcel，用于存储 发送到Binder的输出数据
    mOut.setDataCapacity(256);
}
```



#### IPCThreadState::handlePolledCommands()

处理接收到请求。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=784)

```cpp
status_t IPCThreadState::handlePolledCommands()
{
    status_t result;

    do {
        // 开启循环不断处理消息，直到mIn中没有数据。
        result = getAndExecuteCommand();
    } while (mIn.dataPosition() < mIn.dataSize());

    processPendingDerefs();
    flushCommands();
    return result;
}
```

#### IPCThreadState::getAndExecuteCommand()

这里主要就是处理binder请求，调用 `talkWithDriver()` 向binder驱动读/写数据，最后调用`executeCommand()`来处理返回结果。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=627)

```cpp
status_t IPCThreadState::getAndExecuteCommand()
{
    status_t result;
    int32_t cmd;
	// 和binder驱动通讯。即读也写
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
		// 执行返回的cmd
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

#### IPCThreadState::executeCommand()

这里最终会通过 `BBinder.transact(code)` 来处理对应请求。code是定义在 对应服务(例如`BnServiceManager`)中的接口id。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1274)

```cpp
// 一个全局的 BBinder，其实就是servicemanager
sp<BBinder> the_context_object;
// 这个函数会在 serviceManager 启动时被调用
void IPCThreadState::setTheContextObject(const sp<BBinder>& obj)
{
    the_context_object = obj;
}
// 解析返回数据时的结果体
struct binder_transaction_data_secctx {
  struct binder_transaction_data transaction_data;
  binder_uintptr_t secctx;
};
struct binder_transaction_data {
  union {
    __u32 handle;
    binder_uintptr_t ptr;
  } target;
  binder_uintptr_t cookie;
  __u32 code;
  __u32 flags;
  __kernel_pid_t sender_pid;
  __kernel_uid32_t sender_euid;
  binder_size_t data_size;
  binder_size_t offsets_size;
  union {
    struct {
      binder_uintptr_t buffer;
      binder_uintptr_t offsets;
    } ptr;
    __u8 buf[8];
  } data;
};

status_t IPCThreadState::executeCommand(int32_t cmd)
{
    BBinder* obj;
    RefBase::weakref_type* refs;
    status_t result = NO_ERROR;

    switch ((uint32_t)cmd) {
    case BR_ERROR:
        result = mIn.readInt32();
        break;

    case BR_OK:
        break;
    // ...
    case BR_TRANSACTION_SEC_CTX:
    case BR_TRANSACTION: // 对应 BC_TRANSACTION。注册和检索service就会返回这个，此处是在对应的服务进程
        {
            binder_transaction_data_secctx tr_secctx;
            binder_transaction_data& tr = tr_secctx.transaction_data;
			
            // 从mIn 读取 binder_transaction_data
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

            const void* origServingStackPointer = mServingStackPointer;
            mServingStackPointer = __builtin_frame_address(0);

            const pid_t origPid = mCallingPid;
            const char* origSid = mCallingSid;
            const uid_t origUid = mCallingUid;
            const bool origHasExplicitIdentity = mHasExplicitIdentity;
            const int32_t origStrictModePolicy = mStrictModePolicy;
            const int32_t origTransactionBinderFlags = mLastTransactionBinderFlags;
            const int32_t origWorkSource = mWorkSource;
            const bool origPropagateWorkSet = mPropagateWorkSource;
            clearCallingWorkSource();
            clearPropagateWorkSource();

            mCallingPid = tr.sender_pid;
            mCallingSid = reinterpret_cast<const char*>(tr_secctx.secctx);
            mCallingUid = tr.sender_euid;
            mHasExplicitIdentity = false;
            mLastTransactionBinderFlags = tr.flags;

            Parcel reply;
            status_t error;
            
            if (tr.target.ptr) { // ptr != 0
                // 当前只有弱引用，使用前先通过wp生成一个sp
                if (reinterpret_cast<RefBase::weakref_type*>(tr.target.ptr)->attemptIncStrong(this)) {
                    // 调用BBinder的 transact()
                    error = reinterpret_cast<BBinder*>(tr.cookie)->transact(tr.code, buffer,
                            &reply, tr.flags);
                    reinterpret_cast<BBinder*>(tr.cookie)->decStrong(this);
                } else {
                    error = UNKNOWN_TRANSACTION;
                }
            } else { // ptr = 0，这里是处理ServiceManager的。
                // the_context_object 也是一个 BBinder
                // 内部会调用 ServiceManager.onTransact()
                // 若由需要回复的内容会保存在 reply 中。
                error = the_context_object->transact(tr.code, buffer, &reply, tr.flags);
            }

            if ((tr.flags & TF_ONE_WAY) == 0) {
                if (error < NO_ERROR) reply.setError(error);
                buffer.setDataSize(0);
                constexpr uint32_t kForwardReplyFlags = TF_CLEAR_BUF;
                sendReply(reply, (tr.flags & kForwardReplyFlags));
            } else {
                if (error != OK) {
                    //
                }
            }

            mServingStackPointer = origServingStackPointer;
            mCallingPid = origPid;
            mCallingSid = origSid;
            mCallingUid = origUid;
            mHasExplicitIdentity = origHasExplicitIdentity;
            mStrictModePolicy = origStrictModePolicy;
            mLastTransactionBinderFlags = origTransactionBinderFlags;
            mWorkSource = origWorkSource;
            mPropagateWorkSource = origPropagateWorkSet;
        }
        break;

    case BR_DEAD_BINDER:
        {
            // 收到Binder驱动发来的service死掉的消息，只有Bp端能收到
            BpBinder *proxy = (BpBinder*)mIn.readPointer();
            // 发送讣告，会回调给 DeathRecipient
            proxy->sendObituary();
            mOut.writeInt32(BC_DEAD_BINDER_DONE);
            mOut.writePointer((uintptr_t)proxy);
        } break;

    case BR_CLEAR_DEATH_NOTIFICATION_DONE:
        {
            BpBinder *proxy = (BpBinder*)mIn.readPointer();
            proxy->getWeakRefs()->decWeak(proxy);
        } break;

    case BR_FINISHED:
        result = TIMED_OUT;
        break;

    case BR_NOOP:
        break;

    case BR_SPAWN_LOOPER:
        // 这里将收到来自驱动的指令，表示需要创建一个新线程，用于和Binder通信。
        // isMain=false， 表示不是主线程。
        mProcess->spawnPooledThread(false);
        break;

    default:
        ALOGE("*** BAD COMMAND %d received from Binder driver\n", cmd);
        result = UNKNOWN_ERROR;
        break;
    }
    if (result != NO_ERROR) {
        mLastError = result;
    }

    return result;
}
```

#### BnServiceManager::onTransact()

在 `BBinder.transact()` 会调用这个函数，这里就是最终处理具体业务的地方，会调用具体的业务接口，例如 `addService()`、`getService()`等等。

> [IServiceManager.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/IServiceManager.cpp;l=574)

```cpp
::android::status_t BnServiceManager::onTransact(uint32_t _aidl_code, const ::android::Parcel& _aidl_data, ::android::Parcel* _aidl_reply, uint32_t _aidl_flags) {
  ::android::status_t _aidl_ret_status = ::android::OK;
  switch (_aidl_code) {
  case BnServiceManager::TRANSACTION_getService: // getService
  {
    ::std::string in_name;
    ::android::sp<::android::IBinder> _aidl_return;
    if (!(_aidl_data.checkInterface(this))) {
      _aidl_ret_status = ::android::BAD_TYPE;
      break;
    }
    // 读取数据并校验
    // getService()
    ::android::binder::Status _aidl_status(getService(in_name, &_aidl_return));
    _aidl_ret_status = _aidl_status.writeToParcel(_aidl_reply);
    // ... 校验
  }
  break;
  case BnServiceManager::TRANSACTION_checkService: // checkService
  {
    ::std::string in_name;
    ::android::sp<::android::IBinder> _aidl_return;
    if (!(_aidl_data.checkInterface(this))) {
      _aidl_ret_status = ::android::BAD_TYPE;
      break;
    }
    // 读取数据并校验
    // checkService
    ::android::binder::Status _aidl_status(checkService(in_name, &_aidl_return));
    _aidl_ret_status = _aidl_status.writeToParcel(_aidl_reply);
    // ... 校验
  }
  break;
  case BnServiceManager::TRANSACTION_addService: // addService
  {
    ::std::string in_name;
    ::android::sp<::android::IBinder> in_service;
    bool in_allowIsolated;
    int32_t in_dumpPriority;
    if (!(_aidl_data.checkInterface(this))) {
      _aidl_ret_status = ::android::BAD_TYPE;
      break;
    }
  	// 数据的读取和校验流程
    _aidl_ret_status = _aidl_data.readUtf8FromUtf16(&in_name);
    // ...
    // 调用 addService()
    ::android::binder::Status _aidl_status(addService(in_name, in_service, in_allowIsolated, in_dumpPriority));
    // 写回执
    _aidl_ret_status = _aidl_status.writeToParcel(_aidl_reply);
    // 校验
    if (((_aidl_ret_status) != (::android::OK))) {
      break;
    }
    if (!_aidl_status.isOk()) {
      break;
    }
  }
  break;
  // ... 一系列函数id的 case 处理
  break;
  default:
  {// 默认，这里是binder通讯相关的
    _aidl_ret_status = ::android::BBinder::onTransact(_aidl_code, _aidl_data, _aidl_reply, _aidl_flags);
  }
  break;
  }
  return _aidl_ret_status;
}
```

### 发送回执

#### IPCThreadState::sendReply()

这里主要调用了2个函数：

* `writeTransactionData()`：这个函数主要是将请求信息写入到 mOut中。
* `waitForResponse()`：这里才是和Binder驱动具体通讯的地方，内部调用了 `talkWithDriver()`

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=994)

```cpp
status_t IPCThreadState::sendReply(const Parcel& reply, uint32_t flags)
{
    status_t err;
    status_t statusBuffer;
    // cmd = BC_REPLY
    // handle = -1,
    // code = 0,
    // data = replay
    err = writeTransactionData(BC_REPLY, flags, -1, 0, reply, &statusBuffer);
    if (err < NO_ERROR) return err;
	// 
    return waitForResponse(nullptr, nullptr);
}
```

#### IPCThreadState::writeTransactionData()

主要是将请求信息写入到 mOut中。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1231)

```cpp
status_t IPCThreadState::writeTransactionData(int32_t cmd, uint32_t binderFlags,
    int32_t handle, uint32_t code, const Parcel& data, status_t* statusBuffer)
{
	// 发送数据的结构体
    binder_transaction_data tr;
	// ptr=0
    // 若是发送给ServiceManger的则handle=0，
    tr.target.ptr = 0; /* Don't pass uninitialized stack data to a remote process */
    tr.target.handle = handle;
    tr.code = code;
    tr.flags = binderFlags;
    tr.cookie = 0;
    tr.sender_pid = 0;
    tr.sender_euid = 0;

    const status_t err = data.errorCheck();
    if (err == NO_ERROR) {
        tr.data_size = data.ipcDataSize();
        tr.data.ptr.buffer = data.ipcData();
        tr.offsets_size = data.ipcObjectsCount()*sizeof(binder_size_t);
        tr.data.ptr.offsets = data.ipcObjects();
    } else if (statusBuffer) {
        tr.flags |= TF_STATUS_CODE;
        *statusBuffer = err;
        tr.data_size = sizeof(status_t);
        tr.data.ptr.buffer = reinterpret_cast<uintptr_t>(statusBuffer);
        tr.offsets_size = 0;
        tr.data.ptr.offsets = 0;
    } else {
        return (mLastError = err);
    }
	// 写入指令
    mOut.writeInt32(cmd);
    // 写入数据
    mOut.write(&tr, sizeof(tr));
    return NO_ERROR;
}
```

#### IPCThreadState::waitForResponse()

内部调用了 `talkWithDriver()`和Binder驱动通讯并获取返回。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1004)

```cpp
status_t IPCThreadState::waitForResponse(Parcel *reply, status_t *acquireResult)
{
    uint32_t cmd;
    int32_t err;

    while (1) {
        // 和Binder驱动通讯
        if ((err=talkWithDriver()) < NO_ERROR) break;
        err = mIn.errorCheck();
        if (err < NO_ERROR) break;
        // dataAvail == 0，表示由于驱动的数据未读完，所以暂时没有发送新的请求，继续循环尝试发送。
        if (mIn.dataAvail() == 0) continue;
		// 从 mIn中读取binder驱动的返回结果
        cmd = (uint32_t)mIn.readInt32();
		// 这里就是根据不同的返回值做不同的处理
        switch (cmd) {
        case BR_ONEWAY_SPAM_SUSPECT:
            ALOGE("Process seems to be sending too many oneway calls.");
            CallStack::logStack("oneway spamming", CallStack::getCurrent().get(),
                    ANDROID_LOG_ERROR);
            [[fallthrough]];
        case BR_TRANSACTION_COMPLETE:
            if (!reply && !acquireResult) goto finish;
            break;

        case BR_TRANSACTION_PENDING_FROZEN:
            ALOGW("Sending oneway calls to frozen process.");
            goto finish;

        case BR_DEAD_REPLY:
            err = DEAD_OBJECT;
            goto finish;

        case BR_FAILED_REPLY:
            err = FAILED_TRANSACTION;
            goto finish;

        case BR_FROZEN_REPLY:
            err = FAILED_TRANSACTION;
            goto finish;

        case BR_ACQUIRE_RESULT:
            {
                ALOG_ASSERT(acquireResult != NULL, "Unexpected brACQUIRE_RESULT");
                const int32_t result = mIn.readInt32();
                if (!acquireResult) continue;
                *acquireResult = result ? NO_ERROR : INVALID_OPERATION;
            }
            goto finish;

        case BR_REPLY:
            {
                binder_transaction_data tr;
                err = mIn.read(&tr, sizeof(tr));
                ALOG_ASSERT(err == NO_ERROR, "Not enough command data for brREPLY");
                if (err != NO_ERROR) goto finish;

                if (reply) {
                    if ((tr.flags & TF_STATUS_CODE) == 0) {
                        reply->ipcSetDataReference(
                            reinterpret_cast<const uint8_t*>(tr.data.ptr.buffer),
                            tr.data_size,
                            reinterpret_cast<const binder_size_t*>(tr.data.ptr.offsets),
                            tr.offsets_size/sizeof(binder_size_t),
                            freeBuffer);
                    } else {
                        err = *reinterpret_cast<const status_t*>(tr.data.ptr.buffer);
                        freeBuffer(reinterpret_cast<const uint8_t*>(tr.data.ptr.buffer),
                                   tr.data_size,
                                   reinterpret_cast<const binder_size_t*>(tr.data.ptr.offsets),
                                   tr.offsets_size / sizeof(binder_size_t));
                    }
                } else {
                    freeBuffer(reinterpret_cast<const uint8_t*>(tr.data.ptr.buffer), tr.data_size,
                               reinterpret_cast<const binder_size_t*>(tr.data.ptr.offsets),
                               tr.offsets_size / sizeof(binder_size_t));
                    continue;
                }
            }
            goto finish;

        default:
            // 其他的处理方式，内部还包含了很多其他指令
            err = executeCommand(cmd);
            if (err != NO_ERROR) goto finish;
            break;
        }
    }

finish:
    if (err != NO_ERROR) {
        if (acquireResult) *acquireResult = err;
        if (reply) reply->setError(err);
        mLastError = err;
        logExtendedError();
    }

    return err;
}
```

### 和Binder驱动通讯

#### IPCThreadState::talkWithDriver()

通过 `ioctl()` 来 读/写 binder驱动中的数据。

这里会向binder驱动发送BINDER_WRITE_READ 这个一级指令。binder驱动会根据 `write_size`, `read_size`的值来判断是读取数据还是写入数据。

* write_size > 0：写入数据。
* read_size > 0：读取数据。

> [IPCThreadState.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/IPCThreadState.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1108)
>
> BinderCallback接收请求时：doReceive = false
>
> 发送binder消息时：doReceive=true

```cpp
// doReceive 默认是 true，表示接收数据，false 表示不需要接收返回的数据仅发送数据。
status_t IPCThreadState::talkWithDriver(bool doReceive)
{
    if (mProcess->mDriverFD < 0) {
        return -EBADF;
    }
	// binder_write_read 是用来与binder设备交换数据的结构
    binder_write_read bwr;

    // needRead = true 表示，当前mIn缓冲区已经无数据，可以继续发送指令并读取返回
    // 否则需要先等读取完毕
    const bool needRead = mIn.dataPosition() >= mIn.dataSize();
    // 读取完毕或不需要接收数据则 outAvail = mOut.dataSize()
    // 否则，继续处理 mIn中的未读完数据，此次不写数据，outAvail = 0
    const size_t outAvail = (!doReceive || needRead) ? mOut.dataSize() : 0;
	// 需要写入outAvail大小的数据，数据在mOut.data()中。
    // 不需要写则 write_size = 0
    bwr.write_size = outAvail;
    bwr.write_buffer = (uintptr_t)mOut.data();
	
    if (doReceive && needRead) {
        // 需要写入 mIn.dataCapacity()大小的数据，数据在 mIn.data()中。
        bwr.read_size = mIn.dataCapacity();
        bwr.read_buffer = (uintptr_t)mIn.data();
    } else { // 不需要读则 read_size = 0。
        bwr.read_size = 0;
        bwr.read_buffer = 0;
    }

    // Return immediately if there is nothing to do.
    if ((bwr.write_size == 0) && (bwr.read_size == 0)) return NO_ERROR;
	//
    bwr.write_consumed = 0;
    bwr.read_consumed = 0;
    status_t err;
    do {
        
#if defined(__ANDROID__)
        // 通过 ioctl()来和binder驱动进行通信，这里发送的是BINDER_WRITE_READ指令。
        // 内部会根据 write_size, read_size的值来判断是读取数据还是写入数据。
        if (ioctl(mProcess->mDriverFD, BINDER_WRITE_READ, &bwr) >= 0)
            err = NO_ERROR;
        else
            err = -errno;
#else
        err = INVALID_OPERATION;
#endif
        if (mProcess->mDriverFD < 0) {
            err = -EBADF;
        }
    } while (err == -EINTR);
	
    if (err >= NO_ERROR) {
        // 执行 成功
        // 表示 Binder驱动中 处理 write_consumed大小的写入数据。
        if (bwr.write_consumed > 0) {
            if (bwr.write_consumed < mOut.dataSize())
                // 驱动未消费完
                LOG_ALWAYS_FATAL("Driver did not consume write buffer. "
                                 "err: %s consumed: %zu of %zu",
                                 statusToString(err).c_str(),
                                 (size_t)bwr.write_consumed,
                                 mOut.dataSize());
            else {
                mOut.setDataSize(0);
                processPostWriteDerefs();
            }
        }
        // 表示从binder驱动返回了 read_consumed 大小的数据
        if (bwr.read_consumed > 0) {
            mIn.setDataSize(bwr.read_consumed);
            mIn.setDataPosition(0);
        }
        return NO_ERROR;
    }
    return err;
}
```




## 三、Binder驱动层（选读）

在上面分析ServiceManager的过程中，我们已经了解到了 binder通讯的整体流程，大致概况为以下

* 通过 `open()` 系统调用 打开binder驱动，并获取到驱动返回的fd。
* 通过 `mmap()` 将fd映射到进程空间中。

* 最终通过调用 `ioctl()` 来和binder驱动进行通讯。

而`open()` 和 `ioctl()` 分别就是对应了 binder驱动程序中的  `binder_open()`、`binder_ioctl()`这两个函数。


### 2.1 一些结构体

```c
struct binder_object
{
    uint32_t type;
    uint32_t flags;
    void *pointer;
    void *cookie;
};

struct binder_txn
{
    void *target;
    void *cookie;
    uint32_t code;
    uint32_t flags;

    uint32_t sender_pid;
    uint32_t sender_euid;

    uint32_t data_size;
    uint32_t offs_size;
    void *data;
    void *offs;
};

struct binder_io
{
    char *data;            /* pointer to read/write from */
    uint32_t *offs;        /* array of offsets */
    uint32_t data_avail;   /* bytes available in data buffer */
    uint32_t offs_avail;   /* entries available in offsets array */

    char *data0;           /* start of data buffer */
    uint32_t *offs0;       /* start of offsets buffer */
    uint32_t flags;
    uint32_t unused;
};

/**
 * 记录了打开Binder设备的 进程所对应的Binder通信信息
 */
struct binder_proc {
	struct hlist_node proc_node;
	struct rb_root threads;
	struct rb_root nodes;
	struct rb_root refs_by_desc;
	struct rb_root refs_by_node;
	int pid;
	struct vm_area_struct *vma;
	struct mm_struct *vma_vm_mm;
	struct task_struct *tsk;
	struct files_struct *files;
	struct hlist_node deferred_work_node;
	int deferred_work;
	void *buffer;
	ptrdiff_t user_buffer_offset;

	struct list_head buffers;
	struct rb_root free_buffers;
	struct rb_root allocated_buffers;
	size_t free_async_space;

	struct page **pages;
	size_t buffer_size;
	uint32_t buffer_free;
	struct list_head todo;
	wait_queue_head_t wait;
	struct binder_stats stats;
	struct list_head delivered_death;
	int max_threads;
	int requested_threads;
	int requested_threads_started;
	int ready_threads;
	long default_priority;
	struct dentry *debugfs_entry;
};
```

### 2.2 关键api

#### 2.2.1 binder_open

**struct file**是字符设备驱动相关重要结构。 代表一个打开的文件描述符，它不是专门给驱动程序使用的，系统中每一个打开的文件在内核中都有一个关联的 struct file。 它由内核在 open时创建，并传递给在文件上操作的任何函数。
**private_data** 是用来保存自定义设备结构体的地址的

内核代码可以引用当前进程, 通过存取全局项**current**
- group_leader: 线程组的第一个线程
- uid(实际用户id)，gid(实际组id) : 进程的这两个id在登入时从口令文件/etc/passwd中获取。
- euid(有效用户id)，geid(有效组id): 决定了我们的进程访问文件的权限。进程的有效用户id通常就是实际用户id。
- suid,sgid:当一个进程访问设置了set-user-ID或是set-group-ID标志的文件时，该文件的宿主用户id被保存在suid中。

> [binder.c - Android Code Search](https://cs.android.com/android/kernel/superproject/+/refs/heads/common-android-mainline:common/drivers/android/binder.c;drc=3703fe69dc6c3d662c8d30d463a095b99ed9d69d;bpv=0;bpt=1;l=5794)

```c
/**
 * 驱动层的binder_open函数的作用是创建并初始化了binder_proc结构体, 
 * 该结构体记录了打开Binder设备的进程所对应的Binder通信信息。
 * 类似open系统调用, mmap系统调用导致驱动层的binder_mmap函数被调用。
 */
static int binder_open(struct inode *nodp, struct file *filp)
{
	// 创建binder_proc结构体, 最终放入到file->private_data中
	struct binder_proc *proc;
	// 为binder_proc结构体分配内存空间
	proc = kzalloc(sizeof(*proc), GFP_KERNEL);
	if (proc == NULL)
	// 保存打开Binder设备的进程信息， 即servicemanager
	// 内核代码可以引用当前进程, 通过存取全局项 current
	get_task_struct(current->group_leader);
	// 将当前线程的task保存到proc的tsk
	proc->tsk = current->group_leader;
	// 初始化可执行任务列表
	INIT_LIST_HEAD(&proc->todo);
	// 初始化wait队列, 用于切换current进程到wait状态
	init_waitqueue_head(&proc->wait);
	// 记录进程默认优先级(当前进程的nice值)
	proc->default_priority = task_nice(current);
	// 同步锁，因为binder支持多线程访问
	binder_lock(__func__);
	// BINDER_PROC对象创建数加1
	binder_stats_created(BINDER_STAT_PROC);
	// 将proc_node节点添加到全局列表binder_procs中
	hlist_add_head(&proc->proc_node, &binder_procs);
	proc->pid = current->group_leader->pid;
	//初始化已分发的死亡通知列表
	INIT_LIST_HEAD(&proc->delivered_death);
	// 将proc存入filp结构体的private_data变量中
	filp->private_data = proc;
	binder_unlock(__func__);
	// 在/proc/binder/proc目录下创建Binder通信文件, 文件以PID命名
	if (binder_debugfs_dir_entry_proc) {
		char strbuf[11];
		snprintf(strbuf, sizeof(strbuf), "%u", proc->pid);
		proc->debugfs_entry = debugfs_create_file(strbuf, S_IRUGO,
			binder_debugfs_dir_entry_proc, proc, &binder_proc_fops);
	}
	return 0;
}
```

#### 2.2.2 binder_ioctl

> [binder.c - Android Code Search](https://cs.android.com/android/kernel/superproject/+/refs/heads/common-android-mainline:common/drivers/android/binder.c;l=5510;)

|ioctl指令|说明|
|:-- |: --|
|BINDER_SET_CONTEXT_MSG|专门用于设置context manager|
|BINDER_WRITE_READ|收发Binder IPC数据|

```c
static long binder_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
	int ret;
	// 获取binder_open返回的proc
	struct binder_proc *proc = filp->private_data;
	struct binder_thread *thread;
	unsigned int size = _IOC_SIZE(cmd);
	// arg表示进程空间的binder_write_read结构体地址，位于用户空间，需要转换
	void __user *ubuf = (void __user *)arg;
	trace_binder_ioctl(cmd, arg);
	ret = wait_event_interruptible(binder_user_error_wait, binder_stop_on_user_error < 2);
	if (ret)
		goto err_unlocked;
	binder_lock(__func__);
	// 从proc中获取当前线程, 例如是serviceManager调用的 则是它的main线程
	thread = binder_get_thread(proc);
	if (thread == NULL) {
		ret = -ENOMEM;
		goto err;
	}
	// 匹配ioctl指令
	switch (cmd) {
	case BINDER_WRITE_READ:
		// BINDER_WRITE_READ的朋友走这边
		ret = binder_ioctl_write_read(filp, cmd, arg, thread);
		if (ret)
			goto err;
		break;
	case BINDER_SET_MAX_THREADS:
		if (copy_from_user(&proc->max_threads, ubuf, sizeof(proc->max_threads))) {
			ret = -EINVAL;
			goto err;
		}
		break;
	case BINDER_SET_CONTEXT_MGR:
		// BINDER_SET_CONTEXT_MGR的大佬看看
		ret = binder_ioctl_set_ctx_mgr(filp);
		if (ret)
			goto err;
		break;
	case BINDER_THREAD_EXIT:
		binder_debug(BINDER_DEBUG_THREADS, "%d:%d exit\n",
			     proc->pid, thread->pid);
		binder_free_thread(proc, thread);
		thread = NULL;
		break;
	case BINDER_VERSION: {
		struct binder_version __user *ver = ubuf;

		if (size != sizeof(struct binder_version)) {
			ret = -EINVAL;
			goto err;
		}
		if (put_user(BINDER_CURRENT_PROTOCOL_VERSION,
			     &ver->protocol_version)) {
			ret = -EINVAL;
			goto err;
		}
		break;
	}
	default:
		ret = -EINVAL;
		goto err;
	}
	ret = 0;
err:
	if (thread)
		thread->looper &= ~BINDER_LOOPER_STATE_NEED_RETURN;
	binder_unlock(__func__);
	wait_event_interruptible(binder_user_error_wait, binder_stop_on_user_error < 2);
	if (ret && ret != -ERESTARTSYS)
		pr_info("%d:%d ioctl %x %lx returned %d\n", proc->pid, current->pid, cmd, arg, ret);
err_unlocked:
	trace_binder_ioctl_done(ret);
	return ret;
}
```

##### binder_ioctl_set_ctx_mgr

```c
/**
 * 创建一个binder_node节点保存在全局变量binder_context_mgr_node中，保证唯一
 */
static int binder_ioctl_set_ctx_mgr(struct file *filp)
{
	int ret = 0;
	struct binder_proc *proc = filp->private_data;
	// 获取当前进程的euid(有效用户id)
	kuid_t curr_euid = current_euid();
	// binder_context_mgr_node中记录了当前的contextmanager,若存在则跳出，保证只有一个contextmanager
	if (binder_context_mgr_node != NULL) {
		pr_err("BINDER_SET_CONTEXT_MGR already set\n");
		ret = -EBUSY;
		goto out;
	}
	// 
	ret = security_binder_set_context_mgr(proc->tsk);
	if (ret < 0)
		goto out;
	// 验证uid
	if (uid_valid(binder_context_mgr_uid)) {
		if (!uid_eq(binder_context_mgr_uid, curr_euid)) {
			pr_err("BINDER_SET_CONTEXT_MGR bad uid %d != %d\n",
			       from_kuid(&init_user_ns, curr_euid),
			       from_kuid(&init_user_ns,
					binder_context_mgr_uid));
			ret = -EPERM;
			goto out;
		}
	} else {
		binder_context_mgr_uid = curr_euid;
	}
	// 为context manager创建binder_node , binder_node将于proc关联，指定节点的索引为0
	binder_context_mgr_node = binder_new_node(proc, 0, 0);
	if (binder_context_mgr_node == NULL) {
		ret = -ENOMEM;
		goto out;
	}
	binder_context_mgr_node->local_weak_refs++;
	binder_context_mgr_node->local_strong_refs++;
	binder_context_mgr_node->has_strong_ref = 1;
	binder_context_mgr_node->has_weak_ref = 1;
out:
	return ret;
}
```

##### binder_ioctl_write_read

```c
static int binder_ioctl_write_read(struct file *filp,
				unsigned int cmd, unsigned long arg,
				struct binder_thread *thread)
{
	int ret = 0;
	struct binder_proc *proc = filp->private_data;
	unsigned int size = _IOC_SIZE(cmd);
	void __user *ubuf = (void __user *)arg;
	struct binder_write_read bwr;
	if (size != sizeof(struct binder_write_read)) {
		ret = -EINVAL;
		goto out;
	}
	// 从用户空间复制bwr
	if (copy_from_user(&bwr, ubuf, sizeof(bwr))) {
		ret = -EFAULT;
		goto out;
	}
	// 执行写操作
	if (bwr.write_size > 0) {
		ret = binder_thread_write(proc, thread,
					  bwr.write_buffer,
					  bwr.write_size,
					  &bwr.write_consumed);
		trace_binder_write_done(ret);
		if (ret < 0) {
			...
			goto out;
		}
	}
	// 执行读操作
	if (bwr.read_size > 0) {
		ret = binder_thread_read(proc, thread, bwr.read_buffer,
					 bwr.read_size,
					 &bwr.read_consumed,
					 filp->f_flags & O_NONBLOCK);
		trace_binder_read_done(ret);
		if (!list_empty(&proc->todo))
			wake_up_interruptible(&proc->wait);
		if (ret < 0) {
			....
			goto out;
		}
	}
	// 将结果拷贝回用户空间bwr
	if (copy_to_user(ubuf, &bwr, sizeof(bwr))) {
		ret = -EFAULT;
		goto out;
	}
out:
	return ret;
}
```
###### binder_thread_write

```c
/**
 * BINDER_WRITE_READ指令write_size > 0时将执行写操作
 * 根据不同的BC_指令执行不同的操作
 */
 static int binder_thread_write(struct binder_proc *proc,
			struct binder_thread *thread,
			binder_uintptr_t binder_buffer, size_t size,
			binder_size_t *consumed)
{
    // 也就差不多一年那么长， 还是自己看源码吧
}
```

###### binder_thread_read

这里会处理 `BC_XXX`这些二级指令

```c
/**
 * BINDER_WRITE_READ指令read_size > 0时将执行读操作
 * 根据不同的BINDER_指令执行不同的操作
 */
static int binder_thread_read(struct binder_proc *proc,
			      struct binder_thread *thread,
			      binder_uintptr_t binder_buffer, size_t size,
			      binder_size_t *consumed, int non_block)
{
    // 同上
}
```



## 补充

### BBinder

BBinder 继承自IBinder，**负责 binder通讯相关的逻辑**。

BnInterface 就是继承自BBbinder，并将 Binder通信接口和相关的业务接口相结合。

例如各种系统 向ServiceManger注册服务时传入的IBinder 就是 BBinder，例如`BnServiceManager`、`BnMediaPlayService`等。

> [Binder.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/Binder.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=30)

```cpp
class BBinder : public IBinder
{
}
```



#### BBinder::transact()

内部调用`onTransact()` 来处理请求。

> [Binder.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/Binder.cpp;l=359;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1)

```cpp
// NOLINTNEXTLINE(google-default-arguments)
status_t BBinder::transact(
    uint32_t code, const Parcel& data, Parcel* reply, uint32_t flags)
{
    data.setDataPosition(0);

    if (reply != nullptr && (flags & FLAG_CLEAR_BUF)) {
        reply->markSensitive();
    }

    status_t err = NO_ERROR;
    switch (code) {
        case PING_TRANSACTION:
            err = pingBinder();
            break;
        case START_RECORDING_TRANSACTION:
            err = startRecordingTransactions(data);
            break;
        case STOP_RECORDING_TRANSACTION:
            err = stopRecordingTransactions();
            break;
        case EXTENSION_TRANSACTION:
            CHECK(reply != nullptr);
            err = reply->writeStrongBinder(getExtension());
            break;
        case DEBUG_PID_TRANSACTION:
            CHECK(reply != nullptr);
            err = reply->writeInt32(getDebugPid());
            break;
        case SET_RPC_CLIENT_TRANSACTION: {
            err = setRpcClientDebug(data);
            break;
        }
        default:
            // 调用 onTransact()
            err = onTransact(code, data, reply, flags);
            break;
    }

    // In case this is being transacted on in the same process.
    if (reply != nullptr) {
        reply->setDataPosition(0);
        if (reply->dataSize() > LOG_REPLIES_OVER_SIZE) {
            ALOGW("Large reply transaction of %zu bytes, interface descriptor %s, code %d",
                  reply->dataSize(), String8(getInterfaceDescriptor()).c_str(), code);
        }
    }

    if (CC_UNLIKELY(kEnableKernelIpc && mRecordingOn && code != START_RECORDING_TRANSACTION)) {
        Extras* e = mExtras.load(std::memory_order_acquire);
        AutoMutex lock(e->mLock);
        if (mRecordingOn) {
            Parcel emptyReply;
            timespec ts;
            timespec_get(&ts, TIME_UTC);
            auto transaction = android::binder::debug::RecordedTransaction::
                    fromDetails(getInterfaceDescriptor(), code, flags, ts, data,
                                reply ? *reply : emptyReply, err);
            if (transaction) {
                if (status_t err = transaction->dumpToFile(e->mRecordingFd); err != NO_ERROR) {
                    LOG(INFO) << "Failed to dump RecordedTransaction to file with error " << err;
                }
            } else {
                LOG(INFO) << "Failed to create RecordedTransaction object.";
            }
        }
    }

    return err;
}
```



#### BBinder::onTransact()

服务处理binder请求。

> [Binder.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/Binder.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=750)

```cpp
// NOLINTNEXTLINE(google-default-arguments)
status_t BBinder::onTransact(
    uint32_t code, const Parcel& data, Parcel* reply, uint32_t /*flags*/)
{
    switch (code) {
        case INTERFACE_TRANSACTION:
            CHECK(reply != nullptr);
            reply->writeString16(getInterfaceDescriptor());
            return NO_ERROR;

        case DUMP_TRANSACTION: {
            int fd = data.readFileDescriptor();
            int argc = data.readInt32();
            Vector<String16> args;
            for (int i = 0; i < argc && data.dataAvail() > 0; i++) {
               args.add(data.readString16());
            }
            return dump(fd, args);
        }

        case SHELL_COMMAND_TRANSACTION: {
            int in = data.readFileDescriptor();
            int out = data.readFileDescriptor();
            int err = data.readFileDescriptor();
            int argc = data.readInt32();
            Vector<String16> args;
            for (int i = 0; i < argc && data.dataAvail() > 0; i++) {
               args.add(data.readString16());
            }
            sp<IBinder> shellCallbackBinder = data.readStrongBinder();
            sp<IResultReceiver> resultReceiver = IResultReceiver::asInterface(
                    data.readStrongBinder());
            (void)in;
            (void)out;
            (void)err;
            if (resultReceiver != nullptr) {
                resultReceiver->send(INVALID_OPERATION);
            }
            return NO_ERROR;
        }

        case SYSPROPS_TRANSACTION: {
            report_sysprop_change();
            return NO_ERROR;
        }

        default:
            return UNKNOWN_TRANSACTION;
    }
}
```



### BpBinder

BpBinder 继承自IBinder 是**客户端用来与Server交互的代理类**，p表示 Proxy。

#### BpBinder::PrivateAccessor::create(handle)

> [BpBinder.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/BpBinder.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=135)

```cpp
// 定义
class BpBinder : public IBinder {
    
}

// 调用 BpBinder::create()
static sp<BpBinder> create(int32_t handle) { return BpBinder::create(handle); }

sp<BpBinder> BpBinder::create(int32_t handle) {
    // ....
    return sp<BpBinder>::make(BinderHandle{handle}, trackedUid);
}
```

#### BpBinder的构造函数

> [BpBinder.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/BpBinder.cpp;bpv=0;bpt=1;l=221)

```cpp

// 调用了 BpBinder::BpBinder(Handle&& handle)
BpBinder::BpBinder(BinderHandle&& handle, int32_t trackedUid) : BpBinder(HandBpBinder
        LOG_ALWAYS_FATAL("Binder kernel driver disabled at build time");
        return;
    }

    mTrackedUid = trackedUid;
	// 主要就是向输出缓冲区mOut中写入BC_INCREFS 和 handle = 0
    IPCThreadState::self()->incWeakHandle(this->binderHandle(), this);
}

// handle = 0
BpBinder::BpBinder(Handle&& handle)
      : mStability(0),
        mHandle(handle),
        mAlive(true),
        mObitsSent(false),
        mObituaries(nullptr),
        mDescriptorCache(kDescriptorUninit),
        mTrackedUid(-1) {
    extendObjectLifetime(OBJECT_LIFETIME_WEAK);
}
```

#### IPCThreadState::incWeakHandle()

```cpp
void IPCThreadState::incWeakHandle(int32_t handle, BpBinder *proxy)
{
    LOG_REMOTEREFS("IPCThreadState::incWeakHandle(%d)\n", handle);
    // BC_INCREFS
    mOut.writeInt32(BC_INCREFS);
    // 0
    mOut.writeInt32(handle);
    if (!flushIfNeeded()) {
        // Create a temp reference until the driver has handled this command.
        proxy->getWeakRefs()->incWeak(mProcess.get());
        mPostWriteWeakDerefs.push(proxy->getWeakRefs());
    }
}
```

#### BpBinder::transact()

内部调用了 `IPCThreadState::self()->transact()` 来发送服务注册请求，IPCThreadState中处理的就是Binder的通信逻辑。

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



### 重要的接口定义

#### IInterface

> [IInterface.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/IInterface.h)

```cpp
class IInterface : public virtual RefBase
{
public:
            IInterface();
            static sp<IBinder>  asBinder(const IInterface*);
            static sp<IBinder>  asBinder(const sp<IInterface>&);

protected:
    virtual                     ~IInterface();
    virtual IBinder*            onAsBinder() = 0;
};
```

#### BnInterface

服务端实现服务的接口，是一个类模板，将业务接口 `IXXX` 和 binder接口 `BBinder` 结合。 

> [IInterface.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/IInterface.h;l=70;)

```cpp
template<typename INTERFACE>
class BnInterface : public INTERFACE, public BBinder
{
public:
    virtual sp<IInterface>      queryLocalInterface(const String16& _descriptor);
    virtual const String16&     getInterfaceDescriptor() const;
    typedef INTERFACE BaseInterface;

protected:
    virtual IBinder*            onAsBinder();
};

```

#### BpInterface

客户端访问服务的代理对象接口，通用是一个类模板。

使用的代理模式，继承自 `BpRefBase`，内部持有的 `mRemote` 成员变量就是 BpBinder。

> [IInterface.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/IInterface.h;l=84;)

```cpp
template<typename INTERFACE>
class BpInterface : public INTERFACE, public BpRefBase
{
public:
    explicit                    BpInterface(const sp<IBinder>& remote); // 赋值给成员变量 mRemote
    typedef INTERFACE BaseInterface;

protected:
    virtual IBinder*            onAsBinder(); // 返回 mRemote: BpBinder。
};
```



### interface_cast

这是模板函数，具体的实现 在 `INTERFACE` 中。

例如 `INTERFACE = IServiceManager` 则调用的就是 `IServiceManager::asInterface(obj)`

```cpp
template<typename INTERFACE>
inline sp<INTERFACE> interface_cast(const sp<IBinder>& obj)
{
    return INTERFACE::asInterface(obj);
}
```



### IServiceManager

#### 接口声明

`IServiceManager.h`中声明了接口，其中最关键的是 `DECLARE_META_INTERFACE()` 这个宏定义，宏包括了 Binder通信相关接口。

其他的就是一些 业务上的接口和常量。

> [IServiceManager.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/IServiceManager.h;l=27;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=1;bpt=1)

```cpp
class IServiceManager : public ::android::IInterface {
public:
  typedef IServiceManagerDelegator DefaultDelegator;
  // 这是一个宏，它定义了 asInterface() 等一些接口
  DECLARE_META_INTERFACE(ServiceManager)
  // 
  enum : int32_t { DUMP_FLAG_PRIORITY_CRITICAL = 1 };
  // ....
  // 定义的业务接口
  virtual ::android::binder::Status getService(const ::std::string& name, ::android::sp<::android::IBinder>* _aidl_return) = 0;
  virtual status_t addService(const String16& name, const sp<IBinder>& service,
                                bool allowIsolated = false,
                                int dumpsysFlags = DUMP_FLAG_PRIORITY_DEFAULT) = 0;
 // ....
};  // class IServiceManager
```

#### 接口实现

`IServiceManager.cpp` 中是 具体的实现，其中最总要的就是 `DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE()`这个宏，

它包括了 `DECLARE_META_INTERFACE` 中定义的接口的具体实现。

> [IServiceManager.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/IServiceManager.cpp;bpv=0;bpt=1)

```cpp
namespace android {
namespace os {
// 这个宏中包括了 DECLARE_META_INTERFACE 中定义的接口的具体实现
DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE(ServiceManager, "android.os.IServiceManager")
}  // namespace os
}  // namespace android
#include <android/os/BpServiceManager.h>
#include <android/os/BnServiceManager.h>
#include <binder/Parcel.h>
#include <android-base/macros.h>

namespace android {
namespace os {

// BpServiceManager 是 IInterface的实现类
BpServiceManager::BpServiceManager(const ::android::sp<::android::IBinder>& _aidl_impl)
    // 调用 BpInterface 的构造
    : BpInterface<IServiceManager>(_aidl_impl){
}

// 业务接口的实现 
::android::binder::Status BpServiceManager::getService(const ::std::string& name, ::android::sp<::android::IBinder>* _aidl_return) {
  // ... 
  return _aidl_status;
}

```

BpServiceManager 就是 IServiceManager和 IInterface的实现类。将传进来的 BpBinder保存在 mRemote中。

[BpServiceManager.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:out/soong/.intermediates/frameworks/native/libs/binder/libbinder/android_native_bridge_arm64_armv8-a_shared/gen/aidl/android/os/BpServiceManager.h)

```cpp
// 接口声明
class BpServiceManager : public ::android::BpInterface<IServiceManager> {}

template<typename INTERFACE>
class BpInterface : public INTERFACE, public IInterface, public BpHwRefBase
{
public:
    explicit                    BpInterface(const sp<IBinder>& remote);
    virtual IBinder*            onAsBinder();
};

// 实现
template<typename INTERFACE>
inline BpInterface<INTERFACE>::BpInterface(const sp<IBinder>& remote)
    : BpRefBase(remote)
{
}
    
BpRefBase::BpRefBase(const sp<IBinder>& o)
    // mRemote 就是 传进来的 BpBinder
    : mRemote(o.get()), mRefs(nullptr), mState(0)
{
    extendObjectLifetime(OBJECT_LIFETIME_WEAK);

    if (mRemote) {
        mRemote->incStrong(this);           // Removed on first IncStrong().
        mRefs = mRemote->createWeak(this);  // Held for our entire lifetime.
    }
}
```

### 几个重要的宏定义

`DECLARE_META_INTERFACE` 这个宏定义了一些 **重要的binder通讯接口**，其中就包括了 `asInterface()`。

这个宏在 在服务的业务接口中（例如`IServiceManager接口`），从而将业务接口和binder通讯接口结合起来。

#### DECLARE_META_INTERFACE

> [IInterface.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/IInterface.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=96)

```cpp
// -----------------
#define DECLARE_META_INTERFACE(INTERFACE)                                                         \
public:                                                                                           \
    // 定义描述符，可以通过描述符来查询对应接口
    static const ::android::String16 descriptor;                                                  \
    // asInterface
    static ::android::sp<I##INTERFACE> asInterface(const ::android::sp<::android::IBinder>& obj); \
    // 返回描述符
    virtual const ::android::String16& getInterfaceDescriptor() const;                            \
    // 构造和析构
    I##INTERFACE();                                                                               \
    virtual ~I##INTERFACE();                                                                      \
    // 
    static bool setDefaultImpl(::android::sp<I##INTERFACE> impl);                                 \
    static const ::android::sp<I##INTERFACE>& getDefaultImpl();                                   \
                                                                                                  \
private:                                                                                          \
    static ::android::sp<I##INTERFACE> default_impl;                                              \
                                                                                                  \
public:

#define __IINTF_CONCAT(x, y) (x ## y)
```

#### DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE

`DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE` 这个宏就是定义 `DECLARE_META_INTERFACE`宏中接口的**具体实现**的。

它用于服务的实现类中，这里以 `INTERFACE=ServiceManager` 来解读，会发现和使用aidl时自动生成的IBinder类内的实现很相似。



> [IInterface.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/binder/include/binder/IInterface.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=127;)

```cpp
#ifndef DO_NOT_CHECK_MANUAL_BINDER_INTERFACES

// 这个宏内部调用也是 DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE
#define IMPLEMENT_META_INTERFACE(INTERFACE, NAME)                       \
    static_assert(internal::allowedManualInterface(NAME),               \
                  "b/64223827: Manually written binder interfaces are " \
                  "considered error prone and frequently have bugs. "   \
                  "The preferred way to add interfaces is to define "   \
                  "an .aidl file to auto-generate the interface. If "   \
                  "an interface must be manually written, add its "     \
                  "name to the whitelist.");                            \
    DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE(INTERFACE, NAME)    \

#else

#define IMPLEMENT_META_INTERFACE(INTERFACE, NAME)                       \
    DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE(INTERFACE, NAME)    \

#endif

// Macro to be used by both IMPLEMENT_META_INTERFACE and IMPLEMENT_META_NESTED_INTERFACE
// 这里就是 DECLARE_META_INTERFACE 的具体实现
// ITYPE=IServiceManager, INAME=IServiceManager, BPTYPE=BpServiceManager
// 这里 通过 BpBinder创建了 对应的 BpServiceManager
#define DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE0(ITYPE, INAME, BPTYPE)                     \
    // 返回描述符
    const ::android::String16& ITYPE::getInterfaceDescriptor() const { return ITYPE::descriptor; } \
    // obj 就是 通过 ProcessState::getContextObject() 获取到的 BpBinder(0)
    ::android::sp<ITYPE> ITYPE::asInterface(const ::android::sp<::android::IBinder>& obj) {        \
        ::android::sp<ITYPE> intr;                                                                 \
        if (obj != nullptr) {                                                                      \
            // 根据descriptor 查找是否已存在对应的 IServiceManager
            intr = ::android::sp<ITYPE>::cast(obj->queryLocalInterface(ITYPE::descriptor));        \
            if (intr == nullptr) {                                                                 \
                // 不存在就构建一个，这里就很明显了，其实就是使用 BpBinder 构建了一个 BpServiceManager
                // ::android::sp<BpServiceManager>::make(BpBinder(0))
                intr = ::android::sp<BPTYPE>::make(obj);                                           \
            }                                                                                      \
        }                                                                                          \
        return intr;                                                                               \
    }                                                                                              \
    ::android::sp<ITYPE> ITYPE::default_impl;                                                      \
    bool ITYPE::setDefaultImpl(::android::sp<ITYPE> impl) {                                        \
        /* Only one user of this interface can use this function     */                            \
        /* at a time. This is a heuristic to detect if two different */                            \
        /* users in the same process use this function.              */                            \
        assert(!ITYPE::default_impl);                                                              \
        if (impl) {                                                                                \
            ITYPE::default_impl = std::move(impl);                                                 \
            return true;                                                                           \
        }                                                                                          \
        return false;                                                                              \
    }                                                                                              \
    const ::android::sp<ITYPE>& ITYPE::getDefaultImpl() { return ITYPE::default_impl; }            \
    //
    ITYPE::INAME() {}                                                                              \
    ITYPE::~INAME() {}

// Macro for an interface type.
// 这里是入口
#define DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE(INTERFACE, NAME)                        \
    // 描述符的值
    const ::android::StaticString16 I##INTERFACE##_descriptor_static_str16(                     \
            __IINTF_CONCAT(u, NAME));                                                           \
    // 描述符 
    const ::android::String16 I##INTERFACE::descriptor(I##INTERFACE##_descriptor_static_str16); \
    // IServiceManager, IServiceManager, BpServiceManager
    DO_NOT_DIRECTLY_USE_ME_IMPLEMENT_META_INTERFACE0(I##INTERFACE, I##INTERFACE, Bp##INTERFACE)
```

### Binder消息码

| 指令       |                                                   |
| ---------- | ------------------------------------------------- |
| BINDER_XXX | 一级指令,binder首先处理这些状态码                 |
| BR_XXXX    | 返回码                                            |
| BC_XXXX    | 这些是 BINDER_WRITE_READ 这个一级指令下的二级指令 |

> [binder.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:bionic/libc/kernel/uapi/linux/android/binder.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=226)

```cpp

#define BINDER_WRITE_READ _IOWR('b', 1, struct binder_write_read)
#define BINDER_SET_IDLE_TIMEOUT _IOW('b', 3, __s64)
#define BINDER_SET_MAX_THREADS _IOW('b', 5, __u32)
#define BINDER_SET_IDLE_PRIORITY _IOW('b', 6, __s32)
#define BINDER_SET_CONTEXT_MGR _IOW('b', 7, __s32)
#define BINDER_THREAD_EXIT _IOW('b', 8, __s32)
#define BINDER_VERSION _IOWR('b', 9, struct binder_version)
#define BINDER_GET_NODE_DEBUG_INFO _IOWR('b', 11, struct binder_node_debug_info)
#define BINDER_GET_NODE_INFO_FOR_REF _IOWR('b', 12, struct binder_node_info_for_ref)
#define BINDER_SET_CONTEXT_MGR_EXT _IOW('b', 13, struct flat_binder_object)
#define BINDER_FREEZE _IOW('b', 14, struct binder_freeze_info)
#define BINDER_GET_FROZEN_INFO _IOWR('b', 15, struct binder_frozen_status_info)
#define BINDER_ENABLE_ONEWAY_SPAM_DETECTION _IOW('b', 16, __u32)
#define BINDER_GET_EXTENDED_ERROR _IOWR('b', 17, struct binder_extended_error)

// 这些是从 binder驱动中返回的消息码
enum binder_driver_return_protocol {
  BR_ERROR = _IOR('r', 0, __s32),
  BR_OK = _IO('r', 1),
  BR_TRANSACTION_SEC_CTX = _IOR('r', 2, struct binder_transaction_data_secctx),
  BR_TRANSACTION = _IOR('r', 2, struct binder_transaction_data),
  BR_REPLY = _IOR('r', 3, struct binder_transaction_data),
  BR_ACQUIRE_RESULT = _IOR('r', 4, __s32),
  BR_DEAD_REPLY = _IO('r', 5),
  BR_TRANSACTION_COMPLETE = _IO('r', 6),
  BR_INCREFS = _IOR('r', 7, struct binder_ptr_cookie),
  BR_ACQUIRE = _IOR('r', 8, struct binder_ptr_cookie),
  BR_RELEASE = _IOR('r', 9, struct binder_ptr_cookie),
  BR_DECREFS = _IOR('r', 10, struct binder_ptr_cookie),
  BR_ATTEMPT_ACQUIRE = _IOR('r', 11, struct binder_pri_ptr_cookie),
  BR_NOOP = _IO('r', 12),
  BR_SPAWN_LOOPER = _IO('r', 13),
  BR_FINISHED = _IO('r', 14),
  BR_DEAD_BINDER = _IOR('r', 15, binder_uintptr_t),
  BR_CLEAR_DEATH_NOTIFICATION_DONE = _IOR('r', 16, binder_uintptr_t),
  BR_FAILED_REPLY = _IO('r', 17),
  BR_FROZEN_REPLY = _IO('r', 18),
  BR_ONEWAY_SPAM_SUSPECT = _IO('r', 19),
};

// 应用端发送时使用的binder驱动指令。
enum binder_driver_command_protocol {
  BC_TRANSACTION = _IOW('c', 0, struct binder_transaction_data),
  BC_REPLY = _IOW('c', 1, struct binder_transaction_data),
  BC_ACQUIRE_RESULT = _IOW('c', 2, __s32),
  BC_FREE_BUFFER = _IOW('c', 3, binder_uintptr_t),
  BC_INCREFS = _IOW('c', 4, __u32),
  BC_ACQUIRE = _IOW('c', 5, __u32),
  BC_RELEASE = _IOW('c', 6, __u32),
  BC_DECREFS = _IOW('c', 7, __u32),
  BC_INCREFS_DONE = _IOW('c', 8, struct binder_ptr_cookie),
  BC_ACQUIRE_DONE = _IOW('c', 9, struct binder_ptr_cookie),
  BC_ATTEMPT_ACQUIRE = _IOW('c', 10, struct binder_pri_desc),
  BC_REGISTER_LOOPER = _IO('c', 11),
  BC_ENTER_LOOPER = _IO('c', 12),
  BC_EXIT_LOOPER = _IO('c', 13),
  BC_REQUEST_DEATH_NOTIFICATION = _IOW('c', 14, struct binder_handle_cookie),
  BC_CLEAR_DEATH_NOTIFICATION = _IOW('c', 15, struct binder_handle_cookie),
  BC_DEAD_BINDER_DONE = _IOW('c', 16, binder_uintptr_t),
  BC_TRANSACTION_SG = _IOW('c', 17, struct binder_transaction_data_sg),
  BC_REPLY_SG = _IOW('c', 18, struct binder_transaction_data_sg),
};
```



------
苦工 : [口戛口崩月危.Z][author]

[author]: https://zaze359.github.io
[为什么Android要采用Binder作为IPC机制]:https://www.zhihu.com/question/39440766/answer/89210950
[C/S和ServiceManager]: http://static.zybuluo.com/zaze/hd4k8fd8y0ky6lljv86bwkd9/image_1cbjv1brnoa21sc21coacpb1rtrm.png
[Linux设备驱动之字符设备驱动]: https://blog.csdn.net/andylauren/article/details/51803331
[Linux字符设备驱动框架]: https://www.cnblogs.com/xiaojiang1025/p/6181833.html
[Android系统开篇]: http://gityuan.com/android/
[Linux 的虚拟文件系统]: https://blog.csdn.net/heikefangxian23/article/details/51579971

[设备与驱动的关系以及设备号、设备文件]: https://www.cnblogs.com/lidabo/p/5300529.html
[图解Android - Binder 和 Service]: http://www.cnblogs.com/samchen2009/p/3316001.html
[Android启动流程]: http://static.zybuluo.com/zaze/l1yityve5up0dcnq9icxtwjf/image_1cegf6i1jmjmtdbqisgik1mu89.png
