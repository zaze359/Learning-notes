

# Compose基础

## 什么是Compose

Compose是一个由 Google Android 团队官方推出的声明式UI框架，对标 我们之前使用的 View体系（命令式UI）。

> 命令式：需要从头开始，先创建View，然后拿到View，再来更新View。
>
> 声明式：事先声明好了UI布局，通过维护UI的状态来更新控件的状态。框架内部帮我们哪些命令式的操作。

### 传统的View体系

- 通过**XML** 来写布局。
- `LayoutInflater` 读取 XML 并解析，然后创建对应的View。
- 将View关联到 Window上，这里可能是 Activity、Dialog等，我们会 使用 Java 或者 Kotlin 来开发。

存在问题：

系统需要读取解析XML，在转为View，存在性能损耗。当然我们也可以直接使用代码的方式来布局并创建View，只不过写法相对繁琐。

![image-20241111011638745](./Compose%E5%9F%BA%E7%A1%80.assets/image-20241111011638745.png)

### Compose

* 是一种声明式UI框架，可以方便的 使用 Kotlin 直接以纯代码的方式来写布局。也算是顺应了时代的潮流。
* 通过修改控件的状态来刷新UI。

存在的问题：

每个状态的变更都会需要去刷新界面，这里会依赖 声明式UI框架的优化策略。跳过状态没有变化的控件，只更新状态变化的控件。

![image-20241111011116238](./Compose%E5%9F%BA%E7%A1%80.assets/image-20241111011116238-1731258681314-1.png)









## 可组合函数（composable function）

> 可组合函数用于**描述所需的界面状态**，并不是结构界面组件。
>
> Compose 在渲染时并不会转化成`View`，它的布局与渲染还是在`LayoutNode`上完成的

我们通过添加 `@Composable` 注解，即可定义一个可组合函数，这个注释会告诉 Compose 编译器：这个函数是将数据转换为界面。

```kotlin
@Composable
fun Greeting(name: String) {
    Text(text = "Hello $name!")
}
```

* 只有 Composable 函数内能调用 Composable 函数。
* 可组合函数可能会像动画的每一帧一样非常频繁地运行，所以**应避免副作用（Effect）**。
* 可组合函数可以按任何顺序执行，可组合函数可以并行运行。



### 重组

**输入更改时会再次调用可组合函数，这个过程叫做重组。**Compose 的重组是其声明式 UI 运转的基础，每当状态更新时，都会发生重组，不过会跳过尽可能多的可组合函数和 lambda，仅重组需要更新的部分。

同时重组是乐观操作，Compose 会在参数再次更改之前完成重组。如果某个参数在重组完成之前发生更改，Compose 可能会取消重组，并使用新参数重新开始。（但是 **Effect 依旧会执行，所以可能会导致异常**）。

但并不是说数据没变就不会重组，当**调用点**发生变化时也会触发重组。同时 **不稳定类型也不能跳过重组**。

> **调用点**：调用可组合项的源代码位置。会影响其在组合中的位置，因此会影响界面树。
>
> **不稳定类型**：例如一个有 var 成员的 data class。https://developer.android.com/develop/ui/compose/performance/stability
>
> **稳定类型**：不可变对象(val String等)、仅有 val 成员的 data class 。稳定类型的成员必须也是稳定类型。

* 每个调用都有**唯一的调用点和源位置**，编译器将使用它们对调用进行唯一识别。

* 当从同一个调用点多次调用某个可组合项时，除了调用点之外，还会使用**执行顺序来区分实例**。

所以左侧图例中 列表下方增加数据时，已存在部分将会被重复使用。但是在上方增加、移除或者数据重排时，将会导致参数变化的位置发生重组。

而右侧图例中通过**使用 `key` 指定唯一性** 来避免重组。

![image-20241111020554607](./Compose%E5%9F%BA%E7%A1%80.assets/image-20241111020554607.png)



#### ViewCompositionStrategy：重组策略

