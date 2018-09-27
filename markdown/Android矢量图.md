# android 矢量图

Tags : zaze android

## SVG

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



## Path标签

```

<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="100%" height="100%" version="1.1"
xmlns="http://www.w3.org/2000/svg">

<path d="M250 150 L150 350 L350 350 Z" />

</svg>

```

```
M = moveto   相当于 android Path 里的moveTo(),用于移动起始点
L = lineto   相当于 android Path 里的lineTo()，用于画线
H = horizontal lineto     用于画水平线
V = vertical lineto       用于画竖直线
C = curveto               相当于cubicTo(),三次贝塞尔曲线
S = smooth curveto        同样三次贝塞尔曲线，更平滑
Q = quadratic Belzier curve             quadTo()，二次贝塞尔曲线
T = smooth quadratic Belzier curveto    同样二次贝塞尔曲线，更平滑
A = elliptical Arc   相当于arcTo()，用于画弧
Z = closepath     相当于closeTo(),关闭path
```
