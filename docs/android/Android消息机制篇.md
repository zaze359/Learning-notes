---

layout: post
title:  "Android消息机制篇"
date:   2018-03-29
categories: android

---

Tags : zaze android

[TOC]

* TOC
{:toc}

---

# Android消息机制篇

## 参考资料

以上部分图片和解读说明摘自以下参考资料。

> **<< Android的设计和实现:卷I>>**
> **<<深入理解Android: 卷I>>**


## 0. 消息驱动机制
Android 扩展了线程的退出机制，在启动线程时，在线程内部创建一个消息队列， 然后让线程进入无限循环；
在这个无限循环中，线程会不断的检查消息队列中是否是消息。如果需要执行某个任务，就向线程的消息队列中发送消息，循环检测到有消息到来 便会获取这个消息 进而执行它。如果没有则线程进入等待状态。


### 0.1 一图而窥之

作者太懒, 还在描边中~~

## 1. 浅见Java层


- Looper调用prepare(),在当前执行的线程中生成仅且一个Looper实例，这个实例包含一个MessageQueue对象
- 调用loop()方法,在当前线程进行无限循环，不断从MessageQueue中读取Handler发来的消息。
- 生成Handler实例同时获取到当前线程的Looper对象 
- sendMessage方法, 将自身赋值给msg.target, 并将消息放入MessageQueue中
- 回调创建这个消息的handler中的dispathMessage方法，

```java
/**
 * 构建自己Looper线程，体验消息驱动。(可以直接使用Android 提供的HandlerThread)
 * Looper 线程的特点就是 run方法执行完成之后不会推出 而是进入一个loop消息循环。
 */
class LooperThread extends Thread {
    public Handler mHandler;
    
    public void run() {
        Looper.prepare();
        mHandler = new Handler() {
            public void handleMessage(Message msg) {
                // 处理消息
            }
        };
        Looper.loop();
    }
}
```

```java
/**
 * 穿插一下ThreadLocal(线程局部变量)
 * 实质是线程的变量值的一个副本
 * 而他存取的数据，就是的当前线程的数据
 */
public class ThreadLocal<T> {
    public T get() {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null) {
            ThreadLocalMap.Entry e = map.getEntry(this);
            if (e != null)
                return (T)e.value;
        }
        return setInitialValue();
    }
}
```

### 1.1 消息(Message)

了解一下[Parcelable][Parcelable]和Serializable序列化接口, 号称快10倍, 不过使用相对复杂。

```java
public final class Message implements Parcelable {
    /*消息码, 区分消息类型*/
    public int what;
    ...
    // 表示什么时候执行
    /*package*/ long when;
    ...
    // 存储了下一条消息的引用
    /*package*/ Message next; 
    private static final Object sPoolSync = new Object();
    // 消息池
    private static Message sPool;
    // 消息池当前大小
    private static int sPoolSize = 0;
    private static final int MAX_POOL_SIZE = 10;
    
    /**
     * 获取消息的通用方法
     */
    public static Message obtain() {
        synchronized (sPoolSync) {
            if (sPool != null) {
                // 指向消息的头部
                Message m = sPool;
                // 将消息池头部指向下一条
                sPool = m.next;
                m.next = null;
                // 消息池大小减1
                sPoolSize--;
                // 返回从消息池中取得的消息
                return m;
            }
        }
        // 消息池为空就创建一个消息
        return new Message();
    }
    
    // 实现Parcelable接口的方法, 可以将写入Parcel的对象还原为Message
    public static final Parcelable.Creator<Message> CREATOR  = new Parcelable.Creator<Message>() {
        public Message createFromParcel(Parcel source) {
            Message msg = Message.obtain();
            msg.readFromParcel(source);
            return msg;
        }
        
        public Message[] newArray(int size) {
            return new Message[size];
        }
    };
    
    /**
     * 此处完成了消息池的初始化
     * 使用消息的一方(),只要调用了recycle方法便把会废弃的消息放入消息池中以便重新利用。
     * 放入时这个消息的数据将被清空, 若要使用消息池中的消息, 需要调用obtain方法重新初始化
     */
    public void recycle() {
        clearForRecycle();
        synchronized (sPoolSync) {
            if (sPoolSize < MAX_POOL_SIZE) {
                next = sPool;
                sPool = this;
                sPoolSize++;
            }
        }
    }
    
    /*package*/ void clearForRecycle() {
        flags = 0;
        what = 0;
        arg1 = 0;
        arg2 = 0;
        obj = null;
        replyTo = null;
        when = 0;
        target = null;
        callback = null;
        data = null;
    }
    
}
```

