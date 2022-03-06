
## Tab 键

## 选择器

### id选择器
p#aa

```
<p id="aa"></p>
```

### class选择器

p.aa

```
<p class="aa"></p>
```

## 嵌套

* >：子元素符号，表示嵌套的元素
* +：同级标签符号
* ^：可以使该符号前的标签提升一行


## 分组

(.foo>h1)+(.bar>h2)

```
<div class="foo">  
  <h1></h1>  
</div>  
<div class="bar">  
  <h2></h2>  
</div>
```
## 定义多个标签

要定义多个元素，可以使用 * 符号。比如，ul>li*3可以生成如下代码

```
<ul>  
  <li></li>  
  <li></li>  
  <li></li>  
</ul>
```


