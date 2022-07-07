# 1Flutter常用组件

[第二版序 | 《Flutter实战·第二版》 (flutterchina.club)](https://book.flutterchina.club/)

[Widgets 介绍 | Flutter 中文文档 | Flutter 中文开发者网站](https://flutter.cn/docs/development/ui/widgets-intro)

| 属性 | 类型 | 描述 |
| -- | -- | -- |
|    |    |    |

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

> 和Android的FrameLayout相似。

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

#### 文本(Text)

```dart
const Text(
  "123456",
  textAlign: TextAlign.center,
  style: TextStyle(),
  strutStyle: StrutStyle(
    forceStrutHeight: true, // 去除了文字的内边距，同android的 includeFontPadding = false
  ),
)
```

#### SingleChildScrollView

> 类似Android的`ScrollView`，只有一个子组件。
>
> 不支持基于Sliver的延迟加载模型，性能差。

#### ListView

#### GridView

#### ExpansionPanelList（可展开的面板列表）

#### PageView

> AutomaticKeepAlive 添加组建子项缓存。

#### TabBarView

> DefaultTabController





#### Image（图片）

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

### 按钮

[Material Components widgets | Flutter 中文文档 | Flutter 中文开发者网站](https://flutter.cn/docs/development/ui/widgets/material#Buttons)

#### ElevatedButton

> 指定icon

```dart
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
TextButton.icon(
  icon: const Icon(Icons.backup),
  label: const Text("备份"),
  onPressed: () => {},
)
```

***

### 输入框

#### TextFiled

| 属性                   | 类型                     | 描述                                                            |
| -------------------- | ---------------------- | ------------------------------------------------------------- |
| controller           | TextEditingController? | 控制器：可以监听文本变化、设置默认值、选择编辑内容等。                                   |
| focusNode            | FocusNode?             | 键盘的焦点。可以通过`FocusScope.of(context)`获取`FocusScopeNode`来控制焦点的变化。 |
| decoration           | InputDecoration?       | 外观装饰器：提示文本、背景颜色、边框等。                                          |
| keyboardType         | TextInputType?         | 设置输入键盘类型：TextInputType.phone等。                                |
| textInputAction      | TextInputAction?       | 键盘上回车键的图标。TextInputAction.search等。                            |
| style                | TextStyle?             | 编辑文本的样式。                                                      |
| textAlign            | TextAlign              | 文本对其方式                                                        |
| textDirection        | TextDirection?         | 文本的方向：rtl、ltr。                                                |
| toolbarOptions       | ToolbarOptions?        | 长按或鼠标点击显示的菜单。                                                 |
| showCursor           | bool?                  | 控制是否显示光标。                                                     |
| autofocus            | bool                   | 自动获取键盘的焦点。                                                    |
| obscuringCharacter   | String                 | 指定obscureText = true时，显示的内容被替换为的字符；默认`•`。                     |
| obscureText          | bool                   | 暗文显示内容。                                                       |
| maxLines             | int?                   | 运行最多显示的行数。                                                    |
| minLines             | int?                   | 最少显示的行数。                                                      |
| maxLength            | int?                   | 最大输入长度。                                                       |
| maxLengthEnforcement | MaxLengthEnforcement?  | 定义超出最大长度后如何处理。                                                |
| onChanged            | ValueChanged?          | 输入框内容改变时回调此函数。                                                |
| onEditingComplete    | VoidCallback?          | 输入完成时触发。                                                      |
| onSubmitted          | ValueChanged?          | 输入完成时触发。                                                      |
| inputFormatters      | List?                  | 指定输入格式，当用户输入时，将会根据此格式校验内容。                                    |
| cursorWidth          | double                 | 光标的宽度。                                                        |
| cursorHeight         | double?                | 光标的高度。                                                        |
| cursorRadius         | Radius?                | 光标的圆角设置。                                                      |
| cursorColor          | Color?                 | 光标的颜色。                                                        |
|                      |                        |                                                               |

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
  maxLines: 1,
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

### 表单(Form)

[构建一个有验证判断的表单 - Flutter 中文文档 - Flutter 中文开发者网站 - Flutter](https://flutter.cn/docs/cookbook/forms/validation)

> 创建表单时需要一个`GlobalKey`标识这个表单。
>
> `TextEditingController`或者`onChanged()`来监听文本变化。

```dart
class MyCustomFormState extends State<MyCustomForm> {
  GlobalKey _formKey = GlobalKey<FormState>();

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





### 文本选择控件(SelectableText)

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

### 下拉刷新(RefreshIndicator)

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

### 进度条

#### LinearProgressIndicator

> 线性进度条

#### CircularProgressIndicator

> 圆形进度条

| 属性              | 类型                  | 描述                                   |
| --------------- | ------------------- | ------------------------------------ |
| value           | double?             | 表示当前进度，范围：\[0, 1]。默认`null`会执行一个循环动画。 |
| backgroundColor | Color?              | 背景色                                  |
| valueColor      | Animation\<Color?>? | 进度条颜色；可以指定颜色变化的动画效果。                 |

### InkWell（水波纹效果）



## 三、Cupertino组件

> IOS： Cupertino 风格

```dart
import 'package:flutter/cupertino.dart';
```