### 1.2 消息循环(Looper)

- prepare()与当前线程绑定。
- loop()方法，循环调用MessageQueue.next()获取消息(消息驱动)，交给Message.target.dispatchMessage分发处理(target指Handler, 在Handler.enqueueMessage中被赋值)。

```java
public class Looper {
    // 定义一个线程局部对象存储Looper对象
    static final ThreadLocal<Looper> sThreadLocal = new ThreadLocal<Looper>();
    final MessageQueue mQueue;
    final Thread mThread;
    
    /**
     * 创建了MessageQueue对象
     * 建立了MessageQueue和NativeMessageQueue的关系
     * 初始化了Native层的Looper
     * 持有当前线程的引用
     */
    private Looper() {
        // 创建了MessageQueue对象
        mQueue = new MessageQueue();
        // 将当前线程状态标记为run
        mRun = true;
        // 存储当前线程
        mThread = Thread.currentThread();
    }
    
    /**
     *  prepare()只能被调用一次, 否则直接抛出异常
     *  Looper对象存入ThreadLocal ,保证一个线程中只有一个Looper
     */
    private static void prepare(boolean quitAllowed) {
        if (sThreadLocal.get() != null) {
            throw new RuntimeException("Only one Looper may be created per thread");
        }
        sThreadLocal.set(new Looper(quitAllowed));
    }
    
    /**
     * loop 必须在prepare()后执行，否则报错
     */
    public static void loop() {
        Looper me = myLooper();
        if (me == null) {
            throw new RuntimeException("No Looper; Looper.prepare() wasn't called on this thread.");
        }
        MessageQueue queue = me.mQueue;
        // 在IPCThreadState中记录当前线程所属的PID 和 UID
        // 了解一下Binder
        Binder.clearCallingIdentity();
        final long ident = Binder.clearCallingIdentity();
        while (true) { 
            // 循环监听获取消息, 可能阻塞
            Message msg = queue.next();
            if (msg != null) {
                if (msg.target == null) {
                    return;
                }
                ......
                // 将获取到的消息交给消息处理器
                msg.target.dispatchMessage(msg);
                ......
                // 将处理过的消息回收并放入到消息池中
                msg.recycle();
            }
        }
    }
}
```

### 1.3 消息队列(MessageQueue)

java层实例化对象时, 同时native层也完成初始化（NativeMessageQueue）
保持了一个按照执行时间排序的消息队列，提供了对消息队列管理的一些api

![image_1c9odn8dlocl1lnh18mkahqbdo9.png-85.5kB][MessageQueue于NativeMessageQueue]


- postSyncBarrier() 同步屏障

[同步屏障][同步屏障]

Android 中的 Message 可以分了 同步消息和异步消息
平时这两种消息没有什么区别, 只有当设置了 同步屏障时才有差异
当设置了同步屏障时, 将会过滤这个同步屏障消息之后执行的所有的同步消息
所以同步屏障相当于一个过滤器，当有需要优先处理的消息时可以设置同步屏障

