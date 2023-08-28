# Java学习笔记

* JVM（Java Virtual Machine）。Java虚拟机，是Java实现跨平台的关键。

* JRE（Java Runtime Environment）。Java运行时环境。包含了JVM和Java基本类库。

* JDK（Java Development Kit）。Java的软件开发工具包，基础了JRE和一些工具（javac, javadoc等）。
* OpenJDK：OpenJDK基于Sun捐赠的HotSpot源码，完全开源。由Oracle维护。
* OracleJDK：基于OpenJDK。不完全开源。添加了额外功能和商业功能。



## 基础类型和包装类型

### 基础类型

> 一个内存地址代表一个字节（8bit），0xFF

| 类型      | 字节 | 位数 | 默认值  | 取值范围                                   |
| :-------- | :--- | :--- | :------ | ------------------------------------------ |
| `byte`    | 1    | 8    | 0       | -128 ~ 127                                 |
| `short`   | 2    | 16   | 0       | -32768 ~ 32767                             |
| `char`    | 2    | 16   | 'u0000' | 0 ~ 65535                                  |
| `int`     | 4    | 32   | 0       | -2147483648 ~ 2147483647                   |
| `long`    | 8    | 64   | 0L      | -9223372036854775808 ~ 9223372036854775807 |
| `float`   | 4    | 32   | 0f      | 1.4E-45 ~ 3.4028235E38                     |
| `double`  | 8    | 64   | 0d      | 4.9E-324 ~ 1.7976931348623157E308          |
| `boolean` |      | 1    | false   | true、false                                |

### 包装类

> Integer、Float等8大基础类型对应的引用类型。

包装类的缓存机制：

`Byte`,`Short`,`Integer`,`Long`类默认创建了数值 **[-128，127]** 的相应类型的缓存数据。

`Character` 创建了数值在 **[0,127]** 范围的缓存数据。

`Boolean` 直接返回 `True` or `False`。

### 自动装箱和拆箱

> 拆装箱存在一定的性能损耗。

* 装箱：将基本类型转为包装类型（`valueOf()`）。
* 拆箱：将包装类型转为基本类型（`xxxValue()`）。

```java
Integer i = 1; // 装箱：Integer i = Integer.valueOf(1);
int j = new Integer(2); // 拆箱：int j = new Integer(2).intValue();
```

