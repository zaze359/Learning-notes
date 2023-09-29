# Flutter学习笔记

[Flutter核心原理](./Flutter核心原理.md)

## 一、Flutter简介

### 1.1 特性

*   使用Dart开发。

*   使用自己的渲染引擎自绘UI，不依赖于原生控件。

*   跨平台，支持Android、IOS、Windows等众多平台。

### 1.2 框架结构

![Flutter框架结构](./Flutter%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/1-1.82c25693.png)

Framework层：

| 模块                                     | 分类        | 包                                      |
| -------------------------------------- | --------- | -------------------------------------- |
| Foundation、Animation、Painting、Gestures | dart UI 层 | 它是Flutter Engine暴露的底层UI库，提供动画、手势及绘制功能。 |
| Rendering                              | 渲染层       | 构建渲染树，对变化部分进行更新渲染。                     |
| Widgets                                | 基础组建库     | 基础组建库。                                 |
| Material、Cupertino                     | 风格组件      | 基于Material和IOS设计规范的组建库                 |

Engine层：

主要由C/C++实现，包括了 Skia 引擎、Dart 运行时、文字排版引擎等。实现真正的绘制和显示。

Embedder层：

调用所在平台的操作系统的API。



## 二、搭建Flutter开发环境

[1.3 搭建Flutter开发环境 | 《Flutter实战·第二版》 (flutterchina.club)](https://book.flutterchina.club/chapter1/install_flutter.html#_1-3-1-安装flutter)

修改`~/.bash_profile`配置镜像站:

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn  
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

### 2.1 Flutter安装与配置

> 不需要安装 dart了，flutter sdk自带了 dart

#### mac下使用brew安装

命令：

```shell
# 安装flutter
brew install --cask flutter
# 安装dart sdk
brew tap dart-lang/dart
brew install dart
# dart更新
brew upgrade dart
# 强制link dart
brew link --overwrite dart
```

```bash
# flutter安装目录
/usr/local/Caskroom/flutter/
```

#### Windows下安装

[在 Windows 操作系统上安装和配置 Flutter 开发环境 - Flutter 中文文档 - Flutter 中文开发者网站 - Flutter](https://flutter.cn/docs/get-started/install/windows)

1. **安装Dart SDK**：[Get the Dart SDK | Dart](https://dart.dev/get-dart)

> 需要先安装[choco](https://chocolatey.org/install)包管理工具
>
> PowerShell中输入以下命令，等待一会，直到完成。

```shell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

安装失败删除`C:\ProgramData\chocolatey`，重新执行即可。

> dart sdk安装完成位置：`C:\tools\dart-sdk`

```shell
# To install the Dart SDK:
choco install dart-sdk
# To upgrade the Dart SDK:
choco upgrade dart-sdk
```

2. **下载Flutter SDK**：[Flutter SDK releases | Flutter](https://docs.flutter.dev/development/tools/sdk/releases?tab=windows)

3. **配置环境变量**：

> 用户变量path

```shell
# flutter的安装目录
D:\flutter\bin
```

4. **检测依赖**：

```shell
flutter doctor
```

5. **Android Studio 配置**

   * 配置Dart SDK Path

   *   安装Flutter插件
   
   
      *   安装Dart插件
   



### 2.2 创建项目

使用Android Studio自己创建flutter项目 。

下载官方demo: `gallery`。

```shell
git clone git@github.com:flutter/gallery.git
```

### 2.3 编译环境

#### windows项目

如果需要运行windows客户都，需要下载 Visual Studio，社区版本即可。

[免费的开发人员软件和服务 - Visual Studio (microsoft.com)](https://visualstudio.microsoft.com/zh-hans/free-developer-offers/)

![image-20230506103443944](./Flutter%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0.assets/image-20230506103443944.png)

### 2.4 问题记录


*   **IOS设备运行时提示`无法打开idevicesyslog....`**

    打开设置-> 安全与隐私 -> 通用， 发现有一个请求，允许即可。

    ![image-20220526215955317](Flutter学习笔记.assets/image-20220526215955317.png)

*   **IOS免费开发证书**

    1.  根据Console中的提示,点击`ios/Runner.xcworkspace`。

    2.  打开`xcode -> preferences -> Account`。

    3.  添加一个账号，使用apple id 登录即可。

    4.  在`team`一览 双击team新增一个证书。

    5.  打开项目视图，选择`TARGETS ->Runner->Sign & Capabilities`,添加之前创建的`team`。

*   免费证书最多只能装2个应用

    ```txt
    The maximum number of apps for free development profiles has been reached
    ```

    1. `xcode -> window -> Devices and Simlators`选择设置里面删除应用

    

## 三、基础简介

### 3.1 Widget

> Flutter中的UI都是由一个个Widget嵌套组合构成的，Widget是对视图的一种结构化描述。内部存储的是视图渲染相关的配置信息（布局、渲染、响应事件等）。

* Widget不仅表示UI元素，同时也可以表示功能性组件（`GestureDetector`、`theme`等）。
* Widget是不可变的，配置有变化时Flutter会以重建Widget树的方式进行数据更新（数据驱动UI更新）。

| 属性            |                                                              |      |
| --------------- | ------------------------------------------------------------ | ---- |
| key             | 在`canUpdate()`方法中，会通过`key`和`runtimeType`来判断是否在下一次build时复用旧的widget。 |      |
| createElement() | 创建对应节点的Element对象。                                  |      |
|                 |                                                              |      |

#### Element

> Element 是 Widget 的一个实例化对象，它承载了视图构建的上下文数据（`BuildContext就是Element`），是连接结构化的配置信息到完成最终渲染的桥梁。

对于Element 的创建，Flutter 会在遍历 Widget 树时，调用 createElement 去同步 Widget 自身配置，从而生成对应节点的 Element 对象。

* Element同时持有Widget和RenderObject，相当于中间代理。
* Element将Widget树变化的部分做了抽象，只将真正需要修改的部分同步到RenderObject中，而不是整个渲染视图重建。

#### RenderObject

其中的布局和绘制由RenderObject完成。

#### StatelessWidget（无状态组件）

#### StatefulWidget（有状态的组件）

> 状态在widget生命周期是可以改变的。

```dart
/// 定义widget：
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
	
  // 构建State类
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// 定义State,对应的StatefulWidget需要维护的状态信息。
class _MyHomePageState extends State<MyHomePage> {
  /// 组件的状态：计数值
  int _counter = 0;

  ///  修改状态的函数
  ///  1. 计数自增
  ///  2. 调用setState()通知状态变更
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
}
```

#### RenderObjectWidget

StatelessWidget 和 StatefulWidget 只是用来组装控件的容器, 并不负责最后的布局和绘制。布局和绘制工作实际上是由 RenderObjectWidget 完成的。

[绘制流程](./Flutter核心原理.md)



### 3.2 使用RenderObject自定义Widget

```dart
class CustomWidget extends LeafRenderObjectWidget{
  @override
  RenderObject createRenderObject(BuildContext context) {
    // 创建 RenderObject
    return RenderCustomObject();
  }
  @override
  void updateRenderObject(BuildContext context, RenderCustomObject  renderObject) {
    // 更新 RenderObject
    super.updateRenderObject(context, renderObject);
  }
}

class RenderCustomObject extends RenderBox {

  @override
  void performLayout() {
    // 实现布局逻辑
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // 实现绘制
  }
}
```



### 3.3 生命周期

| 方法  | 类                  | 说明                                                 |
| ----- | ------------------- | ---------------------------------------------------- |
| mount | RenderObjectElement | 生命周期的第一步，负责初始化。将RenderObject插到树上 |
|       |                     |                                                      |
|       |                     |                                                      |



#### 3.3.1 State生命周期

![](https://guphit.github.io/assets/img/2-5.a59bef97.jpg)

| State生命周期         | 描述                                          | 调用时机                                                     |
| --------------------- | --------------------------------------------- | ------------------------------------------------------------ |
| 构造函数              | 负责创建State，接收StatefulWidge的配置数据。  | 在Widget的createState()中被调用                              |
| initState             | State初始化。常用于变量的初始化、设置监听等。 | State被插入视图树时调用                                      |
| didChangeDependencies | 处理State对象的依赖关系发生变化。             | `initState`时会调用；State依赖关系发生变化时调用。主题、语言等发生变化时调用（InheritedWidget）。 |
| build                 | 构建需要的视图, 返回Widget。                  | State准备好数据需要渲染时调用                                |
| reassemble            | 开发阶段时使用。                              | 热重载时                                                     |
| didUpdateWidget       | 组件重新构建。                                | 父Widget setState触发子Widget重建时调用;热重载时;            |
| deactivate            | 组件被移除时调用。                            | 组建不可见时                                                 |
| dispose               | 销毁组建，释放资源。                          | 组件被永久移除                                               |

#### 3.3.2 App生命周期

> 利用WidgetsBindingObserver监听App生命周期。

帧绘制回调：

* 单次回调

  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_){
    print("单次Frame绘制回调");//只回调一次
  });
  ```

* 实时绘制回调

  ```dart
  WidgetsBinding.instance.addPersistentFrameCallback((_) {
    printD("_ReadViewState", "实时Frame绘制回调"); //每帧都回调
  });
  ```



## 四、路由跳转

> 页面跳转相关的配置管理。

### 4.1 普通的路由跳转

#### 4.1.1 路由跳转

```dart
TextButton(
  onPressed: () async {
    // push 执行跳转
    var result = await Navigator.push(
      context,
      // 跳转到 MaterialPageRoute
      MaterialPageRoute(
        builder: (context) {
          return const SecondPage();
        },
        maintainState: true,
        fullscreenDialog: false));
    print("路由返回值: $result");
  },
  child: const Text("Route second page")),
```

#### 4.1.2 路由返回

```dart
class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Second Page"),
      ),
      body: Center(
          child: Column(children: [
        const Text("This is second page"),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, "我回来了"),
          child: const Text("返回"),
        ),
      ])),
    );
  }
}
```

### 4.2 命名路由跳转

#### 4.2.1 注册路由表

在`MaterialApp`的`routes`属性中注册路由表。

`initialRoute`配置初始页路由。

```dart
MaterialApp(
  title: 'Flutter Demo',
  initialRoute: "/",
  theme: ThemeData(
    primarySwatch: Colors.blue,
  ),
  routes: {
    "/": (context) => const MyHomePage(title: 'Flutter Demo Home Page'),
    "second_page": (context) => const SecondPage(),
  });
}
```

#### 4.2.2 通过路由名跳转

```dart
Navigator.pushNamed(context, "second_page");
// 传递参数
// Navigator.pushNamed(context, "second_page");
```

#### 4.2.3 获取参数

```dart
class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取路由参数
    var args = ModalRoute.of(context)?.settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Second Page"),
      ),
      body: Center(
          child: Column(children: [
        Text("This is second page, $args"),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, "I'm back"),
          child: const Text("返回"),
        ),
      ])),
    );
  }
}
```

### 4.3 路由勾子

> 只有当路由表中未注册的路由，才会调用`onGenerateRoute`。
>
> 所以不再使用自带的路由表，改为自定义一个路由表

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});
	
  // 自定义路由表
  static Map<String, WidgetBuilder> routes = {
    "/": (context) => const MyHomePage(title: 'Flutter Demo Home Page'),
    "second_page": (context) => const SecondPage(),
  };

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: "/",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) {
            String? routeName = settings.name;
            // 统一判断一些前置条件再跳转，例如 登录状态等。
            var builder = routes[routeName];
            if (builder == null) {
              return const SecondPage();
            } else {
              return builder(context);
            }
          },
        );
      },
    );
  }
}
```

## 五. Flutter的布局模型

| 组件                            | 类型      | 描述                     |
| ----------------------------- | ------- | ---------------------- |
| LeafRenderObjectWidget        | 非容器组件基类 | 用于没有子节点的widget。如Image  |
| SingleChildRenderObjectWidget | 单子组件基类  | 包含一个子widget。child参数    |
| MultiChildRenderObjectWidget  | 多子组件基类  | 包含多个子Widget。children参数 |

### 5.1 布局模型

#### RenderBox盒型布局。

*   组件对应的渲染对象继承自RenderBox类

*   父组件通过BoxConstraints来描述子组件的约束信息。

> 任何时候子组件都必须遵守其父组件的约束。

```dart
import 'package:flutter/material.dart';

