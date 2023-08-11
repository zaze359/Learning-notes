# Android之NDK开发

NDK 和 JNI 的关系：

* NDK：Android提供的 C/C++ 的**开发组件工具**。
* JNI：java 调用 C/C++的 **桥接接口**。

两者结合就实现了 在 Android 中 开发并调用 C/C++代码的目的。

## NDK

[ndk-build 脚本  | Android NDK  | Android Developers (google.cn)](https://developer.android.google.cn/ndk/guides/ndk-build?hl=zh-cn)

NDK（Native Development Kit）是 Android 提供的 一个开发工具包。

允许我们使用 C/C++ 来开发工具集，同时NDK 会将 C/C++ 代码编译成 动态库 `so`，也支持将 so 和应用打包成 `apk` 。

## JNI

JNI（Java Native Interface）是指 Java 本地接口，它允许运行在 JVM上的 **Java程序去调用本地代码（C/C++以及汇编）**。

在Android Framework中就大量使用了JNI去调用Native层的代码。

JNI 的使用场景：

* 需要调用成熟的 C/C++ 语言编写的代码库。
* 对性能有较高的要求，所以将这部分功能使用C/C++或者汇编来实现。
* Java层没有对应的API，但是需要平台相关特性的支持。（例如OpenSL ES）。
* 需要更高的安全性，反编译so 比 反编译java更难。

### JNI类型

在阅读源码的过程中会经常涉及 JNI，我们需要先了解下 JNI 中的类型是表述的，以及它们和C/C++、Java 之间对应关系。

| 符号                                   | C/C++     | Java    |      |
| -------------------------------------- | --------- | ------- | ---- |
| V                                      | void      | void    |      |
| I                                      | jint      | int     |      |
| J                                      | jlong     | long    |      |
| F                                      | jfloat    | float   |      |
| D                                      | jdouble   | double  |      |
| Z                                      | jboolean  | boolean |      |
| S                                      | jshort    | short   |      |
| C                                      | jchar     | char    |      |
| B                                      | jbyte     | byte    |      |
| -                                      |           |         |      |
| `[`：表示数组。例如 `[I`表示 int数组   | jintArray | int[]   |      |
| `L`: 表示class类型，后面跟完整的类名。 | jobject   | object  |      |
| `Ljava/lang/String`                    | jstring   | String  |      |

> * class 以 `;` 结尾。
>
> * 包名使用 `/` 分割。
>   * 弱存在内部类，使用 `$` 来作为分隔符。
>
> * 参数都包裹在 `()` 中。
> * 最后的符号表示返回值。例如这里的 `J` 。



### 使用方式

定义  `.java/.kt` 文件

> MyNativeLib.java

```java
package com.zaze.core.nativelib;

public class MyNativeLib {

    public native String test();
}
// 若是 kotlin 则使用 external 关键字修饰函数，它等同于 native
```

定义 C/C++文件

> native-lib.cpp

```cpp

#include <jni.h>
#include <string>

// 方法名时固定格式，Java_包名_类名_函数名(JNIEnv, jobject)
extern "C" JNIEXPORT jstring JNICALL
Java_com_zaze_core_nativelib_MyNativeLib_test(JNIEnv *env, jobject  /* this */) {
    std::string hello = "Hello from C++";
    return env->NewStringUTF(hello.c_str());
}
```

JNI 函数名 是和Java中声明的函数对应的：`Java_包名_类名_函数名()`

JNI函数的 前两个参数 是固定格式，它们的值也是自动填充的。 

* `(JNIEnv* env, jclass clazz)`：表示 静态方法
* `(JNIEnv* env, jobject thiz)`：表示 成员函数。

| 参数    |                                                              |      |
| ------- | ------------------------------------------------------------ | ---- |
| JNIEnv  | 表示 JNI 上下文环境。                                        |      |
| jclass  | 第二个参数若是 jclass类型，则说明是**静态方法**。            |      |
| jobject | 表示 **对象**。若位于第二个参数，则特指方法所属的实例对象自身。 |      |
|         |                                                              |      |

JNIEXPORT、JNICALL 是 JNI 中定义的两个宏

* JNIEXPORT：设置可见性，保证动态库中的函数能够被外部调用。
* JNICALL：定义函数的入栈规则。

### 函数声明方式

#### 静态声明

```cpp
static jlong nativeLockCanvas(JNIEnv* env, jclass clazz, jlong nativeObject, jobject canvasObj, jobject dirtyRectObj)
```

#### 动态注册

使用动态注册时会使用到 `JNINativeMethod` 。

```cpp
typedef struct {
    const char* name; // 方法名
    const char* signature; // 方法签名：参数类型+返回类型
    void*       fnPtr; // 指向调用的方法。
} JNINativeMethod;
```

把上面静态声明改为动态注册是下面这个格式：

```cpp
// 定义一个 nativeLockCanvas JNI函数，它指向 nativeLockCanvas() 这个函数。
// 参数 J: jlong
// 参数 Landroid/graphics/Canvas; : jobject
// 参数 Landroid/graphics/Rect; : jobject
// 返回值J: jlong
static const JNINativeMethod gSurfaceMethods[] = {
	{"nativeLockCanvas", "(JLandroid/graphics/Canvas;Landroid/graphics/Rect;)J", (void*)nativeLockCanvas}
}

// 加载动态库
jint JNI_onLoad(JavaVM* vm, void* reserved) {


    return JNI_VERSION_1_4;
}
```



### 常用函数

#### 字符串转换

```cpp
jstring jStr;
// java 字符串 转 C
// 第二个参数表示是否拷贝，false不拷贝，那么指向同一个地址。
const char *cStr = env->GetStringUTFChars(jStr, 0);

// 释放内存，cStr
env->ReleaseStringUTFChars(jStr, cStr);

```



## CMake

### CMakeLists

[CMakeLists编写简易教程 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/473573789)

#### 共享库配置

```cmake
# 指定 cmake 最小版本。
cmake_minimum_required(VERSION 3.4.1)

# project：定义项目名; 
project(zjvmti-agent)
# poject同时会自动生成两个变量 
# ${PROJECT_SOURCE_DIR}: CMakeLists.txt文件所在目录
# ${PROJECT_NAME} : project名

# 打印信息
messaeg(${PROJECT_NAME})
# -----------------------------------
# set：定义/修改变量
# -----------------------------------
# LIBS_DIR 指向 ../../../libs 目录
set(LIBS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../libs)
# 修改值
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall")
# 添加 c++11支持
set(CMAKE_CXX_FLAGS "-std=c++11")

# 定义bzip2_source_dir 变量 指向 /cpp/bzip2
set(bzip2_source_dir ${CMAKE_CURRENT_SOURCE_DIR}/bzip2)
# 将bzip2目录下的源码赋值给 bzip2_source 变量
set(
        bzip2_source
        ${bzip2_source_dir}/blocksort.c
        ${bzip2_source_dir}/bzip2.c
        #        ${bzip2_source_dir}/bzip2recover.c
        ${bzip2_source_dir}/bzlib.c
        ${bzip2_source_dir}/compress.c
        ${bzip2_source_dir}/crctable.c
        ${bzip2_source_dir}/decompress.c
        #        ${bzip2_source_dir}/dlltest.c
        ${bzip2_source_dir}/huffman.c
        #        ${bzip2_source_dir}/mk251.c
        ${bzip2_source_dir}/randtable.c
        #        ${bzip2_source_dir}/spewG.c
        #        ${bzip2_source_dir}/unzcrash.c
)
# -----------------------------------
# 使可生成文件拥有符号表且可被 gdb调试。
add_definitions("-Wall -g")

# -----------------------------------
# 添加头文件，CMakeLists.txt所在文件夹同级的 include
# 仅对后生成的库生效，一般使用 target_link_libraries 代替
include_directories(
${PROJECT_SOURCE_DIR}/../include
)

# -----------------------------------

# 定义一个变量，指定 库名。
set(LIB_NAME  zjvmti-agent)

# 编译c/cpp 生成库：SHARED 表示动态库，STATIC表示静态库
#add_library(jpeg-turbo
#        SHARED
#        IMPORTED
#        )
add_library(
        zjvmti-agent # 编译后的库名
        SHARED # SHARED 表示动态库，STATIC表示静态库
        native-lib.cpp  # 后面都是，参与编译的源文件
        bitmap-compress-lib.cpp
        )
# -----------------------------------
# 搜索 '.' 当前目录下所有c/cpp文件，并赋值给 SRC_LIST
aux_source_directory(. SRC_LIST)
# add_library(native-lib ${SRC_LIST})


# 添加头文件，代码提示
target_include_directories(
        zjvmti-agent PRIVATE
        ${LIBS_DIR}/include
)

# 查找 log 预编译库，并将路径保存在 log-lib变量中
# 默认路径是 cmake 包含的系统库
find_library(
        log-lib # 变量
        log # 预编译库名
        )
        
# -----------------------------------
# 链接库文件
# 将 zjvmti-agent 和所需要的其他库链接起来。
# 链接so文件：-l${libname}，不需要前缀lib和后缀so
# 链接后才能找到 符号引用
target_link_libraries( 
        zjvmti-agent # 目标库
        jnigraphics # AndroidBitmap
        ${log-lib})
```

#### 可执行文件

```cmake
# ... 和上述一样的基本配置
# -----------------------------------
# 生成可执行文件
# -----------------------------------
# 设置可执行文件输出路径，CMakeList所在文件夹下的bin目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/bin)
# 生成可执行文件：${bzip2_source} 为源码
add_executable(${PROJECT_NAME} ${bzip2_source})

# 为可执行文件添加链接库
target_link_libraries(${PROJECT_NAME} ${log-lib})
```

#### 混合编译配置

```cmake
# 指定c c++混合编译，若只写一个则只会使用指定语言编译
project(zjvmti-agent CXX C)
# 配置 c c++ 编译选项
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c99")
# c++11 ： C++11标准
# -fno-rtti 禁用运行时类型信息
# -fno-exceptions 禁用异常机制
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -fno-rtti -fno-exceptions -Wall")

# -----------------------------------
# 编译子目录的 CMakeLists.txt
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/libxhook)
```

> 若存在 c++ 调用 c 编写的a/so库时出现 `1` 错误，此时头文件处需要添加 `extern "C"`。
>
> ```cpp
> extern "C" {
> #include "./bsdiff/bspatch.h"
> #include "./bsdiff/bsdiff.h"
> }
> ```

#### 配置输出路径

```cmake
# 设置动态库的输出路径：生成在当前项目的lib下面,按照cpu架构分开
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/lib/${CMAKE_ANDROID_ARCH_ABI})
# 静态库
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/lib2/${CMAKE_ANDROID_ARCH_ABI})
# 可执行文件输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/lib3/${CMAKE_ANDROID_ARCH_ABI})
```





### CMake编译指令

```shell
# 编译其他会产生很多其他文件，建议单独创建一个 build目录。
cd build

# cmakelists.txt 在上一级目录
# windows 默认生成vs的编译文件，需要使用vs打开生成可执行文件
cmake ..
# 这里指定编译器,需要按照 MinGW-w64
cmake .. -G "MinGW Makefiles"

cmake [cmakelists.txt]


make
```

### 动态库/静态库/可执行

```shell
# 查看静态库文件内容
ar -t *.a
# 查看符号表
nm *.a

# linux
# 查看静态库定义的函数
readelf -c xx.a 
# 查看动态库定义的函数
readelf -A xx.so
```

```shell
# 可执行文件 ELF
# 查看ELF文件所有信息
readelf -a <file>
# ELF 头信息
readelf -h <file>
# 查看ELF文件section信息：
readelf -S <file>
# 查看ELF文件符号表：
readelf -s <file>
# Program Header Table信息
readelf -l <file>

# 查看library的依赖
readelf -d <library> | grep NEEDED
```

## Native 调试

项目中有源码自己编译的，直接使用 Android Studio 断点即可。

无源码场景