| 策略                                          | 说明                                                         | 使用场景                     |
| --------------------------------------------- | ------------------------------------------------------------ | ---------------------------- |
| DisposeOnDetachedFromWindowOrReleasedFromPool | 默认策略。当组合依赖的ComposeView **从 Window 分离或不在容器池**时，组合将被释放。 |                              |
| DisposeOnLifecycleDestroyed                   | ComposeView对应的Lifecycle 被销毁时，组合将被释放            |                              |
| DisposeOnViewTreeLifecycleDestroyed           | 当`ViewTreeLifecycleOwner.Lifecycle` 被销毁时，组合将被释放。即Activity.view 或者 Fragment.view 被销毁时 | Fragment 中使用ComposeView时 |





## 预览界面

添加 `@Preview` 注解后，就能在 Android Stuido 中预览布局。

> 不建议在正式函数中使用，应单独定义一个预览专用的函数。

```kotlin
@Preview(showBackground = true)
@Composable
fun DefaultPreview() {
    MyComposeTheme {
        Greeting("Android")
    }
}
```



## 布局

Compose的默认布局是重叠布局，同 FrameLayout的效果。

### 流程

Compose中父节点会在其子节点之前进行测量，但会在其子节点的尺寸和放置位置确定之后再对自身进行调整。整个过程仅测量一次子项

首先，系统会要求每个节点对自身进行测量，然后以递归方式完成所有子节点的测量，并将尺寸约束条件沿着树向下传递给子节点。再后，确定叶节点的尺寸和放置位置，并将经过解析的尺寸和放置指令沿着树向上回传。

* 节点：measure -> 递归处理子节点（无子节点则跳过） -> size and place

![在搜索结果界面树中进行测量以及确定尺寸和放置位置的顺序](Compose基础.assets/search-result-layout.svg)



帧渲染主要有三个阶段：

* **组合**：界面显示哪些内容。**运行可组合函数**构建界面说明。
* **布局**：测量并放置元素。
* **绘制**：界面元素绘制到画布（屏幕）。



![img](Compose基础.assets/phases-state-read-draw.svg)

![节点布局的三个步骤：测量子项、确定尺寸、放置子项](Compose基础.assets/layout-three-step-process.svg)

### 标准布局组件

![比较三个简单的布局可组合项：Column、Row 和 Box](Compose基础.assets/layout-column-row-box.svg)



### 约束

### 自定义布局修饰符

使用 `layout` 修饰符来修改元素的测量和布局方式。

包含2个参数：measurable（测量的元素）、constraints（来自父的约束条件）。

* 测量：`measurable.measure(constraints)`
* 指定尺寸：`layout(placeable.width, height){}`
* 放置到屏幕上：`placeable.placeRelative(0, placeableY)`

```kotlin
fun Modifier.firstBaselineToTop(
    firstBaselineToTop: Dp
) = layout { measurable, constraints ->
    // Measure the composable：测量
    val placeable = measurable.measure(constraints)

    // Check the composable has a first baseline
    check(placeable[FirstBaseline] != AlignmentLine.Unspecified)
    val firstBaseline = placeable[FirstBaseline]

    // Height of the composable with padding - first baseline
    val placeableY = firstBaselineToTop.roundToPx() - firstBaseline
    val height = placeable.height + placeableY
    // 指定可组合项的尺寸
    layout(placeable.width, height) {
        // Where the composable gets placed：放置到屏幕的位置
        placeable.placeRelative(0, placeableY)
    }
}
```

### 自定义布局

`Layout` 可组合项可以手动测量和布局子项，实现自定义布局。

measurables：需要测量的子项列表。

constraints：来自父的约束条件

```kotlin
@Composable
fun MyBasicColumn(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    Layout(
        modifier = modifier,
        content = content
    ) { measurables, constraints ->
        // Don't constrain child views further, measure them with given constraints
        // List of measured children
        val placeables = measurables.map { measurable ->
            // Measure each children
            // 测量所有子项
            measurable.measure(constraints)
        }

        // Set the size of the layout as big as it can
       	// 自定尺寸
        layout(constraints.maxWidth, constraints.maxHeight) {
            // Track the y co-ord we have placed children up to
            var yPosition = 0

            // Place children in the parent layout
            placeables.forEach { placeable ->
                // Position item on the screen
                // 放置到屏幕上
                placeable.placeRelative(x = 0, y = yPosition)

                // Record the y co-ord placed up to
                yPosition += placeable.height
            }
        }
    }
}
```



### 固有特性测量

`height(IntrinsicSize.Min)` 可将其子项的高度强行调整为最小固有高度。

