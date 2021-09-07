# JDK编译流程



## 简单了解JDK

### OpenJDK、Sun/OracleJDK的关系

2006年11月13日, Sun公司宣布计划将java开源并建立了OpenJDK组织管理源码。**OpenJDK(GPLv2)**就是Sun公司去除了少量产权代码后开源下的产物，它和**SunJDK(JRL)**的除了代码头文件的版权注释之外，**代码几乎完全一样**。

2009年Sun公司被Oracle收购后，有了OracleJDK。

2018年JDK 11发布后，Oracle宣布以后将同时发行两个JDK版本, 并从JDK11起把以前的商业特效全部开源给OpenJDK:

- **Oracle发行的OpenJDK(GPLv2+CE): 完全免费, 半年更新支持。**
- **OracleJDK(OTN, 之前为BCL): 个人免费试用, 生产环境商用收费, 三年更新支持。**

Oracle之前在JDK9 发布后宣布采用持续交付的形式，在3月和9月各发布一个大版本, 导致对JDK版本维护不易。这两个JDK版本可能有处理这方面问题的意思。免费版本维护更新时间短, 迫使商业用户升级, 另一个版本则是收费卖服务的形式, 让用户去购买商业支持。

> JRL: Java研究授权协议,sun自JDK5时代已JRL公开过Java代码, 主要开发给研究人员阅读， JDK6 update23因OpenJDK项目终止。
>
> BCL: 个人和商用都可以使用但是不能进行修改。
>
> OTN:个人免费，商用收费。



## 源码下载

### 1. 通过Mercurial获取源码

1. 安装Mercurial

```bash
brew install hg
# or
sudo easy_install mercurial
```



2. Repository中clone

```bash
hg clone https://hg.openjdk.java.net/jdk/jdk12
```



### 2. 直接下载打包好的源码(推荐✨)

[jdk下载地址](https://hg.openjdk.java.net/jdk)

选择一个版本进入, 然后点击**brower**查看源码。

选择一个压缩包下载。

下载后本地直接解压即可。

![image-20210907220813653](JDK%E7%BC%96%E8%AF%91%E6%B5%81%E7%A8%8B.assets/image-20210907220813653-1024121.png)



## 编译准备

- 阅读doc/building.html
- 目录尽量不要包含中文，以免产生一些问题。
- 尽量选择64位操作系统编译，有32位版本需求可以通过 ``--with-target-bits=32``参数生成。
- 2G以上内存, 6G以上存储空间。

### MacOS编译环境

- MacOs X 10.13版本以上。
- 安装**XCode** 和 **Command Line Tools for XCode**。(提供CLang编译器以及Makefile中用到的其他外部命令)。

Command Line Tools for XCode安装和更新

```bash
xcode-select --install
# 更新
softwareupdate --list
softwareupdate --install -a
```
### Linux编译环境

- GCC4.8以上 或 CLang3.2以上。（官方推荐GCC 7.8, Clang 9.1）

安装GCC:

```bash
sudo apt-get install build-essential
```

第三方库:

| 工具     | 库名称                                      | 安装命令                                                     |
| -------- | ------------------------------------------- | ------------------------------------------------------------ |
| FreeType | The FreeType Project                        | sudo apt-get install libfreetype6-dev                        |
| CUPS     | Common UNIX Printing System                 | sudo apt-get install licups2-dev                             |
| X11      | X Window System                             | sudo apt-get install libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev |
| ALSA     | Advanced Linux Sound Architecture           | sudo apt-get install libasound2-dev                          |
| libffi   | Portable Foreign Function Interface Library | sudo apt-get install libffi-dev                              |
| Autoconf | Extensible Package of M4 Macros             | sudo apt-get install autoconf                                |



### Bootstrap JDK

编译 JDK N 之前必须安装一个至少为 N-1版本的已编译好的JDK(官方称为**Bootstrap JDK**)。

练习时编译JDK12 则安装一个JDK11

```bash
sudo apt-get install openjdk-11-jdk
```

## 执行编译

查看编译参数	

```bash
bash configure --help
```

> 编译参数记录表

| 编译参数 |      |      |
| -------- | ---- | ---- |
|          |      |      |
|          |      |      |
|          |      |      |

## 记录一次完成的编译操作过程

> 编译过程可能会由于缺少组件而无法执行，根据提示安装.

首先执行一次``bash configure``

![image-20210907235308067](JDK%E7%BC%96%E8%AF%91%E6%B5%81%E7%A8%8B.assets/image-20210907235308067.png)
提示没有找到**Autoconf**, 按照提示安装:

```bash
brew install autoconf
```

安装完成再次执行``bash configure``

![image-20210907235954514](JDK%E7%BC%96%E8%AF%91%E6%B5%81%E7%A8%8B.assets/image-20210907235954514.png)

还是报错😭, 猜测可能和没装xcode有关, 老老实实去App Store安装了xcode

