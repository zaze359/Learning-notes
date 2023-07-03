# Class文件格式



## 常量池表(Constant Pool Table)

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

