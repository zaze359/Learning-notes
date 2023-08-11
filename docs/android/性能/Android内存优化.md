# Android内存优化

## 出现内存问题的表现形式

### 应用崩溃

* OOM崩溃。
* 内存分配失败崩溃。
* 内存不足导致应用进程被系统kill。
* 导致设备重启。

### 应用卡顿

* 内存不足导致频繁GC。
* 物理内存不足时系统会触发 low memory killer 机制。
* 系统负载过高。

---

## 常见内存问题

### 内存抖动

短时间内有大量的对象生成并频繁申请释放内存，内存分析图呈现锯齿状，例如使用了大量的临时变量。

由于STW 垃圾回收时会暂停其他所有的工作线程，频繁的GC 会导致App整体卡顿

### 内存泄露

堆中分配的内存由于某种原因无法释放，造成了内存的浪费，甚至导致发生OOM。

分析内存泄露的核心思想是可达性分析，通过获取 GC Roots 引用链 来判断是否发生了内存泄露。

发生内存泄露的条件：对象 **根可达** 且 **不会再被使用**。

例如 一个静态变量持有一个已经destroy 的 Activity，Activity已经销毁不可用了，但是会被一直持有。

处理内存泄露的方式就是找到泄露对象的引用链，然后想办法切断这个引用链。

> C++的内存泄露导致的问题会更加严重，因为它是直接本地内存中分配内存的，需要重启操作系统才能处理。而普通的Java内存泄露重启应用即可。

#### 常见场景

* 单例持有Context。改为使用 Application的Context。

* 没有及时的反注册
  * 网络访问
  * 广播
  * 属性动画：没有及时停止并移除监听导致泄露。被TLS中的AnimatorHandler 持有。
  * 定时器 Timer、TimerTask

* 使用了非静态内部
  * 匿名内部类Handler：持有外部的Activity，并且发送了消息，由于没有及时移除消息导致泄露。

* 资源未释放
  * Sqite 的 Cursor
  * IO流
  * WebView。WebView 中的各种 Callback 会持有Activity 引用，会导致 Activity未回收前 即使调用了 WebView.destroy()，WebView依然不会被回收，需要先将自己从父容器中移除。


#### 内存泄露检测

ReferenceQueue 和 WeakRefrence 结合使用 可以用于判断是否对象是否被GC回收。

* 当**弱引用所引用的对象被垃圾回收器回收时**，虚拟机 会把这个**弱引用加入到关联的引用队列中**。

```java
public class WeakReference<T> extends Reference<T> {
    // 关联一个 ReferenceQueue
    public WeakReference(T referent, ReferenceQueue<? super T> q) {
        super(referent, q);
    }
    
    // 当弱引用所引用的对象会回收时，会调用这个方法
    public boolean enqueue() {
        // 引用 置为空
        this.referent = null;
        // 将弱引用自身 加入到引用队列中。
        return this.queue.enqueue(this);
    }
}
```

模拟测试

* 存在弱引用：没有泄露。
* 不存在弱引用：发生泄露。

LeakCanary 也是基于这个特性， 来判断 引用队列中是否存在弱引用来检测是否发生了内存泄露。

```java
public class Reference {

    final WeakReference<Object> reference;

    // 当 WeakReference 所引用的对象被回收时 WeakReference会被加入这个队列中
    ReferenceQueue<Object> referenceQueue = new ReferenceQueue<>();
    
    Reference(Object obj) {
        this.reference = new WeakReference<>(obj, referenceQueue);
    }

    public static void main(String[] args) {
        Object obj = new Object();
        Reference reference = new Reference(obj);
        System.out.println("TestConst.reference.get 1: " + reference.reference.get()); // 有值
        // 去除强引用
        obj = null;
        System.gc();
        // 等待一下GC
        Thread.sleep(100)
        // null
        System.out.println("TestConst.reference.get 2: " + reference.reference.get());
        // true，队列中包含了 WeakReference
        System.out.println("TestConst.referenceQueue: " + (reference.referenceQueue.poll() == reference.reference));
    }
}

```

### 内存溢出

内存泄露导致内存被耗尽、加载大图等都可以导致发生OOM错误。



---

## low memory killer机制

> 物理内存不足时触发low memory killer机制，进程优先级如下：

![img](./Android%E5%86%85%E5%AD%98%E4%BC%98%E5%8C%96.assets/b8d160f8d487bcb377e0c38ff9a0ac98.png)



## 应用内存限制

| build.prop                  | 说明                                                         | 取值     |
| --------------------------- | ------------------------------------------------------------ | -------- |
| `dalvik.vm.heapstartsize`   | App启动时初始分配的内存大小。                                | 例如8m   |
| `dalvik.vm.heapgrowthlimit` | 单个进程最大内存限制。获取代码：`ActivityManager.getMemoryClass()` | 例如192m |
| `dalvik.vm.heapsize`        | App开启 `android:largeHeap="true"` 后的最大内存限制<br />获取代码：`ActivityManager.getLargeMemoryClass()` | 例如512m |

> android:largeHeap 这个属性一般用于存在大内存的图片或视频的应用。正常情况下不必开启，而应该考虑优化内存。

