# Android内存优化

## 应用内存限制

| build.prop                  | 取值     | 说明                                                         |
| --------------------------- | -------- | ------------------------------------------------------------ |
| `dalvik.vm.heapstartsize`   | 例如8m   | App启动时分配的内存                                          |
| `dalvik.vm.heapgrowthlimit` | 例如192m | App最大内存限制。获取代码：`ActivityManager.getMemoryClass()` |
| `dalvik.vm.heapsize`        | 例如512m | App开启 `android:largeHeap="true"` 后的最大内存限制<br />获取代码：`ActivityManager.getLargeMemoryClass()` |

> android:largeHeap 这个属性一般用于存在大内存的图片或视频的应用。正常情况下不必开启，而应该考虑优化内存。

## 常见的内存问题

### 异常

* OOM崩溃。
* 内存分配失败崩溃。
* 内存不足导致应用进程被系统kill。
* 导致设备重启。

### 卡顿

* 内存不足导致频繁GC。
* 物理内存不足时系统会触发 low memory killer 机制。
* 系统负载过高。

### 内存抖动

* 使用了大量的临时变量，频繁申请释放内存。



> 物理内存不足时触发low memory killer机制，进程优先级如下：

![img](./Android%E5%86%85%E5%AD%98%E4%BC%98%E5%8C%96.assets/b8d160f8d487bcb377e0c38ff9a0ac98.png)



## 内存分析

查看内存使用情况：

[使用内存分析器查看应用的内存使用情况  | Android 开发者  | Android Developers](https://developer.android.com/studio/profile/memory-profiler?hl=zh-cn)

```
adb shell dumpsys meminfo <package_name|pid> [-d]
```



获取ANR 转储信息以及 GC 的详细性能信息

> 发送 SIGQUIT 信号获得 ANR 日志。

```
adb shell kill -S QUIT PID
adb pull /data/anr/traces.txt
```

使用 systrace 来观察 GC 的性能耗时



### Java 内存分析

> 常用的有 Allocation Tracker 和 MAT 这两个工具。

### Native 内存分析

> 使用[AddressSanitize](https://github.com/google/sanitizers)分析。

## Bitmap内存

| Android版本 | Bitmap内存存放位置                              | 备注                                                     |
| ----------- | ----------------------------------------------- | -------------------------------------------------------- |
| 3.0之前     | 对象存放在Java堆， 像素数据是放在 Native 内存。 | Bitmap Native 内存的完全依赖 finalize 函数，时机不可控。 |
| 3.0 ~ 7.0   | 对象和像素数据统一存放在Java堆。                | 占用大量堆内存，导致频繁GC甚至OOM。                      |
| 8.0及之后   | 对象存放在Java堆， 像素数据是放在 Native 内存。 | 利用NativeAllocationRegistry辅助回收Native内存           |



## 参考资料

[03 | 内存优化（上）：4GB内存时代，再谈内存优化 (geekbang.org)](https://time.geekbang.org/column/article/71277)

[系统跟踪概览  | Android 开发者  | Android Developers](https://developer.android.com/topic/performance/tracing)
