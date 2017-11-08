
# Kotlin

## 集成

Project : gradle 

```
buildscript {
    ext.kotlin_version = '1.1.2-4'
    dependencies {
    	classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

Module : gradle

```
apply plugin: 'kotlin-android'

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
看文档吧

fun

var


### 单例

object class

### 注释

```
/**
 * [context] 上下文
 * 
 ** /
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

