# Dart学习笔记

[Dart 编程语言主页 | Dart 中文文档 | Dart](https://dart.cn/)

## 一、语言特性

- 支持AOT（提前编译）和JIT（即时编译）
- 快速分配内容
- 强类型语言，类型安全和空安全

## 二、基础语法

> 和kotlin诸多类似，

### 2.1 变量声明

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

### 2.2 函数

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

> 声明函数变量
>
> 可以作为参数传递

```dart
var hello = (s) {
	print(s)
};
hello("world");

void doFun(var h) {
  h();
}
```

> 定义可选参数

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

### 2.3 空安全

```dart
int? a;
```

### 2.4 异步

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





### 2.5 mixin

> 使用``with``可以将``mixin``类组合使用。

- 相同方法名默认使用最后 一个。

```dart
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









## Dart的单线程模式

> Dart运行原理：消息循环机制
>
> ``microtask queue``：微任务队列。
>
> ``event queue``：事件队列。
>
> 异常：在事件循环中，某个任务发生异常且未捕捉，只会导致``当前任务中断``不在执行，``程序并不会退出``。

![](https://guphit.github.io/assets/img/2-21.eb7484c9.png)
