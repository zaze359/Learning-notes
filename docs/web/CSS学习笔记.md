# CSS学习笔记

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

