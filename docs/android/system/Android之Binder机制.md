---

layout: post
title: "Binder篇"
date: 2018-04-17
categories: android

---


---

# Binder篇

## 参考资料

本文中的部分图片和解读说明摘自以下参考资料。

### 书籍

- **<< Android的设计与实现：卷I >> 杨云君　著**
- **<< 深入理解Android: 卷I >>**

### 链接

* [Android系统开篇][Android系统开篇]
* [为什么Android要采用Binder作为IPC机制][为什么Android要采用Binder作为IPC机制]
* [Linux设备驱动之字符设备驱动][Linux设备驱动之字符设备驱动]
* [Linux字符设备驱动框架][Linux字符设备驱动框架]
* [Linux 的虚拟文件系统][Linux 的虚拟文件系统]
* [设备与驱动的关系以及设备号、设备文件][设备与驱动的关系以及设备号、设备文件]
* [图解Android - Binder 和 Service][图解Android - Binder 和 Service]
* [线程局部存储][线程局部存储]


## 必须了解的一些概念

### Unix/Linux 一切皆是文件

**“一切皆是文件”是 Unix/Linux的基本哲学之一，所有的一切都是通过文件的形式来进行访问和管理，即使不是文件也被抽象成文件的形式。**包括一般的数据文件、程序普通文件、目录、套接字，**设备文件**等。

Linux的内核中大量使用"注册+回调"机制进行驱动程序的编写。

### 设备驱动和设备文件

设备可以分为以下三类：对于字符设备和块设备来说，在`/dev`目录下都有对应的设备文件，通过这些设备文件来操作设备。

- **字符设备(无缓冲)**：只能一个字节一个字节的读写的设备，不能随机读取设备内存中的某一数据，读取数据需要按照先后顺序进行。字符设备是面向流的设备。常见的字符设备如鼠标、键盘、串口、控制台、LED等外设。
- **块设备(有缓冲)**：是指可以从设备的任意位置读取一定长度的数据设备。块设备如硬盘、磁盘、U盘和SD卡等存储设备。
- **网络设备**：网络设备比较特殊，不在是对文件进行操作，而是由专门的网络接口来实现。应用程序不能直接访问网络设备驱动程序。在/dev目录下也没有文件来表示网络设备。

![image-20230301203221532](./Android%E4%B9%8BBinder%E6%9C%BA%E5%88%B6.assets/image-20230301203221532.png)

#### **设备驱动**

**每种设备类型都有与之相对应的设备驱动程序，它是内核的组成部分**。驱动程序创建了一个硬件与硬件或硬件与软件沟通的接口，经由主板上的总线(bus)或其它沟通子系统(subsystem)与硬件形成连接的机制来处理设备的所有IO请求。

#### **设备文件**

**用户程序需要通过设备文件来使用驱动程序进而操作字符设备和块设备，可以认为是设备驱动的接口**。系统中的一个设备对应一个设备文件，这个文件会占用VFS中的一个`inode`。设备文件并不使用数据块，因此设备文件也就没有大小，在设备文件中，inode中文件大小这个字段存放的是访问设备的设备号。设备文件位于`/dev`目录下，它的参数包括：设备文件名、设备类型、主设备号及次设备号。

但是由于外设的种类较多，操作方式各不相同，所以**Linux为所有的设备文件提供了统一的操作函数接口**，使用`struct file_operations`这一数据结构，它是文件层次的I/O接口，包括许多操作函数的指针：如`open()`、`close()`、`read()`、`write()`和用于控制的`ioctl()`等，从而隐藏了设备操作的差异性。这样，应用程序根本不必考虑操作的是设备还是普通文件，可一律当作文件处理，具有非常清晰统一的I/O接口。

我们操作一个设备文件的流程如下：

1. **寻找索引节点(inode)**：通过虚拟文件系统(VFS) 找到相应的`inode`。
2. **执行open()函数（其他函数同理）**：执行创建这个设备文件时注册在inode中的open()函数，对于各种设备文件，最终调用各自驱动程序中的I/O函数进行具体设备的操作。

当设备打开（open）时，内核利用主设备号分派执行相应的驱动程序，次设备号只由相应的设备驱动程序使用。例如一个嵌入式系统，有两个LED指示灯，LED灯需要独立的打开或者关闭。那么，可以写一个LED灯的字符设备驱动程序，将其主设备号注册成5号设备，次设备号分别为1和2。这里，次设备号就分别表示两个LED灯。所以，为了让我们写的驱动能够正常的被应用程序操作，需要做以下几件事：

1. 实现相应的方法。
2. 创建相应的设备文件。



---

### 系统调用(system call)

指运行在使用者空间的程序向操作系统内核请求需要更高权限运行的服务。系统调用提供了用户程序与操作系统之间的接口。

大多数系统交互式操作需求在内核态执行，如设备IO操作或者进程间通信。

常见的系统调用有以下几个：

- **open** ：打开设备文件, 以便访问驱动程序。
- **mmap** ：将设备文件映射到进程的虚拟地址空间。
- **ioctl** ：如果需要扩展新的功能，通常以增设`ioctl()`命令的方式实现，类似于拾遗补漏.
- **fcontl** ：根据文件描述词来操作文件的特性

