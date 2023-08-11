# Android客户端框架

## 常见的应用架构模式

Android中常见的开发框架设计有MVC、MVP、MVVM、MVI等。

### MVC

MVC 即 Model-View-Control 。是一种将视图、数据、业务逻辑分离的经典开发模式。

* **Model（数据层）**：负责控制数据相关逻辑的操作。如文件IO，网络IO、数据库等。
* **View（视图）**：负责视图显示以及一些视图相关的逻辑。即XML、View等。
* **Controller（控制器）**：负责业务逻辑处理。在Android就是Activity、Fragment等，它同时持有了View和Model。

![image-20230227191223857](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230227191223857.png)

不过在Android中使用MVC，若是简单的将Activity 等容器作为Controller，会导致一些问题。因为Activity会持有一些UI并包含很多操作视图逻辑的代码，这就导致Activity即是Controller的同时又是一个View，使得Activity变得越来越臃肿，且存在耦合。

![image-20230227191239955](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230227191239955.png)

> 优点：

简单，写的时候爽快。

> 缺点：

* Activity即是Controller又是View，随着业务复杂，Activity越来越臃肿，维护将会愈加困难。
* Activity内的业务逻辑无法复用。
* View和Model可以直接交互，它们之间存在耦合。



### MVP

MVP（Model-View-Presenter）是基于MVC演进而来，它将Activity中的Controller抽离出来作为Presenter，将Activity等都归类为View，Model则还是和MVC一样。

和MVC的主要区别是 View和Model不直接通信，而是通过Presenter进行交互。一般回定义一个Contract接口，其中包括了该业务MVP架构的结构定义：IView、IPresenter等接口。

有些项目使用MVC框架时可能已经单独抽离了Controller类，并通过回调来操作视图，这样其实应该算是一种MVP。

* **Model**：负责控制数据相关逻辑的操作。和MVC相同。
* **View**：负责视图显示以及一些视图相关的逻辑。Activity、Fragment等被划分到此处。它持有Presenter。
* **Presenter**：负责业务逻辑处理。它持有View和Model。

![image-20230227174121158](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230227174121158.png)

> 优点：

* 将Controller从Activity中分离，解决了Activity臃肿的问题。
* 将Model和View解耦, 它们都只能和Presenter通过接口交互，降低了耦合度。
* Presenter可以用于多个视图，适用于UI变化频繁，但业务逻辑变动不大的情况。不过Presenter和View间还是存在一定的依赖关系。
* 面向接口编程，更易测试。

> 缺点：

* 需要手动定义层间的交互接口，逻辑较复杂且存在大量的模板代码。虽然可以通过模板生成，但还是比较笨重。
* Presenter持有View需要注意内存泄露和view为空等问题。
* 由于View和Presenter间通过接口通信，View的业务逻辑越复杂，则Presenter和View之间的绑定越紧密，此时Presenter的复用程度就降低了。强行复用会导致其他View需要实现很多不需要的接口，则违背接口隔离。

### MVVM

MVVM(Model-View-ViewModel) 应该算是基于MVP演化而来，使用ViewModel代替了Presenter，引入了**数据驱动和**，将MVP中需要 手动进行数据和视图同步的操作，改为了自动。

在Android中，ViewModel将View和Model分离，然后通过LiveData、DataBinding 等组件将 数据 和 UI进行绑定。

* **LiveData（Flow）数据驱动**：Activity 等容器监听 LiveData等组件，当数据发生变化时，基于数据驱动更新UI。
* **DataBinding（双向绑定）**：当View发生变化时会自动反映到ViewModel 中并修改数据，当数据发送变化时也会自动反应在View上。也就是实现了数据的双向绑定。

MVVM 整体结构：

* **Model**：负责控制数据相关逻辑的操作。这部分没有发生变化。
* **View**：负责视图显示以及一些视图相关的逻辑。
* **ViewModel**：负责将View和Model分离，并实现双向绑定。

![image-20230227194551183](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230227194551183.png)

> 优点：

* MVVM框架将Model和View完全分离, 降低了耦合度。
* 不必像MVP一样定义交互接口，使用 LiveData等组件 通过数据驱动更新UI，同时这些组件具有生命周期感知能力，不必再处理生命周期问题，使得开发可以专注于数据和视图的交互。
* ViewModel可以包含多个View的逻辑，实现复用，且View也仅关注自己需要的数据，不会因为ViewModel中其他逻辑而需要实现额外的接口。

> 缺点：

* 自动化的过程无疑会增加问题排除的难度，特别是使用DataBinding时。
* 由于ViewModel对外暴露的数据和View没有什么关联，也存在一定的模板代码，反而有点不好管理。



### MVI

MVI（Model-View-Intent）**单向数据流**，是一种响应式编程思想。它和MVVM类似，不过更加强调数据的流向和唯一数据源。

> 不过具体使用单数据流还是多数据流，官方并没有强制规定。我觉得单数据流过大时可以考虑拆分成多个数据流，只要将数据合理的归类即可。

