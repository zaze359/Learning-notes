# C++学习笔记

## 环境搭建

> Linux默认只有GCC, 安装G++编译器。

```shell
sudo apt-get install g++
```

> GCC编译命令

```shell
gcc a.cpp -o a
# 若编译报错 undefined reference to `std::xxx`
gcc a.cpp -lstdc++ -o a

# 执行
./a
```

> G++编译命令

```shell
g++ xxx.cpp -std=c++14 -o a.out
# 联合编译
g++ a.cpp b.cpp -o b

# 执行
./b
```

> 静态库：`.a`；编译时加载，程序编译时会被链接到目标代码中，运行时不需要再加载这个库。速度快，内存占用多，使执行文件变大。
>
> 动态库：`.o`；运行时加载，编译时不链接，使用时需要动态加载。略慢，内存占用小，执行文件小。



## 程序的生命周期

【编码 Coding】->【预处理 Pre-processing】->【编译 Compiling】->【运行 Running】

### 编码

> 源码

### 预处理

预处理阶段操作的**目标是源码**。由`预处理器`处理。

所有预处理指令以`#`开头：例如`#include` 、`#define`、`#if`等指令

| 指令     | 作用           | 备注                                                         |
| -------- | -------------- | ------------------------------------------------------------ |
| #include | 包含任意文件。 | 源码级别的数据合并，合并到源文件中。`<>` 表示从系统目录查找，`""`表示从当前目录查找。 |
| #define  | 宏定义         | 源码级别的文本替换                                           |
| #undef   | 取消宏定义     | 使用完毕后取消，可以防止后续发生冲突。                       |
| #ifdef   | 宏定义前先检查 | 判断宏是否已存在                                             |
| #if      | 条件编译       |                                                              |
| #else    | 分支           |                                                              |
| #endif   | 检查结束       |                                                              |
|          |                |                                                              |

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

> extern "C"：指示编译器这部分代码按C语言的方式进行编译。**主要作用就是为了能够正确实现C++代码调用其他C语言代码**

* 输入：预处理后的C++源码。

* 输出：二进制可执行文件。

**属性（attribute）**

告知编译器一些信息、提示。不涉及程序的具体执行。

格式：[[...]]

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

## 指针： *

### 裸指针（naked pointer）

> void* 万能指针,可作为一种轻量化的模板编程，它可以指向任何类型的指针。
>
> 它的作用类似泛型擦除，会抹去实例的类型信息，所以使用时需要强制转换类型。。

裸指针也叫原始指针、指针，它来源于C语言。**指针是一个变量，它拥有自己的内存地址，地址内的值为另一个变量的地址**。

* 使用`*`定义一个指针变量，它指向的是 **变量的地址**。赋值时需要使用 `&` 取址运算符来获取变量的地址。

* 指针变量需要通过 `*` 来取值，所以 `*`也叫做**取值运算符**或**间接寻址运算符**。(像a变量，直接访问就能获取到值，就是**直接寻址**)

```cpp
int a = 1;
// 通过 & 获取a的内存地址。
int *p = = &a;
printf("a addr: %d\n", &a); // 6422028 >> a的地址
printf("p: %d\n", p);		// 6422028 >> a的地址，指针的值是a的地址
printf("p addr: %d\n", &p); // 6422016 >> 指针的地址，指针有自己的地址，值存的是 a的地址。
// 使用 * 来取值。输出 1
cout << *p << endl;
```

#### 多级指针

声明 多级指针 就是 使用多个 `*`，一级*、二级 `**`依次类推。访问时也是一样，通过 多个 * 来层层取值。

它们的指都是 变量的地址。

```cpp
int a = 1;
// 一级指针，值为 变量a的地址
int *p = = &a;
// 二级指针，值为 一级指针 p 的地址
int **p2 = &p
printf("p: %d\n", *p);  // 1
printf("p2: %d\n", **p); // 1
```





### 智能指针（smart point）

> 应用尽量使用`智能指针`。

智能指针就是为了避免使用裸指针时可能产生的内存泄露问题，它能够自动管理指针，会在离开作用域时**通过析构释放内存**。

* 使用**RAII 惯用法（Resource Acquisition Is Initialization）**代理了裸指针。实质是对象而并不是指针。

* 重载`*`、`->`运算符，保证和原始指针使用方式相同。

**unique_ptr** 

* 不允许共享（拷贝赋值）。

