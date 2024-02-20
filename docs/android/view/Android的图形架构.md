# Android的图形架构

## 基础概念

罗列一些基础概念，方便快速查阅。

| 概念                     | 说明                                 | 备注                                                         |
| ------------------------ | ------------------------------------ | ------------------------------------------------------------ |
| CPU                      | 擅长逻辑运算，负责计算帧数据。       | 控制器复杂，算术逻辑单元ALU（Arithmetic Logic Unit）较少，   |
| GPU                      | 擅长大量的数学运算，适合进行图形渲染 | 控制器较简单，但是包含大量ALU。                              |
| Buffer                   | 缓冲区，保存渲染好的图形             |                                                              |
| Display                  | 显示设备                             | 从缓冲区读取数据并显示。                                     |
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
| Graphic Buffer           | 装载栅格化的绘制内容                 | Android 4.1 之前使用的是 双缓冲机制；Android 4.1之后引入三缓冲机制，会动态调整，一般还是使用双缓冲，除非发生Jank。 |
| SurfaceFlinger           | 图像流消耗方                         | 使用 OpenGL 和 Hardware Composer 来合成一组 Surface，然后发送给屏幕 |



### 帧和帧率

* **帧（Frame）**：就是指一幅图像。

* **帧率（Frame Rate）**：指一秒内能生成多少帧（图像）。

例如 帧率 = 300fps：表示一秒能生成300幅画面。一帧的周期是3.3ms



### 帧缓冲

帧缓冲（Frame Buffer）就是指**一段存储 图像帧数据 的存储区域**。

`FrameBuffer` 由Linux系统中的 `FrameBuffer Device（FBD）`虚拟设备提供。和它针对不同的硬件提供了一套统一的标准接口，应用层可以通过这些标准接口来输入/输出图像。例如  `ioctl()`、`mmap`、`read()`、`write()`等系统调用。

### 逐行扫描

表示的是显示设备图形显示的方式。实际上显示设备并不是一次性显示图片的，而是**从左到右，从上到下逐行扫描依次更新像素点**。常见的屏幕刷新率 60hz，就是指1秒包括60次完整的扫描周期，单次耗时 16.6ms。

> 当一个扫描周期结束进入下一个扫描周期时 存在一段时间空隙：`Vertical Blanking Interval(VBI)`，常被用于执行缓冲区交换，此时会发送 V-sync。

### 屏幕刷新率

**屏幕刷新率** 指一秒内屏幕刷新的次数，即表示**一秒内能显示多少帧图像**。

屏幕刷新率`60Hz`：表示一秒内设备刷新了60次，一次屏幕完整刷新的耗时大约为`16.6ms`。

帧率 和 屏幕刷新率的区别：

* **帧率**：是指**生成图像的速度**。

* **屏幕刷新率**：是**显示图像的速度**。

### 画面显示存在的问题

#### 画面撕裂（tearing）

画面撕裂 `tearing`就是指 **屏幕内显示的数据来自不同的帧**，从而画面出现撕裂感。 来子不同帧的原因可能是 **帧数据未写完整就用于显示**，或者 **当前屏幕还在执行逐行扫描更新，但是此时缓冲区中的数据发生了变化**。

* **帧数据未写完整**：**仅发生在单缓冲区下**。由于仅一个缓冲区，当屏幕刷新和帧率并不同步时，那么必然会出现新数据还在写，屏幕就去读取并显示这不完整的数据。于是出现了双缓冲技术 来进行读写分离，同时仅写完后才允许交换，保证帧数据的完整性。
* **屏幕显示过程中，缓冲区数据发生变化**：单缓冲区和双缓冲区都可能发生。
  * 单缓冲区就是 屏幕在更新显示时，写入了新数据，覆盖了当前要显示的数据。
  * 双缓冲区虽然通过读写分离解决了 写数据不完整导致的画面撕裂，但是若在**屏幕还没有完全显示的情况下缓冲区发生了交换**，依然会出现画面撕裂，原因就是 swap buffer 发生在数据写完时 且 帧率大于屏幕刷新率。所以仅依靠双缓冲无法彻底解决 tearing问题。

所以若要彻底避免出现 tearing，还需要解决 缓冲区交换时机的问题，这里使用的就是**垂直同步（VSYNC）技术**，将帧率和屏幕刷新率同步，相当于加了同步锁，在VSYNC 到来时进行缓冲区交换。

> 单缓冲 + 垂直同步也能解决画面撕裂，但是这样会导致读写无法并发，性能大大降低。

#### 丢帧（Jank）

> 丢帧（掉帧）不同于跳帧，丢帧并没有丢弃不再显示只是**延迟显示**。
>
> 卡顿会导致丢帧，但是丢帧不一定就是卡顿导致的。

丢帧就是指 **在下一个 VSYNC 到来时 由于CPU/GPU 没有在一个周期内准备好新的帧数据，从而导致依然显示之前一帧的旧数据，新的一帧数据需要再等一个 VSYNC 才能显示 的问题**，这一帧数据的显示发生了延迟。

导致出现丢帧的原因：

* **卡顿**：在双缓冲中由于CPU/GPU 需要处理的内容过多，**一帧数据无法在一个VSYNC周期内完成**，导致帧率降低，感觉卡顿。
* **系统机制问题**：Android 4.1之前 处理 VSYNC信号时会存在由于UI绘制不及时（去处理其他事情）而导致发生丢帧问题。4.1之后 使用同步屏障保证VSYNC来时 先处理 UI 避免了这种情况。



#### 跳帧和画面拖慢

跳帧、追帧：CPU能在一帧内产生多张图片，但是GPU压力大，只能显示最新的，跳过前面的几帧数据。

画面拖慢：CPU压力大，逻辑处理时间大于一帧。



### 垂直同步（VSYNC）

> 垂直同步 ： Vertical Synchronization（VSYNC）

**VSYNC 信号是由屏幕发送的**，每次屏幕扫描完毕，并要进行下一轮扫描时会出现一个垂直同步脉冲（vertical sync pulse），通知系统屏幕开始刷新，它就是VSYNC信号。即当设备刷新频率是 60Hz时，一秒内 会发送 60次 VSYNC信号，每次间隔大约16.6ms。

#### 垂直同步解决了什么问题

> 垂直同步解决了画面撕裂的问题

**VSYNC 强制了 帧率 和 屏幕刷新率 保持同步，只有帧数据准备完成且收到 VSYNC 才能用于显示**。

* 保证数据完整性：未处理完则当前帧依然展示之前的数据。
* 保证显示过程数据不发生变化：即使帧数据已准备完毕，也要等到 VSYNC 信号时才使用准备好的帧数据。

在Android中收到 VSYNC 将执行以下操作：

* Android4.1之前：只用在最后缓冲区切换的显示阶段，目的就仅仅是为了防止出现画面撕裂。
  * 存在的问题就是绘制并不具备最高优先级可能会先区处理其他工作，什么时候执行绘制它是随机的，即使这一帧数据的准备时间很快，远远小于一个VSYNC周期，也可能由于在最后才执行而导致下一个VSYNC来时新一帧的数据没有准备好，显示的依然是上一帧的数据，产生了丢帧。

* Android4.1之后增加：在保证不出现画面撕裂的前提下进一步优化丢帧的问题，此时VSYNC信号还会协调UI的绘制，在同步屏障机制的保证下，VSYNC信号到来时会优先处理UI，CPU/GPU 会立即**准备下一帧数据**。

#### 垂直同步导致的问题

垂直同步也导致了性能下降的问题。

* ⚠️**帧数下降**：**GPU性能再高也会被同步成屏幕刷新率**。且在低性能下帧数将进一步降低。例如当设备的GPU性能比较低下，需要1.5个 VSYNC 周期才能处理完成，但是由于垂直同步机制，我们要多等一个 VSYNC 信号，即2个VSYNC才输出，导致理论上的40帧 变成了实际的30帧，本就不高的帧数将进一步降低。
* ⚠️**延迟**：开启垂直同步期间，GPU已准备好数据后将不再工作，即使周期内剩余的时间够再处理一帧数据，也将等待VSYNC后才准备下一帧。这样就是导致当我们在做一个连续操作时，看到的并不一定是最新的，也就是产生了延迟。



### 多缓冲机制

> 双缓冲、三缓冲等机制主要是为了提升性能。
>
> 缓冲区是按需分配的：
>
> Back Buffer 不一定存在：帧率和刷新率完全一致时不存在并发读写问题，此时单缓冲就够用。当帧率和刷新率不同时才需要创建 Back Buffer 。（大多数情况双缓冲即可）
>
> Triple Buffer 也是在需要时才会创建：由于GPU处理太慢而导致发生掉帧。

#### 单缓冲机制

仅有一个帧缓冲`FrameBuffer`。

##### 单缓冲工作流程

CPU/GPU准备好数据后 往buffer 中写, display 读取帧数据并逐行显示。

##### 单缓冲 tearing 问题

出现的原因可以归类为**并发读写问题**，所以通过**垂直同步使两边频率保持一致从而避免了并发问题，解决了画面撕裂**。

当仅有一个帧缓冲区且无垂直同步时，由于 CPU/GPU 随时可能往buffer中写数据，因此可能出现以下两种情况：

* **显示器显示过程中数据发生变化**：当A帧尚未完全显示在屏幕上，下一帧数据B帧数据却已准备完毕并被写入了 buffer 中覆盖了A帧数据，接着显示器上之前未显示的部分将会显示B帧。结果就是**上面是A帧数据下面是B帧数据，画面出现撕裂感**。
* **帧数据尚未准备完毕**：当前帧数据尚未处理完成被显示器读取并显示，此时也将产生撕裂。

##### 单缓冲 + VSYNC的性能下降问题

> 使用 单缓冲 + VSYNC 处理画面撕裂问题，但是却会导致性能降低。

CPU/GPU的写 需要等待 显示器完成读取和显示，变成了完全的单线程模式，降低了整体性能。所以为了优化性能需要使用了 **双缓冲技术**，双缓冲能将读写分离从而提高性能。

![img](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/30a45ebce7f0995f2f900d67852e028e.png)

#### 双缓冲机制

> 双缓冲使得读写分离，保证数据完整性的同时也提高了性能，一定程度上降低画面撕裂的出现。配合 VSYNC 能彻底解决 画面撕裂问题。

双缓冲顾名思义存在2个帧缓冲区, **一个用于绘制（Back Buffer）**，**一个用于显示（Front Buffer）**。仅当 Back Buffer 处理完数据后才允许进行缓冲区交换（Swap Buffer）。因此保证了数据的完整性，一定程度上减少了tearing的出现。