### C/S体系结构体会一下

- **用户端(Client)** : 是C/S体系结构中使用Server端提供的Service的一方
- **服务端(Server)** : 是C/S体系结构中为Client端提供Service的一方
- **服务代理(Proxy):** 位于Client端, 提供访问服务的接口。主要作用是屏蔽用户端和Server端通讯的细节, 如对请求数据的序列化和对响应数据的反序列化、通信协议的处理等。
- **服务(Service):** 运行在Server端，提供具体的功能处理Client端的请求。
- **服务存根(Stub)**: 可以看作是Service的代理。位于Server端, 屏蔽了Proxy和Service端通信的细节, 对Client端Proxy请求数据的反序列化和对Server端响应数据的序列化、通信协议的封装和处理、匹配Client端调用Service的具体方法。
- **通信协议**：Client端和Server端可以运行于不同的进程中，甚至可以在不同的主机中，因此需要提供远程通信功能。在Android中，主要使用Binder作为Client端与Server端通信的协议。

Android中Binder的体系结构：

| C/S体系结构术语   | Android层 | Native层 |
| ----------------- | --------- | -------- |
| 通信协议          | Binder    | Binder   |
| Client（客户端）  |           |          |
| Server（服务端）  |           |          |
| Proxy（服务代理） |           |          |
| Stub（服务存根）  |           |          |
| Service（服务）   |           |          |
|                   |           |          |





## 一、 初窥Binder

### 1.1 什么是Binder

Android使用的是Linux的进程管理机制，以进程为单位分配虚拟地址空间。

为了安全考虑，一个进程禁止直接与其他进程交互, 也就是**不同进程之间是相互隔离的(Process Isolation)**。

这时候如果需要进行通信，就必须通过Linux内核提供的**进程间通讯(Inter Process Communication, IPC)**。

常见的IPC方式有以下这些：

- **Socket(套接字)** ： 是一种通用接口，主要用于不同机器或跨网络的通信。**Android 中Zygote使用Socket进行通信。**
  - 数据需要拷贝两次，传输效率低。
- **Signal(信号)** ： 适用于进程中断控制，比如非法内存访问，杀死某个进程等。Android中也使用signal机制，如Kill Process。
  - 不适用于信息交换。
- **Pipe(管道)** ： 在创建时分配一个page大小的内存。
  - 缓存区大小比较有限。
  - 数据需要拷贝两次
- **Message Queue(消息队列)** ： 不合适频繁或信息量大的通信。
  - 数据需要拷贝两次，额外的CPU消耗。
- **Semaphore(信号量)** : 常作为一种锁机制，防止某进程正在访问共享资源时，其他进程也访问该资源。
  - 主要作为进程间以及同一进程内不同线程之间的**同步手段**。
- **Shared Memory(共享内存)** : 
  - **数据无需拷贝**，共享缓冲区直接附加到进程虚拟地址空间，**速度快**；
  - **实现方式复杂**，需要考虑到访问临界资源的并发同步问题，**进程间的同步问题**必须各进程利用同步工具解决，
- ....等等

但是这些IPC要么效率低下，要么不适合封装给上层使用, 所以在Android 中并没有大规模使用，取而代之的使用**Binder**。

- Binder是Android对Linux内核层的一个扩展，属于字符设备驱动。主要包括以下操作：
  - `binder_init`：初始化驱动设备。
  - `binder_open`：打开驱动设备。
  - `binder_mmap`：映射内存。
  - `binder_ioctl`：数据操作。

- **Binder仅需要一次数据拷贝，仅次于共享内存**。
- 为了便于上层使用，Android通过对Binder的封装，在**Native层** 和 **Java层**分别提供一套操作Binder的C/S框架。
  - Java层：`ActivityManagerService(Binder)`作为Server，`ActivityManager(BinderProxy)`作为Client。
  - Native层：`MediaPlayService(BBinder)`作为Server，`MediaPlay(BpBinder)`作为Client。



### 1.2 ServiceManager

![image_1cbjv1brnoa21sc21coacpb1rtrm.png-187.2kB][C/S和ServiceManager]

在Android的C/S体系结构中增加了一个额外的组件**ServiceManager**, 提供了**Service注册**和**Service检索**功能。

* **ServiceManager 是由 init 启动的进程**：它优先于其他服务启动，相当于C/S体系结构中的Server。对应可执行程序名为`/system/bin/servicemanager`，其程序入口为`service_manager.c`。
* **ServiceManager 中维护了一个Service信息的列表(`svclist`)**：Service在启动过程中将自身信息注册到ServiceManager中。当Client要使用服务时，只需向ServiceManager提供所需Service的名字便可获取Service信息。
* **ServiceManager 还维护了一个Binder通讯的上下文管理者(context manager)**。


```c
service servicemanager /system/bin/servicemanager
    class core 		# 类型为core，将由boot Action启动
    user system 	# 属于system用户
    group system	# 属于system组
    critical		# critical服务, 异常退出后盖服务需要重启
    # servicemanager 重启会导致以下服务重启
    onrestart restart healthd 	
    onrestart restart zygote
    onrestart restart media
    onrestart restart surfaceflinger
    onrestart restart drm
```
- main

