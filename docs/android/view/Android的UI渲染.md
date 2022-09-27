# Android的UI渲染

px、dp、dpi、ppi、density



| 概念      | 说明               | 备注                                                         |
| --------- | ------------------ | ------------------------------------------------------------ |
| CPU       | 擅长逻辑运算       | 控制器复杂，算术逻辑单元ALU（Arithmetic Logic Unit）较少，   |
| GPU       | 擅长大量的数学运算 | 控制器较简单，但是包含大量ALU。                              |
| OpenGL    | 底层图形库         | 定义了一个跨编程语言、跨平台的编程接口规格的专业的图形程序接口。适用于3D/2D。 |
| OpenGL ES | OpenGL 的嵌入式版  | OpenGL 的API子集                                             |

## Android中的绘制

| 概念                     |                                    |                                                              |
| ------------------------ | ---------------------------------- | ------------------------------------------------------------ |
| Skia                     | 执行绘制的**画笔**                 | 软件绘制引擎，CPU绘制2D图形，skia也可调用OpenGL实现3D效果。  |
| OpenGL ES                | 执行绘制的**画笔**                 | 硬件绘制，GPU绘制3D/2D图形                                   |
| Surface                  | 被绘制和渲染的**画布**             | 每个Window都会关联一个 Surface；Android4.4+进行绘制和渲染的地方。 |
| Graphic Buffer           | 装载栅格化的绘制内容，类似**画板** | Android 4.1 之前使用的是双缓冲机制；Android 4.1+ 使用的是**三缓冲机制**。 |
| SurfaceFlinger           | **合成并输出显示**                 | 通过硬件合成器 Hardware Composer 合成并输出到显示屏          |
| HWC（Hardware Composer） | 硬件合成器                         | 硬件合成器，是控制器系统的硬件抽象，减轻GPU的负载。          |

> 软件绘制和硬件绘制的大体流程

![软件绘制和硬件绘制](./Android%E7%9A%84UI%E6%B8%B2%E6%9F%93.assets/%E8%BD%AF%E4%BB%B6%E7%BB%98%E5%88%B6%E5%92%8C%E7%A1%AC%E4%BB%B6%E7%BB%98%E5%88%B6.png)

### 软件绘制

> Skia

应用程序内使用`Skia`将内容绘制到`Surface`上，仅依靠**CPU绘制渲染栅格化**的过程。

### 硬件绘制

> OpenGL ES、GPU

应用程序内调用`OpenGL ES`接口利用**GPU处理和渲染图形**。

部分不能使用硬件加速的情况将会使用软件绘制，此时渲染性能将变低。比如：渐变、磨砂、圆角、SVG等。



### VSYNC信号

> 若设备刷新频率是 60Hz，则一帧大约为16ms。

每收到 VSYNC 中断，CPU/GPU 会立即准备 Buffer 数据，`SurfaceFlinger`将已准备好的数据进行合成展示。

### Surface

> `Surface`有一个`BufferQueue`缓存队列，队列中有两个`Graphic Buffer`。

不同的`View`或者`Activity`会共用一个`Window`, 而每个`Window`都会关联一个`Surface`。

`SurefaceView` 和 `TextureView`有自己单独的Surface。

### Graphic Buffer

> 离屏缓冲区（OffScreen Buffer）：用于绘制；
>
> Front Graphic Buffer：用于显示；

首先会将内容绘制到`OffScreen Buffer`，在需要显示时(VSYNC)，通过`Swap Buffer`将其中的数据复制到`Front Graphic Buffer`

**双缓冲**

> `OffScreen Buffer` 和 `Front Graphic Buffer`

双缓冲存在的问题是：当GPU绘制时间过长，使得`CPU + GPU的耗时`超过了一个VSYNC信号周期, 此时一个缓存区被用于绘制，一个缓存区则被用于显示，将导致CPU空闲。

**三缓冲（Triple Buffering）**

在双缓冲的前提下新增了一个缓冲区，在发生上述双缓冲问题时，CPU能利用这个新增的缓冲区进行计算。

### SurfaceFlinger

> SurfaceFlinger的图形混合过程是调用的OpenGL。

`SurfaceFlinger`维护管理了一个`BufferQueue`, 并通过匿名共享内存机制和应用层交互。

通过`Swap Buffer` 把所有 `Surface` 中的 `Front Graphic Buffer`统一交给`硬件合成器（Hardware Composer ）`合成并交给系统的`帧缓冲区（Frame Buffer）`， 从而输出到显示屏。

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

## 适配方案

* 限制符适配方案

  `宽高限定符`与 `smallestWidth 限定符`适配方案。

* 今日头条适配方案

  反射修正系统的 density 值