# Launcher开发笔记

- 学习google Launcher3
- 使用 MVVM + databind 架构逐步重构Launcher3(MVC)
- 命名尽量和Launcher3保持一致（略有修改）

## 简介

### 环境

Android 4.1.3(16)及以上

### 涉及到的知识点

|知识点|说明|
| :-- | :-- |
|MVVM|
|Databind||
|RxJava||
|Kotlin|考虑是否使用？|
|EventBus||
|Room?GreenDao?原生？||
|Android 四大组件|Activity、Service、ContentProvider、BroadcastReceiver|
|Android 动画|属性动画等|
|自定义控件|自定义view，事件分发等|
|AppWidget|AppWidgetHost，AppWidgetProviderd等|

知识点太多不细写了

### Launcher3源码解析

|模块|类名|说明|
| :-- | :-- | :-- |
||Launcher|主页面|