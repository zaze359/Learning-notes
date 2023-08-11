# ELF文件

> ELF（Executable and Linking Format）可执行和可链接格式。

是UNIX系统实验室（USL）作为应用程序二进制接口（Application Binary Interface，ABI）而开发和发布的，也是Linux的主要可执行文件格式。

主要类型：

* 可重定向的对象文件（Relocatable File）：汇编器生成的`x.o`文件

* 可执行的对象文件（Executable File）

* 可被共享的对象文件（Shared Object File）：动态库文件，即`x.so`文件。

```shell
# linux
# 查看ELF文件所有信息
readelf -a <file>
# ELF 头信息
readelf -h <file>
# 查看ELF文件section信息：
readelf -S <file>
# 查看ELF文件符号表：
readelf -s <file>
# Program Header Table信息
readelf -l <file>
# 查看library的依赖
readelf -d <library> | grep NEEDED

# 查看静态库定义的函数
readelf -c xx.a 
# 查看动态库定义的函数
readelf -A xx.so
```

![img](./ELF%E6%96%87%E4%BB%B6.assets/181d3fed100b9ca11360a03625db5296.png)

## ELF格式视图

> 只有ELF头的位置是固定的，其余部分的位置和大小是根据ELF头的信息来决定的。

### 链接视图

 链接视图就是在链接时用到的视图，以`节（section）`为单位。

### 执行视图

执行视图就是在执行时用到的视图，以`段（segment）`为单位。

### 释义表

|                      |            |      |
| -------------------- | ---------- | ---- |
| ELF header           | ELF头      |      |
| Program header table | 程序头部表 |      |
| Section              | 节         |      |
| Section header table | 节头表     |      |

| section                             |                                |      |
| ----------------------------------- | ------------------------------ | ---- |
| .got（Global Offset Linkage Table） | 保存全局的偏移量表（加载过程） |      |
| .plt（Procedure Linkage Table）     | 保存过程链接表（加载过程）     |      |
| .dynsym                             | 保存了符号表(Symbol table)信息 |      |

| 数据区 |                                                |                                                              |
| ------ | ---------------------------------------------- | ------------------------------------------------------------ |
| 代码段 | 存放**程序执行代码**的一块内存区域             | 区域的大小在程序运行前就已经确定，通常属于只读不可修改, 某些架构也允许代码段可修改。在代码段中，也有可能包含一些只读的常数变量，例如字符串常量等。 |
| 数据段 | 存放程序中**已初始化的全局变量**的一块内存区域 | 属于静态内存分配，由系统自动分配回收。                       |
| BSS段  | 存放程序中**未初始化的全局变量**的一块内存区域 | 属于静态内存分配。                                           |
| 堆     | 存放进程运行中**被动态分配的内存段**。         | 它的大小并不固定，可动态扩张或缩减                           |
| 栈     | 存放程序临时创建的**局部变量**                 |                                                              |



## 动态链接

> 链接器/加载器（linker）负责将多个.o文件链接重定位成一个大文件，然后加载器（loader）再将这个大文件重定位到一个进程空间中。在linux中链接和加载机制的载体就是ELF文件。

### 链接流程

例如调用`dlopen("libxxx.so")`来加载`xxx.so`文件：

* 系统会先**检查缓存中已加载ELF文件列表**是否存在该so。如果**未加载则执行ELF加载过程**，若**已加载则计数加一**。
* 然后从`libxxx.so`的`dynamic segment`中**读取其所依赖的库**，按照相同的逻辑，把未缓存的库加入加载列表。

### ELF加载流程

* **读取ELF的程序头部表（Program header table）**
* 找到类型为`PT_INERP`的`Interpreter Path`段解析出加载器（linker），修改它可以使用我们自定义的linker。
* 把所有类型为`PT_LOAD`的`Loadable segment`逐个mmap到内存中。
* **读取`Dynamic segment`中的各个信息项**，计算并保存所有section的虚拟地址。
* 执行重定位操作：处理`.rel.xxx`文件
* ELF加载完成，引用计数+1。

## 查看ELF结构

[ELF文件样例](./ELF文件样例.txt)