class BoxTest extends StatelessWidget {
  const BoxTest({super.key});

  @override
  Widget build(BuildContext context) {
    Widget childBox = const DecoratedBox(
      decoration: BoxDecoration(color: Colors.red),
    );
    return Column(
      children: [
        // minHeight, minWidth 有父子节点中的最大值决定
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 50, minHeight: 50),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 100, minHeight: 100),
            child: childBox,
          ),
        ),
        // maxHeight, maxWidth 有父子节点中的最小值决定
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 50,
            maxWidth: 50,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 100,
              maxWidth: 100,
            ),
            child: SizedBox(
              height: 100,
              width: 100,
              child: childBox,
            ),
          ),
        ),
        // 实际看到的效果为 100x50。其实此处父组件的约束其实依然是生效的，并未去除。父约束的高度会体现在留白部分。
        ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 50.0, minHeight: 100.0),
            child: UnconstrainedBox(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(minWidth: 100.0, minHeight: 50.0),
                child: childBox,
              ),
            ))
      ],
    );
  }
}

```

![image-20220530223842268](Flutter学习笔记.assets/image-20220530223842268.png)

#### Sliver(RenderSliver)

> 只有当Sliver出现在视图窗口中时才会构建，是一种按需加载的模型。

*   Scrollable：处理滑动手势，确定滑动偏移时构建Viewport。

*   Viewport：显示视窗，将SliverConstraints传给Sliver。

*   Sliver：按需构建和布局。

`CustomScrollView`:自定义滑动组件， 仅接收Sliver。

`SliverToBoxAdapter`:将RenderBox转换为Sliver。

> `SliverConstraints`：存储约束条件。

| 字段                  | 说明                                                         |
| ------------------- | ---------------------------------------------------------- |
| overlap             | 当前sliver被上一个sliver重叠覆盖的部分的偏移量。即未显示->显示的大小。与scrollOffset相对应 |
| scrollOffset        | 显示部分的偏移量。显示->未显示的大小。                                       |
| userScrollDirection | 用户滑动方向。松手时回弹期间返回的依然是用户之前的操作方向，和实际列表滑动方向相反。                 |
|                     |                                                            |

> `SliverGeometry`

| 字段           | 说明                           |
| ------------ | ---------------------------- |
| scrollExtent | 滚动范围。                        |
| layoutExtent | 布局范围。垂直方向：\[0, layoutExtent] |
| paintOrigin  | 绘制的坐标原点，相对于布局位置。             |
| paintExtent  | 绘制范围大小。                      |

> Sliver布局协议

1.  Viewport 将当前布局和配置信息通过SliverConstraints传递给Sliver。

2.  Sliver确定自身的位置、绘制等信息，保存在SliverGeometry实例中。

3.  Viewport读取geometry中信息对Sliver进行布局和绘制。

### 5.2 布局流程

1.  上层组件向下层组件传递约束（constraints）条件。

2.  下层组件确定自己的大小，然后告诉上层组件。注意下层组件的大小必须符合父组件的约束。

3.  上层组件确定下层组件相对于自身的偏移和确定自身的大小（大多数情况下会根据子组件的大小来确定自身的大小）。

### 5.3 线性布局

> 布局沿水平方向（Row）：
>
> *   主轴：水平方向
>
> *   纵轴：垂直方向
>
> 布局沿垂直方向（Column）：
>
> *   主轴：垂直方向
>
> *   纵轴：水平方向

#### 主轴（MainAxisAlignment）

| 属性           | 说明                                |
| ------------ | --------------------------------- |
| start        | 将子控件放在主轴的起点（例如：垂直->上；水平(LTR)->左）。 |
| end          | 将子控件放在主轴的终点。                      |
| center       | 将子控件放在主轴中心。                       |
| spaceBetween | 将空闲空间均匀的放在子控件之间。                  |
| spaceAround  | 将空闲空间均匀的放在每个子控件的周围（例如：上下、左右）。     |
| spaceEvenly  | 将空闲空间均匀分布在整个布局间。                  |

#### 纵轴（CrossAxisAlignment）

### 5.4 弹性布局

`Flex`组件指定采用弹性布局,`Expanded`可以按权重占用空间。

*   Flex

### 5.5 流式布局

> 超出屏幕部分会自动折叠，不会出现布局的溢出报错。

*   Wrap

*   Flow

### 5.6 层叠布局 Stack

> 相当于Android的FrameLayout

结合 Positioned 使用。

```dart
 Widget buildLeft(BuildContext context, Size parentSize) {
    return Stack(
      children: [
        Positioned(
          left: 50, // 左偏移 50
          width: 100, // 指定布局的宽度。不指定时为子部分大小
          height: 100, // 指定布局的高度。不指定时为子部分大小
          top: 50, // 顶部偏移 50
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: kBackgroundGrey),
            child: Text("123123123"),
          ),
        )
      ],
    );
 }