```c++
// unique_ptr 需要初始化，未初始化时为空指针。
// 直接创建智能指针，这里初始化为 10
unique_ptr ptr1(new int(10));
// 使用工厂函数make_unique 创建智能指针
auto ptr2 = make_unique<int>(10);
assert(ptr2 && *ptr2 == 10);

// 使用std::move()转为右值，并转移控制权，转移后ptr1变为空指针
// 主要是由于 unique_ptr中重写了operator=, 转移权限后会将之前的指针释放
auto ptr3 = std::move(ptr1); 
// ptr1变成了空指针
assert(!ptr1 && ptr3); 
```

**shared_ptr**

* 不同于`unique_ptr`，它的所有权可以被共享（拷贝赋值），通过**引用计数**实现。

* 引用计数的存储和管理存在一定的性能开销（较小）。

* 无法确定真正的释放时机，释放时会阻塞整个进程或者线程，析构中不要有复杂、阻塞的操作。

> 循环引用问题，配合`weak_ptr`使用。

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

## 引用： &

### 使用

* 使用`&` 来定义一个引用变量，且被引用的变量必须初始化。

  ```cpp
  // a必须赋值
  int a = 1;
  // 定义引用r，相当于是a别名。
  int &r = a; 
  ```

* **引用可以看作是变量的别名**，变量和对应的引用变量**具有相同的地址和数据**。

* 使用引用类型作为形参可以避免拷贝，但是函数对形参的修改会影响实参。

  ```cpp
  // 可以避免拷贝
  void modifyByReference(int &num)
  {
      num = 3; // 修改num相当于修改 r
  }
  //
  modifyByReference(r);
  ```

> 完整的测试代码：

```C++
#include <iostream>

using namespace std;

/**
 * @brief
 *
 * @param path 传递的是引用，函数对形参修改后会影响实参
 */
void modifyByReference(int &num)
{
    num = 3;
}

void constReference(const int &num)
{
    // num = 3; // const 无法修改
}

void modifyByRightReference(int &&num)
{
    num = 10;
}

int main()
{
    // ----------------------------------------
    // a是左值，a必须赋值
    // 1是右值。
    int a = 1;
    // 左值：b
    // 右值：a + 1 临时生成的对象
    int b = a + 1;

    cout << a << ", " << b << endl; // 输出1, 2
    cout << "----------------------------------------" << endl;
    cout << "----------------------------------------" << endl;

    // 定义左值引用：lr，相当于是a别名。
    int &lr = a;
    cout << &a << ", " << &lr << endl; // 输出相同地址，例如：0x61fde0, 0x61fde0
    cout << a << ", " << lr << endl;   // 输出1，1

    // 无法直接赋值右值
    // int &r = 1。// 编译报错
    // const 修饰左值引用，支持直接赋值右值
    const int &clr = 5;
    cout << &clr << " -> " << clr << endl;

    // 传递左值引用，内部修改会影响外部
    modifyByReference(lr);
    // modifyByReference(3); // 编译报错，无法传递右值
    cout << a << ", " << lr << endl; // 输出3，3
    // const int &num, const修饰可以传递右值但是无法修改。
    constReference(3);
    cout << "----------------------------------------" << endl;
    cout << "----------------------------------------" << endl;

    // 定义右值引用，能帮助我们能够快速的构建一个引用类型。
    int &&rr = 9;
    // int &&rr = a; // 编译报错，右值引用只能指向右值
    cout << &rr << " -> " << rr << endl;

    // 可以通过 std::move() 将左值转为右值引用，从而实现了右值引用指向左值
    int &&rra = std::move(a);
    // int &&rr2 = std::move(lr); // 和上面是等同的
    cout << &rra << " -> " << rra << ", " << a << endl; // 0x61fde8 -> 3, 3
    // 直接修改右值引用，a也被修改了
    rra = 4;
    cout << rra << ", " << a << endl; // 4, 4
    // 将a转为右值引用，并作为参数传递
    modifyByRightReference(std::move(a));
    // a的值被改变了
    cout << a << ", " << rra << endl; // 10, 10

    // 可以将 rra 赋值给左值引用，所以 rra 本身是一个左值。
    // 声明出来的右值引用是一个左值。
    int &rrl = rra;
    // int rrl = std::move(a); // 编译报错，作为返回值的右值引用是右值
    cout << rrl << ", " << rra << endl; // 10, 10
    cout << "----------------------------------------" << endl;
    cout << "----------------------------------------" << endl;

    std::string s = "aaaa";
    // 这里会将原先 s 中的值直接转移到 rrs中
    std::string rrs = std::move(s);
    cout << s << ", " << rrs << endl; // , aaaa

    s = "aaaa";
    // 左值转左值引用
    std::string &&rrs2 = std::move(s);
    // 右值转右值引用
    std::string &&rrs3 = std::move("ssss");
    cout << s << ", " << rrs2 << ", " << rrs3 << endl; // aaaa, aaaa, ssss


    s = "aaaa";
    // 左值 s，右值 "aaa"
    // 左值s转为 左值引用
    std::string &slr = std::forward<std::string &>(s);
    // 左值s转为了 右值引用
    std::string &&srr = std::forward<std::string>(s);
    // std::string &srr = std::forward<std::string>(s);// 编译报错
    cout << slr << ", " << srr << endl; // aaaa, aaaa

    // 这里需要注意，这里直接将 s中的值转给了 srr2，并且s被置为空
    std::string srr2 = std::forward<std::string>(s);
    cout << slr << ", " << srr2 << endl; // , aaaa
}

```

