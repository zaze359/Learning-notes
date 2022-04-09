# Bootstrap


## 准备

官网(中文) ：[http://www.bootcss.com/](http://www.bootcss.com/)

[Bootstrap5文档](https://v5.bootcss.com/docs/getting-started/introduction/)

依赖于jQuery : [http://jquery.com/](http://jquery.com/)


## HTML5 文档类型

Bootstrap 使用到的某些 HTML 元素和 CSS 属性需要将页面设置为 HTML5 文档类型。在你项目中的每个页面都要参照下面的格式进行设置。

```
<!DOCTYPE html>
<html lang="zh-CN">
  ...
</html>

```

## 移动设备优先

**Bootstrap是移动设备优先的**

在移动设备浏览器上，通过为视口（viewport）设置 meta 属性为 user-scalable=no 可以禁用其缩放（zooming）功能。这样禁用缩放功能后，用户只能滚动屏幕，就能让你的网站看上去更像原生应用的感觉。注意，这种方式我们并不推荐所有网站使用，还是要看你自己的情况而定

```
<meta name="viewport" content="width=device-width, initial-scale=1">

<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">

```



## 开始

### 一、排版

#### 标题

标题（h1-h6/ .h1-.h6）
副标题 (samll)

- h1 : 36px;
- h2 : 30px;
- h3 : 24px;
- h4 : 18px;
- h5 : 14px;
- h6 : 12px;

#### 文本排版

p 标签

```
默认字体 : 14px (普通16px)
行高 : 20px
底部外边距 : 10px
```
```
samll
del
ins
strong
mark
```

#### 表格

- form-inline : 水平排列

- form-control ： 美化控件

- input-lg(sm) : 大小变化


#### 图片

- img-rounded 圆角
- img-circle 圆
- img-thumbnail 带边框的圆角



### 二、Bootstrap 渐进

#### 1、响应式开发

**meta标签中的Viewport**

- width, height
- user-scalable, initial-scale
- maximum-scale, minimum-scale
```
<meta name="viewport" content="width=device-width,initial-scale=1, maximum-scale=1,minimum-scale-1,user-scalable=no" >
```

#### 2、利用栅格系统适配不同环境