```java
private int postSyncBarrier(long when) {
    // 插入一条同步屏障消息
    synchronized (this) {
        final int token = mNextBarrierToken++;
        final Message msg = Message.obtain();
        msg.markInUse();
        msg.when = when;
        msg.arg1 = token;

        Message prev = null;
        Message p = mMessages;
        if (when != 0) {
            while (p != null && p.when <= when) {
                prev = p;
                p = p.next;
            }
        }
        if (prev != null) {
            msg.next = p;
            prev.next = msg;
        } else {
            msg.next = p;
            mMessages = msg;
        }
        return token;
    }
}
```

- 构造函数

```java
// 按照执行时间排序的消息队列
Message mMessages;
public class MessageQueue {
    boolean mQuitAllowed = true; // 默认允许推出, 没看到置为false的地方
    private int mPtr; // used by native code

    private native void nativeInit();
    
    MessageQueue() {
        // 执行Native层初始化操作
        nativeInit();
    }
    
}
```

- MessageQueue.enqueueMessage()

```java
final boolean enqueueMessage(Message msg, long when) {
    // 判断消息是否被使用, 新消息一定是未使用, 在next()里面被处理的消息将被标记为FLAG_IN_USE
    if (msg.isInUse()) {
        throw new AndroidRuntimeException(msg + " This message is already in use.");
    }
    // mQuitAllowed默认为true, 没找到设置为false的地方
    if (msg.target == null && !mQuitAllowed) {
        throw new RuntimeException("Main thread not allowed to quit");
    }
    final boolean needWake;
    synchronized (this) {
        if (mQuiting) { // 默认false, 当target(Handler) 所在线程异常退出时置为true
            RuntimeException e = new RuntimeException(
                msg.target + " sending message to a Handler on a dead thread");
            return false;
        } else if (msg.target == null) {
            mQuiting = true;
        }
        // 给新入队消息赋值执行时间
        msg.when = when;
        // 取出消息队列头部
        Message p = mMessages;
        // 对应三种情况（此时需要将新消息插入头部）
        // 1）消息队列为空 
        // 2）新入队消息需要立即执行 
        // 3）新入队消息的执行时间早于消息队列头部消息的执行时间
        if (p == null || when == 0 || when < p.when) {
            msg.next = p;
            mMessages = msg;
            // 有新消息要处理 若之前是阻塞状态则需要唤醒
            needWake = mBlocked;
        } else {
            // 遍历根据执行时间插入到指定位置
            Message prev = null;
            while (p != null && p.when <= when) {
                prev = p;
                p = p.next;
            }
            msg.next = prev.next;
            prev.next = msg;
            // 头部消息没有发生变化 不需要唤醒
            needWake = false;
        }
    }
    if (needWake) {
        // 唤醒
        nativeWake(mPtr);
    }
    return true;
}
```

- MessageQueue.next() --- 源码更新为8.1版本

