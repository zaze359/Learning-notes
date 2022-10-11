# Android性能分析

## dmtracedump

1. 使用 Android Studio 自带的Android Profiler查看

```
绿色: 线程处于活动状态或准备好使用CPU。也就是说，它处于”运行”或”可运行”状态。
黄色： 线程处于活动状态，但是在完成其工作之前，它正在等待I / O操作（如文件或网络I / O）。
灰色： 线程正在睡眠，不会消耗任何CPU时间，当线程需要访问尚未可用的资源时，有时会发生这种情况。要么线程进入自愿性睡眠，要么内核使线程休眠，直到所需的资源可用。
```
2. 使用 Android Device Monitor
3. 代码接入，分析

### 接入方式

```java
	@Override
    protected void onCreate(Bundle savedInstanceState) {
    	// 默认输出 /sdcard/Android/data/com.xx.xx/files/dmtrace.trace
        Debug.startMethodTracing();
        // 变更输出到 /sdcard/dmtrace.trace
        // Debug.startMethodTracing("dmtrace"); 
        super.onCreate(savedInstanceState);
        ....
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Debug.stopMethodTracing();
    }
```


### 查看dmtrace.trace文件

- 拷贝到电脑上
``adb pull /sdcard/Android/data/com.xx.xx/files .``

- 将dmtrace.trace转换成html输出
``dmtracedump -h dmtrace.trace > aa.html``

## UI渲染性能测量

### 指令输出

#### gfxinfo

```shell
# 输出包含各阶段发生的动画以及帧相关的性能信息
adb shell dumpsys gfxinfo 包名
# 获取最近120 帧每个绘制阶段的耗时信息
adb shell dumpsys gfxinfo 包名 framestats
```

#### SurfaceFlinger

```shell
# 拿到系统 SurfaceFlinger 相关的信息：Graphic Buffer内存的占用情况
adb shell dumpsys SurfaceFlinger
```

## Perfetto

[perfetto  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/studio/command-line/perfetto?hl=zh_cn)

### 抓取方式

> 直接跳转到设置中的页面操作跟踪

```
adb shell am start com.android.traceur/com.android.traceur.MainActivity
```

> 命令行方式

```
adb shell perfetto --config CONFIG-FIle --out FILE
```



## 将trace文件导入到perfetto中

打开https://ui.perfetto.dev/网页。选择`Open trace file`。
