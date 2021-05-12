# Launcher开发笔记

Tags: zazen android

---

[TOC]

---

##  0. 待研究问题

```
InvariantDeviceProfile.java
invDistWeightedInterpolate()的算法？
```

------

## 1. 简介

- 写着玩, 试验新的学的知识, 可能会出现一些千奇百怪的东西
- 顺便学习google Launcher3
- 命名尽量和Launcher3保持一致（略有修改）

### 1.1 项目地址

> [GitHub](https://github.com/zaze359/GBCLauncher.git)

### 1.2 参考资料

> [Google Git](https://android.googlesource.com/platform/packages/apps/Launcher3/)

### 1.3 环境

Android 4.1.3(16)及以上

### 1.4 目标

#### 1.4.1 阶段一

生搬硬套Google Launcher3源码，逐个功能理解、拷贝、微调(加入一些自己的理解), 梳理知识点

#### 1.4.2 阶段二

根据自己的理解完全重构Launcher3

#### 1.4.3 阶段三

根据自己的想法添加功能

------

## 2. 项目分析

> 应用整体框架 MVVM + Databind + Room

### 2.1 项目结构

- 界面结构

<img src="http://static.zybuluo.com/zaze/u0taljl9wno2wj827gljx5b4/launcher3%E7%95%8C%E9%9D%A2%E7%BB%93%E6%9E%84.png" style="zoom:50%;" />

### 2.2 项目知识点

|知识点|说明|
| :-- | :-- |
|MVVM|
|Databind||
|RxJava||
|Kotlin|考虑是否使用？|
|Room?GreenDao?原生？||
|EventBus||
|Android 四大组件||
|Android 动画|属性动画等|
|自定义控件|自定义view，事件分发等|
|AppWidget|AppWidgetHost，AppWidgetProviderd等|

### 2.3 代码解析

### 2.4 重要的模块和类

|模块|类名|说明|
| :-- | :-- | :-- |
||LauncherActivity|主页面|
||CellLayout|自定义的细胞布局|
||WorkSpace|工作区|
||HotSeat|热键|

### 2.5 workspace加载
加载数据并且将数据在主线程中绑定到实际视图上
```
Google Launcher3 源码: 
LauncherModel.LoaderTask.loadAndBindWorkspace(){
    if (!mWorkspaceLoaded) {
        // 若数据未加载则加载数据
        loadWorkspace();
        synchronized (LoaderTask.this) {
            if (mStopped) {
                // 整个task已停止则退出
                return;
            }
            mWorkspaceLoaded = true;
        }
    }
    // Bind the workspace
    // 数据在主线程中绑定到实际视图上
    bindWorkspace(-1);
}

/**
 * 首先加载所有当前页的item(在调用startBinding()之前,解绑所有已存在的items )
 **/
private void bindWorkspace(...) {
    // 解绑
    unbindWorkspaceItemsOnMainThread();
    ....
    // 过滤
    filterCurrentWorkspaceItems();
    filterCurrentAppWidgets();
    filterCurrentFolders();
    // 排序
    sortWorkspaceItemsSpatially(currentWorkspaceItems);
    sortWorkspaceItemsSpatially(otherWorkspaceItems);
    // 绑定
    bindWorkspaceScreens();
    // 绑定当前页
    bindWorkspaceItems();
    // 绑定剩余的其他页
    bindWorkspaceItems();
}

```

## 3 重要的配置
- 在xml中配置

> * 默认workspace的一些配置
``default_workspace_xxx.xml``

```
- 当空数据库创建时，保存状态
- onCreate 中根据状态处理
- 若是空数据库创建则将默认数据写入数据库
```


## 4. 分析






------
作者 : [口戛口崩月危.Z][author]

[author]: https://zaze359.github.io
[2.1.img-1]: http://static.zybuluo.com/zaze/u0taljl9wno2wj827gljx5b4/launcher3%E7%95%8C%E9%9D%A2%E7%BB%93%E6%9E%84.png

  
