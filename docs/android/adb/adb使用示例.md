# adb命令示例

## 常用指令表摘录

> 可直接在iterm中输入``adb``查看
>
> ``adb shell`` 连接到指定设备后, shell下支持的相关命令将不需要再带 ``adb shell``相关前缀。
>
> 此处仅记录部分常用指令:

| 指令                                          | 备注                                               |
| --------------------------------------------- | -------------------------------------------------- |
| ``adb nodaemon server``                       | 查看adb                                            |
| -                                             |                                                    |
| ``adb kill-server``                           | 关闭adb server                                     |
| ``adb start-server``                          | 启动adb server                                     |
| ``adb devices -l``                            | 查看当前连接设备。 -l 显示更多信息                 |
| ``adb -s [serial number] shell``              | 以shell方式连接到指定 serial number 的设备         |
| ``adb tcpip [PORT]``                          | 设置Android设备 监听adb的端口                      |
| ``adb connect HOST[:PORT]``                   | connect to a device via TCP/IP [default port=5555] |
| `adb forward tcp:PORT tcp:PORT`               | 端口转发                                           |
| ``adb disconnect [HOST[:PORT]]``              | 断开连接, 不指定时全部关闭                         |
| -                                             |                                                    |
| ``adb install [-lrtsdg] [--instant] PACKAGE`` | 安装应用。 本地测试包指定 -t                       |
| ``adb uninstall [-k] PACKAGE``                | 卸载应用。 -k 保留数据                             |
| -                                             |                                                    |
| ``adb reboot recovery``                       | 重启并进入recovery mode                            |
| ``adb reboot-bootloader``                     | 重启并进入bootloader                               |
| -                                             |                                                    |
| ``adb shell``                                 | 已Shell方式访问Android 设备                        |
| ``adb wait-for-device``                       | 阻塞等待，直到连接上一个设备                       |



## 通过命令操作设备

以下命令都是在Android设备shell下执行。即先调用 `adb shell`  访问设备。PC下添加 `adb shell` 前缀即可。

### dumpsys
```bash
# 显示所有支持的services
dumpsys -l
dumpsys meminfo pkgxx
dumpsys cpuinfo pkgxx


# 列出所有的安装应用的信息
dumpsys package
# 
dumpsys activity activities
#
dumpsys activity services
```

### am

```bash
am set-debug-app -w com.xxxx
am set-debug-app -w -persitent xxxx
am clear-debug-app

# 强制关闭应用进程
am force-stop "com.zaze.demo"

# 启动应用
am start -W -n com.zaze.demo/.WelcomeActivity -S -a com.zaze.launcher -c android.intent.category.DEFAULT -f 0x10200000
# 启动浏览器并打开指定页面
adb shell am start -a android.intent.action.VIEW -d "http://www.bilibili.com"
```

### pm

```shell
# 列出所有的包名 系统：-s  三方: -3
pm list packages
# 禁用应用或者组件
pm disable-user com.xxx
# 禁用应用或者组件
pm disable com.xxx

# 启用应用或者组件
pm enable com.xxx
```

---

### logcat

```shell
adb logcat
adb -s sn logcat
```

```shell
adb shell
# 过滤筛选
logcat | grep ActivityManager 
```



### cmd

```bash
cmd statusbar expand-notifications
```



### input

#### input text 模拟输入
```bash
input text abcd
```

#### input keyevent 模拟事件
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

| Key                | code |                                    |
| ------------------ | ---- | ---------------------------------- |
| Home               | 3    |                                    |
| Back               | 4    |                                    |
| -                  |      |                                    |
| Up                 | 19   | 上移（类似遥控器的效果）           |
| Down               | 20   | 下移                               |
| Left               | 21   |                                    |
| Right              | 22   |                                    |
| Select/Ok          | 23   | 选中、确定                         |
| -                  |      |                                    |
| Volume+            | 24   |                                    |
| Volume-            | 25   |                                    |
| -                  |      |                                    |
| Menu 菜单          | 82   | 打开当前页面的菜单（没有就不生效） |
| KEYCODE_APP_SWITCH | 187  | 最近任务栈                         |



#### input tab 模拟触摸
```bash
# x, y
input tap 600 800
```

#### input swipe 模拟滑动

```bash
# x, y >> toX, toY
input swipe 666 888 666 666
```



### statusbar

```
# 查看帮助
cmd statusbar help
```

### bootloader, recovery模式

```shell
# 重启
adb reboot
# 重启并进入recovery模式，还原页，恢复出厂设置、刷机等。
adb reboot recovery
# 重启并进入bootloader模式，刷机用
adb reboot-bootloader
```



### 修改分辨率

```shell
adb shell wm size 768x1024
# 还原
adb shell wm size reset
```



### 打开signal开关

```shell
echo 1 > /d/tracing/events/signal/enable
echo 1 > /d/tracing/tracing_on

# 抓取tracing log
cat /d/tracing/trace_pipe
strace -CttTip 22829 -CttTip 22793
```

### 控制虚拟键及顶部状态栏

隐藏虚拟键及顶部状态栏:

```shell
settings put global policy_control immersive.full=*
```

只隐藏顶部状态栏, 底部虚拟键会显示:

```shell
settings put global policy_control immersive.status=*
```

隐藏虚拟键, 顶部状态栏会显示:

```shell
settings put global policy_control immersive.navigation=*
```

恢复原来的设置:

```shell
settings put global policy_control null
```

## 开源项目

[mzlogin/awesome-adb: ADB Usage Complete / ADB 用法大全 (github.com)](https://github.com/mzlogin/awesome-adb)



[1]: http://static.zybuluo.com/zaze/53kqp387aoy6xdxryh1yk2lx/image_1e07q1jt011rt165c3cs1ao91tsr9.png
[2]: http://static.zybuluo.com/zaze/k8cyxkqs5eq1eb7vk63zfodg/image_1e07q380o1gjlqe1t83o501218m.png