##### 双缓冲 无 VSYNC时存在 tearing 和 掉帧问题

> 如果没有 VSYNC ，**仅依靠双缓冲依然可能出现撕裂现象，高帧率下更加明显**。

假设在屏幕未完全显示期间 两个buffer进行了交换，后续显示的内容将会是其他帧的数据，依然出现了画面撕裂的问题。所以还**需要依靠垂直同步来限制Swap buffer的时机**。

同时如果没有VSYNC，即使 CPU/GPU 处理数据的时间远远小于一个VSYNC周期（帧率大于刷新率），但是由于CPU不知道什么时候应该处理UI，所有可能会先处理其他事情而并不即使处理UI绘制，等处理时又错过了屏幕刷新的周期，得等待屏幕下一次刷新，从而导致本不该出现掉帧情况出现了掉帧。而使用 VSYNC 控制UI绘制时机则可避免这种情况。

##### 双缓冲 + VSYNC 流程分析

首先 CPU/GPU 会将内容绘制到 Back Buffer ，当接收到 VSYNC 时，通过 Swap Buffer 将 Back Buffer 和 Front Buffer 进行交换（仅在显示器需要时才交换），这样 CPU/GPU 的就可以直接处理下一帧不再需要阻塞等待，也不会影响显示，提高了性能。

> 蓝色：CPU耗时；使用Back Buffer
>
> 绿色：GPU耗时；使用Back Buffer
>
> 黄色：当前屏幕显示的是第几帧画面。使用Front Buffer
>
> App没有必要刷新时，CPU/GPU不执行，每次刷新将显示同一帧数据。

![img](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/webp.webp)

##### 双缓冲 + VSYNC 的丢帧问题

当GPU绘制时间过长，使得CPU + GPU的耗时超过了一个 VSYNC 信号周期时出现掉帧（帧率小于刷新率）。此时一个缓存区被GPU用于绘制，一个缓存区则被用于显示。**由于 CPU 和 GPU 是共用一个通道的，且GPU真正使用通道，所以将导致CPU空闲等待，甚至在当前周期内GPU处理完成后，CPU/GPU都将空闲**，浪费了性能，当下一个VSYNC到来，又将重复这个流程。

* 每次都需要延迟一帧才能显示画面，产生丢帧。
* CPU/GPU 空转，浪费性能。

![img](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/551fb7b5a8a0bed7d81edde6aff99653.png)

#### 三缓冲机制（Triple Buffer）

> Android 4.1 (Jelly Bean) 开始为了优化性能处理丢帧问题，启动了 Project Butter 黄油计划：包括 `VSYNC`、`Triple Buffer`和`Choreographer(用于协调VSYNC 和 view绘制)`。

三缓冲包含 一个 `Front Buffer`，两个 `Back Buffer`。

在三缓冲 + VSYNC的方案中由于多了一个 Buffer 使得当新的VSYNC 到来时，即使GPU仍在处理，CPU也不会由于和GPU争抢同一个Buffer而导致空闲等待，此时 CPU 可以使用新增的Buffer去立即处理数据，将之前空转的时间利用起来，提高了CPU/GPU的利用率，同时也减少了丢帧现象的出现。

* 充分发挥CPU/GPU并行处理的效率。
* 第一帧的丢帧无法避免，但是可以优化后续的丢帧现象。
* 由于存在3个缓冲区，导致**实际显示的并不是GPU处理完的最新帧，存在一帧的延迟**。因此Android 平时都是双缓冲机制，仅在发生Jank 时会切换到三缓冲

![img](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/4d84d2d6a8f8e25e1622665141d993ed.png)



## Android 页面显示流程