```c
void *svcmgr_handle;
/**
 * 1. 初始化Binder通信环境，打开Binder设备并映射共享内存
 * 2. 将自身注册为上下文管理者
 * 3. 进入无限循环等待接收并处理IPC通信请求
 */
int main(int argc, char **argv)
{
    struct binder_state *bs;
    // #define BINDER_SERVICE_MANAGER ((void*) 0)
    void *svcmgr = BINDER_SERVICE_MANAGER;
    // 打开Binder设备, 映射共享内存用于接收IPC通信数据, 申请的内存为128k
    bs = binder_open(128*1024);
    // 将service_manager注册为context manager
    if (binder_become_context_manager(bs)) {
        return -1;
    }
    svcmgr_handle = svcmgr;
    // 进入无限循环等待接受IPC通信数据
    binder_loop(bs, svcmgr_handler);
    return 0;
}
```

#### 1.2.1 Binder的初始化(binder_open)

由于进程的地址空间是彼此的隔离的，但是内核空间是可以共享的，因此要实现进程间通信，可以在内核中开辟缓冲区保存进程间通信数据，以此来实现共享内存。
1. ServiceManager调用`binder_open()`**初始化Binder通信环境**。(frameworks/base/cmds/service_manager/binder.c)
2. `binder_open()` 借助**binder_state结构体来保存open和mmap系统调用的返回信息**。
3. **open系统调用**打开Binder设备文件, 以便访问Binder驱动程序。导致Binder驱动的binder_open函数被调用。(kernel/drivers/staging/android/binder.c)
4. **mmap系统调用**将Binder设备文件映射到进程的虚拟地址空间, 并通知Binder驱动程序在内核空间创建128KB的缓冲区来保存IPC数据。从而进程空间的某个内存区域和内核空间的某个内存区域建立了映射关系，当前进程的servicemanager可以利用内核缓冲区共享数据。

```c
/**
 * 保存open和mmap系统调用的返回信息
 */
struct binder_state
{
    int fd;         // open系统调用返回的文件描述符
    void *mapped;   // mmap系统调用 返回的映射区的起始地址
    unsigned mapsize;   // 映射区大小
};
```

```c
/**
 * 1. 创建binder_state类型结构体 bs，并分配内存
 * 2. 通过open系统调用以读写方式方式打开设备文件
 * 3. 通过mmap系统调用将设备文件映射到当前进程的虚拟地址空间
 */
struct binder_state *binder_open(unsigned mapsize)
{
    // 创建binder_state类型结构体 bs，并分配内存
    struct binder_state *bs;
    bs = malloc(sizeof(*bs));
    if (!bs) {
        errno = ENOMEM;
        return 0;
    }
    // 通过open系统调用以 读写方式 打开设备文件
    bs->fd = open("/dev/binder", O_RDWR);
    if (bs->fd < 0) {
        goto fail_open;
    }
    // 通过mmap系统调用将设备文件映射到当前进程的虚拟地址空间
    bs->mapsize = mapsize; // 128KB
    bs->mapped = mmap(NULL, mapsize, PROT_READ, MAP_PRIVATE, bs->fd, 0);
    if (bs->mapped == MAP_FAILED) {
        fprintf(stderr,"binder: cannot map device (%s)\n",
                strerror(errno));
        goto fail_map;
    }
    return bs;
// 处理错误代码
fail_map:
    // 关闭设备
    close(bs->fd);
fail_open:
    // 回收资源
    free(bs);
    return 0;
}
```

#### 1.2.2 注册上下文管理者(binder_become_context_manager)

打开Binder设备并映射内存后， servicemanage会将自身注册为Binder通信的上下文管理者。

- service_manager.c -> binder_become_context_manager
```c
int binder_become_context_manager(struct binder_state *bs)
{   
    // 调用Linux系统函数ioctl, 向Binder设备发送BINDER_SET_CONTEXT_MGR
    return ioctl(bs->fd, BINDER_SET_CONTEXT_MGR, 0);
}
```

#### 1.2.3 接收并处理IPC通信请求(binder_loop)

servicemanger是一个处理client请求的Server进程。
在其成为context manager之后便可以想要Service组件注册服务的请求和Client组件使用服务的请求。
当Service组件向serviceManager注册服务时，Service组件所在的进程对应servicemanger就是Client。

##### binder_loop

