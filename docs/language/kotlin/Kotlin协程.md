# Kotlin协程

> 源码常出看到 expect 和 actual 修饰词，他们表示修饰的对象是跨平台的。他们一一对应同名。
>
> expect 相当于接口。actual 是真实的实现。



## 温习总结用

在学习Kotlin协程和写这篇学习总结的过程中，对于协程的概念一直停留在字面概念上。对里面的一些概念也是似懂非懂（协程为什么协作的？挂起信息？continuation怎么理解? 为什么执行结果会作为下次执行的入参？等）突然感觉对协程有了一些理解。所以把我对 协程的理解先阐述在前面，方便后续温习时快速回忆。

在协程中，程序挂起的地方叫做挂起点，我对挂起点的理解是，**协程基于挂起点将 一个完整的函数一分为二，分为上下两部分，上部分就是我们已经执行的，下部分就是我们保存的挂起点信息**。

Kotlin 中会将 挂起点信息 保存到一个 Continuation 实例中。我们可以通过 它来 恢复协程，也就是继续执行 下部分函数。

而为了能够接着继续执行下部分，必然是需要使用到上部分的执行结果的。这也就是为什么 在恢复协程（`resumeWith()`）时，会将执行协程体（ `invokeSuspend()`） 的结果作为参数传递给下一个协程的原因。同时也是为什么仅异步才会挂起的原因，因为同步时就相当于拼一起，直接执行完毕了。

> **基于以上观点，我理解协程 就是将我们声明的实际函数 在需要挂起的地方拆分成更多的子函数（一个个的 `Continuation`就是为了能处理这些子函数 ），再通过一定的方式进行组合调用的这样一个协作过程。而这个组合协同的方式就是指协程的调度。也就理解了为什么说协程之间是相互作用的。**



* **协程实际是一个个 `Continuation` 组成**：我们操作的协程体都是 `Continuation` 的接口实例， 一般为 `SafeContinuation`。它包含一个 `CorutineContext` 上下文来保存信息，和 一个  `resumeWith()` 函数来处理操作。
* **协程是通过 CPS变换 来控制异步调用流程**：将 挂起点信息 保存在 Continuation 对象中，通过传递 Continuation 来控制异步调用流程。就是指恢复和挂起操作不在同一个函数栈中（比如线程切换）的场景下，保存到 Continuation 中 等待后续 调用恢复。

* **协程的启动/恢复相当于是开启了一个无限循环，从而一直获得调度权**：`resumeWith()` 内部 是一个死循环，循环内通过 `invokeSuspend()` 执行协程体。不退出/挂起 的情况下，会将返回值 `outcome` 会作为下次循环 执行协程体 的入参 param。
* **协程的挂起/退出相当于退出内部的循环，从而交出调度权**：在 挂起 或者 结束 时会退出循环。结束时调用回调 ` completion.resumeWith(outcome)`，将结果返回。
* **对称协程的调度方式的实现则是通过统一调度中心的方式**：由一个`特权协程`来统一 启动其他协程。其他协程会在结束前将 调度权还给 特权协程，特权协程再去 启动需要调度的协程，从而将调度权转移给了对应的协程。结束时通过 注册的回调接口进行回调。
* **我们平时使用的大多都是复合协程**：复合协程是基于 简单协程（类似`createCoroutine()`方式创建） 的扩展和封装，方便我们的使用。比如常用的  `launch {}` 就是复合协程的构造器。

## 什么是协程

### 协程的基本概念

协程是一种**程序控制流程的机制**，是为异步程序设计的。其核心点是 函数或一段程序能够被挂起，稍后再在挂起的位置恢复， 这个流程是程序逻辑自己控制的。

* 一个 支持挂起和恢复的程序。Kotlin协程是基于 `Continuation` 来实现挂起和恢复的。
* 以同步（阻塞）执行的方式 实现 异步（非阻塞）任务的执行,  简化了异步编程。
* 不同于线程，协程不需要系统和硬件的支持，是依靠编译器实现的。

协程的核心是 挂起 和 恢复：

* 挂起：让出运行权。

* 恢复：获得运行权。



#### 协程的组成部分

* **协程的执行体**：启动协程时对应的函数，即启动协程需要执行的操作，也叫 **协程体**。
* **协程的控制实例**：创建协程时返回的实例，称为**协程的描述类**。我们可以通过它控制协程的调用流转。
* **协程的状态**：调用流程转移前后，协程的状态会发生相应的变化。

#### Kotlin协程的一些概念

* 协程体：协程中需要执行的操作。是一个被 suspend 修饰的 lambda表达式： `(suspend () -> T)` 。其实是一个 `Continuation` 。
* 协程的控制实例：`Continuation`（续体）
* 协程的状态：`COROUTINE_SUSPENDED` , `UNDECIDED` , `RESUMED` 
* 挂起函数：`suspend`修饰的函数， 只能在挂起函数和协程体内调用。 挂起函数不一定挂起。
* 挂起点：程序需要调度的地方，即**真正被挂起**的位置。只有异步才需要挂起。




### 线程和协程的区别

* 线程：一旦开始执行，那么直到任务结束都就不会暂停。在Java虚拟机中，线程会直接映射为内核线程，而内核线程的**调度是由操作系统控制，通常是按时间片划分的抢占式调度**，。
* 协程：协程可以挂起暂停，稍后再恢复。调度流程是程序通过挂起和恢复自己控制的，也就是由开发者决定，并不会交给系统。**协程之间是相互协作的**。

### 异步程序对比

* 线程切换
* 函数调用栈发生变换

####  **Future**

> 异步结果 **阻塞了主调用流程**。

