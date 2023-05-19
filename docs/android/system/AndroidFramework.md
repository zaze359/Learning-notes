---

layout: post
title:  "AndroidFramework总纲"
date:   2018-04-17
categories: android

---

Tags : zaze android

[TOC]




---

# AndroidFramework总纲

## 参考资料

部分图片和说明出自以下书籍

> **<< Android的设计和实现:卷I>>**
> **<<深入理解Android: 卷I>>**


## Android 系统架构

❑ **Linux 内核层**：包含了 Linux 内核和一些驱动模块（比如 USB 驱动、 Camera 驱动、蓝牙驱动等）
❑ **Libraries 层**：这一层提供动态库（也叫共享库）、 Android 运行时库、 Dalvik 虚拟机等。从编程语言角度来
说，这一层大部分都是用 C 或 C++ 写的，所以也可以简单地把它看成是 Native 层。
❑ **Framework 层**：这一层大部分用 Java 语言编写，它是 Android 平台上 Java 世界的基石。
❑ **Applications 层**：与用户直接交互的就是这些应用程序，它们都是用 Java 开发的

![Android 系统架构图][img_1_Android 系统架构图]

## 启动篇

## Binder篇

## 消息通信篇

## Package Manager篇

## Activity Manager篇




------
苦工 : [口戛口崩月危.Z][author]

[author]: https://zaze359.github.io
[img_1_Android 系统架构图]:http://static.zybuluo.com/zaze/pexn0x9kdfj7afw4mqljnhhc/image_1c9bktt8u2h8pepojn1t966uo9.png
[link_1_深入理解Android]:https://baike.baidu.com/item/%E6%B7%B1%E5%85%A5%E7%90%86%E8%A7%A3Android/3333024?fr=aladdin