```c
/**
 * 1. 首先调用了binder_write函数。传入BC_ENTER_LOOPER指令,标记当前线程进入Binder Looper状态。
 * 2. 之后进入循环从Binder驱动中读取数据并处理数据。
 * [*bs] : binder_state
 * [func] : binder_handler ???
 */
void binder_loop(struct binder_state *bs, binder_handler func)
{
    int res;
    // 定义binder_write_read结构体，发送BINDER_WRITE_READ指令时使用。
    struct binder_write_read bwr;
    unsigned readbuf[32];
    bwr.write_size = 0;
    bwr.write_consumed = 0;
    bwr.write_buffer = 0;
    // BC_ENTER_LOOPER是Binder协议中的Binder Command指令,BC_为前缀。
    readbuf[0] = BC_ENTER_LOOPER;
    // 表示标记当前线程进入Binder Looper状态。
    binder_write(bs, readbuf, sizeof(unsigned));
    // 进入循环
    for (;;) {
        bwr.read_size = sizeof(readbuf);
        bwr.read_consumed = 0;
        bwr.read_buffer = (unsigned) readbuf;
        // 调用ioctl进入BINDER_WRITE_READ分支。
        // 由于write_size = 0, read_size > 0 将会调用binder_thread_read
        // 该函数用于从Binder驱动中读取IPC请求数据，从驱动层返回出来。
        res = ioctl(bs->fd, BINDER_WRITE_READ, &bwr);
        if (res < 0) {
            LOGE("binder_loop: ioctl failed (%s)\n", strerror(errno));
            break;
        }
        // 处理Binder请求。
        res = binder_parse(bs, 0, readbuf, bwr.read_consumed, func);
        if (res == 0) {
            LOGE("binder_loop: unexpected reply?!\n");
            break;
        }
        if (res < 0) {
            LOGE("binder_loop: io error %d %s\n", res, strerror(errno));
            break;
        }
    }
}
```

##### binder_write

```c
/**
 * binder_ioctl函数被调用，进入BINDER_WRITE_READ分支
 * 本次调用将会根据进程在用户空间设置bwr.write_size值，进入binder_thread_write函数
 * [*bs] : binder_state
 * [*data] : readbuf 存储了指令
 * [len] : sizeof()计算某种符号所占的字节数, 这里应该是data的size吧
 */
int binder_write(struct binder_state *bs, void *data, unsigned len)
{
    struct binder_write_read bwr;
    int res;
    bwr.write_size = len;
    bwr.write_consumed = 0;
    bwr.write_buffer = (unsigned) data;
    bwr.read_size = 0;
    bwr.read_consumed = 0;
    bwr.read_buffer = 0;
    // 传入指令BINDER_WRITE_READ
    res = ioctl(bs->fd, BINDER_WRITE_READ, &bwr);
    if (res < 0) {
        fprintf(stderr,"binder_write: ioctl failed (%s)\n",
                strerror(errno));
    }
    return res;
}
```

##### binder_parse

```c
/**
 * 在上次ioctl调用读取到IPC后，对返回数据进行解析
 * Binder驱动层可以返回多种BR指令给servicemanger， 其中BR_TRANSACTION指令用于注册和检索service。
 * func参数由svcmgr_handler指定, Binder驱动层的BR_TRANSACTION指令由它处理。
 */
int binder_parse(struct binder_state *bs, struct binder_io *bio,
                 uint32_t *ptr, uint32_t size, binder_handler func)
{
    int r = 1;
    uint32_t *end = ptr + (size / 4);

    while (ptr < end) {
        uint32_t cmd = *ptr++; // 读取BR指令
        switch(cmd) {
        case BR_NOOP:
            break;
        case BR_TRANSACTION_COMPLETE:
            break;
        case BR_INCREFS:
        case BR_ACQUIRE:
        case BR_RELEASE:
        case BR_DECREFS:
            ptr += 2;
            break;
        case BR_TRANSACTION: {
            struct binder_txn *txn = (void *) ptr;
            if ((end - ptr) * sizeof(uint32_t) < sizeof(struct binder_txn)) {
                LOGE("parse: txn too small!\n");
                return -1;
            }
            binder_dump_txn(txn);
            if (func) {
                unsigned rdata[256/4];
                struct binder_io msg; // Binder驱动发送给当前进程的IPC数据
                struct binder_io reply; // 要写入Binder驱动的IPC数据
                int res;
                // 初始化
                bio_init(&reply, rdata, sizeof(rdata), 4);
                bio_init_from_txn(&msg, txn);
                // 调用func处理BR_TRANSACTION，处理结果保存在reply中
                res = func(bs, txn, &msg, &reply);
                // 处理结果返回给Binder程序
                binder_send_reply(bs, &reply, txn->data, res);
            }
            ptr += sizeof(*txn) / sizeof(uint32_t);
            break;
        }
        case BR_REPLY: {
            struct binder_txn *txn = (void*) ptr;
            if ((end - ptr) * sizeof(uint32_t) < sizeof(struct binder_txn)) {
                LOGE("parse: reply too small!\n");
                return -1;
            }
            binder_dump_txn(txn);
            if (bio) {
                bio_init_from_txn(bio, txn);
                bio = 0;
            } else {
                /* todo FREE BUFFER */
            }
            ptr += (sizeof(*txn) / sizeof(uint32_t));
            r = 0;
            break;
        }
        case BR_DEAD_BINDER: {
            struct binder_death *death = (void*) *ptr++;
            death->func(bs, death->ptr);
            break;
        }
        case BR_FAILED_REPLY:
            r = -1;
            break;
        case BR_DEAD_REPLY:
            r = -1;
            break;
        default:
            LOGE("parse: OOPS %d\n", cmd);
            return -1;
        }
    }
    return r;
}
```

##### svcmgr_handler