```kotlin
/**
 * Future 测试
 */
fun main() {
    MyLog.i(DateUtil.timeMillisToString(), "------ start")
    arrayListOf("1", "2").map {
        testFuture(it)
    }.map {
        it.get()
    }
    MyLog.i(DateUtil.timeMillisToString(), "------ finish")
}

val executors: ExecutorService = Executors.newSingleThreadExecutor()

fun testFuture(test: String): Future<String> {
    MyLog.i(DateUtil.timeMillisToString(), "testFuture $test")
    return executors.submit(Callable {
        MyLog.i(DateUtil.timeMillisToString(), "$test sleeping")
        Thread.sleep(1000L)
        MyLog.i(DateUtil.timeMillisToString(), "$test wakeup")
        test
    })
}
```

运行结果：

```shell
2022-11-02 17:06:42:350: ------ start
2022-11-02 17:06:42:393: testFuture 1
2022-11-02 17:06:42:394: testFuture 2
2022-11-02 17:06:42:394: 1 sleeping
2022-11-02 17:06:43:396: 1 wakeup
2022-11-02 17:06:43:396: 2 sleeping
2022-11-02 17:06:44:406: 2 wakeup
2022-11-02 17:06:44:406: ------ finish
```

#### **CompletableFuture**

> 异步结果不阻塞主调用流程，但是**结果脱离了主调用流程**。

```kotlin
/**
 *  CompletableFuture 测试
 */
fun main() {
    MyLog.i(DateUtil.timeMillisToString(), "------ start")
    arrayListOf("1", "2")
        .map {
            testCompletableFuture(it)
        }
        .let { list -> // 整合结果
            CompletableFuture.allOf(*list.toTypedArray())
                .thenApply {
                    list.map { it.get() }
                }
        }.thenAccept {
            MyLog.i(DateUtil.timeMillisToString(), "$it Accept")
        }
    MyLog.i(DateUtil.timeMillisToString(), "------ main sleeping")
    // 保证主线程或者，不然获取不到结果
    Thread.sleep(3000L)
    MyLog.i(DateUtil.timeMillisToString(), "------ finish")
}

fun testCompletableFuture(test: String): CompletableFuture<String> {
    MyLog.i(DateUtil.timeMillisToString(), "testCompletableFuture $test")
    return CompletableFuture.supplyAsync {
        MyLog.i(DateUtil.timeMillisToString(), "$test sleeping")
        Thread.sleep(1000L)
        MyLog.i(DateUtil.timeMillisToString(), "$test wakeup")
        test
    }
}
```

运行结果：

```shell
2022-11-02 17:19:13:293: ------ start
2022-11-02 17:19:13:333: testCompletableFuture 1
2022-11-02 17:19:13:337: testCompletableFuture 2
2022-11-02 17:19:13:337: 2 sleeping
2022-11-02 17:19:13:337: 1 sleeping
2022-11-02 17:19:13:338: ------ main sleeping
2022-11-02 17:19:14:342: 2 wakeup
2022-11-02 17:19:14:342: 1 wakeup
2022-11-02 17:19:14:342: [1, 2] Accept
2022-11-02 17:19:16:350: ------ finish
```

> 若注释了 `Thread.sleep(3000L)` 输出结果变为以下流程，说明 CompletableFuture 的执行流程脱离了 主调用流程。

```shell
2022-11-02 17:20:31:182: ------ start
2022-11-02 17:20:31:224: testCompletableFuture 1
2022-11-02 17:20:31:228: testCompletableFuture 2
2022-11-02 17:20:31:229: 2 sleeping
2022-11-02 17:20:31:229: 1 sleeping
2022-11-02 17:20:31:230: ------ main sleeping
2022-11-02 17:20:31:230: ------ finish
```

####  **Promise与async/await**

> async/await 以同步的方式 实现了异步任务的执行

```javascript
async function main() {
    try {
        const res = await Promise.all(["1", "2"].map(url => download(url)))
        console.log("res " + res)
    } catch (error) {
        console.error(e)
    }
}

function download(url) {
    return new Promise((resolve, reject) => {
        try {
            console.log("Promise " + url)
            "Promise " + url
        } catch (e) {
            reject(e)
        }
    })
}
```

#### **kotlin 协程**

> suspend 声名 挂起函数，同时函数调用的地方就是 挂起点。

```kotlin
val tag = "coroutine"

fun main() = runBlocking {
    log(tag, "---- start");
    launch {
        log(tag, "main result: $result ")
    }
    log(tag, "---- finish");
}

suspend fun testSuspendable(url: String): String {
    return suspendCoroutine { continuation ->
        thread {
            try {
                // 将正常的结果返回
                continuation.resume(download(url))
            } catch (e: Exception) {
                // 将异常返回
                continuation.resumeWithException(e)
            }
        }
    }
}

fun download(url: String): String {
    log(tag, "Download start $url")
    val file = File("testRes/src/writeToFile.txt");
    FileUtils.deleteFile(file)
    repeat(10000) {
        FileUtils.writeToFile("aaaaaaaaa", file, true)
    }
    val result = FileUtils.readFromFile(file).toString().substring(0, 10)
    log(tag, "Download end $result")
    return result
}
```

运行结果：

```shell
2022-11-03 16:56:13:575 coroutine: : ---- start
2022-11-03 16:56:13:593 coroutine: : ---- finish
2022-11-03 16:56:13:596 coroutine: : Download start testSuspendable
2022-11-03 16:56:14:867 coroutine: : Download end aaaaaaaaaa
2022-11-03 16:56:14:867 coroutine: : main result: aaaaaaaaaa 
```



## 协程的分类

不同语言间对写成的实现在细节上存在较大的差异。以下提供了2种分类方式来审视协程的角度和思路，但是这个分类并不是绝对的。

### 按调用栈分类

#### 有栈协程（Stackful Coroutine）

每一个协程都有自己的调用栈，有点类似于线程的调用栈，这种情况下的协程实现很接近线程，主要的不同体现在调度上。

> 优点

可以在任意函数调用层级的任意位置挂起，并转移调度权。如 Lua

> 缺点

需要额外开辟一块 栈内存。（Go 做了大量优化，按需扩容/缩容，内存占用相对较小）。

