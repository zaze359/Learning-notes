# Android的文件系统

## 分区介绍

| 分区名                        | 名称       | 备注                                                         |
| :---------------------------- | :--------- | ------------------------------------------------------------ |
| /system                       | system     | 存放android操作系统的**二进制可执行文件**以及**框架**。      |
| /data                         | userdata   | 存放用**户数据和配置文件**                                   |
| /cache                        | cache      | 系统升级过程使用的分区或recovery                             |
| /boot                         | boot       | 内核 + **默认启动**过程中所需要的initramfs                   |
| /recovery                     | recovery   | 内核 + 将**系统启动至recovery模式**的initramfs               |
| /storage                      | sdcard     | 外置或者内置sdcard                                           |
| /vender                       |            | 存储厂商对Android系统的修改                                  |
|                               |            |                                                              |
| /dev                          | dev        | 包含了所有Linux系统中使用的外部设备                          |
| /proc                         |            | 配置数据                                                     |
| /net                          |            | 网络相关配置数据                                             |
| /sys/fs/cgroup                |            | 任意进程进行分组化管理的Linux内核功能。Android操作系统也就凭借着这个技术，为每个应用程序分配不同的cgroup，将每个程序进行隔离，达到了一个应用程序不会影响其他应用程序环境的目的。 |
| /mnt                          |            | “挂载”挂接光驱、USB设备的目录                                |
| metadata                      |            |                                                              |
| metadata                      |            |                                                              |
| oem                           |            |                                                              |
| /mnt/runtime/default/emulated |            |                                                              |
|                               | 开关机动画 | /system/media/shutdownanimation<br />/system/media/bootanimation.zip<br />/system/framework/framework-res.apk/assets/images |





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

  