
# Kotlin

Tags : zaze android

---

[TOC]

---

## 集成

Project : gradle 

```
buildscript {
    ext.kotlin_version = '1.1.2-4' // 版本自己更新
    dependencies {
    	classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

Module : gradle

```
apply plugin: 'kotlin-android'  // kotin 基础
apply plugin: 'kotlin-android-extensions'   //
apply plugin: 'kotlin-kapt'    // kapt

compile "org.jetbrains.kotlin:kotlin-stdlib-jre7:$kotlin_version"
```


## 亮点

### 一、不在使用findViewById()

gradle

```
apply plugin: 'kotlin-android-extensions'
```

view.java

```
import kotlinx.android.synthetic.main.activity_main.*;
```

example : 

```
<TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:id="@+id/tv_message"
        android:text="Hello World!" />
```

```
// 直接就能访问到控件进行操作了
tv_message.text = "Hello Kotlin!";
```

### 二、字符串拼接

```
String a = "aa";
String b = "b $a ${c()}"

fun c : String() {
	return "cc"
}
```


## 语法

看文档吧~~~
[Kotlin中文站][Kotlin中文站]

### 延迟加载

- lateinit 修饰符
```
有的成员属性不能在构造函数中初始化，会在稍后某的地方完成初始化，可以确定是非空
```

- by layz(mode = x)
```
mode = LazyThreadSafetyMode.SYNCHRONIZED (线程安全)
mode = LazyThreadSafetyMode.NONE (线程不安全)
```

### 单例

- object class


### 注解


- @JvmFeild
```

```

- @JvmStatic
```
 和object一起使用, 变成正在的静态, 不用INSTANCE
```

- @JvmOverloads
```
类似方法的多态

@JvmOverloads fun test(a : String = "")

等价下面
fun test()
fun test(a : String)
```



### 数组

#### 1. 直接指定长度

``
val fixedSizeArray = arrayOfNulls<Int>(5)
``

#### 2.使用装箱操作

```
val arr = arrayOf(1, 2, 3)
val intArr = intArrayOf(1, 2, 3)    //同理还有 booleanArrayOf() 等
```

#### 3.使用闭包进行初始化

```
val asc = Array(5, { i -> i * i })  //0,1,4,9,16
```

#### 4.空数组

```
val empty = emptyArray<Int>()
长度为 0 的空数组
```

#### 5.访问数组元素

```
val arr = arrayOf(1, 2, 3)
println(asc[1])         //  1
println(asc.get(1))     //  1
//    println(asc[10])      ArrayIndexOutOfBoundsException
```

### 内联函数和内联扩展函数

|函数|范例|函数体内的对象|返回值|
|:--|:--|:--|:--|
|let|obj.let{}|it表示obj|函数块最后一行的返回值|
|run|obj.run{}|this指代obj|函数块最后一行的返回值|
|also|obj.also{}|it指代obj|obj对象|
|apply|obj.apply{}|this指代obj|obj对象|
|with|with(obj){}|this指代obj|函数块最后一行的返回值|







[Kotlin中文站]: https://www.kotlincn.net/