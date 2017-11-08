
# CMD 命令


## brew

安装``brew`` : ``ruby -e "$(curl -fsSL /homebrew/go)"``

```
brew deps *		# 列出软件包的依赖关系
brew info *		# 查看软件包信息
brew list		# 列出已安装的软件包
brew search *
brew install *
brew update	*		# 更新 Homebrew 的信息
brew outdated		# 看一下哪些软件可以升级
brew upgrade <xxx>	# 如果不是所有的都要升级，那就这样升级指定的
brew upgrade; brew cleanup    # 如果都要升级，直接升级完然后清理干净

```

## tomcat

- 搜索tomcat是否存在：
brew search tomcat
- 安装tomcat：
brew install tomcat
- 检查是否安装成功：
catalina -h
- 运行tomcat：
catalina run

## Android

###  查看当前正在运行的Activity

shell中输入：logcat | grep ActivityManager 真机运行应用，可以实时

cmd命令中输入：adb shell dumpsys activity activities

###  bootloader recovery

adb reboot recovery

adb reboot-bootloader

### 常用命令

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

```
logcat
logcat -d
logcat -c

```

[http://ghoulich.xninja.org/2015/12/08/android_logcat_manual/](http://ghoulich.xninja.org/2015/12/08/android_logcat_manual/ "Logcat")


## TCPSpeed

sudo java -jar ~/Documents/ZAZE/tcpspeed_client/tcpspeed_client.jar

## other

511536

636467