#### 无栈协程（Stackless Coroutine）

没有自己的调用栈。状态通过状态机或者闭包等语法实现。

* 状态机：通过状态流转 来实现 控制流转。
* 闭包：保存变量。

> Kotlin 的协程是通过 状态机 + 闭包 的方式实现的。通常被认为是 无栈协程。不过 Kotlin 通过 `suspend`函数嵌套调用的方式，实现 任意挂起函数调用层次的 挂起，这却是有栈协程的特性。

### 按调度方式分类

#### 对称协程

> 类似线程，更能体现出协程的独立性和协作性。

* 任意协程都是相互独立且平等的，不会因为调用关系而存在从属关系。

* 调度权可以在任意协程间转移。

#### 非对称协程

> 更加符合我们的思维习惯，调用有来有回，形成闭环。
>
> 是多数语言的实现方式。

* 调度权只能出让给协程的调用方，存在从属关系。

* 可以通过建立统一分发中心的方式，实现对称协程的能力。



## 协程使用案例

* 通过`createCoroutine()`创建协程体后，需要调用返回值 `Continuation`的`resume()`方法来启动协程，否则将一直处于挂起状态。
* `startCoroutine()`函数内部会在创建协程体后会立即调用`resume()`。

> `createCoroutine()` 和 `startCoroutine()` 都存在一个带 `receiver` 参数的声明，我们可以在协程体内 使用 this访问`receiver` 实例，它的作用是约束和扩展协程体。
>
> 

代码样例：

```kotlin
const val TAG = "CreateCoroutine"

/**
 * 创建协程体: createCoroutine
 * 需要调用 resume启动
 */
val continuation = suspend { // 协程体
    MyLog.i(TAG, "In Coroutine 1")
    1
}.createCoroutine(object : Continuation<Int> {
    override val context: CoroutineContext
        get() = EmptyCoroutineContext

    override fun resumeWith(result: Result<Int>) {
        // 协程结束后的回调
        MyLog.i(TAG, "Coroutine End: $result")
    }
})


/**
 * 创建并立即执行 : startCoroutine
 */
val continuation2 = suspend {
    MyLog.i(TAG, "In Coroutine 2")
    2
}.startCoroutine(object : Continuation<Int> {
    override val context: CoroutineContext
        get() = EmptyCoroutineContext

    override fun resumeWith(result: Result<Int>) {
        MyLog.i(TAG, "Coroutine End: $result")
    }
})

fun main() {
    // 调用resume()启动协程
    continuation.resume(Unit)
    // 等同上方，实际 resume 就是调用的这个方法。
//    continuation.resumeWith(Result.success(Unit))
}

```

输出结果：

```shell
CreateCoroutine: In Coroutine 2
CreateCoroutine: Coroutine End: Success(2)
CreateCoroutine: In Coroutine 1
CreateCoroutine: Coroutine End: Success(1)
```

## 协程的大体流程

*  我们可以通过 `createCoroutine()` 函数来创建协程并返回协程体 `Continuation`，是一个`SafeContinuation` 实例。
*  `SafeContinuation` 实际是个代理类，内部的 `delegate`才是 `Continuation` 的本体。
*  `delegate` 是一个匿名内部类, 继承自 `SuspendLambda`，是 `suspend lambda` 被编译器处理后生成的，`SuspendLambda` 是 `Cotinuation` 接口的实现类。
*  我们实际调用的是 `delegate.resumeWith()` 来启动协程，`delegate` 就是协程体。

*  `delegate.resumeWith()` 内部 通过 `invokeSuspend()` 启动了协程。

*  结束后调用` completion.resumeWith(outcome)` 将结果回调给我们。

![Kotlin协程类图](./Kotlin%E5%8D%8F%E7%A8%8B.assets/Kotlin%E5%8D%8F%E7%A8%8B%E7%B1%BB%E5%9B%BE.png)

## 协程启动流程分析

> 此分析流程 基于上面的 `CreateCoroutine` 代码范例，我们通过添加断点的方式跟踪协程的启动过程，从而 加深对理解 Kotlin 协程的理解。
>
> IDEA 代码跳转 到的是 `kotlin-stdlib-comom:x.xx.xx` 下，具体实现在 `kotlin-stdlib:x.xx.xx`下。
>
> 真实的源码文件 一般是 `xxxJvm.kt`  格式。
>
> 如`SafeContinuationJvm.kt`

了解大概后来看看具体流程。

### 协程的创建

通过标准库提供的  `createCoroutine()` 函数来创建协程。

#### createCoroutine()

```kotlin
@SinceKotlin("1.3")
@Suppress("UNCHECKED_CAST")
public fun <T> (suspend () -> T).createCoroutine(
    completion: Continuation<T>
): Continuation<Unit> =
    SafeContinuation(createCoroutineUnintercepted(completion).intercepted(), COROUTINE_SUSPENDED)

// receiver 参数用于约束和扩展协程体，协程体内的this 就是 receiver，从而可以执行 receiver 内的方法。
public fun <R, T> (suspend R.() -> T).createCoroutine(
    receiver: R,
    completion: Continuation<T>
): Continuation<Unit> =
    SafeContinuation(createCoroutineUnintercepted(receiver, completion).intercepted(), COROUTINE_SUSPENDED)

```

* 协程体【`(suspend () -> T)`】：是协程的执行体。它是一个 suspend Lambda 表达式。最终会被编译器处理成匿名内部类。
* 参数【`completion: Continuation<T>`】：协程的完成回调，会在协程执行完成后调用。
* 返回值【`Continuation<Unit>`】：用于触发协程的启动，内部保存了协程执行所需的上下文。

> 小结
>
> * `createCoroutine()`  是一个扩展函数，它的 receiver type 【 `(suspend () -> T)` 】是一个被 suspend 修饰的 lambda表达式，就是上方代码案例中的 `suspend { ... }`。
> *  `createCoroutine()` 返回了一个 `Continuation` 的实例，我们可以用它来启动协程。

