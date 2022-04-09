# HTML5
## 标签

### 媒体标签

> 音频: ``audio`` 
>
> 视频: ``video``

|属性|描述|
|:--|--|
|src|资源地址|
|controls|显示播放控制器|
|autoplay|自动播放(部分浏览器不生效,也可能是浏览器禁用了自动播放)|
|loop|循环播放|

```html
<audio src="D:\CloudMusic\冰糖IO - 下一站更甜.mp3" controls autoplay loop></audio>
<!-- muted 默认静音播放 -->
<video src="D:\CloudMusic\MV\泠鸢yousa - 神的随波逐流.mp4" controls autoplay muted></video>
```

### 超链接

> ``a``

|属性|描述|
|:--|--|
|herf|链接地址; '#': 空链接|
|target|'_self';'_blank';'#'|

```html
<!-- 超链接 _self _blank # -->
<a href="https://space.bilibili.com/198297/?spm_id_from=333.999.0.0" target="#">冰糖IO</a>
```


### 列表

> 有序/无序列表

|标签|描述|
|:--|--|
|ol|表示一个有序列表组，内部仅能包裹li标签|
|ul|表示一个无序列表组，内部仅能包裹li标签|
|li|表示列表组中的一个项目, 可以包裹任意标签|

```html
<!-- 有序列表 -->
<ol>
    <li>item1</li>
    <li>item2</li>
    <li>item3</li>
</ol>

<!-- 无序列表 -->
<ul class="list-group">
    <li class="list-group-item">
        <span class="badge">1</span>
        item1
    </li>
    <li class="list-group-item">
        <span class="badge">2</span>
        item2
    </li>
    <li class="list-group-item">
        <span class="badge">3</span>
        item3
    </li>
</ul>
```

> 自定义列表

|标签|描述|
|:--|--|
|dl|表示一个自定义列表组，仅能包裹dt/dd标签|
|dt|表示列表的标题，可以包裹任意标签|
|dd|表示列表组中的一个项目，可以包裹任意标签; 默认缩进|

```html
<!--自定义列表-->
<dl>
    <dt>dtdtdtdt</dt>
    <dd>111111</dd>
    <dd>222222</dd>
</dl>
```

### 表格

|标签|描述|
|:--|--|
|table|表格主体|
|caption|定义表格的标题|
|tr|表格的行|
|td|表格的单元格|
|th|定义表头|

> 结构标签主要用于突出内容的含义，便于理解

|结构标签|描述|
|:--|--|
|thead|表头的头部|
|tbody|表格主体内容|
|tfoot|表格的底部|

|属性|描述|
|:--|--|
|rowspan|行合并，合并时保留最上方的行|
|colspan|列合并，合并时保留最左边的行|

```html
<table>
    <caption>测试表格2</caption>
    <!--表格头部-->
    <thead>
    <tr>
        <th>head1</th>
        <th>head2</th>
    </tr>
    </thead>
    <!--表格主体内容-->
    <tbody>
    <tr>
        <td>body1</td>
        <td>body2</td>
    </tr>
    <tr>
        <td>body1</td>
        <td>body2</td>
    </tr>
    </tbody>
    <!--表格结尾-->
    <tfoot>
        <td>foot1</td>
        <td>foot2</td>
    </tfoot>
</table>
```

### 表单

#### input标签

|type|描述|
|:--|--|
|text|文本|
|password|密码|
|radio|单选|
|checkbox|复选|
|file|文件上传|
|submit|用于提交|
|reset|重置|
|button|普通的按钮，配合js使用|

> text; password

|属性|描述|
|:--|--|
|placeholder|占位符，提示用户|

> radio

|属性|描述|
|:--|--|
|name|分组名, 相同的name表示属于同一组|
|checked|默认选中|

## 基础概念

### block，inline和inline-block概念和区别

#### display:block 块状元素

1. block元素会独占一行，多个block元素会各自新起一行。默认情况下，block元素宽度自动填满其父元素宽度。
2. block元素可以设置width,height属性。块级元素即使设置了宽度,仍然是独占一行。
3. block元素可以设置margin和padding属性。


#### display:inline 行内元素

1. inline元素不会独占一行，多个相邻的行内元素会排列在同一行里，直到一行排列不下，才会新换一行，其宽度随元素的内容而变化。
2. inline元素设置width,height属性无效。
3. inline元素的margin和padding属性，水平方向的padding-left, padding-right, margin-left, margin-right都产生边距效果；但竖直方向的padding-top, padding-bottom, margin-top, margin-bottom不会产生边距效果。

#### inline-block

简单来说就是将对象呈现为inline对象，但是对象的内容作为block对象呈现。之后的内联对象会被排列在同一行内。比如我们可以给一个link（a元素）inline-block属性值，使其既具有block的宽度高度特性又具有inline的同行特性。