```java
 Message next() {
    //如果消息循环已经退出并被处理，返回。
    //如果应用程序尝试在退出后重新启动looper，就会发生这种情况。
    final long ptr = mPtr;
    if (ptr == 0) {
        return null;
    }
    int pendingIdleHandlerCount = -1; // IdleHander的数量, 下面有介绍IdleHandler
    int nextPollTimeoutMillis = 0; // 空闲等待时间
    for (;;) {
        if (nextPollTimeoutMillis != 0) {
            Binder.flushPendingCommands();
        }
        // 传入NativeMessageQueue的地址, 和等待时间
        nativePollOnce(ptr, nextPollTimeoutMillis);
        synchronized (this) {
            final long now = SystemClock.uptimeMillis();
            Message prevMsg = null;
            Message msg = mMessages;
            if (msg != null && msg.target == null) {
                // msg.target == null 表示碰到了同步屏障
                // 遍历消息队列直到找到异步消息 或者 直到最后都没有找到
                do {
                    prevMsg = msg;
                    msg = msg.next;
                } while (msg != null && !msg.isAsynchronous());
            }
            if (msg != null) {
                // 当前时间大于消息执行时间，消息队列指向下一条, 将执行的消息标记使用并返回
                if (now < msg.when) {
                    // 未到消息执行时间, 计算到可以执行的时间的时间差
                    nextPollTimeoutMillis = (int) Math.min(msg.when - now, Integer.MAX_VALUE);
                } else {
                    // 标记为不阻塞
                    mBlocked = false;
                    //  移除消息队列头
                    if (prevMsg != null) {
                        // 碰到过同步屏障
                        // prevMsg表示最后一条同步消息
                        // prevMsg.next()等同于mMessages
                        prevMsg.next = msg.next;
                    } else {
                        // 没有碰到同步屏障是为null
                        mMessages = msg.next;
                    }
                    msg.next = null;
                    // 消息标记为已使用
                    msg.markInUse();
                    return msg;
                }
            } else {
                nextPollTimeoutMillis = -1;
            }
            if (mQuitting) {
                dispose();
                return null;
            }
            // 当前时间空闲, 看看有没有IdleHandler需要执行， 若没有则将当前线程状态设置为阻塞
            if (pendingIdleHandlerCount < 0
                    && (mMessages == null || now < mMessages.when)) {
                pendingIdleHandlerCount = mIdleHandlers.size();
            }
            if (pendingIdleHandlerCount <= 0) {
                mBlocked = true;
                continue;
            }
            if (mPendingIdleHandlers == null) {
                mPendingIdleHandlers = new IdleHandler[Math.max(pendingIdleHandlerCount, 4)];
            }
            mPendingIdleHandlers = mIdleHandlers.toArray(mPendingIdleHandlers);
        }
        // 处理空闲消息
        for (int i = 0; i < pendingIdleHandlerCount; i++) {
            final IdleHandler idler = mPendingIdleHandlers[i];
            mPendingIdleHandlers[i] = null; // release the reference to the handler
            boolean keep = false;
            try {
                keep = idler.queueIdle();
            } catch (Throwable t) {
                Log.wtf(TAG, "IdleHandler threw exception", t);
            }
            if (!keep) {
                synchronized (this) {
                    mIdleHandlers.remove(idler);
                }
            }
        }
        pendingIdleHandlerCount = 0;
        nextPollTimeoutMillis = 0;
    }
}
```

### 1.4 消息处理器(Handler)

Handle是Looper线程的消息处理器, 承担了发送消息和处理消息两部分工作。

- 构造函数

```java
final MessageQueue mQueue;
final Looper mLooper;
final Callback mCallback;
IMessenger mMessenger; // 用于跨进程发送消息
public Handler() {
    ....
    // 将 Looper、MessageQueue和Handler关联到一起
    mLooper = Looper.myLooper();4
    if (mLooper == null) {
    // 必须调用Looper.prepare()后才能使用
        throw new RuntimeException(
            "Can't create handler inside thread that has not called Looper.prepare()");
    }
    mQueue = mLooper.mQueue;
    mCallback = null;
}
```


- Handler.post(new Runnable())

实际是发送了一条消息,此处的Runnable并没有创建线程，只是作为一个callback使用

```java
public final boolean post(Runnable r){
   return  sendMessageDelayed(getPostMessage(r), 0);
}

private static Message getPostMessage(Runnable r) {
    Message m = Message.obtain();
    m.callback = r;
    return m;
}
```

- Handler.sendMessageAtTime()

将自身赋值给msg.target, 并将消息放入MessageQueue中

```java
/**
 * uptimeMillis 表示何时处理这个消息
 */
public boolean sendMessageAtTime(Message msg, long uptimeMillis){
    boolean sent = false;
    MessageQueue queue = mQueue;
    if (queue != null) {
        // 将当前的Handler 指定为处理消息的目标端
        msg.target = this;
        // 入队
        sent = queue.enqueueMessage(msg, uptimeMillis);
    }
    else {
        RuntimeException e = new RuntimeException(
            this + " sendMessageAtTime() called with no mQueue");
        Log.w("Looper", e.getMessage(), e);
    }
    return sent;
}
```