先来看看返回的  `Continuation `  的定义。它是一个接口，包含一个 协程上下文（CoroutineContext） 和 一个 `resumeWith()` 函数。

#### Continuation

```kotlin
@SinceKotlin("1.3")
public interface Continuation<in T> {
    // 
    public val context: CoroutineContext
	
    /**
     * 恢复协程的执行
     * 参数 result 内存储的是 执行结果（某个值或异常）。
     **/
    public fun resumeWith(result: Result<T>)
}
```

接着看看 我们实际获得的  `SafeContinuation` 的实例。从源码可以发现 `SafeContinuation` 实际是 `delegate` 的代理。

#### SafeContinuation

> SafeContinuationJvm.kt

```kotlin
@PublishedApi
@SinceKotlin("1.3")
internal actual class SafeContinuation<in T>
internal actual constructor(
    private val delegate: Continuation<T>,
    initialResult: Any?
) : Continuation<T>, CoroutineStackFrame {
    @PublishedApi
    internal actual constructor(delegate: Continuation<T>) : this(delegate, UNDECIDED)

    public actual override val context: CoroutineContext
        get() = delegate.context

    // 只有 挂起的协程才需要恢复。
  	// 创建协程时，初始化为 COROUTINE_SUSPENDED
    public actual override fun resumeWith(result: Result<T>) {
        while (true) { // lock-free loop
            val cur = this.result // atomic read
            when {
              	// 未定状态，直接更新 resule 数据, 调用 getOrThrow() 将直接获得结果。
                cur === UNDECIDED -> if (RESULT.compareAndSet(this, UNDECIDED, result.value)) return
                cur === COROUTINE_SUSPENDED -> if (RESULT.compareAndSet(this, COROUTINE_SUSPENDED, RESUMED)) {
                    // 状态为 COROUTINE_SUSPENDED, 调用 resumeWith 
                    delegate.resumeWith(result)
                    return
                }
                else -> throw IllegalStateException("Already resumed")
            }
        }
    }
  
  	/**
  	 *  挂起、返回结果或异常
  	 **/
    @PublishedApi
    internal actual fun getOrThrow(): Any? {
        var result = this.result // atomic read
        if (result === UNDECIDED) {
          	// 
            if (RESULT.compareAndSet(this, UNDECIDED, COROUTINE_SUSPENDED)) return COROUTINE_SUSPENDED
            result = this.result // reread volatile var
        }
        return when {
            result === RESUMED -> COROUTINE_SUSPENDED // already called continuation, indicate COROUTINE_SUSPENDED upstream
            result is Result.Failure -> throw result.exception
            else -> result // either COROUTINE_SUSPENDED or data
        }
    }
}

```

> 小结：
>
> `SafeContinuation` 实际是一个代理, 内部的 `delegate`才是 `Continuation` 的本体，我们启动协程时实际调用的是 `delegate.resumeWith()` 
>
> * 若是 COROUTINE_SUSPENDED 状态，则将状态 更新为RESUMED 并调用 resumeWith 执行协程。
> * 若为 UNDECIDED 状态，则直接更新数据 到 RESULT，  之后调用 getOrThrow() 将直接获得结果。

新的问题： `delegate` 是什么？

#### delegate

实例是通过`createCoroutineUnintercepted(completion).intercepted()`创建的。`createCoroutineUnintercepted()`，它是一个跨平台的函数。`intercepted()` 是一个拦截处理过程，对研究整体流程没什么影响，可忽略。

> IntrinsicsJvm.kt

```kotlin
@SinceKotlin("1.3")
public actual fun <T> (suspend () -> T).createCoroutineUnintercepted(
    completion: Continuation<T>
): Continuation<Unit> {
    val probeCompletion = probeCoroutineCreated(completion)
    return if (this is BaseContinuationImpl)
        create(probeCompletion) // 调用此处
    else
        createCoroutineFromSuspendFunction(probeCompletion) {
            (this as Function1<Continuation<T>, Any?>).invoke(it)
        }
}
```

最后调用了 ` this.create()`函数创建，是  `BaseContinuationImpl` 的子类。

```kotlin
@SinceKotlin("1.3")
internal abstract class BaseContinuationImpl(
    public val completion: Continuation<Any?>?
) : Continuation<Any?>, CoroutineStackFrame, Serializable {
    
    // 内部无具体实现
    public open fun create(completion: Continuation<*>): Continuation<Unit> {
        throw UnsupportedOperationException("create(Continuation) has not been overridden")
    }
}
```

但是`BaseContinuationImpl`中没有`create()`的具体实现。单纯看源码已经没有进一步的信息。

通过断点查看 实例信息，发现它是一个匿名内部类：`com.zaze.kotlin.example.coroutine.CreateCoroutineKt$continuation$1`。

所以 创建的 **具体实现应该是在匿名内部类中**。

那么这个 匿名内部类时如何生成的呢？

阅读参考资料时得知 `delegate` 继承自 `SuspendLambda` 。是 `suspend lambda` 被编译器处理后生成的。

通过加断点日志，将`delegate`的父类型打印出来验证了一下。

````shell
delegate's super class: class kotlin.coroutines.jvm.internal.SuspendLambda
````

所以它的父类确实是 `SuspendLambda`，我们可以在同`IntrinsicsJvm.kt`下找到它。注释中也明确的写了 Suspension lambdas 是继承自这个类。

#### SuspendLambda

```kotlin
@SinceKotlin("1.3")
// Suspension lambdas inherit from this class
internal abstract class SuspendLambda(
    public override val arity: Int,
    completion: Continuation<Any?>?
) : ContinuationImpl(completion), FunctionBase<Any?>, SuspendFunction {
    constructor(arity: Int) : this(arity, null)

    public override fun toString(): String =
        if (completion == null)
            Reflection.renderLambdaToString(this) // this is lambda
        else
            super.toString() // this is continuation
}


// 主要处理了 拦截器相关的流程
@SinceKotlin("1.3")
// State machines for named suspend functions extend from this class
internal abstract class ContinuationImpl(
    completion: Continuation<Any?>?,
    private val _context: CoroutineContext?
) : BaseContinuationImpl(completion) {
    constructor(completion: Continuation<Any?>?) : this(completion, completion?.context)
}
```

