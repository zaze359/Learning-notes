# Android启动流程

## 总体概览

![img](./Android%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.assets/image_1cegf6i1jmjmtdbqisgik1mu89.png)


1. **给设备供电，执行bootloader**：主要负责初始化软件运行的最小硬件环境，最后加载内核到内存中。
2. 内核加载进内存后，首先进入内核引导界面(主要是汇编)，在引导阶段最后，调用`start_kernel`进入内核启动阶段。内核最终启动用户空间的init程序。
3. **init**程序负责解析**init.rc**配置文件执行**Action和Service**,开启系统守护进程。其中最重要的是**zygote**和**ServiceManager**。前者是Android启动的第一个Dalvik虚拟机(4.4以上应该是ART吧)，它负责启动java世界的进程。后者是Binder通信的基础。
4. **zygote** fork了**system_server进程**,同时定义了一个Socket用于**接收AMS启动应用的请求**。
5. 在**system_server**进程的**init1(启动Native System Service)**和**init2(启动Jave System Service)**启动了系统进程。
6. 系统服务启动后会注册到ServiceManager中，用于Binder通信。
7. ActivityManagerService进入systemReady状态。
8. 在systemReady状态下，ActivityManagerService与zygote中的Socket通信，请求启动Home。
9. zygote收到请求，执行runSelectLoopMode处理请求。
10. zygote处理请求会通过forkAndSpecialize启动新的应用进程，最终启动了Home。

 

## bootloader

> 主要负责初始化软件运行的最小硬件环境，加载内核到内存中。