```shell
adb shell getprop
```

---



## 客户端内存监控

### Hprof 收集

由于 dump 操作比较耗时，一般采用子进程执行dump生成 堆转储文件，主进程通过 FileObsever 方式来监听结果

* 挂起虚拟机 拷贝主进程的中线程。通过native hook 实现`suspend` 。
* fork 子进程，子进程开始 dump 收集信息，并写入到一个 hprof 文件中。
* 恢复虚拟机。通过native hook 实现`resume` 。
* 主进程通过 FileObsever  监听 hprof 文件。

### 线下GC监控

可以使用 `Debug` 类获取GC的情况：

```java
// GC次数
Debug.getRuntimeStat("art.gc.gc-count");
// GC使用的总耗时/ms
Debug.getRuntimeStat("art.gc.gc-time");


// 阻塞式GC的次数
Debug.getRuntimeStat("art.gc.blocking-gc-count");
// 阻塞式GC的总耗时
Debug.getRuntimeStat("art.gc.blocking-gc-time");
```



---

## 图片内存

### Bitmap存储位置

| Android版本 | Bitmap内存存放位置                              | 备注                                                     |
| ----------- | ----------------------------------------------- | -------------------------------------------------------- |
| 3.0 -       | 对象存放在Java堆， 像素数据是放在 Native 内存。 | Bitmap Native 内存的完全依赖 finalize 函数，时机不可控。 |
| 3.0 ~ 8.0 - | 对象和像素数据统一存放在Java堆。                | 占用大量堆内存，导致频繁GC甚至OOM。                      |
| 8.0 +       | 对象存放在Java堆， 像素数据是放在 Native 内存。 | 利用NativeAllocationRegistry辅助回收Native内存           |



### bitmap内存大小

| 格式      | 每个像素内存大小 |                                         |
| --------- | ---------------- | --------------------------------------- |
| ALPHA_8   | 1byte = 8bit     | 只有8位的透明通道                       |
| ARGB_8888 | 4byte = 32bit    | 每个通道8位。                           |
| ARGB_4444 | 2byte = 16bit    | 每个通道4位。质量较差，已经不推荐使用。 |
| RGB_565   | 2byte = 16bit    | 没有透明通道。                          |
| RGBA_F16  | 8byte = 64bit    |                                         |

#### 直接获取

Bitmap 提供了 以下两种方式获取：

```java
// bitmap 中实际图片像素占用大小。
public final int getByteCount()
// bitmap 已分配内存大小，>= bytecount
public final int getAllocationByteCount()
```

正常情况下面两个函数相同，发生复用时则不同。

例如先使用大图，申请了 500kb，然后复用bitmap 放一个 100kb小图。

* getAllocationByteCount = 500kb
* getByteCount = 100kb

#### 手动计算

计算公式：**图片转换后的分辨率 * 每个像素内存大小**。

例如 图片转换后的分辨率 ：1920 x 1080；格式：ARGB_8888。

`1920 * 1080 * 4 = 8294400 byte`。

> 注意：这里是图片转换后的分辨率，不同于图片原始分辨率，从资源目录加载的图片会受到 设备的 dpi 和 资源目录的影响。
>
> 我们调用 `Bitmap.decodeResource()` 时，Android已经帮我们根据不同的来源进行了分辨率转换：**原图片分辨率 * (设备dpi /  资源目录dpi)**。
>
> * 同一张图在 设备dpi越高的设备，占用的内存越大。图片会被放大。
> * 将同一张图放到低分辨率资源目录 会比 放在高分辨率资源目录 占用更大的内存。图片会被放大。
>
> 文件、网络中获取的图片 分辨率不受影响，部分三方库会特殊处理成原图分辨率，所以也不受影响。



### 压缩优化

* 质量压缩：改变的是存储的大小，不影响加载到内存的大小。适用于图片上传
* 尺寸压缩：可以改变内存中的大小，适用于加载大图、生成缩略图

#### 质量压缩

有损压缩，通过算法优化像素点，将某些点附加相近的像素点同化。改变的是位深和透明度，尺寸不变。

* **改变的是存储的大小**，不影响加载到内存的大小。
* 适用于**图片上传、下载**。

`Bitmap.compress()` 这个函数可以实现质量压缩，还可以用来格式转换。

```java
/**
 * @param format   压缩格式；png > jpeg > webp
 * @param quality  压缩率 0 ~ 100。100表示不压缩。 png是无损压缩，所以这个属性对它无效。
 * @param stream   输出流，输出压缩后的数据
 * @return true if successfully compressed to the specified stream.
 */
public boolean compress(CompressFormat format, int quality, OutputStream stream)
```

#### 尺寸压缩

按照一定倍数对图片减少单位尺寸的像素值。

* **可以改变内存大小**。
* 常用于**加载大图、 生成缩略图**。

`BitmapFactory.Options`