> 小结
>
> `delegate` 是一个匿名内部类, 继承自 `SuspendLambda`，是 `suspend lambda` 被编译器处理后生成的。`SuspendLambda` 是一个 `Cotinuation` 接口的实现类。

#### 总结

* `createCoroutine()`  是一个扩展函数，它的 receiver type 【 `(suspend () -> T)` 】是一个被 suspend 修饰的 lambda表达式，就是上方代码案例中的 `suspend { ... }`。
*  `createCoroutine()` 返回类型为 `Continuation` ，实际是 `SafeContinuation` 的实例，我们可以用它来启动协程。

* `SafeContinuation` 本质是一个代理, 内部的 `delegate`才是 `Continuation` 的本体，我们启动协程时实际调用的是 `delegate.resumeWith()` 
* `delegate` 是一个匿名内部类, 继承自 `SuspendLambda`，是 `suspend lambda` 被编译器处理后生成的。`SuspendLambda` 也是 `Cotinuation` 接口的实现类。

### 协程的启动

#### resume()

我们通过调用 `Continuation.resume(value)` 来启动/恢复协程，参数 value 是作为最近一个挂起点的返回值， 即**调用 `resume(value)` 后，之前的 挂起点 会收到 `value` 这个返回值**。

```kotlin
@SinceKotlin("1.3")
@InlineOnly
public inline fun <T> Continuation<T>.resume(value: T): Unit =
    resumeWith(Result.success(value))
```

实际调用的是自身的 `Continuation.resumeWith()`函数，所以我们可见将上述测试代码的改成以下内容, 效果相同。

```kotlin
fun main() {
    // 调用resume()启动协程
    // continuation.resume(Unit)
    // 等同上方，实际 resume 就是调用的这个方法。
	continuation.resumeWith(Result.success(Unit))
}
```

接着在来看看 `resumeWith()` 内部又做了什么？

我们在`SuspendLambda` 的父类 `BaseContinuationImpl`中找了`resumeWith()`的具体实现：

#### resumeWith()

> `BaseContinuationImpl.resumeWith()` 内部 调用了 `invokeSuspend()`

```kotlin
@SinceKotlin("1.3")
internal abstract class BaseContinuationImpl(
    public val completion: Continuation<Any?>?
) : Continuation<Any?>, CoroutineStackFrame, Serializable {
    public final override fun resumeWith(result: Result<Any?>) {
        var current = this
        var param = result
        while (true) {
          	// 获取挂起点，需要从哪里恢复
            probeCoroutineResumed(current)
            with(current) {
                val completion = completion!! 
                val outcome: Result<Any?> =
                    try {
                        // 执行协程体， 获取返回值。此处是 1
                        val outcome = invokeSuspend(param)
                      	// 若挂起，则退出循环
                        if (outcome === COROUTINE_SUSPENDED) return
                        Result.success(outcome)
                    } catch (exception: Throwable) {
                        Result.failure(exception)
                    }
                releaseIntercepted() // this state machine instance is terminating
              	// 完成回调 是一个 具体的协程，继续执行
                if (completion is BaseContinuationImpl) {
                    // unrolling recursion via loop
                    current = completion
                  	// 返回值作为下次执行的参数
                    param = outcome
                } else {
                    // top-level completion reached -- invoke and return
                    // 协程结束的回调。
                    completion.resumeWith(outcome)
                    return
                }
            }
        }
    }

    protected abstract fun invokeSuspend(result: Result<Any?>): Any?
}
```

通过断点走一下流程：

* `resumeWith` 内部会调用 `invokeSuspend()` 会启动/恢复协程。此处打印 `In Coroutine 1` 。

* `outcome = 1` 作为返回值。

* 此处为执行后就协程结束 并调用 `completion.resumeWith(outcome)` 将结果作为参数传给回调。不过若 `completion` 依然还是一个 具体的协程，将继续进行循环，并将返回结果作为 下次循环是 执行协程体的 参数。

  

> 小结
>
> * **协程的启动/恢复相当于是 `resumeWith()` 内开始循环**：`delegate.resumeWith()` 内部 是一个死循环，循环通过 `invokeSuspend()` 执行协程体。不退出的情况下，会将返回值 `outcome` 会作为下次循环 执行协程体 的入参。
> * **协程的挂起/退出相当于退出`resumeWith()`  内的循环**：在 挂起 或者 结束 时会退出循环。结束时调用回调 ` completion.resumeWith(outcome)`，将结果返回。
>
> 新的疑问：
>
> `invokeSuspend()` 的具体实现是什么样的？

#### invokeSuspend()

invokeSUpend() 的具体实现 在编译器生成的 匿名内部类中，我们可以通过反编译的方式查看内部流程。



## 协程的组成部分

### 函数的挂起

协程的挂起就是 程序执行流程发生异步调用时，当前调用流程的执行状态进入等待状态。

* 被 `suspend` 关键字修饰的函数叫做 挂起函数。
* 挂起函数不一定会挂起，只是支持挂起的能力。
* 挂起函数可以调用任意函数，但只能在 协程体 或者 其他挂起函数内 被调用。普通函数不能调用挂起函数。

> `@RestrictsSuspension`  注解修饰 Scope 后，协程体内只能调用内部自身的 挂起函数，不能调用外部的挂起函数。
>
> 快路径（fast path）：挂起函数直接同步返回。比如提前启动的异步任务已经执行完成，结果已存在。
>
> 慢路径（slow path）：需要挂起，等待异步任务完成时通过 `Continuation` 的恢复调用返回结果。
>

