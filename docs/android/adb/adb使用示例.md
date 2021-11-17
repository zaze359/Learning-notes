# adb命令示例

## 常用指令表摘录

> 可直接在iterm中输入``adb``查看
>
> ``adb shell`` 连接到指定设备后, shell下支持的相关命令将不需要再带 ``adb``、``adb shell``相关前缀。
>
> 此处仅记录部分常用指令:

| 指令                                      | 备注                                               |
| ----------------------------------------- | -------------------------------------------------- |
| adb nodaemon server                       | 查看adb                                            |
|                                           |                                                    |
| adb kill-server                           | 关闭adb server                                     |
| adb start-server                          | 启动adb server                                     |
| adb devices -l                            | 查看当前连接设备。 -l 显示更多信息                 |
| adb -s [serial number] shell              | 以shell方式连接到指定 serial number 的设备         |
| adb tcpip [PORT]                          | 设置Android设备监听adb的端口                       |
| adb connect HOST[:PORT]                   | connect to a device via TCP/IP [default port=5555] |
| adb disconnect [HOST[:PORT]]              | 断开连接, 不指定时全部关闭                         |
|                                           |                                                    |
| adb install [-lrtsdg] [--instant] PACKAGE | 安装应用。 本地测试包指定 -t                       |
| adb uninstall [-k] PACKAGE                | 卸载应用。 -k 保留数据                             |
|                                           |                                                    |
| adb reboot recovery                       | 重启并进入recovery mode                            |
| adb reboot-bootloader                     | 重启并进入bootloader                               |
|                                           |                                                    |

## 通过命令操作设备

### 打开signal开关

```shell
echo 1 > /d/tracing/events/signal/enable
echo 1 > /d/tracing/tracing_on

抓取tracing log
cat /d/tracing/trace_pipe
strace -CttTip 22829 -CttTip 22793
```

### 控制虚拟键及顶部状态栏

隐藏虚拟键及顶部状态栏:

```
settings put global policy_control immersive.full=*
```

只隐藏顶部状态栏, 底部虚拟键会显示:

```
settings put global policy_control immersive.status=*
```

隐藏虚拟键, 顶部状态栏会显示:

```
settings put global policy_control immersive.navigation=*
```

恢复原来的设置:

```
settings put global policy_control null
```





## 应用相关

### dumpsys
```bash
dumpsys -l  // 显示所有支持的services
dumpsys meminfo pkgxx
dumpsys cpuinfo pkgxx

dumpsys package   // 列出所有的安装应用的信息
dumpsys activity activities
```

### am

```bash
am set-debug-app -w com.xxxx
am set-debug-app -w -persitent xxxx
am clear-debug-app
am force-stop "com.zaze.demo"

# 启动应用
am start -W -n com.zaze.demo/.WelcomeActivity -S -a com.zaze.launcher -c android.intent.category.DEFAULT -f 0x10200000
# 启动浏览器并打开指定页面
adb shell am start -a android.intent.action.VIEW -d "http://www.bilibili.com"
```

### pm

```
pm list packages  // 列出所有的包名。
pm disable-user com.xxx // 禁用应用或者组件
pm disable com.xxx // 禁用应用或者组件
pm enable com.xxx // 启用应用或者组件
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



## cmd

```bash
cmd statusbar expand-notifications
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
input keyevent 187 	// KEYCODE_APP_SWITCH
```

### input tab 模拟触摸
```bash
input tab 600 800
```

### input swipe 模拟滑动

```bash
input swipe 666 888 666 666
```



## statusbar



```
# 查看帮助
cmd statusbar help

```





## bootloader, recovery模式

```bash
adb reboot  // 重启
adb reboot recovery // 重启并进入recovery模式
adb reboot-bootloader   // 重启并进入bootloader模式
```



[1]: http://static.zybuluo.com/zaze/53kqp387aoy6xdxryh1yk2lx/image_1e07q1jt011rt165c3cs1ao91tsr9.png
[2]: http://static.zybuluo.com/zaze/k8cyxkqs5eq1eb7vk63zfodg/image_1e07q380o1gjlqe1t83o501218m.png