# Android的图形架构

## 基础概念

| 概念                     | 说明                                 | 备注                                                         |
| ------------------------ | ------------------------------------ | ------------------------------------------------------------ |
| CPU                      | 擅长逻辑运算                         | 控制器复杂，算术逻辑单元ALU（Arithmetic Logic Unit）较少，   |
| GPU                      | 擅长大量的数学运算，适合图形渲染     | 控制器较简单，但是包含大量ALU。                              |
| diaplay                  | 显示设备                             | 从缓冲区读取数据并显示。                                     |
| -                        |                                      |                                                              |
| OpenGL                   | 底层图形库，是操作GPU的API           | 定义了一个跨编程语言、跨平台的编程接口规格的专业的图形程序接口。适用于3D/2D。 |
| OpenGL ES（GLES）        | OpenGL 的嵌入式版                    | OpenGL 的API子集。功耗更低                                   |
| EGL                      | EGL是渲染API和原生窗口系统之间的接口 | 作为OpenGL和原生窗口系统之间的桥梁。                         |
| HWC（Hardware Composer） | 硬件合成器                           | 硬件合成器，是控制器系统的硬件抽象，减轻GPU的负载。          |
| -                        |                                      |                                                              |
| Texture                  | 纹理                                 | 纹理是应用于 Surface 的**图像或照片**，可以改变它的颜色、光泽或其外观的任何其他部分。 |
| Shader                   | 着色器                               | 一种通过即时演算 生成贴图的程序。                            |
| Material                 | 材质                                 | 本质是一组供渲染器读取的数据集。包含贴图纹理、shader等       |
| -                        |                                      |                                                              |
| Skia                     | 软件绘制引擎                         | CPU绘制2D图形，skia也可调用OpenGL实现3D效果。                |
| Surface                  | 图像流生产方                         | 进行绘制和渲染的地方。                                       |
| Graphic Buffer           | 装载栅格化的绘制内容                 | Android 4.1 之前使用的是 双缓冲机制；Android 4.1之后使用的是 三缓冲机制。 |
| SurfaceFlinger           | 图像流消耗方                         | 使用 OpenGL 和 Hardware Composer 来合成一组 Surface，然后发送给屏幕 |

### 屏幕刷新率

> 指一秒内屏幕刷新的次数，即表示一秒内能**显示多少帧图像**。

` 屏幕刷新率 = 60Hz`：表示一秒内设备刷新了60次，每一帧大约为16.6ms。

### 帧率

> 指一秒内GPU能**生成多少画面**。
>

`帧率 = 300fps`：表示一秒能生成300幅画面。

帧率 和 屏幕刷新率的区别：

* **帧率**是指**生成**。

* **屏幕刷新率**是**显示**。



### 垂直同步（VSYNC）

> 垂直同步 ： Vertical Synchronization（VSYNC）
>
> 每次屏幕刷新都会发送一个VSYNC信号，通知系统屏幕开始刷新。
>
> 即当设备刷新频率是 60Hz时，VSYNC信号大约16.6ms发送一次。
>
> 如何不产生画面撕裂（tearing）：**保证帧数据的完整性 **和 **保证显示过程数据不发生变化**。
>

VSYNC 强制了 帧率 和 屏幕刷新率 保持同步：

* 即使帧数据已准备完毕，也要等到 VSYNC 信号时才使用准备好的帧数据。
* 只有帧数据准备完成且收到 VSYNC 才能用于显示。未处理完则当前帧依然展示之前的数据（保证数据完整性）。

在Android中收到 VSYNC 将执行以下操作：

* Android4.1之前：只用在最后缓冲区切换的显示阶段，防止画面撕裂。

* Android4.1之后增加：CPU/GPU 会立即**准备下一帧数据**，协调UI的绘制，依赖同步屏障机制，优先处理UI。

⚠️**垂直同步导致的问题**：垂直同步解决了画面撕裂的问题，但也导致了性能下降的问题。

* **帧数下降**：GPU性能再高也会被同步成屏幕刷新率。且在低性能下帧数将进一步降低。例如当设备的GPU性能比较低下，需要1.5个 VSYNC 周期才能处理完成，但是由于垂直同步机制，我们要等待到第下一个 VSYNC 信号才输出，导致理论上的40帧 变成了实际的30帧，本就不高的帧数将进一步降低。
* **延迟**：开启垂直同步期间，GPU已准备好数据后将不再工作，即使周期内剩余的时间够再处理一帧数据，也将等待VSYNC后才准备下一帧。但我们的操作是连续的，所以产生了延迟。



### 多缓冲机制

> 双缓冲、三缓冲等机制主要是为了提升性能。
>
> 缓冲区是按需分配的：
>
> Back Buffer 不一定存在：帧率和刷新率完全一致时不存在并发读写问题，此时单缓冲就够用。当帧率和刷新率不同时才需要创建 Back Buffer 。（大多数情况双缓冲即可）
>
> Triple Buffer 也是在需要时才会创建：由于GPU处理太慢而导致发生掉帧。

#### 单缓冲机制

> 仅一个`Frame Buffer`

**工作流程：**

CPU/GPU准备数据并往buffer中写, display读取帧数据并逐行显示。

**单缓冲画面撕裂（tearing）问题**：

> `tearing`：屏幕内显示的数据来自多个不同帧，画面出现撕裂感。 

出现的原因可以归类为**并发读写问题**，所以通过**垂直同步使两边频率保持一致从而避免了并发问题，解决了画面撕裂**。

当仅有一个帧缓冲区且无垂直同步时，由于 CPU/GPU 随时可能往buffer中写数据，因此可能出现以下两种情况：

* **显示器显示过程中数据发生变化**：当A帧尚未完全显示在屏幕上，下一帧数据B帧数据却已准备完毕并被写入了 buffer 中覆盖了A帧数据，接着显示器上之前未显示的部分将会显示B帧。结果就是**上面是A帧数据下面是B帧数据，画面出现撕裂感**。
* **帧数据尚未准备完毕**：当前帧数据尚未处理完成被显示器读取并显示，此时也将产生撕裂。

**单缓冲 + VSYNC的性能下降问题:**

> 使用 单缓冲 + VSYNC 处理画面撕裂问题，但是却会导致性能降低。

CPU/GPU的写 需要等待 显示器完成读取和显示，变成了完全的单线程模式，降低了整体性能。所以为了优化性能出现了`双缓冲技术，将读写分离提高了性能，同时保证数据完整性也降低tearing的出现`。

![img](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/30a45ebce7f0995f2f900d67852e028e.png)

#### 双缓冲机制

> Back Buffer：用于绘制；
>
> Front Buffer：用于显示；
>
> 双缓冲使得 读写分离，保证数据完整性的同时也提高了性能，一定程度上降低tearing的出现。

双缓冲顾名思义存在2个帧缓冲区, 一个用于绘制（Back Buffer），一个用于显示（Front Buffer）。仅当 Back Buffer 处理完数据后才允许进行缓冲区交换（Swap Buffer）。因此保证了数据的完整性，一定程度上减少了tearing的出现。

> 如果没有 VSYNC ，**仅依靠双缓冲依然可能出现撕裂现象，高帧率下更加明显**。

假设在屏幕未完全显示期间 两个buffer进行了交换，后续显示的内容将会是其他帧的数据，依然出现了画面撕裂的问题。所以还**需要依靠垂直同步限制Swap buffer的时机**。