#### 挂起点

协程内挂起函数的调用称为挂起点。 

在我理解中，挂起点相当于将 一个函数基于这个点 一分为二，上部分就是我们已经执行的，下部分就是我们保存的挂起点信息。

#### 协程的状态

> 通过 `createCoroutine()`  等一些构造器创建时，默认赋值为 COROUTINE_SUSPENDED 。

* UNDECIDED：待定，协程的默认状态。
* COROUTINE_SUSPENDED：挂起状态。
* RESUMED：执行中。

```kotlin
@SinceKotlin("1.3")
@PublishedApi // This class is Published API via serialized representation of SafeContinuation, don't rename/move
internal enum class CoroutineSingletons { COROUTINE_SUSPENDED, UNDECIDED, RESUMED }
```



#### suspendCoroutine

`suspendCoroutine()` 是 Kotlin 提供的拥有挂起能力的函数。若发生 异步调用则会挂起当前协程。当在 `block` 内部调用了 `safe.resume()` 将不会挂起，此时将直接返回结果。 `SafeContinuation` 保证了 仅异步是挂起。

内部调用了 `suspendCoroutineUninterceptedOrReturn()` 函数，它的具体实现，是在编译时被编译器替换的。

```kotlin
@SinceKotlin("1.3")
@InlineOnly
public suspend inline fun <T> suspendCoroutine(crossinline block: (Continuation<T>) -> Unit): T {
    contract { callsInPlace(block, InvocationKind.EXACTLY_ONCE) }
    return suspendCoroutineUninterceptedOrReturn { c: Continuation<T> ->
        val safe = SafeContinuation(c.intercepted()) // 生成一个新的 SafeContinuation，内部保存了挂起点信息。
        block(safe)
        safe.getOrThrow()
    }
}

@SinceKotlin("1.3")
@InlineOnly
@Suppress("UNUSED_PARAMETER", "RedundantSuspendModifier")
public suspend inline fun <T> suspendCoroutineUninterceptedOrReturn(crossinline block: (Continuation<T>) -> Any?): T {
    contract { callsInPlace(block, InvocationKind.EXACTLY_ONCE) }
    throw NotImplementedError("Implementation of suspendCoroutineUninterceptedOrReturn is intrinsic")
}
```

* `suspendCoroutine()` 调用时若是异步调用则会挂起当前协程，并回调一个 `Continuation` 用以恢复。
* `suspendCoroutine()` 的同步返回值 是在下次调用 `resume(value)` 恢复时获得， 返回值内容为 恢复时传入的值。



#### CPS 变换

> Continuation-Passing-Style Transformation

Kotlin 将 挂起点信息 保存在 Continuation 对象中，通过传递 Continuation 来控制异步调用流程。



### 协程的上下文

主要承载资源获取、配置管理等工作，是执行环境相关的通用数据资源的统一管理者。

* 协程上下文的结构类似 `List`、`Map`， 内部存储为一个左向链表，节点一般为 `CombinedContext`。
* 可以通过 `+` 进行 Element 的合并。

常见的有 `EmptyCoroutineContext`、`Job`、`Dispatcher`等。

#### CoroutineContext（协程上下文）

* `CoroutineContext` 接口 是一个以 Key 为索引的 **数据集合**。
* Element 是数据元素，且内部只会存放自己的数据。

* 为了方便API设计，Element 也实现了 CoroutineContext 接口。所以它即 可以是集合，也可以是元素。

```kotlin
@SinceKotlin("1.3")
public interface CoroutineContext {

    public operator fun <E : Element> get(key: Key<E>): E?

    public fun <R> fold(initial: R, operation: (R, Element) -> R): R

    // 内部会遍历当前上下文(this), 将有相同 key 的元素去除， 新的覆盖旧的
    public operator fun plus(context: CoroutineContext): CoroutineContext =
    	// 添加空上下文， 直接返回即可。
        if (context === EmptyCoroutineContext) this else
    		// fold 遍历 context上下文的链表。
            context.fold(this) { acc, element ->
                // acc：当前上下文 this 的左向链表。
                // element：context 的元素。
                // 移除 acc 中的 key 相同的 element，然后返回移除后的上下文。
                val removed = acc.minusKey(element.key)
                // 即唯一有一个相同的元素，直接返回元素
                if (removed === EmptyCoroutineContext) element else {
					// 处理拦截器
                    val interceptor = removed[ContinuationInterceptor]
                    // 不存在拦截器，构造一个 CombinedContext，继续循环处理
                    if (interceptor == null) CombinedContext(removed, element) else {
                        // 存在拦截器， 放到最后面
                        val left = removed.minusKey(ContinuationInterceptor)
                        if (left === EmptyCoroutineContext) CombinedContext(element, interceptor) else
                            CombinedContext(CombinedContext(left, element), interceptor)
                    }
                }
            }

	// 返回一个去除了指定 key 后的上下文。
    public fun minusKey(key: Key<*>): CoroutineContext
}

```

```kotlin
// Key
public interface Key<E : Element>
// 
public interface Element : CoroutineContext {

    public val key: Key<*>

    public override operator fun <E : Element> get(key: Key<E>): E? =
    @Suppress("UNCHECKED_CAST")
    if (this.key == key) this as E else null

    // 上下文添加逻辑时会用到
    // acc -> initial
    // element -> this
    public override fun <R> fold(initial: R, operation: (R, Element) -> R): R =
    operation(initial, this)

    public override fun minusKey(key: Key<*>): CoroutineContext =
    if (this.key == key) EmptyCoroutineContext else this
}


```

#### EmptyCoroutineContext

> 表示一个空的协程上下文，内部无数据。实现了 `CoroutineContext` 接口。
>