该修饰符具有递归性，它将查询 `Row` 及其子项 `minIntrinsicHeight`。

```kotlin
@Composable
fun TwoTexts(
    text1: String,
    text2: String,
    modifier: Modifier = Modifier
) {
    Row(modifier = modifier.height(IntrinsicSize.Min)) {
        Text(
            modifier = Modifier
                .weight(1f)
                .padding(start = 4.dp)
                .wrapContentWidth(Alignment.Start),
            text = text1
        )
        Divider(
            color = Color.Black,
            modifier = Modifier.fillMaxHeight().width(1.dp)
        )
        Text(
            modifier = Modifier
                .weight(1f)
                .padding(end = 4.dp)
                .wrapContentWidth(Alignment.End),
            text = text2
        )
    }
}
```

> 自定义布局可以重写 `MeasurePolicy` 相关方法。

```kotlin
@Composable
fun MyCustomComposable(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    return object : MeasurePolicy {
        override fun MeasureScope.measure(
            measurables: List<Measurable>,
            constraints: Constraints
        ): MeasureResult {
            // Measure and layout here
        }

        override fun IntrinsicMeasureScope.minIntrinsicWidth(
            measurables: List<IntrinsicMeasurable>,
            height: Int
        ) = {
            // Logic here
        }

        // Other intrinsics related methods have a default value,
        // you can override only the methods that you need.
    }
}
```

---

## 交互

### 点击

> clickable：检测对元素的**点击**。

```kotlin
@Composable
fun ClickableSample() {
    val count = remember { mutableStateOf(0) }
    // content that you want to make clickable
    Text(
        text = count.value.toString(),
        modifier = Modifier.clickable(..配置参数) { count.value += 1 }
    )
}
// clickable() 包含很多配置参数
// 例如 去除水波纹
Modifier.clickable(
    interactionSource = remember { MutableInteractionSource() },
    indication = null
)
```

### 自定义手势处理

> pointerInput：提供更详细的事件。

```kotlin
Modifier.pointerInput(Unit) {
    detectTapGestures(
        onPress = { /* Called when the gesture starts */ },
        onDoubleTap = { /* Called on Double Tap */ },
        onLongPress = { /* Called on Long Press */ },
        onTap = { /* Called on Tap */ }
    )
}
```

### 滚动

* verticalScroll：垂直滚动
* horizontalScroll：水平滚动

```kotlin
@Composable
fun ScrollBoxes() {
    Column(
        modifier = Modifier
            .background(Color.LightGray)
            .size(100.dp)
            .verticalScroll(rememberScrollState()) // rememberScrollState() 获取或更改滚动状态
    ) {
        repeat(10) {
            Text("Item $it", modifier = Modifier.padding(2.dp))
        }
    }
}
```

> scrollable：滚动监听，不会真的滚动元素。

```kotlin
@Composable
fun ScrollableSample() {
    // actual composable state
    var offset by remember { mutableStateOf(0f) }
    Box(
        Modifier
            .size(150.dp)
            .scrollable(
                orientation = Orientation.Vertical,
                state = rememberScrollableState { delta -> // delta 单次滚动间隔的偏移量
                    offset += delta
                    delta
                }
            )
            .background(Color.LightGray),
        contentAlignment = Alignment.Center
    ) {
        Text(offset.toString())
    }
}
```

### 嵌套滚动

默认为从子级传到父级，当子级无法滚动时，将由父级处理。

提供了 `Modifier.nestedScroll()` 自定义协调滚动。

```kotlin
val scrollState = rememberLazyListState()
val topBarState = rememberTopAppBarState()
val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(topBarState)

Modifier.fillMaxSize()
	.nestedScroll(scrollBehavior.nestedScrollConnection)
```



### 互动状态（InteractionSource）

`InteractionSource` 提供了多种方法来获取各种互动状态。

* collectIsPressedAsState()：按下
* collectIsFocusedAsState()：焦点
* collectIsDraggedAsState()：拖动
* collectIsHoveredAsState()：悬浮在上方

