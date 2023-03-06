# Linux下的文件系统





## tmpfs

**tmpfs是一种虚拟内存文件系统**，它运行在虚拟内存 VM 中, 所以它的访问速度很快。

tmpfs的默认上限大小是VM的一半，但是它并不会直接占用那么多内存，而是用多少占用多少，直到达到指定的上限大小。

* VM(virtual memory)：虚拟内存，由RM 和 swap构成。内核中的vm子系统会在RM不足时，将RM中不常用的数据交互到swap中，需要使用时才从swap中交换到RM中。
* RM(Real Memory)：真实的物理内存，访问速度很快。
* swap：交换区，是由磁盘虚拟出来的内存空间，访问速度较慢。

### 如何使用tmpfs

我们可以通过 `mount` 命令将 tmpfs文件系统挂载带 指定的目录下，这样我们往指定目录下写的文件相当于是直接写到了VM内存中。

> **Note**：由于存储在VM中，当面我们 `umount` 取消挂载后，之前保存的内容也会丢失。

```shell
# -t 指定文件系统类型：tmpfs
# -o size=100m 指定
# 设备名：mtmpfs
# 挂载点：/home/tmpfs
sudo mkdir /home/tmpfs
sudo mount -t tmpfs -o size=500m mtmpfs /home/tmpfs

# 通过挂载点 卸除文件系统
sudo umount -v /home/tmpfs
# 通过设备名 卸除文件系统
sudo umount -v mtmpfs
```

可用使用 `df` 命令查看挂载情况：

![image-20230305200032015](./Linux%E4%B8%8B%E7%9A%84%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20230305200032015.png)



### 测试效果

使用 `dd` 命令测试写入：

> `/dev/zero` 能够无限提供空字符。常用于生成特定大小的空文件，或者用它去覆盖信息。

```shell
# 直接写满
dd if=/dev/zero of=/home/tmpfs/a.bin
# 写入100MB数据
dd if=/dev/zero of=/home/tmpfs/a.bin bs=1024k count=100
```

![image-20230305200259133](./Linux%E4%B8%8B%E7%9A%84%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20230305200259133.png)

测试读取：

> `/dev/null` 一个特殊的空设备，任何写入其中的数据最终都会被丢弃，所以也被称为 **“黑洞”**。常用于接收不需要的输出流。

```shell
# 读取100MB数据
dd of=/dev/null if=/home/tmpfs/a.bin bs=1024k count=100
```

## proc

**proc 是虚拟文件系统**， 以文件的形式提供 Linux内核空间 和 用户空间 之间的通信接口，可以获取系统内部的信息，例如各个进程信息、cpu负载、内存等。

* 一般挂载在 `/proc`下，它不存在真实的硬盘存储。
* 读取内部文件时文件内容是动态生成的。

![image-20230305203038261](./Linux%E4%B8%8B%E7%9A%84%E6%96%87%E4%BB%B6%E7%B3%BB%E7%BB%9F.assets/image-20230305203038261.png)

| 文件       |                                                              |      |
| ---------- | ------------------------------------------------------------ | ---- |
| 数字文件夹 | 文件名是pid，内部保存的是对应进程的一些信息。例如进程中打开的文件描述符fd，加载的动态库地址maps等。 |      |
| bootconfig |                                                              |      |
| cpuinfo    | 查看CPU信息                                                  |      |
| devices    | 内核中已注册的设备                                           |      |
| cmdline    | 内核的启动参数，例如启动镜像路径 BOOT_IMAGE等。              |      |
| version    | 系统版本                                                     |      |
| meminfo    | 内核的内存信息                                               |      |
| mounts     | 已挂载的文件系统，可以看到所有通过 `mount`挂载的文件系统，proc也能在里面找到。 |      |
| interrupts | 中断信息                                                     |      |
| partitions | 系统分区表                                                   |      |

