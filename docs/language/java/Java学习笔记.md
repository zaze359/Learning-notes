# Java学习笔记

## 线程

| Java线程状态  | Native线程状态           | 说明                                                         |
| ------------- | ------------------------ | ------------------------------------------------------------ |
| BLOCKED       | Blocked                  | Monitor阻塞，在`synchronized`时发现锁已被其他线程占用。线程正在等待获取锁 |
| NEW           | Starting                 | 线程启动                                                     |
| TERMINATED    | Terminated               | 线程已执行完毕。                                             |
| RUNNABLE      | Runnable                 | 正在运行中。                                                 |
| RUNNABLE      | Native                   | 正在调用JNI方法。                                            |
| RUNNABLE      | Suspended                | 由于GC或者debugger导致暂停。                                 |
| WAITING       | WaitingForGcToComplete   | 等待GC完毕。                                                 |
| WAITING       | WaitingForDeoptimization | 等待Deoptimization完毕                                       |
| WAITING       | WaitingForJniOnLoad      | 等待dlopen和JNI load方法完毕                                 |
| WAITING       | Waiting                  | 调用了`Object.wait()`, **没有设置超时时间**。线程正在等待被其他线程唤醒。自身不持有锁 |
| TIMED_WAITING | TimedWaiting             | 调用了`Object.wait()`,**设置了超时时间**。                   |
| TIMED_WAITING | Sleeping                 | 调用了`Thread.sleep()`                                       |

```java
synchronized (object)  {     // 在这里卡住 --> BLOCKED
    object.wait();           // 在这里卡住 --> WAITING
}  
```

