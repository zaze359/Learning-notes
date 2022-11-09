# Android的图像架构

## 基础概念

| 概念                     | 说明                                 | 备注                                                         |
| ------------------------ | ------------------------------------ | ------------------------------------------------------------ |
| CPU                      | 擅长逻辑运算                         | 控制器复杂，算术逻辑单元ALU（Arithmetic Logic Unit）较少，   |
| GPU                      | 擅长大量的数学运算，适合图形渲染     | 控制器较简单，但是包含大量ALU。                              |
| diaplay                  | 显示设备                             | 从缓冲区读取数据并显示。                                     |
|                          |                                      |                                                              |
| OpenGL                   | 底层图形库，是操作GPU的API           | 定义了一个跨编程语言、跨平台的编程接口规格的专业的图形程序接口。适用于3D/2D。 |
| OpenGL ES（GLES）        | OpenGL 的嵌入式版                    | OpenGL 的API子集。功耗更低                                   |
| EGL                      | EGL是渲染API和原生窗口系统之间的接口 | 作为OpenGL和原生窗口系统之间的桥梁。                         |
| HWC（Hardware Composer） | 硬件合成器                           | 硬件合成器，是控制器系统的硬件抽象，减轻GPU的负载。          |
|                          |                                      |                                                              |
| Texture                  | 纹理                                 | 纹理是应用于 Surface 的图像，改变它的颜色、光泽或其外观的任何其他部分。 |
| Shader                   | 着色器                               | 一种通过即时演算 生成贴图的程序。                            |
| Material                 | 材质                                 | 本质是一组供渲染器读取的数据集。包含贴图纹理、shader等       |
|                          |                                      |                                                              |
| Skia                     | 软件绘制引擎                         | CPU绘制2D图形，skia也可调用OpenGL实现3D效果。                |
| Surface                  | 图像流生产方                         | 进行绘制和渲染的地方。                                       |
| Graphic Buffer           | 装载栅格化的绘制内容                 | Android 4.1 之前使用的是 双缓冲机制；Android 4.1之后使用的是 三缓冲机制。 |
| SurfaceFlinger           | 图像流消耗方                         | 使用 OpenGL 和 Hardware Composer 来合成一组 Surface，然后发送给屏幕 |

### 屏幕刷新率

> 指一秒内屏幕刷新的次数，即表示一秒内能显示多少帧图像。

若一秒内设备刷新了60次，则` 屏幕刷新率 = 60Hz`。每一帧大约为16.6ms。

### 帧率

> 指一秒内GPU能生成多少画面。
>
> **帧率是指生成，屏幕刷新率是显示**。

若一秒能生成300幅画面，则`帧率 = 300fps`。

### 垂直同步（VSYNC）

> 垂直同步 ： Vertical Synchronization（VSYNC）
>
> 每次屏幕刷新都会发送一个VSYNC信号，通知系统屏幕开始刷新。
>
> 即当设备刷新频率是 60Hz时，VSYNC信号大约16.6ms发送一次。
>
> 如何不产生画面撕裂（tearing）：**保证帧数据的完整性 **和 **保证显示过程数据不发生变化**。
>
> **垂直同步解决了画面撕裂的问题，但也导致了性能下降的问题。**

VSYNC 强制了 帧率 和 屏幕刷新率 保持同步：

* 即使帧数据已准备完毕，也要等到 VSYNC 信号时才使用准备好的帧数据。
* 只有帧数据准备完成且收到 VSYNC 才能用于显示。未处理完则当前帧依然展示之前的数据（保证数据完整性）。

在Android中收到 VSYNC 将执行以下操作：

* Android4.1之前：只用在最后缓冲区切换的显示阶段，防止画面撕裂。

* Android4.1之后增加：CPU/GPU 会立即**准备下一帧数据**，协调UI的绘制，依赖同步屏障机制，优先处理UI。

⚠️**垂直同步导致的问题：**

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

**画面撕裂（tearing）问题：**

> `tearing`：屏幕内显示的数据来自多个不同帧，画面出现撕裂感。 
>
> 出现的原因可以归类为**并发读写问题**，所以通过垂直同步使两边频率保持一致从而避免并发问题。

当仅有一个帧缓冲区且无垂直同步时，由于 CPU/GPU 随时可能往buffer中写数据，因此可能出现以下两种情况：

* **显示器显示过程中数据发生变化**：当A帧尚未完全显示在屏幕上，下一帧数据B帧数据却已准备完毕并被写入了 buffer 中覆盖了A帧数据，接着显示器上之前未显示的部分将会显示B帧。结果就是**上面是A帧数据下面是B帧数据，画面出现撕裂感**。
* **帧数据尚未准备完毕**：当前帧数据尚未处理完成被显示器读取并显示，此时也将产生撕裂。

**单缓冲 + VSYNC的性能问题:**

> 使用 单缓冲 + VSYNC 处理画面撕裂问题，但是却会导致性能降低。

CPU/GPU的写 需要等待 显示器完成读取和显示，变成了完全的单线程模式，降低了整体性能。所以为了优化性能出现了`双缓冲技术，将读写分离提高了性能，同时保证数据完整性也降低tearing的出现`。

