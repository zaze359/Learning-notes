# Java虚拟机(JVM)

## 参考资料

> **深入理解Java虚拟机（第3版）**📚



## 概述

### 什么是JVM?

### Java虚拟机家族:

| JVM                   | 备注                                                         |
| --------------------- | ------------------------------------------------------------ |
| Sun Classic VM        | **世界第一款商用Java虚拟机。**<br />纯解释器方式执行。<br />可以外挂即时编译器,不过此时解释器便不再工作。<br />JDK1.0时搭载, 从JDK 1.2开始和HotSpot 共存, 直至1.4完全退出商用虚拟机的历史舞台。<br />基于Handle的对象查找方式。 |
| Exact VM              | JDK1.2版本时在Solaris平台上发表过, 后未普及就被HotSpot Vm替代。<br />采用准确式内存管理,可以知道内存中某个位置的数据具体时什么类型。<br />热点探测、编译器和解释器混合工作等。 |
| **HotSpot VM**        | Sun公司收购后，从JDK1.2开始搭载。<br />**全世界使用最广泛的虚拟机**<br />准确式内存管理、热点代码探测技术、编译器和解释协同工作等。 |
| BEA JRockit           | 后被Oracle收购，不再发展, HotSport从中吸取了部分功能，如Java Mission Control监控工具。 |
| **IBM J9**            |                                                              |
| Mobile/Embedded VM    |                                                              |
| BEA Liquid VM/Azul VM | 专有虚拟机:与特定硬件平台绑定、软硬件配合。                  |
| Apache Harmony        | 非华为的Harmony OS。😂<br />它的许多代码被吸纳进Google Android SDK中。 |
| Dalvik虚拟机          | **并不是一个Java虚拟机，但和Java存在千丝万缕的关系。**<br />它没有遵循《Java虚拟机规范》，不能直接执行Java的Class文件，使用寄存器架构而不是Java虚拟机中常见的栈架构。<br />Android 5.0 开始ART(支持AOT提前编译)全面替代了Dalvik虚拟机。 |
| 一些非主流Java虚拟机  | KVM、Java Card VM、Squawk VM等等。                           |

