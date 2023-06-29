# Android之JNI框架的使用

JNI（Java Native Interface）是Android提供的一种编程框架，它允许运行在JVM上的Java程序去调用本地代码（C/C++以及汇编）。

在Android Framework中就大量使用了JNI去调用Native层的代码。

## 使用场景

* 调用成熟的 C/C++语言编写的代码库。
* 对性能有较高的要求，所以将这部分功能使用C/C++或者汇编来实现。
* Java层没有对应的API，但是需要平台相关特性的支持。（例如OpenSL ES）。

## 使用方式

### Java层调用Native层





## NDK脚本

[ndk-build 脚本  | Android NDK  | Android Developers (google.cn)](https://developer.android.google.cn/ndk/guides/ndk-build?hl=zh-cn)
