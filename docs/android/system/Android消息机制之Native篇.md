---

layout: post
title:  "Android消息机制篇"
date:   2018-03-29
categories: android

---

[TOC]


---

# Android消息机制之Native篇

## 参考资料

以下部分图片和解读说明摘自以下参考资料。

> **<< Android的设计和实现:卷I>>**
> **<<深入理解Android: 卷I>>**

## 1. 一图而窥之

作者太懒, 还在描边中~~

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

