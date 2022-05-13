# android的分区和文件系统

## 分区摘录

|名称|对应分区|备注|
|:--|:--|---|
|system|/system|存放android操作系统的**二进制可执行文件**以及**框架**。|
|boot|/boot|内核 + **默认启动**过程中所需要的initramfs|
|recovery|/recovery|内核 + 将**系统启动至recovery模式**的initramfs|
|cache|/cache|用于进行系统升级或recovery|
|userdata|/data|存放用户数据和配置文件|
||||
|dev|/dev|包含了所有Linux系统中使用的外部设备|
||/proc|配置数据|
||/net|网络相关配置数据|
||/sys/fs/cgroup|任意进程进行分组化管理的Linux内核功能。Android操作系统也就凭借着这个技术，为每个应用程序分配不同的cgroup，将每个程序进行隔离，达到了一个应用程序不会影响其他应用程序环境的目的。|
||/mnt|“挂载”挂接光驱、USB设备的目录|
||metadata||
| |metadata ||
||oem||
||storage||
||/mnt/runtime/default/emulated||
|开关机动画||/system/media/shutdownanimation<br />/system/media/bootanimation.zip<br />/system/framework/framework-res.apk/assets/images|



## 文件系统

- 虚拟文件系统（VFS）

  ```
  主要作用是对应用层屏蔽具体的文件系统，并提供统一的接口。
  ```

- 文件系统（File System）

  ```
  例如ext4, F2FS等。
  查看系统可以识别的文件系统：/proc/filesystems
  ```

- 页缓存（Page Cache）

  ```
  文件系统对数据的缓存，如果已在Page Cache中就不会去读取磁盘。
  读/写操作都会使用到。
  ```

  

## 磁盘

- 通用块层

  ```
  位于内核空间。
  系统中能够堆积访问固定大小数据块的设备称为块设备，例如SSD和硬盘等。
  通用块层的主要作用是接收上层发出的磁盘请求，并发出I/O请求。让上层不必关系底层硬件的具体实现。
  ```

- I/O调度层

  ```
  根据调度算法对请求进行合并和排序，从而降低真正的磁盘I/O。
  /sys/block/[disk]/queue/nr_requests      // 队列长度，一般是 128。
  /sys/block/[disk]/queue/scheduler        // 调度算法
  ```

- 块设备驱动层

  ```
  根据具体的物理设备，选择对应的驱动程序操作硬件设备完成I/O请求。
  闪存：电子擦写存储数据。
  光盘：激光烧录存储。
  ```

