---
title: Android逆向工程
date: 2020-04-16 13:43
---
Tags： zaze android cmd

[TOC]

# Android逆向工程
---
## 1. 资源文档

> [Google Source](https://android.googlesource.com/ )
>
> [下载源代码  | Android 开源项目  | Android Open Source Project](https://source.android.com/setup/downloading)
>
> [编译准备工作  | Android 开源项目  | Android Open Source Project (google.cn)](https://source.android.google.cn/setup/building)
>
> [清华大学开源软件镜像站](https://mirror.tuna.tsinghua.edu.cn/help/AOSP/)
>
> [Nexus 6P镜像](repo%20init%20-u%20https://android.googlesource.com/platform/manifest%20-b%20android-8.0.0_r17 )



## 2. [源码下载及编译](../aosp/AOSP下载及编译)

## 3. 问题处理

问题1

```
[  1% 1563/81559] Lex: checkpolicy <= external/selinux/checkpolicy/policy_scan.l
FAILED: out/host/linux-x86/obj/EXECUTABLES/checkpolicy_intermediates/policy_scan.c 
/bin/bash -c "prebuilts/misc/linux-x86/flex/flex-2.5.39 -oout/host/linux-x86/obj/EXECUTABLES/checkpolicy_intermediates/policy_scan.c external/selinux/checkpolicy/policy_scan.l"
flex-2.5.39: loadlocale.c:130:_nl_intern_locale_data: ?? 'cnt < (sizeof (_nl_value_type_LC_TIME) / sizeof (_nl_value_type_LC_TIME[0]))' ???
Aborted (core dumped)
[  1% 1566/81559] target  C++: nvram_hal_test <= system/nvram/hal/tests/nvram_hal_test.cc
ninja: build stopped: subcommand failed.
08:36:31 ninja failed with: exit status 1
build/core/main.mk:21: recipe for target 'run_soong_ui' failed
make: *** [run_soong_ui] Error 1
```
```
Fix : export LC_ALL=C
```

## 4. 模拟器

模拟器连接

```
查询进程号
lsof -i |grep pid
adb connect 127.0.0.1:xxxx
```

```
adb kill-server
adb start-server
adb -s <serial number> shell
adb nodaemon server 查看adb
```

可读写运行模拟器

```
显示模拟器列表
emulator -list-avds
打开队员模拟器
emulator -avd Pixel_2_API_29 -writable-system
```

```
adb root
adb remount
```

发生错误

```
PANIC: Missing emulator engine program for 'x86' CPU.

默认使用../Android/sdk/tools/下的emulator 脚本
使用../Android/sdk/emulator/下的emulator 脚本
```


----------


## 6. 反编译Apk文件

### 6.1. 下载apktool

[下载地址][apktool]

> windows 将解压路径添加到PATH环境变量中


### 6.2. java文件编译和反编译
```
public class Hello {
	public int foo(int a, int b) {
		return (a + b) * (a - b);
	}

	public static void main(String[] argc) {
		Hello hello = new Hello();
		System.out.println(hello.foo(5, 3));
	}
}
```

编译成.class文件

```
javac Hello.java
```

反编译.class

```
javap Hello.class

Compiled from "Hello.java"
public class Hello {
  public Hello();
  public int foo(int, int);
  public static void main(java.lang.String[]);
}
```
```
javap -c -classpath . Hello

Compiled from "Hello.java"
public class Hello {
  public Hello();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: return

  public int foo(int, int);
    Code:
       0: iload_1
       1: iload_2
       2: iadd
       3: iload_1
       4: iload_2
       5: isub
       6: imul
       7: ireturn

  public static void main(java.lang.String[]);
    Code:
       0: new           #2                  // class Hello
       3: dup
       4: invokespecial #3                  // Method "<init>":()V
       7: astore_1
       8: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
      11: aload_1
      12: iconst_5
      13: iconst_3
      14: invokevirtual #5                  // Method foo:(II)I
      17: invokevirtual #6                  // Method java/io/PrintStream.println:(I)V
      20: return
}
```

### 6.3. dex文件生成和反汇编

.class生产dex文件

```
../Android/Sdk/build-tools/28.0.2/dx --dex --output=Hello.dex Hello.class
```

查看dex文件

```
../Android/Sdk/build-tools/28.0.2/dexdump.exe -d Hello.dex
```

BakSmali反汇编dex

```
java -jar baksmali.jar -o baksmaliout  Hello.dex
java -jar baksmali.jar -x classes.odex -d framework
```


```
java -jar ddx.jar -d ddxut Hello.dex
```

### 6.4. 反编译apk命令

加载框架

```
版本过旧时会导致打包加载资源等失败
从平板的/system/framework中获取
apktool if framework-res.apk
```

**decode** : 该命令用于进行反编译apk文件

```
apktool d <file.apk> -f -o <dir>

apktool d demo.apk -o outdir
```

反编译目录说明

|目录|说明|备注|
|:--|:--|:--|
|res|资源文件|提示信息往往是关键代码的风向标|
|res\values\public.xml|索引值|相当于R.java|
|smali|程序所有的反汇编代码||
|AndroidManifest.xml|||
|apktool.yml|||

**smali转dex**

```
java -jar ~/Documents/break/smali_baksmali/smali-2.1.3.jar outDir -o classes.dex
```

**dex2jar**

```
d2j-dex2jar classes.dex
```

编译修改好的文件

```
build:该命令用于编译修改好的文件，一般用法为: 
apktool b <dir>
```

### 6.5. 签名

[APK手动签名参考文档](../publish/APK手动签名参考.md)

**install-framework**

```
该命令用于为APKTool安装特定的framework-res.apk文件，以方便进行反编译一些与ROM相互依赖的APK文件。具体情况请看常见问题
```

**aapt**

```
/Users/zaze/Library/Android/sdk/build-tools/21.1.1/aapt
aapt l -a xx.apk > demo.txt
```
**AXMLPrinter2**

```
java -jar AXMLPrinter2.jar AndroidManifest.xml > AndroidManifest.txt
```


------------

## 7. Android可执行文件

### 7.1 Android 程序生成步骤

![image_1dr2t0g351rs61vloir31f4tl509.png-133.1kB][4]



[apktool]: https://ibotpeaches.github.io/Apktool/


[1]: https://android.googlesource.com/
[2]: repo%20init%20-u%20https://android.googlesource.com/platform/manifest%20-b%20android-8.0.0_r17
[3]: https://source.android.google.cn/setup/building
[4]: http://static.zybuluo.com/zaze/3kv7jpews93qo233fo5rchbd/image_1dr2t0g351rs61vloir31f4tl509.png