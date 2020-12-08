# Launcher3源码分析

[TOC]

## 项目信息

* [Google官方](https://android.googlesource.com/platform/packages/apps/Launcher3/)
* 最小sdk版本为16
* Android 5.0 版本及以上可能会出现因为相同权限声明而不能安装的问题
* 如果你想要可以在Eclipse编译的版本，可以看这个tag: GOODBYE_ECLIPSE


---
## 参考资料

* [Android的触摸控制流程](http://www.fookwood.com/archives/806)
* [Launcher3界面的布局和结构](http://www.fookwood.com/archives/846)
* [Launcher3中的常用类](http://www.fookwood.com/archives/854)
* [Launcher3的启动流程（一）](http://www.fookwood.com/archives/863)
* [细说ItemInfo](http://www.fookwood.com/archives/875)
* [Launcher3的启动流程（二）](http://www.fookwood.com/archives/894)
* [Launcher3分析之拖动图标的流程——按下](http://www.fookwood.com/archives/925)
* [Launcher3分析之拖动图标的流程——移动](http://www.fookwood.com/archives/940)
* [Launcher3分析之拖动图标的流程——放下](http://www.fookwood.com/archives/946)
* [PagedView的原理 – 滑动](http://www.fookwood.com/archives/955)
* [如何给Launcher3添加左屏](http://www.fookwood.com/archives/1048)
* [IconCache原理](http://www.fookwood.com/archives/1072)
* [找个Launcher开发](http://www.fookwood.com/archives/1066)
* [LauncherRootView和DragLayer的布局过程](http://www.fookwood.com/archives/1085)

## Launcher3项目结构

挑选Launcher3整个项目中几个重要的类进行分析,了解项目的整体结构。

| 类名             | 说明         |
| :--------------- | :----------- |
| LauncherActivity | 主页面       |
| CellLayout       | 自定义的布局 |
| WorkSpace        | 工作区       |
| HotSeat          | 热键         |