```kotlin
@SinceKotlin("1.3")
public object EmptyCoroutineContext : CoroutineContext, Serializable {
    private const val serialVersionUID: Long = 0
    private fun readResolve(): Any = EmptyCoroutineContext

    public override fun <E : Element> get(key: Key<E>): E? = null
    public override fun <R> fold(initial: R, operation: (R, Element) -> R): R = initial
    public override fun plus(context: CoroutineContext): CoroutineContext = context
    public override fun minusKey(key: Key<*>): CoroutineContext = this
    public override fun hashCode(): Int = 0
    public override fun toString(): String = "EmptyCoroutineContext"
}
```

#### CombinedContext

> `CoroutineContext` 添加元素时，主要涉及到 `CombinedContext` 类。它是 CoroutineContext 存储逻辑的具体实现类。

* CombinedContext 是一个左向链表结构。
* left：表示下一个节点。
* element：表示当前节点的元素。
* 拦截器永远位于链表的尾部，方便更快的读取拦截器。

```kotlin
@SinceKotlin("1.3")
internal class CombinedContext(
    private val left: CoroutineContext,
    private val element: Element
) : CoroutineContext, Serializable {

	....
    // 每次循环将操作结果作为下次循环的初始值(initial)。
    public override fun <R> fold(initial: R, operation: (R, Element) -> R): R =
        operation(left.fold(initial, operation), element)
	
    // 将 同key 的元素删除。去重的作用
    public override fun minusKey(key: Key<*>): CoroutineContext {
        // 相同 直接返回 left
        element[key]?.let { return left }
        // 不同，向左继续查找
        val newLeft = left.minusKey(key)
        return when {
            newLeft === left -> this
            newLeft === EmptyCoroutineContext -> element
            else -> CombinedContext(newLeft, element)
        }
    }
	....
}

```

### 协程的拦截器

拦截器也是协程上下文的一种实现，允许我们拦截协程异步回调时的恢复操作，可以在挂起点恢复执行的位置添加拦截器来实现一些 AOP 操作。协程的调度器也基于拦截器实现的。

拦截器的 Key 固定为 `ContinuationInterceptor`。

拦截器相关的流程是在 `ContinuationImpl` 中处理的

```kotlin
@SinceKotlin("1.3")
// State machines for named suspend functions extend from this class
internal abstract class ContinuationImpl(
    completion: Continuation<Any?>?,
    private val _context: CoroutineContext?
) : BaseContinuationImpl(completion) {
    constructor(completion: Continuation<Any?>?) : this(completion, completion?.context)

    public override val context: CoroutineContext
        get() = _context!!

    // 缓存拦截器用
    @Transient
    private var intercepted: Continuation<Any?>? = null

    // 调用拦截器的 `interceptContinuation()` 方法
    public fun intercepted(): Continuation<Any?> =
        intercepted
            ?: (context[ContinuationInterceptor]?.interceptContinuation(this) ?: this)
                .also { intercepted = it }

    protected override fun releaseIntercepted() {
        val intercepted = intercepted
        if (intercepted != null && intercepted !== this) {
            context[ContinuationInterceptor]!!.releaseInterceptedContinuation(intercepted)
        }
        this.intercepted = CompletedContinuation // just in case
    }
}
```

### 总结

协程的 启动/恢复 相当于开启一个循环，内部执行 协程体，每次执行结果都会作为下次循环中 执行协程体的入参。当协程挂起或者执行完毕时 退出循环。

* 协程 通过绑定 `CoroutineContext` 这个上下文，来设置一些数据丰富协程的功能。
* 协程 通过调用 `suspend` 修饰的挂起函数实现挂起。如 `suspendCoroutine()`
* 协程 通过 `Continuation.resume(value)`进行恢复。参数 `value` 将作为一个挂起点的返回值。

## 复合协程

基于 协程基础设施提供的简单协程 进行封装，得到框架层面的复合协程。方便应用。

> 复合协程的实现模式

* 协程的构造器：

* 协程的返回值：泛型声明参数。若需要返回值，也会存在泛型参数声明返回值。
* 协程的状态机：在协程的创建、启动、完成过程中，处理协程的状态流转。
* 协程的作用域：`xxScope`形式的接口，约束挂起函数的调用位置。



### 从 `Sequence` 来了解一下复合协程的组成结构

以 Kotlin 协程自带的序列生成器 `Sequence` 进行分析。

```kotlin
fun main() {
  	// 构建一个序列生成器，是一个 Iterator
    val sequence = sequence {
        yield(1)
        yield(2)
        yield(3)
        yield(4)
        yieldAll(listOf(1, 2, 3, 4))
    }
  	// for 循环时，会调用hasNext() 恢复协程
    for (element in sequence) {
        println(element)
    }
}
```

#### 协程的构造器 

```kotlin
public fun <T> sequence(@BuilderInference block: suspend SequenceScope<T>.() -> Unit): Sequence<T> = Sequence { iterator(block) }

public inline fun <T> Sequence(crossinline iterator: () -> Iterator<T>): Sequence<T> = object : Sequence<T> {
    override fun iterator(): Iterator<T> = iterator()
}
public fun <T> iterator(@BuilderInference block: suspend SequenceScope<T>.() -> Unit): Iterator<T> {
    val iterator = SequenceBuilderIterator<T>()
  	// 创建协程
    iterator.nextStep = block.createCoroutineUnintercepted(receiver = iterator, completion = iterator)
    return iterator
}
```

#### 协程的状态机

> for 循环时，会调用hasNext()。 
>
> 若数据已准备完毕，返回 true ，执行 `next()` 返回数据；若数据未准备完毕，则会调用 `resume()` 恢复协程（ `resume()`  内部进入循环）。
>
> 协程启动/恢复后，会调用 yield() 准备数据，并将协程状态更新 `COROUTINE_SUSPENDED` ，协程挂起（`resume()` 退出循环）。

