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

