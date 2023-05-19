# AOSP下载及编译

> [Google Source](https://android.googlesource.com/ )
>
> [下载源代码  | Android 开源项目  | Android Open Source Project](https://source.android.com/setup/downloading)
>
> [编译准备工作  | Android 开源项目  | Android Open Source Project (google.cn)](https://source.android.google.cn/setup/building)
>
> [清华大学开源软件镜像站](https://mirror.tuna.tsinghua.edu.cn/help/AOSP/)

## 1. 下载源代码

### 1.1. 环境配置

有缺少根据提示根据提示安装即可。

```shell
sudo apt-get upgrade
# openjdk
sudo apt-get install openjdk-8-jdk
# git、curl、python等工具
sudo apt-get install git curl python
```

### 1.2. Repo 安装

1. 确保主目录下有一个 bin/ 目录，并且该目录包含在路径中：

   ```shell
   mkdir ~/bin
   PATH=~/bin:$PATH
   ```

2. 下载 Repo 工具，并确保它可执行：

   ```shell
   curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
   chmod a+x ~/bin/repo
   ```

### 1.3. 初始化 Repo

1. 创建一个空目录来存放aosp文件：

   > 如果是 MacOS，必须在区分大小写的文件系统中创建该目录

   ```shell
   mkdir WORKING_DIRECTORY
   cd WORKING_DIRECTORY
   ```

2. 配置git参数:

   ```shell
   git config --global user.name "Your Name"
   git config --global user.email "you@example.com"
   ```

3. 执行``repo init``指定源码的**来源**和**版本**:
   
   - Google

     ```shell
     repo init -u https://android.googlesource.com/platform/manifest
     ## -b 指定分支
     repo init -u https://android.googlesource.com/platform/manifest -b android-4.0.1_r1
     ```
   
   - 清华镜像
   
       ```shell
       repo init -u https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/platform/manifest -b android-11.0.0_r32
       ```
       
     若之前已有AOSP源码, 通过下述命令替换地址:
     
     ```shell
     git config --global url.https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/.insteadof https://android.googlesource.com
     ```
     
   - 查看已有版本
   
     ```
     cd .repo/manifests
     git branch -a
     ```

### 1.4. 同步Android源代码

```shell
repo sync
# -c 仅下载当前分支
# -j4 启动4个线程下载
# 2>&1 | tee sync.log 记录错误日志
# 根据自身调衡参数
repo sync -c -j4 2>&1 | tee sync.log
```

---

## 2. 源码编译及编译

### 2.1. 清理旧的构建产物

```shell
sudo apt install make
make clobber
```

### 2.2. 初始化环境

```shell
source build/envsetup.sh
# or
. build/envsetup.sh
```

### 2.3. 选择编译目标

> 要详细了解如何针对实际硬件进行编译以及如何在实际硬件上运行编译系统，请参阅[运行编译系统](https://source.android.google.cn/setup/running)

```shellshe l
# aosp_arm: BUILD
# eng: BUILDTYPE
lunch aosp_arm-eng
```

| 编译类型  | 使用情况                                                     |
| :-------- | :----------------------------------------------------------- |
| user      | 权限受限；适用于生产环境                                     |
| userdebug | 与“user”类似，但具有 root 权限和可调试性；是进行调试时的首选编译类型 |
| eng       | 具有额外调试工具的开发配置                                   |

### 2.4. 编译

```
make -j4
```

编译过程可能会由于缺少一些组件而失败, 根据提示安装即可, 一下记录一些

```
sudo apt install libncurses5
```

一些常用编译命令记录

```shell

source build/envsetup.sh
# Launcher3应用所在的目录
cd packages/apps/Launcher3
# 编译当前目录中的所有模块，不编译依赖模块
mm
# 编译当前目录中的所有模块及其依赖项
mma 
# 编译 提供的目录中的所有模块及其依赖项
mmma
```







## 编译系统

|              |                                                            |      |
| ------------ | ---------------------------------------------------------- | ---- |
| `android.bp` | 基于 bp 的语法规则编写的脚本，它定义和描述了一个模块的构建 |      |
| Blueprint    | 解析 android.bp 文件。                                     |      |
| Soong        | Blueprint解析后通过 Soong编译成 Ninja                      |      |
| Ninja        |                                                            |      |
| -            |                                                            |      |
| android.mk   |                                                            |      |
|              |                                                            |      |



---

## 记录下载和编译遇到的一些问题

> 遇事不决先重置一下
>
> ```
> repo forall -c "git reset --hard HEAD"
> ```
>

### 重新调用``repo init``需使用``--config-name``

```shell
Your identity is
....
please re-run ‘repo init’ with --config-name
```

此错误安装提示在最后加上``--config-name``并根据提示输入``user.name``和`` user.email``即可

```shell
repo init -u https://mirrors.tuna.tsinghua.edu.cn/git/AOSP/platform/manifest --config-name
```

 





