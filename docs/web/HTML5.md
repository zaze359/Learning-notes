# HTML5


## block，inline和inline-block概念和区别

### display:block 块状元素

1. block元素会独占一行，多个block元素会各自新起一行。默认情况下，block元素宽度自动填满其父元素宽度。
2. block元素可以设置width,height属性。块级元素即使设置了宽度,仍然是独占一行。
3. block元素可以设置margin和padding属性。


### display:inline 行内元素

1. inline元素不会独占一行，多个相邻的行内元素会排列在同一行里，直到一行排列不下，才会新换一行，其宽度随元素的内容而变化。
2. inline元素设置width,height属性无效。
3. inline元素的margin和padding属性，水平方向的padding-left, padding-right, margin-left, margin-right都产生边距效果；但竖直方向的padding-top, padding-bottom, margin-top, margin-bottom不会产生边距效果。

### inline-block

简单来说就是将对象呈现为inline对象，但是对象的内容作为block对象呈现。之后的内联对象会被排列在同一行内。比如我们可以给一个link（a元素）inline-block属性值，使其既具有block的宽度高度特性又具有inline的同行特性。

## 标签

### audio、video

|属性|描述|
|:--|--|
|src|资源地址|
|controls|显示播放控制器|
|autoplay|自动播放(部分浏览器不生效,也可能是浏览器禁用了自动播放)|
|loop|循环播放|

example:
```html

<audio src="D:\CloudMusic\冰糖IO - 下一站更甜.mp3" controls autoplay loop></audio>

<!-- muted 默认静音播放 -->
<video src="D:\CloudMusic\MV\泠鸢yousa - 神的随波逐流.mp4" controls autoplay muted></video>
```