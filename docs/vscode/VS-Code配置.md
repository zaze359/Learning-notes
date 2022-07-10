---
title: VS Code Spring Boot
date: 2020-07-01 17:05
---
# VS-Code配置

## 编译环境配置

### C语言

#### 1. Windows安装C编译器

##### 在线安装（我失败了，最终使用了离线安装）
[下载 MinGW-W64 GCC](https://www.mingw-w64.org/downloads/)

选择 ``Sourceforge``点击下载即可

![Sourceforge](image/VS-Code配置/1649488821383.png)


> 安装选项

![img](image/VS-Code配置/1649489888863.png)

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

![result](image/VS-Code配置/1649490901801.png)

##### 离线安装

在线安装出现报错: ``This file has been downloaded incorrently!``。

![](image/VS-Code配置/1649491469263.png)

- 选择离线安装

[离线下载地址](https://sourceforge.net/projects/mingw-w64/files/mingw-w64/)

![](image/VS-Code配置/1649491665873.png)

-  配置环境变量

path中添加 ``D:\mingw64\bin``; 根据自己实际安装位置调整。

- 校验是否配置成功

```
gcc -v
```

#### 2. 安装需要的插件

- C/C++



#### 3. 项目配置

修改``c_cpp_properties.json``，添加一下include目录。

```json
{
    "configurations": [
        {
            "name": "Win32",
            "includePath": [
                "${workspaceFolder}/**",
                "D:/mingw64/include/**"
            ],
            "defines": [
                "_DEBUG",
                "UNICODE",
                "_UNICODE"
            ],
            "compilerPath": "D:\\mingw64\\bin\\gcc.exe",
            "cStandard": "gnu17",
            "cppStandard": "gnu++14",
            "intelliSenseMode": "windows-gcc-x64"
        }
    ],
    "version": 4
}

```



## 插件安装

### Markdown

Office Viewer

## Spring Boot

### 初始化

- DevTools（代码修改热更新，无需重启）

- [X] Web（集成tomcat、SpringMVC） @2020-11-03 10:07:00

- Lombok（智能生成setter、getter、toString等接口，无需手动生成，代码更简介）
- Thymeleaf （模板引擎）。
  YAML

### Vue

```
// 安装webpack
npm install -g webpack 
// 
npm init
//
npm i webpack vue vue-loader

```

## 问题处理记录

### 控制台乱码

终端中输入 ``chcp``查看当前编码格式。

| 编码格式 | 代码  |
| -------- | ----- |
| GBK      | 936   |
| UTF-8    | 65001 |
| GB2312   | 20936 |

修改编码

```shell
# chcp + 代码
chcp 65001
```