同时如果没有VSYNC，即使 CPU/GPU 处理数据的时间远远小于一个VSYNC周期（帧率大于刷新率），但是由于CPU不知道什么时候应该处理UI，所有可能会先处理其他事情而并不即使处理UI绘制，等处理时又错过了屏幕刷新的周期，得等待屏幕下一次刷新，从而导致本不该出现掉帧情况出现了掉帧。而使用 VSYNC 控制UI绘制时机则可避免这种情况。

**双缓冲 + VSYNC 流程如下：**

首先 CPU/GPU 会将内容绘制到 Back Buffer ，当接收到 VSYNC 时，通过 Swap Buffer 将 Back Buffer 和 Front Buffer 进行交换（仅在显示器需要时才交换），这样 CPU/GPU 的就可以直接处理下一帧不再需要阻塞等待，也不会影响显示，提高了性能。

> 蓝色：CPU耗时；使用Back Buffer
>
> 绿色：GPU耗时；使用Back Buffer
>
> 黄色：当前屏幕显示的是第几帧画面。使用Front Buffer
>
> App没有必要刷新时，CPU/GPU不执行，每次刷新将显示同一帧数据。

![img](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/webp.webp)

**双缓冲 + VSYNC存在的问题**：

* `Jank`（丢帧）：当GPU绘制时间过长，使得`CPU + GPU的耗时`超过了一个 VSYNC 信号周期时依然会出现掉帧（帧率小于刷新率）。此时一个缓存区被GPU用于绘制，一个缓存区则被用于显示，由于 CPU 和 GPU 共用一个通道，所以将导致CPU空闲等待，且在该周期内GPU处理完成后，CPU/GPU都将空闲，最终的结果就是这帧期间CPU/GPU基本没有做事。即**跨越了两个VSYNC信号周期,出现丢帧现象**。

![img](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/551fb7b5a8a0bed7d81edde6aff99653.png)

#### 三缓冲机制（Triple Buffer）

> Android 4.1 (Jelly Bean) 开启了 Project Butter 黄油计划：主要就是`VSYNC`、`Triple Buffer`和`Choreographer`。
>
> 为了优化性能处理丢帧（`jank`）问题。
>
> 包含一个Front Buffer，两个Back Buffer。

**三缓冲 + VSYNC的方案**使得当 VSYNC 到来时，即使GPU仍在处理，CPU也不会由于和GPU争抢同一个Buffer导致等待空闲，而是使用新增Buffer去立即处理数据。

* 充分发挥CPU/GPU并行处理的效率。
* 仅在开始时掉一帧，保证后续不再发生掉帧。
* 存在一帧的延迟。

![img](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/4d84d2d6a8f8e25e1622665141d993ed.png)



## Android 渲染流程

