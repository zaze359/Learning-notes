# RxJava学习笔记

Tags : zaze

---
[TOC]

---

## 一、线程调度

- **Schedulers.immediate()**
直接在当前线程运行

- **Schedulers.newThread()**
总是启动一个新的线程

- **Schedulers.io()**
内部实现是用一个无数量上限的线程池
I/O操作,不要把计算工作放在io(),可以避免创建不必要的线程

- **Schedulers.computation()**
使用的固定的线程池，大小为cpu核数;
计算时使用的Scheduler;
不会被I/O等操作限制性的操作;
不要用于IO操作;

- **Schedulers.from(executor)**
指定的Executor作为调度器

- **Schedulers.trampoline()**
在当前线程排队开始执行

- **AndroidSchedulers.mainThread()**
Android主线程

### 小计

- subscribeOn
指定被观察者Observable在哪里运行

- observeOn()
指定观察者Observer 在哪里运行;
observeOn() 指定的是之后的操作所在的线程

- doOnSubscribe()
即使在之前调用observeOn(), 也已subscribe()所在线程中为准;
若后面有 subscribeOn(), 可以变更线程;

## 二、操作符

- map()
主要用于转换数据
```
map
```

- flatMap()
**重新生成一个Observable对象**,并转换数据
分发成多个Observable，最后合并为一个Observale
合并后的结果是无序的
```
flatMap
```

- concatMap()
基本等同flatMap
区别是 concatMap最后的结果是有序的


- filter()
过滤数据 true返回, false被过滤
```
filter
```

- Merge()
合并 : 多输入，单输出


- take()
指定最多输出几个结果
```
take
```

- doOnNext()
对每次输出做一定对预处理
```
- 调试
- 去保存/缓存网络结果
```

- firstElement()
发射第一个元素或者结束
```
firstElement
```