```kotlin
private typealias State = Int

private const val State_NotReady: State = 0
private const val State_ManyNotReady: State = 1
private const val State_ManyReady: State = 2
private const val State_Ready: State = 3
private const val State_Done: State = 4
private const val State_Failed: State = 5

private class SequenceBuilderIterator<T> : SequenceScope<T>(), Iterator<T>, Continuation<Unit> {
    private var state = State_NotReady
    private var nextValue: T? = null
    private var nextIterator: Iterator<T>? = null
    var nextStep: Continuation<Unit>? = null

    override fun hasNext(): Boolean {
        while (true) {
            when (state) {
                State_NotReady -> {}
                State_ManyNotReady ->
                    if (nextIterator!!.hasNext()) {
                        state = State_ManyReady
                        return true
                    } else {
                        nextIterator = null
                    }
                State_Done -> return false
                State_Ready, State_ManyReady -> return true
                else -> throw exceptionalState()
            }

            state = State_Failed
            val step = nextStep!!
            nextStep = null
            step.resume(Unit) // 恢复协程
        }
    }

    override fun next(): T {
        when (state) {
            State_NotReady, State_ManyNotReady -> return nextNotReady()
            State_ManyReady -> {
                state = State_ManyNotReady
                return nextIterator!!.next()
            }
            State_Ready -> {
                state = State_NotReady
                @Suppress("UNCHECKED_CAST")
                val result = nextValue as T
                nextValue = null
                return result
            }
            else -> throw exceptionalState()
        }
    }

    private fun nextNotReady(): T {
        if (!hasNext()) throw NoSuchElementException() else return next()
    }

    private fun exceptionalState(): Throwable = when (state) {
        State_Done -> NoSuchElementException()
        State_Failed -> IllegalStateException("Iterator has failed.")
        else -> IllegalStateException("Unexpected state of the iterator: $state")
    }


    override suspend fun yield(value: T) {
      	// 保存数据，更新状态
        nextValue = value
        state = State_Ready
      	// 挂起
        return suspendCoroutineUninterceptedOrReturn { c ->
            nextStep = c
            COROUTINE_SUSPENDED
        }
    }

    override suspend fun yieldAll(iterator: Iterator<T>) {
        if (!iterator.hasNext()) return
        nextIterator = iterator
        state = State_ManyReady
        return suspendCoroutineUninterceptedOrReturn { c ->
            nextStep = c
            COROUTINE_SUSPENDED
        }
    }

    override fun resumeWith(result: Result<Unit>) {
        result.getOrThrow() // just rethrow exception if it is there
        state = State_Done
    }

    override val context: CoroutineContext
        get() = EmptyCoroutineContext
}
```

#### 协程的的返回值

`Sequence`没有返回值

```kotlin
    override fun resumeWith(result: Result<Unit>) {
        result.getOrThrow() // just rethrow exception if it is there
        state = State_Done
    }
```

#### 协程的作用域

>  协程体内只能调用内部自身的 挂起函数，不能调用外部的挂起函数。

```kotlin
@RestrictsSuspension
@SinceKotlin("1.3")
public abstract class SequenceScope<in T> internal constructor() {
    public abstract suspend fun yield(value: T)

    public abstract suspend fun yieldAll(iterator: Iterator<T>)


    public suspend fun yieldAll(elements: Iterable<T>) {
        if (elements is Collection && elements.isEmpty()) return
        return yieldAll(elements.iterator())
    }

    public suspend fun yieldAll(sequence: Sequence<T>) = yieldAll(sequence.iterator())
}

```

### 

## Kotlin协程框架

### Job（协程的描述类）

> 官方提供的协程的描述类，功能相当于线程中的Thread。可以操作协程。

```kotlin
public interface Job : CoroutineContext.Element {
  
  	// 存入上下文中后，可以通过 Key 查询
    public companion object Key : CoroutineContext.Key<Job> {
        init {
            CoroutineExceptionHandler
        }
    }
  
  	// 是否存活的状态
    public val isActive: Boolean
    public val isCompleted: Boolean
    public val isCancelled: Boolean

    @InternalCoroutinesApi
    public fun getCancellationException(): CancellationException

    public fun start(): Boolean
	
  	// 取消协程
    public fun cancel(cause: CancellationException? = null)
		
    public val children: Sequence<Job>

    @InternalCoroutinesApi
    public fun attachChild(child: ChildJob): ChildHandle

  	// 挂起 指导协程结束
    public suspend fun join()

    public val onJoin: SelectClause0

    public fun invokeOnCompletion(handler: CompletionHandler): DisposableHandle

   
    @InternalCoroutinesApi
    public fun invokeOnCompletion(
        onCancelling: Boolean = false,
        invokeImmediately: Boolean = true,
        handler: CompletionHandler): DisposableHandle
}

public typealias CompletionHandler = (cause: Throwable?) -> Unit
```

| 函数                   |                                                            |                                                              |
| ---------------------- | ---------------------------------------------------------- | ------------------------------------------------------------ |
| `join()`               | 是一个挂起函数，调用后调用处将会挂起，直到被等待协程完成。 | 1. 被等待协程已完成，join 不会挂起而是立即返回。<br />2. 被等待协程未完成，join 挂起，直到协程执行完成。<br />3. 调用协程已取消，则立即抛出 `CancellationException`。 |
| `cancel()`             | 取消协程                                                   |                                                              |
| `isActive`             | 协程是否仍在执行。true 表示在执行。                        |                                                              |
| `key`                  | 用于将Job 存入它的协程上下文中。                           |                                                              |
| `invokeOnCompletion()` | 协程结束回调。存在三种情况。                               | 1. `null`：协程正常结束。<br />2. `CancellationException`：协程被取消，这个异常需要特殊处理，和 普通的异常区分开。<br />3. 其他异常：发生了错误，需要处理异常。 |

### CoroutineState（协程的状态）



### 协程的调度器

协程的调度器也基于拦截器实现的。Kotlin 官方协程框架的默认实现方式是使用的线程调度。

## 参考资料

> 以下部分图片和解读说明摘自以下参考资料。

《深入理解Kotlin协程》