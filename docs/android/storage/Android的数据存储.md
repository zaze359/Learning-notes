# Android的数据存储

> 数据存储的六要素：正确性、时间开销、空间开销、安全、开发成本和兼容性。



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

## Android常用的存储方式

* [SharedPreferences](./SharedPreferences.md)
* [ContentProvider](./ContentProvider.md)
* 文件
* 数据库（SQLite）

开源存储方案

* mmkv