- **Handler.dispatchMessage()消息分配**

以下源码可以看出, 当使用post()发送消息时, 最后会调用runnable.run()回调。sendMessage()则是执行handleMessage()， 这个就是我们构建对象时重写的方法

```java
public void dispatchMessage(Message msg) {  
    if (msg.callback != null) {  
        handleCallback(msg);  
    } else {  
        if (mCallback != null) {  
            if (mCallback.handleMessage(msg)) {  
                return;  
            }  
        }  
        handleMessage(msg);  
    }  
}
private static void handleCallback(Message message) {
    message.callback.run();
}
```

## 2. 深入native层


### 2.1 Looper.cpp

Java层的Looper主要是负责从MessageQueue中循环读取消息分发给Handler处理
Native层Looper主要是负责监听ReadPipe(读管道)，发送消息(Java中是由Handler处理的)

- 构造函数

```c
Looper::Looper(bool allowNonCallbacks) :
        mAllowNonCallbacks(allowNonCallbacks), mSendingMessage(false),
        mResponseIndex(0), mNextMessageUptime(LLONG_MAX) {
    int wakeFds[2];
    // 创建一个管道
    int result = pipe(wakeFds);
    // 管道读端
    mWakeReadPipeFd = wakeFds[0];
    // 管道写端
    mWakeWritePipeFd = wakeFds[1];
    // 给读管道设置非阻塞的flag, 保证在没有缓冲区可读的情况下立即返回而不阻塞。
    result = fcntl(mWakeReadPipeFd, F_SETFL, O_NONBLOCK);
    // 同理给写管道设置非阻塞
    result = fcntl(mWakeWritePipeFd, F_SETFL, O_NONBLOCK);
#ifdef LOOPER_USES_EPOLL
    // 分配epoll实例，注册唤醒管道并监听
    mEpollFd = epoll_create(EPOLL_SIZE_HINT);
    // 定义监听事件
    struct epoll_event eventItem;
    memset(& eventItem, 0, sizeof(epoll_event));
    // 监听EPOLLIN类型事件, 该事件表示对应的文件有数据可读
    eventItem.events = EPOLLIN;
    eventItem.data.fd = mWakeReadPipeFd;
    // 注册监听事件, 这里只监听mWakeReadPipeFd
    result = epoll_ctl(mEpollFd, EPOLL_CTL_ADD, mWakeReadPipeFd, & eventItem);
#else
    // Add the wake pipe to the head of the request list with a null callback.
    ...
#endif
#ifdef LOOPER_STATISTICS
    ...
#endif
}
```

- Looper::getForThread(); Looper::setForThread();

```c
// 将Looper放入到线程中
void Looper::setForThread(const sp<Looper>& looper) {
    sp<Looper> old = getForThread(); // also has side-effect of initializing TLS
    // 增加新引用的计数
    if (looper != NULL) {
        looper->incStrong((void*)threadDestructor);
    }
    // 将新的Looper对象设置到线程局部对象
    pthread_setspecific(gTLSKey, looper.get());
    // 减少老引用的计数
    if (old != NULL) {
        old->decStrong((void*)threadDestructor);
    }
}

static pthread_once_t gTLSOnce = PTHREAD_ONCE_INIT;
// 获取线程中的Looper
sp<Looper> Looper::getForThread() {
    // initTLSKey 指代 initTLSKey()函数 内部调用pthread_key_create(...)创建线程局部对象
    // PTHREAD_ONCE_INIT  在Linex 线程模型中表示在本线程只执行一次
    int result = pthread_once(& gTLSOnce, initTLSKey);
    LOG_ALWAYS_FATAL_IF(result != 0, "pthread_once failed");
    // 返回线程局部对象中的Looper对象
    return (Looper*)pthread_getspecific(gTLSKey);
}
```