```c
/**
 * binder_loop的func参数由此方法指定
 * servicemanager在接收到Binder驱动层的BR_TRANSACTION指令后, 由该函数处理。
 * 1. do_find_service : Client端的getService
 * 2. do_add_service : Client段的addService
 */
int svcmgr_handler(struct binder_state *bs,
                   struct binder_txn *txn,
                   struct binder_io *msg,
                   struct binder_io *reply)
{
    struct svcinfo *si;
    uint16_t *s;
    unsigned len;
    void *ptr;
    uint32_t strict_policy;
    // 检查Binder驱动层传递的txn->targer
    if (txn->target != svcmgr_handle)
        return -1;
    // 读取并校验传递过来的IPC数据
    strict_policy = bio_get_uint32(msg);
    s = bio_get_string16(msg, &len);
    if ((len != (sizeof(svcmgr_id) / 2)) ||
        memcmp(svcmgr_id, s, sizeof(svcmgr_id))) {
        fprintf(stderr,"invalid id %s\n", str8(s));
        return -1;
    }
    // Binder驱动在接收到添加或者检索的Service的请求后，会在txn->code中记录相应的请求 
    switch(txn->code) {
    case SVC_MGR_GET_SERVICE: // 对应客户端的getService
    case SVC_MGR_CHECK_SERVICE:
        // 与Parcel的处理方式类似, 在连续的buffer内存中,顺序读取流
        s = bio_get_string16(msg, &len);
        // 查找service
        ptr = do_find_service(bs, s, len);
        // 没有找到则跳出
        if (!ptr)
            break;
        // 找到则放入reply中 binder_io->data(binder_object)->pointer
        bio_put_ref(reply, ptr);
        return 0;
    case SVC_MGR_ADD_SERVICE: // 对应客户端的addService
        s = bio_get_string16(msg, &len);
        ptr = bio_get_ref(msg);
        if (do_add_service(bs, s, len, ptr, txn->sender_euid))
            return -1;
        break;
    case SVC_MGR_LIST_SERVICES: { // 遍历检索services
        unsigned n = bio_get_uint32(msg);
        si = svclist;
        while ((n-- > 0) && si)
            si = si->next;
        if (si) {
            bio_put_string16(reply, si->name);
            return 0;
        }
        return -1;
    }
    default:
        LOGE("unknown code %d\n", txn->code);
        return -1;
    }
    bio_put_uint32(reply, 0);
    return 0;
}
```

- do_add_service

```c
int do_add_service(struct binder_state *bs,
                   uint16_t *s, unsigned len,
                   void *ptr, unsigned uid)
{
    struct svcinfo *si;
    if (!ptr || (len == 0) || (len > 127))
        return -1;
    // 验证该UID是否具备添加服务的权限。
    // root和system用户以及在allowed结构体数组中定义的
    if (!svc_can_register(uid, s)) {
        LOGE("add_service('%s',%p) uid=%d - PERMISSION DENIED\n",
             str8(s), ptr, uid);
        return -1;
    }
    // 从svclist(服务列表)中查询是否已经注册过该服务
    si = find_svc(s, len);
    if (si) { // 已注册
        if (si->ptr) {
            LOGE("add_service('%s',%p) uid=%d - ALREADY REGISTERED, OVERRIDE\n",
                 str8(s), ptr, uid);
            svcinfo_death(bs, si);
        }
        si->ptr = ptr;
    } else {
        // 给新注册的服务分配内存, 并放入到svclist头部
        si = malloc(sizeof(*si) + (len + 1) * sizeof(uint16_t));
        if (!si) { // 分配内存OOM
            LOGE("add_service('%s',%p) uid=%d - OUT OF MEMORY\n",
                 str8(s), ptr, uid);
            return -1;
        }
        si->ptr = ptr;
        si->len = len;
        memcpy(si->name, s, (len + 1) * sizeof(uint16_t));
        si->name[len] = '\0';
        si->death.func = svcinfo_death;
        si->death.ptr = si;
        si->next = svclist;
        svclist = si;
    }
    // 接收Binder设备发送的服务退出通知，清理一些资源
    binder_acquire(bs, ptr);
    binder_link_to_death(bs, ptr, &si->death);
    return 0;
}
```

- do_find_service

```c
/**
 * 从svclist中检索服务并返回
 */
void *do_find_service(struct binder_state *bs, uint16_t *s, unsigned len)
{
    struct svcinfo *si;
    // 从svclist中检索服务
    si = find_svc(s, len);
    if (si && si->ptr) {
        // 返回
        return si->ptr;
    } else {
        return 0;
    }
}
```


## 二、乱挖Binder驱动层


kernel/drivers/staging/android/binder.c


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

## 三、分析MediaServer的启动和注册

Native System Service大多数由init和SystemServer的init1阶段启动。
这里以init.rc中配置的media服务为例,分析Server启动和Service注册。
对应的可执行文件是 /system/bin/mediaserver
mediaserver的main函数位于 frameworks/av/media/mediaserver/main_mediaserver.cpp中

- main_mediaserver.cpp

