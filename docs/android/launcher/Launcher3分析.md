# Launcher3分析

[TOC]

## 项目下载

* [Google官方](https://android.googlesource.com/platform/packages/apps/Launcher3/)
* [GitHub](https://github.com/zaze359/Launcher3)



## Launcher3项目结构



​	Launcher3其实就是一个Activity,  整体的结构如下图, 项目的入口为**Launcher.java**。布局文件为

**res/layout/launcher.xml**。

​	最外层为**LauncherRootView**, 是一个FrameLayout, 内部包含一个childView: **DragLayer**, DragLayer内部就是我们在手机上能看到界面,主要为**Workspace**, **WorkspacePageIndicator**,**Hotseat**, **DropTargetBar**等。

​	**Workspace**就是屏幕中可以滑动的部分, 继承自自定义的**PagedView**, 内部有一个重要的childView: **CellLayout**, 其中装的就是一个个我们看到的应用图标和小组件。

​	**WorkspacePageIndicator**，是Workspace的指示器, 主要表示总共有几屏，当前是第几屏。

​	**hotseat(Hotseat)** , 在屏幕的最底部,主要放置一些比较常用的应用图标，例如短信、相机、浏览器等。

​	**drop_target_bar(DropTargetBar)**,  当我们在拖拽图标时顶部显示卸载、删除的区域。

​	**scrim_view(ScrimView)**，.....

​	**overview_panel(Space)**,.....

​	**apps_view(AllAppsContainerView)**，这个页面就是Launcher3中上滑时看到的页面，展示了所有的应用图标，并且顶部悬浮了一个搜索框。

<img src="assets/Launcher3.png" alt="Launcher3" style="zoom: 25%;" />

<img src="assets/Launcherxml布局分析.png" alt="Launcherxml布局分析" style="zoom:50%;" />





挑选Launcher3整个项目中几个重要的类进行分析,了解项目的整体结构。

| 类名                     | 说明               |
| :----------------------- | :----------------- |
| Launcher                 | 主页面             |
| CellLayout               | 自定义的布局       |
| WorkSpace                | 工作区             |
| HotSeat                  | 热键               |
| WidgetsFullSheet         | 组件展示页         |
| RecyclerViewFastScroller | 小组件的侧边滚动条 |



