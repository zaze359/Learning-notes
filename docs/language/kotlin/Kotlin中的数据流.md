# Kotlin中的数据流 

**Kotlin中的数据流 以协程为基础，所以需要在协程内执行**。它可按顺序发送多个值。

是一组可通过异步方式进行计算处理的数据序列。

数据流包含三个实体：

* **提供方**：生产数据流中的数据。
* **中介（可选）**：可以修改发送到数据流的值，或修正数据流本身。
* **使用方**：使用数据流中的值



![数据流中包含的实体；使用方、可选中介和提供方](./Kotlin%E4%B8%AD%E7%9A%84%E6%95%B0%E6%8D%AE%E6%B5%81.assets/flow-entities.png)

### 冷数据流和热数据流

**冷数据流（惰性）**

* **末端操作才触发流程**：即需要时才会触发流程。

* **中间操作都是惰性求值**：即需要时才进行求值计算，不要分配所有的中间集合产物，占用内存更小，性能更佳。
* **多次使用时需要重新操作**：即每次都重新生成数据。

例如`Sequence`、`flow{...}`

**热数据流**

* **生成和消费相互独立**：生产端是立刻生成数据的，且会将数据存储。
* **从数据流收集数据不会触发任何提供方代码**：生成数据后可以直接取用，不用从头生成数据。

例如`Channel`、`StateFlow`、`SharedFlow`、`channelFlow { ... }`

### Channel

Channel 主要用于**协程间的传递数据**。用法类似Java的`BlockQueue`。

* 使用`send()`**发送数据后默认会挂起当前协程**。可以通过指定`capacity`和`onBufferOverflow` 来修改行为。
* 使用`receive()`**接收数据会后挂起当前协程**。

> 需要注意的是Channel是一种生成者消费者模式。产生的元素仅能被一方消费。即有任意一方接收后，其他消费者都无法再接收到，直到产生新的数据。
>
> 若想实现发送后多方接收可以考虑使用`SharedFlow`。

了解以下Channel构造方法的参数含义：

| 属性                                   |                                                              |                                                              |
| -------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `capacity: Int`                        | 指定通道类型；默认为`RENDEZVOUS`                             | RENDEZVOUS：无buffer，send后就会挂起，必须等待接收。<br />CONFLATED：send不会挂起。仅保留最新数据，即 receiver获得的永远是新数据。<br />BUFFERED：当元素超过buffer大小（默认为64），send会被挂起。<br />UNLIMITED：无限制, send不会挂起。 |
| `onBufferOverflow: BufferOverflow`     | 指定buffer溢出的行为，当capacity为`BUFFERED`或`RENDEZVOUS`时生效; | SUSPEND：默认，挂起。<br />DROP_OLDEST：删除最旧元素。<br />DROP_LATEST：删除最新元素。 |
| `onUndeliveredElement: ((E) -> Unit)?` | 元素发送了但是没有被接收时会调用。                           | 例如`capacity = Channel.CONFLATED`仅保留最新数据，其他被替换的数据会通过这个方法回调给我们。 |

测试案例：

```kotlin
/**
 * 发送默认会挂起当前协程, 可以通过指定capacity和onBufferOverflow修改行为。
 * 接收数据会挂起当前协程
 */
fun main() = runBlocking {
    var channel = Channel<Int>()
    // 效果等同 capacity = Channel.CONFLATED
//    channel = Channel<Int>(onBufferOverflow = BufferOverflow.DROP_OLDEST) 
    channel = Channel(capacity = Channel.CONFLATED,  onUndeliveredElement = { i ->
        println("channel onUndeliveredElement $i")
    })
//    channel = Channel(capacity = Channel.UNLIMITED)
    channel = Channel(capacity = Channel.BUFFERED)
//    channel = Channel(capacity = Channel.BUFFERED, onBufferOverflow = BufferOverflow.DROP_OLDEST)
    val job = launch {
        for (i in 0..200) {
            println("channel send $i")
            channel.send(i)
            delay(50)
        }
    }
    delay(5000)
    // receive()会挂起当前协程
    repeat(10) {
        println("channel repeat received: ${channel.receive()}")
        delay(100)
    }
    // channel支持遍历
    for (i in channel) {
        // 从10开始打印，0~9 已被消费
        println("channel foreach received: $i")
        delay(100)
        // 若不主动close()，将一直等待接收新数据
//        if (i >= 100) {
//            channel.close()
//            job.cancel()
//        }
    }
    println("Done!")
}
```



### Flow

> Flow需要在协程内执行, 是冷数据流。
>
> Flow和RxJava很像，也是响应式结构，同样支持链式调用。

* 使用`Flow builders`构建flow。

  ```kotlin
  /// 支持以下几种方式构建flow
  flowOf(...) 
  asFlow() 
  flow { ... } 
  channelFlow { ... } 
  MutableStateFlow and MutableSharedFlow 
  ```

* 通过`emit()`发送数据。
* 通过`collect() `接收数据。

> flow在消费时才会生成数据。
>
> 需要注意flow 中不能使用不同的`CoroutineContext` 来`emit()`数据，否则接收数据时将抛出异常。若需要切换上下文可以使用`flowOn`而不是`withContext()`。不过`flowOn` 更改的是上游数据流的 `CoroutineContext`，下游并不会受影响。



### StateFlow

> 是可观察的数据容器类
>
> 如果需要更新这个状态，可以使用`MutableStateFlow`

* `StateFlow`是热数据流。

* 通过`value`属性读取当前状态数据。。
* 当新使用方开始从数据流中收集数据时，它将接收信息流中的**最近一个状态及任何后续状态**。

> 官方推荐在页面中使用`repeatOnLifecycle(Lifecycle.State.xxx)`来更新界面。
>
> 因为使用 `launch` 或 `launchIn` 扩展函数从界面直接收集数据流。即使 View 不可见，这些函数也会处理事件。可能会导致应用崩溃。 
>
> `launchWhenResumed()`等扩展函数在新的源码中已经备注会引起资源浪费的问题，后续将会废弃。

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
        ...
        lifecycleScope.launch {
            // repeatOnLifecycle launches the block in a new coroutine every time the
            // lifecycle is in the STARTED state (or above) and cancels it when it's STOPPED.
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                latestNewsViewModel.uiState.collect { uiState ->
                }
            }
        }
    }
```

### SharedFlow

> `SharedFlow` 是 `StateFlow` 的可配置性极高的泛化数据流。
>
> 想更新数据可以使用`MutableSharedFlow`。

-  `replay`：针对新订阅者重新发送多个之前已发出的值。
-  `onBufferOverflow`：指定在处理缓冲区中已满时，发送的数据执行的策略。默认值为 `BufferOverflow.SUSPEND`挂起，同Channel中的配置。



## 参考资料

[学习采用 Kotlin Flow 和 LiveData 的高级协程 (google.cn)](https://developer.android.google.cn/codelabs/advanced-kotlin-coroutines?hl=zh_cn#7)

[Android 上的 Kotlin 数据流  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/kotlin/flow?hl=zh_cn)