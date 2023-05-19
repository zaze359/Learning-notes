# C语言基础

## 指针

* 使用`*`定义一个指针变量，它指向的是 变量的地址。赋值时需要使用 `&` 取址运算符来获取变量的地址。

* 指针变量需要通过 `*` 来取值，所以 `*`也叫做**取值运算符**或**间接寻址运算符**。(像a变量，直接访问就能获取到值，就是直接寻址)

### 指针和数组

我们能够使用数组表示法来引用指针，同时也能用指针表示法来引用数组元素。
```c
typedef unsigned char *byte_pointer;
void show_bytes(byte_pointer start, size_t len) {
    size_t i;
    for(i = 0; i < len; i++) {
        // start[i] 表示想要读取以start指向的位置为起始的第i个位置处的字节。
        printf(" %.2x", start[i]);
    }
    printf("\n");
}
```


## typedef数据类型命名

一种给数据类型命名的方式。

```c
// int_pointer 定义为一个指向int的指针。
typedef int *int_pointer;
// 声明了一个int指针类型的变量ip
int_pointer ip;
```
等效于：
```c
int *ip;
```

## printf格式化输出
以``%``开头的字符序列表示如何格式化下一个参数。

|符号|说明|
|--|--|
|%d|十进制整数|
|%f|浮点数|
|%c|字符|
|||



### `__attribute__`机制

`__attribute__` 是个编译器指令，编译器描述特殊的标识、错误检查或高级优化。

它可以设置函数属性（Function Attribute ）、变量属性（Variable Attribute ）和类型属性（Type Attribute ）等。

格式：

```cpp
// 禁用 内存检测
__attribute__((no_sanitize("memory")))
```

| 属性        |                                                  |      |
| ----------- | ------------------------------------------------ | ---- |
| noreturn    | 告诉编译器该函数没有返回值                       |      |
| format      | 告知编译器检查传给相应函数的参数中的格式字符串。 |      |
| no_sanitize | 禁用某些功能的检测。                             |      |
|             |                                                  |      |

