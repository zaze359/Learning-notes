# Android系统镜像

Android设备只能刷专门为相应型号定制的镜像。厂商会在设备上刷一套默认系统镜像作为出场设置。

## 如何获取镜像

我们可以先下载一个Google 提供的 Android系统镜像或者从设备中提取出来，方便后续对照学习。

### 从 factory image repository 下载镜像

下载地址：[Factory Images for Nexus and Pixel Devices  | Google Play services  | Google Developers](https://developers.google.com/android/images?hl=zh-cn)

解压压缩包：

```shell
tar zxvf .\angler-opm7.181205.001-factory-b75ce068.zip
```

![image-20221030233819736](./Android%E7%B3%BB%E7%BB%9F%E9%95%9C%E5%83%8F.assets/image-20221030233819736.png)

```shell
cd angler-opm7.181205.001
mkdir images
tar zxvf .\image-angler-opm7.181205.001.zip -C ./images
```

![image-20221030234209262](./Android%E7%B3%BB%E7%BB%9F%E9%95%9C%E5%83%8F.assets/image-20221030234209262.png)

### 从设备中提取镜像



完整的镜像组要由以下几个文件组成：

* **Boot Loader**：包含在启动阶段由应用处理器（application processor）执行的代码, 用于寻找和加载boot镜像、进行固件升级和使系统进入 recovery 模式。
* **boot镜像**：一般由 内核 和 `RAM disk` 组成，作用是加载系统。
* **recovery镜像**：同样由 内核 和  `RAM disk` （另一个）组成。一般用来在正常启动失败或通过 OTA 升级时，把系统加载到 `recovery模式`。
* **/system 分区镜像**：存放完整的android系统。包含Google提供的 二进制可执行文件 和 framework，以及厂商体哦那个的一些东西。
* **/data 分区镜像**：存放 默认出厂设置 的数据文件，是`/system分区`中程序正常运行所必需的文件。恢复出厂设置 就是将此镜像 刷到 /data 分区进行还原。

## Boot Loader

> Boot Loader会被刷到 `aboot分区`。

含有启动阶段由应用处理器(application processor)执行的代码，用于寻找和加载boot镜像、进行固件升级和使系统进入 recovery 模式。

大多数还会实现一个USB stack，使得用户可以在电脑上控制启动和升级过程（通常是通过`fastboot`）。

一般都选用LK（Little Kernel）作为启动器，部分厂商可能不同（例如三星）。LK仅实现了最基本的启动功能。

包含的功能：

- 基本的硬件支持 

- 找到并启动内核

- 基本的UI

- 支持console

- 使设备可被用作USB目标设备

- 支持闪存分区

- 支持数字签名

## boot 镜像

> boot 镜像会被刷到 `boot分区`。

一般由内核和RAM disk组成，作用是加载系统。

正常启动后，`RAM disk` 会被 Android 用作 root 文件系统（/）。其中的`/init.rc`及相关文件 规定了系统余下部分如何被加载。



## recovery 镜像

> recovery 镜像会被刷到 `recovery 分区`。

由 内核 和  `RAM disk` （另一个）组成。一般用来在正常启动失败或通过 OTA 升级时，把系统加载到 `recovery模式`。



/system 分区镜像

/data 分区镜像



## 参考资料

《最强Android书 架构大剖析》