- Looper::wake() 唤醒

```c
void Looper::wake() {
    ...
    ssize_t nWrite;
    do {
        // 向管道写入字符串"W"
        // Looper监听了读管道，当有数据写入时,即有数据可读，处理消息的现场就会因为I/O事件被唤醒
        nWrite = write(mWakeWritePipeFd, "W", 1);
    } while (nWrite == -1 && errno == EINTR);
    if (nWrite != 1) {
        if (errno != EAGAIN) {
            LOGW("Could not write wake signal, errno=%d", errno);
        }
    }
}
```

- Looper::pollOnce();

```c
inline int pollOnce(int timeoutMillis) {
    return pollOnce(timeoutMillis, NULL, NULL, NULL);
}
int Looper::pollOnce(int timeoutMillis, int* outFd, int* outEvents, void** outData) {
    int result = 0;
    for (;;) {
        // 处理Response, mResponses由Looper:pushResponse方法填充
        // 创建Looper对象时mResponseIndex = 0
        // 这个循环只是返回了Response对应请求的标识信息ident
        // Response的处理由pollInner方法完成
        while (mResponseIndex < mResponses.size()) {
            const Response& response = mResponses.itemAt(mResponseIndex++);
            ALooper_callbackFunc callback = response.request.callback;
            if (!callback) {
                int ident = response.request.ident;
                int fd = response.request.fd;
                int events = response.events;
                void* data = response.request.data;
                ...
                if (outFd != NULL) *outFd = fd;
                if (outEvents != NULL) *outEvents = events;
                if (outData != NULL) *outData = data;
                return ident;
            }
        }
        if (result != 0) { // result由pollInner赋值, 默认 = 0
            ...
            if (outFd != NULL) *outFd = 0;
            if (outEvents != NULL) *outEvents = NULL;
            if (outData != NULL) *outData = NULL;
            return result;
        }
        result = pollInner(timeoutMillis);
    }
}
```

- Looper::pollInner()