```



### 5.7 布局对齐

*   Align

    ```dart
    Container(
      height: 200,
      width: 200,
      child: const Align(
        // 以矩形的中心点为原点, 向左偏移 100 * 0.5
        alignment: Alignment(-0.5, 0),
        child: FlutterLogo(
          size: 100,
        ),
      ),
    )
    ```

*   FractionalOffset

    ```dart
    Container(
      height: 200,
      width: 200,
      child: const Align(
        // 以父组件的左上角为原点， 向右偏移 100 * 0.1, 向下偏移 100 * 0.1
        alignment: FractionalOffset(0.1, 0.1),
        widthFactor: 2, // 宽度是childWidget的 2倍
        heightFactor: 2, // 高度是childWidget的 2倍
        child: FlutterLogo(
          size: 100,
        ),
      ),
    )
    ```



## 6. 动画

### Animation

`Animation<T>` 可以通过继承它来实现不同的动画。它用于保存动画的插值和状态，我们可以添加不同的监听器来监听动画。

* addListener()：帧监听器。每一帧都会回调。
* addStatusListener()：状态监听器。状态发生变化时回调。例如 开始、结束等。



### CurvedAnimation

曲线动画，继承自 Animation，包括线性和非线性两种。

```dart
CurvedAnimation curve = CurvedAnimation(parent: controller, curve: Curves.linear);
```

| Curves曲线 | 动画过程                     |
| ---------- | ---------------------------- |
| linear     | 匀速的                       |
| decelerate | 匀减速                       |
| ease       | 开始加速，后面减速           |
| easeIn     | 开始慢，后面快               |
| easeOut    | 开始快，后面慢               |
| easeInOut  | 开始慢，然后加速，最后再减速 |

### AnimationController

和ScrollerController等控制类相同，它用来控制动画。

* Tween：指定动画执行期间，数值的变化范围。

  ```dart
  // 对于缩放 scale，表示从0 缩放到1.
  Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: controller,
          curve: Interval(0, 0.3, curve: Curves.fastOutSlowIn),
      ))
  ```

  

## 8. 事件交互

- 原始的指针事件（Pointer Event），对应原生开发的Down、Up等事件。
- 手势识别（Gesture Detector）。

> 事件处理流程

1.  Hit Test：手指按下时，发送`PointDownEvent`，深度优先遍历当前的`Render Object树`，对每一个渲染树做命中测试。若命中则添加到`HitTestResult`中。

2.  事件分发：遍历`HitTestResult`，调用每个渲染对象的`handleEvent`处理Down事件。若手指移动则分发`PointMoveEvent`事件。

3.  事件清理：当触发`PointerUpEvent`或`PointCancelEvent`时，会先将事件进行分发，然后清空`HitTestResult`。

> Hit Test仅在`PointDownEvent`事件触发时进行。
>
> 子组件比父组件先响应事件。

### 8.1 指针事件

使用`IgnorePointer`和`AbsorbPointer`忽略阻止子树接收`PointerEvent`。

> 使用Listener Widget监听子Widget的指针事件。
>
> 指针事件不会发生冲突。每一个节点都能收到。

### 8.2 手势识别

`GestureDetector` Widget手势监听:

> 内部使用多个GestureRecognizer来处理手势。
>
> 手势冲突：发生嵌套时子视图优先响应。

| 函数        |          |
| ----------- | -------- |
| onTab       | 点击回调 |
| onDoubleTab | 双击回调 |
| onLongPress | 长按回调 |
| onPanUpdate | 拖动回调 |

### 8.3 手势冲突处理

> 利用Linstener处理。



> 自定义GestureRecognizer

确定了手势竞争胜出者时， 会调用胜出者的`acceptGesture()`方法，然后调用其他手势识别等`rejectGesture`。

利用这一点。我们可以通过自定手势识别`GestureRecognizer`，




### 8.3 ScrollController

> 滑动监听

声明：

```dart
  final ScrollController _controller = ScrollController();