> 官方提供了一个学习参考案例：[google/grafika: Grafika test app (github.com)](https://github.com/google/grafika)

我们在开发时一般都是在Activity中设置我们的布局，应用启动后打开对应的页面就能在屏幕上面看到我们设置的布局。所以我们可以将Activity的创建过程作为切入点，进而了解 Android UI 是如何一步步显示到屏幕上的。详细的源码分析我放在了 [Activity启动流程](./system/Android之Activity启动流程.md) 这篇文章中。

大致可以概况为两个大的步骤：

* **页面视图框架的搭建**：主要是处理一个页面中的层级关系，将职责划分开。此时不涉及到渲染。
* **渲染和上屏**：页面的框架搭好后就是 页面的绘制渲染以及上屏。

### 页面视图框架的搭建

* **创建Activity**：`ActvityThread` 接收到 Activity 的创建消息后 会调用 `handleLaunchActivity()`  这个函数，内部通过反射创建了 Activity。
* **创建`PhoneWindow`**：Activity 创建后会先被调用`Activity.attach()`函数，它创建了 `PhoneWindow` 这个 Window，用于承载我们的view。
* **创建DecorView**：之后会调用我们熟悉的生命周期函数： `Activity.onCreate()`。我们会在这里调用 `setContentView()` 来传入我们需要显示的布局，它实际上调用的 `PhoneWindow.setContentView()`，它首先会在创建一个 `DecorView`，并加载 DecorView的布局。
* **创建我们的布局**：DecorView 中包含一个child `mContentParent`。在创建我们传入的布局时会将他作为 parent。

![Android视图层级](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/Android%E8%A7%86%E5%9B%BE%E5%B1%82%E7%BA%A7-1666707059734-2.png)

| 视图组件       | 类           |                                                              |
| -------------- | ------------ | ------------------------------------------------------------ |
| Activity       | MainActivity | 一个Activity 关联一个Window。                                |
| Window         | PhoneWindow  | 承载了视图的显示、控制顶层窗口的外观和行为。包括绘制背景和标题栏、默认的按键处理等。Window 可以是Activity、Dialog等。 |
| View           | DecorView    | View是一个基本的UI单元，占据屏幕的一块矩形区域，可用于绘制，并能处理事件。 |
| ViewRoot       | ViewRootImpl | 持有了 DecorView，并且会和WMS 、Surface等交互。              |
| Surface        | Surface      | 一个Window 关联 一个 Surface                                 |
| SurfaceFlinger |              | 控制窗口的合成，将需要显示的多个Window合并成一个，然后发送给屏幕。 |
| WindowManager  |              |                                                              |

## 渲染整体架构

[图形  | Android 开源项目  | Android Open Source Project](https://source.android.com/docs/core/graphics?hl=zh-cn)

通过上面的步骤，我们应用中一个Activity的视图框架就搭建好了，接着就是了解视图的绘制流程。在Android中，所以的内容最终都会渲染到 Surface上，Google提供了一张 Surface渲染过程中关键组件间的协同图：

![surface渲染](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/ape-fwk-graphics.png)



这个图将中包括 以下几个组成部分：

* **Image Stream Producers**：图像流生产者。可以是生成图形缓冲区以供消耗的任何内容。
  * 最常见的就是应用端，实质是 surface，最终传递给 framework 的 RenderThread 线程来渲染。

  * 其他还有 `OpenGL ES`、`Canvas 2D` 、`mediaserver` 视频解码器等。

* **Image Stream Consumers**：图像流消费者。
  * 最常见消费方是 `SurfaceFlinger`，它从BufferQueue中获取图像流数据，使用OpenGL 和 Hardware Composer 来合成 Surface，接着交给HAL。

  * OpenGL ES 应用也可以消耗图像流，例如相机应用会消耗相机预览图像流。非 GL 应用也可以是使用方，例如 `ImageReader` 类。

* **Window Positioning**：

* **Native Framework** ：`RenderThread` 获取surface 的 buffer，通过 OpenGL 渲染后重新把缓冲区放回 BufferQueue。
* **HAL**：硬件混合渲染器。将最终图像交给屏幕显示。





![图形数据流](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/graphics-pipeline.png)





UI线程会逐帧执行布局并渲染到缓冲区。

### BufferQueue

缓冲队列 `BufferQueue`  连接了 图形数据的成产者 和 图形数据的消费者。

缓存区的特点：

* BufferQueue 永远不会复制数据，而是通过句柄进行传递。

* 首次从 BufferQueue 请求某个缓冲区时，该缓冲区将被分配并初始化为零。必须进行初始化，以避免意外地在进程之间共享数据。

* 重复使用缓冲区时，以前的内容仍会存在。

Google提供一张BufferQueue的通信过程图：

![BufferQueue 通信过程](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/bufferqueue.png)



* 生成者调用`dequeueBuffer()` 从 BufferQueue 中获取一个可用的缓冲区。
* 生成者向缓冲区绘制数据，绘制完毕后调用`queueBuffer()`使缓冲区入队。
* 消费者通过 `acquireBuffer()` 从 BufferQueue 中获取到该缓冲区，并使用缓冲区数据进行合成处理。
* 消费者使用完毕后，通过调用 `releaseBuffer()` 将该缓冲区放回队列。

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



### PageFlipping

PageFlipping 即画面交换，指分配了一个能容纳两帧数据的缓冲，前面一个缓冲叫 `FrontBuffer`，后面一个缓冲叫 `BackBuffer`.

* 消费者使用FrontBuffer中的旧数据，而生产者用新数据填充 BackBuffer，二者互不干扰。

* 当需要更新显示时，BackBuffer 变成 FrontBuffer，FrontBuffer 变成 BackBuffer



### Surface 混合方式

Surface 支持软件混合 和 硬件混合：

* 软件混合：例如使用 `copyBlt` 进行源数据和 目标数据的混合
  * copyBlt：数据拷贝，  也可以由硬件实现。
* 硬件混合：使用 `Overlay` 系统提供的接口。
  * Overlay：必须有硬件支持。主要用于视频的输出





### 



## 绘制流程

Android中有两种绘制方式：**软件绘制**和**硬件绘制**。

流程如下：

* 画笔：Skia/OpenGL ES
* 画布：Surface
* 画板：Graphic Buffer
* 显示：SurfaceFlinger

无论是使用 Skia 软件绘制，还是使用OpenGL硬件绘制，最终都是绘制到 Surface上，而Surface会通过缓冲区向 SurfaceFlinger提供数据，最终 SurfaceFlinger将多个数据合成一组 Surface 展示到屏幕上。

![软件绘制和硬件绘制](./Android%E7%9A%84%E5%9B%BE%E5%BD%A2%E6%9E%B6%E6%9E%84.assets/%E8%BD%AF%E4%BB%B6%E7%BB%98%E5%88%B6%E5%92%8C%E7%A1%AC%E4%BB%B6%E7%BB%98%E5%88%B6.png)

### 软件绘制

> Skia、CPU

应用程序内使用`Skia`将内容绘制到`Surface`上，仅依靠**CPU绘制渲染栅格化**的过程。

CPU处理数据（view的绘制过程） -> Skia渲染 -> 缓存到buffer中 -> 从buffer获取数据显示。

### 硬件绘制

> OpenGL ES、GPU

应用程序内调用`OpenGL ES`接口利用**GPU处理和渲染图形**。

部分不能使用硬件加速的情况（如渐变、磨砂、圆角、SVG等）将会使用软件绘制，此时渲染性能将变低。。

CPU处理数据 （view的绘制过程）-> GPU渲染 -> 缓存到buffer中 -> 从buffer获取数据显示。



## Window和 WindowManager

**Window 是 View的容器**，每个Window都会包含一个 Surface，Android所有的视图（Activity、Dialog、Toast等）最终都是通过 Window来呈现的，具体的实现类时 PhoneWindow。

主要负责管理View的以下内容：

* 生命周期：添加、删除、更新View。
* 输入和焦点事件
* 屏幕旋转
* 动画切换
* 位置等

### Window分类

* 应用Window：例如Activity
* 子Window：场景的Dialog一般为子Window。子Window比如存在一个父Window。
* 系统Window：一般需要声明特殊的权限才能创建系统Window。
  * ``<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />``

| Flag                  |                                                              |                                                              |
| --------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| FLAG_NOT_FOCUSABLE    | 表示Window不需要获取焦点，也不需要接收各种输入事件，事件会直接传递给下层的具有焦点的Window | 设置这个标记后会同时添加FLAG_NOT_TOUCH_MODAL                 |
| FLAG_NOT_TOUCH_MODAL  | 仅处理当前Window区域内的单击事件，区域外的单击事件传递给底层的Window。 | 一般都会添加这个标记，除非不希望其他window收到点击单击事件。如何不设置这个标记，其他Window无法收到点击事件。 |
| FLAG_SHOW_WHEN_LOCKED | 开启后 会显示在锁屏界面上。                                  |                                                              |

### WindowManager

**WindowManager则是我们访问Window的入口**。具体的实现类是 WindowManagerImpl，



## View的绘制



### RenderThread和RenderNode

> Android 5.0引入；
>
> CPU将数据同步给GPU后，一般不阻塞等待GPU的绘制，直接返回。而GPU绘制渲染图形的操作都在`RenderThread`中执行，减轻`UIThread`的压力

`RenderNode` 中存有渲染帧的所有信息，可以做一些属性动画。



### Surface

> 表示缓冲区队列中的生产方。
>
> ⚠️`SurefaceView` 和 `TextureView`有自己单独的Surface。

不同的 View 或者 Activity 会共用一个 Window ， 而每个 Window 都会关联一个`Surface`。Surface是一个接口，供 生产方 与 消耗方 交换缓冲区。

* Surface  包含 一个 `BufferQueue` 缓存队列，队列中有两个 `Graphic Buffer` 。可以通过 `canvas()`写入。
  *  **Off Screen Buffer**：用于绘制。
  *  **Front Graphic Buffer**：用于显示。

* 应用通过 `SurfaceHolder` 接口控制 Surface 将图像渲染到屏幕上。



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



### 层和屏幕

我们手机屏幕位于一个 `XYZ` 三维坐标中：

* X：对于 LTR 是从屏幕左边指向右边，左边界为0。RTL 则相反。
* Y：从上指向下。上边界为0 。
* Z：从屏幕内部指向外部。图像之间层层叠加，顶层会覆盖底层。存在**图层(Layer)**的概念，和 PS 中的图层一样。

SurfaceFlinger对这些按照Z轴排好序的显示层进行图像混合，混合后的图像就是我们在屏幕上看到的画面。

Surface中不同的layer定义：	

[ISurfaceComposerClient.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/libs/gui/include/gui/ISurfaceComposerClient.h;l=31?q=ISurfaceComposerClient&ss=android%2Fplatform%2Fsuperproject)

| Flag                  | Layer            |                                                              |
| --------------------- | ---------------- | ------------------------------------------------------------ |
| eFXSurfaceBufferQueue | BufferStateLayer | 标准的Surface                                                |
| eFXSurfaceBufferState | BufferStateLayer | 标准的Surface                                                |
| eFXSurfaceEffect      | EffectLayer      | 标准的Surface                                                |
| eFXSurfaceContainer   | ContainerLayer   | 创建surface容器。此surface没有缓冲区，仅用作其他surfaces或InputInfo的容器。 |
| eFXSurfaceMask        |                  |                                                              |





## 适配方案

| 名词            | 说明                                                         |
| --------------- | ------------------------------------------------------------ |
| px              | 像素，图片的最小单位。                                       |
| in              | 英寸，1in = 2.54cm。手机的屏幕尺寸指的就是手机对角线长度。   |
| dpi             | 点密度，印刷业使用的单位，表示每英寸包含的 墨点数数量。      |
| ppi             | 像素密度，表示屏幕 每英寸包含的像素点数量。                  |
| densityDpi(dpi) | 像素密度，和 ppi 一个意思。                                  |
| density         | 屏幕密度，以160dpi为基准，`density = densityDpi / 160`。     |
| dp              | Android中定义的UI长度单位，同尺寸下不同分辨率下它们的宽高dp值是一样的，只是density 不同，从而保证显示效果一致。以160dpi为基准定义的，`1dp = density * 1px`。 |


| 屏幕类型 | 分辨率 | dpi  | 限定符 |
| -------- | ------ | ---- | ------ |
| 小屏幕   | ldpi   | 120  | small  |
| 中等屏幕 | mdpi   | 160  | normal |
| 大屏幕   | hdpi   | 240  | large  |
| 超大屏   | xhdpi  | 320  | xlarge |
| 超超大屏 | xxhdpi | 480  |        |
|          | xxxdpi | 640  |        |

| 屏幕方向 |      |      |
| -------- | ---- | ---- |
| land     | 横屏 |      |
| port     | 竖屏 |      |
|          |      |      |



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

## mipmap和drawable的区别

> mipmap 适合 应用图标，而drawable适合存放应用的图片资源（.9、png、gif、xml等等）

两者在正常情况下表现形式是一致的，仅在使用了 `Bundle(.aab)` 才会有明显的差别，Bundle会按需下载drawable：

* apk中drawable仅加载符合当前像素密度文件，而mipmap会全部保留。
* 缩放差异：drawable用于是同一张图进行缩放，mipmap则会找比分辨率大且最接近的那张来进行缩放。



## 补充

### 软件绘制源码分析

软件绘制流程的入口是在 `ViewRootImpl.drawSoftware()` 这个函数。

#### ViewRootImpl.drawSoftware()

* 从 Surface中 通过 `lockCanvas()`  获取到一块 Canvas。
* 调用 `DocorView.draw(canvas)` 将 Canvas 传给 `DocorView` 用于绘制。

[ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=4815)

```java
	private boolean drawSoftware(Surface surface, AttachInfo attachInfo, int xoff, int yoff,
            boolean scalingRequired, Rect dirty, Rect surfaceInsets) {
        // Draw with software renderer.
        final Canvas canvas;

        int dirtyXOffset = xoff;
        int dirtyYOffset = yoff;
        if (surfaceInsets != null) {
            dirtyXOffset += surfaceInsets.left;
            dirtyYOffset += surfaceInsets.top;
        }

        try {
            dirty.offset(-dirtyXOffset, -dirtyYOffset);
            final int left = dirty.left;
            final int top = dirty.top;
            final int right = dirty.right;
            final int bottom = dirty.bottom;
			// 从 mSurface 中lock一块Canvas,
            canvas = mSurface.lockCanvas(dirty);

            // TODO: Do this in native
            canvas.setDensity(mDensity);
        } catch (Surface.OutOfResourcesException e) {
            handleOutOfResourcesException(e);
            return false;
        } catch (IllegalArgumentException e) {
            mLayoutRequested = true;    // ask wm for a new surface next time.
            return false;
        } finally {
            dirty.offset(dirtyXOffset, dirtyYOffset);  // Reset to the original value.
        }

        try {
            // 使用透明通道 或 存在偏移，先清空画布
            if (!canvas.isOpaque() || yoff != 0 || xoff != 0) {
                canvas.drawColor(0, PorterDuff.Mode.CLEAR);
            }
			
            dirty.setEmpty();
            mIsAnimating = false;
            mView.mPrivateFlags |= View.PFLAG_DRAWN;
			// 复原偏移
            canvas.translate(-xoff, -yoff);
            if (mTranslator != null) {
                mTranslator.translateCanvas(canvas);
            }
            canvas.setScreenDensity(scalingRequired ? mNoncompatDensity : 0);
			// 调用 DocorView的draw()，这里开始绘制我们的布局。
            mView.draw(canvas);
			//
            drawAccessibilityFocusedDrawableIfNeeded(canvas);
        } finally {
            try {
                // unlock
                surface.unlockCanvasAndPost(canvas);
            } catch (IllegalArgumentException e) {
                Log.e(mTag, "Could not unlock surface", e);
                mLayoutRequested = true;    // ask wm for a new surface next time.
                //noinspection ReturnInsideFinallyBlock
                return false;
            }
        }
        return true;
    }
```



#### Surface.lockCanvas()

调用了 `nativeLockCanvas()` 这个本地方法，并传入了 `mNativeObject` 这个 `native surface` 的内存地址。

* 获取到了一块 用于绘制的 `bakcBuffer`。
* 将  canvas、bitmap、native surface 它们通过 buffer 关联了起来。

> [Surface.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/Surface.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=449)

```java
public class Surface implements Parcelable {
    // native surface的内存地址
    long mNativeObject; // package scope only for SurfaceControl access
    // 当前 lock住的 native surface, unlock时使用
    private long mLockedObject;
    private final Canvas mCanvas = new CompatibleCanvas();
    
    // inOutDirty
    public Canvas lockCanvas(Rect inOutDirty)
            throws Surface.OutOfResourcesException, IllegalArgumentException {
        synchronized (mLock) {
            checkNotReleasedLocked();
            if (mLockedObject != 0) {
                throw new IllegalArgumentException("Surface was already locked");
            }
            // 调用JNI，内部将 canvas、bitmap、native surface 通过buffer进行关联，
            // 返回一个新的 native surface引用
            // nativeObject: navtive surface 地址
            // canvasObj: java层的 Canvas。
            // dirtyRectObj: 需要重绘的矩形块 Rect
            // lockedSurface
            mLockedObject = nativeLockCanvas(mNativeObject, mCanvas, inOutDirty);
            return mCanvas;
        }
    }
}

```

##### 【android_view_Surface.nativeLockCanvas()】

* 首先构建一块数据缓冲区buffer。
* 将 Surface 和 buffer 以及 一块绘制区域关联。
* 根据 buffer 以及 绘制区域 构建一个Bitmap，并于 Canvas关联。
* 最后重新创建一个 Surface引用并返回地址。

在这个函数中将  canvas、bitmap、native surface 通过buffer进行关联，它们持有同一个buffer。

Canvas 向bitmap中写入数据，也就是向 buffer 中写入数据。

[android_view_Surface.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/jni/android_view_Surface.cpp;l=188?q=nativeLockCanvas)

```cpp
// nativeObject: navtive surface 地址
// canvasObj: java层的 Canvas。
// dirtyRectObj: 需要重绘的矩形块 Rect
static jlong nativeLockCanvas(JNIEnv* env, jclass clazz,
        jlong nativeObject, jobject canvasObj, jobject dirtyRectObj) {
    
    // 根据 地址获取到 surface 并 sp化。
    sp<Surface> surface(reinterpret_cast<Surface *>(nativeObject));
	// ...
	// 构建一个重绘区域 Rect
    Rect dirtyRect(Rect::EMPTY_RECT);
    Rect* dirtyRectPtr = NULL;
	// 从 dirtyRectObj 获取矩形块的信息。
    if (dirtyRectObj) {
        dirtyRect.left   = env->GetIntField(dirtyRectObj, gRectClassInfo.left);
        dirtyRect.top    = env->GetIntField(dirtyRectObj, gRectClassInfo.top);
        dirtyRect.right  = env->GetIntField(dirtyRectObj, gRectClassInfo.right);
        dirtyRect.bottom = env->GetIntField(dirtyRectObj, gRectClassInfo.bottom);
        dirtyRectPtr = &dirtyRect;
    }

    // buffer缓冲区
    ANativeWindow_Buffer buffer;
    // 将surface 和 buffer、rect关联。
    status_t err = surface->lock(&buffer, dirtyRectPtr);

	// 转换成Canvas
    graphics::Canvas canvas(env, canvasObj);
    // 
    // 传入的buffer和DataSpace 用于构建一个bitmap。
    // 因此 canvas和 buffer 关联，即绘制的数据往这个buffer中填充。
    canvas.setBuffer(&buffer, static_cast<int32_t>(surface->getBuffersDataSpace()));

    if (dirtyRectPtr) {
        canvas.clipRect({dirtyRect.left, dirtyRect.top, dirtyRect.right, dirtyRect.bottom});
    }

    if (dirtyRectObj) {
        env->SetIntField(dirtyRectObj, gRectClassInfo.left,   dirtyRect.left);
        env->SetIntField(dirtyRectObj, gRectClassInfo.top,    dirtyRect.top);
        env->SetIntField(dirtyRectObj, gRectClassInfo.right,  dirtyRect.right);
        env->SetIntField(dirtyRectObj, gRectClassInfo.bottom, dirtyRect.bottom);
    }

    // Create another reference to the surface and return it.  This reference
    // should be passed to nativeUnlockCanvasAndPost in place of mNativeObject,
    // because the latter could be replaced while the surface is locked.
    // 创建另一个 surface引用。
    sp<Surface> lockedSurface(surface);
    lockedSurface->incStrong(&sRefBaseOwner);
    return (jlong) lockedSurface.get();
}
```

##### 【Surface::lock】

* 通过 `dequeueBuffer()` 获取一块 空闲的缓冲区。
* 利用获取到的缓冲区 构建 `backBuffer: GraphicBuffer`。
* 使用上一次绘制的缓冲区 `mPostedBuffer` 构建 `frontBuffer: GraphicBuffer `。
* 判断是否可以将 `frontBuffer` 拷贝到 `backBuffer` ，若可以则拷贝，减少更新。
* 调用 `buffer.lockAsync()` 获取一块内存用于绘制。

[Surface.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/Surface.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=2421)

```cpp
// 当前绘制使用的buffer
sp<GraphicBuffer>           mLockedBuffer;

// 上一次绘制时使用的Buffer
sp<GraphicBuffer>           mPostedBuffer;

status_t Surface::lock(
        ANativeWindow_Buffer* outBuffer, ARect* inOutDirtyBounds)
{
    if (mLockedBuffer != nullptr) {
        ALOGE("Surface::lock failed, already locked");
        return INVALID_OPERATION;
    }

    if (!mConnectedToCpu) {
        int err = Surface::connect(NATIVE_WINDOW_API_CPU);
        if (err) {
            return err;
        }
        // we're intending to do software rendering from this point
        setUsage(GRALLOC_USAGE_SW_READ_OFTEN | GRALLOC_USAGE_SW_WRITE_OFTEN);
    }

    ANativeWindowBuffer* out;
    int fenceFd = -1;
    // 取出一个 空闲的buffer，赋值给 out
    status_t err = dequeueBuffer(&out, &fenceFd);
    if (err == NO_ERROR) {
        // 构建一个 GraphicBuffer 叫做 backBuffer
        sp<GraphicBuffer> backBuffer(GraphicBuffer::getSelf(out));
        const Rect bounds(backBuffer->width, backBuffer->height);

        Region newDirtyRegion;
        if (inOutDirtyBounds) {
            newDirtyRegion.set(static_cast<Rect const&>(*inOutDirtyBounds));
            newDirtyRegion.andSelf(bounds);
        } else {
            newDirtyRegion.set(bounds);
        }

        // figure out if we can copy the frontbuffer back
        // mPostedBuffer是上一次绘制时使用的Buffer
        // 构建一个 frontBuffer
        const sp<GraphicBuffer>& frontBuffer(mPostedBuffer);
        
        const bool canCopyBack = (frontBuffer != nullptr &&
                backBuffer->width  == frontBuffer->width &&
                backBuffer->height == frontBuffer->height &&
                backBuffer->format == frontBuffer->format);

        if (canCopyBack) {
            // copy the area that is invalid and not repainted this round
            // 可以拷贝前缓冲区，将 frontBuffer拷贝到 backBuffer
            const Region copyback(mDirtyRegion.subtract(newDirtyRegion));
            if (!copyback.isEmpty()) {
                copyBlt(backBuffer, frontBuffer, copyback, &fenceFd);
            }
        } else {
            // if we can't copy-back anything, modify the user's dirty
            // region to make sure they redraw the whole buffer
            // 不能拷贝则清空dirty region。需要进行全量的的更新
            newDirtyRegion.set(bounds);
            mDirtyRegion.clear();
            Mutex::Autolock lock(mMutex);
            for (size_t i=0 ; i<NUM_BUFFER_SLOTS ; i++) {
                mSlots[i].dirtyRegion.clear();
            }
        }


        { // scope for the lock
            Mutex::Autolock lock(mMutex);
            int backBufferSlot(getSlotFromBufferLocked(backBuffer.get()));
            if (backBufferSlot >= 0) {
                Region& dirtyRegion(mSlots[backBufferSlot].dirtyRegion);
                mDirtyRegion.subtract(dirtyRegion);
                dirtyRegion = newDirtyRegion;
            }
        }

        mDirtyRegion.orSelf(newDirtyRegion);
        if (inOutDirtyBounds) {
            *inOutDirtyBounds = newDirtyRegion.getBounds();
        }

        void* vaddr;
        // 调用 lock 获取一块内存，地址会保存在 vaddr中。
        status_t res = backBuffer->lockAsync(
                GRALLOC_USAGE_SW_READ_OFTEN | GRALLOC_USAGE_SW_WRITE_OFTEN,
                newDirtyRegion.bounds(), &vaddr, fenceFd);


        if (res != 0) {
            err = INVALID_OPERATION;
        } else { //  mLockedBuffer 保存当前使用的buffer
            mLockedBuffer = backBuffer;
            outBuffer->width  = backBuffer->width;
            outBuffer->height = backBuffer->height;
            outBuffer->stride = backBuffer->stride;
            outBuffer->format = backBuffer->format;
            // bits指向内存地址。
            outBuffer->bits   = vaddr;
        }
    }
    return err;
}
```

##### 【Canvas.setBuffer()】

* 根据 `buffer` 和 `DataSpace` 构建一个bitmap。
* 将bitmap 设置给 canvas。
* 后续在canvas中绘制的数据就保存在这个bitmap中。

> [canvas.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/libs/hwui/apex/include/android/graphics/canvas.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=117)

```cpp
class Canvas {
    bool setBuffer(const ANativeWindow_Buffer* buffer,
                       int32_t /*android_dataspace_t*/ dataspace) {
            return ACanvas_setBuffer(mCanvas, buffer, dataspace);
    }
}


bool ACanvas_setBuffer(ACanvas* canvas, const ANativeWindow_Buffer* buffer,
                       int32_t /*android_dataspace_t*/ dataspace) {
    SkBitmap bitmap;
    // 根据 buffer和DataSpace 构建一个bitmap。
    bool isValidBuffer = (buffer == nullptr) ? false : convert(buffer, dataspace, &bitmap);
    // 将bitmap 设置给 canvas。
    TypeCast::toCanvas(canvas)->setBitmap(bitmap);
    return isValidBuffer;
}
```



#### Surface.unlockCanvasAndPost()

调用了 `nativeUnlockCanvasAndPost()` 这个本地方法，并传入了 `mLockedObject` 这个 `native surface` 的内存地址。

* 将绘制完毕的 buffer 提交到 缓冲区队列中。
* 通知 SurfaceFlinger 更新。

> [Surface.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/Surface.java;l=471)

```java
class Surface {
    public void unlockCanvasAndPost(Canvas canvas) {
        synchronized (mLock) {
            checkNotReleasedLocked();

            if (mHwuiContext != null) {
                mHwuiContext.unlockAndPost(canvas);
            } else {
                unlockSwCanvasAndPost(canvas);
            }
        }
    }

	private void unlockSwCanvasAndPost(Canvas canvas) {
        try {
            // 调用 JNI
            nativeUnlockCanvasAndPost(mLockedObject, canvas);
        } finally {
            nativeRelease(mLockedObject);
            mLockedObject = 0;
        }
    }
}
```



##### 【android_view_Surface.nativeUnlockCanvasAndPost()】

> [android_view_Surface.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/jni/android_view_Surface.cpp;l=188?q=nativeLockCanvas)

```cpp
static void nativeUnlockCanvasAndPost(JNIEnv* env, jclass clazz,
        jlong nativeObject, jobject canvasObj) {
    sp<Surface> surface(reinterpret_cast<Surface *>(nativeObject));
    if (!isSurfaceValid(surface)) {
        return;
    }

    // detach the canvas from the surface
    graphics::Canvas canvas(env, canvasObj);
    canvas.setBuffer(nullptr, ADATASPACE_UNKNOWN);

    // unlock surface
    status_t err = surface->unlockAndPost();
    if (err < 0) {
        jniThrowException(env, IllegalArgumentException, NULL);
    }
}
```

##### 【Surface::unlockAndPost()】

* 首先 unlock 解锁缓冲区。 
* 将包含最新绘制数据的 `mLockedBuffer` 加入到缓冲队列中。
* 将 `mLockedBuffer` 赋值给 `mPostedBuffer`。最后将 `mLockedBuffer` 置空

> [Surface.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/Surface.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=2516)

```cpp
status_t Surface::unlockAndPost()
{
    int fd = -1;
    // unlock
    status_t err = mLockedBuffer->unlockAsync(&fd);
	// 将这块包含最新绘制数据的buffer 加入到缓冲队列中。
    err = queueBuffer(mLockedBuffer.get(), fd);
	// 将 mLockedBuffer赋值给 mPostedBuffer
    mPostedBuffer = mLockedBuffer;
    //
    mLockedBuffer = nullptr;
    return err;
}
```



##### 【Surface::queueBuffer()】

> [Surface.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/Surface.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=1166)

```cpp
int Surface::queueBuffer(android_native_buffer_t* buffer, int fenceFd) {
    ATRACE_CALL();
    ALOGV("Surface::queueBuffer");
    Mutex::Autolock lock(mMutex);

    int i = getSlotFromBufferLocked(buffer);
    if (i < 0) {
        if (fenceFd >= 0) {
            close(fenceFd);
        }
        return i;
    }
    if (mSharedBufferSlot == i && mSharedBufferHasBeenQueued) {
        if (fenceFd >= 0) {
            close(fenceFd);
        }
        return OK;
    }

    IGraphicBufferProducer::QueueBufferOutput output;
    IGraphicBufferProducer::QueueBufferInput input;
    getQueueBufferInputLocked(buffer, fenceFd, mTimestamp, &input);
    applyGrallocMetadataLocked(buffer, input);
    sp<Fence> fence = input.fence;

    nsecs_t now = systemTime();

    status_t err = mGraphicBufferProducer->queueBuffer(i, input, &output);
    mLastQueueDuration = systemTime() - now;
    if (err != OK)  {
        ALOGE("queueBuffer: error queuing buffer, %d", err);
    }

    onBufferQueuedLocked(i, fence, output);
    return err;
}
```

#### GraphicBuffer



### Surface创建流程

在 `ViewRootImpl.performTraversals()`  执行绘制的过程中，会调用 `relayoutWindow()` 向WMS发起 binder请求创建Surface。

WMS会创建一个 `SurfaceControl` 并由 control 来创建并管理Surface。

#### 【ViewRootImpl.relayoutWindow()】

* 通过 `mWindowSession` 向 WMS 发起了 `relayoutWindow()`  binder请求。
  * 传入的 `mWindow` 用于接收回调。
  * 传入的 `mSurfaceControl` 在binder通信中被更新为 WMS中新建的实例。
* 更新 Surface 指向 新的native层Surface。
  * 使用BLAST时，`mBlastBufferQueue`会创建的新Surface，并更新给ViewRoot中的 mSerfauce。
  * 不使用BLAST时，从 `mSurfaceControl` 更新给 `ViewRootImp.mSerfauce`。

[ViewRootImpl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/ViewRootImpl.java;l=8185)

```java
class ViewRootImpl ... {
    
    // 创建了一个 Surface 对象
    public final Surface mSurface = new Surface();
    private final SurfaceControl mSurfaceControl = new SurfaceControl();
    private final SurfaceSession mSurfaceSession = new SurfaceSession();
	// 
    private BLASTBufferQueue mBlastBufferQueue;
    
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
            // 传入了 mSurfaceControl 
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



#### 【Session.relayout()】

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



#### 【WindowManagerService.relayoutWindow()】

[WindowManagerService.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/WindowManagerService.java;l=2253)

```java
public int relayoutWindow(Session session, IWindow client, LayoutParams attrs,
            int requestedWidth, int requestedHeight, int viewVisibility, int flags, int seq,
            int lastSyncSeqId, ClientWindowFrames outFrames,
            MergedConfiguration outMergedConfiguration, SurfaceControl outSurfaceControl,
            InsetsState outInsetsState, InsetsSourceControl[] outActiveControls,
            Bundle outSyncIdBundle) {
        // ...
        synchronized (mGlobalLock) {
            // ...
            if (viewVisibility != View.GONE) {
                win.setRequestedSize(requestedWidth, requestedHeight);
            }

            int attrChanges = 0;
            int flagChanges = 0;
            int privateFlagChanges = 0;
            if (attrs != null) {
                // .....
            }

            if ((attrChanges & WindowManager.LayoutParams.ALPHA_CHANGED) != 0) {
                winAnimator.mAlpha = attrs.alpha;
            }
            win.setWindowScale(win.mRequestedWidth, win.mRequestedHeight);
            
			// ...
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

           // ...
        }
        Binder.restoreCallingIdentity(origId);
        return result;
    }
```



#### 【WindowManagerService.createSurfaceControl()】

创建一个 `SurfaceController`，并将信息更新到 传入的 `outSurfaceControl`中。

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
            // 最终调用了 SurfaceController 的构造函数，并通过 SurfaceSession 创建了 Surface。
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



#### 【WindowStateAnimator.createSurfaceLocked()】

这里创建 一个 `WindowSurfaceController`对象， `WindowSurfaceController`对象内部包含 一个 `SurfaceController`实例。

[WindowStateAnimator.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/services/core/java/com/android/server/wm/WindowStateAnimator.java;l=291)

```java
class WindowStateAnimator {
    
    WindowSurfaceController mSurfaceController;
	WindowSurfaceController createSurfaceLocked() {
        final WindowState w = mWin;
        if (mSurfaceController != null) {
            return mSurfaceController;
        }

        int flags = SurfaceControl.HIDDEN;
        final WindowManager.LayoutParams attrs = w.mAttrs;

        if (w.isSecureLocked()) {
            flags |= SurfaceControl.SECURE;
        }

        if ((mWin.mAttrs.privateFlags & PRIVATE_FLAG_IS_ROUNDED_CORNERS_OVERLAY) != 0) {
            flags |= SurfaceControl.SKIP_SCREENSHOT;
        }
        // Set up surface control with initial size.
        try {

            final boolean isHwAccelerated = (attrs.flags & FLAG_HARDWARE_ACCELERATED) != 0;
            final int format = isHwAccelerated ? PixelFormat.TRANSLUCENT : attrs.format;
			// 创建 WindowSurfaceController，它内部创建了 SurfaceControl
            mSurfaceController = new WindowSurfaceController(attrs.getTitle().toString(), format,
                    flags, this, attrs.type);
            mSurfaceController.setColorSpaceAgnostic((attrs.privateFlags
                    & WindowManager.LayoutParams.PRIVATE_FLAG_COLOR_SPACE_AGNOSTIC) != 0);

            w.setHasSurface(true);

            w.mInputWindowHandle.forceChange();
        }
		// ....

        return mSurfaceController;
    }
}	

```



### SurfaceControl

在 WMS 会创建一个 `SurfaceControl` ，它对应Native的 `android_view_SurfaceControl.cpp`。

客户端通过这个类和 `Native SurfaceControl` 交互。

* 首先在 `SurfaceControl` 的构造函数中会调用 `nativeCreate(SurfaceSession)` 返回 `mNativeObject` ，这个返回值是指向 `native SurfaceControl`的地址。

* 可以通过 `mNativeObject`这个 `SurfaceControl` 来创建一个 `Surface`对象。

[SurfaceControl.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/java/android/view/SurfaceControl.java;l=1538)

```java
public final class SurfaceControl implements Parcelable {
    
    // 指向 native SurfaceControl
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
        // 这个parcel 写入了构建SurfaceControl 的参数
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
            // 调用 SurfaceControl_nativeCreate() 创建了 SurfaceControl
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

#### 【android_view_SurfaceControl.nativeCreate()】

创建了一个 `native SurfaceControl` 并将它的地址返回。 `native SurfaceControl` 负责和 `SurfaceComposerClient(和SurfaceFlinger交互)`、`Surface` 交互。

[android_view_SurfaceControl.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/jni/android_view_SurfaceControl.cpp;l=398?q=SurfaceControl.cpp)

```cpp
// sessionObj： SurfaceSession
// parentObject：SurfaceControl
// metadataParcel：传入的参数
static jlong nativeCreate(JNIEnv* env, jclass clazz, jobject sessionObj,
        jstring nameStr, jint w, jint h, jint format, jint flags, jlong parentObject,
        jobject metadataParcel) {
    ScopedUtfChars name(env, nameStr);sessionObj
    sp<SurfaceComposerClient> client;
    // 从 sessionObj 中获取到 SurfaceComposerClient 对象。
    // SurfaceComposerClient 是用于和 SurfaceFlinger通信的。
    if (sessionObj != NULL) {
        client = android_view_SurfaceSession_getClient(env, sessionObj);
    } else {
        client = SurfaceComposerClient::getDefault();
    }
    SurfaceControl *parent = reinterpret_cast<SurfaceControl*>(parentObject);
    
    // 定义一个了 SurfaceControl, 名字却叫 surface???
    sp<SurfaceControl> surface;
    // 存放解析后数据的结构
    LayerMetadata metadata;
    Parcel* parcel = parcelForJavaObject(env, metadataParcel);
    if (parcel && !parcel->objectsCount()) {
        // 将parcel中数据解析到 metadata 中。
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
	// createSurfaceChecked() 内部创建了 SurfaceControl 实例，会赋值给传入的surface变量。
    status_t err = client->createSurfaceChecked(String8(name.c_str()), w, h, format, &surface,
                                                flags, parentHandle, std::move(metadata));

    // 强引用计数 + 1
	// 入参(void *)nativeCreate 并没有什么作用，release版中不会使用。
    surface->incStrong((void *)nativeCreate);
    // 从SurfaceControl 中获取 native SurfaceControl 的地址并返回
    return reinterpret_cast<jlong>(surface.get());
}
```

#### 【SurfaceComposerClient::createSurfaceChecked()】

[SurfaceComposerClient.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/SurfaceComposerClient.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=2106)

```cpp
// 和 SurfaceFlinger 进行 binder通信的 代理对象
sp<ISurfaceComposerClient>  mClient;

// outSurface 是传入的 SurfaceControl
// metadata
status_t SurfaceComposerClient::createSurfaceChecked(const String8& name, uint32_t w, uint32_t h,
                                                     PixelFormat format,
                                                     sp<SurfaceControl>* outSurface, uint32_t flags,
                                                     const sp<IBinder>& parentHandle,
                                                     LayerMetadata metadata,
                                                     uint32_t* outTransformHint) {
    sp<SurfaceControl> sur;
    status_t err = mStatus;

    if (mStatus == NO_ERROR) {
        // handle 是 Layer
        sp<IBinder> handle;
        sp<IGraphicBufferProducer> gbp;

        uint32_t transformHint = 0;
        int32_t id = -1;
        // 这里是一个 binder请求，请求创建 surface，surface会赋值给 handle。
        // 根据Binder机制的原理，直接找 ISurfaceComposerClient 对应的 BnSurfaceComposerClient 即可
        // 最终发现调用的是 Client.cpp，它是 SurfaceFlinger 的代理类。
        err = mClient->createSurface(name, w, h, format, flags, parentHandle, std::move(metadata),
                                     &handle, &gbp, &id, &transformHint);

        if (outTransformHint) {
            *outTransformHint = transformHint;
        }
        if (err == NO_ERROR) {
            // 使用 handle 创建一个 SurfaceControl。
            // 将 outSurface 指向这个新建的 SurfaceControl 对象
            *outSurface =
                    new SurfaceControl(this, handle, gbp, id, w, h, format, transformHint, flags);
        }
    }
    return err;
}
```



#### 【Client::createSurface()】

Client 实质是 SurfaceFlinger 的代理。调用了  `SF.createLayer()`。

> [Client.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/Client.cpp;l=75;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1)

```cpp
status_t Client::createSurface(const String8& name, uint32_t /* w */, uint32_t /* h */,
                               PixelFormat /* format */, uint32_t flags,
                               const sp<IBinder>& parentHandle, LayerMetadata metadata,
                               sp<IBinder>* outHandle, sp<IGraphicBufferProducer>* /* gbp */,
                               int32_t* outLayerId, uint32_t* outTransformHint) {
    // We rely on createLayer to check permissions.
    // 将构建参数存放到 LayerCreationArgs 中
    LayerCreationArgs args(mFlinger.get(), this, name.c_str(), flags, std::move(metadata));
    // 传入了args, outHandle 会在内部被赋值
    return mFlinger->createLayer(args, outHandle, parentHandle, outLayerId, nullptr,
                                 outTransformHint);
}

```

### 创建Layer

* 创建 一个 Layer。
* 将Layer添加到 `SurfaceFlinger.mCreatedLayers`中。

#### 【SurfaceFlinger::createLayer()】

根据不同的 flags 做不同的处理，不同类型会创建不同的 Layer，`eFXSurfaceBufferQueue`、`eFXSurfaceBufferState` 这两个表示标准的 surface，会调用 `createBufferStateLayer()`。

> [SurfaceFlinger.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/SurfaceFlinger.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=4713)
>
>  [layer flags  定义](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/libs/gui/include/gui/ISurfaceComposerClient.h;l=48)

```cpp

status_t SurfaceFlinger::createLayer(LayerCreationArgs& args, sp<IBinder>* outHandle,
                                     const sp<IBinder>& parentHandle, int32_t* outLayerId,
                                     const sp<Layer>& parentLayer, uint32_t* outTransformHint) {

    status_t result = NO_ERROR;

    // layer：显示层
    sp<Layer> layer;
	// eFXSurfaceMask
    switch (args.flags & ISurfaceComposerClient::eFXSurfaceMask) {
        case ISurfaceComposerClient::eFXSurfaceBufferQueue:
        case ISurfaceComposerClient::eFXSurfaceBufferState: { // 表示标准的 surface
            // 调用 createBufferStateLayer()这个。
            result = createBufferStateLayer(args, outHandle, &layer);
            std::atomic<int32_t>* pendingBufferCounter = layer->getPendingBufferCounter();
            if (pendingBufferCounter) {
                std::string counterName = layer->getPendingBufferCounterName();
                mBufferCountTracker.add((*outHandle)->localBinder(), counterName,
                                        pendingBufferCounter);
            }
        } break;
        case ISurfaceComposerClient::eFXSurfaceEffect:
            result = createEffectLayer(args, outHandle, &layer);
            break;
        case ISurfaceComposerClient::eFXSurfaceContainer:
            result = createContainerLayer(args, outHandle, &layer);
            break;
        default:
            result = BAD_VALUE;
            break;
    }

    if (result != NO_ERROR) {
        return result;
    }

    bool addToRoot = args.addToRoot && callingThreadHasUnscopedSurfaceFlingerAccess();
    wp<Layer> parent(parentHandle != nullptr ? fromHandle(parentHandle) : parentLayer);
    if (parentHandle != nullptr && parent == nullptr) {
        ALOGE("Invalid parent handle %p.", parentHandle.get());
        addToRoot = false;
    }
    if (parentLayer != nullptr) {
        addToRoot = false;
    }

    int parentId = -1;
    // We can safely promote the layer in binder thread because we have a strong reference
    // to the layer's handle inside this scope or we were passed in a sp reference to the layer.
    sp<Layer> parentSp = parent.promote();
    if (parentSp != nullptr) {
        parentId = parentSp->getSequence();
    }
    if (mTransactionTracing) {
        mTransactionTracing->onLayerAdded((*outHandle)->localBinder(), layer->sequence, args.name,
                                          args.flags, parentId);
    }
	// 添加 layer 到 成员变量 mCreatedLayers中
    result = addClientLayer(args.client, *outHandle, layer, parent, addToRoot, outTransformHint);
    if (result != NO_ERROR) {
        return result;
    }

    *outLayerId = layer->sequence;
    return result;
}
```

#### 【SurfaceFlinger::createBufferStateLayer()】

> [SurfaceFlinger.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/SurfaceFlinger.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=4817)

```cpp
status_t SurfaceFlinger::createBufferStateLayer(LayerCreationArgs& args, sp<IBinder>* handle,
                                                sp<Layer>* outLayer) {
    args.textureName = getNewTexture();
    // 创建 BufferStateLayer 赋值给 outLayer
    *outLayer = getFactory().createBufferStateLayer(args);
    // 获取 outLayer.handle
    *handle = (*outLayer)->getHandle();
    return NO_ERROR;
}
```

#### 【DefaultFactory::createBufferStateLayer()】

> [SurfaceFlingerDefaultFactory.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/SurfaceFlingerDefaultFactory.cpp;l=116)

```cpp
// 创建了一个 BufferStateLayer
sp<BufferStateLayer> DefaultFactory::createBufferStateLayer(const LayerCreationArgs& args) {
    return new BufferStateLayer(args);
}
```

#### 【Layer::getHandle()】

Handle 同时持有了  `SurfaceFlinger` 和 `Layer`。

> [Layer.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/Layer.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=286)

```cpp
sp<IBinder> Layer::getHandle() {
    Mutex::Autolock _l(mLock);
    if (mGetHandleCalled) {
        ALOGE("Get handle called twice" );
        return nullptr;
    }
    mGetHandleCalled = true;
    return new Handle(mFlinger, this);
}

//
class Handle : public BBinder, public LayerCleaner {
    public:
        Handle(const sp<SurfaceFlinger>& flinger, const sp<Layer>& layer)
              : LayerCleaner(flinger, layer, this), owner(layer) {}
        const String16& getInterfaceDescriptor() const override { return kDescriptor; }

        static const String16 kDescriptor;
        wp<Layer> owner;
    };

// 
class LayerCleaner {
    sp<SurfaceFlinger> mFlinger;
    sp<Layer> mLayer;
    BBinder* mHandle;
```



#### 【SurfaceFlinger::addClientLayer()】

> [SurfaceFlinger.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/SurfaceFlinger.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=3668)

```cpp
// 
std::vector<LayerCreatedState> mCreatedLayers GUARDED_BY(mCreatedLayersLock);

status_t SurfaceFlinger::addClientLayer(const sp<Client>& client, const sp<IBinder>& handle,
                                        const sp<Layer>& layer, const wp<Layer>& parent,
                                        bool addToRoot, uint32_t* outTransformHint) {
    if (mNumLayers >= ISurfaceComposer::MAX_LAYERS) {
		// ... Layer过多
        return NO_MEMORY;
    }

    {
        std::scoped_lock<std::mutex> lock(mCreatedLayersLock);
        mCreatedLayers.emplace_back(layer, parent, addToRoot);
    }

    layer->updateTransformHint(mActiveDisplayTransformHint);
    if (outTransformHint) {
        *outTransformHint = mActiveDisplayTransformHint;
    }
    // attach this layer to the client
    if (client != nullptr) { // 将 layer 和 client关联
        client->attachLayer(handle, layer);
    }

    setTransactionFlags(eTransactionNeeded);
    return NO_ERROR;
}
```





#### 【Surface.copyFrom()】

> [Surface.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/Surface.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=615)

```java
 	@UnsupportedAppUsage
    public void copyFrom(SurfaceControl other) {
        if (other == null) {
            throw new IllegalArgumentException("other must not be null");
        }

        long surfaceControlPtr = other.mNativeObject;
        if (surfaceControlPtr == 0) {
            throw new NullPointerException(
                    "null SurfaceControl native object. Are you using a released SurfaceControl?");
        }
        // 传入旧值mNativeObject 和 surfaceControlPtr
        long newNativeObject = nativeGetFromSurfaceControl(mNativeObject, surfaceControlPtr);
        // 更新
        updateNativeObject(newNativeObject);
    }
```



#### 【Surface::nativeGetFromSurfaceControl()】

[android_view_Surface.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/jni/android_view_Surface.cpp;l=283?q=nativeGetFromSurfaceControl)

```cpp
static jlong nativeGetFromSurfaceControl(JNIEnv* env, jclass clazz,
        jlong nativeObject,
        jlong surfaceControlNativeObj) {
    
    // nativeObject 转为 Surface
    Surface* self(reinterpret_cast<Surface *>(nativeObject));
    // surfaceControlNativeObj 转为 SurfaceControl
    sp<SurfaceControl> ctrl(reinterpret_cast<SurfaceControl *>(surfaceControlNativeObj));

    // If the underlying IGBP's are the same, we don't need to do anything.
    if (self != nullptr &&
            IInterface::asBinder(self->getIGraphicBufferProducer()) ==
            IInterface::asBinder(ctrl->getIGraphicBufferProducer())) {
        return nativeObject;
    }
	// 从 surfaceContrl.getSurface() 中获取 Surface
    sp<Surface> surface(ctrl->getSurface());
    if (surface != NULL) {
        surface->incStrong(&sRefBaseOwner);
    }

    return reinterpret_cast<jlong>(surface.get());
}
```



#### 【SurfaceControl::getSurface()】

[SurfaceControl.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/SurfaceControl.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=152)

```cpp
sp<SurfaceComposerClient>   mClient;
mutable sp<BLASTBufferQueue> mBbq;
mutable sp<SurfaceControl> mBbqChild;
//
mutable sp<Surface>         mSurfaceData;

sp<Surface> SurfaceControl::getSurface()
{
    Mutex::Autolock _l(mLock);
    if (mSurfaceData == nullptr) {
        // 
        return generateSurfaceLocked();
    }
    return mSurfaceData;
}

//
sp<Surface> SurfaceControl::generateSurfaceLocked()
{
    uint32_t ignore;
    auto flags = mCreateFlags & (ISurfaceComposerClient::eCursorWindow |
                                 ISurfaceComposerClient::eOpaque);
    
    // mBbq 的 SurfaceControl
    mBbqChild = mClient->createSurface(String8("bbq-wrapper"), 0, 0, mFormat,
                                       flags, mHandle, {}, &ignore);
    mBbq = sp<BLASTBufferQueue>::make("bbq-adapter", mBbqChild, mWidth, mHeight, mFormat);
    mSurfaceData = mBbq->getSurface(true);

    return mSurfaceData;
}
```



---

### BufferStateLayer

> [BufferStateLayer.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/BufferStateLayer.cpp;l=56)

```cpp
BufferStateLayer::BufferStateLayer(const LayerCreationArgs& args)
      : BufferLayer(args), mHwcSlotGenerator(new HwcSlotGenerator()) {
    mDrawingState.dataspace = ui::Dataspace::V0_SRGB;
}
```





---

### SurfaceFlinger服务

[SurfaceFlinger.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/SurfaceFlinger.h;l=187)

```cpp
// mScheduler 启动后 会回调给 ISchedulerCallback，也就是自身
class SurfaceFlinger : public BnSurfaceComposer,
                       public PriorityDumper,
                       private IBinder::DeathRecipient,
                       private HWC2::ComposerCallback,
                       private ICompositor,
                       private scheduler::ISchedulerCallback {
	
    std::unique_ptr<scheduler::Scheduler> mScheduler;
                           
//
}
```

#### mian()

向 ServiceManger 注册了 `SurfaceFlinger` 服务。

[main_surfaceflinger.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/native/services/surfaceflinger/main_surfaceflinger.cpp;l=79)

```cpp
int main(int, char**) {
    hardware::configureRpcThreadpool(1 /* maxThreads */,
            false /* callerWillJoin */);
    startGraphicsAllocatorService();
	//
    ProcessState::self()->setThreadPoolMaxThreadCount(4);
	//

    sp<ProcessState> ps(ProcessState::self());
    ps->startThreadPool();
    sp<SurfaceFlinger> flinger = surfaceflinger::createSurfaceFlinger();

    // initialize before clients can connect
    flinger->init();
	//
    // publish surface flinger
    sp<IServiceManager> sm(defaultServiceManager());
    // 添加服务
    sm->addService(String16(SurfaceFlinger::getServiceName()), flinger, false,
                   IServiceManager::DUMP_FLAG_PRIORITY_CRITICAL | IServiceManager::DUMP_FLAG_PROTO);

    sp<SurfaceComposerAIDL> composerAIDL = new SurfaceComposerAIDL(flinger);
    sm->addService(String16("SurfaceFlingerAIDL"), composerAIDL, false,
                   IServiceManager::DUMP_FLAG_PRIORITY_CRITICAL | IServiceManager::DUMP_FLAG_PROTO);

    startDisplayService(); // dependency on SF getting registered above
    // 开启looper循环 处理binder消息
    flinger->run();
    return 0;
}
```



#### SurfaceFlinger::init()

[SurfaceFlinger.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/SurfaceFlinger.cpp;l=769)

```cpp
void SurfaceFlinger::init() {
    Mutex::Autolock _l(mStateLock);
    auto builder = renderengine::RenderEngineCreationArgs::Builder()
                           .setPixelFormat(static_cast<int32_t>(defaultCompositionPixelFormat))
                           .setImageCacheSize(maxFrameBufferAcquiredBuffers)
                           .setUseColorManagerment(useColorManagement)
                           .setEnableProtectedContext(enable_protected_contents(false))
                           .setPrecacheToneMapperShaderOnly(false)
                           .setSupportsBackgroundBlur(mSupportsBlur)
                           .setContextPriority(
                                   useContextPriority
                                           ? renderengine::RenderEngine::ContextPriority::REALTIME
                                           : renderengine::RenderEngine::ContextPriority::MEDIUM);
    if (auto type = chooseRenderEngineTypeViaSysProp()) {
        builder.setRenderEngineType(type.value());
    }
    mCompositionEngine->setRenderEngine(renderengine::RenderEngine::create(builder.build()));
    mMaxRenderTargetSize =
            std::min(getRenderEngine().getMaxTextureSize(), getRenderEngine().getMaxViewportDims());

    mCompositionEngine->setTimeStats(mTimeStats);
    mCompositionEngine->setHwComposer(getFactory().createHWComposer(mHwcServiceName));
    mCompositionEngine->getHwComposer().setCallback(*this);
    ClientCache::getInstance().setRenderEngine(&getRenderEngine());

    enableLatchUnsignaledConfig = getLatchUnsignaledConfig();
    // Process any initial hotplug and resulting display changes.
    processDisplayHotplugEventsLocked();
    const auto display = getDefaultDisplayDeviceLocked();
    const auto displayId = display->getPhysicalId();


    // initialize our drawing state
    mDrawingState = mCurrentState;

    // set initial conditions (e.g. unblank default device)
    initializeDisplays();
    mPowerAdvisor->init();

    char primeShaderCache[PROPERTY_VALUE_MAX];
    property_get("service.sf.prime_shader_cache", primeShaderCache, "1");


    onActiveDisplaySizeChanged(display);

    // Inform native graphics APIs whether the present timestamp is supported:

    const bool presentFenceReliable =
            !getHwComposer().hasCapability(Capability::PRESENT_FENCE_IS_NOT_RELIABLE);
    mStartPropertySetThread = getFactory().createStartPropertySetThread(presentFenceReliable);
}
```



#### SurfaceFlinger::run()

> [SurfaceFlinger.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/SurfaceFlinger.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=483)

```cpp
void SurfaceFlinger::run() {
    mScheduler->run();
}
```

#### Scheduler.run()

开启循环从binder驱动读取消息，有新消息时会被唤醒。

[Scheduler.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/Scheduler/Scheduler.cpp;l=129;)

```cpp
// Scheduler是一个 MessageQueue
class Scheduler : impl::MessageQueue {
    void Scheduler::run() {
        while (true) {
            // binder通信那一套流程
            // 有消息时会被唤醒，并从binder驱动读取消息。
            waitMessage();
        }
	}
}
```







### 和 SurfaceFlinger 建立通信

#### SurfaceSession.java

**SurfaceSession 就是专门用于 创建/删除 和 SurfaceFlinger 通讯的SurfaceComposerClient的**。

在创建 SurfaceControl 时 会SurfaceSession来创建 SurfaceComposerClient，而SurfaceComposerClient 会和 SurfaceFlinger进行连接。

* mNativeClient：是一个SurfaceComposerClient, 负责 和 SurfaceFlinger 进行交互。

* nativeCreate() ：内部和 SurfaceFlinger 建立了连接。
* nativeDestroy()：关闭和 SurfaceFlinger 的连接。

> [SurfaceSession.java - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/base/core/java/android/view/SurfaceSession.java;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=28)
>
> 对应 `frameworks/base/core/jni/android_view_SurfaceSession.cpp`

```java
public final class SurfaceSession {
    @UnsupportedAppUsage(maxTargetSdk = Build.VERSION_CODES.R, trackingBug = 170729553)
    private long mNativeClient; // SurfaceComposerClient*
    private static native long nativeCreate();
    private static native void nativeDestroy(long ptr);

    /** Create a new connection with the surface flinger. */
    @UnsupportedAppUsage
    public SurfaceSession() {
        // 这里调用 nativeCreate() 这个JNI 创建了 SurfaceComposerClient，返回对应的地址。
        // mNativeClient:SurfaceComposerClient 和 SurfaceFlinger 进行交互。
        mNativeClient = nativeCreate();
    }

    @Override
    protected void finalize() throws Throwable {
        try {
            kill();
        } finally {
            super.finalize();
        }
    }

    @UnsupportedAppUsage
    public void kill() {
        if (mNativeClient != 0) {
            nativeDestroy(mNativeClient);
            mNativeClient = 0;
        }
    }
}
```



#### android_view_SurfaceSession.cpp

主要就是注册了 `nativeCreate()` 和 `nativeDestroy()`这两个JNI 方法。

* nativeCreate ：创建了一个 SurfaceComposerClient 并将 引用计数+1。内部和SurfaceFlinger 建立了连接。
* nativeDestroy：SurfaceComposerClient 引用计数 -1。

> [android_view_SurfaceSession.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/master:frameworks/base/core/jni/android_view_SurfaceSession.cpp;l=43?q=SurfaceSession)

```cpp
namespace android {

static struct {
    jfieldID mNativeClient;
} gSurfaceSessionClassInfo;

// 创建 SurfaceComposerClient
static jlong nativeCreate(JNIEnv* env, jclass clazz) {
    SurfaceComposerClient* client = new SurfaceComposerClient();
    // 引用计数 +1，这里会调用 onFirstRef() 进行初始化。
    client->incStrong((void*)nativeCreate);
    return reinterpret_cast<jlong>(client);
}

static void nativeDestroy(JNIEnv* env, jclass clazz, jlong ptr) {
    SurfaceComposerClient* client = reinterpret_cast<SurfaceComposerClient*>(ptr);
    // 引用计数 -1
    client->decStrong((void*)nativeCreate);
}

// 注册JNI函数
static const JNINativeMethod gMethods[] = {
    /* name, signature, funcPtr */
    { "nativeCreate", "()J",
            (void*)nativeCreate },
    { "nativeDestroy", "(J)V",
            (void*)nativeDestroy },
};

int register_android_view_SurfaceSession(JNIEnv* env) {
    int res = jniRegisterNativeMethods(env, "android/view/SurfaceSession",
            gMethods, NELEM(gMethods));
    LOG_ALWAYS_FATAL_IF(res < 0, "Unable to register native methods.");

    jclass clazz = env->FindClass("android/view/SurfaceSession");
    gSurfaceSessionClassInfo.mNativeClient = env->GetFieldID(clazz, "mNativeClient", "J");
    return 0;
}

} // namespace android
```



---

#### SurfaceComposerClient

负责和 SurfaceFlinger 交互。

[SurfaceComposerClient.cpp - 定义](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/SurfaceComposerClient.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=2019)

```cpp
// SurfaceComposerClient 继承自 RefBase
class SurfaceComposerClient : public RefBase
{
    // 通过 ISurfaceComposer.createConnection() 获得。
    // 是和 SurfaceFlinger通讯的 BpSurfaceComposer
    sp<ISurfaceComposerClient>  mClient;
}

SurfaceComposerClient::SurfaceComposerClient() : mStatus(NO_INIT) {}
```

##### 【SurfaceComposerClient::onFirstRef()】

`SurfaceComposerClient` 构造函数没什么特别，需要注意的是 它继承自 RefBase ，在 `onFirstRef()` 中做了初始化，这函数是在第一次调用 `incStrong()` 时触发的。

* 首先通过 ComposerService 获取了和一个 SurfaceFlinger 通讯的 ISurfaceComposer。
* 接着通过 ISurfaceComposer 和 SurfaceFlinger  建立连接，并获取到了了 ISurfaceComposerClient，也是一个和 SurfaceFlinger 通信的Binder接口，只不过负责业务不同。
* 后续 使用 ISurfaceComposerClient 来和 SurfaceFlinger 进行交互。

> [SurfaceComposerClient::onFirstRef()](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/SurfaceComposerClient.cpp;l=2024)

```cpp
// 初始化
void SurfaceComposerClient::onFirstRef() {
    // ComposerService 是单例模式。
    // 获取到一个 ISurfaceComposer，看下去会发现 ISurfaceComposer 实际是和 SurfaceFlinger通讯的 BpSurfaceComposer
    sp<ISurfaceComposer> sf(ComposerService::getComposerService());
    if (sf != nullptr && mStatus == NO_INIT) {
        // sf 未初始化时，进行初始化
        sp<ISurfaceComposerClient> conn;
        // ISurfaceComposer 相当于 Binder连接池服务，返回了一个 ISurfaceComposerClient 
        // 获取到的ISurfaceComposerClient，也是一个和 SurfaceFlinger通信的Binder接口，只不过负责业务不同。
        conn = sf->createConnection();
        if (conn != nullptr) {
            // 成员变量赋值
            mClient = conn;
            mStatus = NO_ERROR;
        }
    }
}
```

---



#### ComposerService

 ComposerService 继承自 Singleton，是一个单例模式，内部持有SurfaceFlinger 通讯的Binder代理对象。

>  [ComposerService.h - 定义](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/include/private/gui/ComposerService.h;l=41)

```cpp
class ComposerService : public Singleton<ComposerService>
{
    // 这是一个 IInterface，在这里实际是 SurfaceFlinger的Binder代理对象
    sp<ISurfaceComposer> mComposerService;
    sp<IBinder::DeathRecipient> mDeathObserver;
}
```

##### 【ComposerService::getComposerService()】

获取了 ComposerService 单例, 并和 SurfaceFlinger 建立了Binder通讯。

> [SurfaceComposerClient.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/SurfaceComposerClient.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=108)

```cpp
sp<ISurfaceComposer> ComposerService::getComposerService() {
    // 使用 Singleton 单例构造器 构建单例。
    ComposerService& instance = ComposerService::getInstance();
    Mutex::Autolock _l(instance.mLock);
    if (instance.mComposerService == nullptr) { // 为空, 表示未和 SurfaceFlinger建立binder通讯。
        // 这里 主要是向ServiceManager 获取 SurfaceFlinger 的Binder代理接口。
        // 最后赋值给了mComposerService
        if (ComposerService::getInstance().connectLocked()) {
            // 注册监听上报
            WindowInfosListenerReporter::getInstance()->reconnect(instance.mComposerService);
        }
    }
    return instance.mComposerService;
}
```

##### 【ComposerService::connectLocked()】

在这里向 ServiceManager 获取名为 `SurfaceFlinger`的服务的Binder通讯接口 BpSurfaceComposer，并赋值给 mComposerService。

[SurfaceComposerClient.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/SurfaceComposerClient.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=84)

```cpp
bool ComposerService::connectLocked() {
    // 服务名: SurfaceFlinger
    const String16 name("SurfaceFlinger");
    // waitForService() 是向 serviermanager请求获取 SurfaceFlinger 服务。
    mComposerService = waitForService<ISurfaceComposer>(name);
    if (mComposerService == nullptr) {
        return false; // fatal error or permission problem
    }
	// 监听 SurfaceFlinger 
    // Create the death listener.
    class DeathObserver : public IBinder::DeathRecipient {
        ComposerService& mComposerService;
        virtual void binderDied(const wp<IBinder>& who) {
            mComposerService.composerServiceDied();
        }
     public:
        explicit DeathObserver(ComposerService& mgr) : mComposerService(mgr) { }
    };

    mDeathObserver = new DeathObserver(*const_cast<ComposerService*>(this));
    IInterface::asBinder(mComposerService)->linkToDeath(mDeathObserver);
    return true;
}
```



#### 【SurfaceFlinger::createConnection()】

创建了一个 Client 并返回，用于binder通讯。

[SurfaceFlinger.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/SurfaceFlinger.cpp;l=487;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=1;bpt=1)

```cpp
sp<ISurfaceComposerClient> SurfaceFlinger::createConnection() {
    // 创建一个 Client 内部持有 SurfaceFlinger自身。
    // Client 是一个 BnSurfaceComposerClient
    const sp<Client> client = new Client(this);
    return client->initCheck() == NO_ERROR ? client : nullptr;
}
```



#### Client

Client 实质是 SurfaceFlinger 的代理。Client接受客户端的请求，然后把处理提交给SurfaceFlinger。

> [Client.cpp - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/services/surfaceflinger/Client.cpp;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;l=36)

```cpp
// 这里保存了 layer
// key 是 Handle。value是 Layer。
DefaultKeyedVector< wp<IBinder>, wp<Layer> > mLayers;

// Client 是 binder 通讯的服务端实现
class Client : public BnSurfaceComposerClient {
    sp<SurfaceFlinger> mFlinger;
}

// 实质是个代理，内部实现是调用 mFlinger->createLayer()。
status_t Client::createSurface(const String8& name, uint32_t /* w */, uint32_t /* h */,
                               PixelFormat /* format */, uint32_t flags,
                               const sp<IBinder>& parentHandle, LayerMetadata metadata,
                               sp<IBinder>* outHandle, sp<IGraphicBufferProducer>* /* gbp */,
                               int32_t* outLayerId, uint32_t* outTransformHint) {
    // We rely on createLayer to check permissions.
    LayerCreationArgs args(mFlinger.get(), this, name.c_str(), flags, std::move(metadata));
    // 这里
    return mFlinger->createLayer(args, outHandle, parentHandle, outLayerId, nullptr,
                                 outTransformHint);
}
```

#### ISurfaceComposerClient

定义了 binder通讯接口 以及 几个业务接口，包括`createSurface()`等。

[ISurfaceComposerClient.h - Android Code Search](https://cs.android.com/android/platform/superproject/+/refs/heads/master:frameworks/native/libs/gui/include/gui/ISurfaceComposerClient.h;drc=7346c436e5a11ce08f6a80dcfeb8ef941ca30176;bpv=0;bpt=1;l=31)

```cpp
class ISurfaceComposerClient : public IInterface {
public:
    // binder通讯相关
    DECLARE_META_INTERFACE(SurfaceComposerClient)
        
    // 业务接口
    virtual status_t createSurface(const String8& name, uint32_t w, uint32_t h, PixelFormat format,
                                   uint32_t flags, const sp<IBinder>& parent,
                                   LayerMetadata metadata, sp<IBinder>* handle,
                                   sp<IGraphicBufferProducer>* gbp, int32_t* outLayerId,
                                   uint32_t* outTransformHint) = 0;
    virtual status_t createWithSurfaceParent(const String8& name, uint32_t w, uint32_t h,
                                             PixelFormat format, uint32_t flags,
                                             const sp<IGraphicBufferProducer>& parent,
                                             LayerMetadata metadata, sp<IBinder>* handle,
                                             sp<IGraphicBufferProducer>* gbp, int32_t* outLayerId,
                                             uint32_t* outTransformHint) = 0;
    virtual status_t clearLayerFrameStats(const sp<IBinder>& handle) const = 0;
    virtual status_t getLayerFrameStats(const sp<IBinder>& handle, FrameStats* outStats) const = 0;
    virtual status_t mirrorSurface(const sp<IBinder>& mirrorFromHandle, sp<IBinder>* outHandle,
                                   int32_t* outLayerId) = 0;
};

class BnSurfaceComposerClient : public SafeBnInterface<ISurfaceComposerClient> {
public:
    BnSurfaceComposerClient()
          : SafeBnInterface<ISurfaceComposerClient>("BnSurfaceComposerClient") {}

    status_t onTransact(uint32_t code, const Parcel& data, Parcel* reply, uint32_t flags) override;
};

} // namespace android
```









---

## 参考资料

> 以上部分内容摘录自一下资料。

[图形  | Android 开源项目  | Android Open Source Project](https://source.android.com/docs/core/graphics)

[20 | UI 优化（上）：UI 渲染的几个关键概念 (geekbang.org)](https://time.geekbang.org/column/article/80921)

[Android 屏幕刷新机制 - 简书 (jianshu.com)](https://www.jianshu.com/p/0d00cb85fdf3)

[Android VSYNC与图形系统中的撕裂、双缓冲、三缓冲浅析_看书的小蜗牛的博客-CSDN博客_android 三缓冲](https://blog.csdn.net/happylishang/article/details/104196560)

[游戏中的“垂直同步”与“三重缓冲”究竟是个啥？_萧戈的博客-CSDN博客_三重缓冲](https://blog.csdn.net/xiaoyafang123/article/details/79268157)

