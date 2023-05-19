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




## Looper.cpp

Java层的Looper主要是负责从MessageQueue中循环读取消息分发给Handler处理
Native层Looper主要是负责监听ReadPipe(读管道)，发送消息(Java中是由Handler处理的)

### 构造函数

内部创建了epoll

> [Looper.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/Looper.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=76)

```cpp
Looper::Looper(bool allowNonCallbacks)
    : mAllowNonCallbacks(allowNonCallbacks),
      mSendingMessage(false),
      mPolling(false),
      mEpollRebuildRequired(false),
      mNextRequestSeq(WAKE_EVENT_FD_SEQ + 1),
      mResponseIndex(0),
      mNextMessageUptime(LLONG_MAX) {
    // 重置 WakeEventFd，后续 epoll 会监听这个fd
    // fd设置非阻塞的flag：EFD_NONBLOCK
    mWakeEventFd.reset(eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC));
	
    AutoMutex _l(mLock);
    // 创建 epoll
    rebuildEpollLocked();
}
```

#### Looper::rebuildEpollLocked()

> [Looper.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/Looper.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=146)

```cpp
void Looper::rebuildEpollLocked() {
    if (mEpollFd >= 0) {
        // 重置已存在的epoll
        mEpollFd.reset();
    }
	// 重写创建一个epoll实例
    mEpollFd.reset(epoll_create1(EPOLL_CLOEXEC));
	// 创建监听事件类型：EPOLLIN, 表示对应的fd有数据可读
    epoll_event wakeEvent = createEpollEvent(EPOLLIN, WAKE_EVENT_FD_SEQ);
    // 注册监听事件, 监听 mWakeEventFd 这个fd
    // 即监听 mWakeEventFd 什么时候有数据可读
    int result = epoll_ctl(mEpollFd.get(), EPOLL_CTL_ADD, mWakeEventFd.get(), &wakeEvent);
    
	// mRequests中保存了所有注册到looper中的fd,这里循环注册epoll
    for (const auto& [seq, request] : mRequests) {
        epoll_event eventItem = createEpollEvent(request.getEpollEvents(), seq);

        int epollResult = epoll_ctl(mEpollFd.get(), EPOLL_CTL_ADD, request.fd, &eventItem);
        if (epollResult < 0) {
            ALOGE("Error adding epoll events for fd %d while rebuilding epoll set: %s",
                  request.fd, strerror(errno));
        }
    }
}

```



### Looper::prepare()

首先会从TLS中获取当前线程中的Looper，不存在则创建一个Looper

> [Looper.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/Looper.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=128)

```cpp
sp<Looper> Looper::prepare(int opts) {
    bool allowNonCallbacks = opts & PREPARE_ALLOW_NON_CALLBACKS;
    // 获取线程中的Looper，不存在则创建一个
    sp<Looper> looper = Looper::getForThread();
    if (looper == nullptr) {
        looper = sp<Looper>::make(allowNonCallbacks);
        Looper::setForThread(looper);
    }
	// 返回looper
    return looper;
}
```

#### Looper::getForThread()

从TLS中获取当前线程的Looper。

* `pthread_getspecific`：从TLS 中根据 key查找对应的数据。

> [Looper.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/Looper.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=120)

```cpp
// 在Linex 线程模型中表示在本线程只执行一次
static pthread_once_t gTLSOnce = PTHREAD_ONCE_INIT;
// 获取线程中的Looper
sp<Looper> Looper::getForThread() {
    // initTLSKey 指代 initTLSKey()函数 内部调用pthread_key_create(...)创建线程局部对象
    // gTLSOnce = PTHREAD_ONCE_INIT，表示在本线程只执行一次
    int result = pthread_once(& gTLSOnce, initTLSKey);
    LOG_ALWAYS_FATAL_IF(result != 0, "pthread_once failed");
	// 返回线程局部对象中的Looper对象
    Looper* looper = (Looper*)pthread_getspecific(gTLSKey);
    return sp<Looper>::fromExisting(looper);
}
```

#### Looper::setForThread()

将Looper 保存到当前线程的TLS中。

* `pthread_setspecific`：将对应数据以 kv 格式保存到 TLS中。

> [Looper.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/Looper.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=106)

