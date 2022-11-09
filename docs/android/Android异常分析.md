# Android异常分析

Android常见的异常可以分为ANR（Application Not Responding）和崩溃，崩溃包括JavaCrash和[NativeCrash](./Android异常分析之NativeCrash.md)。

Java崩溃是由于触发了未捕获的异常，native崩溃一般都是访问了非法地址等导致程序异常退出。



### 异常分析

* Java Crash：异常信息比较直观，观察对应堆栈即可，OOM相关错误时需要观察内存信息和资源信息。

* Native Crash：需要观察 signal、code、fault addr 等内容，以及崩溃时Java的堆栈。
* ANR：
  * 主线程是否存在锁等待。
  * 观察ANR 日志中 iowait、CPU、GC、system server 等信息，进一步确定是 I/O 问题，或是 CPU 竞争问题，还是由于大量 GC 导致卡死。

## 崩溃

崩溃捕获

### 崩溃

### 衡量指标

启动崩溃率：影响最大。使用安全模式相关技术，给用户自救的机会。

UV 崩溃率：用户出现一次就会被计算

```tex
UV 崩溃率 = 发生崩溃的 UV / 登录 UV
```

UV 异常率：

```tex
UV 异常率 = 发生异常退出或崩溃的 UV / 登录 UV
```





PV 崩溃率

重复崩溃率

## 信息采集

异常信息：

* 进程名、线程名。区分前后台进程，是否是UI线程等。
* 崩溃堆栈和类型。是java crash还是native crash或是ANR。

日志信息：

* 应用日志：logcat获取应用现场日志。
* 系统日志：系统的event logcat会记录App运行的一些基本情况。记录在`/system/etc/event-log-tags`中。

应用信息：

* 崩溃场景：发生在哪个页面、哪个业务中。
* 关键操作路径：日志打点记录的用户操作路径。
* 其他信息：业务相关的主要流程日志。

资源信息：

* 文件句柄fd：文件句柄的限制可以通过 `/proc/self/limits` 获得，一般单个进程允许打开的最大文件句柄个数为 1024。过多时(800以上)需要检查是否有文件泄露的问题。
* 线程数：当前线程数大小可以通过 `/proc/self/status`得到，过多时需要排查是否存在线程相关问题。
* JNI：通过 DumpReferenceTables 统计 JNI 的引用表，分析是否存在JNI泄露问题。

设备信息：

* 系统信息：

  * 设备类型、系统（版本、ABI等）、厂商、硬件信息（CPU等）等。

  * 设备状态：root、模拟器、xposed等。

* 磁盘信息	

* 网络信息

* 内存信息

  * 系统剩余内存：可以读取`/proc/meminfo`获得。

  * 应用使用内存：PSS（Proportional Set Size） 和 RSS（Resident Set Size） 通过 `/proc/self/smap` 计算

  * 虚拟内存：虚拟内存可以通过 `/proc/self/status` 得到
