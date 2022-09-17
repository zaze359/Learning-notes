# Android任务调度

## 一、Handler

> 常用的任务调度方式，贯穿整个Android的消息机制

* 休眠时无法执行。



### AlarmManager

[alarms官方文档](https://developer.android.com/training/scheduling/alarms)

> 当设备在低电耗模式下处于空闲状态时，不会触发闹钟。所有已设置的闹钟都会推迟，直到设备退出低电耗模式。
> Doze模式下可以使用 **setAndAllowWhileIdle()** 或 **setExactAndAllowWhileIdle()**

* 利用系统级的闹钟服务，持有`Wakelock`。
* 需要精准的在指定时间执行，例如闹钟。
* 指定间隔重复执行任务。
* Google不建议在`Alarm`中操作网络网络相关业务。



### Job Scheduler

> 指定场景执行任务，Google推荐将网络相关业务放到此处。

### Sync Adapter

> 用于和服务器同步数据



### GCM(FCM)

> 国内被墙，无法使用

应用消息推送

### WorkManager

[Schedule tasks with WorkManager | Android Developers](https://developer.android.com/topic/libraries/architecture/workmanager)

> 强大的任务调度解决方案，适用于处理后台任务。

三种类型的任务调度：

* 立即执行
* 长时间运行
* 可延期执行