```

设置监听：

```dart
_controller.addListener(() {
  MyLog.d("_ReadViewState", "offset: ${_controller.offset}");
});
```

执行滑动：

```dart
_controller.animateTo(0, duration: Duration(milliseconds: 200), curve: Curves.ease);
```

## 9. 组件间数据传递

### 属性传值

构建组建时直接传递参数即可， 层级比较深时，会很繁琐。

### InhertedWidget

>  适用于Widget树中共享数据。
>
> 数据流向：父 > 子

```dart
// _BookContainer 当作正常的 widget使用即可，
// 它的数据发生变化时，会使 建立绑定的子widget 发生更新。
class _BookContainer extends InheritedWidget {
  _BookContainer(
      {
      required this.book,
      required super.child});
  Book book;

  // 其他Widget 这里的数据时通过这个 of() 函数来获取数据。
  static _BookContainer? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BookContainer>(); // 建立了绑定关系，发生变化时会调用子Widget的didChangeDependencies()

  // 仅获取，不建立绑定关系
  // static _BookContainer? of(BuildContext context) =>
  //     context.getElementForInheritedWidgetOfExactType<_BookContainer>()?.widget as _BookContainer;
  
  @override
  bool updateShouldNotify(covariant _BookContainer oldWidget) {
    return book != oldWidget.book;
  }
}