> Integer 涉及到一个享元模式的问题，对于 -128 ~ 127 的数值，它会优先从缓存中复用，也就是说。
>
> 这样就能避免频繁new Integer对象，提升性能。但是也带来了一个问题，那就是由于当触发缓存时，对于两个相同的Integer 例如 Integer(100）使用 `==` 进行判断会返回true。而超出上述的范围时，会重新创建一个新的 Integer对象，例如 Integer(10000)，此时两个相同值的 Integer 使用 `==` 进行判断会返回false。

### 这两者类型的区别

* 默认值：包装类型的默认值是null, 基础类型的默认值是具体的某个值。
* 泛型：包装类型可用于泛型，基础类型则不行。
* 内存存储位置：包装类属于对象类型，对象实例存储在堆中。基础类型作为局部变量存储在虚拟机栈的局部变量表中。
* 内存占用：基础类型占用空间更小。
* 比较方式：基础类型直接值比较，包装类型则时`equals`比较，值相同，对象不一定相同。

## 变量和常量

```java

public class TestConst {
    public String a = "var"; // 变量
    public static String sa = "static var"; // 静态变量
    public final String b = "val"; // 常量，需要类实例化才能访问。
    public static final String sb = "static val"; // 静态常量
    private static final String sbb = new String("static val"); // 静态常量 编译器间不能确定值，不会被优化，且需要类加载后才能访问

    public TestConst() {
    }

    public void aa() {
        System.out.println("a: " + this.a); // 变量需要通过实例化对象访问
        System.out.println("sa: " + sa); // 静态变量，可以直接访问
        System.out.println("b: val");	// 常量，被内联优化
        System.out.println("sb: static val"); // 静态常量，被内联优化
        System.out.println("sbb: " + sbb);	// 编译时无法确定值的静态常量，不会内优化，但是能直接访问
    }
}
```

### 变量

没有被final 修饰，在运行过程中可以被修改的数据类型。再加上 static 修饰后就是静态变量。

> 静态变量和变量的区别：
>
> 变量属于具体的类实例化对象，需要实例化后才能访问。
>
> 静态变量属于类对象，只要类加载后就可以访问，不必再实例化对象。

### 常量

指final 修饰的数据类型，一但指确定后，在运行过程中不会被修改。static final 修饰的数据类型 就是静态常量。

对于在编译期间能够确定值的常量，会通过内联的方式优化。

> 静态常量和常量的区别：
>
> 常量属于类实例化对象，需要实例化对象后使用。
>
> 静态常量属于类对象，能够直接访问，如果在编译时能确定值，那么就被内联到调用处，这样即使类没有加载也是能正常使用的。



## 访问修饰符

| 修饰符    | 可见性                               |
| --------- | ------------------------------------ |
| private   | 私有，仅类内可见                     |
| default   | 同包级可见，不加修饰符时默认就是整个 |
| protected | 同包级以及子类可见                   |
| public    | 所以可见                             |



## 进程

进程是操作系统对一个正在运行的程序的一种抽象。

* 进程是操作系统**资源分配的最小单位**。
* 不同进程间数据不共享，且相互不影响。
* 一个进程可以包含多个线程，子线程的崩溃可能导致进程的退出。
* 多进程间的切换很耗资源。
  * 需要切换内存地址空间。
  * 需要保存/恢复上下文。

## 线程

线程是CPU 调度的最小单位。

* 多线程间的切换比多进程的切换开销更小，同进程下的线程内存空间是相同的，但每次切换还是需要保存/恢复上下文，这里涉及用户态和内核态的切入切出，频繁切换时资源消耗也不小。

### 线程状态

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

### sleep原理

调用线程的sleep()函数时，会将线程挂起，并修改状态为阻塞，同时根据参数启动一个定时器，到时间后会发送一个中断，将状态修改为read状态，并进入到就绪队列中等待调度。

### 线程上下文切换

* CPU分配给线程的时间片用完了，此时会发生上下文切换。
* 线程结束，此时会发生上下文切换。
* 线程被阻塞（锁、sleep、IO、数据库连接等），此时同样会发生上下文切换。

### synchronized 关键字

synchronized 关键字是Java 中的一种同步方式，使用synchronized修饰时，相当于加锁，仅允许一个执行线程访问它。

* 保证了原子性：锁的最基本作用就是为了保证原子性。
* 保证了可见性：修改会立刻刷新到主存，即直接存取原始内存地址。

synchronized 作用于不同函数：

* 修饰静态方法：锁的是 `类.class`，这个类对象。
* 修饰非静态方法：锁的时 具体的类实例。

因此两个线程可以同时分别访问 都被synchronized修饰的静态方法和非静态方法，且不会发生竞争。





## 线程池

线程池是一种线程重复利用的技术，它会保留一定数量的线程，在没有任务时会休眠，当有任务时就会调度线程去执行任务。

### 线程池优点

* **线程的统一管理**：所有的线程都在线程池中创建，做到了统一的管理。
* **降低资源消耗、利用率高**：线程池可以重复利用已创建的线程，从而减少线程频繁创建和销毁的消耗。

> 不合理的使用线程池会导致很多问题。
>
> * 资源耗尽问题：申请线程池的很大，或者支持无限创建线程，就会导致资源的浪费甚至耗尽，从而影响运行性能。

### 线程池的状态

| 状态       |                                                              |                                                  |
| ---------- | ------------------------------------------------------------ | ------------------------------------------------ |
| RUNNING    | 线程池创建后就会处于 RUNNING。                               | 此时线程池正常可用                               |
| SHUTDOWN   | 调用了 `shutdown()`后。                                      | 不能接收新任务，会等待队列中的任务执行完毕。     |
| STOP       | 调用`shutdownNow()`后。                                      | 不能接收新任务，并且会去终止当前任务             |
| TIDYING    | 所有任务都已经终止，且workcount==0，会先更新这个状态然后准备执行 `terminated()`。 | 不能接收新任务，这是变为 TERMINATED 之前的状态。 |
| TERMINATED | 处于`SHUTDOWN`或`STOP` 状态 且所有任务执行完毕后会更新为这个状态。 | 表示线程池已终止，无法使用。                     |

![image-20230626212716486](./Java%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230626212716486.png)

### 线程池任务处理流程

![image-20230626222320294](./Java%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230626222320294.png)

* 核心线程未满时，会优先创建核心线程处理任务，直到满载。
* 核心线程池满后，新任务会加入到 workQueue 中等待调度。
  * 需要注意的是corePoolSize=0的场景，那么在加入到workQueue后会立即创建一个非核心线程来执行任务。
* 工作队列也满了之后，会创建非核心线程来处理新添加的任务。
* 非核心线池也满载后，还有新任务添加就会进入拒绝策略流程。
  * 线程池上限 = workQueue.size() + maximumPoolSize。

> `addWorker()` 的作用就是创建一个线程并执行任务。默认创建核心线程，传入false是创建的就是非核心线程。

```java
 	public void execute(Runnable command) {
        if (command == null)
            throw new NullPointerException();
        /*
         * Proceed in 3 steps:
         *
         * 1. If fewer than corePoolSize threads are running, try to
         * start a new thread with the given command as its first
         * task.  The call to addWorker atomically checks runState and
         * workerCount, and so prevents false alarms that would add
         * threads when it shouldn't, by returning false.
         *
         * 2. If a task can be successfully queued, then we still need
         * to double-check whether we should have added a thread
         * (because existing ones died since last checking) or that
         * the pool shut down since entry into this method. So we
         * recheck state and if necessary roll back the enqueuing if
         * stopped, or start a new thread if there are none.
         *
         * 3. If we cannot queue task, then we try to add a new
         * thread.  If it fails, we know we are shut down or saturated
         * and so reject the task.
         */
        int c = ctl.get();
        // 当前工作线程数 小于 corePoolSize
        // 调用 addWorker() 创建线程
        if (workerCountOf(c) < corePoolSize) {
            if (addWorker(command, true)) 
                return; // 线程创建成功，就返回
            c = ctl.get();
        }
        // 大于corePoolSize 或 核心线程创建失败
        // 尝试加入到工作队列 workQueue 中。
        if (isRunning(c) && workQueue.offer(command)) {
            int recheck = ctl.get();
            // 重新检查一下
            if (! isRunning(recheck) && remove(command))
                reject(command);
            else if (workerCountOf(recheck) == 0)
                // 需要特别注意这里，如果当前工作线程=0，那么会立即创建一个非核心线程来执行任务。
                addWorker(null, false);
        }
        // 加入 workQueue失败，尝试创建非核心线程执行
        else if (!addWorker(command, false))
            // 线程创建失败，执行拒绝策略
            reject(command);
    }
```

### 线程池的四种拒绝策略

#### AbortPolicy

线程池的默认策略。处理方式是**抛出RejectedExecutionException 异常，新任务也不会被执行**。

> 适用于关键的核心业务，这样我们可以通过抛出的异常即使发现问题并做一些补救措施。

```java
    public static class AbortPolicy implements RejectedExecutionHandler {
        public AbortPolicy() { }
        
        /**
         * Always throws RejectedExecutionException.
         *
         * @param r the runnable task requested to be executed
         * @param e the executor attempting to execute this task
         * @throws RejectedExecutionException always
         */
        public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
            // 抛出异常
            throw new RejectedExecutionException("Task " + r.toString() +
                                                 " rejected from " +
                                                 e.toString());
        }
    }
```

#### DiscardPolicy

和 AbortPolicy的区别是 不会抛出异常，**直接忽略了新添加的任务，并且无事发生**。

> 适用于处理那些偶尔不执行也没事的不重要的业务，例如数据采样统计数据之类的任务，当然还得结合具体业务。

```java
    public static class DiscardPolicy implements RejectedExecutionHandler {
        public DiscardPolicy() { }

        /**
         * Does nothing, which has the effect of discarding task r.
         *
         * @param r the runnable task requested to be executed
         * @param e the executor attempting to execute this task
         */
        public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
        }
    }
```

#### DiscardOldestPolicy

丢弃最旧的任务，即**将阻塞队列最前面的任务丢弃**，然后将新任务加入到阻塞队列中。

> 使用于对老数据不敏感，偏好新数据的场景，例如采集数据本地应用信息之类的任务。

```java
public static class DiscardOldestPolicy implements RejectedExecutionHandler {
        /**
         * Creates a {@code DiscardOldestPolicy} for the given executor.
         */
        public DiscardOldestPolicy() { }

        /**
         * Obtains and ignores the next task that the executor
         * would otherwise execute, if one is immediately available,
         * and then retries execution of task r, unless the executor
         * is shut down, in which case task r is instead discarded.
         *
         * @param r the runnable task requested to be executed
         * @param e the executor attempting to execute this task
         */
        public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
            if (!e.isShutdown()) {
                // 丢弃 队头
                e.getQueue().poll();
                // 添加任务
                e.execute(r);
            }
        }
    }
```

#### CallerRunsPolicy

直接**在调用线程中执行这个被拒绝的任务**。特点就是任务用于不会被丢弃，但是可能会导致一些性能问题。

> 适用于不允许任务丢失，性能要求不高的场景。

```java
    public static class CallerRunsPolicy implements RejectedExecutionHandler {
        /**
         * Creates a {@code CallerRunsPolicy}.
         */
        public CallerRunsPolicy() { }

        /**
         * Executes task r in the caller's thread, unless the executor
         * has been shut down, in which case the task is discarded.
         *
         * @param r the runnable task requested to be executed
         * @param e the executor attempting to execute this task
         */
        public void rejectedExecution(Runnable r, ThreadPoolExecutor e) {
            if (!e.isShutdown()) {
                // 直接执行
                r.run();
            }
        }
    }
```



### 线程池的阻塞队列类型

#### LinkedBlockingQueue：无界队列

常见的就是 LinkedBlockingQueue，它是基于链表的，队列大小无限制，永远不会触发拒绝策略。

> 注意点：当队列中的任务都比较耗时时，容易导致队列堆积，进而占用了大量内存。

#### 有界队列

> 需要处理好拒绝策略。

* ArrayBlockingQueue：先进先出（FIFO）队列。
  * 创建时需要指定队列大小。
  * 基于数组实现。
* PriorityBlockingQueue：优先级队列。
  * 创建时可以指定队列大小，默认size = 11。
  * 以数组的方式存储，数据内的元素会进行堆化，使用小顶堆实现优先级。
  * 通过 Comparator 来进行优先级比较。

#### SynchronousQueue：同步移交队列

SynchronousQueue，内部是一个不存储元素的BlockingQueue，因为也算不上是一个队列，主要起到任务调度的作用, **将需要加入的任务移交到另一个线程中去执行**。

内部存在两种策略：

* TransferQueue：队列的方式，先进先出，公平策略。头节点指向的是先加入的节点。
* TransferStack：栈的方式，先进后出，非公平策略，默认是这种策略。头节点指向的是后加入的节点。

原理：

主要逻辑都是在 `transfer()` 函数中，它会判断根据传入的数据 e 来判断是入队还是出队。

* 默认是不阻塞的。此时 若 e != null 表示入队，直接返回null，表示入队失败，从而就会创建一个新的线程来执行任务。

* 阻塞场景：此时若 e != null 表示入队，此时会阻塞线程。若 e == null 表示出队，会唤醒 头节点中的等待线程。

> 一般在无界线程池（能无限创建线程）或者有拒绝策略的线程池中使用。例如 `Executors.newCachedThreadPool()` 缓存线程池就是使用的这个阻塞队列。

### 默认提供的四种线程池

#### newSingleThreadExecutor()

单线程的线程池，永远只有一个线程工作，使用的阻塞队列是 LinkedBlockingQueue 无界队列，能无限添加任务。

```java
public static ExecutorService newSingleThreadExecutor() {
    return new FinalizableDelegatedExecutorService
        (new ThreadPoolExecutor(1, 1,
                                0L, TimeUnit.MILLISECONDS,
                                new LinkedBlockingQueue<Runnable>()));
}
```

#### newFixedThreadPool()

定长的线程池，所有线程都是核心线程，所有指定线程数就是并发数，使用的也是 无界队列。

```java
    public static ExecutorService newFixedThreadPool(int nThreads) {
        return new ThreadPoolExecutor(nThreads, nThreads,
                                      0L, TimeUnit.MILLISECONDS,
                                      new LinkedBlockingQueue<Runnable>());
    }
```

#### newCachedThreadPool()

缓存线程池。最大线程数是Integer.MAX_VALUE，相当于支持无限创建线程，使用的是 SynchronousQueue 同步移交队列，通过一直创建线程还快速处理任务。

```java
    public static ExecutorService newCachedThreadPool() {
        return new ThreadPoolExecutor(0, Integer.MAX_VALUE,
                                      60L, TimeUnit.SECONDS,
                                      new SynchronousQueue<Runnable>());
    }
```

#### newScheduledThreadPool()

支持周期、定时执行的线程池。最大线程数是Integer.MAX_VALUE，相当于支持无限创建线程。

使用的是 DelayedWorkQueue，类似优先级队列，都是基于  堆 实现的，会将任务按照时间来进行排序，最先执行的放在前面。

```java
    public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize) {
        return new ScheduledThreadPoolExecutor(corePoolSize);
    }

    public ScheduledThreadPoolExecutor(int corePoolSize) {
        super(corePoolSize, Integer.MAX_VALUE, 0, NANOSECONDS,
              new DelayedWorkQueue());
    }
```



### 自定义线程池的使用

构造函数：

* corePoolSize：核心线程数，表示默认长期在工作的线程。这里满了会将任务加入到workQueue中。
* maximumPoolSize：线程池最大线程数量，当workQueue满时，动态的创建线程来帮助消费任务。
  * 额外线程数：maximumPoolSize - corePoolSize。

* keepAliveTime：空闲线程（非核心线程）的存活时间
* unit：存活时间的时间单位
* workQueue：工作队列、阻塞队列，用于存储待调度的任务
* threadFactory：

```java
public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,
                              TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory) {
        this(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue,
             threadFactory, defaultHandler);
    }
```

案例：

```java
ThreadPoolExecutor serverExecutor = new ThreadPoolExecutor(1, 1, 0L,
                TimeUnit.MILLISECONDS, new LinkedBlockingQueue(), new ThreadFactory() {
            @Override
            public Thread newThread(@NonNull Runnable r) {
                Thread thread = new Thread(r, "socket server thread " + id++);
                if (thread.isDaemon()) {
                    thread.setDaemon(false);
                }
                return thread;
            }
        });
```



## 锁

锁是一直解决并发问题的常用机制。

### 可重入锁/不可重入锁

* 可重入：如果一个线程获取到了锁，那么后续这个线程还能一直获取到锁，**不会被自己锁住**。
  * Synchronized、ReentrantLock 这些是可重入锁。
* 不可重入：如果一个线程获取到了锁，那么后续这个线程继续申请锁时是会被自己锁住的。

### 公平锁/不公平锁

* 公平锁：**先到先得。**多线程申请锁时会加入到队列中，最后按照申请的顺序来获取锁的，队头先获取到锁。
  * 线程都能获取到锁。
  * 除了第一个线程之外，其他线程都会阻塞等待，然后需要cpu去唤醒，吞吐量低。
* 不公平锁：**来得早不如来得巧。**线程申请锁时会先尝试获取锁，能获取不到时才会加入到队列中等待。
  * 可以减少CPU唤醒线程的次数，同时提高吞吐量。
  * 可能会导致部分线程一直获取不到锁。

### 独占锁/共享锁

* 独占锁：这个锁只能被一个线程持有，是互斥的。
  * 常见的有 Synchronized、ReentrantLock、ReentrantReadWriteLock的写锁等。

* 共享锁：这个锁可以被多个线程持有，多个线程可以同时访问。
  * ReentrantReadWriteLock的读锁就是共享锁。


### 悲观锁和乐观锁

#### 悲观锁

悲观锁的设计思想是：认为数据很容易被外界修改，所以**使用前会先加锁，直到数据使用完毕才会释放锁**。

Java中的 Synchronized 关键字、ReentrantLock就是悲观锁。

* 悲观锁是互斥的，是独占锁。

#### 乐观锁

乐观锁的设计思想是：认为数据不容易被外界修改，它**不会在使用数据时加锁，而是会在更新数据时判断一下数据是否被别人修改**。

虽然名字带锁，**乐观锁实际是一种无锁操作**。Java的并发包下的原子类就是使用的乐观锁实现的CAS。

### CAS（CompareAndSwap）

> `compareAndSwap`、`compareAndSet` 都是CAS，不同API名字存在一些差异。
>
> CAS 需要硬件支持。底层通过CPU的CAS指令对缓存加锁或总线加锁的方式来实现多处理器之间的原子操作。

CAS是基于乐观锁实现的，它主要有三个值：内存中的旧值、期望值、修改的新值。

* 调用接口时会传入一个期望值以及需要修改的新值。
* 指令执行时会将内存中的值作为旧值，若旧值等于期望值则将 内存中的值更新为旧值。
* 若此时旧值不等于期望值，后续可以选择重试或者结束。
* 重试时一般会使用自旋机制。

### 自旋锁

**自旋锁其实就是一个 `while` 死循环**，此时线程会一直去检测状态，除时间片耗尽的情况外不会发生上下文切换，但是比较浪费CPU。通常会在 CAS 的重试机制中使用。

### 死锁问题

死锁是在多线程并发编程中常见的一种问题。发生死锁的场景是两个线程处于竞争状态，且互相持有对方需要的资源，在相互等待对方释放。

- **互斥条件**：一个资源同一时刻只能被一个线程或进程使用。
- **占用且等待条件**：请求的资源得不到时会一直等待，并且不释放已占有的资源。
- **不可抢占（不可剥夺）条件**：其他线程/进程无法强制剥夺被被其他线程/进程占有的资源，只能由持有者自己释放。
- **循环等待条件**：每个线程/进程都在等待下一个线程/进程所持有的资源，导致永远处于等待状态。

解决死锁的方式，根据不同的场景选择处理方式：

* 互斥条件无法被破坏，因为我们加锁的目的就是为了保证一个资源同一时刻只能被一个线程或进程使用。

* **破坏占用且等待**：一次性将所有需要的资源都申请过来，这样就不用等待其他线程释放了。
* **破坏不可抢占**：当新的资源无法获取到时，将当前已获取到的资源先释放。先让其他线程处理。
* **破坏循环等待**：必须按照顺序来申请资源，即 先持有了资源1后才能申请资源2，且申请了资源2后不能回头重新去申请资源1，而是应该一直持有1。



死锁代码案例：线程A持有 lock1，同时在等待lock2，但是线程B持有了lock2并且在等待lock1，由于线程A无法获取到lock2，所以就会一直等待且无法释放lock1，这样就发生了死锁。

```java

class Work {
    private static final Object lock1 = new Object();
    private static final Object lock2 = new Object();

    public static void main(String[] args) {
        final Work work = new Work();
        // 启动两个线程模拟死锁
        new Thread(work::doFirst).start();
        new Thread(work::doSecond).start();
    }

    public void doFirst() {
        // 先锁 lock1，再锁lock2
        synchronized (lock1) {
            System.out.println("doFirst lock1");
            try {
                // 休眠，保证另一个线程执行
                Thread.sleep(3000L);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
            synchronized (lock2) { // 死锁
                System.out.println("doFirst lock2");
            }
        }
    }

    public void doSecond() {
        // 先锁 lock2，再锁lock1
        synchronized (lock2) {
            System.out.println("doSecond lock2");
            try {
                // 休眠，保证另一个线程执行
                Thread.sleep(3000L);
            } catch (InterruptedException e) {
                throw new RuntimeException(e);
            }
            synchronized (lock1) { // 死锁
                System.out.println("doSecond lock1");
            }
        }
    }
}
```





---

## 拷贝

### 浅拷贝

> Object.clone()是浅拷贝。

* 在堆上新生成了一份拷贝对象实例。
* 若对于内部的引用类型仅是引用拷贝，即内部属性还是指向的同一个对象。**修改内部引用类型会影响到另一方**。

### 深拷贝

* 在堆上不仅生成了一份拷贝对象实例还生成了内部对象的拷贝对象。
* 完全复制对象，包括对象内部的对象。
* 任何一方对原实例对象的修改以及内部对象的修改都**完全不会影响到另一方**。

### 引用拷贝

* 堆上未生成新的对象实例。
* 两个不同的引用指向同一个对象，仅引用不同。

* 两者指向的是同一个对象，所以**任何一方修改都会影响到另一方**。

## 单例模式

单例模式是常见的一种设计模式，特点就是 单例对象的实例有且仅有一个，作为一个全局对象。

### 静态常量

在类中直接创建一个静态常量的方式实现单例，是一个饿汉式单例。会在类装载的时候实例化这个静态常量，利用了类的初始化锁来保证线程安全。

```java
class Singleton {
    private static final Singleton instance = new Singleton();
    private Singleton(){}
    public static getInstance() {
        return instance;
    }
}
```

饿汉式的问题就是 会过早的创建对象，容易造成内存浪费。

### 静态代码块

和静态常量实现单例的方式类似，也是一个饿汉式单例。同样利用了类的初始化锁来保证线程安全。

```java
class Singleton {
    private static final Singleton instance;
    static {
        instance = new Singleton();
    }
    private Singleton(){}
    public static getInstance() {
        return instance;
    }
}
```

### 静态内部类

类只有在被使用到时才会被加载，静态内部类单例就是利用这个特性，我们只有在调用 `getInstance()`时才会触发 `_Singleton` 这个静态内部的类加载，同时实例化单例对象，这样就实现了懒汉式单例，并使用类的初始化锁来保证线程安全.

```java
class Singleton {
    
    private Singleton(){}
    
    public static getInstance() {
        return _Singleton.instance;
    }
    
    // 静态内部
    private static class _Singleton() {
        private static final Singleton instance = new Singleton();
    }
}
```

### 枚举类

枚举天然就是一个单例模式，还能防止反序列化重新创建新的对象。

```java
public enum Singleton {
    INSTANCE;
    
    public void doSomething() {
        
    }
}
```

### 双重检测

双重检测（DCL，double-checked locking）是为了优化 线程安全的懒汉式单例每次访问都需要申请锁的问题。仅在第一次实例化时才会去加锁。第二次检测是防止其他已经在等待锁线程获取到锁后再次实例化。

```java
class Singleton {
    private volatile static Singleton instance;
    private Singleton(){}
    public static getInstance() {
        if(instance == null) { // 第一次检测，不加锁。
            synchronized(Singleton.class) { // 类锁
                if(instance == null) { // 第二次检测，防止其他已经在等待锁线程获取到锁后再次实例化。
                    instance = new Singleton();
                }
            } 
        }
    }
}
```

同时会添加 volatile 来修饰instance，禁止指令重排，保证 instance 的内存可见性。

#### volatile 关键字

volatile 关键字修饰的变量具有 以下几个特征：

* 可见性：修改会立刻刷新到主存，即直接存取原始内存地址。保证了**不同线程对该变量操作的内存可见性**。
  * 写入volatile变量：会把该线程对应的本地内存中的共享变量同步到主存中。
  * 读取volatile变量：该线程对应的本地内存会被置为无效，线程会从主存中直接读取共享变量。
* 有序性（禁止指令重排）
  * 禁止了指令重排，避免出现由于非原子操作而导致的并发问题。
  * 对于一个volatile 修饰的变量，若一个线程先去写，另一个线程去读，则一定时写入完成后 才能读取。

**禁止指令重排的目的**：主要是由于 单例对象在实例化过程中并不是一个原子操作，`singleton = new Singleton()`分为三个步骤：

1. 给singleton对象分配内存。此时singleton依然是 null
2. 调用构造函数初始化。
3. 将singleton指向分配的内存空间地址，这样才使得 singleton != null。

而 2、3 两个步骤顺序即使颠倒 也不会影响 最终的结果，所以可能发生指令重排，导致 singleton 先指向内存空间的地址，但是缺还没有调用构造函数进行初始化。此时若是发生并发，另一个线程在双重检测的第一次检测中发现 `singleton != null`，直接返回并使用的这个还未初始化的对象，那么就会出现问题。

**内存可见性**：主要是由于Java内存模型引起的，线程会从主存中同步内存到本地内存，正常情况都是读写的线程本地内存，然后再同步到主存中，这就会在多线程并发中出现不同线程中内存同步的问题。而这个可见性的作用就是 直接读写主内存。同时volatile 还保证 写在读之前。

> 需要注意的是**volatile 并不能保证原子性**，因为它虽然能保证读取在写之后，但是并不会阻止线程的并发读取，像 i++、对象实例化这样的非原子的操作，第一步读取依然会发生并发问题。所以在双重检测中还需要加锁保证原子性。
>
> 所以双重检测时会配合 synchronized  一起使用。

**volatile原理**：基于内存屏障 LOCK 前缀指令。

* 保证LOCK后面的只能不能重排到LOCK之前。
* 使cpu内存写入内存。同时使其他cpu的缓存失效。



## .happens-before九大规则





## Java内存模型和JVM内存结构

### JVM内存结构

JVM内存结构描述的是JVM虚拟机的内部存储结构。

### Java内存模型：JMM

JMM则是和多线程并发编程相关的一个概念。

![image-20230628005457266](./Java%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230628005457266.png)

