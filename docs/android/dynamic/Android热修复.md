# Android热修复



## 基于类加载实现热修复

* 修改 `DexPathList.dexElements` ，将修复文件放在最前面。

## 简易调试流程

### dex命令位置

``../Android/sdk/build-tools/xxxx/dx``

### 1. 打包jar

``jar cvf path.jar ydc/hotfix/BugClass.class``


### 2. 做成补丁包path_dex.jar


再把path.jar做成补丁包path_dex.jar，只有通过dex工具打包而成的文件才能被Android虚拟机(dexopt)执行。
依然在该路径下执行以下命令:

``dx --dex --output=path_dex.jar path.jar``


### 3. 拷贝path_dex

我们把path_dex文件拷贝到assets目录下


### 4. 应用补丁

- 创建一个私有目录，并把补丁包文件写入到该目录下， 模拟下载
- 合并数组dexElements
