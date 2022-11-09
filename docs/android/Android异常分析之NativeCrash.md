# Android异常分析之NativeCrash

[TOC]



## NativeCrash产生的原因

native崩溃可能是由于访问了非法地址、地址对齐出现问题、程序主动abort等，产生了相应的signal信号，导致程序异常退出。

而native crash往往错误信息模糊，上下文不全且又难以捕捉处理。

| 现有方案           |                           |                                                          |
| ------------------ | ------------------------- | -------------------------------------------------------- |
| Google 的 breakpad | 跨平台、权威、成熟        | 代码体量大                                               |
| 利用logcat日志     | Android系统自带机制，简单 | 不可靠，需要在发生崩溃时启动新的进程采集过滤logcat日志。 |
| coffeecatch        | 实现简洁，改动简单        | 存在一定的兼容性问题                                     |

|       |      |      |
| ----- | ---- | ---- |
| Bugly |      |      |
|       |      |      |
|       |      |      |



## 信号机制

- 信号机制是**进程之间相互传递消息的一种方法**，信号全称为软中断信号。
- linux把这些中断处理，统一为**信号量**，可以**注册信号量向量进行处理**。
- 在Unix-like系统中，所有的崩溃都是编程错误或者硬件错误相关的，系统遇到不可恢复的错误时会触发崩溃机制让程序退出，如除零、段地址错误等。**异常发生时，CPU通过异常中断的方式，触发异常处理流程。**不同的处理器，有不同的异常中断类型和中断处理方式。

函数运行在用户态，当遇到**系统调用**、**中断**或是**异常**时，程序会进入内核态。

![图片](./Android%E5%BC%82%E5%B8%B8%E5%88%86%E6%9E%90%E4%B9%8BNativeCrash.assets/640.jpeg)



1. 信号的接收

   内核接收信号后，将信号**放入到对应进程的信号队列**中，同时**发送一个中断**, 使进程陷入到内核态（此时信号在队列中还未处理）。

2. 信号的检测

   * 进程从**内核态返回用户态时**。
   * 进程在内核态中，从睡眠到**被唤醒时**。

3. 信号的处理

   当发现有新信号时，内核会将当前内核栈中的**内容拷贝到用户栈**上，并**修改指令寄存器（eip）**将其指向信号处理函数。接着进程**返回用户态中，执行相应的信号处理行函数**。处理完成后返回内核态，检查是否还有其他信号未处理。若处理完毕，则**将内核栈恢复**（从用户栈拷贝回来），同时**恢复eip**, 将其指向中断前的运行位置，最后**返回用户态**继续执行。

