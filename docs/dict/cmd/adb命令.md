# adb命令

标签（空格分隔）： cmd

[TOC]

---

## 设备相关

### adb服务开关
```shell
adb kill-server
adb start-server
```

### 设备连接
```shell
adb devices
adb -s <serial number> shell
```

打开signal开关

```shell
echo 1 > /d/tracing/events/signal/enable
echo 1 > /d/tracing/tracing_on

抓取tracing log
cat /d/tracing/trace_pipe
strace -CttTip 22829 -CttTip 22793
```

### 状态栏修改

隐藏虚拟键及顶部状态栏：

```
adb shell settings put global policy_control immersive.full=*
```

隐藏顶部状态栏（底部虚拟键会显示）

```
adb shell settings put global policy_control immersive.status=*
```

隐藏虚拟键（顶部状态栏会显示）

```
adb shell settings put global policy_control immersive.navigation=*
```

恢复原来的设置：

```
adb shell settings put global policy_control null
```

## 应用相关


### 启动应用
```
adb shell am start -W -n com.zaze.demo/.WelcomeActivity -S -a com.zaze.launcher -c android.intent.category.DEFAULT -f 0x10200000
```

### dumpsys
```
dumpsys -l  // 显示所有支持的services
dumpsys meminfo pkgxx
dumpsys cpuinfo pkgxx

adb shell dumpsys package   // 列出所有的安装应用的信息
adb shell dumpsys activity activities
```

### am

```bash
am set-debug-app -w com.xxxx
am set-debug-app -w -persitent xxxx
am clear-debug-app
adb shell am force-stop "com.zaze.demo"
```

### pm

```
pm list packages  // 列出所有的包名。
pm disable-user com.xxx // 禁用应用或者组件
pm disable com.xxx // 禁用应用或者组件
pm enable com.xxx // 启用应用或者组件
```


## 签名

使用**keytool**生成签名

```
keytool -genkey -v -keystore android.keystore -alias android -keyalg RSA -validity 20000 -keystore /Users/zaze/android_demo.keystore
keytool -list -v -keystore debug.keystore
```
使用**jarsigner**对apk进行签名


```
jarsigner -verbose -digestalg SHA1 -sigalg MD5withRSA -keystore /Users/zaze/Documents/ZAZE/android_zaze.keystore -storepass 123456 -signedjar your_signed.apk source.apk android
```

```
-f : 输出文件覆盖源文件
-v : 详细的输出log
-p : outfile.zip should use the same page alignment for all shared object files within infile.zip
-c : 检查当前APK是否已经执行过Align优化。另外上面的数字4是代表按照4字节（32位）边界对齐。
java -jar apksigner.jar sign    //执行签名操作
--ks ***                        //签名证书路径
--ks-key-alias ***              //生成jks/keystore时指定的alias
--ks-pass pass:***              //KeyStore密码
--key-pass pass:***             //签署者的密码，即生成jks时指定alias对应的密码
--out output.apk                //输出路径
input.apk                       //被签名的apk

apksigner sign -verbose --ks android_zaze.keystore --ks-key-alias android --out app-release-signed.apk app-release_protected.apk 

java -jar apksigner.jar sign  --ks ***  --ks-key-alias ***  --ks-pass pass:***  --key-pass pass:***  --out output.apk  input.apk  
```

查看签名文件信息

```
keytool -list -v -keystore android_zaze.keystore
```

查看apk签名信息

```
apksigner verify -v xxx.apk
```


---

## logcat 

```bash
adb logcat
adb -s sn logcat
```

```bash
>> adb shell
// 过滤筛选
>> logcat | grep ActivityManager 
```


## input

### input text 模拟输入
```bash
input text
```

### input keyevent 模拟事件
```bash
input keyevent 3    // Home
input keyevent 4    // Back
input keyevent 19   // Up
input keyevent 20   // Down
input keyevent 21   // Left
input keyevent 22   // Right
input keyevent 23   // Select/Ok
input keyevent 24   // Volume+
input keyevent 25   // Volume-
input keyevent 82   // Menu 菜单
```

### input tab 模拟触摸
```bash
input tab 600 800
```

### input swipe 模拟滑动

```bash
input swipe 666 888 666 666
```

## bootloader, recovery模式

```bash
adb reboot  // 重启
adb reboot recovery // 重启并进入recovery模式
adb reboot-bootloader   // 重启并进入bootloader模式
```



[1]: http://static.zybuluo.com/zaze/53kqp387aoy6xdxryh1yk2lx/image_1e07q1jt011rt165c3cs1ao91tsr9.png
[2]: http://static.zybuluo.com/zaze/k8cyxkqs5eq1eb7vk63zfodg/image_1e07q380o1gjlqe1t83o501218m.png