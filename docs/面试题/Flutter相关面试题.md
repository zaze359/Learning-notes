# Flutter相关面试题



## Flutter有哪几种Widget

Flutter的Widget不仅表示UI元素，同时也可以表示功能性组件（`GestureDetector`、`theme`等）。

### StatelessWidget

无状态组件

### StatefulWidget

有状态的组件, 状态在widget生命周期是可以改变的。

### RenderObjectWidget

### InheritedWidget

> 数据共享



## StatelessWidget的生命周期

[Flutter中的StatelessWidget及其生命周期 - 掘金 (juejin.cn)](https://juejin.cn/post/6864724677504270349)

> StatelessElement.build()方法关联了widget.build()

```dart
Widget build() => (widget as StatelessWidget).build(this);
```

![StatelessElement、Component、Element的关系.png](./Flutter%E7%9B%B8%E5%85%B3%E9%9D%A2%E8%AF%95%E9%A2%98.assets/a5b9390e5fd44f4f84e9cee1f425b2fetplv-k3u1fbpfcp-zoom-in-crop-mark4536000.png)

## StatefulWidget和StatelessWidget在接口设计上，为什么会有区别？

Widget相当于视图的配置信息。

StatelessWidget表示无状态组件，它是不变的，所以直接创建所需Widget即可。

StatefullWidget是状态感知的，状态发生变化相当于配置更新，此时需要更新Widget，所以State和Widget是由关联性的，由State来创建Widget在逻辑上更清晰，同时这也是一种数据驱动视图更新的模式。

**为什么有createState()方法？**

我觉得首先应该是解偶，更加灵活。还有可能就是区分Stateless和Statefull两个组件的侧重点，前者侧重构建，后者更强调状态变化，突出数据驱动更新视图这一概念。