```c
/**
 * 1. 创建ProcessState对象
 * 2. 获取servicemanager的代理对象
 * 3. 运行并注册server
 * 4. Server进程开启线程池
 */
int main(int argc, char** argv)
{
    // 创建ProcessState对象，赋值给proc变量
    sp<ProcessState> proc(ProcessState::self());
    // 获取servicemanager的代理对象
    sp<IServiceManager> sm = defaultServiceManager();
    LOGI("ServiceManager: %p", sm.get());
    // 运行并注册AudioFlinger服务
    AudioFlinger::instantiate();
    // 运行并注册MediaPlayerService服务
    MediaPlayerService::instantiate();
    // 运行并注册CameraService服务
    CameraService::instantiate();
    // 运行并注册AudioPolicyService服务
    AudioPolicyService::instantiate();
    // Server进程开启线程池
    ProcessState::self()->startThreadPool();
    // 添加线程
    IPCThreadState::self()->joinThreadPool();
}
```

### 3.1 ProcessState.cpp


#### ProcessState::self()

1. 构建ProcessState对象
2. 通过fcntl系统调用打开Binder设备。
3. 调用mmap系统调用将Binder设备映射到进程的地址空间。

```c
/**
 * self()是一个构建单例的方法
 * 保证当前进程只有一个ProcessState对象。
 */
sp<ProcessState> ProcessState::self()
{
    if (gProcess != NULL) return gProcess;
    AutoMutex _l(gProcessMutex);
    if (gProcess == NULL) gProcess = new ProcessState;
    return gProcess;
}
```

```c
/**
 * 和servicemanager的binder_open函数类似。
 * 1. 首先通过open_drive()函数打开Binder设备，初始化mDriverFD
 * 2. 通过mmap系统调用将Binder设备映射到进程的地址空间
 */
ProcessState::ProcessState()
    : mDriverFD(open_driver()) // 在初始化列表中打开Binder设备
    , mVMStart(MAP_FAILED)
    , mManagesContexts(false)
    , mBinderContextCheckFunc(NULL)
    , mBinderContextUserData(NULL)
    , mThreadPoolStarted(false)
    , mThreadPoolSeq(1)
{
    if (mDriverFD >= 0) {
#if !defined(HAVE_WIN32_IPC)
        // 通过mmap系统调用将Binder设备映射到进程空间
        mVMStart = mmap(0, BINDER_VM_SIZE, PROT_READ, MAP_PRIVATE | MAP_NORESERVE, mDriverFD, 0);
        if (mVMStart == MAP_FAILED) {
            // *sigh*
            LOGE("Using /dev/binder failed: unable to mmap transaction memory.\n");
            close(mDriverFD);
            mDriverFD = -1;
        }
#else
        mDriverFD = -1;
#endif
    }
    LOG_ALWAYS_FATAL_IF(mDriverFD < 0, "Binder driver could not be opened.  Terminating.");
}
```

#### open_device()

```c
/**
 * 1. 通过open系统调用打开binder设备, 返回文件描述符用于调用ioctl指令。
 * 2. BINDER_VERSION命令获取Binder协议版本号。
 * 3. BINDER_SET_MAX_THREADS设置当前server线程池上线。
 */
static int open_driver()
{
    // 一样的套路打开/dev/binder设备节点来用于Binder驱动程序,返回文件描述符
    int fd = open("/dev/binder", O_RDWR);
    if (fd >= 0) {
        // 通过fcontl,对fd设置文件描述符号标记。
        // F_SETFD是设置文件描述符标记的命令
        // FD_CLOEXEC是新的标记值，表示当前进程执行exec系列函数时，将会关闭fd
        fcntl(fd, F_SETFD, FD_CLOEXEC);
        int vers;
        // 向Binder驱动发送BINDER_VERSION命令获取Binder协议版本号,存入&vers
        status_t result = ioctl(fd, BINDER_VERSION, &vers);
        if (result == -1) {
            LOGE("Binder ioctl to obtain version failed: %s", strerror(errno));
            close(fd);
            fd = -1;
        }
        // 比较版本是否一致
        if (result != 0 || vers != BINDER_CURRENT_PROTOCOL_VERSION) {
            LOGE("Binder driver protocol does not match user space protocol!");
            close(fd);
            fd = -1;
        }
        size_t maxThreads = 15;
        // 向Binder驱动发送BINDER_SET_MAX_THREADS命令。
        // 设置当前server线程池上线，支持客户端最大并发访问数为15。
        result = ioctl(fd, BINDER_SET_MAX_THREADS, &maxThreads);
        if (result == -1) {
            LOGE("Binder ioctl to set max threads failed: %s", strerror(errno));
        }
    } else {
        LOGW("Opening '/dev/binder' failed: %s\n", strerror(errno));
    }
    return fd;
}
```

#### getContextObject()