![image-20221010172953758](./ELF%E6%96%87%E4%BB%B6.assets/image-20221010172953758.png)

### ELF头

```shell
ELF 头：
  Magic：   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00 
  类别:                              ELF32
  数据:                              2 补码，小端序 (little endian)
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI 版本:                          0
  类型:                              DYN (共享目标文件)
  系统架构:                          ARM
  版本:                              0x1
  入口点地址：               0x0
  程序头起点：          52 (bytes into file)
  Start of section headers:          656088 (bytes into file)
  标志：             0x5000200, Version5 EABI, soft-float ABI
  Size of this header:               52 (bytes)
  Size of program headers:           32 (bytes)
  Number of program headers:         8
  Size of section headers:           40 (bytes)
  Number of section headers:         27
  Section header string table index: 26
```

### Dynamic segment

> 加载各个信息项：字符串表、导入表

![image-20221010182231427](./ELF%E6%96%87%E4%BB%B6.assets/image-20221010182231427.png)

可以在对应的`elf_common.h`文件中查看*d_tag*的定义

| tag         | value 10进制 | value 16进制 |                                  |                                                 |
| ----------- | ------------ | ------------ | -------------------------------- | ----------------------------------------------- |
| DT_NEEDED   | 1            | 0x01         | 需要加载的依赖库的字符串表偏移量 | String table offset of a needed shared library. |
| DT_STRTAB   | 5            | 0x05         | 字符串表地址                     | *Address of string table.*                      |
| DT_STRSZ    | 10           | 0x0a         | 字符串表size                     | *Size of string table.*                         |
| DT_REL      | 17           | 0x11         | 重定位表地址                     | *Address of ElfNN_Rel relocations.*             |
| DT_RELSZ    | 18           | 0x12         | 重定位表total size               | *Total size of ElfNN_Rel relocations.*          |
|             |              |              |                                  |                                                 |
| DT_JMPREL   | 23           | 0x17         | PLT 导入表地址                   | Address of PLT relocations.                     |
| DT_PLTRELSZ | 2            | 0x02         | PLT 导入表total size             | *Total size in bytes of PLT relocations.*       |
| DT_PLTREL   | 20           | 0x14         | PLT 类型                         | *Type of relocation used for PLT.*              |

### 符号表（Symbol Table）

相当于一个助记符，用一个字符串来标识地址。即将符号名称和地址进行绑定。方便了符号的引用。

* 符号名称：函数名、变量名
* 符号值（Symbol Value）：代码地址、数据地址。
  * 代码地址：如函数名、跳转标号
  * 数据地址：如全局变量




```shell
Symbol table '.dynsym' contains 2717 entries:
   Num:    Value  Size Type    Bind   Vis      Ndx Name
     0: 00000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 00000000     0 FUNC    GLOBAL DEFAULT  UND sysconf@LIBC (2)
     2: 00000000     0 FUNC    GLOBAL DEFAULT  UND __cxa_atexit@LIBC (2)
     3: 00000000     0 FUNC    GLOBAL DEFAULT  UND __cxa_f[...]@LIBC (2)
     4: 00000000     0 FUNC    GLOBAL DEFAULT  UND strerror@LIBC (2)
     5: 00000000     0 FUNC    GLOBAL DEFAULT  UND pthread[...]@LIBC (2)
.......
  2710: 00077665    72 FUNC    GLOBAL DEFAULT   13 _ZNSt6__ndk19to_[...]
  2711: 0007bad5     4 FUNC    GLOBAL DEFAULT   13 _ZNSt13bad_excep[...]
  2712: 0009c198    12 OBJECT  WEAK   DEFAULT   17 _ZTINSt6__ndk117[...]
  2713: 00062dc5   392 FUNC    WEAK   DEFAULT   13 _ZNSt6__ndk19__n[...]
  2714: 00052035   196 FUNC    GLOBAL DEFAULT   13 _ZN8iocanary8IOC[...]
  2715: 0005ba8d    20 FUNC    WEAK   DEFAULT   13 _ZNSt6__ndk113ba[...]
  2716: 00076a0d    88 FUNC    WEAK   DEFAULT   13 _ZNSt6__ndk112ba[...]
```