```



### Notificaiton

> 适用于子Widget状态变更，向上通知的场景。
>
> 数据流向：子 > 父



### EventBus

> 事件总线: 发布/订阅模式共享数据。和其他平台的事件总线类似。
>
> 适用于跨组件、跨页面甚至非组件。

添加依赖：

```bash
flutter pub add event_bus
```

定义事件

```dart
class StringEvent {
  StringEvent(this.text);

  String text;
}
```

订阅/取消订阅

```dart
EventBus bus = EventBus();
class TestEventWidgetState extends State<TestEventWidget> {
  StreamSubscription? subscription;
  String? text;

  @override
  Widget build(BuildContext context) {
    return Text("show: $text");
  }

  @override
  void dispose() {
    // 取消订阅
    subscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    // 订阅
    subscription = bus.on<StringEvent>().listen((event) {
      // 执行更新操作等
      setState(() {
        text = event.text;
      });
    });
    super.initState();
  }
}
```

发送事件

```dart
bus.fire(Event.next);
```



### Provider

> 基于 InhertedWidget实现的跨组件状态共享方案。所有只需要作为父Widget即可共享。
>
> `Provider`帮我们将Model和InheritedWidget直接建立订阅关系，并在生命周期中自动绑定和解绑。

添加依赖：

```bash
flutter pub add provider 
```

定义一个Model，共享数据和操作：

```dart
// 继承 ChangeNotifier，以便调用 notifyListeners 通知变更
class ReadCache with ChangeNotifier, DiagnosticableTreeMixin {
  Future<PageState?>? pageFuture;
  bool menuVisible = false;