```c
/**
 * 返回上下文管理者对应的BpBinder(服务代理对象)
 */
sp<IBinder> ProcessState::getContextObject(const sp<IBinder>& /*caller*/)
{
    return getStrongProxyForHandle(0);
}

/**
 * 1. 查找是否存在对应的handle_entry
 * 2. handle == 0表示上下文管理器特殊处理
 * 3. 不存在则创建一个BpBinder(handle)
 */
sp<IBinder> ProcessState::getStrongProxyForHandle(int32_t handle)
{
    sp<IBinder> result;
    AutoMutex _l(mLock);
    // 查找是否存在对应的handle_entry
    handle_entry* e = lookupHandleLocked(handle);
    if (e != NULL) {
        // 如果当前不存在 或者我们不能在当前entry中获取到weak reference(应该是表示被回收吧)
        // 则创建一个新的BpBinder
        IBinder* b = e->binder;
        if (b == NULL || !e->refs->attemptIncWeak(this)) {
            if (handle == 0) {
                //上下文管理器的特殊情况…
                //上下文管理器是我们创建BpBinder代理的唯一对象，但没有包含引用。
                //执行一个虚拟事务，以确保在创建第一个本地引用之前注册上下文管理器(在创建BpBinder时将会发生)。
                //如果在不存在上下文管理器时为BpBinder创建了本地引用，那么驱动程序将无法提供对上下文管理器的引用，但是驱动程序API不返回状态。
                
                Parcel data;
                status_t status = IPCThreadState::self()->transact(
                        0, IBinder::PING_TRANSACTION, data, NULL, 0);
                if (status == DEAD_OBJECT)
                   return NULL;
            }

            b = new BpBinder(handle); 
            e->binder = b;
            if (b) e->refs = b->getWeakRefs();
            result = b;
        } else {
            // This little bit of nastyness is to allow us to add a primary
            // reference to the remote proxy when this team doesn't have one
            // but another team is sending the handle to us.
            result.force_set(b);
            e->refs->decWeak(this);
        }
    }

    return result;
}

```

### 3.2 BpBinder.cpp

/frameworks/native/libs/binder/BpBinder.cpp

#### 构造函数

```
/**
 * 1. BpBinder初始化列表赋值 mHandle = handle
 * 2. 调用IPCThreadState::self()->incWeakHandle(handle)
 */
BpBinder::BpBinder(int32_t handle)
    : mHandle(handle)
    , mAlive(1)
    , mObitsSent(0)
    , mObituaries(NULL)
{
    ALOGV("Creating BpBinder %p handle %d\n", this, mHandle);
    extendObjectLifetime(OBJECT_LIFETIME_WEAK);
    // 主要就是向输出缓冲区mOut中写入BC_INCREFS 和 handle = 0
    IPCThreadState::self()->incWeakHandle(handle);
}

```

### 3.3 IPCThreadState.cpp

/frameworks/native/libs/binder/IPCThreadState.cpp
TLS(Thread Local Storage, 线程局部存储), 在Linux的进程和线程模型中，同一个进程内的多个线程共享进程的地址空间，因此不同线程可以共享一个全局变量和静态变量。TLS的作用就是一个线程在访问时其他线程不可。它提供了一个全局的索引表存储线程局部数据的地址，通过pthread_key_t去查询其局部数据。

```c
/**
 * 这个方法主要用于获取IPCThreadState
 * 1. gTLS不存在则创建一个，然后goto restart;
 * 2. 根据gTLS查询IPCThreadState, 存在则返回，不存在则创建一个
 */
IPCThreadState* IPCThreadState::self()
{
    if (gHaveTLS) { // TLS存在时, 不过初始是false
restart:
        // const 等同final
        const pthread_key_t k = gTLS;
        // 获取gTLS对应的IPCThreadState
        IPCThreadState* st = (IPCThreadState*)pthread_getspecific(k);
        if (st) return st;        
        return new IPCThreadState;
    }

    if (gShutdown) { // 初始false
        ALOGW("Calling IPCThreadState::self() during shutdown is dangerous, expect a crash.\n");
        return NULL;
    }
    pthread_mutex_lock(&gTLSMutex);
    // TLS不存在是，创建一个pthread_key_create, 重新跳转到restart处
    if (!gHaveTLS) {
        // 创建pthread_key_t : gTLS, 用于设置检索TLS
        int key_create_value = pthread_key_create(&gTLS, threadDestructor);
        if (key_create_value != 0) {
            pthread_mutex_unlock(&gTLSMutex);
            return NULL;
        }
        gHaveTLS = true;
    }
    pthread_mutex_unlock(&gTLSMutex);
    // 跳转到restart
    goto restart;
}
```

```
void IPCThreadState::incWeakHandle(int32_t handle)
{
    LOG_REMOTEREFS("IPCThreadState::incWeakHandle(%d)\n", handle);
	// 向输出缓冲区中写入BC_INCREFS 和 handle = 0
    mOut.writeInt32(BC_INCREFS);
    mOut.writeInt32(handle);
}
```

### 3.4 获取ServiceManager的Proxy对象(BpBinder)
Client端查询服务或者Server端注册服务时，都要首先获取ServiceManager的Proxy对象(`BpBinder`)，然后通过这个代理对象与ServiceManager通信。

![image_1cchrav4k4dvepjpmbvh1cum9.png-372.9kB][ServiceManager的类层次结构]

