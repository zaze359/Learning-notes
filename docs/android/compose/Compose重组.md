# 重组

Compose 是声明式工具集，它的更新方式是通过新参数调用同一个可组合项。这些参数是界面状态的表现形式。每当状态更新时，都会发生重组。

### 可组合函数（composable function）

添加 `@Composable` 注解后即可定义一个可组合函数，这个注释会告诉 Compose 编译器：这个函数是将数据转换为界面。可组合函数用于**描述所需的界面状态**，并不是结构界面组件。

```kotlin
@Composable
fun Greeting(name: String) {
    Text(text = "Hello $name!")
}
```

* 只有 Composable 函数内能调用 Composable 函数。
* 可组合函数可能会像动画的每一帧一样非常频繁地运行，所以**应避免副作用**。
* **可组合函数可以按任何顺序执行**，所以多个同级的可组合函数间不应该存在依赖关系，每个函数都需要保持独立
* **可组合函数可以并行运行**，意味着可能在后台线程池中执行。所以如果在可组合函数中调用 `viewModel`内的函数，则 Compose 可能会同时从多个线程调用该函数（因为可组合函数同时会被频繁调用）。



### 重组

**输入更改时会再次调用可组合函数，这个过程叫做重组。**

每当状态更新时，都会发生重组。重组会跳过尽可能多的可组合函数和 lambda，仅重组需要更新的部分。

同时重组是乐观操作，Compose 会在参数再次更改之前完成重组。如果某个参数在重组完成之前发生更改，Compose 可能会取消重组，并使用新参数重新开始。（但是附带效果依旧会执行，所以会导致异常）。

> **调用点**：调用可组合项的源代码位置。会影响其在组合中的位置，因此会影响界面树。

* 每个调用都有**唯一的调用点和源位置**，编译器将使用它们对调用进行唯一识别。

* 当从同一个调用点多次调用某个可组合项时，除了调用点之外，还会使用**执行顺序来区分实例**。

所以当在列表下方增加数据时，已存在部分将会被重复使用。但是在上方增加、移除或者数据重排时，将会导致参数变化的位置发生重组。

**可以使用 `key` 指定唯一性：**

```kotlin
@Composable
fun MoviesScreen(movies: List<Movie>) {
    Column {
        for (movie in movies) {
            key(movie.id) { // Unique ID for this movie
                MovieOverview(movie)
            }
        }
    }
}
```

#### ViewCompositionStrategy：重组策略

| 策略                                          | 说明                                                         | 使用场景                     |
| --------------------------------------------- | ------------------------------------------------------------ | ---------------------------- |
| DisposeOnDetachedFromWindowOrReleasedFromPool | 默认策略。当组合依赖的ComposeView **从 Window 分离或不在容器池**时，组合将被释放。 |                              |
| DisposeOnLifecycleDestroyed                   | ComposeView对应的Lifecycle 被销毁时，组合将被释放            |                              |
| DisposeOnViewTreeLifecycleDestroyed           | 当`ViewTreeLifecycleOwner.Lifecycle` 被销毁时，组合将被释放。即Activity.view 或者 Fragment.view 被销毁时 | Fragment 中使用ComposeView时 |