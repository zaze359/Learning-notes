# JVM垃圾收集器

> 垃圾收集器需要考虑的核心问题：
>
> 1. 哪些内存需要回收？
>
> 2. 什么时候回收？
>
> 3. 如何回收？



现代垃圾收集器大部分都是基于分代收集理论设计的。以经典分代为例：

- 新生代（Young Generation）: 一个Eden和两个Survivor（From Survivor 和 To Survivor）。
- 老年代（Old Generation）:
- ~~永久代（Permanent Generation）~~: HotSpot早期方法区，其他虚拟机并不存在, JDK 6准备计划放弃，JDK 7开始实行，JDK 8 时被元空间替代。

Eden区存放刚刚创建的对象，如果Eden区存放不下就放入到Survivor区，再者老年代中。

GC回收时，将Eden区中存活的对象放入Survivor From中，下一次回收时将Survivor From中的对象存入Survivor To中





## 观察GC日志

```shell
# Concurrent----后台回收内存，不暂停用户线程
# Alloc----当app要申请内存，而堆又快满了的时候，会阻塞用户线程

Explicit----调用Systemt.gc()等方法的时候触发，一般不建议使用

NativeAlloc----当native内存有压力的时候触发

Name
Concurrent mark sweep----全部对象的检测回收
Concurrent partial mark sweep----部分的检测回收
Concurrent sticky mark sweep----仅检测上次回收后创建的对象，速度快，卡顿少，比较频繁

```