* **Model（ViewState）**：此处的Model是指UI的所有状态，包括UI中显示的数据，加载的状态等。
* **View**：视图。和其他框架没有区别。
* **Intent（ViewEvent）**：是指用户操作UI 的事件。
* ViewModel：和 MVVM 中的ViewModel功能一致，将M、V、I关联起来，接收 ViewEvent处理数据，输出 ViewState更新UI。

![image-20230227194752185](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230227194752185.png)

> 优点：

* 由于是单向数据流，更容易跟踪定位。
* 将数据和View 建立了一定的关联性，数据和事件集中管理，使结构更加清晰易维护，可读性更高。

> 缺点：

* 每次更新State对象都需要重新创建，即使仅变动了某一个部分，会产生额外的内存开销。
* 页面复杂时，State将会很复杂，同时State更新会导致整个页面都更新。可以考虑State分组拆分或者实现Diff操作。



---

## 项目代码结构

### 技术维度划分

> adapter、ui、util 等按照技术类型的方式分包。

由于业务之间没有设定边界，容易导致不同业务间的横向依赖，代码耦合度高。

某一业务迭代时会影响到其他业务，随着业务的增加后期很难维护。

### 业务维度划分

> user、message等按照业务进行分包。

根据业务来划分，可以保证业务代码的高度内聚，职责更加单一，同时也能减少不同模块间的横向依赖。

可以减少各业务迭代的影响范围，不容易发生冲突。

### 组件化分层

根据业务维度来划分代码，基于关注点分离，每个组件专注于自身代码高度内聚、职责更加单一。

项目代码分成一个个独立的可复用组件，最终通过组件组合的方式合成系统。

组件化一般分为： 业务组件、功能组件、基础组件。业务组件在最上层，基础组件在最下层。

* **业务组件**：根据业务维度划分的独立组件，平时的业务迭代主要都是在这些组件内进行。例如用户模块、消息模块等。
* **功能组件**：和业务存在关联作为业务功能的支撑，并且可在不同业务间复用的功能。例如分享、支付等。
* **基础组件**：和业务无关的完全通用的代码和依赖库。例如网络请求、图片加载、数据存储等。

组件间的依赖规则：

* 上层组件依赖下层组件，但是**下层组件不能依赖上层组件**。
* 业务组件之间**不应该存在横向依赖**。

### 组件化的优点

* 由于业务员组件间不存在依赖，开发时互不干扰。
* 组件职责单一且功能内聚，方便单元测试。
* 组件开发完毕后，可直接使用打包产物，组件可复用。能提高编译速度和开发效率。

## 项目重构

重构能使整个项目更易于理解，提高项目的可维护性和可测性，降低项目维护成本和风险。在后续迭代中也能起到减少开发周期的效果，不过重构这个过程需要耗费一些时间，复杂度越高耗时越长。

### 重构的粒度

在平时的项目迭代可以适当的进行中低粒度的重构，能缓解项目变得臃肿混乱，也能有利于后续进行大型的重构。对于大型重构则需要设立专项来解决，牵扯面较广。

| 类型         | 说明                                                    | 粒度 | 复杂度 | 耗时 | 收益 |
| ------------ | ------------------------------------------------------- | ---- | ------ | ---- | ---- |
| 类内部的重构 | 参数/函数重命名、函数参数的缩减、过大函数的拆分等。     | 低   | 低     | 低   | 低   |
| 类间的重构   | 提取公共超类/接口，进行抽象，职责划分。抽取公共工具类。 | 中   | 中     | 中   | 中   |
| 项目架构重构 | 例如组件化，往往也伴随着上述两种重构。                  | 高   | 高     | 高   | 高   |

---

## 项目分析工具

### Dependencies

Android Studio自带的依赖分析工具。可以分析项目中组件、packages和classes之间的依赖关系。使用于本地检测依赖。

![image-20230228160338448](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230228160338448.png)

Dependency Validation 自定义规则进行过滤。

1. 首先添加Scopes。

   * 可以根据 `Packages`和`Project`两种方式指定匹配规则。packages是按照包名，Project是按照文件路径。

   * 选择`inclulde ..`指定包含哪些文件，`exclude ..` 指定排除哪些文件。

2. 使用Scopes来定义检测规则。例如截图中是，apps中的代码不能在utils中的代码依赖。

3. 重新执行检测。不符合规则的部分将会被标记为红色。

![image-20230228170302552](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230228170302552.png)

![image-20230228170745748](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230228170745748.png)



### ArchUnit

[Getting Started - ArchUnit](https://www.archunit.org/getting-started)

可以使用 Java 单元测试框架来检查 Java 代码的架构。可以检查packages和classes、layers 和slices之间的依赖关系，检查循环依赖关系等。即可用于本地检测依赖，也可集成仅CI流水线。

```groovy
dependencies {
    testImplementation 'com.tngtech.archunit:archunit:1.0.1'
}
```



### Inspection

使用Android Studio自带的 Inspect工具来检测代码质量。

![image-20230228171928202](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230228171928202.png)

也可以使用IDE字段的 remove unused resources 来扫描没有使用的资源。

![image-20230228172305419](./Android%E5%AE%A2%E6%88%B7%E7%AB%AF%E6%A1%86%E6%9E%B6.assets/image-20230228172305419.png)

### Sonar





