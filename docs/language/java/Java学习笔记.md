# Java学习笔记

* JVM（Java Virtual Machine）。Java虚拟机，是Java实现跨平台的关键。

* JRE（Java Runtime Environment）。Java运行时环境。包含了JVM和Java基本类库。

* JDK（Java Development Kit）。Java的软件开发工具包，基础了JRE和一些工具（javac, javadoc等）。
* OpenJDK：OpenJDK基于Sun捐赠的HotSpot源码，完全开源。由Oracle维护。
* OracleJDK：基于OpenJDK。不完全开源。添加了额外功能和商业功能。



## 基础类型和包装类型

### 基础类型

| 类型      | 字节 | 位数 | 默认值  | 取值范围                                   |
| :-------- | :--- | :--- | :------ | ------------------------------------------ |
| `byte`    | 1    | 8    | 0       | -128 ~ 127                                 |
| `short`   | 2    | 16   | 0       | -32768 ~ 32767                             |
| `int`     | 4    | 32   | 0       | -2147483648 ~ 2147483647                   |
| `long`    | 8    | 64   | 0L      | -9223372036854775808 ~ 9223372036854775807 |
| `char`    | 2    | 16   | 'u0000' | 0 ~ 65535                                  |
| `float`   | 4    | 32   | 0f      | 1.4E-45 ~ 3.4028235E38                     |
| `double`  | 8    | 64   | 0d      | 4.9E-324 ~ 1.7976931348623157E308          |
| `boolean` |      | 1    | false   | true、false                                |

### 包装类

> Integer、Float等8大基础类型对应的引用类型。

包装类的缓存机制：

`Byte`,`Short`,`Integer`,`Long`类默认创建了数值 **[-128，127]** 的相应类型的缓存数据。

`Character` 创建了数值在 **[0,127]** 范围的缓存数据。

`Boolean` 直接返回 `True` or `False`。

### 自动装箱和拆箱

> 拆装箱存在一定的性能损耗。

* 装箱：将基本类型转为包装类型（`valueOf()`）。
* 拆箱：将包装类型转为基本类型（`xxxValue()`）。

```java
Integer i = 1; // 装箱：Integer i = Integer.valueOf(1);
int j = new Integer(2); // 拆箱：int j = new Integer(2).intValue();

```



### 两者的区别

* 默认值：包装类型的默认值是null, 基础类型的默认值是具体的某个值。
* 泛型：包装类型可用于泛型，基础类型则不行。
* 内存存储位置：包装类属于对象类型，对象实例存储在堆中。基础类型作为局部变量存储在虚拟机栈的局部变量表中。
* 内存占用：基础类型占用空间更小。
* 比较方式：基础类型直接值比较，包装类型则时`equals`比较，值相同，对象不一定相同。



## 强,软,弱,虚引用

* StrongReference(强引用)

  如果一个对象是强引用, 即使OOM也不会被回收
  当没有任何对象指向它时 会被GC回收

* SoftReference(软引用)

  若一个对象仅具有软引用, 则当内存不足时会被gc回收
  用于内存敏感的高速缓存

* WeakReference(弱引用)

  则当gc扫描时发现只具有弱引用的对象, 则会被回收

* PhantomReference(虚引用)

  若一个对象仅具有虚引用,则在任何时候都可能被垃圾回收器回收





## 线程

| Java线程状态  | Native线程状态           | 说明                                                         |
| ------------- | ------------------------ | ------------------------------------------------------------ |
| BLOCKED       | Blocked                  | Monitor阻塞，在`synchronized`时发现锁已被其他线程占用。线程正在等待获取锁 |
| NEW           | Starting                 | 线程启动                                                     |
| TERMINATED    | Terminated               | 线程已执行完毕。                                             |
| RUNNABLE      | Runnable                 | 正在运行中。                                                 |
| RUNNABLE      | Native                   | 正在调用JNI方法。                                            |
| RUNNABLE      | Suspended                | 由于GC或者debugger导致暂停。                                 |
| WAITING       | WaitingForGcToComplete   | 等待GC完毕。                                                 |
| WAITING       | WaitingForDeoptimization | 等待Deoptimization完毕                                       |
| WAITING       | WaitingForJniOnLoad      | 等待dlopen和JNI load方法完毕                                 |
| WAITING       | Waiting                  | 调用了`Object.wait()`, **没有设置超时时间**。线程正在等待被其他线程唤醒。自身不持有锁 |
| TIMED_WAITING | TimedWaiting             | 调用了`Object.wait()`,**设置了超时时间**。                   |
| TIMED_WAITING | Sleeping                 | 调用了`Thread.sleep()`                                       |

```java
synchronized (object)  {     // 在这里卡住 --> BLOCKED
    object.wait();           // 在这里卡住 --> WAITING
}  
```

## 拷贝

### 浅拷贝

> Object.clone()是浅拷贝。

* 在堆上新生成了一份拷贝对象实例。
* 若对于内部的引用类型仅是引用拷贝，即内部属性还是指向的同一个对象。**修改内部引用类型会影响到另一方**。

### 深拷贝

* 在堆上不仅生成了一份拷贝对象实例还生成了内部对象的拷贝对象。
* 完全复制对象，包括对象内部的对象。
* 任何一方对原实例对象的修改以及内部对象的修改都**完全不会影响到另一方**。

### 引用拷贝

* 堆上未生成新的对象实例。
* 两个不同的引用指向同一个对象，仅引用不同。

* 两者指向的是同一个对象，所以**任何一方修改都会影响到另一方**。

## JVM

[JVM学习笔记](./JVM学习笔记.md)

