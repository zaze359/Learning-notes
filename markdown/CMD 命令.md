
# 常用命令

Tags : zazen

---

[TOC]

---

## Brew

安装``brew`` : ``ruby -e "$(curl -fsSL /homebrew/go)"``

```
brew deps *		# 列出软件包的依赖关系
brew info *		# 查看软件包信息
brew list		# 列出已安装的软件包
brew search *
brew install *
brew update	*		# 更新 Homebrew 的信息
brew outdated		# 看一下哪些软件可以升级
brew upgrade; brew cleanup    # 如果都要升级，直接升级完然后清理干净
brew upgrade <xxx>	# 如果不是所有的都要升级，那就这样升级指定的

```

## Tomcat

- 搜索tomcat是否存在：
``brew search tomcat``
- 安装tomcat：
``brew install tomcat``
- 检查是否安装成功：
``catalina -h``
- 运行tomcat：
``catalina run``

## Android

- 查看当前正在运行的Activity

`` logcat | grep ActivityManager``
真机运行应用，可以实时

``adb shell dumpsys activity activities``

``ps |grep -E 'com.zaze.demo|com.zaze.test'``

###  bootloader recovery

```
adb reboot recovery
adb reboot-bootloader
```
### 刷机
[Google原生固件包][1]
```
a
```

### root
[SuperSu][3]

```
- 下载APK
- 下载zip包
- 下载TWRP .img

```

### 12345

ifconfig en0

查看内核版本 ``cat /proc/version``


du -m    以m为单位查看大小
df	剩余空间

mount -o remount, rw /

### 查看进程

``ps``

``ps | grep packageName``

### keytool

```
keytool -genkey -v -keystore android.keystore -alias android -keyalg RSA -validity 20000 -keystore /Users/zaze/android_demo.keystore

keytool -list -v -keystore debug.keystore

```

### 日志

[Android的logcat日志工具使用详解][2]

```
logcat
logcat -d
logcat -c

```

## TCPSpeed

sudo java -jar ~/Documents/ZAZE/tcpspeed_client/tcpspeed_client.jar

## Other

### 显示隐藏文件

``ls -aF``



511536

636467







[1]: https://developers.google.com/android/nexus/images
[2]: http://ghoulich.xninja.org/2015/12/08/android_logcat_manual/
[3]: http://www.supersu.com/download