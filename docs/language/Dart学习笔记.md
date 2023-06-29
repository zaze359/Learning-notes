# Dart学习笔记

[Dart 编程语言主页 | Dart 中文文档 | Dart](https://dart.cn/)

## 一、语言特性

> Flutter开发时热重载就是基于JIT。
>
> 项目发布时，使用的是AOT。

- 支持AOT（提前编译）和JIT（即时编译）
- 快速分配内容
- 强类型语言，类型安全和空安全。
- Dart中一切都是对象(包含函数、运算符)。
- Dart不支持参数重载，以可选命名参数和可选参数的方式替代。

## 二、基础语法

### 2.1 类型和变量声明

- 可变变量：var

  ```dart
  // 赋值时决定类型，且类型不可改变
  var hw = "hello world";
  ```

- 不可变变量：final、const

  ```dart
  // 第一次使用时被初始化，类型不可改变。
  final hello = "hello";
  // 编译时常量，类型不可改变。
  const world = "world";
  ```

### 2.2 基础类型

#### num

- int(64位)
- double

#### bool和String(UTF-16)

#### List和Map

```dart
var list1 = ["A", "B", "C"];
var list2 = <String>["A", "B", "C"];
var list3 = List<String>.of(["A", "B", "C"]);

var map1 = <String, String>{'a': 'A','b': 'B',};
var map2 = Map<String, String>();
```

### 2.3 函数

#### 定义普通函数

```dart
// 此处返回类型默认是dynamic, 不是String
helloWorld() {
	return "hello world";
}

// 声明了返回类型，则为String
String hello() {
	return "hello";
}
```

#### 可选命名参数和可选函数

> 按位置：参数增加`[]`。
>
> 按名字：参数增加 `{}`。

```dart
// 按照位置
void hello(String a, String b, [String? device]) {
	// ....
}
// 调用
hello('hello', "world");
```

```dart
// 按照参数名
void hello2({String? a, String? b, String? c}) {
	// ....
}
// 缺省 a
hello2(b:'hello', c:"world");
```

#### 函数当作参数传递

> dart中函数也是对象类型: ``Function``。
>
> 所以函数可以定义为变量，也可当作参数进行传递。

```dart
// Function(String) hello = (s) {
//   print(s);
// };
hello(s) {
  print(s);
}
hello("world");					// 直接调用函数
doFun(hello, "world");	// 作为参数传递
///
void doFun(Function(String) h, String str) {
  h(str);
}
```



### 2.4 空安全

```dart
int? a;
```

### 2.5 异步

``Future``：处理异步操作。

```dart
Future<int> execute() {
  return Future.delayed(
    const Duration(
      seconds: 1,
    ), () {
      print("do something ~");
      sleep(const Duration(seconds: 2));
      print("done and return ~");
      return Random(1).nextInt(10);
    });
}
TextButton(
  onPressed: () {
    print("execute start");
    execute(1).then((value) {
      _updateNum(value);
    }).catchError((e) {
      // 失败时执行
      print(e);
    }).whenComplete(() {
      // 无论成功或失败都会执行
    });
    print("execute end"); // 紧跟start后输出
  },
  child: Text("Future"),
)
```

``Stream``：区别于``Futrue``的点在于，它支持接受多个异步操作的返回结果，常用于下载。

```dart
Stream<int> executeBySteam() {
  return Stream.fromFutures([
    execute(1),
    execute(3),
  ]);
}
TextButton(
  onPressed: () {
    print("execute start");
    executeBySteam().listen((event) {
      _updateNum(event);
    }, onError: (e) {
      print(e.message);
    });
    print("execute end"); // 紧跟start后输出
  },
  child: Text("Stream"),
)
```

async声明异步函数

```dart
Future<String> lookUpVersion() async => '1.0.0';
```

> 必须在带有async关键字的异步函数中使用``await``。
>
> Stream中使用``await for``。

完整测试代码：

```dart

class AsyncTest extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AsyncTestState();
  }
}

class _AsyncTestState extends State<AsyncTest> {
  int _randomNum = 0;

  void _updateNum(int newNum) {
    print("updateNum $newNum");
    setState(() {
      _randomNum = newNum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text("_randomNum: $_randomNum"),
          TextButton(
            onPressed: () {
              print("execute start");
              execute(1).then((value) {
                _updateNum(value);
              }).catchError((e) {
                // 失败时执行
                print(e);
              }).whenComplete(() {
                // 无论成功或失败都会执行
              });
              print("execute end"); // 紧跟start后输出
            },
            child: Text("Future"),
          ),
          TextButton(
            onPressed: () async {
              print("execute start");
              // 等待异步执行结果。可换成
              var i = await execute(1);
              _updateNum(i);
              print("execute end"); // 最后输出
            },
            child: Text("Future await"),
          ),
          TextButton(
            onPressed: () {
              print("execute start");
              executeBySteam().listen((event) {
                _updateNum(event);
              }, onError: (e) {
                print(e.message);
              });
              print("execute end"); // 紧跟start后输出
            },
            child: Text("Stream"),
          ),
          TextButton(
            onPressed: () async {
              print("execute start");
              await for (var i in executeBySteam()) {
                _updateNum(i);
              }
              print("execute end"); // 最后输出
            },
            child: Text("Stream await for"),
          )
        ],
      ),
    );
  }

  Future<int> execute(int delay) {
    return Future.delayed(
        Duration(
          seconds: delay,
        ), () {
      print("do something ~");
      return Random().nextInt(100);
    });
  }

  Stream<int> executeBySteam() {
    return Stream.fromFutures([
      execute(1),
      execute(3),
    ]);
  }
}

```



### 2.5 extends、Implements和mixin

#### extends

> 和java一样

子类由父类派生，能获取父类的成员变量和方法实现，可以根据需要覆写。

#### implements

> 和java的区别就是不用再定义接口类，类似于直接装类转成的类接口。

dart中的类可以通过``implements``被当作接口供子类实现，不过需要重新实现成员变量、方法声明和初始化。

#### mixin(混入)

使用``with``可以将``mixin``类组合使用，相当于多继承的功能。

> 多继承的歧义问题：相同方法名默认使用 **最后一个**。

```dart
// mixin 类
mixin AutomaticKeepAliveClientMixin<T extends StatefulWidget> on State<T> {
    
}

class _PageState extends State<Page> with AutomaticKeepAliveClientMixin {

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Center(child: Text("${widget.text}", textScaleFactor: 5));
  }

  @override
  bool get wantKeepAlive => true;
}
```

### 2.6 特殊运算符摘录

| 运算符 | 范例           | 说明                                                         |
| ------ | -------------- | ------------------------------------------------------------ |
| ?.     | a?.toString(); | a不为null则执行后面部分toString()，否则跳过。                |
| ??=    | a ?? = "";     | a为null时赋值，否则跳过。                                    |
| ??     | a ?? b         | 相当于三目运算，a为null则返回a,否则返回b。                   |
| ..     |                | 级联运算符，可以在同一个对象上连续调用多个函数和访问成员变量。有点类型kotlin的apply。 |

#### 运算符覆写

> ` operator` 关键字表示是：类成员运算符函数。

```dart
  @override
  bool operator ==(Object other) {
    ...
  }
```



### 访问可见性

dart 没有 public，protected和private 这些访问修饰符，默认都是public。

可以使用 `_` 开头表示私有，仅在当前作用域可见。

```dart
// _A 仅能在当前这个 .dart文件访问
class _A {
    
}

class B {
    // _b仅能在 B中访问
    void _b() {
        
    }
}
```

###  get/set

```cpp
// book是成员变量，它的 get 方法 返回的是 _book
// 表示返回类型是 Book
Book get book => _book;

// page是成员变量
// page的set方法接收一个 int类型的参数，后面的函数体是set方法的实现。
set page(int page) {
    _params["{{page}}"] = page;
}

```



### 扩展（extension）

通过  `extension`  关键字来对类进行扩展

> 可以省略扩展名，但是它仅能在声明的地方使用。

```dart
// SiteEntityExt 是扩展名
// SiteEntity 是原始类型
// asExternalModel() 是扩展方法
extension SiteEntityExt on SiteEntity {
  Site asExternalModel() {
    return Site(
        title: title,
        url: url,
        tags: tags,
        from: from,
        type: type,
        updateTime: updateTime);
  }
}

// use
SiteEntity site = new SiteEntity();
site.asExternalModel();
```



### 单例模式

> Dart单例模式：static变量 + 工厂构造函数

```dart
class BookConfig {
  BookConfig._internal(this.viewWidth, this.viewHeight);

  static final BookConfig _instance = BookConfig._internal(0, 0);

  factory BookConfig({double viewWidth = 0, double viewHeight = 0}) {
    _instance.updateSize(viewWidth, viewHeight);
    return _instance;
  }
}
```



### 并发

使用isolate

错误处理:

> 传给isolate处理的函数必须是顶级函数，因为内存不共享，内部使用的变量都无法使用。
>
> 所以需要将函数将函数放到最外层。或者声明为静态(变量能访问，但是是初始化值)。

```
Illegal argument in isolate message: (object extends NativeWrapper)
```



## 内存分配和垃圾回收

### 内存分配

- 创建对象仅需要在堆上移动指针。
- 内存增长总是线性的，省去了查找可用内存的过程。

### 垃圾回收

采用了多生代算法。

Dart的新生代在内存回收时采用`半空间机制`。触发垃圾回收时，Dart会先将当前半空间中的`活跃对象拷贝到备用空间`，然后整体释放内存。回收过程仅操作了活跃对象，没有引用的对象则被忽略，很适合大量对象需要销毁重建的场景。

## Dart的单线程模式

> Dart 中并发是通过lsolate(隔离区)实现。

lsolates之间不会共享内存，而是通过事件循环在事件队列上传递消息通行。

> Dart运行原理：消息循环机制。
>
> ``microtask queue``：微任务队列。
>
> ``event queue``：事件队列。
>
> 异常：在事件循环中，某个任务发生异常且未捕捉，只会导致``当前任务中断``不在执行，``程序并不会退出``。

![](https://guphit.github.io/assets/img/2-21.eb7484c9.png)