  void prevPage() {
    MyLog.d("ReadCache", "prevPage");
    pageFuture = bookController.getPrevPage();
    // 通知变更
    notifyListeners();
  }

  void nextPage() {
    MyLog.d("ReadCache", "nextPage");
    pageFuture = bookController.getNextPage();
    notifyListeners();
  }

  void showMenu() {
    MyLog.d("ReadCache", "showMenu");
    menuVisible = true;
    notifyListeners();
  }
}
```

构建一个Provider：

```dart
// Provider的使用方式和 普通的Widget相同
ChangeNotifierProvider(
    create: (_) => ReadCache(),  // 创建共享的数据
    child: const BookReaderPage(), // 创建子组件
),
```

```dart
// 多个Provider组合注入
MultiProvider(
  providers: [
    // ChangeNotifierProvider提供读写， 仅需读取可以只使用Provider即可
    ChangeNotifierProvider(create: (_) => ReadCache()),
  ],
  child: const BookReaderPage(),
)
```

获取共享数据：

> Provider扩展了BuildContext,新增 `watch`和`read`两个api来获取共享数据。

- **watch**：同`dependOnInheritedWidgetOfExactType`将建立绑定关系。变化时会重新build。

  ```dart
  context.watch<ReadCache>().pageFuture
  ```
  
- **read**：同`getElementForInheritedWidgetOfExactType`仅获取数据。

  ```dart
  context.read<ReadCache>().pageFuture
  ```
  
- **Consumer**：获取数据并会在数据变化时触发重组，可以控制UI刷新粒度

  ```dart
  Consumer<_BookSearchMode>(
    builder: (c, mode, _) {
      print("mode : ${mode.books}");
      return BookListPage(
        mode.books,
        simple: false,
        onTap: (book) {
          AppRoutes.startBookDetailPage(context, book);
        },
      );
    },
  )
  ```
  
  

Provider内部原理梳理：

> Provider在内部构建了`_InheritedProviderScope`，它继承自InheritedWidget，持有我们的共享数据, 再通过它构建了我们的widget，所以我们可以使用InheritedWidget的特性。

```dart
class InheritedProvider<T> extends SingleChildStatelessWidget {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return _InheritedProviderScope<T?>(
      owner: this,
      // ignore: no_runtimetype_tostring
      debugType: kDebugMode ? '$runtimeType' : '',
      child: builder != null
          ? Builder(
              builder: (context) => builder!(context, child),
            )
          : child!,
    );
  }
}
```

使用Flutter自带的`ChangeNotifier`来做数据变化的通知, 以及自动实现了订阅和取消订阅。

```dart
class ListenableProvider<T extends Listenable?> extends InheritedProvider<T> {
	/// 设置监听
  static VoidCallback _startListening(
    InheritedContext e,
    Listenable? value,
  ) {
    // value 就是我们的Model
    // e.markNeedsNotifyDependents 内部调用了 markNeedsBuild()执行重新构建。
    value?.addListener(e.markNeedsNotifyDependents);
    return () => value?.removeListener(e.markNeedsNotifyDependents);
  }
}
```

```dart
class ChangeNotifierProvider<T extends ChangeNotifier?>
    extends ListenableProvider<T> {
	/// 取消监听
  static void _dispose(BuildContext context, ChangeNotifier? notifier) {
    notifier?.dispose();
  }
}
```



## 10. 状态栏和导航栏

### 全局状态栏透明

```dart
void main() {
  DebugConfiguration.debug();
  runApp(const MyApp());
  // 设置全局状态栏透明
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
}
```

### 全局沉浸式
```dart
void main() {
  runApp(const MyApp());
  // SystemUiMode 还有很多其他样式
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}
```

### 隐藏AppBar仅显示状态栏
```dart
return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // 也可以通过这个中方式设置单个页面的沉浸式
        foregroundColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: ...,
    );
