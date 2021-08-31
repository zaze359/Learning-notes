# Launcher3之启动流程

[TOC]

## 流程概述

Launcher3的入口为**Launcher.class**, 这个类是一个Activity，直接从**onCreate()**方法开始分析。

![image-20201224165242285](assets/Launcher初始化流程.png)

onCreate()在被调用时并没有直接调用setContentView(), 而是先进行了一些初始化配置, 主要步骤如下:

 1. 通过**LauncherAppState.getInstance(this)**初始化了一些全局到配置、注册广播、监听配置变化和通知角标变化等

    mInvariantDeviceProfile:InvariantDeviceProfile: 这里面是Launcher布局在不同设备中的布局配置，比如iconSize, 显示几行几列等。

    - mIconCache:IconCache: 应用图标缓存。
    - mWidgetCache:WidgetPreviewLoader: 
    - mModel:LauncherModel: 主要负责数据层相关逻辑，并且通过**mCallbacks:LauncherModel.Callbacks**来进行数据回调通知，Launcher.java实现了这个接口, 由LauncherAppState.setLauncher()方法(内部调用了LauncherModel.initialize())对mCallbacks进行赋值。
    - 通过LauncherAppsCompat监听应用的变更情况。
    - 注册BroadcastReceiver: 位置变更、配置变更等。
    - 监听notification badging。

 2. 调用mModel.initialize(launcher)向LauncherModel中**设置数据监听回调**

 3. **成员变量初始化**(mDragController, mAppWidgetManager等)

 4. 调用**setupViews()**对view进行了初始化以及同一些Controller建立了关联和设置了一些事件监听

 5. 最后调用**mModel.startLoader()**进行数据加载。

上述步骤结束后才调用了setContentView()，之后又注册了一些广播监听()