| 重要属性           |                                                              |      |
| ------------------ | ------------------------------------------------------------ | ---- |
| inJustDecodeBounds | true 表示此次decode不分配内存，仅获取图片的信息。处理大图时可以先设置true。 |      |
| outWidth/outHeight | 图片原始宽高。                                               |      |
| inSampleSize       | 采样率，**生成缩放到指定尺寸的 bitmap**；取值是最好是 2的幂次，最小为1，例如2 表示宽高都缩小到 1/2，整体缩小到 1/4 |      |
|                    |                                                              |      |

尺寸压缩流程：

* 创建 BitmapFactory.Options，并设置 `inJustDecodeBounds = true` 加载图片的原始信息。
* 获取到原始宽高后根据业务需求计算出 采样率，并赋值给 inSampleSize。
* 更新 `inJustDecodeBounds = false`，重新加载图片。

```kotlin
fun decodeToBitmap(
        width: Int,
        height: Int,
        onDecode: (BitmapFactory.Options?) -> Bitmap
    ): Bitmap {
        if (width <= 0 || height <= 0) { // 不缩放，直接解码
            return onDecode(null)
        }
        val options = BitmapFactory.Options().apply {
            // 设置false，先获取原始宽高
            inJustDecodeBounds = true
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }
        // 第一次 decode，获取宽高。
        onDecode(options)
        options.apply {
            // 置为 false ，需要加载
            inJustDecodeBounds = false
            if (outWidth == 0 || outHeight == 0) {
                outWidth = width
                outHeight = height
            } else {
                // 仅当 宽高 都比 需求的尺寸大时 才缩放
                // 保证 inSampleSize 的取值是 2的幂次
                // 防止缩太小 需要进行拉伸。
                var (tempWidth: Int, tempHeight: Int) = outWidth to outHeight
                while (tempHeight > height && tempWidth > width) {
                    inSampleSize *= 2
                    tempWidth /= 2
                    tempHeight /= 2
                }
            }
        }
    	// 第二次解码，真正加载图片
        return onDecode(options)
    }
```

### 自定义 libjpeg 压缩图片

Android 是基于 skia 引擎，skia 使用了 libjpeg编解码库，我们调用的 bitmap 压缩API 最终通过 libjpeg 来进行压缩的，但是早期由于手机性能较弱，哈夫曼编码又很耗费CPU，所有采用定长编码算法来替代哈夫曼编码。不过在高版本中 skia 引擎已经开启了 哈夫曼编码。

`libjpeg-turbo` 是 `libjpeg`的增强库，使用SIMD指令加速，速度更快。可以通过libjpeg 来实现哈夫曼编码算法进行解压缩。

> 微信 基于  `libjpeg`  自己实现了一套图片的压缩 。

##### libjpeg-turbo编译

源码下载：[libjpeg-turbo/libjpeg-turbo: Main libjpeg-turbo repository (github.com)](https://github.com/libjpeg-turbo/libjpeg-turbo)

cmake-gui下载：[Download | CMake](https://cmake.org/download/)

可以使用 Android Studio 进行编译。

1. 创建一个 Native C++ Project，然后拷贝源码到 cpp 目录下。

2. 关联 源码中的 CMakeLists.txt文件，配置平台架构

```kotlin
android {
    compileSdk = libs.versions.compileSdk.get().toInt()
    defaultConfig {
        minSdk = libs.versions.minSdk.get().toInt()
        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++11"
            }
            ndk {
                // 'x86', 'x86_64', 'armeabi', 'armeabi-v7a', 'arm64-v8a'
                abiFilters.add("x86")
            }
        }
    }
    
    ndkVersion = "16.1.4479499"
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/libjpeg-turbo/CMakeLists.txt")
            version = "3.22.1"
        }
    }
}
```

直接编译项目即可获取到so。可以从以下几个目录中拷贝，根据 debug还是release 来选择。

* `build/intermediates/stripped_native_libs/debug`：合并了所有依赖。
* `build/intermediates/merged_native_libs/debug`：去除了符号。
* `.cxx/Debug/编译标识ID/`

![image-20230801234534713](./../../private/%25E4%25B8%25B4%25E6%2597%25B6%25E7%25AC%2594%25E8%25AE%25B0.assets/image-20230801234534713.png)![image-20230801234548271](./Android%E5%86%85%E5%AD%98%E4%BC%98%E5%8C%96.assets/image-20230801234548271.png)



### 重复Bitmap对象检测

指Bitmap像素数据完全一致，但是却存在多个不同对象。

主要是 针对Android 8.0前（< 26）的设备，此时Bitmap的内存数据保存在堆中，而8.0+ 开始bitmap的内存数据保存到了Native 内存中，导致无法获取到 mBuffer。

检测思路：

1. 通过 `Debug.dumpHprofData(filePaht)` 生成 堆转储 hprof 文件。
2. 使用 hprof 分析库分析 文件。例如 sqaure 的  HAHA 库。
3. 解析获取到所有的bitmap实例。
4. 计算 bitmap 的 内存数据 `mBuffer` 的 hashcode。若hashcode相同则认为存在重复对象。

---

## 参考资料

[03 | 内存优化（上）：4GB内存时代，再谈内存优化 (geekbang.org)](https://time.geekbang.org/column/article/71277)

[系统跟踪概览  | Android 开发者  | Android Developers](https://developer.android.com/topic/performance/tracing)
