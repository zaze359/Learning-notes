
# 消息机制篇

Tags : ZAZE Android

---

[TOC]

---

```
- Looper调用prepare(),在当前执行的线程中生成仅且一个Looper实例，这个实例包含一个MessageQueue对象
- 调用loop()方法,在当前线程进行无限循环，不断从MessageQueue中读取Handler发来的消息。
- 生成Handler实例同时获取到当前线程的Looper对象 
- sendMessage方法, 将自身赋值给msg.target, 并将消息放入MessageQueue中
- 回调创建这个消息的handler中的dispathMessage方法，
```

## 1. 消息(Message)
```
建议使用Message.obtain()方法生成Message对象; 因为Message内部维护了一个Message池用于Message的复用，避免使用new 重新分配内存
```

## 2. 消息队列(MessageQueue)

## 3. 消息循环(Looper)

```
- prepare()与当前线程绑定。
- loop()方法，通过MessageQueue.next()获取取消息，交给Message.target.dispatchMessage分发处理(target指Handler, 在Handler.enqueueMessage中被赋值)。
```

- prepare()
```
/**
 *  prepare()只能被调用一次, 否则直接抛出异常
 *  保证一个线程中只有一个Looper
 **/
private static void prepare(boolean quitAllowed) {
    if (sThreadLocal.get() != null) {
        throw new RuntimeException("Only one Looper may be created per thread");
    }
    sThreadLocal.set(new Looper(quitAllowed));
}
```

- loop()
```
/**
 * loop 必须在prepare()后执行，否则报错
 **/
public static void loop() {
    final Looper me = myLooper();
    if (me == null) {
        throw new RuntimeException("No Looper; Looper.prepare() wasn't called on this thread.");
    }
    .....
    for(;;) {
        Message msg = queue.next(); // might block
        ......
        msg.target.dispatchMessage(msg);
        ......
    }
}
```

## 4. 消息处理器(Handler)
```
- 生成Handler实例同时获取到当前线程的Looper对象 
```

- sendMessage()
```
将自身赋值给msg.target, 并将消息放入MessageQueue中
```

- post(new Runnable())
 实际是发送了一条消息,此处的Runnable并没有创建线程，只是作为一个callback使用
```
public final boolean post(Runnable r){
   return  sendMessageDelayed(getPostMessage(r), 0);
}

private static Message getPostMessage(Runnable r) {
    Message m = Message.obtain();
    m.callback = r;
    return m;
}
```
- **dispatchMessage()消息分配**
以下源码可以看出, 当使用post()发送消息时, 最后会调用runnable.run()回调。sendMessage()则是执行handleMessage()， 这个就是我们构建对象时重写的方法
```
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
```
可以参考ActivityThread类中的空闲时执行gc流程

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