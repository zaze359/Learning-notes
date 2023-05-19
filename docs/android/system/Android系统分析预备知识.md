# Android系统分析预备知识

这里汇总了 分析Android系统时可能需要了解的基础知识。

## 参考资料

* [Linux设备驱动之字符设备驱动][Linux设备驱动之字符设备驱动]
* [Linux字符设备驱动框架][Linux字符设备驱动框架]
* [Linux 的虚拟文件系统][Linux 的虚拟文件系统]
* [设备与驱动的关系以及设备号、设备文件][设备与驱动的关系以及设备号、设备文件]
* [线程局部存储](http://www.cppblog.com/Tim/archive/2012/07/04/181018.html )

## Unix/Linux 一切皆是文件

**“一切皆是文件”是 Unix/Linux的基本哲学之一，所有的一切都是通过文件的形式来进行访问和管理，即使不是文件也被抽象成文件的形式。**包括一般的数据文件、程序普通文件、目录、套接字，**设备文件**等。

Linux的内核中大量使用"注册+回调"机制进行驱动程序的编写。

### 设备驱动和设备文件

设备可以分为以下三类：对于字符设备和块设备来说，在`/dev`目录下都有对应的设备文件，通过这些设备文件来操作设备。

- **字符设备(无缓冲)**：只能一个字节一个字节的读写的设备，不能随机读取设备内存中的某一数据，读取数据需要按照先后顺序进行。字符设备是面向流的设备。常见的字符设备如鼠标、键盘、串口、控制台、LED等外设。
- **块设备(有缓冲)**：是指可以从设备的任意位置读取一定长度的数据设备。块设备如硬盘、磁盘、U盘和SD卡等存储设备。
- **网络设备**：网络设备比较特殊，不在是对文件进行操作，而是由专门的网络接口来实现。应用程序不能直接访问网络设备驱动程序。在/dev目录下也没有文件来表示网络设备。

![image-20230301203221532](./Android%E7%B3%BB%E7%BB%9F%E5%88%86%E6%9E%90%E9%A2%84%E5%A4%87%E7%9F%A5%E8%AF%86.assets/image-20230301203221532.png)

### 设备驱动

**每种设备类型都有与之相对应的设备驱动程序，它是内核的组成部分**。驱动程序创建了一个硬件与硬件或硬件与软件沟通的接口，经由主板上的总线(bus)或其它沟通子系统(subsystem)与硬件形成连接的机制 来处理设备的所有IO请求。

### 设备文件

**用户程序需要通过设备文件来使用驱动程序进而操作字符设备和块设备，可以认为是设备驱动的接口**。

* 系统中的一个设备对应一个设备文件，这个文件会占用VFS中的一个`inode`。

* 设备文件并不使用数据块，因此设备文件也就没有大小，在设备文件中，inode中文件大小这个字段存放的是访问设备的设备号。

* 设备文件位于`/dev`目录下，它的参数包括：设备文件名、设备类型、主设备号及次设备号。

由于外设的种类较多，操作方式各不相同，所以**Linux为所有的设备文件提供了统一的操作函数接口**，使用`struct file_operations`这一数据结构，它是文件层次的I/O接口，包括许多操作函数的指针：如`open()`、`close()`、`read()`、`write()`和用于控制的`ioctl()`等，从而隐藏了设备操作的差异性。这样，应用程序根本不必考虑操作的是设备还是普通文件，可一律当作文件处理，具有非常清晰统一的I/O接口。

我们操作一个设备文件的流程如下：

1. **寻找索引节点(inode)**：通过虚拟文件系统(VFS) 找到相应的`inode`。
2. **执行open()函数（其他函数同理）**：执行创建这个设备文件时注册在inode中的open()函数，对于各种设备文件，最终调用各自驱动程序中的I/O函数进行具体设备的操作。

当设备打开（open）时，内核利用主设备号分派执行相应的驱动程序，次设备号只由相应的设备驱动程序使用。例如一个嵌入式系统，有两个LED指示灯，LED灯需要独立的打开或者关闭。那么，可以写一个LED灯的字符设备驱动程序，将其主设备号注册成5号设备，次设备号分别为1和2。这里，次设备号就分别表示两个LED灯。所以，为了让我们写的驱动能够正常的被应用程序操作，需要做以下几件事：

1. 实现相应的方法。
2. 创建相应的设备文件。



---

## 系统调用(system call)

指运行在使用者空间的程序向操作系统内核请求需要更高权限运行的服务。系统调用提供了用户程序与操作系统之间的接口。

大多数系统交互式操作需求在内核态执行，如设备IO操作或者进程间通信。

常见的系统调用有：

| system call | 说明                                                         |
| ----------- | ------------------------------------------------------------ |
| open        | 打开设备文件, 以便访问驱动程序。                             |
| mmap        | 将设备文件映射到进程的虚拟地址空间。                         |
| ioctl       | 如果需要扩展新的功能，通常以增设`ioctl()`命令的方式实现，类似于拾遗补漏. |
| fcontl      | 根据文件描述词来操作文件的特性                               |

## C/S体系结构

- **用户端(Client)** : 是C/S体系结构中使用Server端提供的Service的一方
- **服务端(Server)** : 是C/S体系结构中为Client端提供Service的一方
- **服务代理(Proxy):** 位于Client端, 提供访问服务的接口。主要作用是屏蔽用户端和Server端通讯的细节, 如对请求数据的序列化和对响应数据的反序列化、通信协议的处理等。
- **服务(Service):** 运行在Server端，提供具体的功能处理Client端的请求。
- **服务存根(Stub)**: 可以看作是Service的代理。位于Server端, 屏蔽了Proxy和Service端通信的细节, 对Client端Proxy请求数据的反序列化和对Server端响应数据的序列化、通信协议的封装和处理、匹配Client端调用Service的具体方法。
- **通信协议**：Client端和Server端可以运行于不同的进程中，甚至可以在不同的主机中，因此需要提供远程通信功能。在Android中，主要使用Binder作为Client端与Server端通信的协议。

---

## I/O多路复用

多路复用是指：**多个I/O请求 复用一个进程或线程来处理**。

即当一个连接发生阻塞就立刻切换，去处理其他的请求。从而消除了I/O阻塞，从而充分利用CPU。

## BIO（Block IO）

同步阻塞IO，默认的Socket编程就是阻塞IO。每个客户端连接都需要一个线程来接收数据，十分浪费。

* 创建 Socket 接口。
* 通过 `bind()`  将接口号和端口号进行绑定。
* 开启一个循环，在循环中调用 `read` 读取或 `listener`监听事件，但是是阻塞的。
* 有客户端连接 或者消息发送过来时会被唤醒。

## NIO（NONBLOCK IO）

同步非阻塞IO。和BIO的区别主要是无需阻塞等待。**等待事件时线程是挂起的，处理事件还是阻塞的**。

NIO的大致流程如下：

* 创建 Socket 接口。
* 通过 `bind` 函数 将接口号和端口号进行绑定。
* 监听事件，同时**将Socket标记为非阻塞**。
* 遍历检查所有socket，有事件就处理。

### select

首先进程会把所有的Socket告诉内核（此时内核相当于多路复用器），当有I/O事件发生时内核**会遍历所有Socket**，当某个socket有事件发生时，就去该socket上处理事件。

* 会拷贝所有用户空间的fd_set 到 内核中。
* 仅知道有I/O事件，不知道是哪些I/O，所以每次都要遍历所有socket，效率很低。

### poll

poll 和 select原理基本相同。主要区别是poll是基于链表存储，没有最大连接数的限制。

### epoll

epoll **不需要遍历**所有的socket， 仅**管理活跃的连接**。只当连接真正可读、可写时才会处理，若发生阻塞就立刻切换，处理其他的请求。

epoll大量的连接管理是在操作系统内核里做的，应用程序负担小，可以建立大量的连接而仅消耗不多的内存。（几十万连接 = 几百M内存）。

epoll 的大致流程如下：

* 调用 `epoll_create()` 创建一个文件，返回一个fd。
* 创建Socket、绑定端口号、监听事件，同时标记为非阻塞。
* 调用 `epoll_ctl()` 将socket 和 监听事件写入 fd。
* 开启循环 调用 `epoll_wait()`函数进行监听，此函数返回已经就绪事件的长度（0表示没有）。

---

## 虚拟机、进程、应用程序之间的关系。

* **一个虚拟机对应一个进程**。
* **一个进程可以运行多个应用程序**。
* **一个应用程序也可以开启多个进程**。此时多个进程之间需要使用进程间通信来交换。

## 进程间通讯(IPC)

Linux为了安全考虑，一个进程禁止直接与其他进程交互, 也就是**不同进程之间是相互隔离的(Process Isolation)**。这时候如果需要进行通信，就必须通过Linux内核提供的**进程间通讯(Inter Process Communication, IPC)**，I是一种标准的Unix通信机制。。

### LPC和RPC

LPC和RPC 就是 IPC 的两种类型。

* LPC：本地过程调用，指同一台设备中不同进程间的通信。
* RPC：远程过程调用，不同设备进程间的通信，通常用在网络上。

### 常见的IPC方式

| IPC                     |                                                              | 存在问题                                                     |
| ----------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Pipe(管道)              | 会在创建时分配一个page大小的内存。                           | 缓存区大小比较有限，数据需要拷贝两次。                       |
| Socket(套接字)          | 一种通用接口，主要是用于不同机器或跨网络的通信。对于读写的大小没有限制。 | 数据需要拷贝两次，传输效率低。(Android 中使用的LocalSocket 传输效率其实很高) |
| Signal(信号)            | 适用于进程中断控制，比如非法内存访问，杀死某个进程等。Android中也使用了signal机制，如Kill Process时。 | 不适用于信息交换                                             |
| Semaphore(信号量)       | 常作为一种锁机制，防止某进程正在访问共享资源时，其他进程也访问该资源。 |                                                              |
| Message Queue(消息队列) |                                                              | 不合适频繁或信息量大的通信。数据需要拷贝两次。               |
| Shared Memory(共享内存) | 共享缓冲区直接附加到进程虚拟地址空间。                       | **数据无需拷贝,速度快,但是实现方式复杂。**需要考虑到访问临界资源的并发同步问题。所以各进程需要利用同步工具解决**进程间的同步问题**。 |



### LocalSocket

在Android中，ATMS和zygote间使用的是一个LocalSocket进行通讯。

LocalSocket 实际是使用 `AF_UNIX` 创建的 UNIX Domain Socket ，它仅适用于本地进程间的通信，而一般的网络sokcet是使用AF_INET 创建的，它主要是为了在不同机器间进行通信。

* LocalSocket  不用经过网络协议栈，所以也就不用处理相关协议的编解码，同时不受限于网络带宽，具有很高效的传输速率。
* LocalSocket  是将数据从一个进程拷贝到另一个进程，不用打包/拆包、计算校验和维护序号和应答等。

> 不过使用LocalSocket 需要申请 Inter

```java
	
	public void create(int sockType) throws IOException {
        if (fd != null) {
            throw new IOException("LocalSocketImpl already has an fd");
        }
        int osType;
        switch (sockType) {
            case LocalSocket.SOCKET_DGRAM:
                osType = OsConstants.SOCK_DGRAM;
                break;
            case LocalSocket.SOCKET_STREAM:
                osType = OsConstants.SOCK_STREAM;
                break;
            case LocalSocket.SOCKET_SEQPACKET:
                osType = OsConstants.SOCK_SEQPACKET;
                break;
            default:
                throw new IllegalStateException("unknown sockType");
        }
        try {
            // AF_UNIX
            fd = Os.socket(OsConstants.AF_UNIX, osType, 0);
            mFdCreatedInternally = true;
        } catch (ErrnoException e) {
            e.rethrowAsIOException();
        }
    }
```



## fork进程

> copy on write机制：先全部复制然后再根据需要进行修改。

在进程中调用fork() 后会基于copy on write机制 创建一个子进程。这个函数一次调用会返回两次。

* 返回子进程：返回0
* 返回父进程：返回新创建的子进程的pid。

```cpp
#include <stdio.h>
#include <unistd.h>

// 需要在Linux中编译运行, windows 无法使用fork()创建子进程
int main() 
{
    pid_t pid = fork();
    if(pid == 0) {
        printf("----- in child\n");
        printf("child pid=%d; retrun %d\n", getpid(), pid);
    } else {
        printf("----- in parent\n");
        printf("parent pid=%d; retrun %d\n", getpid(), pid);
    }
}
```



## watchdog

watchdog是Android的一个系统服务，它的机制和我们应用层常见的ANR类似，它是来处理系统服务未响应的情况。

watchdog会一定间隔的检测服务正常，若存在问题则认为服务未响应，然后watchdog调用 Process.kill() 将服务进程杀死。

* MonitorChecker：检测服务是否被长时间锁住。
* HandlerChecker：检测loop中的消息队列是否阻塞。

## Usap(Unspecialized App Process)

Usap 是 Android 10之后引入的一种 快速创建应用进程 的新机制。

* 它会通过 prefork 的方式将进程提前创建，并保存到 一个 Usap pool 中。
* 当有应用需要启动时，直接从池子中取出已经创建好的进程分配给它。而不必再重新fork。

## RefBase、sp和wp

* RefBase： 是Android中所有对象的始祖，类似Java的Object。内部包含一个影子对象mRefs，管理了强弱引用计数。
* sp (strong pointer)：将实际对象 sp化后，强弱引用计数各加1，sp析构后 引用计数都 减1。
  * 默认情况下 强引用计数为0 会使实际对象被delete。
* wp (weak pointer)：将实际对象 wp 化后，弱引用计数各加1，sp析构后 弱引用计数减1。
  * 弱引用计数为0 会使影子对象被delete。

### RefBase

Android中所有对象的始祖，类似Java的Object。

[RefBase.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:system/core/libutils/RefBase.cpp;l=764;bpv=1;bpt=1)

```c++
class RefBase
{
    // 影子对象：负责引用计数管理
    weakref_impl* const mRefs;
    
    // 默认构造函数。构造自身的同时也创建一个 weakref_impl
    // mRefs 成员变量被初始化。
    RefBase::RefBase()
        : mRefs(new weakref_impl(this))
    {
    }
	
    // 影子对象接口，它的实现类是 weakref_impl
    class weakref_type
    {
    };
};


enum {
    // 强引用计数控制实际对象的生命周期.在强引用计数为0，删除实际对象，弱引用计数为0时删除影子对象。
    OBJECT_LIFETIME_STRONG  = 0x0000, 
    // 弱引用计数控制实际对象的生命周期，当强引用计数和弱引用计数都为0时同时删除实际对象和影子对象。
    OBJECT_LIFETIME_WEAK    = 0x0001, 
    OBJECT_LIFETIME_MASK    = 0x0001
}; // 默认OBJECT_LIFETIME_STRONG，可以调用  extendObjectLifetime()修改

// weakref_impl 主要负责引用计数管理。继承自RefBase的内部类 weakref_type
class RefBase::weakref_impl : public RefBase::weakref_type
{
public:
    std::atomic<int32_t>    mStrong;	// 强引用计数
    std::atomic<int32_t>    mWeak;	// 弱引用计数
    RefBase* const          mBase;	// 指向的实际对象
    std::atomic<int32_t>    mFlags;
    // ...
    
    weakref_impl(RefBase* base)
        : mStrong(INITIAL_STRONG_VALUE) // 初始化强引用计数，值为INITIAL_STRONG_VALUE
        , mWeak(0)	// 初始化弱引用计数，默认0。
        , mBase(base)	// 指向的实际对象
        , mFlags(OBJECT_LIFETIME_STRONG) // 默认为 OBJECT_LIFETIME_STRONG。
        , mStrongRefs(NULL)
        , mWeakRefs(NULL)
        , mTrackEnabled(!!DEBUG_REFS_ENABLED_BY_DEFAULT)
        , mRetain(false)
    {
    }
    
    ~weakref_impl()
    {
        // 清空了 mStrongRefs和 mWeakRefs两个链中保存的ref。
        // 它们是在 addStrongRef() 和 addWeakRef()是添加的,
        // 所以仅针对 debug版本，release中是空。
    }
    
};

// 实际对象自身的析构
RefBase::~RefBase()
{
    int32_t flags = mRefs->mFlags.load(std::memory_order_relaxed);
    // 默认是OBJECT_LIFETIME_STRONG
    if ((flags & OBJECT_LIFETIME_MASK) == OBJECT_LIFETIME_WEAK) {
        // 不走这，此处是判断 mWeak等于 0 就删除 影子对象。
        if (mRefs->mWeak.load(std::memory_order_relaxed) == 0) {
            // 弱引用为0 则 删除影子对象mRefs。调用 ~weakref_impl()
            delete mRefs;
        }
    } else {
        // 主要是些日志输出。
    }
    // 将 mRefs 置为 空指针
    const_cast<weakref_impl*&>(mRefs) = nullptr;
}


```

### sp

表示强引用，将实际对象 sp化后，强弱引用计数各加1，sp析构后 引用计数都 减1。默认情况下 强引用计数为0 会使实际对象被delete。

[StrongPointer.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/include/utils/StrongPointer.h;l=31)

```cpp
template<typename T>
class sp {
    
private:
    T* m_ptr; // 对象的指针
}

// 摘录其中一个
template<typename T>
sp<T>::sp(T* other)
        : m_ptr(other) { // sp 持有对象的指针
    if (other) {
        // other的实际对象
        // 调用 RefBase::incStrong，强/弱引用计数都 + 1
        other->incStrong(this);
    }
}
// .....

template<typename T>
sp<T>::~sp() {
    if (m_ptr) // 调用实际对象的 RefBase::decStrong()
        m_ptr->decStrong(this);
}
```

```cpp
// sp构造时调用，使影子对象的强引用计数和弱引用计数都 + 1
void RefBase::incStrong(const void* id) const
{
    // 获取影子对象
    weakref_impl* const refs = mRefs;
    // 原子操作，内部会调用 refs->mWeak.fetch_add() 使弱引用计数 mWeak + 1，
    refs->incWeak(id);
	// release版本是空实现，什么都没做。
    refs->addStrongRef(id);
    // 原子操作，强引用计数 mStrong + 1，并返回修改之前的值
    const int32_t c = refs->mStrong.fetch_add(1, std::memory_order_relaxed);
    if (c != INITIAL_STRONG_VALUE)  {
        // 不是初始值，则表明这个对象已经被强引用过了，不是第一次。
        return;
    }
    check_not_on_stack(this);
    // 减去初始值，得到真实的引用计数
    int32_t old __unused = refs->mStrong.fetch_sub(INITIAL_STRONG_VALUE, std::memory_order_relaxed);
    // 第一次引用时调用。默认空实现，可以重载用于初始化。
    refs->mBase->onFirstRef();
}

// ~sp，析构时调用
// id 并没有什么用，仅在debug时会用到，作为唯一标识。
void RefBase::decStrong(const void* id) const
{
    // 获取影子对象
    weakref_impl* const refs = mRefs;
    // release版本中空实现
    refs->removeStrongRef(id);
    // 强引用计数 - 1
    const int32_t c = refs->mStrong.fetch_sub(1, std::memory_order_release);
	
    if (c == 1) { // 最后一个强引用被释放了
        std::atomic_thread_fence(std::memory_order_acquire);
        // 回调
        refs->mBase->onLastStrongRef(id);
        int32_t flags = refs->mFlags.load(std::memory_order_relaxed);
        if ((flags&OBJECT_LIFETIME_MASK) == OBJECT_LIFETIME_STRONG) {
            // 删除实际对象, 即~RefBase析构将被调用.
            // 在~RefBase中存在判断，实际对象内部的影子对象并没有销毁
            delete this;
            // 若设置了flags = OBJECT_LIFETIME_WEAK，此处会跳过删除，在decWeak中删除。
        }
    }
    // 在这里内部弱引用计数 - 1，并删除了影子对象。
    refs->decWeak(id);
}
```

### wp

表示弱引用，将实际对象 wp 化后，弱引用计数各加1，sp析构后 弱引用计数减1。弱引用计数为0 会使影子对象被delete。

当对象允许由弱生强时，和flags有关一般就是指强引用计数 > 0，可以使用  `wp.promote()`  生成一个 sp。

[RefBase.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/include/utils/RefBase.h;l=595;)

```cpp
template <typename T>
class wp
{
    T*              m_ptr;	// 指向实际对象
    weakref_type*   m_refs;	// 指向影子对象
};

// 构造函数的实现 sp 类似
template<typename T>
wp<T>::wp(const sp<T>& other)
    : m_ptr(other.m_ptr) // wp 赋值为sp.m_ptr，即和sp持有相同的指针
{
    // 存在指针，调用 RefBase::createWeak()，弱引用计数 + 1
    m_refs = m_ptr ? m_ptr->createWeak(this) : nullptr;
}
//
template<typename T>
wp<T>::~wp()
{	// 调用影子对象的 RefBase::weakref_type::decWeak(), 弱引用计数 - 1
    if (m_ptr) m_refs->decWeak(this);
}

```

```cpp
// wp构造时调用，弱引用计数 + 1
RefBase::weakref_type* RefBase::createWeak(const void* id) const
{	
    // 原子操作，内部会调用 refs->mWeak.fetch_add() 使弱引用计数 mWeak + 1，
    mRefs->incWeak(id);
    // 返回 wp
    return mRefs;
}

// ~wp析构时或 ~sp析构时调用，弱引用计数-1 并考虑释放内存
void RefBase::weakref_type::decWeak(const void* id)
{
    // 向下转型，将影子对象强转为 weakref_impl
    weakref_impl* const impl = static_cast<weakref_impl*>(this);
    // release中空实现
    impl->removeWeakRef(id);
    // 弱引用计数 - 1，并返回旧值
    const int32_t c = impl->mWeak.fetch_sub(1, std::memory_order_release);
	// 不是最后一个wp析构，则之间返回。
    if (c != 1) return;
    // c = 1 表示当前是最后 wp调用析构。考虑释放内存。
    atomic_thread_fence(std::memory_order_acquire);

    int32_t flags = impl->mFlags.load(std::memory_order_relaxed);
    if ((flags&OBJECT_LIFETIME_MASK) == OBJECT_LIFETIME_STRONG) {
        // 正常的析构流程
        if (impl->mStrong.load(std::memory_order_relaxed)
                == INITIAL_STRONG_VALUE) {
            // 没有存在过强引用，通常不应该发生，仅记录。
        } else {
            // 在这里 删除影子对象自身
            delete impl;
        }
    } else { 
        impl->mBase->onLastWeakRef(id);
        // 设置了flags = OBJECT_LIFETIME_WEAK 时的流程，在这里删除指向的实际对象，因为在~sp中跳过了。
        delete impl->mBase;
    }
}
```



## 同步技术

### Mutex：互斥

用于多线程访问同一个资源的时候，保证一次只有一个线程能访问该资源。锁的使用将导致从用户态转入内核态。

内部使用 type 来控制是否支持跨进程的线程同步，SHARE表示支持跨进程的场景。

* `Mutex.lock()`：调用后锁定资源，系统保证一次只有一个线程能lock。若之前已经被lock，则会等待，直到unlock。
* `Mutex.unlock()`：释放资源，其他人能够访问。
* `Mutex.trylock()`：尝试锁定资源，更加返回值来判断是否锁定成功。

> `lock()` 和 `unlock()`需要一一对应以免发生死锁。

内部提供了 `AutoLock`来方便的使用Mutex。

* 构造时调用 `lock()`。
* 析构时调用 `unlock()`。

### Condition：条件

用于 某一个线程需要满足一定条件后才能执行的场景。内部使用 type 来控制是否支持跨进程的线程同步，SHARE表示支持跨进程的场景。

* 等待者：需要满足一定条件才能执行的线程。
  * `wait(mutex)`：等待触发条件。内部会先调用 `mutex.unlock()`，然后等待条件触发，触发后再调用 `mutex.lock()`。
  * `waitRelative(mutex,reltime)`：等待触发并设置超时。
* 触发者：触发这个条件的线程。
  * `signal()`：通知条件满足，仅一个会被唤醒。
  * `broadcast()`：唤醒所有。

### 原子操作

原子操作是最小的执行单位，也就是说这个操作绝不会在执行完毕前被任何事情打断。原子操作可以避免锁的使用从而提供效率，但是需要CPU的支持。

例如我们常见的 `i++`操作, i 是全局变量，一般分为三个步骤：

1. 从内存读取数据到寄存器。
2. 将寄存器中的数据递增。
3. 将寄存器的结果写回内存。

这三个步骤在单线程中顺序执行是没有问题的，但是在多线程中则可能由于线程调度的问题导致出现问题。

* 线程A 执行了 步骤 1，读取了数据。
* 然后调度到线程B，B执行了 1、2、3修改了i。
* 调度回线程A，此时继续执行2、3。注意此时A中的数据还是之前读取的旧数据。
* 最终结果就是执行了2次++但是，i仅增加了1。

## TLS

TLS 是为每个线程提供了一块空间，用以 `kv`的格式存储变量，并且这块空间线程间是不共享的，是每个线程所私有的存储空间，所以多线程访问也不存在数据竞争，不会相互影响。

为什么要用TLS?

主要是因为在Linux的进程和线程模型中，同一个进程内的多个线程共享进程的地址空间，因此不同线程间共享一个全局变量和静态变量。所以一个线程修改后也会影响到其他线程，并且使用全局变量是为了保证安全，往往需要锁来控制，成本也比较高。

但是一个模块中我们可能会需要一些全局变量来存储数据，但是又不希望线程之间互相影响，基于这个场景操作系统就提供了 TLS机制。

TLS 将数据和线程关联起来，提供了一个全局的索引表存储线程局部数据的地址，可以通过 `pthread_key_t` 去查询数据。