```

### 修改状态栏文字颜色

```dart
appBar: AppBar(
        // SystemUiOverlayStyle.dark: 黑色
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: 0,
      ),
```



## 混合开发

### Android和Flutter之间的页面跳转

[将 Flutter 集成到现有应用 - Flutter 中文文档 - Flutter 中文开发者网站 - Flutter](https://flutter.cn/docs/development/add-to-app)

Android 跳转到 Flutter 实际就是跳转到一个包含了 FlutterView的Activity。官方提供了多种嵌入FlutterView的方式：

* 使用FlutterActivity。
* 使用FlutterFragment。
* 使用FlutterEngine 嵌入 FlutterView

#### 使用FlutterActivity 跳转

```kotlin
class FlutterViewActivity : AppCompatActivity() {
	myButton.setOnClickListener {
      startActivity(
        FlutterActivity
          .withNewEngine()
          // 改为对应的路由即可
          .initialRoute("/my_route")
          .build(this)
      )
    }
}
```

#### Activity嵌入FlutterView

```kotlin
class FlutterViewActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 
        val flutterView = Flutter.createView(this, lifecycle, "flutter_view" )
        val flutterLayoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT
        )
        addContentView(flutterView, flutterLayoutParams)
    }
}
```

#### 使用FlutterEngine 

```kotlin
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var flutterViewEngine: FlutterViewEngine
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // 创建 FlutterEngine
        val engine = FlutterEngine(applicationContext)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(),
            "showCell"))
		// 创建 FlutterViewEngine
        flutterViewEngine = FlutterViewEngine(engine)
		// 关联到当前 Activity
        flutterViewEngine.attachToActivity(this)
		//
        val flutterView = FlutterView(context)	
        //
        binding.root.addView(flutterView);
        //
		flutterViewEngine.attachFlutterView(flutterView);
    }

    override fun onDestroy() {
        super.onDestroy()
        flutterViewEngine.detachActivity()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        flutterViewEngine.onRequestPermissionsResult(requestCode, permissions, grantResults)
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        flutterViewEngine.onActivityResult(requestCode, resultCode, data)
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onUserLeaveHint() {
        flutterViewEngine.onUserLeaveHint()
        super.onUserLeaveHint()
    }
}
```



#### Activity嵌入FlutterFragment

和正常使用 Fragment的方式是一样，需要注意的是 需要将生命周期变化传递给 FlutterFragment。

*  `/` 为初始路由。

```kotlin
class MyActivity : FragmentActivity() {
  companion object {
	// 随便取个名字
    private const val TAG_FLUTTER_FRAGMENT = "flutter_fragment"
  }

