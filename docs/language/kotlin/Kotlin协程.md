# Kotlin协程

> 源码常出看到 expect 和 actual 修饰词，他们表示修饰的对象是跨平台的。他们一一对应同名。
>
> expect 相当于接口。actual 是真实的实现。

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

* **协程的执行体**：启动协程对应的函数，也叫 **协程体**。
* **协程的控制实例**：创建协程时返回的实例，称为**协程的描述类**。我们可以通过它控制协程的调用流转。
* **协程的状态**：调用流程转移前后，协程的状态会发生相应的变化。

#### Kotlin协程的一些概念

* 协程体：协程中需要执行的操作， `(suspend () -> T)` 一个被 suspend 修饰的 lambda表达式。其实是一个 `Continuation` 。
* 协程的控制实例：`Continuation`
* 协程的状态：
* 挂起函数：`suspend`修饰的函数， 只能在挂起函数和协程体内调用。
* 挂起点：程序被挂起的位置。


### 线程和协程的区别

* 线程：一旦开始执行，那么直到任务结束都就不会暂停。**线程之间是抢占式的调度**，由操作系统控制。
* 协程：协程可以挂起暂停，稍后再恢复。**协程之间是相互协作的**。调度流程是程序通过挂起和恢复自己控制的。

### 异步程序对比

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

## 协程启动流程分析

> 我们可以通过添加断点的方式跟踪协程的启动过程。
>
> IDEA 代码跳转 到的是 `kotlin-stdlib-comom:x.xx.xx` 下，具体实现在 `kotlin-stdlib:x.xx.xx`下。
>
> 真实的源码文件 一般是 `xxxJvm.kt`  格式。
>
> 如`SafeContinuationJvm.kt`

### 协程使用案例

* 通过`createCoroutine()`创建协程体后，需要调用返回值 `Continuation`的`resume()`方法来启动协程，否则将一直处于挂起状态。
* `startCoroutine()`函数内部会在创建协程体后会立即调用`resume()`。

> 代码样例

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

### 先看看总结

*  我们可以通过 `createCoroutine()` 函数来创建协程并返回协程体 `Continuation`，是一个`SafeContinuation` 实例。
* `SafeContinuation` 实际是个代理类，内部的 `delegate`才是 `Continuation` 的本体。
* `delegate` 是一个匿名内部类, 继承自 `SuspendLambda`，是 `suspend lambda` 被编译器处理后生成的，`SuspendLambda` 是 `Cotinuation` 接口的实现类。
* 我们实际调用的是 `delegate.resumeWith()` 来启动协程，`delegate` 就是协程体。

* `delegate.resumeWith()` 内部 通过 `invokeSuspend()` 启动了协程。

* 结束后调用` completion.resumeWith(outcome)`，并将结果回调给我们。

UML该类

![Kotlin协程类图](./Kotlin%E5%8D%8F%E7%A8%8B.assets/Kotlin%E5%8D%8F%E7%A8%8B%E7%B1%BB%E5%9B%BE.png)



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
```

* Receiver【`(suspend () -> T)`】：是协程的执行体。它是一个 suspend Lambda 表达式。最终会被编译器处理成匿名内部类。
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

    // createCoroutine 时传入的是 COROUTINE_SUSPENDED
    public actual override fun resumeWith(result: Result<T>) {
        while (true) { // lock-free loop
            val cur = this.result // atomic read
            when {
                cur === UNDECIDED -> if (RESULT.compareAndSet(this, UNDECIDED, result.value)) return
                cur === COROUTINE_SUSPENDED -> if (RESULT.compareAndSet(this, COROUTINE_SUSPENDED, RESUMED)) {
                    // 调用此处
                    delegate.resumeWith(result)
                    return
                }
                else -> throw IllegalStateException("Already resumed")
            }
        }
    }
}

```

> 小结：
>
> `SafeContinuation` 实际是一个代理, 内部的 `delegate`才是 `Continuation` 的本体，我们启动协程时实际调用的是 `delegate.resumeWith()` 

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