### 左值和右值

* 左值：存在地址（可以通过 `&` 获取地址）。一般来说是表达式中等号左边部分。**变量就是最常见的一种左值**。

* 右值：不存在地址（无法通过 `&` 获取地址）。一般来说是表达式中`=`右边部分。常见的右值有：**常量** 和**表达式的临时变量(例如x + y)**。

```cpp
// a是左值，a必须赋值
// 1是右值。
int a = 1;
// 左值：b
// 右值：a + 1 临时生成的对象
int b = a + 1;
cout << a << ", " << b << endl; // 输出1, 2
```

### 左值引用

通过`&` 来声明左值引用，上面的例子`int &r = a` 中 r 就是左值引用。即一般常见的引用都是左值引用。

**左值引用一般只能接收左值，不能接收右值**。此时作为参数使用十分不方便，必须先定义一个变量，不能直接传值。

* **使用 const 左值引用，此时即可以接收左值也可以接收右值，但是此时将不能修改值**。所以一般作为参数使用时都会加上const。(const常量相当于不能修改的变量，它也是存在地址的)。

```cpp
int a = 1;
// a 是左值，1是右值
// 定义左值引用：lr，相当于是a别名。
int &lr = a;
cout << &a << ", " << &lr << endl; // 输出相同地址，例如：0x61fde0, 0x61fde0
cout << a << ", " << lr << endl; // 输出1，1

// 无法直接赋值右值
// int &r = 1。// 编译报错

// const 修饰左值引用，支持直接赋值右值
const int &clr = 5;
cout << &clr << " -> " << clr << endl;

// 传递左值引用，内部修改会影响外部
modifyByReference(lr);
// modifyByReference(3); // 编译报错，无法传递右值
cout << a << ", " << lr << endl; // 输出3，3

// const int &num, const修饰可以传递右值但是无法修改。
constReference(3);


// A a = new A()
// A() 是右值
```

### 右值引用

使用 `&&` 来声明右值引用。右值引用就是为了解决 左值引用使用时存在的问题：

* 一般的**左值引用不能接收右值**，所以无法直接传值，必须要定义一个变量。
* 使用 **const 修饰左值引用参数时，虽然可以接收右值即直接传值，但是却无法修改了**，也存在缺陷。

右值引用作为参数时，即可以减少不必要的拷贝开销和内存开销，同时使得函数即支持右值方式接收参数，也支持修改原先的左值。

例如 上方智能指针的案例中，重写的operator 就接收的是右值引用。

* **右值引用只能指向右值**。
* **右值引用本身即可以是左值，也可以是右值**。
  * 声明出来的右值引用是一个左值。
  * 作为返回值的右值引用是右值：`std::move()` 返回值的 `int &&` 是一个右值，它没有被明确声明不存在名字。

```cpp
// 定义右值引用，能帮助我们能够快速的构建一个引用类型。
int &&rr = 9;
// int &&rr = a; // 编译报错，右值引用只能指向右值，而a是左值。
cout << &rr << " -> " << rr << endl;

// 可以通过 std::move() 将左值转为右值引用，从而实现了右值引用指向左值
int &&rra = std::move(a);
// int &&rr2 = std::move(lr); // 和上面是等同的
cout << &rra << " -> " << rra << ", " << a << endl; // 0x61fde8 -> 3, 3
// 直接修改右值引用，a也被修改了
rra = 4;
cout << rra << ", " << a << endl; // 4,4
// 将a转为右值引用，并作为参数传递
modifyByRightReference(std::move(a));
// a的值被改变了
cout << a << ", " << rra << endl; // 10, 10 

// 可以将 rra 赋值给左值引用，所以 rra 本身是一个左值。
// 声明出来的右值引用是一个左值。
int &rrl = rra;
// int rrl = std::move(a); // 编译报错，作为返回值的右值引用是右值
cout << rrl << ", " << rra << endl; // 10, 10
```