- **Binder通信接口**： 提供了通信协议的实现，只要有`IBinder`, `BBinder`, `BpBinder`三个类组成。
  - **IBinder**：定义了Binder通信的接口。**描述如何服务进行交互**。
  - **BBinder**：它是Service 对应的Binder对象**，描述如何处理Client的请求**。
  - **BpBinder**：它是**Client端访问BBinder的代理对象**，负责打开Binder设备与服务端通信。

- **Binder服务接口**:  `IServiceManager`定义了Client端可以访问Server端提供的哪些服务。
- **Proxy**: 主要由`BpInterface` 和 `BpServiceManager` 实现。
  - `BpServiceManager`实现了服务接口中生命的方法
  - `BpInterface->mRemote`中存储了Client端创建的`BpBinder`对象。

- **Stub**: 主要有`BnInterface` 和 `BnServiceManger`实现。


#### Static.h

一些全局变量的定义

```c
namespace android {
    // For TextStream.cpp
    extern Vector<int32_t> gTextBuffers;
    // For ProcessState.cpp
    extern Mutex gProcessMutex;
    extern sp<ProcessState> gProcess;
    // For IServiceManager.cpp
    extern Mutex gDefaultServiceManagerLock;
    extern sp<IServiceManager> gDefaultServiceManager;
    extern sp<IPermissionController> gPermissionController;
}
```

#### IServiceManager->defaultServiceManager()

```c
/**
 * 用于获取ServiceManager的Proxy对象(BpBinder)
 * 1. 调用ProcessState::self()->getContextObject(NULL),获取BpBidner
 * 2. 通过Interface_cast()转换成IServiceManager(BpServiceManager)
 */
sp<IServiceManager> defaultServiceManager()
{
    // 定义在Static.h中的全局变量, 从这里看是个单例
    if (gDefaultServiceManager != NULL) return gDefaultServiceManager;
    {
        AutoMutex _l(gDefaultServiceManagerLock);
        while (gDefaultServiceManager == NULL) {
            // interface_cast是在IServiceManager的父类IInterface中定义的
            gDefaultServiceManager = interface_cast<IServiceManager>(
                ProcessState::self()->getContextObject(NULL));
            if (gDefaultServiceManager == NULL)
                sleep(1);
        }
    }
    return gDefaultServiceManager;
}
```

- 调用IMPLEMENT_META_INTERFACE

```
IMPLEMENT_META_INTERFACE(ServiceManager, "android.os.IServiceManager");
```

#### IInterface.cpp

- interface_cast

```c
/**
 * 此时INTERFACE = IServiceManager
 * 所以调用的是IServiceManager::asInterface(obj)
 * 不过IServiceManager和IInterface都没有定义这个方法
 * 而是在宏定义DECLARE_META_INTERFACE中定义
 */
template<typename INTERFACE>
inline sp<INTERFACE> interface_cast(const sp<IBinder>& obj)
{
    return INTERFACE::asInterface(obj);
}
```

- DECLARE_META_INTERFACE

```
// 定义了方法和常量
#define DECLARE_META_INTERFACE(INTERFACE)                               \
    static const android::String16 descriptor;                          \
    static android::sp<I##INTERFACE> asInterface(                       \
            const android::sp<android::IBinder>& obj);                  \
    virtual const android::String16& getInterfaceDescriptor() const;    \
    I##INTERFACE();                                                     \
    virtual ~I##INTERFACE();                                            \
    
    
// 具体的实现
// IServiceManager 中调用这个宏定义(ServiceManager, "android.os.IServiceManager")
// 实质是 new BpServiceManager(obj : BpBinder)
#define IMPLEMENT_META_INTERFACE(INTERFACE, NAME)                       \
    const android::String16 I##INTERFACE::descriptor(NAME);             \
    const android::String16&                                            \
            I##INTERFACE::getInterfaceDescriptor() const {              \
        return I##INTERFACE::descriptor;                                \
    }                                                                   \
    android::sp<I##INTERFACE> I##INTERFACE::asInterface(                \
            const android::sp<android::IBinder>& obj)                   \
    {                                                                   \
        android::sp<I##INTERFACE> intr;                                 \
        if (obj != NULL) {                                              \
            intr = static_cast<I##INTERFACE*>(                          \
                obj->queryLocalInterface(                               \
                        I##INTERFACE::descriptor).get());               \
            if (intr == NULL) {                                         \
                intr = new Bp##INTERFACE(obj);                          \
            }                                                           \
        }                                                               \
        return intr;                                                    \
    }                                                                   \
    I##INTERFACE::I##INTERFACE() { }                                    \
    I##INTERFACE::~I##INTERFACE() { }                                   \

```


### 3.3 注册Service

### 3.4 Server进程开启线程池

## 四、Client端使用服务代理对象

## 五、服务代理和服务通信

## 六、Java层中的Binder



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
[ServiceManager的类层次结构]: http://static.zybuluo.com/zaze/1767giazv6g21m2dvi016g4u/image_1cchrav4k4dvepjpmbvh1cum9.png
[线程局部存储]:http://www.cppblog.com/Tim/archive/2012/07/04/181018.html


[Android启动流程]: http://static.zybuluo.com/zaze/l1yityve5up0dcnq9icxtwjf/image_1cegf6i1jmjmtdbqisgik1mu89.png
