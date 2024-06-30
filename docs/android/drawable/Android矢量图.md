# android 矢量图

SVG 意为可缩放矢量图形（Scalable Vector Graphics），是使用 XML 来描述二维图形和绘图程序的语言；

使用 SVG 的优势在于：

1. SVG 可被非常多的工具读取和修改（比如记事本）,由于使用xml格式定义，所以可以直接被当作文本文件打开，看里面的数据；
2. SVG 与 JPEG 和 GIF 图像比起来，尺寸更小，且可压缩性更强，SVG 图就相当于保存了关键的数据点，比如要显示一个圆，需要知道圆心和半径，那么SVG 就只保存圆心坐标和半径数据，而平常我们用的位图都是以像素点的形式根据图片大小保存对应个数的像素点，因而SVG尺寸更小；
3. SVG 是可伸缩的，平常使用的位图拉伸会发虚，压缩会变形，而SVG格式图片保存数据进行运算展示，不管多大多少，可以不失真显示；
4. SVG 图像可在任何的分辨率下被高质量地打印;
5. SVG 可在图像质量不下降的情况下被放大;
6. SVG 图像中的文本是可选的，同时也是可搜索的（很适合制作地图）;
7. SVG 可以与 Java 技术一起运行;
8. SVG 是开放的标准;
9. SVG 文件是纯粹的 XML;

## path属性表

| a | b                                | c                                             |
| :- | :------------------------------- | :-------------------------------------------- |
| M | moveto                           | 相当于android Path里的moveTo(),用于移动起始点 |
| L | lineto                           | 相当于android Path里的lineTo(),用于画线       |
| H | horizontal lineto                | 用于画 水平线                                 |
| V | vertical lineto                  | 用于画 竖直线                                 |
| C | curveto                          | 相当于cubicTo(),三次贝塞尔曲线                |
| S | smooth curveto                   | 同样三次贝塞尔曲线，更平滑                    |
| Q | quadratic Belzier curve quadTo() | 二次贝塞尔曲线                                |
| T | smooth quadratic Belzier curveto | 同样二次贝塞尔曲线，更平滑                    |
| A | elliptical Arc                   | 相当于arcTo()，用于画弧。                     |
| Z | closepath                        | 相当于closeTo(),关闭path                      |
|  |  |  |
|  |  |  |
|  |  |  |
|  |  |  |
|  |  |  |

```
"M50,50 a10,5 0 0,0 0 7"
起始点 50, 50
10，5 为椭圆x，y轴半径
第一个0 为 x轴旋转角度
第二个0 为取大小弧度，0为小，1为大
第三个0 为顺逆时针，0为逆1为顺
第四个0 起始 y 偏移，
7 起始 x 偏移，

```









### svg

```xml
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="100%" height="100%" version="1.1"
xmlns="http://www.w3.org/2000/svg">

<path d="M250 150 L150 350 L350 350 Z" />

</svg>
```

### vector

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:tint="?attr/colorControlNormal"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M10,20v-6h4v6h5v-8h3L12,3 2,12h3v8z" />
</vector>

```
