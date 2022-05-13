[TOC]

# Android消息机制-Java篇

> 在启动线程时，线程内部维护了一个消息队列， 然后让线程进入无限循环。
> 在这个无限循环中，线程会不断的检查消息队列中是否是消息。
> 如果需要执行某个任务，可以就向线程中的消息队列中发送消息。
> 当循环检测到有消息到来，便会获取这个消息并执行它。如果没有则线程进入等待状态。


整个消息机制的流程大致可以总结为以下几步:
1. 在线程启动时通过``Looper.prepare()``创建一个唯一的``Looper实例``,这个实例内**维护一个MessageQueue对象**。
2. 调用loop()，在当前线程**启动Looper循环**，不断读取MessageQueue中的Messsage，并调用``msg.target.dispatchMessage(msg)``执行, 没有消息需要执行时将会阻塞。
3. 获取线程中的Looper对象**生成Handler实例发送消息**， Handler对象将消息放入Looper的MessageQueue中。
4. MessageQueue将链表中的所有消息进行排序: 根据最执行时间进行从近到远排序。
5. 若当前阻塞，则通过``nativeWake(mPtr)``唤醒epoll。

## 相关图表

### 1. UML类图
> 此处列出一些关键类的UML图，包含一些关键字段和方法。

![UML](Android消息机制之Java篇.assets/UML.png)


## 重要的类
### 1. 消息(Message)

所有的通过Handler发送的消息，最终都是将一个Message对象放入MessageQueue中。

Message对象内部存在一个静态变量``sPool``，用于Message的复用。Message.obtain()方法生成Message可以避免new的重新分配内存


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


### 2. 消息队列(MessageQueue)


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

### 3. 消息循环(Looper)

> ``prepare()``：与当前线程绑定。
>
> ``loop()``：循环调用``MessageQueue.next()``获取消息，交给``Message.target.dispatchMessage``分发处理(target指Handler, 在Handler.enqueueMessage中被赋值)。

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

### 4. 消息处理器(Handler)

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



### 5. 线程局部变量(ThreadLocal)

```java
/**
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


## !!!

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
```java
// 可以参考ActivityThread类中的空闲时执行gc流程
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
     * @return false : 执行一次后就从Handler线程中remove掉
     */
    @Override
    public boolean queueIdle() {
        Log.d("", "我真的还想再活五百年~!!!");
        return false;
    }
}
```


## 参考资料

以上部分图片和解读说明摘自以下参考资料。

> **<< Android的设计和实现:卷I>>**
>
> **<<深入理解Android: 卷I>>**




[MessageQueue于NativeMessageQueue]: http://static.zybuluo.com/zaze/kbfxaf2elx70xzzpc1ue4n8m/image_1c9odn8dlocl1lnh18mkahqbdo9.png
[Parcelable]:https://blog.csdn.net/justin_1107/article/details/72903006
[同步屏障]:https://blog.csdn.net/asdgbc/article/details/79148180