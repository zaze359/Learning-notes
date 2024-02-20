# CSS学习笔记

[CSS - 学习 Web 开发 | MDN (mozilla.org)](https://developer.mozilla.org/zh-CN/docs/Learn/CSS)

## 选择器

### id选择器 #

```html
<p id="aa"></p>
```

```css
/* 选择id=aa 的p标签 */
p#aa
```

### class选择器 .

```html
<p class="aa"></p>
```

```css
/* 选择class=aa 的p标签 */
p.aa
```



## Flex 弹性布局





## 精灵图

精灵图就是图片拼合技术，将多张小图片合成一张大图片。可以减少网络请求的数量。

通过 `background-position`来定位其中的小图片。

```css
<style>
/* box宽高和需要显示的小图标的宽高一致。*/
.box {
    width: 100px;
    height: 100px;
    /* 一般都是负值，表示将背景图 x轴左移10px, y轴上移10px*/
    background-position: -10px -10px;
}
</style>
```

## 属性表

| 属性           | 说明                                                         |
| -------------- | ------------------------------------------------------------ |
| display        | 布局方式，flex等。                                           |
| flex           | 在弹性布局主轴方向的占比权重，具体值、auto等。               |
| flex-direction | 指定弹性布局 主轴方向。row、row-reverse、column、column-reverse。 |
| flex-wrap      | 布局溢出方式，nowrap、wrap、auto等。                         |
| flex-basis     | 指定初始长度。                                               |
| -              |                                                              |
| margin         | 外边距。<br />1. 指定**一个**值时，应用到**全部四个边**的外边距上。 <br />2. 指定**两个**值时，第一个值会应用于**上边和下边**，第二个值应用于**左边和右边**。<br />3. 指定**三个**值时，**上边**，**右边和左边**，**下边**。 <br />4. 指定**四个**值时，（顺时针方向）作为**上**，**右**，**下**，**左**。 |
| padding        | 内边距。参数规则同margin                                     |
| gap            | 指定容器中子元素的间的间距。                                 |
| -              |                                                              |
| vh             | 基于屏幕可见的高度，100vh, 表示占满 100% 高度                |
| vw             | 基于屏幕可见的宽度                                           |
| vmin           | 取 vh vw 中较小的一个                                        |
| vmax           | 取 vh vw 中较大的一个                                        |
| %              | 百分比是基于 父元素的大小                                    |
| -              |                                                              |
| rem            | 1rem = 1 * font-size，表示几倍字体大小，默认是16px，可以通过 ``html{font-size: 18px}`` 来修改。 |
| -              |                                                              |
| border         | 边距。`1px solid gray`                                       |
| border-radius  | 圆角。                                                       |