![img](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/30a45ebce7f0995f2f900d67852e028e.png)

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

![img](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/webp.webp)

**双缓冲 + VSYNC存在的问题**：

* `Jank`（丢帧）：当GPU绘制时间过长，使得`CPU + GPU的耗时`超过了一个 VSYNC 信号周期时依然会出现掉帧（帧率小于刷新率）。此时一个缓存区被GPU用于绘制，一个缓存区则被用于显示，由于 CPU 和 GPU 共用一个通道，所以将导致CPU空闲等待，且在该周期内GPU处理完成后，CPU/GPU都将空闲，最终的结果就是这帧期间CPU/GPU基本没有做事。即**跨越了两个VSYNC信号周期,出现丢帧现象**。

![img](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/551fb7b5a8a0bed7d81edde6aff99653.png)

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

![img](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/4d84d2d6a8f8e25e1622665141d993ed.png)



## Android 渲染流程

> 官方提供了一个学习参考案例：[google/grafika: Grafika test app (github.com)](https://github.com/google/grafika)

了解了垂直同步和三缓冲机制。我们来看看 Android 整体的图形架构，以及它包含的主要组件。

> 在 Android 中 所有的界面元素都会经过一系列的测量和布局过程，该过程会将这些元素融入到矩形区域中。然后，所以可见的View都会渲染到 `Surface` 上。所有被渲染的可见 `Surface` 都被 `SurfaceFlinger` 合成到屏幕。
>
> UI线程会逐帧执行布局并渲染到缓冲区。

[官方提供了一张图形组件间的协同图](https://source.android.com/docs/core/graphics)：

![图像渲染组件](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/ape-fwk-graphics.png)



图像数据流：

> 图像流生产方：可以是生成图形缓冲区以供消耗的任何内容。例如 `OpenGL ES`、`Canvas 2D` 和 `mediaserver 视频解码器`。
>
> 图像流消耗方：最常见消耗方是 `SurfaceFlinger`。其他 OpenGL ES 应用也可以消耗图像流，例如相机应用会消耗相机预览图像流。非 GL 应用也可以是使用方，例如 `ImageReader` 类。

![图形数据流](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/graphics-pipeline.png)



### 绘制流程

Android中有两种绘制方式：**软件绘制**和**硬件绘制**。

流程如下：

![软件绘制和硬件绘制](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/%E8%BD%AF%E4%BB%B6%E7%BB%98%E5%88%B6%E5%92%8C%E7%A1%AC%E4%BB%B6%E7%BB%98%E5%88%B6.png)

* 画笔：Skia/OpenGL ES
* 画布：Surface
* 画板：Graphic Buffer
* 显示：SurfaceFlinger

#### 软件绘制

> Skia、CPU

应用程序内使用`Skia`将内容绘制到`Surface`上，仅依靠**CPU绘制渲染栅格化**的过程。

CPU处理数据（view的绘制过程） -> Skia渲染 -> 缓存到buffer中 -> 显示从buffer获取数据显示。

#### 硬件绘制

> OpenGL ES、GPU

应用程序内调用`OpenGL ES`接口利用**GPU处理和渲染图形**。

部分不能使用硬件加速的情况（如渐变、磨砂、圆角、SVG等）将会使用软件绘制，此时渲染性能将变低。。

CPU处理数据 （view的绘制过程）-> GPU渲染 -> 缓存到buffer中 -> 显示从buffer获取数据显示。

### BufferQueue

> BufferQueue 永远不会复制数据，而是通过句柄进行传递。
>
> 首次从 BufferQueue 请求某个缓冲区时，该缓冲区将被分配并初始化为零。必须进行初始化，以避免意外地在进程之间共享数据。
>
> 重复使用缓冲区时，以前的内容仍会存在。

`BufferQueue` 类连接了 图形数据的成产者 和 图形数据的消费者。

![BufferQueue 通信过程](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/bufferqueue.png)



* 生成方调用`dequeueBuffer()` 从 BufferQueue 中获取一个可用的缓冲区。向缓冲区后填充数据（绘制）。
* 绘制完毕后，生成方调用`queueBuffer()`使缓冲区入队。
* 使用方通过 `acquireBuffer()` 从 BufferQueue 中获取到该缓冲区，并使用缓冲区数据进行合成于处理。
* 使用完毕后，通过调用 `releaseBuffer()` 将该缓冲区放回队列。

### Gralloc

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

### Surface

> 表示缓冲区队列中的生产方。
>
> ⚠️`SurefaceView` 和 `TextureView`有自己单独的Surface。

不同的 View 或者 Activity 会共用一个 Window ， 而每个 Window 都会关联一个`Surface`。

Surface是一个接口，供 生产方 与 消耗方 交换缓冲区。它有一个 `BufferQueue` 缓存队列，队列中有两个 Graphic Buffer ,  Off Screen Buffer（用于绘制）、 Front Graphic Buffer（用于显示）。

* 应用通过 SurfaceHolder 接口控制 Surface 将图像渲染到屏幕上。

我们可用通过



### SurfaceHolder

SurfaceHolder 是系统用于与应用共享 Surface 所有权的接口。

应用需要通过 SurfaceHolder  来获取和设置 Surface 参数。

和View 交互的大多数组件都会涉及到它。一些其他 API（如 MediaCodec）将在 Surface 本身上运行。

一个 SurfaceView 包含一个 SurfaceHolder 。



### SurfaceFlinger

SurfaceFlinger  接收来自多个源的数据缓冲区，使用 OpenGL 和 Hardware Composer 来合成一组 Surface，然后发送给屏幕。通过`Swap Buffer` 把所有 `Surface` 中的 `Front Graphic Buffer` 统一交给硬件合成器(Hardware Composer)  合成并交给系统的`帧缓冲区（Frame Buffer）`， 从而输出到显示屏。

* `SurfaceFlinger` 是图像缓冲区队列的最常见的消费者，对数据进行合成，然后发送到屏幕。
* `SurfaceFlinger` 维护管理了一个`BufferQueue`, 并通过 匿名共享内存机制 和 应用层交互。

* `SurfaceFlinger` 仅在有工作要执行时才会被唤醒，而不是每秒将其唤醒 60 次（60fps下）。系统会尝试避免工作，并且如果屏幕没有任何更新，将停用 VSYNC。

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

![Grafika 连续拍摄 activity](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/continuous_capture_activity.png)

* `setOnFrameAvailableListener()`：设置监听，当有新的数据帧时会回调。
* `updateTexImage()`：使用新的图像数据流更新当前的数据帧。
* `getTransformMatrix()`：检索转换纹理矩阵，渲染时需要使用。
* `getTimeStamp()`：检索数据戳。







### TextureView（纹理视图）

TextureView 结合了 View 和 SurfaceTexture，TextureView 对 SurfaceTexture 进行包装，并负责响应回调以及获取新的缓冲区



View是如何显示在屏幕上的？主要涉及到了哪些类？具体经过了哪些流程？

Android是如何接收VSYNC信号的？

收到VSYNC信号后Android又是如何处理的？

















### 了解视图的层级

首先我们要知道View是如何显示到屏幕上的，我们可以从Activity的`setContentView()`中找起，因为我们在这个方法中传入了需要显示的布局。

> 涉及Activity、PhoneWindow、DecorView

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
    public void setContentView(View view) {
        // window在attach()中创建, 是一个PhoneWindow
        getWindow().setContentView(view);
        initWindowDecorActionBar();
    }
}

```

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

从`setConentView()`流程中我们可以了解Activity、Window、DecorView之间的关系，进而得到一个基本的视图结构。

* **一个Activity对应一个Windows**： Activity 在 `attach()` 时创建了 PhoneWindow。
* **PhoneWindow承载了视图的显示**：`Activity.setContentView()`最终调用了`PhoneWindow.setContentView()`，然后在此方法中创建了DecorView。
* **DecorView是最顶级的视图**：PhoneWindow首先创建了DecorView，然后通过DecorView构建子View`mContentParent`,最后将`mContentParent`作为我们传入的布局的父View。

![Android视图层级](./Android%E7%9A%84%E5%9B%BE%E5%83%8F%E6%9E%B6%E6%9E%84.assets/Android%E8%A7%86%E5%9B%BE%E5%B1%82%E7%BA%A7-1666707059734-2.png)



### View的绘制



### RenderThread和RenderNode

> Android 5.0引入；
>
> CPU将数据同步给GPU后，一般不阻塞等待GPU的绘制，直接返回。而GPU绘制渲染图形的操作都在`RenderThread`中执行，减轻`UIThread`的压力

`RenderNode` 中存有渲染帧的所有信息，可以做一些属性动画。

### Window Manager

> Window 是 View的容器，每个窗口都会包含一个 Surface 。

主要负责管理View的以下内容：

* 生命周期
* 输入和焦点事件
* 屏幕旋转
* 动画切换
* 位置等



## View的绘制流程

## 适配方案

px、dp、dpi、ppi、density



* 限制符适配方案

  `宽高限定符`与 `smallestWidth 限定符`适配方案。

* 今日头条适配方案

  反射修正系统的 density 值



## 参考资料

> 以上部分内容摘录自一下资料。

[图形  | Android 开源项目  | Android Open Source Project](https://source.android.com/docs/core/graphics)

[20 | UI 优化（上）：UI 渲染的几个关键概念 (geekbang.org)](https://time.geekbang.org/column/article/80921)

[Android 屏幕刷新机制 - 简书 (jianshu.com)](https://www.jianshu.com/p/0d00cb85fdf3)

[Android VSYNC与图形系统中的撕裂、双缓冲、三缓冲浅析_看书的小蜗牛的博客-CSDN博客_android 三缓冲](https://blog.csdn.net/happylishang/article/details/104196560)

[游戏中的“垂直同步”与“三重缓冲”究竟是个啥？_萧戈的博客-CSDN博客_三重缓冲](https://blog.csdn.net/xiaoyafang123/article/details/79268157)

