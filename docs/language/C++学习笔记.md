# C++学习笔记

## 环境搭建

> Linux默认只有GCC, 安装G++编译器。

```shell
sudo apt-get install g++
```

> GCC编译命令

```shell
gcc a.cpp -o a
```

> G++编译命令

```shell
g++ xxx.cpp -std=c++14 -o a.out
```

## 程序的生命周期

【编码 Coding】->【预处理 Pre-processing】->【编译 Compiling】->【运行 Running】

### 编码

> 源码

### 预处理

> 预处理阶段操作的**目标是源码**。由`预处理器`处理。
>
> 所有指令以`#`开头：例如`#include` 、`#define`、`#if`等指令

| 指令     | 作用           | 备注                                   |
| -------- | -------------- | -------------------------------------- |
| #include | 包含任意文件   | 源码级别的数据合并，合并到源文件中。   |
| #define  | 宏定义         | 源码级别的文本替换                     |
| #undef   | 取消宏定义     | 使用完毕后取消，可以防止后续发生冲突。 |
| #ifdef   | 宏定义前先检查 | 判断宏是否已存在                       |
| #if      | 条件编译       |                                        |
| #else    | 分支           |                                        |
| #endif   | 检查结束       |                                        |
|          |                |                                        |

>Include Guard
>
>防止重复包含

```c++

#ifndef _XXX_H_INCLUDED_
#define _XXX_H_INCLUDED_

...    // 头文件内容

#endif // _XXX_H_INCLUDED_
```



> 条件编译
>
> 可以针对不同系统进行不同处理。

```c++
#if 0          // 0即禁用下面的代码，1则是启用
  ...          // 任意的代码
#endif         // 预处理结束

#if 1          // 1启用代码，用来强调下面代码的必要性
  ...          // 任意的代码
#endif         // 预处理结束
```

### 编译

> 输入：预处理后的C++源码。
>
> 输出：二进制可执行文件。

**属性（attribute）**

> 告知编译器一些信息、提示。不涉及程序的具体执行。
>
> 格式：[[...]]
>
> 官方属性

|                    |       |      |
| ------------------ | ----- | ---- |
| noreturn           | C++11 |      |
| carries_dependency | C++11 |      |
| deprecated         | C++14 |      |
| fallthrough        |       |      |
| likely             |       |      |

> GCC属性
>
> gnu::