### 重定位表（Relocation）

加载器(linker)在处理文件时，可能需要对某些内存地址（写死的绝对地址）进行修正。重定位表就是记录这些需要修正的地址。

每个需要重定位的代码段和数据段都会有一个重定位表。`.rel.dyn`对应`.dyn`段。

* offset（偏移量）：重定位入口的偏移量

```shell
重定位节 '.rel.dyn' at offset 0x3ae84 contains 3269 entries:
 偏移量     信息    类型              符号值      符号名称
0009bd70  00000017 R_ARM_RELATIVE   
.....
0009f6bc  00000c15 R_ARM_GLOB_DAT    00000000   __stack_chk_guard@LIBC
0009fa1c  00001515 R_ARM_GLOB_DAT    00000000   pthread_create@LIBC
0009f7d8  00001a15 R_ARM_GLOB_DAT    00000000   free@LIBC
0009fa04  00004b15 R_ARM_GLOB_DAT    00000000   strtoull@LIBC
0009fa00  00004c15 R_ARM_GLOB_DAT    00000000   strtoll@LIBC
0009f9f8  00005915 R_ARM_GLOB_DAT    00000000   __sF@LIBC
0009fa08  00005a15 R_ARM_GLOB_DAT    00000000   strtoimax@LIBC
0009fa0c  00005c15 R_ARM_GLOB_DAT    00000000   strtoumax@LIBC
0009c9d4  00008e02 R_ARM_ABS32       000727c5   _ZNSt6__ndk114__c[...]
0009cce0  00008f02 R_ARM_ABS32       00098cca   _ZTSNSt6__ndk17co[...]
0009c118  00009002 R_ARM_ABS32       0009c12c   _ZTINSt6__ndk126_[...]
0009bd84  00009102 R_ARM_ABS32       00048b3d   _ZNSt6__ndk119bas[...]
....
重定位节 '.rel.plt' at offset 0x414ac contains 1397 entries:
....
```

### GOT表（Global Offset Table）

> 全局偏移表
>
> 位于数据段

符号表和重定位表是满足编译和链接的重定位需求。而加载过程的重定位则有`GOT`和`PLT`来处理。

### PLT表（Procedure Linkage Table）

> 过程链接表，位于代码段。
>
> 每一天PLT记录都是一小段可执行代码。

为了满足动态链接的特性，使用的时候才链接（**懒加载**），引入了`PLT表`。即动态库首次加载时，所有的函数地址并没有被解析。



> **蹦床（Trampoline）**：外部代码首先会调用PLT中的记录，然后由PLT的相应记录会去调用实际的函数。

### GOT和PLT调用流程

* jmp：跳转到一个地址。
* push：将一个值放到栈中。即向最终调用的函数传递参数。
* PLT[0]：用于解析地址。

第一次函数调用时，若在GOT表中未找到对应地址，则会跳转回`jmp *GOT[n]`的下一条指令。然后顺序执行。

第一次函数调用后，动态加载器会将地址写入到GOT[n]中，后续将直接调用func，不再需要解析。

![GOT和PLT调用过程](./ELF%E6%96%87%E4%BB%B6.assets/GOT%E5%92%8CPLT%E8%B0%83%E7%94%A8%E8%BF%87%E7%A8%8B.png)

![img](./ELF%E6%96%87%E4%BB%B6.assets/8bacb98e41eaa8ed048294dbf42896c6.png)

## 参考资料

[13. readelf elf文件格式分析 — Linux Tools Quick Tutorial (linuxtools-rst.readthedocs.io)](https://linuxtools-rst.readthedocs.io/zh_CN/latest/tool/readelf.html)

[3.1 链接加载原理及elf文件格式_pwl999的博客-CSDN博客](https://blog.csdn.net/pwl999/article/details/78218935)

[ELF解析00_介绍_哔哩哔哩_bilibili-有7个视频，很详细](https://www.bilibili.com/video/BV1no4y1U7C6/?spm_id_from=333.999.0.0)

[理解elf文件的got和plt-软件逆向-看雪论坛-安全社区|安全招聘|bbs.pediy.com](https://bbs.pediy.com/thread-262255.htm)