4. 常见信号量类型

   [siginfo_t -- data structure containing signal information (mkssoftware.com)](https://www.mkssoftware.com/docs/man5/siginfo_t.5.asp)

   ![图片](./Android%E5%BC%82%E5%B8%B8%E5%88%86%E6%9E%90%E4%B9%8BNativeCrash.assets/640-1666342734742-3.jpeg)

## 崩溃捕获解析流程

### 编译端

编译C/C++代码时，需要将带符号信息的文件保留下来。

### 客户端

捕获崩溃后尽可能多的收集有用信息写入日志，选择合适的时机上传服务端。

#### 注册信号处理函数

#### 设置额外栈空间

如SIGSEGV很有可能时栈溢出引起的，此时如果在默认的栈上运行可能会破坏程序的运行线程，同时再一次触发相同的信号。

#### 兼容其他signal处理

某些信号可能在我们注册之前已被安装过信号处理函数，为了防止我们的处理函数覆盖原先的处理，需要保存旧的处理函数，等我们的信号处理函数处理完成后，再重新运行旧的处理函数。

### 服务端

读取客户端上报的日志文件，寻找合适的符号文件，生成可读的C/C++调用栈。



相对偏移地址 = pc值 - 加载到内存的起始地址

pc值：程序加载到内存中的绝对地址。

`/proc/self/maps`：记录了各个模块在内存中的地址范围



![img](./Android%E5%BC%82%E5%B8%B8%E5%88%86%E6%9E%90%E4%B9%8BNativeCrash.assets/95d9733860e3a52c6c3b5976ca25b711.jpg)



## BreakPad

> Breakpad is a set of client and server components which implement a crash-reporting system.
>
> Breakpad 是一套实现崩溃报告系统的客户端和服务端组件，是工具集。 

组件：

- **client：用于客户端集成。**以library的形式内置在应用中，当崩溃发生时生成 minidump文件。
- **symbol dumper：负责用于生成符号表。**读取由编译器生成的调试信息（debugging information），并生成 symbol file。
- **processor：负责将minidump解析为stack trace。**读取minidump文件 和 symbol file，生成可读的stack trace。

### breakpad源码编译

> Linux环境下执行

[google/breakpad源码下载](https://github.com/google/breakpad)

```shell
git clone https://github.com/google/breakpad.git
```

下载`linux-syscall-support`三方库, `linux_syscall_support.h`放到Breakpad 源码目录 `src/third_party/lss/`下，没有lss则新建一个。

```shell
# lss（linux-syscall-support）
git clone https://chromium.googlesource.com/linux-syscall-support
```

编译

```shell
cd src
# Build the source.
./configure && make
# Optionally, run tests.
make check
# Optionally, install the built libraries
# 安装我们需要的工具：minidump_stackwalk、dump_syms, 安装完成后可在shell中直接使用。
sudo make install
```

### 客户端项目集成breakpad

> 选择对应客户端需要的文件，例如Android底层为linux：选择`src/client/linux/libbreakpad_client.a`。

* 拷贝breakpad 目录下的 src 目录，去除`client`下非当前平台的代码

* 设置 include paths

  ```cmake
  # breakpad
  include_directories(external/libbreakpad/src external/libbreakpad/src/common/android/include)
  add_subdirectory(external/libbreakpad)
  list(APPEND LINK_LIBRARIES breakpad)
  
  add_library(breakpad-core SHARED
          breakpad.cpp)
  target_link_libraries(breakpad-core ${LINK_LIBRARIES}
          log)
  ```

  

```c++
#include "client/linux/handler/exception_handler.h"

// 写完minidump后的回调函数
// 回调中做尽可能少的事，或者开启一个新进程处理。
// breakpad自己实现的libc中的一些方法，处理整个堆的内存都耗尽的场景，避免直接调用libc
bool DumpCallback(const google_breakpad::MinidumpDescriptor &descriptor,
                  void *context,
                  bool succeeded) {
    ALOGD("===============crrrrash================");
    ALOGD("Dump path: %s\n", descriptor.path());
    return succeeded;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_sample_breakpad_BreakpadInit_initBreakpadNative(JNIEnv *env, jclass type, jstring path_) {
    const char *path = env->GetStringUTFChars(path_, 0);
	// 初始化ExceptionHandler, 
    // path 指定minidump文件写入到的目录
    google_breakpad::MinidumpDescriptor descriptor(path);
    static google_breakpad::ExceptionHandler eh(descriptor, NULL, DumpCallback, NULL, true, -1);

    env->ReleaseStringUTFChars(path_, path);
}
```



### 生成Stack Trace

> `D:\Android Studio\plugins\android-ndk\resources\lldb\bin`下的`minidump_stackwalk`。
>
> 使用源码编译的`minidump_stackwalk`，`dump_sy`。在`breakpad/src/processor`中。

#### 使用dump_syms生成symbol files

`/app/build/intermediates/cmake/debug/obj`下选择对应架构的文件，拷贝到linux中。

![image-20221021214022481](./Android%E5%BC%82%E5%B8%B8%E5%88%86%E6%9E%90%E4%B9%8BNativeCrash.assets/image-20221021214022481.png)



```shell
dump_syms libcrash-lib.so > libcrash-lib.so.sym
```

#### 建立symbol files目录结构

使用文本编辑器打开`libcrash-lib.so.sym`符号表，找到类似以下格式位置：

```tex
MODULE Linux arm64 1C6899E234B5F47158EC00BF4D4105F10 libcrash-lib.so
```

新建目录`Symbol/libcrash-lib.so/1C6899E234B5F47158EC00BF4D4105F10/`，并将 `libcrash-lib.so.sym` 文件复制到该文件夹中。

#### 使用minidump_stackwalk解析minidump文件

> `xxx.dmp`文件为客户端生成的minidump文件。

```shell
# 无符号表
minidump_stackwalk crashDump/fab01027-b33a-4423-36999b87-c7cf3310.dmp > crashLog.txt
# 使用对应符号表生成可读的stack trace
minidump_stackwalk crashDump/fab01027-b33a-4423-36999b87-c7cf3310.dmp ./Symbol > dump.txt 
```

对比两份日志，使用符号表后，原因的内存地址变成了可读的代码位置。

![image-20221021230206344](./Android%E5%BC%82%E5%B8%B8%E5%88%86%E6%9E%90%E4%B9%8BNativeCrash.assets/image-20221021230206344.png)

> 也可使用`aadr2line`工具将无符号日志中的地址转位代码位置：

```shell
D:\ndk\android-ndk-r16b\toolchains\aarch64-linux-android-4.9\prebuilt\windows-x86_64\bin\aarch64-linux-android-addr2line -C -f -e .\libcrash-lib.so 0x5e0
```







### 问题记录

make未安装：

```tex
config.status: error: Something went wrong bootstrapping makefile fragments
    for automatic dependency tracking.  If GNU make was not used, consider
    re-running the configure script with MAKE="gmake" (or whatever is
    necessary).  You can also try re-running configure with the
    '--disable-dependency-tracking' option to at least be able to build
    the package (albeit without support for automatic dependency tracking).
See `config.log' for more details
```

```shell
# 检测是否安装了make
sudo apt install make
```

linux_syscall_support：

```
In file included from ./src/client/linux/dump_writer_common/thread_info.h:36,
                 from ./src/client/linux/minidump_writer/linux_dumper.h:53,
                 from ./src/client/linux/minidump_writer/minidump_writer.h:41,
                 from src/tools/linux/core2md/core2md.cc:33:
./src/common/memory_allocator.h:49:10: fatal error: third_party/lss/linux_syscall_support.h: 没有那个文件或目录
```

将之前下载的`linux_syscall_support`中的`linux_syscall_support.h`放到`third_party/lss/`下。



## 分析工具

### objdump

查看编译后的文件的组成。

1. 查找objdump文件位置

```shell
find ~/Library/Android/sdk/ndk -name "*objdump"
```

2. 指令介绍

```shell
# 查看所以指令
--help
# 显示输出汇编内容
arm-linux-androideabi/bin/objdump -d libA.so > libA.txt
```

### addr2line

将指令的地址和可执行映像转换成文件名、函数名和源代码行数的工具。
适用于debug版本或带有symbol信息的库。

1. 查找addr2line文件位置

```shell
find ~/Library/Android/sdk/ndk -name "arm-linux-androideabi-addr2line"
# 64位动态库
find ~/Library/Android/sdk/ndk -name "aarch64-linux-android-addr2line"
```

2. 指令介绍

```bash
# 查看所以指令
--help
# 解析还原崩溃信息
# -C -f  错误行数所在的函数名称
# -e  错误地址的对应路径及行数
arm-linux-androideabi-addr2line -C -f -e libA.so 00001111
# 64位
aarch64-linux-android-addr2line  -C -f -e libA.so 00001111
```



## 参考资料

[Android 平台 Native 代码的崩溃捕获机制及实现 (qq.com)](https://mp.weixin.qq.com/s/g-WzYF3wWAljok1XjPoo7w)

[breakpad文档 - Git at Google (googlesource.com)](https://chromium.googlesource.com/breakpad/breakpad/+/master/docs/)

[Google Breakpad 学习笔记 - 简书 (jianshu.com)](https://www.jianshu.com/p/295ebf42b05b)
