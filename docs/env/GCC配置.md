## GCC安装配置

> C/C++编译环境配置

### Windows安装C编译器

#### 在线安装（我失败了，最终使用了离线安装）

[下载 MinGW-W64 GCC](https://www.mingw-w64.org/downloads/)

选择 ``Sourceforge``点击下载即可

![1649488821383](./GCC%E9%85%8D%E7%BD%AE.assets/1649488821383.png)


> 安装选项

![img](./GCC%E9%85%8D%E7%BD%AE.assets/1649489888863.png)

- Version(gcc的版本)

一般直接使用默认版本即可。

- Archiecture(系统架构)

根据自身电脑选择。
 ``i686``: 对于32位; ``x86_64``对应64位。

- Threads(操作系统接口协议)

开发的应用程序遵循的协议。
``win32``: Windows程序
``posix``: Linux、Unix、Mac OS等其他操作系统下的程序。

- Exception(异常处理模型)

``Archiecture选择64位时``: seh、sjlj。 seh性能好，不支持32位，sjlj稳定性好，支持32位。

``Archiecture选择32位时``: dwarf、sjlj。dwarf性能好但是不支持64位。

- Build revision(修订版本)
  修复漏洞的版本标识，使用默认即可。

![result](./GCC%E9%85%8D%E7%BD%AE.assets/1649490901801.png)

#### 离线安装

在线安装出现报错: ``This file has been downloaded incorrently!``。

![](./GCC%E9%85%8D%E7%BD%AE.assets/1649491469263.png)

- 选择离线安装

[离线下载地址](https://sourceforge.net/projects/mingw-w64/files/mingw-w64/)

![](./GCC%E9%85%8D%E7%BD%AE.assets/1649491665873.png)

-  配置环境变量

path中添加 ``D:\mingw64\bin``; 根据自己实际安装位置调整。

- 校验是否配置成功

```shell
gcc -v
```
