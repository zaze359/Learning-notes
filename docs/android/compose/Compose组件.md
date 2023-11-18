# Compose组件

[Material 组件和布局  | Jetpack Compose  | Android Developers](https://developer.android.com/jetpack/compose/layouts/material)

[Material Design：里面有在各种语言下的API导航](https://m3.material.io/)

> material、material2、material3 中的API 会存在一些差异

## AppBar

> TopAppBar

```kotlin
CenterAlignedTopAppBar(
  title = {
    Text(
      text = "TopAppBar", style = MaterialTheme.typography.titleLarge
    )
  },)
```

> BottomAppBar

```kotlin
BottomAppBar(
  containerColor = Color.Yellow, contentColor = Color.Red
) {
  Box(
    modifier = Modifier
    .fillMaxSize()
    .background(Color.Blue),
    contentAlignment = Alignment.Center
  ) {
    Text(
      modifier = Modifier.background(Color.White),
      text = "BottomAppBar",
      textAlign = TextAlign.Center,
      style = MaterialTheme.typography.titleLarge
    )
  }
}
```

## Scaffold

提供了许多槽位放置常见的顶级 Material 组件。

```kotlin
Scaffold(
  snackbarHost = { SnackbarHost(hostState = snackbarHostState) },
  topBar = { // topBar
    CenterAlignedTopAppBar(
      title = {
        Text(
          text = "TopAppBar", style = MaterialTheme.typography.titleLarge
        )
      },)
  },
  bottomBar = { // bottomBar
    BottomAppBar(
      containerColor = Color.Yellow, contentColor = Color.Red
    ) {
      Box(
        modifier = Modifier
        .fillMaxSize()
        .background(Color.Blue),
        contentAlignment = Alignment.Center
      ) {
        Text(
          modifier = Modifier.background(Color.White),
          text = "BottomAppBar",
          textAlign = TextAlign.Center,
          style = MaterialTheme.typography.titleLarge
        )
      }
    }
  }) { innerPadding ->
      // innerPadding 它的值是 topBar/bottomBar 占据的大小
      val screenModifier = Modifier.padding(innerPadding)
      Box(
        modifier = screenModifier.background(Color.Blue),
        contentAlignment = Alignment.Center
      ) {
        Text(
          text = "Content",
          color = Color.Black,
          textAlign = TextAlign.Center,
          style = MaterialTheme.typography.titleLarge
        )
      }
     }
```

## Box（容器）

一个基础的容器，是对Layout的封装。 

提供了`BoxScope` 作用域允许我们进行对组件进行排版。

```kotlin
@Composable
inline fun Box(
    modifier: Modifier = Modifier,
    contentAlignment: Alignment = Alignment.TopStart,
    propagateMinConstraints: Boolean = false,
    content: @Composable BoxScope.() -> Unit // BoxScope 提供了一些拓展功能，align
) {
    val measurePolicy = rememberBoxMeasurePolicy(contentAlignment, propagateMinConstraints)
    Layout(
        content = { BoxScopeInstance.content() },
        measurePolicy = measurePolicy,
        modifier = modifier
    )
}

@LayoutScopeMarker
@Immutable
interface BoxScope {
    @Stable
    fun Modifier.align(alignment: Alignment): Modifier
    @Stable
    fun Modifier.matchParentSize(): Modifier
}
```



## Surface

是对 `Box` 的封装，方便裁剪、设置边框和背景等设置。

> Notes：Surface中并没有像Box那样提供一个Scope，所以Surface并没有提供排版的功能，需要单独在嵌套一层Box来排版。

```kotlin
fun Surface(
    modifier: Modifier = Modifier,
    shape: Shape = RectangleShape,	// 裁剪、边框
    color: Color = MaterialTheme.colorScheme.surface, // 背景色
    contentColor: Color = contentColorFor(color), // content 中 color属性的默认颜色。若子项设置则以子项的为准
    tonalElevation: Dp = 0.dp,
    shadowElevation: Dp = 0.dp,
    border: BorderStroke? = null,
    content: @Composable () -> Unit
){
    val absoluteElevation = LocalAbsoluteTonalElevation.current + tonalElevation
    CompositionLocalProvider(
        LocalContentColor provides contentColor,
        LocalAbsoluteTonalElevation provides absoluteElevation
    ) {
        Box(
            modifier = modifier
                .surface(
                    shape = shape,
                    backgroundColor = surfaceColorAtElevation(
                        color = color,
                        elevation = absoluteElevation
                    ),
                    border = border,
                    shadowElevation = shadowElevation
                )
                .semantics(mergeDescendants = false) {}
                .pointerInput(Unit) {},
            propagateMinConstraints = true
        ) {
            content()
        }
    }
}
```

## Divider（分割线）

```kotlin
Divider(
    modifier = Modifier.padding(horizontal = 14.dp), // 设置元素如何放置。padding
    thickness = 20.dp, // 厚度
    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f) // 颜色
)
```



---

## Text（文本）

> 源码

```kotlin
fun Text(
    text: String,	// 文本
    modifier: Modifier = Modifier,		// 设置布局属性
    color: Color = Color.Unspecified,	// 颜色
    fontSize: TextUnit = TextUnit.Unspecified,	// 字体大小
    fontStyle: FontStyle? = null,								// 斜体、加粗等
    fontWeight: FontWeight? = null,							// 字体权重
    fontFamily: FontFamily? = null,							// 字体类型
    letterSpacing: TextUnit = TextUnit.Unspecified,	// 字间距
    textDecoration: TextDecoration? = null,					// 
    textAlign: TextAlign? = null,										// 对齐方式
    lineHeight: TextUnit = TextUnit.Unspecified,		// 行高
    overflow: TextOverflow = TextOverflow.Clip,			// 溢出时处理方式
    softWrap: Boolean = true,												// 
    maxLines: Int = Int.MAX_VALUE,
    onTextLayout: (TextLayoutResult) -> Unit = {},
    style: TextStyle = LocalTextStyle.current
)
```

使用方式：

```kotlin
@Preview
@Composable
fun SimpleText() {
    val offset = Offset(5.0f, 10.0f)
    Column {
        Text(
            "Hello World",
            modifier = Modifier.width(150.dp), // 宽度 150dp
            color = Color.Black, // 字体颜色
            fontSize = 20.sp, // 字号
            fontFamily = FontFamily.Serif, // 字体
            fontStyle = FontStyle.Italic, // 斜体
            fontWeight = FontWeight.Bold, // 粗体
            textAlign = TextAlign.Center, // 对齐方式：居中。实际只能水平居中，无法垂直居中
            style = TextStyle(
                fontSize = 32.sp, // 此处的优先级低于外部的 fontSize
                shadow = Shadow( // 文字阴影
                    color = Color.Blue,
                    offset = offset,
                    blurRadius = 3f
                )
            ),
        )
        // 引用资源文件
        Text(stringResource(R.string.app_name))
    }
}
```

> 文本居中
>
> 处理方案为再外部套一层 `Box` ，由`Box`来控制宽高
>
> * 水平垂直居中：设置 `contentAlignment = Alignment.Center`
> * 仅垂直居中：设置 `contentAlignment = Alignment.CenterStart`

```kotlin
Box(
  modifier = Modifier
  .fillMaxSize()
  .background(Color.Blue),
  contentAlignment = Alignment.Center
) {
  Text(
    modifier = Modifier
    .background(Color.White),
    text = "BottomAppBar",
    textAlign = TextAlign.Center,
    style = MaterialTheme.typography.titleLarge
  )
}
```



> 字体的使用。

```kotlin
// 加载 res/font 中的字体
val firaSansFamily = FontFamily(
        Font(R.font.firasans_light, FontWeight.Light),
        Font(R.font.firasans_regular, FontWeight.Normal),
        Font(R.font.firasans_italic, FontWeight.Normal, FontStyle.Italic),
        Font(R.font.firasans_medium, FontWeight.Medium),
        Font(R.font.firasans_bold, FontWeight.Bold)
)
// 直接使用 FontFamily
Text(..., fontFamily = firaSansFamily, fontWeight = FontWeight.Light)


// 定义 Typography
val MyTypography = Typography(
   body1 = TextStyle(
   fontFamily = fontFamily,
   fontWeight = FontWeight.Normal,
   fontSize = ...
),
   body2 = TextStyle(
   fontFamily = fontFamily,
   fontWeight = FontWeight.Bold,
   letterSpacing = ...
),
   h4 = TextStyle(
   fontFamily = fontFamily,
   fontWeight = FontWeight.SemiBold
   ...
),
MyAppTheme(
   typography = MyTypography
) {
...
```

> AnnotatedString（多样式文本）
>
> 类似 SpannableString

* `buildAnnotatedString` 构建 `AnnotatedString`。
* `SpanStyle`：指定文本内容的样式。
* `ParagraphStyle`：应用于整个段落，指定文字对齐、文字方向、行高和文字缩进样式。并会将整段隔离出来单独成为段落。

```kotlin
@Composable
fun ParagraphStyle() {
    Text(
        buildAnnotatedString {
            withStyle(style = ParagraphStyle(lineHeight = 30.sp)) {
                withStyle(style = SpanStyle(color = Color.Blue)) {
                    append("Hello\n")
                }
                withStyle(
                    style = SpanStyle(
                        fontWeight = FontWeight.Bold,
                        color = Color.Red
                    )
                ) {
                    append("World\n")
                }
                append("Compose")
            }
        }
    )
}
```

> SelectionContainer：文本选择

```kotlin
@Composable
fun PartiallySelectableText() {
    SelectionContainer {
        Column {
            Text("This text is selectable")
            Text("This one too")
            Text("This one as well")
          	// 禁用部分文本选择
            DisableSelection {
                Text("But not this one")
                Text("Neither this one")
            }
            Text("But again, you can select this one")
            Text("And this one too")
        }
    }
}
```

## ClickableText（可获取点击位置的文本）

```kotlin
@Composable
fun SimpleClickableText() {
    ClickableText(
        text = AnnotatedString("Click Me"),
        onClick = { offset ->
            Log.d("ClickableText", "$offset -th character is clicked.")
        }
    )
}
```

使用 `buildAnnotatedString` 添加注释：

```kotlin
@Composable
fun AnnotatedClickableText() {
    val annotatedText = buildAnnotatedString {
        append("Click ")
      	// 添加注释
        pushStringAnnotation(tag = "URL",
                             annotation = "https://developer.android.com")
        withStyle(style = SpanStyle(color = Color.Blue,
                                    fontWeight = FontWeight.Bold)) {
            append("here")
        }

        pop()
    }

    ClickableText(
        text = annotatedText,
        onClick = { offset ->
            // 获取 URL 注释内容
            annotatedText.getStringAnnotations(tag = "URL", start = offset,
                                                    end = offset)
                .firstOrNull()?.let { annotation ->
                    // If yes, we log its value
                    Log.d("Clicked URL", annotation.item)
                }
        }
    )
}
```

## TextField（文本输入）

```kotlin
@Composable
fun SimpleFilledTextFieldSample() {
    var text by remember { mutableStateOf("Hello") }
    
    TextField(
        value = text,
        onValueChange = { text = it },
        label = { Text("Label") }
    )
}
```

设置样式：

* `visualTransformation`：文本替换

```kotlin
@Composable
fun PasswordTextField() {
    var password by rememberSaveable { mutableStateOf("") }

    TextField(
        value = password,
        onValueChange = { password = it },
        label = { Text("Enter password") },
      	// 密码 * 
        visualTransformation = PasswordVisualTransformation(),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password)
    )
}
```



## Button（按钮）

各种类型按钮

> `androidx.compose.material3:material3`

```kotlin
Column(modifier = modifier.padding(24.dp)) {
  Button(onClick = {
    println("Button onClick")
  }) {
    Text("Button")
  }
  ElevatedButton(onClick = { // 按钮是浮起突出的
    println("ElevatedButton onClick")
  }) {
    Text("ElevatedButton")
  }
  FilledTonalButton(onClick = { // 扁平的填充
    println("FilledTonalButton onClick")
  }) {
    Text("FilledTonalButton")
  }
  OutlinedButton(onClick = {  // 包含边界
    println("OutlinedButton onClick")
  }) {
    Text("OutlinedButton")
  }
  TextButton(onClick = {  // 透明背景
    println("TextButton onClick")
  }) {
    Text("TextButton")
  }
}
```

![image-20221219220959203](Compose组件.assets/image-20221219220959203.png)



## Image（图片）

### 加载本地图片

```kotlin
val imageModifier = Modifier
    .size(150.dp)
    .border(BorderStroke(1.dp, Color.Black))
    .background(Color.Yellow)
Image(
  	// painter 等同 Drawable
    painter = painterResource(id = R.drawable.dog),
    contentDescription = stringResource(id = R.string.dog_content_description),
    contentScale = ContentScale.Fit,
    modifier = imageModifier
)
```

> painter之外的其他两种参数：ImageBitmap 和 ImageVector

```kotlin
val imageBitmap = ImageBitmap.imageResource(R.drawable.dog)
val imageVector = ImageVector.vectorResource(id = R.drawable.baseline_shopping_cart_24)
```

### 加载网络图片

可以使用 `rememberAsyncImagePainter()` 加载网络图片

```kotlin
Image(
    painter = rememberAsyncImagePainter(
        model = ImageRequest.Builder(LocalContext.current)
        .data(url)
        .size(1920, 1080)
        .crossfade(true)
        .build(),
        onState = { // 加载状态回调
            ZLog.d(ZTag.TAG, "onState: $it")
        }
    ),
    contentScale = ContentScale.Fit,
    modifier = Modifier.size(160.dp),
    contentDescription = ""
)

```

### 图片缩放：ContentScale

| 样式                    | 说明                                                         |
| ----------------------- | ------------------------------------------------------------ |
| ContentScale.None       | 不对来源图片应用任何缩放。如果内容小于目标边界，则不会缩放以适应相应区域。多余部分被裁剪不显示。 |
| ContentScale.Fit        | 均匀缩放图片，并保持宽高比（默认）。如果内容小于指定大小，系统会放大图片以适应边界。 |
| ContentScale.Crop       | 将图片居中裁剪到可用空间。                                   |
| ContentScale.FillHeight | 缩放来源图片，保持宽高比不变，使边界与目标高度匹配。多余宽度被裁剪不显示。 |
| ContentScale.FillWidth  | 缩放来源图片，保持宽高比不变，使边界与目标宽度匹配。多余高度被裁剪不显示。 |
| ContentScale.FillBounds | 以**非均匀**方式垂直和水平缩放内容，以填充目标边界。（注意：如果将图片放入与其宽高比不完全相符的容器中，则图片会失真） |
| ContentScale.Inside     | 缩放来源图片，使宽高保持在目标边界内。如果来源图片在两个维度上都小于或等于目标，则其行为类似于“None”。内容始终包含在边界内。如果内容小于边界，则不会应用缩放。 |

### ColorFilter：颜色处理

> 调整色调：ColorFilter.tint
>
> [BlendMode](https://developer.android.com/reference/kotlin/androidx/compose/ui/graphics/BlendMode) 指定混合模式

```kotlin
Image(
    painter = painterResource(id = R.drawable.dog),
    contentDescription = stringResource(id = R.string.dog_content_description),
    colorFilter = ColorFilter.tint(Color.Green, blendMode = BlendMode.Darken)
)
```

> 对比度：ColorFilter.colorMatrix

```kotlin
val contrast = 2f // 0f..10f (1 should be default)
val brightness = -180f // -255f..255f (0 should be default)
val colorMatrix = floatArrayOf(
    contrast, 0f, 0f, 0f, brightness,
    0f, contrast, 0f, 0f, brightness,
    0f, 0f, contrast, 0f, brightness,
    0f, 0f, 0f, 1f, 0f
)
Image(
    painter = painterResource(id = R.drawable.dog),
    contentDescription = stringResource(id = R.string.dog_content_description),
    colorFilter = ColorFilter.colorMatrix(ColorMatrix(colorMatrix))
)
```

> 颜色反转：ColorFilter.colorMatrix

```kotlin
val colorMatrix = floatArrayOf(
    -1f, 0f, 0f, 0f, 255f,
    0f, -1f, 0f, 0f, 255f,
    0f, 0f, -1f, 0f, 255f,
    0f, 0f, 0f, 1f, 0f
)
Image(
    painter = painterResource(id = R.drawable.dog),
    contentDescription = stringResource(id = R.string.dog_content_description),
    colorFilter = ColorFilter.colorMatrix(ColorMatrix(colorMatrix))
)
```

### 模糊处理：Modifier.blur()

> Android 12 及更高版本支持模糊效果。低版本无效

```kotlin
Image(
    painter = painterResource(id = R.drawable.dog),
    contentDescription = stringResource(id = R.string.dog_content_description),
    contentScale = ContentScale.Crop,
    modifier = Modifier
        .size(150.dp)
        .blur(
            radiusX = 10.dp, // 水平模糊半径
            radiusY = 10.dp, // 垂直模糊半径
            edgeTreatment = BlurredEdgeTreatment(RoundedCornerShape(8.dp))
        )
)
```

> 自定义 Painter

```kotlin
// 图片叠加
class OverlayImagePainter constructor(
    private val image: ImageBitmap,
    private val imageOverlay: ImageBitmap,
    private val srcOffset: IntOffset = IntOffset.Zero,
    private val srcSize: IntSize = IntSize(image.width, image.height),
    private val overlaySize: IntSize = IntSize(imageOverlay.width, imageOverlay.height)
) : Painter() {

    private val size: IntSize = validateSize(srcOffset, srcSize)
    override fun DrawScope.onDraw() {
        // draw the first image without any blend mode
        drawImage(
            image,
            srcOffset,
            srcSize,
            dstSize = IntSize(
                this@onDraw.size.width.roundToInt(),
                this@onDraw.size.height.roundToInt()
            )
        )
        // draw the second image with an Overlay blend mode to blend the two together
        drawImage(
            imageOverlay,
            srcOffset,
            overlaySize,
            dstSize = IntSize(
                this@onDraw.size.width.roundToInt(),
                this@onDraw.size.height.roundToInt()
            ),
            blendMode = BlendMode.Overlay
        )
    }

    /**
     * Return the dimension of the underlying [ImageBitmap] as it's intrinsic width and height
     */
    override val intrinsicSize: Size get() = size.toSize()

    private fun validateSize(srcOffset: IntOffset, srcSize: IntSize): IntSize {
        require(
            srcOffset.x >= 0 &&
                srcOffset.y >= 0 &&
                srcSize.width >= 0 &&
                srcSize.height >= 0 &&
                srcSize.width <= image.width &&
                srcSize.height <= image.height
        )
        return srcSize
    }
}


val rainbowImage = ImageBitmap.imageResource(id = R.drawable.rainbow)
val dogImage = ImageBitmap.imageResource(id = R.drawable.dog)
val customPainter = remember {
    OverlayImagePainter(dogImage, rainbowImage)
}
// 使用 Image 显示
Image(
    painter = customPainter,
    contentDescription = stringResource(id = R.string.dog_content_description),
    contentScale = ContentScale.Crop,
    modifier = Modifier.wrapContentSize()
)

// 绘制到 Box 中
Box(
    modifier =
    Modifier.background(color = Color.Gray)
        .padding(30.dp)
        .background(color = Color.Yellow)
        .paint(customPainter)
) { /** intentionally empty **/ }
```

---

## Icon（图标）

适用于小图标元素，算是 Image的简化版

```kotlin
Icon(
    Icons.Rounded.ShoppingCart,
    contentDescription = stringResource(id = R.string.shopping_cart_content_desc)
)
```

## Canvas

`Canvas` 可组合项会创建并管理基于视图的 `Canvas`。

```kotlin
Canvas(modifier = Modifier.fillMaxSize()) {
    val canvasWidth = size.width
    val canvasHeight = size.height

    drawLine(
        start = Offset(x = canvasWidth, y = 0f),
        end = Offset(x = 0f, y = canvasHeight),
        color = Color.Blue,
        strokeWidth = 5F
    )
  
    drawCircle(
        color = Color.Blue,
        center = Offset(x = canvasWidth / 2, y = canvasHeight / 2),
        radius = size.minDimension / 4
    )
  	// 矩形，顺时针旋转 45度
    rotate(degrees = 45F) {
        drawRect(
            color = Color.Gray,
            topLeft = Offset(x = canvasWidth / 3F, y = canvasHeight / 3F),
            size = canvasSize / 3F
        )
    }
  	// withTransform 组合动画
    withTransform({
      translate(left = canvasWidth / 5F)
      rotate(degrees = 45F)
    }) {
      drawRect(
        color = Color.Gray,
        topLeft = Offset(x = canvasWidth / 3F, y = canvasHeight / 3F),
        size = canvasSize / 3F
      )
    }
}
```

## Brush（渐变和着色器）

有`HorizontalGradient`、 `LinearGradient` 、`RadialGradient`、`SolidColor`等Brush

```kotlin
// 横向渐变
val brush = Brush.horizontalGradient(listOf(Color.Red, Color.Blue))
Canvas(
    modifier = Modifier.size(200.dp),
    onDraw = {
        drawCircle(brush)
    }
)

```

> colorStop 更改颜色分布
>
> 0 ~ 1 指定影响范围

```kotlin
val colorStops = arrayOf(
    0.0f to Color.Yellow,
    0.2f to Color.Red,
    1f to Color.Blue
)
Box(
    modifier = Modifier
        .requiredSize(200.dp)
        .background(Brush.horizontalGradient(colorStops = colorStops))
)
```

> TileMode：指定图形重复方式
>
> * TileMode.Repeated：重复
> * TileMode.Mirror：镜像
> * TileMode.Clamp：采样最近一个的色值，将剩余空间填充。
> * TileMode.Decal：透明的黑色对原始边界以外的内容进行采样，并填充。

```kotlin
val listColors = listOf(Color.Yellow, Color.Red, Color.Blue)
val tileSize = with(LocalDensity.current) {
    50.dp.toPx()
}
Box(
    modifier = Modifier
        .requiredSize(200.dp)
        .background(
            Brush.horizontalGradient(
                listColors,
                endX = tileSize,
                tileMode = TileMode.Repeated
            )
        )
)
```

> 使用图片作为 Brush：可以用图片来绘制文字背景等各种图形

```kotlin
val imageBrush =
    ShaderBrush(ImageShader(ImageBitmap.imageResource(id = R.drawable.dog)))

// Use ImageShader Brush with TextStyle
Text(
    text = "Hello Android!",
    style = TextStyle(
        brush = imageBrush,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 36.sp
    )
)

// Use ImageShader Brush with DrawScope#drawCircle()
Canvas(onDraw = {
    drawCircle(imageBrush)
}, modifier = Modifier.size(200.dp))
```



## Snackbar（信息提示）

* 调用 `rememberScaffoldState()` 获取 `scaffoldState`
* 传递给 `Scaffold`。
* 调用 `scaffoldState.snackbarHostState.showSnackbar()`  显示提示信息。

```kotlin
val scaffoldState = rememberScaffoldState()
val scope = rememberCoroutineScope()
Scaffold(
    scaffoldState = scaffoldState,
    floatingActionButton = {
        ExtendedFloatingActionButton(
            text = { Text("Show snackbar") },
            onClick = {
                scope.launch {
                    val result = scaffoldState.snackbarHostState
                        .showSnackbar(
                            message = "Snackbar",
                            actionLabel = "Action",
                            // Defaults to SnackbarDuration.Short
                            duration = SnackbarDuration.Indefinite
                        )
                    when (result) {
                        SnackbarResult.ActionPerformed -> {
                            /* Handle snackbar action performed */
                          // 点击 snackbar actionLabel 触发事件时
                        }
                        SnackbarResult.Dismissed -> {
                            /* Handle snackbar dismissed */
                        }
                    }
                }
            }
        )
    }
) {
    // Screen content
}
```

> material3

* 调用 `remember { SnackbarHostState() }` 获取 `snackbarHostState`
* 根据 `snackbarHostState` 创建 `SnackbarHost` 传递给 `Scaffold`。
* 调用 `snackbarHostState.showSnackbar()`  显示提示信息。

```kotlin
val snackbarHostState: SnackbarHostState = remember { SnackbarHostState() }

Scaffold(
  snackbarHost = {
    MySnackbarHost(hostState = snackbarHostState)
  },

){...}


@Composable
fun MySnackbarHost(
    hostState: SnackbarHostState,
    modifier: Modifier = Modifier,
    snackbar: @Composable (SnackbarData) -> Unit = { Snackbar(it) }
) {
    SnackbarHost(
        hostState = hostState,
        modifier = modifier
            .systemBarsPadding()
            .wrapContentWidth(align = Alignment.Start)
            .widthIn(max = 550.dp),
        snackbar = snackbar
    )
}

// showSnackbar
LaunchedEffect(errorMessageText, retryMessageText, snackbarHostState) {
  val snackbarResult = snackbarHostState.showSnackbar(
    message = errorMessageText,
    actionLabel = retryMessageText
  )
  if (snackbarResult == SnackbarResult.ActionPerformed) {
    onRefreshPostsState()
  }
  // Once the message is displayed and dismissed, notify the ViewModel
  onErrorDismissState(errorMessage.id)
}

```



## Column（列）和Row（行）

Column 和 Row 所有列表项无论是否可见都会进行组合和布局，所以当存在大量列表项时应该使用 LazyColumn 和 LazyRow。

* Column：每个子级都将垂直放置的垂直列表
* Row：每个子级都将水平放置的水平列表

> 源码

```kotlin
inline fun Column(
    modifier: Modifier = Modifier,
    verticalArrangement: Arrangement.Vertical = Arrangement.Top,
    horizontalAlignment: Alignment.Horizontal = Alignment.Start,
    content: @Composable ColumnScope.() -> Unit
) {
    val measurePolicy = columnMeasurePolicy(verticalArrangement, horizontalAlignment)
    Layout(
        content = { ColumnScopeInstance.content() },
        measurePolicy = measurePolicy,
        modifier = modifier
    )
}
```

> 范例
>
> 设置位置：
>
> * `Row` ： `horizontalArrangement` 和 `verticalAlignment` 。
> * `Column`： `verticalArrangement` 和 `horizontalAlignment`

```kotlin
  Column(modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
        ) {
        Text(
            text = "Hello $name!",
            color = Color.Green,
        )
        Text(
            text = "Hello $name!",
            color = Color.Red,
        )
    }
```

### 滚动

默认是没有滚动的。

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



## LazyColumn 和 LazyRow

延迟加载的列表，默认存在滚动效果，相当于 RecyclerView，**只会对在组件视口中可见的列表项进行组合和布局**。

和 RecyclerView 的区别是 但是 LazyColumn 不会回收其子元素, 而是在滚动时进行重新组合。

```kotlin
LazyColumn {
  	// 添加单个列表项
    item {
        Text(text = "First item")
    }

  	// 添加多个列表项
    items(5) { index ->
        Text(text = "Item: $index")
    }

    item {
        Text(text = "Last item")
    }
}

@Composable
fun MessageList(messages: List<Message>) {
    LazyColumn {
        items(
            items = messages,
            key = { message -> // 能避免key 未修改项每次都重组，同时也能防止列表数据更新丢失状态（例如滑动位置）
                // Return a stable + unique key for the item
                message.id
            }
        ) { message ->
            MessageRow(message)
        }
    }
}

// 内容内边距。
// 项内容中 左右16，上下8
LazyColumn(
    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
) {
    // ...
}

// 内容间距
// 每个列表项之间 4dp
LazyColumn(
    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
) {
    // ...
}
```

> 粘性标题

```kotlin
LazyColumn {
  grouped.forEach { (initial, contactsForInitial) ->
                   stickyHeader {
                     CharacterHeader(initial)
                   }

                   items(contactsForInitial) { contact ->
                                              ContactListItem(contact)
                                             }
                  }
}
```

> 响应滚动位置

```kotlin
@OptIn(ExperimentalAnimationApi::class) // AnimatedVisibility
@Composable
fun MessageList(messages: List<Message>) {
    Box {
        val listState = rememberLazyListState()

        LazyColumn(state = listState) {
            // ...
        }

        val showButton by remember {
            derivedStateOf { // 获取第一个可见项
                listState.firstVisibleItemIndex > 0
            }
        }

        AnimatedVisibility(visible = showButton) {
            ScrollToTopButton()
        }
    }
}
```

> 控制滚动位置

```kotlin
@Composable
fun MessageList(messages: List<Message>) {
    val listState = rememberLazyListState()
    // Remember a CoroutineScope to be able to launch
    val coroutineScope = rememberCoroutineScope()

    LazyColumn(state = listState) {
        // ...
    }

    ScrollToTopButton(
        onClick = {
            coroutineScope.launch {
                // Animate scroll to the first item  平滑滚动
              	// scrollToItem() 立即滚动
                listState.animateScrollToItem(index = 0)
            }
        }
    )
}
```

> 添加 `contentType`
>
> 此时Compose 只会在相同类型的项之间重复使用组合。

```kotlin
LazyColumn {
    items(elements, contentType = { it.type }) {
        // ...
    }
}
```



## Grid（网格）

> `LazyVerticalGrid` 和 `LazyHorizontalGrid` 可组合项为在网格中显示列表项提供支持。延迟垂直网格会在可垂直滚动容器中跨多个列显示其列表项，而延迟水平网格则会在水平轴上有相同的行为。

```kotlin
@Composable
fun PhotoGrid(photos: List<Photo>) {
    LazyVerticalGrid(
      	// 或 rows 用于控制单元格组成列或行的方式
      	// 指定每列的宽度为128dp
      	// GridCells.Fixed 指定列数。
        columns = GridCells.Adaptive(minSize = 128.dp)
    ) {
        items(photos) { photo ->
            PhotoItem(photo)
        }
    }
}
```

## StaggeredGrid：瀑布流

* LazyVerticalStaggeredGrid：垂直瀑布流
* LazyHorizontalStaggeredGrid：水平瀑布流





## Paging（分页）

引入 Paging 库 ``androidx.paging:paging-compose``

```kotlin
import androidx.paging.compose.collectAsLazyPagingItems
import androidx.paging.compose.items

@Composable
fun MessageList(pager: Pager<Int, Message>) {
    val lazyPagingItems = pager.flow.collectAsLazyPagingItems()

    LazyColumn {
        items(
          items = lazyPagingItems,
          // The key is important so the Lazy list can remember your
          // scroll position when more items are fetched!
          key = { message -> message.id }
        ) { message ->
            if (message != null) {
                MessageRow(message)
            } else {
                MessagePlaceholder()
            }
        }
    }
}
```



---

## ConstraintLayout

Compose 能够高效的处理较深的布局层次结构，一般情况下不需要使用 `ConstraintLayout` 。

它的使用场景一般有以下情况：

- **提高代码的可读性**：为了避免在屏幕上定位元素时嵌套多个 `Column` 和 `Row`。
- **依赖其他项定位**：相对于其它可组合项来定位可组合项，或根据引导线、屏障线或链来定位可组合项。

使用方式：

* 为可组合项创建引用：`createRefs()` 或 `createRefFor()` 。
* 提供约束条件：`constrainAs(ref){}`。lambda 中指定具体的约束条件。

```kotlin
@Composable
fun ConstraintLayoutContent() {
    ConstraintLayout {
        // Create references for the composables to constrain
        val (button, text) = createRefs()

        Button(
            onClick = { /* Do something */ },
            // Assign reference "button" to the Button composable
            // and constrain it to the top of the ConstraintLayout
            modifier = Modifier.constrainAs(button) {
                top.linkTo(parent.top, margin = 16.dp)
            }
        ) {
            Text("Button")
        }

        // Assign reference "text" to the Text composable
        // and constrain it to the bottom of the Button composable
        Text("Text", Modifier.constrainAs(text) {
            top.linkTo(button.bottom, margin = 16.dp)
        })
    }
}
```

> 使用 `ConstraintSet` 将约束传递。通过 `layoutId()` 分配引用。可以将约束和布局解偶，方便后续更换约束。

```kotlin
@Composable
fun DecoupledConstraintLayout() {
    BoxWithConstraints {
        val constraints = if (minWidth < 600.dp) {
            decoupledConstraints(margin = 16.dp) // Portrait constraints
        } else {
            decoupledConstraints(margin = 32.dp) // Landscape constraints
        }

        ConstraintLayout(constraints) {
            Button(
                onClick = { /* Do something */ },
                modifier = Modifier.layoutId("button")
            ) {
                Text("Button")
            }

            Text("Text", Modifier.layoutId("text"))
        }
    }
}

private fun decoupledConstraints(margin: Dp): ConstraintSet {
    return ConstraintSet {
        val button = createRefFor("button")
        val text = createRefFor("text")

        constrain(button) {
            top.linkTo(parent.top, margin = margin)
        }
        constrain(text) {
            top.linkTo(button.bottom, margin)
        }
    }
}
```

### 引导线

* 水平引导线：`top` 、`bottom`。
* 垂直引导线：`start` 、 `end`。
* `createGuidelineFrom*` 创建引导线，在 `Modifier.constrainAs()` 中使用。

```kotlin
 // Create guideline from the start of the parent at 10% the width of the Composable
val startGuideline = createGuidelineFromStart(0.1f)
// Create guideline from the end of the parent at 10% the width of the Composable
val endGuideline = createGuidelineFromEnd(0.1f)
//  Create guideline from 16 dp from the top of the parent
val topGuideline = createGuidelineFromTop(16.dp)
//  Create guideline from 16 dp from the bottom of the parent
val bottomGuideline = createGuidelineFromBottom(16.dp)
```



### 屏障线

根据所指定边中处于**最边缘位置的 widget** 创建虚拟引导线。

```kotlin
val topBarrier = createTopBarrier(button, text)
val bottomBarrier = createBottomBarrier(button, text)
val startBarrier = createStartBarrier(button, text)
val endBarrier = createEndBarrier(button, text)
```



### 链

可在水平或垂直方向创建链。

```kotlin
val verticalChain = createVerticalChain(button, text, chainStyle = ChainStyle.Spread)
val horizontalChain = createHorizontalChain(button, text)
```

- `ChainStyle.Spread`：空间会在**所有可组合项之间均匀分布**。
- `ChainStyle.SpreadInside`：空间会在**所有可组合项之间均匀分布，不包括第一个可组合项之前或最后一个可组合项之后的任何可用空间。**
- `ChainStyle.Packed`：空间会分布在第一个可组合项之前和最后一个可组合项之后，**各个可组合项之间没有空间，会挤在一起**。



---

## ModalNavigationDrawer：侧边抽屉

> Material3
>
> [androidx.compose.material3  | Android Developers](https://developer.android.com/reference/kotlin/androidx/compose/material3/package-summary#ModalNavigationDrawer(kotlin.Function0,androidx.compose.ui.Modifier,androidx.compose.material3.DrawerState,kotlin.Boolean,androidx.compose.ui.graphics.Color,kotlin.Function0))

```kotlin
val drawerState = rememberDrawerState(DrawerValue.Closed)
val scope = rememberCoroutineScope()
// icons to mimic drawer destinations
val items = listOf(Icons.Default.Favorite, Icons.Default.Face, Icons.Default.Email)
val selectedItem = remember { mutableStateOf(items[0]) }
ModalNavigationDrawer(
    drawerState = drawerState,
    drawerContent = { // 抽屉内的导航内容
        ModalDrawerSheet {
            Spacer(Modifier.height(12.dp))
            items.forEach { item ->
                NavigationDrawerItem(
                    icon = { Icon(item, contentDescription = null) },
                    label = { Text(item.name) },
                    selected = item == selectedItem.value,
                    onClick = {
                        scope.launch { drawerState.close() }
                        selectedItem.value = item
                    },
                    modifier = Modifier.padding(NavigationDrawerItemDefaults.ItemPadding)
                )
            }
        }
    },
    content = { // 显示的内容
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(text = if (drawerState.isClosed) ">>> Swipe >>>" else "<<< Swipe <<<")
            Spacer(Modifier.height(20.dp))
            Button(onClick = { scope.launch { drawerState.open() } }) {
                Text("Click to open")
            }
        }
    }
)
```



## NavHost：导航

### 添加依赖

```kotlin
dependencies {
    def nav_version = "2.5.3"

    implementation("androidx.navigation:navigation-compose:$nav_version")
}
```

### 创建 NavHostController

使用 `rememberNavController()` 创建 `NavHostController`，用于控制导航

```kotlin
val navController = rememberNavController()
```

### 创建并关联 NavHost

用于配置导航路径图，

```kotlin
// 创建 NavHost
// startDestination 指定初始页面
NavHost(navController = navController, startDestination = "profile") {
  	// 添加对于导航目标
    composable("profile") { Profile(/*...*/) } 
    composable("friendslist") { FriendsList(/*...*/) }
    /*...*/
}

// navigation 定义导航结构。当导航图较大时建议进行拆分。
fun NavGraphBuilder.loginGraph(navController: NavController) {
    navigation(startDestination = "username", route = "login") {
        composable("username") { ... }
        composable("password") { ... }
        composable("registration") { ... }
    }
}
NavHost(navController, startDestination = "home") {
    ...
    loginGraph(navController)
    ...
}
```

### 导航到目的地

使用 `navigate()` 执行导航   

```kotlin
navController.navigate("friendslist")

// Pop everything up to the "home" destination off the back stack before
// navigating to the "friendslist" destination
navController.navigate("friendslist") {
    popUpTo("home") // 弹出home 之上的所有，不包括 home 
}

// Pop everything up to and including the "home" destination off
// the back stack before navigating to the "friendslist" destination
navController.navigate("friendslist") {
    popUpTo("home") { inclusive = true } // 弹出home及其他。
}

// 
navController.navigate("search") {
	popUpTo(navController.graph.findStartDestination().id) {
    // 配置仅保留顶级导航的状态
    saveState = true
  }
  // 避免同一个目标产生多个副本
	launchSingleTop = true 
  // 重新选择以前选定的项目时 恢复状态
	restoreState = true
}


```

### 参数导航

```kotlin
NavHost(startDestination = "profile/{userId}") {
  	// 定义参数导航（不建议传递复杂数据）
    // 指定参数类型：NavType.StringType
    composable(
        "profile/{userId}",
        arguments = listOf(navArgument("userId") { type = NavType.StringType })
    ) { backStackEntry -> // NavBackStackEntry 中获取参数
    	Profile(navController, backStackEntry.arguments?.getString("userId"))
		}
  	// 可选参数：?userId={userId}
  	// 需要默认值defaultValue 或 nullability = true
    composable(
        "profile?userId={userId}",
        arguments = listOf(navArgument("userId") { defaultValue = "user1234" })
    ) { backStackEntry -> // 获取参数
        Profile(navController, backStackEntry.arguments?.getString("userId"))
    }
}

// 传参： "profile/{userId}" 
navController.navigate("profile/user1234")
```

### 获取参数

通过 backStackEntry 获取参数

```kotlin
		composable(
        "profile?userId={userId}",
        arguments = listOf(navArgument("userId") { defaultValue = "user1234" })
    ) { backStackEntry -> // 获取参数
        Profile(navController, backStackEntry.arguments?.getString("userId"))
    }
```

### 深层链接（DeepLink）

```kotlin
NavHost(startDestination = "profile/{id}") {
  	// 深层链接 deepLinks
  	// https://www.example.com/{id} 这种格式
  	val uri = "https://www.example.com"
    composable(
        "profile?id={id}",
        deepLinks = listOf(navDeepLink { uriPattern = "$uri/{id}" }) 
    ) { backStackEntry ->
        Profile(navController, backStackEntry.arguments?.getString("id"))
    }
}
```

> 对外公开 需要在 manifest.xml 中声明

```kotlin
<activity …>
  <intent-filter>
    ...
    <data android:scheme="https" android:host="www.example.com" />
  </intent-filter>
</activity>
```

>  执行跳转

```kotlin
val id = "exampleId"
val context = LocalContext.current
val deepLinkIntent = Intent(
    Intent.ACTION_VIEW,
    "https://www.example.com/$id".toUri(),
    context,
    MyActivity::class.java
)

val deepLinkPendingIntent: PendingIntent? = TaskStackBuilder.create(context).run {
    addNextIntentWithParentStack(deepLinkIntent)
    getPendingIntent(0, PendingIntent.FLAG_UPDATE_CURRENT)
}
```

### 集成底部导航

> 添加依赖

```kotlin
dependencies {
    implementation("androidx.compose.material:material:1.3.1")
}

android {
    buildFeatures {
        compose = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.3.2"
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}
```

使用密封的类 定义导航路径

```kotlin
sealed class Screen(val route: String, @StringRes val resourceId: Int) {
    object Profile : Screen("profile", R.string.profile)
    object FriendsList : Screen("friendslist", R.string.friends_list)
}
```

完整案例：

```kotlin
// 定义导航项
val items = listOf(
   Screen.Profile,
   Screen.FriendsList,
)

val navController = rememberNavController()
Scaffold(
  bottomBar = {
    BottomNavigation {
      val navBackStackEntry by navController.currentBackStackEntryAsState()
      val currentDestination = navBackStackEntry?.destination
      items.forEach { screen ->
        BottomNavigationItem(
          icon = { Icon(Icons.Filled.Favorite, contentDescription = null) },
          label = { Text(stringResource(screen.resourceId)) },
          selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
          onClick = {
            // 执行导航
            navController.navigate(screen.route) {
              // Pop up to the start destination of the graph to
              // avoid building up a large stack of destinations
              // on the back stack as users select items
              popUpTo(navController.graph.findStartDestination().id) {
                saveState = true
              }
              // Avoid multiple copies of the same destination when
              // reselecting the same item
              launchSingleTop = true
              // Restore state when reselecting a previously selected item
              restoreState = true
            }
          }
        )
      }
    }
  }
) { innerPadding ->
  // 定义导航
  NavHost(navController, startDestination = Screen.Profile.route, Modifier.padding(innerPadding)) {
    composable(Screen.Profile.route) { Profile(navController) }
    composable(Screen.FriendsList.route) { FriendsList(navController) }
  }
}
```



### 使用基于 fragment 的 Navigation 从 Compose 导航

> nav_profile 定义了 导航路径

```kotlin
override fun onCreateView( /* ... */ ) {
    setContent {
        MyScreen(onNavigate = { dest -> findNavController().navigate(dest) })
    }
}

@Composable
fun MyScreen(onNavigate: (Int) -> ()) {
    Button(onClick = { onNavigate(R.id.nav_profile) } { /* ... */ }
}
```



## **Accompanist** 

[Accompanist (google.github.io)](https://google.github.io/accompanist/)

[google/accompanist: A collection of extension libraries for Jetpack Compose (github.com)](https://github.com/google/accompanist)

```kotlin
implementation("com.google.accompanist:accompanist-flowlayout:0.28.0")
implementation("com.google.accompanist:accompanist-pager:0.28.0")
implementation("com.google.accompanist:accompanist-permissions:0.28.0")
implementation("com.google.accompanist:accompanist-swiperefresh:0.28.0")
implementation("com.google.accompanist:accompanist-systemuicontroller:0.28.0")
```



### 权限配置

```kotlin
implementation("com.google.accompanist:accompanist-permissions:0.28.0")
```

提供了 PermissionState 来获取权限状态

> 需要注意的是，一开始获取到的shouldShowRationale 是false, 需要调用一下`permissionState.launchPermissionRequest()`，才能获取到真正的状态。

```kotlin
@OptIn(ExperimentalPermissionsApi::class)
@Composable
fun PermissionRequired() {
    // flag 记录是否已经请求过权限，保证shouldShowRationale能获取到值。
    val flag = remember {
        mutableStateOf(0)
    }
    val permissionState = rememberPermissionState(
        permission = permission
    ) {// 申请权限后回调
        if (!it) {
            flag.value++
        }
    }
    when (permissionState.status) {
        PermissionStatus.Granted -> {
            // 获取到权限
        }
        is PermissionStatus.Denied -> {
            if (flag.value > 0 && permissionState.status is PermissionStatus.Denied && !permissionState.status.shouldShowRationale) {
                // 权限被永久拒绝

            } else {
                // 当前无权限 申请权限

                permissionState.launchPermissionRequest()
            }
        }
    }
}

```