### std::move()和std::forward()

* `std::move()`：它的作用是无条件的将**左值/右值转为右值引用**。
* `std::forward<type>()`：它会根据传递的具体类型来进行转换。（这里的类型指的是 type 指定的类型）
  * 若传递的是**左值则转为左值引用**
  * 若传递的是**右值则转为右值引用**。


> 这里的例子中，使用 std::move() 或者 std::forward() 赋值给 std::string 后，原先的对象会被置为空，并不是由于 move和forward引起的，而是 std::string 重写了 `operator=(basic_string&& __str)` 导致的。这样做可以减少不必要的拷贝开销和内存开销。

```cpp
 std::string s = "aaaa";
// 这里会将原先 s 中的值直接转移到 rrs中，并且s被置为空，可以减少不必要的拷贝开销和内存开销
std::string rrs = std::move(s);
cout << s << ", " << rrs << endl; // , aaaa

s = "aaaa";
// 左值转左值引用
std::string &&rrs2 = std::move(s);
// 右值转右值引用
std::string &&rrs3 = std::move("ssss");
cout << s << ", " << rrs2 << ", " << rrs3 << endl; // aaaa, aaaa, ssss


s = "aaaa";
// 左值 s，右值 "aaaa"
// 左值s转为 左值引用
std::string &slr = std::forward<std::string &>(s);
// 左值s转为了 右值引用
std::string &&srr = std::forward<std::string>(s);
// std::string &srr = std::forward<std::string>(s);// 编译报错
cout << slr << ", " << srr << endl; // aaaa, aaaa

// 这里需要注意，这里直接将 s中的值转给了 srr2，并且s被置为空
std::string srr2 = std::forward<std::string>(s);
cout << slr << ", " << srr2 << endl; // , aaaa
```



## 宏（合理使用）

宏定义又称为宏代换、宏替换，简称为 **宏**。

* **发生在预处理阶段**，所以没有任何运行期的效率损失。
  * 预处理器发现此类宏定义时，会将所有的``标识符``替换成``替换字符串``。

  * 替换字符是C语言记号，例如数、字符常量、运算符、标点等。

* **没有作用域概念，全局生效**。对于临时使用的宏可以通过`#undef`取消定义

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
// 定义符号：使用 BEGIN和END 来分别 表示 {}
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

- ``#`` ：表示指定参数转换为字符串。
-  ``##``（记号连接运算符）：会将指定的参数连接起来。

> **注意**：宏名和括号间 不要有空格，例如：`SUM (x, y) (x + y) `。
>
> 此写法将会被识别为 简单的宏替换 ，将 `SUM` 替换为: `(x, y) (x + y)`。

```C++
#include <iostream>

// 带参数的宏定义
// 注意宏民和括号间不要又空格例如：SUM (x, y) (x + y)
// 此写法将会被识别为简单的宏替换，替换为: (x, y) (x + y)
#define SUM(x, y) (x + y)
// # 表示转换s为字符串。
#define TO_STRING(s) #s
// ##（记号连接运算符）：会将x,y 2个参数拼接起来
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

### 类定义

> `= delete` 表示明确地禁用某个函数形式。

```C++
class A final 
{
public:
    A() = default;  // 明确告诉编译器，使用默认实现
   ~A() = default;  // 明确告诉编译器，使用默认实现
    A(const A&) = delete; // 禁止拷贝构造 
    A& operator=(const A&) = delete; // 禁止拷贝赋值
    