```kotlin
val interactionSource = remember { MutableInteractionSource() }
val isPressed by interactionSource.collectIsPressedAsState() // 是否按下的状态

Button(
    onClick = { /* do something */ },
    interactionSource = interactionSource) {
    Text(if (isPressed) "Pressed!" else "Not pressed")
}

// 获取状态处理
val interactionSource = remember { MutableInteractionSource() }
val interactions = remember { mutableStateListOf<Interaction>() }

LaunchedEffect(interactionSource) {
    interactionSource.interactions.collect { interaction ->
        when (interaction) {
            is PressInteraction.Press -> {
                interactions.add(interaction)
            }
            is DragInteraction.Start -> {
                interactions.add(interaction)
            }
        }
    }
}
```




---

## 动画效果

[动画  | Jetpack Compose  | Android Developers](https://developer.android.com/jetpack/compose/animation)

### AnimatedVisibility

```kotlin
AnimatedVisibility(
    visible = visible,
    enter = fadeIn(), // 进入动画
    exit = fadeOut() // 退出动画
) {
    // Fade in/out the background and the foreground.
    Box(Modifier.fillMaxSize().background(Color.DarkGray)) {
        Box(
            Modifier
                .align(Alignment.Center)
                .animateEnterExit( // 子项进入/退出动画
                    // Slide in/out the inner box.
                    enter = slideInVertically(),
                    exit = slideOutVertically()
                )
                .sizeIn(minWidth = 256.dp, minHeight = 64.dp)
                .background(Color.Red)
        ) {
            // Content of the notification…
        }
    }
}
```



### animate*AsState

相关API 有 `animateDpAsState`、`animateColorAsState`  等。

```kotlin
val alpha: Float by animateFloatAsState(if (enabled) 1f else 0.5f)
Box(
    Modifier.fillMaxSize()
        .graphicsLayer(alpha = alpha)
        .background(Color.Red)
)
```

> animationSpec ：spring（弹簧）、tween、repeatable等

---



## Modifier（修饰符）

* 修改可组合项的大小、布局、行为和外观。
* 顺序会影响最终结果。如 `clickable()` 和 `padding()`，`padding()` 在后面时，内边距也可点击，反之则不可点击。

设置元素如何放置，支持链式调用

```kotlin
Modifier.fillMaxWidth().padding(vertical = 4.dp, horizontal = 8.dp)
```

| 函数                                    |                          |                                                              |
| --------------------------------------- | ------------------------ | ------------------------------------------------------------ |
| ``fillMaxWidth()``                      | 填充至其父的最大可用宽度 | 会使父布局也填充满最大可以用的空间。                         |
| ``fillMaxHeight()``                     | 填充至其父的最大可用高度 |                                                              |
| ``fillMaxSize()``                       | 填充至其父的最大可用尺寸 |                                                              |
| `width()`                               | 设置宽度                 |                                                              |
| `height()`                              | 设置高度                 | `IntrinsicSize.Min` 强行调整为最小固有高度                   |
| `widthIn(min, max)`                     | 设置最小最大宽度         |                                                              |
| `heightIn(min,max)`                     | 设置最小最大高度         |                                                              |
| ``padding()``                           | 设置内边距               | 没有外边距修饰符。                                           |
| ``paddingFromBaseline()``               | 在文本基线上方添加内边距 | 到基线保持特定距离                                           |
| ``offset()``                            | 设置x,y的偏移量          | `padding` 和 `offset` 之间的区别在于,可组合项添加 `offset` 不会改变其测量结果。需要注意在 LTR 和 RTL 这两种不同的布局方式中，它的表现将不同。对于正偏移值，在LTR中右移，RTL中左移。 |
| `absoluteOffset()`                      | 设置x,y的偏移量          | 正偏移值一律会将元素向右移。即 LTR 中的 `offset()`           |
|                                         |                          |                                                              |
| ``size(width = 10.dp, height = 10.dp)`` | 设置宽高尺寸。           |                                                              |
| `indication()`                          | 水波纹                   |                                                              |

| 特殊场景函数        |               |                                                              |
| ------------------- | ------------- | ------------------------------------------------------------ |
| `matchParentSize()` | 仅 Box 中可用 | 子布局与父项 `Box` 尺寸相同，并且不影响 `Box` 的尺寸。和 `fillMaxSize`的不同在于，它不会影响到父布局的尺寸。 |
| `weight`            | Row 和 Column | 权重                                                         |
|                     |               |                                                              |

### 绘制修饰符（在可组合项前后进行绘制）

* Modifier.drawWithContent：选择绘制顺序
* Modifier.drawBehind：在可组合项后面绘制
* Modifier.drawWithCache：绘制和缓存绘制对象。只要绘制区域的大小不变，或者读取的任何状态对象都未发生变化，对象就会被缓存

```kotlin
var pointerOffset by remember {
    mutableStateOf(Offset(0f, 0f))
}
Column(
    modifier = Modifier
        .fillMaxSize()
        .pointerInput("dragging") {
            detectDragGestures { change, dragAmount ->
                pointerOffset += dragAmount
            }
        }
        .onSizeChanged {
            pointerOffset = Offset(it.width / 2f, it.height / 2f)
        }
        .drawWithContent {
            drawContent()
            // draws a fully black area with a small keyhole at pointerOffset that’ll show part of the UI.
            drawRect(
                Brush.radialGradient(
                    listOf(Color.Transparent, Color.Black),
                    center = pointerOffset,
                    radius = 100.dp.toPx(),
                )
            )
        }
) {
    // Your composables here
}
```

### 图形修饰符（缩放、平移、旋转等变换功能）

> Modifier.graphicsLayer：提供 缩放、平移、旋转、裁剪等变换功能

```kotlin
// 缩放 scaleX
Image(
    painter = painterResource(id = R.drawable.sunset),
    contentDescription = "Sunset",
    modifier = Modifier
        .graphicsLayer {
            this.scaleX = 1.2f
            this.scaleY = 0.8f
        }
)

// 平移 translationX
Image(
    painter = painterResource(id = R.drawable.sunset),
    contentDescription = "Sunset",
    modifier = Modifier
        .graphicsLayer { 
            this.translationX = 100.dp.toPx()
            this.translationY = 10.dp.toPx()
        }
)

// 旋转 rotationX
Image(
    painter = painterResource(id = R.drawable.sunset),
    contentDescription = "Sunset",
    modifier = Modifier
        .graphicsLayer {
          	// TransformOrigin 指定旋转的原点。默认为 (0.5f,0.5f)
            this.transformOrigin = TransformOrigin(0f, 0f)
            this.rotationX = 90f
            this.rotationY = 275f
            this.rotationZ = 180f
        }
)

// 裁剪clip：graphicsLayer的裁剪功能会绘制到边界之外。
Box(
  modifier = Modifier
  .clip(RectangleShape) // 保证 graphicsLayer 不会绘制到 边界之外
  .size(200.dp)
  .border(2.dp, Color.Black)
  .graphicsLayer {
    clip = true
    shape = CircleShape
    translationY = 50.dp.toPx()
  }
  .background(Color(0xFFF06292))
) {
  Text(
    "Hello Compose",
    style = TextStyle(color = Color.Black, fontSize = 46.sp),
    modifier = Modifier.align(Alignment.Center)
  )
}

// 透明度 alpha
Image(
    painter = painterResource(id = R.drawable.sunset),
    contentDescription = "clock",
    modifier = Modifier
        .graphicsLayer {
            this.alpha = 0.5f
        }
)

// 设置合成策略，
Image(
    painter = painterResource(id = R.drawable.sunset),
    contentDescription = "clock",
    modifier = Modifier.graphicsLayer {
      // 使用屏幕外缓冲区绘制，不设置时涉及 alpha的BlendMode 不设置时将无法正常工作。
      // 如 BlendMode.Clear：合成时会将所有像素清楚，导致 Image 显示黑色或者透明显示其他图层内容。
      compositingStrategy = CompositingStrategy.Offscreen
      // CompositingStrategy.Auto 与 CompositingStrategy.Offscreen策略 完成的所有绘制都会被裁剪至绘制区域 Canvas 的大小。内部绘制的内容超过部分将不显示
		}
)

```

### 裁剪

```kotlin
Image(
    painter = painterResource(id = R.drawable.dog),
    contentDescription = stringResource(id = R.string.dog_content_description),
    contentScale = ContentScale.Crop,
    modifier = Modifier
        .size(200.dp)
        .clip(CircleShape)  // 圆形
  			// .clip(RoundedCornerShape(16.dp)) // 圆角
)

// 自定义 Shape
class SquashedOval : Shape {
    override fun createOutline(
        size: Size,
        layoutDirection: LayoutDirection,
        density: Density
    ): Outline {
        val path = Path().apply {
            // We create an Oval that starts at ¼ of the width, and ends at ¾ of the width of the container.
            addOval(
                Rect(
                    left = size.width / 4f,
                    top = 0f,
                    right = size.width * 3 / 4f,
                    bottom = size.height
                )
            )
        }
        return Outline.Generic(path = path)
    }
}
```





## View中嵌入Compose

Compose 提供了  来和 原先的 View 体系进行结合

ComposeView 源码，它实际就是一个 ViewGroup， 提供了一个 `setContent()` 函数切换到Compose环境 添加 Composeable.

```kotlin
class ComposeView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : AbstractComposeView(context, attrs, defStyleAttr) {

    private val content = mutableStateOf<(@Composable () -> Unit)?>(null)

    @Suppress("RedundantVisibilityModifier")
    protected override var shouldCreateCompositionOnAttachedToWindow: Boolean = false
        private set

    @Composable
    override fun Content() {
        content.value?.invoke()
    }

    override fun getAccessibilityClassName(): CharSequence {
        return javaClass.name
    }

    /**
     * Set the Jetpack Compose UI content for this view.
     * Initial composition will occur when the view becomes attached to a window or when
     * [createComposition] is called, whichever comes first.
     */
    fun setContent(content: @Composable () -> Unit) {
        shouldCreateCompositionOnAttachedToWindow = true
        this.content.value = content
        if (isAttachedToWindow) {
            createComposition()
        }
    }
}

abstract class AbstractComposeView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : ViewGroup(context, attrs, defStyleAttr) {}
```



### 代码创建ComposeView

```kotlin
val composeView = ComposeView(requireContext()).apply {
        // 设置重组策略，和 fragment.view 关联
        setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
  			// 这里添加 Composeable
        setContent { // 这里已经是Compose环境了
          MyApp()
        }
    }
```



## Activity 和 Fragment 中使用Compose

### Activity

```kotlin
class MainActivity : AbsActivity() {

    @OptIn(ExperimentalMaterial3WindowSizeClassApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
      	// ComponentActivity的扩展函数，是对ComposeView 对封装
        setContent {
            MyApp()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MyApp() {
  ....
}
```

### Fragment

```kotlin
class MainFragment : AbsFragment() {
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        lifecycle
        viewLifecycleOwner.lifecycle
        return ComposeView(requireContext()).apply {
            // 设置重组策略，和 fragment.view 关联
            setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
            setContent {
            	MyApp()
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MyApp() {
  ....
}
```



## Compose 和 Flutter 

> Flutter：强调的是所有平台上业务和UI的一致。最终都是在Flutter的Skia引擎上处理的，而不是对应平台的操作系统。可移植性好，性能略差。
>
> Kotlin Multiplatform + Compose Multiplatform：Compose实现多端的UI， KMP 则是会编译成指定平台的二进制文件，调用的是原生API。侧重于复用，可移植性差些，性能好。

| Compose          | Flutter      |                                                              |
| ---------------- | ------------ | ------------------------------------------------------------ |
| 树形结构界面     | 树形结构界面 | 一般尽量仅更新修改的部分                                     |
| @Composable      | Widget       | 都是元素的配置，用于描述应用的界面。而并非是真正的控件。且两者提供的常用组件的命名也十分类似 |
| CompositionLocal | Provider     | 一种数据共享的方式，同时限制了作用域。数据可以在界面树中传递 |
|                  |              |                                                              |







## 参考资料

[Jetpack Compose  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/courses/pathways/compose?hl=zh-cn)

[Jetpack Compose 界面应用开发工具包 - Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/jetpack/compose)

[Jetpack Compose  | Android Developers (google.cn)](https://developer.android.google.cn/jetpack/compose/interop)

[Compose 编程思想](https://developer.android.google.cn/jetpack/compose/mental-model)

[GitHub repo 模板](https://github.com/android/android-dev-challenge-compose)

[Compose 中的布局](https://developer.android.google.cn/jetpack/compose/layout)

[Compose 文档: 列表](https://youtu.be/BhqPpUYJYeQ)
