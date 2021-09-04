# Apk的反编译和重编译

Tags : zaze

---

[TOC]

---

## 反编译工具

- [jadx](https://github.com/skylot/jadx)
- apktools + dex2jar + [jd-gui](https://github.com/java-decompiler/jd-gui) 

## 手动反编译流程

### 1. 加载framework(可选)
此命令用于为 **apktool** 安装指定的 **framework-res.apk** 文件, 以方便进行反编译一些与ROM相互依赖的apk文件。
版本过旧时会导致打包加载资源等失败, 可从设备的 **/system/framework** 中获取。

```bash
apktool if framework-res.apk
## 上下等同
apktool install-framework framework-res.apk
```

### 2. decode
该命令用于进行反编译apk文件

```
apktool d <file.apk> -f -o <dir>
```

### 3. smali

- smali to dex
```
java -jar baksmali-2.0.2.jar outDir -o classes.dex
```

- odex to smail
```bash
java -jar baksmali-2.0.2.jar -x classes.odex -d framework
```

### 4. dex2jar

```
d2j-dex2jar classes.dex
```

## 修改后重新编译apk


### 1. rebuild apk
该命令用于编译修改好的文件
```
apktool b <dir>
```

### 2. sign apk

- 生成签名

```bash
keytool -genkey -v -keystore android.keystore -alias android -keyalg RSA -validity 20000 -keystore /Users/zaze/android_demo.keystore
```

- 对apk进行签名

```bash
jarsigner -verbose -digestalg SHA1 -sigalg MD5withRSA -keystore /Users/zaze/android_demo.keystore -storepass 123456 -signedjar your_signed.apk source_unsign.apk android
```

### 3. 一些可能用到指令

- keytool相关

```bash
## 查看keystore
keytool -list -v -keystore debug.keystore
## 查看CERT.RSA
keytool -printcert -file CERT.RSA
```

```
java -jar baksmali-2.0.2.jar -o outclasses14  out.dex
java -jar baksmali.jar -x classes.odex -d framework
```
- aapt

```
/Users/zaze/Library/Android/sdk/build-tools/21.1.1/aapt
aapt l -a xx.apk > demo.txt
```

- AXMLPrinter2

```
java -jar AXMLPrinter2.jar AndroidManifest.xml > AndroidManifest.txt
```