    // 定义成员变量 num
    int num = 0;
};
```

### 创建类对象

```c++
int main()
{
    // 显示调用构造函数。由于在函数内部之间创建，所以内存是栈上分配。
    A a = A();
    // 隐式调用了 默认构造函数。 和上面的显示调用相同。
    A aa;

    // 使用 new 创建的是指针，内存分配在堆上。
    A* aaa = new A();

    return 0;
}
```

### 类成员访问

对类的成员变量和函数的访问分两种情况：

* 普通类实例：使用 `.` 访问。

  ```cpp
  int main() {
      A a;
      a.num;
  }
  ```
  
* 类指针类型：使用 `->`访问。

  ```cpp
  int main() {
      A a;
      A *p = &a;
      // 访问
      p->num;
  }
  ```


### 内嵌类(nested class)

C++的内嵌类和Java内部类类似，不过C++需要有一
个显式的成员指向外部类对象，而Java则是有一个隐式的成员指向外部对象。



## 抽象类

**包含一个或多个纯虚函数的类叫做纯虚类，也叫做抽象类**，它只能作为基类，不能实例化。

```cpp
class ITest
{
public:
// 虚函数
virtual void test() 
{
    cout << "test is called" << endl;
}
// 纯虚函数
virtual void getTest()=0;
}
```

### 虚函数

虚函数就是 添加了 `virtual` 修饰词的类成员函数。

虚函数的作用主要是实现了多态的机制，是一种泛型技术，在用父类指针调用函数时，实际调用的是指针指向的实际类型（子类）的成员函数。

它和普通函数的区别主要有以下几点：

* 使用类的指针调用成员函数时：普通函数由指针类型决定，**而虚函数由指针指向的实际类型决定**。

> 纯虚函数：成员函数的形参后面写上=0，它没有函数体，必须在派生类中定义。等同Java中的抽象函数。
>





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



## 泛型

### 模板

C++的模板是泛型编程的一种实现，可以使用 `template` 关键定义模板，实现一套不依赖具体类型的通用代码。

* 函数模板

  ```cpp
  template <typename T>
  T max(T const& a, T const& b) 
  { 
      return a < b ? b:a; 
  } 
  ```

* 类模板：`template<typename INTERFACE>` 和`template <class T>`一般是通用的，仅当 T 是一个类且存在子类时应使用 `typename`。

  ```cpp
  template <class T>
  class Stack { 
    private: 
      vector<T> elems; 
   
    public: 
      void push(T const&);  // 入栈
      void pop();               // 出栈
      bool empty() const{       // 如果为空则返回真。
          return elems.empty(); 
      } 
  }; 
  
  //
  template<typename INTERFACE>
  class BnInterface : public INTERFACE, public BBinder
  {
  public:
      virtual sp<IInterface>      queryLocalInterface(const String16& _descriptor);
      virtual const String16&     getInterfaceDescriptor() const;
      typedef INTERFACE BaseInterface;
  
  protected:
      virtual IBinder*            onAsBinder();
  };
  
  ```

  





## Atomic：原子操作

> C++ 11 增加的一些列原子操作相关的类，这里摘录几个。



* store()：原子写操作。成功返回true。
* load()：原子读操作。成功返回true
* exchange()：交换两个值。成功返回true。
* compare_exchange_weak(expected, desired)：CAS，若当前值满足预期就更新为给定值。即 `if(this == expected)` 则 `this = desired`。weak版比strong版本性能更高，不过Weak版本有时会出现符合条件也返回false的情况。
* compare_exchange_strong(expected, desired)：基本和weak版一样，不过strong更加严谨。





## 其他

### 关键字摘录

| 关键字   |                                                              |                                                  |
| -------- | ------------------------------------------------------------ | ------------------------------------------------ |
| explicit | 指定构造函数或转换函数为显式, 即**不能用于隐式调用或隐式类型转换**. | **隐式调用**：使用赋值操作符`=` 会调用构造函数。 |
|          |                                                              |                                                  |
|          |                                                              |                                                  |

### 符号摘录

| 符号 |                                                      |                                                  |
| ---- | ---------------------------------------------------- | ------------------------------------------------ |
| `::` | 域作用符，可以是命名空间、类、结构体等，调用其成员。 | `std::string`，表示std命名空间下的string类。     |
| `:`  | 在构造函数后表示初始化成员变量。                     | `A::A():a(1)`。构造A的同时赋值成员变量 `a = 1`。 |
| `.`  | 类或结构体的成员运算符                               | `obj.a = 1 `                                     |
| `->` | 指针指向成员的运算符                                 | `p->a = 1`                                       |
| `*`  | **取值运算符**或**间接寻址运算符**。                 |                                                  |



### 性能分析

* top：快速查看进程的CPU、内存使用情况。
* pstack和strace：显示进程在用户空间和内核空间的函数调用情况。
* perf：一定频率采样分析进程，统计各个函数的CPU使用情况。
* gpreftools：基于采样，侵入式（需要编码集成）的性能分析工具，可以生产文本和图形化（例如火焰图）的分析报告。

