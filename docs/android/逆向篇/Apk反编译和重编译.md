# Apk

# 反编译和重编译

Tags : zaze

---

[TOC]

---

## 反编译工具

- [jadx](https://github.com/skylot/jadx)
- [apktool](https://ibotpeaches.github.io/Apktool/ ) + [dex2jar](https://github.com/pxb1988/dex2jar/releases) + [jd-gui](https://github.com/java-decompiler/jd-gui) 

## 手动反编译流程

### 1. 加载framework(可选)
此命令用于为 **apktool** 安装指定的`framework-res.apk` 文件, 以方便进行反编译一些与ROM相互依赖的apk文件。
版本过旧时会导致打包加载资源等失败, 可从设备的`/system/framework` 中获取。

```shell
apktool if framework-res.apk
## 上下等同
apktool install-framework framework-res.apk
# 清空framework
apktool empty-framework-dir
```

### 2. 反编译apk文件
该命令用于进行反编译apk文件

```shell
apktool d <file.apk> -f -o outdir
# 不解压资源
apktool d <file.apk> -r -o outdir
```

反编译目录说明

| 目录                  | 说明                 | 备注                                                         |
| :-------------------- | :------------------- | :----------------------------------------------------------- |
| res                   | 资源文件             |                                                              |
| res\values\public.xml | 对外暴露资源。       | 指明了资源ID、资源类型、资源名间的关系。保持住资源ID，防止重编译时发生变化 |
| smali                 | 程序所有的反汇编代码 |                                                              |
| AndroidManifest.xml   |                      |                                                              |
| apktool.yml           |                      |                                                              |

## 修改APK

手动修改smail文件，修改资源，重新打包。

### smali

- smali to dex
```shell
java -jar baksmali-2.0.2.jar outDir -o classes.dex
```

- odex to smail
```shell
java -jar baksmali-2.0.2.jar -x classes.odex -d framework
```

### dex2jar

```shell
d2j-dex2jar classes.dex
```

## 重新编译apk

该命令用于编译修改好的文件
```shell
# 为之前反编译时的outdir目录
apktool b outdir -o new.apk
# jar
java -jar apktool.jar b outdir
```

## apk对齐

Android11以上apk需要4字节对齐。

使用sdk自带的`zipalign`对齐。

```shell
# 对齐
zipalign -p -f -v 4 xx.apk aligned.apk

# 确认对齐
zipalign -c -v 4 aligned.apk
```

### apk签名

>  对齐后使用apksigner

[APK手动签名参考文档](./APK手动签名参考.md)

### 一些可能用到指令

```shell
java -jar baksmali-2.0.2.jar -o outclasses14  out.dex
java -jar baksmali.jar -x classes.odex -d framework
```
- aapt

```shell
/Users/zaze/Library/Android/sdk/build-tools/21.1.1/aapt
aapt l -a xx.apk > demo.txt
```

- AXMLPrinter2

```shell
java -jar AXMLPrinter2.jar AndroidManifest.xml > AndroidManifest.txt
```