```cpp
void Looper::setForThread(const sp<Looper>& looper) {
    sp<Looper> old = getForThread(); // also has side-effect of initializing TLS
    if (looper != nullptr) {
        // 新实例的 引用计数 ++
        looper->incStrong((void*)threadDestructor);
    }
	// 保存到 TLS中
    pthread_setspecific(gTLSKey, looper.get());

    if (old != nullptr) {
        // 旧实例的 引用计数 --
        old->decStrong((void*)threadDestructor);
    }
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



### Looper::pollOnce()

负责处理消息，返回 对应请求的标识信息ident

> [Looper.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/Looper.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=185)

```cpp
int Looper::pollOnce(int timeoutMillis, int* outFd, int* outEvents, void** outData) {
    int result = 0;
    for (;;) {
        // 创建Looper对象时mResponseIndex = 0
        // mResponses 是由 Looper:pushResponse() 方法填充的
        // 在循环中处理Response，返回了Response对应请求的标识信息ident
        while (mResponseIndex < mResponses.size()) {
            const Response& response = mResponses.itemAt(mResponseIndex++);
            int ident = response.request.ident;
            if (ident >= 0) {
                int fd = response.request.fd;
                int events = response.events;
                void* data = response.request.data;

                if (outFd != nullptr) *outFd = fd;
                if (outEvents != nullptr) *outEvents = events;
                if (outData != nullptr) *outData = data;
                return ident;
            }
        }

        if (result != 0) { // result 由 pollInner()赋值, 默认 = 0
            if (outFd != nullptr) *outFd = 0;
            if (outEvents != nullptr) *outEvents = 0;
            if (outData != nullptr) *outData = nullptr;
            return result;
        }
		// 调用 pollInner(), 内部会创建Response 并添加到 mResponses中
        result = pollInner(timeoutMillis);
    }
}
```

#### Looper::pollInner()

内部会处理消息：

* Message消息：会回调 `handleMessage()`来处理。
* Callback消息：会回调 `handleEvent()` 来处理。

> [Looper.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/Looper.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=221)

```cpp
int Looper::pollInner(int timeoutMillis) {
	// 根据下一条消息的到期时间调整超时时间。
    if (timeoutMillis != 0 && mNextMessageUptime != LLONG_MAX) {
        nsecs_t now = systemTime(SYSTEM_TIME_MONOTONIC);
        int messageTimeoutMillis = toMillisecondTimeoutDelay(now, mNextMessageUptime);
        if (messageTimeoutMillis >= 0
                && (timeoutMillis < 0 || messageTimeoutMillis < timeoutMillis)) {
            timeoutMillis = messageTimeoutMillis;
        }
    }
    // Poll.
    int result = POLL_WAKE;
    mResponses.clear();
    mResponseIndex = 0;
    // We are about to idle.
    mPolling = true;
	// 使用了Linux的epoll机制, 调用epoll_wait监听mEpollFd上的事件。mEpollFd在创建Looper时创建
    // 若果没有事件发生, 将在epoll_wait中等待，时间就是timeoutMillis
    struct epoll_event eventItems[EPOLL_MAX_EVENTS];
    int eventCount = epoll_wait(mEpollFd.get(), eventItems, EPOLL_MAX_EVENTS, timeoutMillis);

    // No longer idling.
    mPolling = false;
    // Acquire lock.
    mLock.lock();

    // Rebuild epoll set if needed.
    // 若需要重建epoll则重建
    if (mEpollRebuildRequired) {
        mEpollRebuildRequired = false;
        rebuildEpollLocked();
        goto Done;
    }

    // Check for poll error.
    // 检测,若出错或者超时,跳Done
    // ...

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
            // 监听的其他文件描述符所发出的请求
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
    // Invoke pending message callbacks.
    // 处理Native层的消息
    mNextMessageUptime = LLONG_MAX;
    while (mMessageEnvelopes.size() != 0) {
        nsecs_t now = systemTime(SYSTEM_TIME_MONOTONIC);
        const MessageEnvelope& messageEnvelope = mMessageEnvelopes.itemAt(0);
        if (messageEnvelope.uptime <= now) {
            { // obtain handler
                sp<MessageHandler> handler = messageEnvelope.handler;
                Message message = messageEnvelope.message;
                mMessageEnvelopes.removeAt(0);
                mSendingMessage = true;
                mLock.unlock();
				// 回调 handleMessage() 处理消息
                handler->handleMessage(message);
            } // release handler

            mLock.lock();
            mSendingMessage = false;
            result = POLL_CALLBACK;
        } else {
            // The last message left at the head of the queue determines the next wakeup time.
            // 设置下次唤醒时间
            mNextMessageUptime = messageEnvelope.uptime;
            break;
        }
    }

    // Release lock.
    mLock.unlock();

    // Invoke all response callbacks.
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



### 处理消息

#### MessageHandler

这里声明了一个 纯虚函数 `handleMessage()`，它负责实现处理消息的逻辑，需要根据具体场景的Handle来看。

> [Looper.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/include/utils/Looper.h;l=80;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=1;bpt=1)

```cpp
class MessageHandler : public virtual RefBase {
protected:
    virtual ~MessageHandler();

public:
    /**
     * Handles a message.
     */
    virtual void handleMessage(const Message& message) = 0;
};
```

#### LooperCallback

这里声明了一个 纯虚函数 `handleEvent()`，它负责实现处理消息的逻辑，需要根据具体场景的callback来看。

>[Looper.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:system/core/libutils/include/utils/Looper.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=103)

```cpp
class LooperCallback : public virtual RefBase {
protected:
    virtual ~LooperCallback();
public:
    virtual int handleEvent(int fd, int events, void* data) = 0;
};

```



### 发送消息

#### Looper::sendMessage()

用于在Native层中发送消息


## android_os_MessageQueue.cpp

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

## 

苦工 : [口戛口崩月危.Z][author]

[author]: https://zaze359.github.io

