# NativeCrash分析

[TOC]

## 崩溃信号参考

[siginfo_t -- data structure containing signal information (mkssoftware.com)](https://www.mkssoftware.com/docs/man5/siginfo_t.5.asp)

## 分析工具

### objdump
查看编译后的文件都组成。

1. 查找objdump文件位置

```bash
find ~/Library/Android/sdk/ndk -name "*objdump"
```

2. 指令介绍

```
# 查看所以指令
--help
# 显示输出汇编内容
arm-linux-androideabi/bin/objdump -d libmmkv.so > libmmkv.txt
```

### addr2line

将指令的地址和可执行映像转换成文件名、函数名和源代码行数的工具。
适用于debug版本或带有symbol信息的库。

1. 查找addr2line文件位置

   ```bash
   find ~/Library/Android/sdk/ndk -name "arm-linux-androideabi-addr2line"
   find ~/Library/Android/sdk/ndk -name "aarch64-linux-android-addr2line"
   ```
 
2. 指令介绍

   ```bash
   # 查看所以指令
   --help
   # 
   arm-linux-androideabi-addr2line -C -f -e libmmkv.so 0000b66c
   ```

    

