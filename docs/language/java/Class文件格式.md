# Class文件格式

## 格式范例

```java
public class Simple {
    private static final List<String> works = new ArrayList<>();
}
```

* `#1 = Methodref          #6.#18` ：首先`Methodref`表明这个常量是方法定义，由`#6` 、`.`、`#18` 拼接得到。最终结果是类实例的构造函数。
  * 没有定义自身的构造函数，所以调用的是父类 Object的构造函数。

```java
Classfile /D:/GitRepository/KotlinExample/src/main/java/com/zaze/kotlin/example/test/Simple.class
  Last modified 2023年7月24日; size 409 bytes
  MD5 checksum 80dae30bd54abde081f9dd8b7447bb97
  Compiled from "Simple.java"
public class com.zaze.kotlin.example.test.Simple	// 类全限定名
  minor version: 0	// jdk 次版本号
  major version: 55	// jdk 主版本号
  flags: (0x0021) ACC_PUBLIC, ACC_SUPER		// 类的访问标识
  this_class: #5                          // com/zaze/kotlin/example/test/Simple
  super_class: #6                         // java/lang/Object
  interfaces: 0, fields: 1, methods: 2, attributes: 1
Constant pool:	// 常量池
   #1 = Methodref          #6.#18         // java/lang/Object."<init>":()V
   #2 = Class              #19            // java/util/ArrayList
   #3 = Methodref          #2.#18         // java/util/ArrayList."<init>":()V
   #4 = Fieldref           #5.#20         // com/zaze/kotlin/example/test/Simple.works:Ljava/util/List;
   #5 = Class              #21            // com/zaze/kotlin/example/test/Simple
   #6 = Class              #22            // java/lang/Object
   #7 = Utf8               works
   #8 = Utf8               Ljava/util/List;
   #9 = Utf8               Signature		
  #10 = Utf8               Ljava/util/List<Ljava/lang/String;>;
  #11 = Utf8               <init>
  #12 = Utf8               ()V
  #13 = Utf8               Code
  #14 = Utf8               LineNumberTable
  #15 = Utf8               <clinit>
  #16 = Utf8               SourceFile
  #17 = Utf8               Simple.java
  #18 = NameAndType        #11:#12        // "<init>":()V
  #19 = Utf8               java/util/ArrayList
  #20 = NameAndType        #7:#8          // works:Ljava/util/List;
  #21 = Utf8               com/zaze/kotlin/example/test/Simple
  #22 = Utf8               java/lang/Object
{
  private static final java.util.List<java.lang.String> works;
    descriptor: Ljava/util/List;
    flags: (0x001a) ACC_PRIVATE, ACC_STATIC, ACC_FINAL
    Signature: #10                          // Ljava/util/List<Ljava/lang/String;>;

  public com.zaze.kotlin.example.test.Simple();
    descriptor: ()V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 6: 0

  static {};
    descriptor: ()V
    flags: (0x0008) ACC_STATIC
    Code:
      stack=2, locals=0, args_size=0
         0: new           #2                  // class java/util/ArrayList
         3: dup
         4: invokespecial #3                  // Method java/util/ArrayList."<init>":()V
         7: putstatic     #4                  // Field works:Ljava/util/List;
        10: return
      LineNumberTable:
        line 7: 0
}
SourceFile: "Simple.java"

```

## 常量池(Constant pool)

用于存放编译期间生成的各种 **字面量** 和 **符号引用** 。类加载到内存后，class文件常量池会被**存放到运行时常量池中**。

### 字面量

字面量（literal）是用于表达源代码中一个固定值的表示法（natation）。包括整数、浮点数和字符串字面量。

* 字符串字面量

  ```java
  String a = "b";
  // b就是字面量
  ```

* 基本类型的常量（final 修饰的变量）

  ```java
  int i = 1;
  // i就是字面量
  
  public static final int j = 2; // 2是字面量
  ```
  

### 符号引用（Symbilic Reference）

在 Java 源文件被编译成字节码文件时，所有的变量和方法引用都作为符号引用保存在 Class 文件的常量池里。包括类符号引用、字段符号引用、方法符号引用、接口方法符号。

* 类和方法的全限定名：例如String：`java/lang/String`。
* 字段的名称和描述符。
* 方法的名称和描述符。

### 符号表

| 符号                                            | C/C++              | Java    |
| ----------------------------------------------- | ------------------ | ------- |
| V                                               | void               | void    |
| I                                               | jint               | int     |
| J                                               | jlong              | long    |
| F                                               | jfloat             | float   |
| D                                               | jdouble            | double  |
| Z                                               | jboolean           | boolean |
| S                                               | jshort             | short   |
| C                                               | jchar              | char    |
| B                                               | jbyte              | byte    |
| -                                               |                    |         |
| `[`：表示数组。例如 `[I`表示 int数组            | jintArray          | int[]   |
| `L`: 表示class类型。例如 `Ljava/lang/String;`。 | 都是 `jobject`类型 | String  |

> * class 以 `;` 结尾。
>
> * 包名使用 `/` 分割。
>   * 若存在内部类，使用 `$` 来作为分隔符。
>
> * 参数都包裹在 `()` 中。
> * 最后的符号表示返回值。例如这里的 `J` 。
