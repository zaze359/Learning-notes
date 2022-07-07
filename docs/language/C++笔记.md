# C++笔记

## 1. 使用GCC编译

```shell
gcc a.cpp -o a
```

## 2. .h文件和.cpp文件

| 文件类型 | 定义      | 内容      | 作用           |
| -------- | --------- | --------- | -------------- |
| .cpp     | C++源文件 | C++源代码 | 定义，具体实现 |
| .h       | C++头文件 | C++源代码 | 声明           |
|          |           |           |                |

思考为什么会存在2个文件：

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



## 3. 宏

宏定义又称为宏代换、宏替换，简称为``宏``

### 3.1 简单的宏

格式：``#define 标识符 替换字符串``

预处理器发现此类宏定义时，会将所有的``标识符``替换成``替换字符串``。

替换字符是C语言记号，例如数、字符常量、运算符、标点等。

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

### 3.2 带参数的宏

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