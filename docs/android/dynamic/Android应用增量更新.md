# Android应用增量更新

核心：基于BSDiff差量算法，比较两个版本APK间的差异，生成Patch包，客户端根据已安装apk和patch包直接组装成新的apk包进行安装。

## 下载

### bsdiffs

[官网：Binary diff (daemonology.net)](http://www.daemonology.net/bsdiff/)：无法下载了

[Github：Releases · mendsley/bsdiff (github.com)](https://github.com/mendsley/bsdiff)

[bsdiff for windows (pokorra.de)](https://www.pokorra.de/coding/bsdiff.html)

### bzip2

bsdiff 使用 bzip2 来解压缩数据。

[Downloads – bzip2](http://www.bzip.org/downloads.html)

[bzip2 download | SourceForge.net](https://sourceforge.net/projects/bzip2/)

## 编译

将 bsdiff 和  bzip 源码导入到Android Studio中，使用cmakelists.txt进行配置和编译。

## 使用

```shell
# 生成差异文件命令
bsdiff [old] [new] [patch]
# 合并文件命令
bspatch [old] [new] [patch]
```

