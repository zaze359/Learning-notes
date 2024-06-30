# Flutter功能列表

[第二版序 | 《Flutter实战·第二版》 (flutterchina.club)](https://book.flutterchina.club/)

[Widgets 介绍 | Flutter 中文文档 | Flutter 中文开发者网站](https://flutter.cn/docs/development/ui/widgets-intro)

[Flutter组件实现案例集合](https://github.com/nisrulz/flutter-examples)



​	

## 一、Flutter组件

```dart
import 'package:flutter/widgets.dart';
```

### 1.1 布局类组件(layout widget)

#### Center

> 1.  只有一个子组件
>
> 2.  将其子组件树对齐到父布局中心。

| 属性    | 类型      | 描述  |
| ----- | ------- | --- |
| child | Widget? | 子组件 |

```dart
Center(
  // Center is a layout widget. It takes a single child and positions it
  // in the middle of the parent.
  child: Column(
	// ...
  ),
)
```

#### Flex

> 弹性布局

内部可以使用`Expanded`组建指定权重来布局。

#### Row

> 线性布局, 继承自Flex
>
> 1.  可以包含多个子组件。
>
> 2.  水平布局

#### Column

> 线性布局, 继承自Flex
>
> 1.  可以包含多个子组件。
>
> 2.  垂直分布。

| 属性                 | 类型                 | 描述                                             |
| ------------------ | ------------------ | ---------------------------------------------- |
| mainAxisSize       | MainAxisSize       | 默认`MainAxisSize.max`，尽可能多的占用空间。类似match\_parent |
| mainAxisAlignment  | MainAxisAlignment  | 如何沿主轴放置子组件，默认start。`MainAxisSize.min`时此属性无效。   |
| crossAxisAlignment | CrossAxisAlignment | 子组件在纵轴的对齐方式。受`verticalDirection`影响。            |
| children           | List\<Widget>      | 子组件列表                                          |
| verticalDirection  | VerticalDirection  | 子组件垂直方向的布局方式，默认`VerticalDirection.down`，从上到下布局 |

```dart
Column(
  // Column is also a layout widget. It takes a list of children and
  // arranges them vertically. By default, it sizes itself to fit its
  // children horizontally, and tries to be as tall as its parent.
  mainAxisAlignment: MainAxisAlignment.center,
  children: <Widget>[
    const Text(
      'You have pushed the button this many times121212:',
    ),
    Text(
      '$_counter',
      style: Theme.of(context).textTheme.headline4,
    ),
  ],
)
```

#### Wrap

>  流式布局

| 属性           | 类型            | 描述            |
| ------------ | ------------- | ------------- |
| spacing      | double        | 主轴方向的间距。      |
| runSpacing   | double        | 纵轴方向的间距。      |
| alignment    | WrapAlignment | 主轴方向 组件的对齐方式。 |
| runAlignment | WrapAlignment | 纵轴方向 组件的对齐方式。 |
|              |               |               |

#### Stack

> 和Android的FrameLayout相似。层叠布局 

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



#### Container

> 矩形视觉元素。

#### Padding

> 设置边距

| 属性      | 类型                 | 描述  |
| ------- | ------------------ | --- |
| padding | EdgeInsetsGeometry | 边距  |
| child   | Widget?            | 子组件 |

### 1.2 容器类组件

#### SizedBox

### 1.3 功能组件

#### Text：文本

```dart
const Text(
  "123456",
  textAlign: TextAlign.center, // 文本内容居中
  style: TextStyle(),
  strutStyle: StrutStyle(
    forceStrutHeight: true, // 去除了文字的内边距，同android的 includeFontPadding = false
  ),
)
```

#### SingleChildScrollView

类似Android的 ScrollView ，只有一个子组件。

* 不支持基于Sliver的延迟加载模型，性能差。适用于数量较少时使用。

#### CustomScrollView



#### ListView

#### GridView

#### ExpansionPanelList（可展开的面板列表）

#### PageView

> AutomaticKeepAlive 添加组建子项缓存。

#### TabBarView

> DefaultTabController





#### Image：图片

**Image**

|                 |                  |
| --------------- | ---------------- |
| Image.asset()   | 加载本地资源图片 |
| Image.file()    | 加载本地图片文件 |
| Image.network() | 加载网络图片     |

**FadeInImage**

> 支持占位图、加载动画等高级功能

```dart
FadeInImage.assetNetwork(
  placeholder: 'assets/a.jpg',
  image: 'https://xxx/xxx/xxx.jpg',
  fit: BoxFit.none,
  width: 300,
  height: 300,
)
```

**CachedNetworkImage(三方)**

```dart
 CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error));
  }
```







#### Widget的显示和隐藏

**Offstage**

> 隐藏后不占位置
>
> `offstage=true 表示在下层，即不需要显示，也不占位`，false时显示在最上方

```dart
Offstage(
  offstage: !visible,
  child: Container(
    constraints: BoxConstraints.tight(Size(200.0, 100.0)),
    color: Colors.blue,
  ),
);
```

**Visibility**

> 可控制是否占位，是否响应事件
>
> `maintainInteractivity`为true响应事件时，maintainSize、maintainState、maintainAnimation都需要为true

```dart
Visibility(
  visible: false, // 是否显示
  maintainSize: true, // 是否保持大小
  maintainState: true,
  maintainAnimation: true,
  maintainInteractivity: true, // 是否响应事件
  child: GestureDetector(
    child: Container(
      constraints: BoxConstraints.tight(Size(200.0, 100.0)),
      color: Colors.blue,
    ),
    onTap: () {
      print('onTap');
    },
  ),
)
```

#### Divider：分割线

- Divider：水平分割线
- VerticalDivider：垂直分割线

| 属性         |                                           |                         |
| ------------ | ----------------------------------------- | ----------------------- |
| indent       | 起点缩进距离                              |                         |
| endIndent    | 终点缩进距离                              |                         |
| color        | 分割线颜色                                |                         |
| height/width | 分割线区域的高度/宽度, 并不是分割线的高度 | VerticalDivider时为宽度 |
| thickness    | 分割线的高度                              |                         |

#### IntrinsicHeight/IntrinsicWidth

它们的作用是将子widget的高度/宽度调整为其本身实际高度/宽度

当Row无固定高度，子组件将不会自动占满，Column同理。

此时可以使用IntrinsicHeight 组件包裹，使得子组件占满。

```dart
IntrinsicHeight(
    child: Row(
        children: [],
    ),
),
```

#### AppBar

|                           |                  |                                        |
| ------------------------- | ---------------- | -------------------------------------- |
| automaticallyImplyLeading | 是否自动提示导航 | 默认true, 设为false可去除默认的leading |
| toolbarHeight             | 设置 toolbar高度 |                                        |

#### SliverAppBar

用于 Sliver中

|                 |                                                              |                                        |
| --------------- | ------------------------------------------------------------ | -------------------------------------- |
| expandedHeight  | 展开时的高度                                                 |                                        |
| collapsedHeight | 收缩时的高度                                                 |                                        |
| floating        | 是否漂浮在上方                                               |                                        |
| snap            | true, 只要下滑就会展开显示，false只有滑倒边界时才会显示隐藏部分 | 和floating = true 时使用，不可单独使用 |
| pinned          | 是否固定在上方                                               | true 会将SliverAppBar固定在上方        |

#### FittedBox

| 属性 | 说明                               |
| ---- | ---------------------------------- |
| fit  | 指定适配方式。`BoxFit.contain`等。 |

#### NestedScrollView

> 处理滑动冲突：滑动冲突时默认子元素生效。



#### Transform

> `Transform`的变换是在绘制阶段，不是布局阶段， 所以子组件占用的空间大小和位置是固定不变的。

* 平移

  ```dart
  Transform.translate(...);
  ```

* 旋转

      Transform.rotate(...);

* 缩放

      Transform.scale(...);

#### RotatedBox

> `RotatedBox`的变换是在layout阶段, 会影响子组件的位置和大小。

#### Clip

| 组件      | 描述                     |
| --------- | ------------------------ |
| ClipOval  | 内切圆                   |
| ClipRRect | 圆角矩形                 |
| ClipRect  | 将组件布局之外的部分剪裁 |
| ClipPath  | 按照Path进行自定义剪裁   |

#### CustomClipper

> 自定义裁剪范围

```dart
class MyClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    // 裁剪左上角 1/4部分
    return Rect.fromLTWH(0, 0, size.width / 2, size.height / 2);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return true;
  }
}
```



## 二、Material组件

[Material Components widgets | Flutter 中文文档 | Flutter 中文开发者网站](https://flutter.cn/docs/development/ui/widgets/material)

> Android：Material Design风格

```dart
import 'package:flutter/material.dart';
```

### Scaffold

Material 库中提供的UI结构框架。

| 属性                   | 类型                   | 描述   |
| -------------------- | -------------------- | ---- |
| appBar               | PreferredSizeWidget? | 导航栏  |
| body                 | Widget?              | 主体内容 |
| floatingActionButton | Widget?              | 悬浮按钮 |

***

### Button：按钮

[Material Components widgets | Flutter 中文文档 | Flutter 中文开发者网站](https://flutter.cn/docs/development/ui/widgets/material#Buttons)

#### ElevatedButton

> 指定icon

```dart
// 直接创建
ElevatedButton(
  	onPressed: () => {},
    style: TextButton.styleFrom(
        minimumSize: const Size(80, 44),
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
        ),
    ),
    child: Text(text, style: const TextStyle(fontSize: 16)),
)

// 使用 factory
//  实际返回的是 _ElevatedButtonWithIcon
ElevatedButton.icon(
  icon: const Icon(Icons.backup),
  label: const Text("备份"),
  onPressed: () => {},
)
```

#### IconButton

> 图标按钮：默认透明背景，点击后出现背景，例如播放图标按钮

#### FloatingActionButton

> 浮动按钮

| 属性        | 类型            | 描述                 |
| --------- | ------------- | ------------------ |
| onPressed | VoidCallback? | 点击操作回调函数。          |
| tooltip   | String?       | 点击的提示描述，长按时显示。     |
| child     | Widget?       | 悬浮按钮内显示的内容，通常是个图标。 |

#### OutlinedButton

默认带边框，背景透明

> 指定icon

```dart
//  实际返回的是 _OutlinedButtonWithIcon
OutlinedButton.icon(
  icon: const Icon(Icons.backup),
  label: const Text("备份"),
  onPressed: () => {},
)
```

***

#### TextButton

默认背景透明

> 指定icon

```dart
//  实际返回的是 _TextButtonWithIcon
// 通过style清除默认padding
TextButton.icon(
    style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        // side: const BorderSide(
        //     color: Colors.grey, width: 0.5, style: BorderStyle.solid),
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(24.0),
        // ),
    ),
    icon: const Icon(Icons.backup),
    label: const Text("备份"),
    onPressed: () => {},
)
```

***

### TextFiled：输入框

| 属性                 | 类型                   | 描述                                                         |
| -------------------- | ---------------------- | ------------------------------------------------------------ |
| controller           | TextEditingController? | 控制器：可以监听文本变化、设置默认值、选择编辑内容等。       |
| focusNode            | FocusNode?             | 键盘的焦点。可以通过`FocusScope.of(context)`获取`FocusScopeNode`来控制焦点的变化。 |
| decoration           | InputDecoration?       | 外观装饰器：提示文本、背景颜色、边框等。                     |
| keyboardType         | TextInputType?         | 设置输入键盘类型：TextInputType.phone、TextInputType.multiline等。 |
| textInputAction      | TextInputAction?       | 键盘上回车键的图标。TextInputAction.search等。               |
| style                | TextStyle?             | 编辑文本的样式。                                             |
| textAlign            | TextAlign              | 文本对其方式                                                 |
| textDirection        | TextDirection?         | 文本的方向：rtl、ltr。                                       |
| toolbarOptions       | ToolbarOptions?        | 长按或鼠标点击显示的菜单。                                   |
| showCursor           | bool?                  | 控制是否显示光标。                                           |
| autofocus            | bool                   | 自动获取键盘的焦点。                                         |
| obscuringCharacter   | String                 | 指定obscureText = true时，显示的内容被替换为的字符；默认`•`。 |
| obscureText          | bool                   | 暗文显示内容。                                               |
| maxLines             | int?                   | 运行最多显示的行数。                                         |
| minLines             | int?                   | 最少显示的行数。                                             |
| maxLength            | int?                   | 最大输入长度。                                               |
| maxLengthEnforcement | MaxLengthEnforcement?  | 定义超出最大长度后如何处理。                                 |
| onChanged            | ValueChanged?          | 输入框内容改变时回调此函数。                                 |
| onEditingComplete    | VoidCallback?          | 输入完成时触发。                                             |
| onSubmitted          | ValueChanged?          | 输入完成时触发。                                             |
| inputFormatters      | List?                  | 指定输入格式，当用户输入时，将会根据此格式校验内容。         |
| cursorWidth          | double                 | 光标的宽度。                                                 |
| cursorHeight         | double?                | 光标的高度。                                                 |
| cursorRadius         | Radius?                | 光标的圆角设置。                                             |
| cursorColor          | Color?                 | 光标的颜色。                                                 |
|                      |                        |                                                              |

```dart
// 定义controller
var editController = TextEditingController();
// 设置监听
editController.addListener(() {
  print("editController: ${editController.text}");
});
// 设置默认值
editController.text = "111";
// .. 
var tf = TextField(
  // keyboardType: TextInputType.datetime,
  textInputAction: TextInputAction.search,
  decoration: InputDecoration(
    labelText: "账号", hintText: "请输入", prefixIcon: Icon(Icons.person)),
  autofocus: true,
  obscuringCharacter: '@',
    
  // maxLines > 0, 支持多行输入
  maxLines: 8,
  minLines: 1,
  maxLength: 10,
  showCursor: false,
  // textAlign: TextAlign.center,
  textDirection: TextDirection.rtl,
  textAlignVertical: TextAlignVertical(y: 1),
  // obscureText: true,
  cursorWidth: 4,
  cursorColor: Color.fromARGB(222, 214, 25, 25),
  cursorHeight: 30,
  cursorRadius: Radius.circular(2),
  controller: editController,
  onChanged: (value) {
    print("onChanged: $value");
  },
);
```

如何



### Form：表单

[构建一个有验证判断的表单 - Flutter 中文文档 - Flutter 中文开发者网站 - Flutter](https://flutter.cn/docs/cookbook/forms/validation)

> 创建表单时需要一个`GlobalKey`标识这个表单。
>
> `TextEditingController`或者`onChanged()`来监听文本变化。

```dart
class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

class MyCustomFormState extends State<MyCustomForm> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController _controller = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    // 创建Form表单
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _controller,
            validator: (value) {// 检验输入内容是否正确，null表示正确。
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
            // onChanged: ....
          ),
          ElevatedButton(
            onPressed: () {
              // 使用_formKye.currentState()访问FormState
              // 此处会遍历表单内所有的validate方法。
              // 当所有都通过验证时才会返回true。
              if (_formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Processing Data')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  
  @override
  void initState() {
    super.initState();
    // 使用addListener()注册监听
    _controller.addListener((){
      // 打印输入内容
      print('addListener: ${_controller.text}');
    });
  }
  
  @override
  void dispose() { // 解绑
    _controller.dispose();
    super.dispose();
  }
}
```





### SelectableText：文本选择控件

```dart
SelectableText.rich(
      TextSpan(
        children: widget._contentText.characters.map((element) {
          return TextSpan(
            text: element,
            style: TextStyle(color: Colors.red),
            onEnter: (event) {
              MyLog.d("_SinglePageViewState", "onEnter: $event");
            },
            onExit: (event) {
              MyLog.d("_SinglePageViewState", "onExit: $event");
            },
          );
        }).toList(),
      ),
      selectionControls: MaterialTextSelectionControls(),
      onTap: (){
        MyLog.d("_SinglePageViewState", "onTap");
      },
      // toolbarOptions: ,
    );
```



***

### RefreshIndicator：下拉刷新

```dart
Future<void> _refreshBookshelf() async {

}

RefreshIndicator(
  onRefresh: () {
    return _refreshBookshelf();
  },
  child: _grid(2, books),
);
```

### Progress：进度条

#### LinearProgressIndicator

> 线性进度条

#### CircularProgressIndicator

> 圆形进度条

| 属性              | 类型                  | 描述                                   |
| --------------- | ------------------- | ------------------------------------ |
| value           | double?             | 表示当前进度，范围：\[0, 1]。默认`null`会执行一个循环动画。 |
| backgroundColor | Color?              | 背景色                                  |
| valueColor      | Animation\<Color?>? | 进度条颜色；可以指定颜色变化的动画效果。                 |

### InkWell：水波纹效果



## 三、Cupertino组件

> IOS： Cupertino 风格

```dart
import 'package:flutter/cupertino.dart';
```



## 四、其他

### 剪贴板（Clipboard）

```dart
/// 复制到剪贴板
Clipboard.setData(ClipboardData(text: "123123123"));

/// 获取剪贴版内容
Clipboard.getData(Clipboard.kTextPlain).then((value) => {
    print("value: ${value?.text}")
});
```

### 提示（Snackbars）

```dart
ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('复制成功')),
);
```