> 官方提供了一个学习参考案例：[google/grafika: Grafika test app (github.com)](https://github.com/google/grafika)

了解了垂直同步和三缓冲机制。我们来看看 Android 整体的图形架构，以及它包含的主要组件。

> 在 Android 中 所有的界面元素都会经过一系列的测量和布局过程，该过程会将这些元素融入到矩形区域中。然后，所以可见的View都会渲染到 `Surface` 上。所有被渲染的可见 `Surface` 都被 `SurfaceFlinger` 合成到屏幕。
>
> UI线程会逐帧执行布局并渲染到缓冲区。

[官方提供了一张图形组件间的协同图](https://source.android.com/docs/core/graphics)：

![图像渲染组件](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/ape-fwk-graphics.png)



图像数据流：

> 图像流生产方：可以是生成图形缓冲区以供消耗的任何内容。例如 `OpenGL ES`、`Canvas 2D` 和 `mediaserver 视频解码器`。
>
> 图像流消耗方：最常见消耗方是 `SurfaceFlinger`。其他 OpenGL ES 应用也可以消耗图像流，例如相机应用会消耗相机预览图像流。非 GL 应用也可以是使用方，例如 `ImageReader` 类。

![图形数据流](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/graphics-pipeline.png)



### 绘制流程

Android中有两种绘制方式：**软件绘制**和**硬件绘制**。

流程如下：

* 画笔：Skia/OpenGL ES
* 画布：Surface
* 画板：Graphic Buffer
* 显示：SurfaceFlinger

无论是使用 Skia 软件绘制，还是使用OpenGL硬件绘制，最终都是绘制到 Surface上，而Surface会通过缓冲区向 SurfaceFlinger提供数据，最终 SurfaceFlinger将多个数据合成一组 Surface 展示到屏幕上。

![软件绘制和硬件绘制](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/%E8%BD%AF%E4%BB%B6%E7%BB%98%E5%88%B6%E5%92%8C%E7%A1%AC%E4%BB%B6%E7%BB%98%E5%88%B6.png)

#### 软件绘制

> Skia、CPU

应用程序内使用`Skia`将内容绘制到`Surface`上，仅依靠**CPU绘制渲染栅格化**的过程。

CPU处理数据（view的绘制过程） -> Skia渲染 -> 缓存到buffer中 -> 从buffer获取数据显示。

#### 硬件绘制

> OpenGL ES、GPU

应用程序内调用`OpenGL ES`接口利用**GPU处理和渲染图形**。

部分不能使用硬件加速的情况（如渐变、磨砂、圆角、SVG等）将会使用软件绘制，此时渲染性能将变低。。

CPU处理数据 （view的绘制过程）-> GPU渲染 -> 缓存到buffer中 -> 从buffer获取数据显示。

### BufferQueue

> BufferQueue 永远不会复制数据，而是通过句柄进行传递。
>
> 首次从 BufferQueue 请求某个缓冲区时，该缓冲区将被分配并初始化为零。必须进行初始化，以避免意外地在进程之间共享数据。
>
> 重复使用缓冲区时，以前的内容仍会存在。

`BufferQueue` 类连接了 图形数据的成产者 和 图形数据的消费者。

![BufferQueue 通信过程](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/bufferqueue.png)



* 生成方调用`dequeueBuffer()` 从 BufferQueue 中获取一个可用的缓冲区。向缓冲区后填充数据（绘制）。
* 绘制完毕后，生成方调用`queueBuffer()`使缓冲区入队。
* 使用方通过 `acquireBuffer()` 从 BufferQueue 中获取到该缓冲区，并使用缓冲区数据进行合成于处理。
* 使用完毕后，通过调用 `releaseBuffer()` 将该缓冲区放回队列。

### Gralloc 内存分配器

> `hardware/libhardware/include/hardware/gralloc.h`

Gralloc 内存分配器实现了 HAL 接口，并通过 usage flags 执行缓冲区分配。

usage flags 有：

- 从软件 (CPU) 访问内存的频率
- 从硬件 (GPU) 访问内存的频率
- 是否将内存用作 OpenGL ES (GLES) 纹理
- 视频编码器是否会使用内存

> Gralloc 用法标志 `GRALLOC_USAGE_PROTECTED` 允许仅通过受硬件保护的路径显示图形缓冲区。这些叠加平面是显示 DRM 内容的唯一途径（SurfaceFlinger 或 OpenGL ES 驱动程序无法访问受 DRM 保护的缓冲区）。
>
> [DRM  | Android 开源项目  | Android Open Source Project](https://source.android.com/docs/core/media/drm)



### EGLSurface 和 OpenGL ES（GLES）

EGI 是一个通过操作系统 创建 和 访问窗口 的库，适合渲染到屏幕上。

OpenGL ES是图形渲染 API（OpenGL 的API子集），适合绘制多边形。





### Vulkan

> Vulkan 是一种用于高性能 3D 图形的低开销、跨平台 API。



### SurfaceView（表面视图）

SurfaceView 是一个组件，使用方法和普通View差不多，它结合了 Surface 和 View，有自己独立的 Surface。

使用SurfaceView 进行渲染时 SurfaceFlinger 会直接将缓冲区合成到屏幕上，从而可以通过单独的线程/进程渲染，并与应用界面渲染隔离。

#### GLSurfaceView

GLSurfaceView 是 SurfaceView 的补充，提供了用于管理 EGL 上下文、线程间通信以及与 activity 生命周期的交互的帮助程序类。

* 可以认为是一种 SurfaceView 的使用范例。
* 简化了 GLES 的使用。

```java
public class GLSurfaceView extends SurfaceView implements SurfaceHolder.Callback2 {

}
```



### SurfaceTexture（表面纹理）

SurfaceTexture 是 Surface 和 GLES 纹理的组合，提供了输出到 GLES 纹理的接口。内部**包含了一个由应用来消费的 BufferQueue**，不同于 SurfaceView是直接显示。可作为MediaCodec、MediaPlayer、和 VideoDecode等类的输出对象，可对数据流做二次处理。

生产方将新的缓冲区排入队列时，`onFrameAvailable()` 回调会通知应用。然后，应用调用 `updateTexImage()`。此时会释放先前占用的缓冲区，从队列中获取新缓冲区并执行 EGL 调用，从而使 GLES 可将此缓冲区作为外部纹理（GL_TEXTURE_EXTERNAL_OES）使用。

[Grafika 的连续拍摄 案例](https://github.com/google/grafika/blob/master/app/src/main/java/com/android/grafika/ContinuousCaptureActivity.java)：一边录制一边显示。

![Grafika 连续拍摄 activity](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/continuous_capture_activity.png)

* `setOnFrameAvailableListener()`：设置监听，当有新的数据帧时会回调。
* `updateTexImage()`：使用新的图像数据流更新当前的数据帧。
* `getTransformMatrix()`：检索转换纹理矩阵，渲染时需要使用。
* `getTimeStamp()`：检索数据戳。







### TextureView（纹理视图）

TextureView 结合了 View 和 SurfaceTexture，TextureView 对 SurfaceTexture 进行包装，并负责响应回调以及获取新的缓冲区



View是如何显示在屏幕上的？主要涉及到了哪些类？具体经过了哪些流程？

Android是如何接收VSYNC信号的？

收到VSYNC信号后Android又是如何处理的？











## 了解视图的层级关系

首先我们要知道View是如何显示到屏幕上的，我们可以从Activity的创建过程看起。这里涉及了Android应用启动流程相关的知识点，具体内容可以查看 [Activity启动流程](./system/Android之Activity启动流程.md)这篇文章。这里概况一下流程：zygote孵化了应用进程后 会调用 `ActivityThread.main()` 来启动应用程序，这里启动了mainLooper 来接收消息，其中就包括了Activity 的创建消息，接收到消息会调用 `handleLaunchActivity()` ，然后内部通过反射创建了 Activity，接着调用 Activity.attach() 、`Activity.onCreate()` 等，就这样启动了一个Activity。

* `Activity.attach()`： 内部创建了 PhoneWindow，它负责承载我们的view。
* `Activity.onCreate()`：我们会在这里通过 `setContentView()` 传入我们需要显示的View。

### Activity

> [Activity.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/app/Activity.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=8225)

```java
public class Activity extends ... {
    final void attach(...) {
        attachBaseContext(context);

        mFragments.attachHost(null /*parent*/);
		// 此处创建PhoneWindow，承载view
        mWindow = new PhoneWindow(this, window, activityConfigCallback);
        ......
        getAutofillClientController().onActivityAttached(application);
        ......
    }
    // `setContentView()`中找起，因为我们在这个方法中传入了需要显示的布局。
    public void setContentView(View view) {
        // window在attach()中创建, 是一个PhoneWindow
        getWindow().setContentView(view);
        initWindowDecorActionBar();
    }
}
```



### PhoneWindow

> 

```java
public class PhoneWindow extends Window ... {
        @Override
    public void setContentView(int layoutResID) {
        // 构建DecorView，decorView是mContentParent的根视图
        if (mContentParent == null) {
            installDecor();
        } else if (!hasFeature(FEATURE_CONTENT_TRANSITIONS)) {
            mContentParent.removeAllViews();
        }
		// 使用mContentParent作为root构建了我们传入的布局视图。
        // 由此可知DecorView是最顶层视图。
        if (hasFeature(FEATURE_CONTENT_TRANSITIONS)) { 
            // 此处是转场动画，不过最终还是在scene.enter方法中使用mContentParent作为root构建了视图。和else相同。
            final Scene newScene = Scene.getSceneForLayout(mContentParent, layoutResID,
                    getContext());
            transitionTo(newScene);
        } else {
            mLayoutInflater.inflate(layoutResID, mContentParent);
        }
        ......
    }
    
    private void installDecor() {
        ......
        if (mDecor == null) {
            mDecor = generateDecor(-1); // 构建DecorView
			......
        } else {
            mDecor.setWindow(this);
        }
		if (mContentParent == null) {
            // 构建decorview布局，返回mContentParent
			mContentParent = generateLayout(mDecor); 
            ......
        }
        ......
    }
    
	protected DecorView generateDecor(int featureId) {
     	......
        return new DecorView(context, featureId, this, getAttributes());
    }
    protected ViewGroup generateLayout(DecorView decor) {
        ......
        mDecor.startChanging();
        // 加载decorview布局
        mDecor.onResourcesLoaded(mLayoutInflater, layoutResource);
        
        ViewGroup contentParent = (ViewGroup)findViewById(ID_ANDROID_CONTENT);
        ......
        mDecor.finishChanging();
        return contentParent;
    }
}
```

从`setConentView()`流程中我们可以了解Activity、Window、DecorView 、WindowManager之间的关系，进而得到一个基本的视图结构。



| 视图组件      |                                                              |             |                                                              |
| ------------- | ------------------------------------------------------------ | ----------- | ------------------------------------------------------------ |
| Activity      |                                                              |             | 一个Activity对应一个Windows。Activity 在 `attach()` 时创建了 `PhoneWindow`。 |
| Window        | 承载了视图的显示、控制顶层窗口的外观和行为。包括绘制背景和标题栏、默认的按键处理等。 | PhoneWindow | `Activity.setContentView()`最终调用了`Window.setContentView()`，然后在此方法中**创建了DecorView**。 |
| View          | View是一个基本的UI单元，占据屏幕的一块矩形区域，可用于绘制，并能处理事件。 | DecorView   | PhoneWindow首先创建了DecorView，然后通过DecorView构建子View`mContentParent`,最后将`mContentParent`作为我们传入的布局的父View。所以 DecorView 是最顶级的视图。 |
| WindowManager |                                                              |             |                                                              |

![Android视图层级](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/Android%E8%A7%86%E5%9B%BE%E5%B1%82%E7%BA%A7-1666707059734-2.png)



### View的绘制



### RenderThread和RenderNode

> Android 5.0引入；
>
> CPU将数据同步给GPU后，一般不阻塞等待GPU的绘制，直接返回。而GPU绘制渲染图形的操作都在`RenderThread`中执行，减轻`UIThread`的压力

`RenderNode` 中存有渲染帧的所有信息，可以做一些属性动画。

### WindowManager

> Window 是 View的容器，每个窗口都会包含一个 Surface 。

主要负责管理View的以下内容：

* 生命周期
* 输入和焦点事件
* 屏幕旋转
* 动画切换
* 位置等





## Surface相关流程

### Surface

> 表示缓冲区队列中的生产方。
>
> ⚠️`SurefaceView` 和 `TextureView`有自己单独的Surface。

不同的 View 或者 Activity 会共用一个 Window ， 而每个 Window 都会关联一个`Surface`。Surface是一个接口，供 生产方 与 消耗方 交换缓冲区。

* Surface  一个 `BufferQueue` 缓存队列，队列中有两个 `Graphic Buffer` 。
  *  **Off Screen Buffer**：用于绘制。
  *  **Front Graphic Buffer**：用于显示。

* 应用通过 `SurfaceHolder` 接口控制 Surface 将图像渲染到屏幕上。

我们可通过

### SurfaceHolder

SurfaceHolder 是系统用于与应用共享 Surface 所有权的接口。一个 SurfaceView 包含一个 SurfaceHolder 。

应用可以通过 SurfaceHolder  来获取和设置 Surface 参数。

和 View 交互的 大多数组件都会涉及到它。一些其他 API（如 MediaCodec）将在 Surface 本身上运行。

### SurfaceFlinger

`SurfaceFlinger`  接收来自多个源的数据缓冲区，使用 OpenGL 和 Hardware Composer 来合成一组 Surface，然后发送给屏幕。通过`Swap Buffer` 把所有 `Surface` 中的 `Front Graphic Buffer` 统一交给硬件合成器(Hardware Composer)  合成并交给系统的`帧缓冲区（Frame Buffer）`， 从而输出到显示屏。

* `SurfaceFlinger` 是图像缓冲区队列的最常见的消费者，对数据进行合成，然后发送到屏幕。
* `SurfaceFlinger` 维护管理了一个`BufferQueue`, 并通过 匿名共享内存机制 和 应用层交互。

* `SurfaceFlinger` 仅在有工作要执行时才会被唤醒，而不是每秒将其唤醒 60 次（60fps下）。系统会尝试避免工作，并且如果屏幕没有任何更新，将停用 VSYNC。



### SurfaceSession





## View的绘制流程

|        |                                          |      |
| ------ | ---------------------------------------- | ---- |
| Canvas | 画图的动作。提供了基础的绘画函数。       |      |
| Bitmap | 画布。是一块存储图像像素的数据存储区域。 |      |
| Paint  | 画笔。表述绘制时的风格、颜色等。         |      |

一般Canvas都会包含一个Bitmap，并使用Paint在这个Bitmap作图。









## 适配方案

| 屏幕类型 | 分辨率 | 限定符 |
| -------- | ------ | ------ |
| 小屏幕   | ldpi   | small  |
| 中等屏幕 | mdpi   | normal |
| 大屏幕   | hdpi   | large  |
| 超大屏   | xhdpi  | xlarge |
| 超超大屏 | xxhdpi |        |
|          |        |        |

| 屏幕方向 |      |      |
| -------- | ---- | ---- |
| land     | 横屏 |      |
| port     | 竖屏 |      |
|          |      |      |

|         |      |      |
| ------- | ---- | ---- |
| px      |      |      |
| dp      |      |      |
| dpi     |      |      |
| ppi     |      |      |
| density |      |      |



### 限制符适配方案

* `Smallest-Width Qualifier`：屏幕最小宽度限定符。我可以对屏幕宽度设置一个最小`dp`值，当屏幕宽度大于这个值的设备就会使用对应目录下的文件，屏幕宽度小于这个值的时就会使用其他的资源。

  ```shell
  # 限定屏幕最小宽度 600dp
  layout-sw600dp
  # 大于600dp则使用 layout-sw600dp
  # 小于则使用其他的，例如layout
  ```

* 宽高限定符

### 今日头条适配方案

反射修正系统的 density 值





## 补充

### Surface

在 `ViewRootImpl.performTraversals()`  执行绘制的过程中，会调用 `relayoutWindow()` 向WMS发起 binder请求创建Surface。

WMS会创建一个 `SurfaceControl` 并由 control 来创建并管理Surface。

#### ViewRootImpl.relayoutWindow()

* 通过 `mWindowSession` 向 WMS 发起了 `relayoutWindow()`  binder请求。
  * 传入的 `mWindow` 用于接收回调。
  * 传入的 `mSurfaceControl` 在binder通信中被更新为 WMS中新建的实例。
* 更新 Surface 指向 新的native层Surface。
  * 使用BLAST时，`mBlastBufferQueue`会创建的新Surface，并更新给ViewRoot中的 mSerfauce。
  * 不使用BLAST时，从 `mSurfaceControl` 更新给 `ViewRootImp.mSerfauce`。

[ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;l=8185)

```java
class ViewRootImpl ... {
    private int relayoutWindow(WindowManager.LayoutParams params, int viewVisibility,
            boolean insetsPending) throws RemoteException {
        final WindowConfiguration winConfigFromAm = getConfiguration().windowConfiguration;
        final WindowConfiguration winConfigFromWm =
                mLastReportedMergedConfiguration.getGlobalConfiguration().windowConfiguration;
        final WindowConfiguration winConfig = getCompatWindowConfiguration();
        final int measuredWidth = mMeasuredWidth;
        final int measuredHeight = mMeasuredHeight;
        final boolean relayoutAsync;



        final int requestedWidth = (int) (measuredWidth * appScale + 0.5f);
        final int requestedHeight = (int) (measuredHeight * appScale + 0.5f);
        int relayoutResult = 0;
        mRelayoutSeq++;

        // 通过 mWindowSession 向 WMS发起 binder请求
        if (relayoutAsync) {
            // 异步
            mWindowSession.relayoutAsync(mWindow, params,
                    requestedWidth, requestedHeight, viewVisibility,
                    insetsPending ? WindowManagerGlobal.RELAYOUT_INSETS_PENDING : 0, mRelayoutSeq,
                    mLastSyncSeqId);
        } else {
            // 发起binder通信，传入了的mWindow 用于接收回调。
            // mSurfaceControl 
            relayoutResult = mWindowSession.relayout(mWindow, params,
                    requestedWidth, requestedHeight, viewVisibility,
                    insetsPending ? WindowManagerGlobal.RELAYOUT_INSETS_PENDING : 0, mRelayoutSeq,
                    mLastSyncSeqId, mTmpFrames, mPendingMergedConfiguration, mSurfaceControl,
                    mTempInsets, mTempControls, mRelayoutBundle);
            mRelayoutRequested = true;

            final int maybeSyncSeqId = mRelayoutBundle.getInt("seqid");
            if (maybeSyncSeqId > 0) {
                mSyncSeqId = maybeSyncSeqId;
            }
            mWinFrameInScreen.set(mTmpFrames.frame);
            if (mTranslator != null) {
                mTranslator.translateRectInScreenToAppWindow(mTmpFrames.frame);
                mTranslator.translateRectInScreenToAppWindow(mTmpFrames.displayFrame);
                mTranslator.translateRectInScreenToAppWindow(mTmpFrames.attachedFrame);
                mTranslator.translateInsetsStateInScreenToAppWindow(mTempInsets);
                mTranslator.translateSourceControlsInScreenToAppWindow(mTempControls);
            }
            mInvCompatScale = 1f / mTmpFrames.compatScale;
            mInsetsController.onStateChanged(mTempInsets);
            mInsetsController.onControlsChanged(mTempControls);

            mPendingAlwaysConsumeSystemBars =
                    (relayoutResult & RELAYOUT_RES_CONSUME_ALWAYS_SYSTEM_BARS) != 0;
        }

        final int transformHint = SurfaceControl.rotationToBufferTransform(
                (mDisplayInstallOrientation + mDisplay.getRotation()) % 4);

        WindowLayout.computeSurfaceSize(mWindowAttributes, winConfig.getMaxBounds(), requestedWidth,
                requestedHeight, mWinFrameInScreen, mPendingDragResizing, mSurfaceSize);

        final boolean transformHintChanged = transformHint != mLastTransformHint;
        final boolean sizeChanged = !mLastSurfaceSize.equals(mSurfaceSize);
        final boolean surfaceControlChanged =
                (relayoutResult & RELAYOUT_RES_SURFACE_CHANGED) == RELAYOUT_RES_SURFACE_CHANGED;
        if (mAttachInfo.mThreadedRenderer != null &&
                (transformHintChanged || sizeChanged || surfaceControlChanged)) {
            if (mAttachInfo.mThreadedRenderer.pause()) {
                // Animations were running so we need to push a frame
                // to resume them
                mDirty.set(0, 0, mWidth, mHeight);
            }
        }

        if (mSurfaceControl.isValid() && !HardwareRenderer.isDrawingEnabled()) {
            // When drawing is disabled the window layer won't have a valid buffer.
            // Set a window crop so input can get delivered to the window.
            mTransaction.setWindowCrop(mSurfaceControl, mSurfaceSize.x, mSurfaceSize.y).apply();
        }

        mLastTransformHint = transformHint;
      
        mSurfaceControl.setTransformHint(transformHint);

        if (mAttachInfo.mContentCaptureManager != null) {
            MainContentCaptureSession mainSession = mAttachInfo.mContentCaptureManager
                    .getMainContentCaptureSession();
            mainSession.notifyWindowBoundsChanged(mainSession.getId(),
                    getConfiguration().windowConfiguration.getBounds());
        }
		
        // 这里更新了 mSurface
        if (mSurfaceControl.isValid()) {
            if (!useBLAST()) {
                // 从 mSurfaceControl 更新
                mSurface.copyFrom(mSurfaceControl);
            } else {
                // 此处从 mBlastBufferQueue创建的新Surface中更新。
                updateBlastSurfaceIfNeeded();
            }
            if (mAttachInfo.mThreadedRenderer != null) {
                mAttachInfo.mThreadedRenderer.setSurfaceControl(mSurfaceControl);
                mAttachInfo.mThreadedRenderer.setBlastBufferQueue(mBlastBufferQueue);
            }
            if (mPreviousTransformHint != transformHint) {
                mPreviousTransformHint = transformHint;
                dispatchTransformHintChanged(transformHint);
            }
        } else {
            if (mAttachInfo.mThreadedRenderer != null && mAttachInfo.mThreadedRenderer.pause()) {
                mDirty.set(0, 0, mWidth, mHeight);
            }
            destroySurface();
        }

        if (restore) {
            params.restore();
        }

        setFrame(mTmpFrames.frame);
        return relayoutResult;
    }
}
```



#### Session.relayout()

这里已经到了 WMS 所在的system_server进程，调用了 `WindowManagerService.relayoutWindow()`。

* outSurfaceControl 用 `out`修饰，所以它会被服务端更新并将新值返回给客户端。

> aidl中的定义
>
> [IWindowSession.aidl - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/view/IWindowSession.aidl;l=1?q=IWindowSession&sq=&ss=android%2Fplatform%2Fsuperproject)

```java
    int relayout(IWindow window, in WindowManager.LayoutParams attrs,
            int requestedWidth, int requestedHeight, int viewVisibility,
            int flags, int seq, int lastSyncSeqId, out ClientWindowFrames outFrames,
            out MergedConfiguration outMergedConfiguration, out SurfaceControl outSurfaceControl,
            out InsetsState insetsState, out InsetsSourceControl[] activeControls,
            out Bundle bundle);
```

> [Session.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/Session.java;l=243)

```java
	public int relayout(IWindow window, WindowManager.LayoutParams attrs,
            int requestedWidth, int requestedHeight, int viewFlags, int flags, int seq,
            int lastSyncSeqId, ClientWindowFrames outFrames,
            MergedConfiguration mergedConfiguration, SurfaceControl outSurfaceControl,
            InsetsState outInsetsState, InsetsSourceControl[] outActiveControls,
            Bundle outSyncSeqIdBundle) {
		// mService 就是 WindowManagerService ;
        // 新的 SurfaceControll 会更新到 outSurfaceControl 中，最终又通过binder回传给应用进程。
        int res = mService.relayoutWindow(this, window, attrs,
                requestedWidth, requestedHeight, viewFlags, flags, seq,
                lastSyncSeqId, outFrames, mergedConfiguration, outSurfaceControl, outInsetsState,
                outActiveControls, outSyncSeqIdBundle);

        return res;
    }
```



#### WindowManagerService.relayoutWindow()

[WindowManagerService.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java;l=2253)

```java
public int relayoutWindow(Session session, IWindow client, LayoutParams attrs,
            int requestedWidth, int requestedHeight, int viewVisibility, int flags, int seq,
            int lastSyncSeqId, ClientWindowFrames outFrames,
            MergedConfiguration outMergedConfiguration, SurfaceControl outSurfaceControl,
            InsetsState outInsetsState, InsetsSourceControl[] outActiveControls,
            Bundle outSyncIdBundle) {
        if (outActiveControls != null) {
            Arrays.fill(outActiveControls, null);
        }
        int result = 0;
        boolean configChanged = false;
        final int pid = Binder.getCallingPid();
        final int uid = Binder.getCallingUid();
        final long origId = Binder.clearCallingIdentity();
        synchronized (mGlobalLock) {
            final WindowState win = windowForClientLocked(session, client, false);
            if (win == null) {
                return 0;
            }
            if (win.mRelayoutSeq < seq) {
                win.mRelayoutSeq = seq;
            } else if (win.mRelayoutSeq > seq) {
                return 0;
            }

            if (win.cancelAndRedraw() && win.mPrepareSyncSeqId <= lastSyncSeqId) {
                // The client has reported the sync draw, but we haven't finished it yet.
                // Don't let the client perform a non-sync draw at this time.
                result |= RELAYOUT_RES_CANCEL_AND_REDRAW;
            }

            final DisplayContent displayContent = win.getDisplayContent();
            final DisplayPolicy displayPolicy = displayContent.getDisplayPolicy();

            WindowStateAnimator winAnimator = win.mWinAnimator;
            if (viewVisibility != View.GONE) {
                win.setRequestedSize(requestedWidth, requestedHeight);
            }

            int attrChanges = 0;
            int flagChanges = 0;
            int privateFlagChanges = 0;
            if (attrs != null) {
                displayPolicy.adjustWindowParamsLw(win, attrs);
                attrs.flags = sanitizeFlagSlippery(attrs.flags, win.getName(), uid, pid);
                attrs.inputFeatures = sanitizeSpyWindow(attrs.inputFeatures, win.getName(), uid,
                        pid);
                int disableFlags =
                        (attrs.systemUiVisibility | attrs.subtreeSystemUiVisibility) & DISABLE_MASK;
                if (disableFlags != 0 && !hasStatusBarPermission(pid, uid)) {
                    disableFlags = 0;
                }
                win.mDisableFlags = disableFlags;
                if (win.mAttrs.type != attrs.type) {
                    throw new IllegalArgumentException(
                            "Window type can not be changed after the window is added.");
                }
                if (!(win.mAttrs.providedInsets == null && attrs.providedInsets == null)) {
                    if (win.mAttrs.providedInsets == null || attrs.providedInsets == null
                            || (win.mAttrs.providedInsets.length != attrs.providedInsets.length)) {
                        throw new IllegalArgumentException(
                                "Insets types can not be changed after the window is added.");
                    } else {
                        final int insetsTypes = attrs.providedInsets.length;
                        for (int i = 0; i < insetsTypes; i++) {
                            if (win.mAttrs.providedInsets[i].type != attrs.providedInsets[i].type) {
                                throw new IllegalArgumentException(
                                        "Insets types can not be changed after the window is "
                                                + "added.");
                            }
                        }
                    }
                }

                flagChanges = win.mAttrs.flags ^ attrs.flags;
                privateFlagChanges = win.mAttrs.privateFlags ^ attrs.privateFlags;
                attrChanges = win.mAttrs.copyFrom(attrs);
                final boolean layoutChanged =
                        (attrChanges & WindowManager.LayoutParams.LAYOUT_CHANGED) != 0;
                if (layoutChanged || (attrChanges
                        & WindowManager.LayoutParams.SYSTEM_UI_VISIBILITY_CHANGED) != 0) {
                    win.mLayoutNeeded = true;
                }
                if (layoutChanged && win.providesNonDecorInsets()) {
                    configChanged = displayPolicy.updateDecorInsetsInfo();
                }
                if (win.mActivityRecord != null && ((flagChanges & FLAG_SHOW_WHEN_LOCKED) != 0
                        || (flagChanges & FLAG_DISMISS_KEYGUARD) != 0)) {
                    win.mActivityRecord.checkKeyguardFlagsChanged();
                }
                if (((attrChanges & LayoutParams.ACCESSIBILITY_TITLE_CHANGED) != 0)
                        && (mAccessibilityController.hasCallbacks())) {
                    // No move or resize, but the controller checks for title changes as well
                    mAccessibilityController.onSomeWindowResizedOrMovedWithCallingUid(
                            uid, win.getDisplayContent().getDisplayId());
                }

                if ((privateFlagChanges & SYSTEM_FLAG_HIDE_NON_SYSTEM_OVERLAY_WINDOWS) != 0) {
                    updateNonSystemOverlayWindowsVisibilityIfNeeded(
                            win, win.mWinAnimator.getShown());
                }
                if ((attrChanges & (WindowManager.LayoutParams.PRIVATE_FLAGS_CHANGED)) != 0) {
                    winAnimator.setColorSpaceAgnosticLocked((win.mAttrs.privateFlags
                            & WindowManager.LayoutParams.PRIVATE_FLAG_COLOR_SPACE_AGNOSTIC) != 0);
                }
                if (win.mActivityRecord != null
                        && !displayContent.mDwpcHelper.keepActivityOnWindowFlagsChanged(
                                win.mActivityRecord.info, flagChanges, privateFlagChanges)) {
                    mH.sendMessage(mH.obtainMessage(H.REPARENT_TASK_TO_DEFAULT_DISPLAY,
                            win.mActivityRecord.getTask()));
                    Slog.w(TAG_WM, "Activity " + win.mActivityRecord + " window flag changed,"
                            + " can't remain on display " + displayContent.getDisplayId());
                    return 0;
                }
            }

            if ((attrChanges & WindowManager.LayoutParams.ALPHA_CHANGED) != 0) {
                winAnimator.mAlpha = attrs.alpha;
            }
            win.setWindowScale(win.mRequestedWidth, win.mRequestedHeight);

            if (win.mAttrs.surfaceInsets.left != 0
                    || win.mAttrs.surfaceInsets.top != 0
                    || win.mAttrs.surfaceInsets.right != 0
                    || win.mAttrs.surfaceInsets.bottom != 0) {
                winAnimator.setOpaqueLocked(false);
            }

            final int oldVisibility = win.mViewVisibility;

            // If the window is becoming visible, visibleOrAdding may change which may in turn
            // change the IME target.
            final boolean becameVisible =
                    (oldVisibility == View.INVISIBLE || oldVisibility == View.GONE)
                            && viewVisibility == View.VISIBLE;
            boolean imMayMove = (flagChanges & (FLAG_ALT_FOCUSABLE_IM | FLAG_NOT_FOCUSABLE)) != 0
                    || becameVisible;
            boolean focusMayChange = win.mViewVisibility != viewVisibility
                    || ((flagChanges & FLAG_NOT_FOCUSABLE) != 0)
                    || (!win.mRelayoutCalled);

            boolean wallpaperMayMove = win.mViewVisibility != viewVisibility
                    && win.hasWallpaper();
            wallpaperMayMove |= (flagChanges & FLAG_SHOW_WALLPAPER) != 0;
            if ((flagChanges & FLAG_SECURE) != 0 && winAnimator.mSurfaceController != null) {
                winAnimator.mSurfaceController.setSecure(win.isSecureLocked());
            }

            win.mRelayoutCalled = true;
            win.mInRelayout = true;

            win.setViewVisibility(viewVisibility);
            ProtoLog.i(WM_DEBUG_SCREEN_ON,
                    "Relayout %s: oldVis=%d newVis=%d. %s", win, oldVisibility,
                            viewVisibility, new RuntimeException().fillInStackTrace());


            win.setDisplayLayoutNeeded();
            win.mGivenInsetsPending = (flags & WindowManagerGlobal.RELAYOUT_INSETS_PENDING) != 0;

            // We should only relayout if the view is visible, it is a starting window, or the
            // associated appToken is not hidden.
            final boolean shouldRelayout = viewVisibility == View.VISIBLE &&
                    (win.mActivityRecord == null || win.mAttrs.type == TYPE_APPLICATION_STARTING
                            || win.mActivityRecord.isClientVisible());

            // If we are not currently running the exit animation, we need to see about starting
            // one.
            // We don't want to animate visibility of windows which are pending replacement.
            // In the case of activity relaunch child windows could request visibility changes as
            // they are detached from the main application window during the tear down process.
            // If we satisfied these visibility changes though, we would cause a visual glitch
            // hiding the window before it's replacement was available. So we just do nothing on
            // our side.
            // This must be called before the call to performSurfacePlacement.
            if (!shouldRelayout && winAnimator.hasSurface() && !win.mAnimatingExit) {
                if (DEBUG_VISIBILITY) {
                    Slog.i(TAG_WM,
                            "Relayout invis " + win + ": mAnimatingExit=" + win.mAnimatingExit);
                }
                result |= RELAYOUT_RES_SURFACE_CHANGED;
                if (!win.mWillReplaceWindow) {
                    // When FLAG_SHOW_WALLPAPER flag is removed from a window, we usually set a flag
                    // in DC#pendingLayoutChanges and update the wallpaper target later.
                    // However it's possible that FLAG_SHOW_WALLPAPER flag is removed from a window
                    // when the window is about to exit, so we update the wallpaper target
                    // immediately here. Otherwise this window will be stuck in exiting and its
                    // surface remains on the screen.
                    // TODO(b/189856716): Allow destroying surface even if it belongs to the
                    //  keyguard target.
                    if (wallpaperMayMove) {
                        displayContent.mWallpaperController.adjustWallpaperWindows();
                    }
                    focusMayChange = tryStartExitingAnimation(win, winAnimator, focusMayChange);
                }
            }

            

            if (shouldRelayout && outSurfaceControl != null) {
                try {
					// 创建一个 surfaceControl，
                    result = createSurfaceControl(outSurfaceControl, result, win, winAnimator);
                } catch (Exception e) {
                    displayContent.getInputMonitor().updateInputWindowsLw(true /*force*/);
                    Binder.restoreCallingIdentity(origId);
                    return 0;
                }
            }

            mWindowPlacerLocked.performSurfacePlacement(true /* force */);

            if (shouldRelayout) {
                Trace.traceBegin(TRACE_TAG_WINDOW_MANAGER, "relayoutWindow: viewVisibility_1");

                result = win.relayoutVisibleWindow(result);

                if ((result & WindowManagerGlobal.RELAYOUT_RES_FIRST_TIME) != 0) {
                    focusMayChange = true;
                }
                if (win.mAttrs.type == TYPE_INPUT_METHOD
                        && displayContent.mInputMethodWindow == null) {
                    displayContent.setInputMethodWindowLocked(win);
                    imMayMove = true;
                }
                win.adjustStartingWindowFlags();
            } else {
                winAnimator.mEnterAnimationPending = false;
                winAnimator.mEnteringAnimation = false;

                if (outSurfaceControl != null) {
                    if (viewVisibility == View.VISIBLE && winAnimator.hasSurface()) {
                        Trace.traceBegin(TRACE_TAG_WINDOW_MANAGER, "relayoutWindow: getSurface");
                        winAnimator.mSurfaceController.getSurfaceControl(outSurfaceControl);
                        Trace.traceEnd(TRACE_TAG_WINDOW_MANAGER);
                    } else {
                        if (DEBUG_VISIBILITY) Slog.i(TAG_WM, "Releasing surface in: " + win);

                        try {
                            Trace.traceBegin(TRACE_TAG_WINDOW_MANAGER, "wmReleaseOutSurface_"
                                    + win.mAttrs.getTitle());
                            outSurfaceControl.release();
                        } finally {
                            Trace.traceEnd(TRACE_TAG_WINDOW_MANAGER);
                        }
                    }
                }

                Trace.traceEnd(TRACE_TAG_WINDOW_MANAGER);
            }

            if (focusMayChange) {
                if (updateFocusedWindowLocked(UPDATE_FOCUS_NORMAL, true /*updateInputWindows*/)) {
                    imMayMove = false;
                }
            }

            // updateFocusedWindowLocked() already assigned layers so we only need to
            // reassign them at this point if the IM window state gets shuffled
            boolean toBeDisplayed = (result & WindowManagerGlobal.RELAYOUT_RES_FIRST_TIME) != 0;
            if (imMayMove) {
                displayContent.computeImeTarget(true /* updateImeTarget */);
                if (toBeDisplayed) {
                    displayContent.assignWindowLayers(false /* setLayoutNeeded */);
                }
            }

            if (wallpaperMayMove) {
                displayContent.pendingLayoutChanges |=
                        WindowManagerPolicy.FINISH_LAYOUT_REDO_WALLPAPER;
            }

            if (win.mActivityRecord != null) {
                displayContent.mUnknownAppVisibilityController.notifyRelayouted(win.mActivityRecord);
            }

            Trace.traceBegin(TRACE_TAG_WINDOW_MANAGER, "relayoutWindow: updateOrientation");
            configChanged |= displayContent.updateOrientation();
            Trace.traceEnd(TRACE_TAG_WINDOW_MANAGER);

            if (toBeDisplayed && win.mIsWallpaper) {
                displayContent.mWallpaperController.updateWallpaperOffset(win, false /* sync */);
            }
            if (win.mActivityRecord != null) {
                win.mActivityRecord.updateReportedVisibilityLocked();
            }
            if (displayPolicy.areSystemBarsForcedConsumedLw()) {
                result |= WindowManagerGlobal.RELAYOUT_RES_CONSUME_ALWAYS_SYSTEM_BARS;
            }
            if (!win.isGoneForLayout()) {
                win.mResizedWhileGone = false;
            }

            if (outFrames != null && outMergedConfiguration != null) {
                win.fillClientWindowFramesAndConfiguration(outFrames, outMergedConfiguration,
                        false /* useLatestConfig */, shouldRelayout);

                // Set resize-handled here because the values are sent back to the client.
                win.onResizeHandled();
            }

            if (outInsetsState != null) {
                outInsetsState.set(win.getCompatInsetsState(), true /* copySources */);
            }
            win.mInRelayout = false;

            if (outSyncIdBundle != null) {
                final int maybeSyncSeqId;
                if (USE_BLAST_SYNC && win.useBLASTSync() && viewVisibility == View.VISIBLE
                        && win.mSyncSeqId > lastSyncSeqId) {
                    maybeSyncSeqId = win.shouldSyncWithBuffers() ? win.mSyncSeqId : -1;
                    win.markRedrawForSyncReported();
                } else {
                    maybeSyncSeqId = -1;
                }
                outSyncIdBundle.putInt("seqid", maybeSyncSeqId);
            }

            if (configChanged) {
                displayContent.sendNewConfiguration();
            }
            if (outActiveControls != null) {
                getInsetsSourceControls(win, outActiveControls);
            }
        }

        Binder.restoreCallingIdentity(origId);
        return result;
    }
```



#### WindowManagerService.createSurfaceControl()

创建一个 SurfaceController，并将信息更新到 传入的 outSurfaceControl中。

SurfaceController 构造函数通过 SurfaceSession 创建了 native surface，并将返回的地址保存到 `mNativeObject` 中，会通过它来创建 java层的Surface对象。

[WindowManagerService.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java;l=2692)

```java
private int createSurfaceControl(SurfaceControl outSurfaceControl, int result,
            WindowState win, WindowStateAnimator winAnimator) {
        if (!win.mHasSurface) {
            result |= RELAYOUT_RES_SURFACE_CHANGED;
        }

        WindowSurfaceController surfaceController;
        try {
            Trace.traceBegin(TRACE_TAG_WINDOW_MANAGER, "createSurfaceControl");
            // 最终调用了 SurfaceController的构造函数，并通过 SurfaceSession 创建了 Surface。
            surfaceController = winAnimator.createSurfaceLocked();
        } finally {
            Trace.traceEnd(TRACE_TAG_WINDOW_MANAGER);
        }
        if (surfaceController != null) {
            // 这里是将 新建的surfaceController 信息拷贝到 outSurfaceControl中。
            // 内部 实现outSurfaceControl.copyFrom(mSurfaceControl, "WindowSurfaceController.getSurfaceControl");
            surfaceController.getSurfaceControl(outSurfaceControl);
        } else {
			// 创建 surface control失败，释放
            outSurfaceControl.release();
        }

        return result;
    }
```

### SurfaceControl

在 WMS 创建Surface流程中，会先创建一个 `SurfaceControl` ，并在 `SurfaceControl` 的构造函数中调用 `nativeCreate(SurfaceSession)` 创建了 `Surface`。 `mNativeObject` 保存指向 native surface的地址。

* SurfaceControl 实现了 parcelable 序列化接口，它可以在binder 通信期间会传输。
* SurfaceControl  包含了很多 native函数。

[SurfaceControl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/view/SurfaceControl.java;l=1538)

```java
public final class SurfaceControl implements Parcelable {
    
    // 指向 native surface
    // 会通过它来创建 java层的Surface对象。
    public long mNativeObject;
    
    // 
	private SurfaceControl(SurfaceSession session, String name, int w, int h, int format, int flags,
            SurfaceControl parent, SparseIntArray metadata, WeakReference<View> localOwnerView,
            String callsite)
                    throws OutOfResourcesException, IllegalArgumentException {
        if (name == null) {
            throw new IllegalArgumentException("name must not be null");
        }

        mName = name;
        mWidth = w;
        mHeight = h;
        mLocalOwnerView = localOwnerView;
        // 注意这个parcel
        Parcel metaParcel = Parcel.obtain();
        try {
            if (metadata != null && metadata.size() > 0) {
                metaParcel.writeInt(metadata.size());
                for (int i = 0; i < metadata.size(); ++i) {
                    metaParcel.writeInt(metadata.keyAt(i));
                    metaParcel.writeByteArray(
                            ByteBuffer.allocate(4).order(ByteOrder.nativeOrder())
                                    .putInt(metadata.valueAt(i)).array());
                }
                metaParcel.setDataPosition(0);
            }
            // 调用 SurfaceControl_nativeCreate() 创建了 Surface
            // 传入了 session:SurfaceSession
            // 		 parent:SurfaceControl
            //       metaParcel
            mNativeObject = nativeCreate(session, name, w, h, format, flags,
                    parent != null ? parent.mNativeObject : 0, metaParcel);
        } finally {
            metaParcel.recycle();
        }
        if (mNativeObject == 0) {
            throw new OutOfResourcesException(
                    "Couldn't allocate SurfaceControl native object");
        }
        mNativeHandle = nativeGetHandle(mNativeObject);
        mCloseGuard.openWithCallSite("release", callsite);
    }
}
```

#### android_view_SurfaceControl.nativeCreate()

[android_view_SurfaceControl.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/jni/android_view_SurfaceControl.cpp;l=398?q=SurfaceControl.cpp)

```cpp
// sessionObj： SurfaceSession
// parentObject：SurfaceControl
static jlong nativeCreate(JNIEnv* env, jclass clazz, jobject sessionObj,
        jstring nameStr, jint w, jint h, jint format, jint flags, jlong parentObject,
        jobject metadataParcel) {
    ScopedUtfChars name(env, nameStr);
    sp<SurfaceComposerClient> client;
    // 从sessionObj 中获取 到SurfaceComposerClient对象。
    if (sessionObj != NULL) {
        client = android_view_SurfaceSession_getClient(env, sessionObj);
    } else {
        client = SurfaceComposerClient::getDefault();
    }
    // parentObject 转为 SurfaceControl*
    SurfaceControl *parent = reinterpret_cast<SurfaceControl*>(parentObject);
    
    // 定义一个 surface, 它是 SurfaceControl
    sp<SurfaceControl> surface;
    // 
    LayerMetadata metadata;
    Parcel* parcel = parcelForJavaObject(env, metadataParcel);
    if (parcel && !parcel->objectsCount()) {
        // 将parcel中数据解析为  LayerMetadata
        status_t err = metadata.readFromParcel(parcel);
        if (err != NO_ERROR) {
          jniThrowException(env, "java/lang/IllegalArgumentException",
                            "Metadata parcel has wrong format");
        }
    }

    sp<IBinder> parentHandle;
    if (parent != nullptr) {
        parentHandle = parent->getHandle();
    }
	// createSurfaceChecked() 内部创建了 SurfaceControl 实例，赋值给了 surface。
    // 这里也传入了 metadata。
    status_t err = client->createSurfaceChecked(String8(name.c_str()), w, h, format, &surface,
                                                flags, parentHandle, std::move(metadata));

    // surface的 强引用计数 + 1
	// 入参(void *)nativeCreate 并没有什么作用，
    surface->incStrong((void *)nativeCreate);
    // 返回
    return reinterpret_cast<jlong>(surface.get());
}
```

### SurfaceComposerClient.createSurfaceChecked()

[SurfaceComposerClient.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/SurfaceComposerClient.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=2106)

```cpp

// binder通信接口
sp<ISurfaceComposerClient>  mClient;

status_t SurfaceComposerClient::createSurfaceChecked(const String8& name, uint32_t w, uint32_t h,
                                                     PixelFormat format,
                                                     sp<SurfaceControl>* outSurface, uint32_t flags,
                                                     const sp<IBinder>& parentHandle,
                                                     LayerMetadata metadata,
                                                     uint32_t* outTransformHint) {
    sp<SurfaceControl> sur;
    status_t err = mStatus;

    if (mStatus == NO_ERROR) {
        sp<IBinder> handle;
        sp<IGraphicBufferProducer> gbp;

        uint32_t transformHint = 0;
        int32_t id = -1;
        // 这里是一个 binder请求，请求创建 surface
        // 根据Binder机制的原理，直接找 ISurfaceComposerClient 对应的 BnSurfaceComposerClient即可
        err = mClient->createSurface(name, w, h, format, flags, parentHandle, std::move(metadata),
                                     &handle, &gbp, &id, &transformHint);

        if (outTransformHint) {
            *outTransformHint = transformHint;
        }
        ALOGE_IF(err, "SurfaceComposerClient::createSurface error %s", strerror(-err));
        if (err == NO_ERROR) {
            // 创建一个 SurfaceControl 实例对象
            *outSurface =
                    new SurfaceControl(this, handle, gbp, id, w, h, format, transformHint, flags);
        }
    }
    return err;
}
```



### Client::createSurface()

> [Client.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/Client.cpp;l=75;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1)

```cpp
status_t Client::createSurface(const String8& name, uint32_t /* w */, uint32_t /* h */,
                               PixelFormat /* format */, uint32_t flags,
                               const sp<IBinder>& parentHandle, LayerMetadata metadata,
                               sp<IBinder>* outHandle, sp<IGraphicBufferProducer>* /* gbp */,
                               int32_t* outLayerId, uint32_t* outTransformHint) {
    // We rely on createLayer to check permissions.
    LayerCreationArgs args(mFlinger.get(), this, name.c_str(), flags, std::move(metadata));
    return mFlinger->createLayer(args, outHandle, parentHandle, outLayerId, nullptr,
                                 outTransformHint);
}

```







### SurfaceSession

在创建 SurfaceControl 时 会使用到 SurfaceSession。

> [SurfaceSession.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/SurfaceSession.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=28)

```java
public final class SurfaceSession {
    // Note: This field is accessed by native code.
    @UnsupportedAppUsage(maxTargetSdk = Build.VERSION_CODES.R, trackingBug = 170729553)
    private long mNativeClient; // SurfaceComposerClient*

    private static native long nativeCreate();
    private static native void nativeDestroy(long ptr);

    /** Create a new connection with the surface flinger. */
    @UnsupportedAppUsage
    public SurfaceSession() {
        // 这里调用 SurfaceSession_nativeCreate()创建了一个 SurfaceComposerClient，返回对应的地址。
        mNativeClient = nativeCreate();
    }

    /* no user serviceable parts here ... */
    @Override
    protected void finalize() throws Throwable {
        try {
            kill();
        } finally {
            super.finalize();
        }
    }

    /**
     * Remove the reference to the native Session object. The native object may still exist if
     * there are other references to it, but it cannot be accessed from this Java object anymore.
     */
    @UnsupportedAppUsage
    public void kill() {
        if (mNativeClient != 0) {
            nativeDestroy(mNativeClient);
            mNativeClient = 0;
        }
    }
}
```





## 参考资料

> 以上部分内容摘录自一下资料。

[图形  | Android 开源项目  | Android Open Source Project](https://source.android.com/docs/core/graphics)

[20 | UI 优化（上）：UI 渲染的几个关键概念 (geekbang.org)](https://time.geekbang.org/column/article/80921)

[Android 屏幕刷新机制 - 简书 (jianshu.com)](https://www.jianshu.com/p/0d00cb85fdf3)

[Android VSYNC与图形系统中的撕裂、双缓冲、三缓冲浅析_看书的小蜗牛的博客-CSDN博客_android 三缓冲](https://blog.csdn.net/happylishang/article/details/104196560)

[游戏中的“垂直同步”与“三重缓冲”究竟是个啥？_萧戈的博客-CSDN博客_三重缓冲](https://blog.csdn.net/xiaoyafang123/article/details/79268157)