```c
int Looper::pollInner(int timeoutMillis) {
    ...
    // 根据下一条消息的到期时间调整超时时间。
    if (timeoutMillis != 0 && mNextMessageUptime != LLONG_MAX) {
        nsecs_t now = systemTime(SYSTEM_TIME_MONOTONIC);
        int messageTimeoutMillis = toMillisecondTimeoutDelay(now, mNextMessageUptime);
        if (messageTimeoutMillis >= 0
                && (timeoutMillis < 0 || messageTimeoutMillis < timeoutMillis)) {
            timeoutMillis = messageTimeoutMillis;
        }
        ...
    }
    // Poll.
    int result = ALOOPER_POLL_WAKE;
    mResponses.clear();
    mResponseIndex = 0;
    ...
#ifdef LOOPER_USES_EPOLL
    // 使用了Linux的epoll机制, 调用epoll_wait监听mEpollFd上的事件。mEpollFd在创建Looper时创建
    // 若果没有事件发生, 将在epoll_wait中等待，时间就是timeoutMillis
    struct epoll_event eventItems[EPOLL_MAX_EVENTS];
    int eventCount = epoll_wait(mEpollFd, eventItems, EPOLL_MAX_EVENTS, timeoutMillis);
#else
    // Wait for wakeAndLock() waiters to run then set mPolling to true.
    mLock.lock();
    while (mWaiters != 0) {
        mResume.wait(mLock);
    }
    mPolling = true;
    mLock.unlock();
    size_t requestedCount = mRequestedFds.size();
    int eventCount = poll(mRequestedFds.editArray(), requestedCount, timeoutMillis);
#endif
    mLock.lock();
    // 出错或者超时,跳Done
    if (eventCount < 0) {
        if (errno == EINTR) {
            goto Done;
        }
        result = ALOOPER_POLL_ERROR;
        goto Done;
    }
    if (eventCount == 0) {
        ...
        result = ALOOPER_POLL_TIMEOUT;
        goto Done;
    }
    ...
#ifdef LOOPER_USES_EPOLL
    // 处理所有事件
    for (int i = 0; i < eventCount; i++) {
        int fd = eventItems[i].data.fd;
        uint32_t epollEvents = eventItems[i].events;
        if (fd == mWakeReadPipeFd) {
            if (epollEvents & EPOLLIN) {
                awoken();
            } else {
                ...
            }
        } else {
            // 监听的其他文件描述符所发出的请求
            ssize_t requestIndex = mRequests.indexOfKey(fd);
            if (requestIndex >= 0) {
                int events = 0;
                if (epollEvents & EPOLLIN) events |= ALOOPER_EVENT_INPUT;
                if (epollEvents & EPOLLOUT) events |= ALOOPER_EVENT_OUTPUT;
                if (epollEvents & EPOLLERR) events |= ALOOPER_EVENT_ERROR;
                if (epollEvents & EPOLLHUP) events |= ALOOPER_EVENT_HANGUP;
                // 先不处理, 放入到mResponse中
                pushResponse(events, mRequests.valueAt(requestIndex));
            } else {
                ...
            }
        }
    }
Done: ;
    // 忽略不看其他类型的epoll events
    ....
    // 具体处理Message和Request
    mNextMessageUptime = LLONG_MAX;
    while (mMessageEnvelopes.size() != 0) {
        // 处理Native层的消息
        nsecs_t now = systemTime(SYSTEM_TIME_MONOTONIC);
        const MessageEnvelope& messageEnvelope = mMessageEnvelopes.itemAt(0);
        if (messageEnvelope.uptime <= now) {
            { // obtain handler
                sp<MessageHandler> handler = messageEnvelope.handler;
                Message message = messageEnvelope.message;
                mMessageEnvelopes.removeAt(0);
                mSendingMessage = true;
                mLock.unlock();
                ...
                handler->handleMessage(message); // 处理消息
            } // release handler
            mLock.lock();
            mSendingMessage = false;
            result = ALOOPER_POLL_CALLBACK;
        } else {
            // 设置下次唤醒时间
            mNextMessageUptime = messageEnvelope.uptime;
            break;
        }
    }
    mLock.unlock();
    // Invoke all response callbacks.
    for (size_t i = 0; i < mResponses.size(); i++) {
        const Response& response = mResponses.itemAt(i);
        ALooper_callbackFunc callback = response.request.callback;
        if (callback) {
            int fd = response.request.fd;
            int events = response.events;
            void* data = response.request.data;
            ...
            int callbackResult = callback(fd, events, data);
            if (callbackResult == 0) {
                removeFd(fd);
            }
            result = ALOOPER_POLL_CALLBACK;
        }
    }
    return result;
}
```

- Looper::sendMessage() Native层发送消息


### 2.2 android_os_MessageQueue.cpp

这里其实也实现了和Java层Looper.prepare()方法相同的功能 

- 构造函数

```c++
NativeMessageQueue::NativeMessageQueue() {
    // 查询是否存在
    mLooper = Looper::getForThread();
    if (mLooper == NULL) {
        // 没有就创建Looper
        mLooper = new Looper(false);
        Looper::setForThread(mLooper);
    }
}
```

- android_os_MessageQueue_nativeInit()