  private var flutterFragment: FlutterFragment? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // 布局文件，包含ID R.id.fragment_container.
    setContentView(R.layout.my_activity_layout)

    val fragmentManager: FragmentManager = supportFragmentManager

    flutterFragment = fragmentManager
      .findFragmentByTag(TAG_FLUTTER_FRAGMENT) as FlutterFragment?

    // 创建并添加 FlutterFragment。和正常使用Fragment一样。
    if (flutterFragment == null) {
      var newFlutterFragment = FlutterFragment.createDefault()
      flutterFragment = newFlutterFragment
      fragmentManager
        .beginTransaction()
        .add(
          R.id.fragment_container,
          newFlutterFragment,
          TAG_FLUTTER_FRAGMENT
        )
        .commit()
    }
  }
    
    @Override
    public void onPostResume() {
        super.onPostResume();
        flutterFragment.onPostResume();
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        flutterFragment.onNewIntent(intent);
    }

    @Override
    public void onBackPressed() {
        flutterFragment.onBackPressed();
    }

    @Override
    public void onRequestPermissionsResult(
        int requestCode,
        @NonNull String[] permissions,
        @NonNull int[] grantResults
    ) {
        flutterFragment.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        );
    }

    @Override
    public void onUserLeaveHint() {
        flutterFragment.onUserLeaveHint();
    }

    @Override
    public void onTrimMemory(int level) {
        super.onTrimMemory(level);
        flutterFragment.onTrimMemory(level);
    }
}

```



#### Flutter ->Android



## 参考资料

> 部分内容摘自以下资料

[Flutter - Build apps for any screen](https://flutter.dev/)

[Flutter 中文开发者网站 | Flutter —— 为所有屏幕构建精美应用](https://flutter.cn/)

[Flutter中文网 (flutterchina.club)](https://flutterchina.club/)

[第二版序 | 《Flutter实战·第二版》 (flutterchina.club)](https://book.flutterchina.club/)