[Attribute Syntax (Using the GNU Compiler Collection (GCC))](https://gcc.gnu.org/onlinedocs/gcc/Attribute-Syntax.html)

**静态断言（static_assert）**

> 不同于assert（动态断言）作用于运行阶段，静态断言在编译时生效。

### 运行





## C++的文件类型

| 文件类型 | 定义      | 内容      | 作用           |
| -------- | --------- | --------- | -------------- |
| .cpp     | C++源文件 | C++源代码 | 定义，具体实现 |
| .h       | C++头文件 | C++源代码 | 声明           |
| .hpp     | 完整      | 完整      | 完整的功能     |

思考为什么会存在`.h`和`.cpp`两个文件：

首先C++支持分离式编译(separate compilation)。

```
所以一个程序的内容可以放在不同的cpp文件中，且每个文件的内容都相对独立，编译时不需要其他文件参与。
```

那么它时如何调用其他文件的方法的呢？

通过对编译后的目标文件和其他的目标文件进行``链接（link）``实现的。

``a.cpp``：

```C++
// 定义
void a(){
  printf("aaaaa")
}
```

``b.cpp``：

```c++
// 声明
void a();
int main() {
	a();
	return 0;
}
```

``b.cpp``需要调用``a.cpp``	中的``void a()``，那么首先 ``a.cpp``中需要定义这个函数，而``b.cpp``中需要声明这个函数。当存在多个函数需要调用时，``b.cpp``中则需要知道且声明所有需要调用函数，这个声明过程将十分复杂。``.h``文件就是处理这个问题的。

``a.h``：

```C++
void a();
```

``b.cpp``中引入这个``a.h``头文件即可：

```C++
#include "a.h"
int main() {
	a();
	return 0;
}
```

## 指针

### 裸指针（naked pointer）

> 原始指针、指针，来源于C语言。
>
> 内存地址索引。
>
> 尽量使用`智能指针`。
>
> 使用`*`定义。

```c++
int a = 1;
// 指针变量p指向a，值就是a的地址。
int *p = &a;
// 此处的*表示取值。输出 1
cout << *p << endl;
```



### 智能指针（smart point）

> 使用**RAII 惯用法（Resource Acquisition Is Initialization）**代理了裸指针。重载`*`、`->`，保证和原始指针使用方式相同。
>
> 自动管理指针，离开作用域时析构释放内存。

**unique_ptr** 

> 实质是对象不是指针。
>
> 不允许共享（拷贝赋值）。
> 使用`std::move()`转移**所有权**。转移后变为空指针。

```c++
// 需要初始化，未初始化时为空指针。
unique_ptr ptr1(new int(10));
// 工厂函数创建智能指针
auto ptr2 = make_unique<int>(10);
assert(ptr2 && *ptr2 == 10);
// 使用move()转移所有权
auto ptr3 = std::move(ptr1); 
// ptr1变成了空指针
assert(!ptr1 && ptr3); 
```

**shared_ptr**

> 不同于`unique_ptr`，它的所有权可以被共享（拷贝赋值），通过**引用计数**实现。
>
> 引用计数的存储和管理存在一定的性能开销（较小）。
>
> 无法确定真正的释放时机，释放时会阻塞整个进程或者线程，析构中不要有复杂、阻塞的操作。

循环引用问题，配合`weak_ptr`使用。

```C++
auto n1 = make_shared(); // 工厂函数创建智能指针
```

**weak_ptr**

> 用于解决循环引用问题，只观察指针，不会增加引用计数（弱引用）。

```C++
if (!n1->next.expired()) { // 检查指针是否有效 
    auto ptr = n1->next.lock(); // lock()获取shared_ptr 
    assert(ptr == n2);
}
```

## 引用

> 引用可以看作是数据的别名。两者的地址相同，数据相同。
>
> 定义时使用`&`表示引用。必须初始化。

```C++
int a = 1;
int &r = a;
// 输出1，1
cout << a << ", " << r << endl;
// 此处的&表示取地址，输出两个相同的地址
cout << &a << ", " << &r << endl;
```





## 宏（合理使用）

> 宏定义又称为宏代换、宏替换，简称为``宏``。

* 发生在`预处理阶段`，所以没有任何运行期的效率损失。

  预处理器发现此类宏定义时，会将所有的``标识符``替换成``替换字符串``。

  替换字符是C语言记号，例如数、字符常量、运算符、标点等。

* 没有作用域概念，`全局生效`。对于临时使用的宏可以通过`#undef`取消定义

> 一些预定义的宏

| 指令                 |                     |      |
| -------------------- | ------------------- | ---- |
| __cplusplus          | 标记了C++语言的版本 |      |
| __cpp_decltype       |                     |      |
| __cpp_decltype_auto  |                     |      |
| _cpp_lib_make_unique |                     |      |
| FILE                 |                     |      |
| LINE                 |                     |      |
| DATE                 |                     |      |



### 1. 简单的宏

格式：``#define 标识符 替换字符串``

```C++
#include <iostream>

#define HELLO "hello"
// 定义符号
#define BEGIN {
#define END }

void a() BEGIN
    printf(" func a\n");
END

int main() {
    printf(HELLO);
    a();
}
```

一些容易出现的错误声明方式：

```
// 将会被替换为 = "hello"
#define HELLO = "hello"
// 将会被替换为 "hello";
#define HELLO "hello";
```

### 2. 带参数的宏

格式：``#define 标识符 替换字符串``

- ``#`` 表示转换为字符串。
-  ``##``（记号连接运算符）：会将参数连接起来。

```C++
#include <iostream>

// 带参数的宏定义
// 注意宏民和括号间不要又空格例如：SUM (x, y) (x + y)
// 此写法将会被识别为简单的宏替换，替换为: (x, y) (x + y)
#define SUM(x, y) (x + y)
// # 表示转换为字符串。
#define TO_STRING(s) #s
// ##（记号连接运算符）：会将2个参数连接起来
#define CONCAT(x, y) x ## y

int main() {
    printf("sum %d\n", SUM(x, y)); // 输出 3
    printf("to string %s\n", TO_STRING(hello)); // 此处hello将被转为 "hello"输出。
    printf("concat %d", CONCAT(22, 33)); // 输出 2233
}

```

## 常量/变量

### volatile

> 少用、慎用。

* 静止编译器优化

* 会影响性能。

### const

> const对象只能调用const成员函数

* 修饰变量，只读。
* 修饰成员函数，不改变对象状态。
* 可以被编译器优化。
* ~~常量指针：const*（只读）~~，少用，尽量使用smart point。
* 万能引用：const& （只读）

### mutable

> 一般用于不对外暴露的成员变量。比如计数器等。

* 修饰成员变量。
* 可以接触const的限制，但是不影响对象的常量性。



## 类

* 构造函数
* 析构函数
* 拷贝构造函数
* 拷贝赋值函数
* 转移构造函数
* 转移赋值函数

> `= delete` 表示明确地禁用某个函数形式。

```C++

class DemoClass final 
{
public:
    DemoClass() = default;  // 明确告诉编译器，使用默认实现
   ~DemoClass() = default;  // 明确告诉编译器，使用默认实现
    DemoClass(const DemoClass&) = delete; // 禁止拷贝构造 
    DemoClass& operator=(const DemoClass&) = delete; // 禁止拷贝赋值
};
```



## 容器

> 存储的元素是`值`

### 顺序容器

> 线性表结构

连续存储

* array：静态数组
* vector：动态数组
* deque：双端队列

链表存储

* list：双向链表
* forward_list：单向链表

### 有序容器

> 插入元素有排序成本

红黑树结构

* set/multiset：集合
* map/multimap：关联数组/字典

### 无序容器

> 插入、查找成本低

散列结构

* unordered_set/unordered_multiset： 集合
* unordered_map/unordered_multimap：关联数组



## 性能分析工具

* top：快速查看进程的CPU、内存使用情况。
* pstack和strace：显示进程在用户空间和内核空间的函数调用情况。
* perf：一定频率采样分析进程，统计各个函数的CPU使用情况。
* gpreftools：基于采样，侵入式（需要编码集成）的性能分析工具，可以生产文本和图形化（例如火焰图）的分析报告。