```c++
/**
 * 创建一个NativeMessageQueue对象
 * 将Java层与Native层的MessageQueue关联起来
 * 从而在Java层中可以通过mPtr成员变量来访问Native层的NativeMessageQueue对象
 * [obj]: 表示调用native 的Java类
 */
static void android_os_MessageQueue_nativeInit(JNIEnv* env, jobject obj) {
    // JNI层创建一个NativeMessageQueue对象
    NativeMessageQueue* nativeMessageQueue = new NativeMessageQueue();
    if (! nativeMessageQueue) {
        jniThrowRuntimeException(env, "Unable to allocate native queue");
        return;
    }
    // 将Java层与Native层的MessageQueue关联起来
    android_os_MessageQueue_setNativeMessageQueue(env, obj, nativeMessageQueue);
}

static void android_os_MessageQueue_setNativeMessageQueue(JNIEnv* env, jobject messageQueueObj,
        NativeMessageQueue* nativeMessageQueue) {
        // SetIntField是JNI层向Java传输数据的方法。
        // 这里将nativeMessageQueue的地址保存到Java层MessageQueue对象的mPtr成员变量中
    env->SetIntField(messageQueueObj, gMessageQueueClassInfo.mPtr,
             reinterpret_cast<jint>(nativeMessageQueue));
}

static struct {
    // jfieldID表示Java层成员变量的名字,因此这里指代Java层MessageQueue对象的mPtr成员变量
    jfieldID mPtr;   // native object attached to the DVM MessageQueue
} gMessageQueueClassInfo;
```

-  android_os_MessageQueue_nativeWake

```c++
static void android_os_MessageQueue_nativeWake(JNIEnv* env, jobject obj, jint ptr) {
    // ptr 是java层MessageQueue的mPtr成员变量，存储了JNI层创建的 NativeMessageQueue的地址
    NativeMessageQueue* nativeMessageQueue = reinterpret_cast<NativeMessageQueue*>(ptr);
    return nativeMessageQueue->wake();
}

// 最终调用了JNI Looper的wake方法
void NativeMessageQueue::wake() {
    mLooper->wake();
}
```

- android_os_MessageQueue_nativePollOnce()

```c++
static void android_os_MessageQueue_nativePollOnce(JNIEnv* env, jobject obj,
        jint ptr, jint timeoutMillis) {
    // 根据mPtr找到 nativeMessageQueue
    NativeMessageQueue* nativeMessageQueue = reinterpret_cast<NativeMessageQueue*>(ptr);
    nativeMessageQueue->pollOnce(timeoutMillis);
}
void NativeMessageQueue::pollOnce(int timeoutMillis) {
    // 转发给Looper对象处理
    mLooper->pollOnce(timeoutMillis);
}
```

## 3. ~！@#￥%……&*（

### HandleThread

```
主要和Handle结合使用来处理异步任务

- 实质是一个Thread, 继承自Thread
- 他拥有自己的Looper对象
- 必须调用HandleThread.start()方法, 因为在run中创建Looper对象
```

### IdleHandler

* 使用场景:

```
- 主线程加载完页面之后，去加载一些二级界面;
- 管理一些任务, 空闲时触发执行队列。
```

* Handler线程空闲时执行:

```
- 线程的消息队列为空
- 消息队列头部的处理时间未到
```

* 使用

可以参考ActivityThread类中的空闲时执行gc流程

```java
class IdleForever implements MessageQueue.IdleHandler {
    /**
     * @return true : 保持此Idle一直在Handler中, 每次线程执行完后都会在这执行.
     */
    @Override
    public boolean queueIdle() {
        Log.d("", "我,天地难葬!");
        return true;
    }

}

class IdleOnce implements MessageQueue.IdleHandler {
    /**
     * @return false : 执行一次后就从Handler线程中remove掉。
     */
    @Override
    public boolean queueIdle() {
        Log.d("", "我真的还想再活五百年~!!!");
        return false;
    }
}
```

------
苦工 : [口戛口崩月危.Z][author]

[author]: https://zaze359.github.io
[MessageQueue于NativeMessageQueue]: http://static.zybuluo.com/zaze/kbfxaf2elx70xzzpc1ue4n8m/image_1c9odn8dlocl1lnh18mkahqbdo9.png
[Parcelable]:https://blog.csdn.net/justin_1107/article/details/72903006
[同步屏障]:https://blog.csdn.net/asdgbc/article/details/79148180