#### Continuation.resume()

我们通过调用 `Continuation.resume()` 来启动协程。

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

#### BaseContinuationImpl.resumeWith()

> `resumeWith()` 内部 调用了 `invokeSuspend()`

```kotlin
@SinceKotlin("1.3")
internal abstract class BaseContinuationImpl(
    public val completion: Continuation<Any?>?
) : Continuation<Any?>, CoroutineStackFrame, Serializable {
    public final override fun resumeWith(result: Result<Any?>) {
        var current = this
        var param = result
        while (true) {
            probeCoroutineResumed(current)
            with(current) {
                val completion = completion!! 
                val outcome: Result<Any?> =
                    try {
                        // 执行协程体， 获取返回值。此处是 1
                        val outcome = invokeSuspend(param)
                        if (outcome === COROUTINE_SUSPENDED) return
                        Result.success(outcome)
                    } catch (exception: Throwable) {
                        Result.failure(exception)
                    }
                releaseIntercepted() // this state machine instance is terminating
                if (completion is BaseContinuationImpl) {
                    // unrolling recursion via loop
                    current = completion
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

* 调用 `invokeSuspend()` 会启动协程：打印 `In Coroutine 1`，并返回 1 。
* 协程结束 调用 `completion.resumeWith(outcome)` 将结果作为参数传给回调。

> 小结
>
> * `delegate.resumeWith()` 内部 通过 `invokeSuspend()` 启动了协程。
>
> * 结束后调用回调 ` completion.resumeWith(outcome)`，并将结果返回。
>
> 新的疑问：
>
> `invokeSuspend()` 的具体实现是什么样的？

#### invokeSuspend()

invokeSUpend() 的具体实现 在编译器生成的 匿名内部类中，我们可以通过反编译的方式查看内部流程。



## 函数的挂起

协程的挂起就是 程序执行流程发生异步调用时，当前调用流程的执行状态进入等待状态。

* 被 `suspend` 关键字修饰的函数叫做 挂起函数。
* 挂起函数不一定会挂起，只是支持挂起的能力。
* 挂起函数可以调用任意函数，但只能在 协程体 或者 其他挂起函数内 被调用。普通函数不能调用挂起函数。

### 挂起点

协程内挂起函数的调用称为挂起点。



> CoroutineSingletons

```kotlin
@SinceKotlin("1.3")
@PublishedApi // This class is Published API via serialized representation of SafeContinuation, don't rename/move
internal enum class CoroutineSingletons { COROUTINE_SUSPENDED, UNDECIDED, RESUMED }
```



## 协程的上下文

主要承载资源获取、配置管理等工作，是执行环境相关的通用数据资源的统一管理者。

* 协程上下文的结构类似 `List`、`Map`， 内部存储为一个左向链表，节点一般为 `CombinedContext`。
* 可以通过 `+` 进行 Element 的合并。

常见的有 `EmptyCoroutineContext`、`Job`、`Dispatcher`等。

### CoroutineContext（协程上下文）

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

### EmptyCoroutineContext

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

### CombinedContext

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

## 协程的拦截器

拦截器也是协程上下文的一种实现，允许我们拦截协程异步回调时的恢复操作，可以在挂起点恢复执行的位置添加拦截器来实现一些 AOP 操作。

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













快路径（fast path）：挂起函数直接同步返回。比如提前启动的异步任务已经执行完成，结果已存在。

慢路径（slow path）：需要挂起，等待异步任务完成时通过 `Continuation` 的恢复调用返回结果。



## 总结

* 协程 通过绑定 `CoroutineContext` 这个上下文，来设置一些数据丰富协程的功能。

* 协程 通过调用 `suspend` 修饰的挂起函数实现挂起。

* 协程 通过 `Continuation`的 恢复调用进行恢复。

* 



## 参考资料

> 以下部分图片和解读说明摘自以下参考资料。

《深入理解Kotlin协程》