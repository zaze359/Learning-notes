# Java对象创建流程

## 对象类型

- 普通Java对象
- 数组
- Class对象

## 对象创建方式

- 通常使用``new``关键字：调用构造器来初始化实例字段。
- `Object.clone`复制：直接复制已有的数据。
- 反序列化：直接复制已有的数据。
- `Unsafe.allocateInstance`：没有初始化实例字段。

## new语句创建

* 请求内存的 `new` 指令。

* 调用构造器的 `invokespecial` 指令。

构造器调用流程：

> 子类中会优先调用父类的构造器，层层递进直至Object类。

子类构造器调用父类构造器。若父类存在无参构造器，则java编译器会自动添加对父类构造器的调用（隐式调用）。若不存在无参构造器，则需要在子类构造器中显示调用有参构造器（super、this）。

## 对象创建流程

### 1. 类加载检查

首先需要找到类，然后执行类加载。

* JVM虚拟机接收到 `new` 指令。
* 检查指令的参数是否能在运行时常量池中找到对应类的符号引用。
* 检查这个符号引用代表的类是否已经被加载过。即类加载的三个过程：加载、连接、初始化。
* 若未加载则**执行类加载流程**。

### 2. 分配内存

通过第一步的类加载检查后，JVM就会给对象**分配内存**。

从Java堆中分配一块指定大小的内存给对象实例。根据堆的内存是否规整存在两种分配方式：**指针碰撞（内存规整）**、**空闲列表（内存不规则）**。

### 3. 初始化零值

当内存分配完成后，虚拟机会将这块分配的内存空间都初始化为零值（除对象头），其实就是 将java对象的字段默认初始为零值（对应类型的初始值）。

### 4. 设置对象头

接着虚拟机会对对象设置一些必要的信息，存放在对象头中。主要包括三个部分：MarkWord、元数据指针、数组数据（数组对象才有）。

其中MarkWord比较复杂，包括： 对象的HashCode、对象所属年代、对象锁、偏向锁等等。

![img](./Java%E5%AF%B9%E8%B1%A1%E5%88%9B%E5%BB%BA%E6%B5%81%E7%A8%8B.assets/1748585-20230525094258181-1639554907.png)

### 5. 执行init方法初始化

执行完 上面几个步骤，虚拟机的工作基本已经完成了，不过此时所有字段都还是null。所以在最后会执行 `<init>` 来进行成员变量的初始化（静态变量则是在类加载时期就已经初始化了）。

这个方法会**根据我们设置的初始值来为字段赋值**。初始化完毕后这个对象就真正的创建好了。

>  `<init>` 流程：
>
>  * 若存在父类，则先调用 `super.init`。
>
>  * 按照声明顺序进行自身非静态变量的赋值初始化。
>  * **最后调用自身的构造函数**。



---

## 类加载

### ClassLoader

**类加载器（ClassLoader）** 的主要作用就是将 class字节码 加载到 JVM中，从而能够创建class对应的实例对象，当然它还支持加载资源（图片、文本等）。ClassLoader 赋予了动态加载的能力。

当多个线程访问方法区的同一个类时，若这个类未被JVM加载，此时仅允许一个线程执行加载，其余线程必须等待。

#### 双亲委派机制

除了最顶层的BootstrapClassLoader，其余的ClassLoader 实例都有一个 `parent: ClassLoader`。**自底向上判断类是否已加载，自顶向下加载类**。CustomClassLoader 最底层，BootstrapClassLoader最顶层。

* ClassLoader 调用 `loadClass()`  执行类加载时，会**优先通过自身 判断类是否已加载**，若没加载，则会委派给 parent 处理。
* 若传递到最顶层 ClassLoader 也没加载，则会去加载对应类，**优先 parent 来加载类**，然后再层层回传。
* 若 parent ClassLoader 无法加载，才会由 子ClassLoader加载。

优点：

* 共享：顶层加载过的类能够共享给底层，能避免类的重复加载；也起到了预加载 的作用（jvm加载了核心库）。
* 隔离：类的唯一性由 加载类的类加载器和 类自身决定，不同继承路线上的ClassLoader加载的类肯定不是同一个类，可以防止顶层的类被替换。
  * 同一个Class： 相同的 ClassName + PackageName + ClassLoader。
  * 在同一个ClassLoader中类名是唯一的，不同的ClassLoader则可以持有相同的类名。


> **打破双亲委派**：自定义 ClassLoader 重写 `loadClass()`，不委派给 parent 即可。

```java
public abstract class ClassLoader {
    private final ClassLoader parent;
    // 此处实现双亲委派
    protected Class<?> loadClass(String name, boolean resolve)
        throws ClassNotFoundException
    {
            // First, check if the class has already been loaded
            Class<?> c = findLoadedClass(name);
            if (c == null) {
                try {
                    if (parent != null) {
                        // 交由 parent加载，相当于递归，也是先判断是否已加载
                        c = parent.loadClass(name, false);
                    } else {
                        // 交由最顶层 BootstrapClass 去加载
                        c = findBootstrapClassOrNull(name);
                    }
                } catch (ClassNotFoundException e) {
                    // ClassNotFoundException thrown if class not found
                    // from the non-null parent class loader
                }
				// 若未加载，则
                if (c == null) {
                    // If still not found, then invoke findClass in order
                    // to find the class.
                    // 找到类
                    c = findClass(name);
                }
            }
        	// 回调结果
            return c;
    }
    // 判断是否已加载
    protected final Class<?> findLoadedClass(String name) {
        ClassLoader loader;
        if (this == BootClassLoader.getInstance())
            loader = null;
        else
            loader = this;
        // native，根据ClassLoader 和 name 定位class
        return VMClassLoader.findLoadedClass(loader, name);
    }
    // 这里由子类重载来实现具体的类加载逻辑，若是 BaseDexClassLoader，会从dex解析出来的 pathList 中查找
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        throw new ClassNotFoundException(name);
    }
}
```



### 类加载时机

* 虚拟机启动时标明的启动类。`main()` 函数所在类
* new 对象实例。
* 调用类的静态字段或者方法时。
  * 静态常量不会触发类加载，因为会在编译期间被内联到调用处。
* 初始化子类时需要先初始化父类。
* JDK8 的 default 声明的接口（默认实现），接口实现类初始化时 会先将接口初始化。

### 类加载流程

JVM创建一个对象实例的之前需要先进行类加载，一个类加载必定会经过**加载、连接（验证+准备+解析）、初始化** 这几个过程。

![image-20230606160421193](./Java%E5%AF%B9%E8%B1%A1%E5%88%9B%E5%BB%BA%E6%B5%81%E7%A8%8B.assets/image-20230606160421193.png)



#### 1. 加载

在类加载的时候，系统会首先判断当前类是否被加载过，已加载过则会之间返回，没有则去尝试加载。

* JVM会使用类加载器 **根据全限定名查询对应的class文件**。
* 读取 class文件的二进制字节流，转换为方法区中的运行时数据结构。
  * 由于加载的是二进制字节流，所以class字节码的来源既可以是本地也可以是远程的。只要符合JVM规范即可。

* 在**堆**中生成一个代表这个类的 **class类对象，用于访问之前存放在方法区中的数据**。
  * 类的数据还是在方法区中的，class对象仅是个访问入口。


#### 2. 连接

连接包含了 验证、准备、解析三个过程。

* **验证**：验证加载的class文件是否符合JVM的规范
* **准备**：给类的静态变量分配内存，并给定对应类型的初始值。
* **解析**：将常量池中的符号引用替换为直接引用。

##### 2.1 验证

这个过程主要是为了确保被加载的类的正确性，**验证加载的class文件是否符合JVM的规范**。

> **验证过程是可以跳过的**，可以使用`-Xverify:none`来关闭验证从而缩短类加载时间。

* **验证文件格式**：校验是否符合class文件格式规范，包含校验是否以`0xCAFEBABE`开头（class文件固定格式头）、主次版本是否支持、常量池中常量类型是否支持等。
* **验证元数据**：对字节码描述的信息进行语义分析，是否符合Java语言规范。
* **验证字节码**：校验类的方法体，分析数据流和控制流，确保在运行时的符合逻辑。
* **验证符号引用**：确保解析动作能正确执行。例如类的全限定名能找到类等。在解析阶段，JVM将符号引用替换为直接引用（对象的索引值）。

##### 2.2 准备

在准备阶段**会给类变量（静态变量）分配内存**，并且**设置对应数据类型的初始值**，需要注意的并不是我们代码中指定的初始值，静态变量最终会随着class对象一起保存到 java堆中。

> 这个过程也包括了静态常量，不过它是直接赋值的指定值。
>
> 注意这里并不包括类实例变量，实例变量是在实例化时初始化的。不在类加载阶段。

##### 2.3 解析

指**将常量池中的符号引用替换为直接引用的过程**。主要包括类/接口、字段、方法、方法类型、方法句柄以及调用调用限定符这些符号引用。最终得到这些符号引用在**内存中的指针或者偏移量**，也就能够获取到真正的内存入口地址。

#### 3. 初始化

> `<clinit>` 类型初始化函数 是在编译后自动生成的，在JVM执行类型加载时调用，且只执行一次。它是带锁线程安全，因此多线程进行类初始化存在并发阻塞的问题。

初始化阶段会调用 `<clinit>`方法，开始真正执行字节码。

**主要是对static变量进行初始化操作，也包括static 代码块的执行**。



### 类卸载

> 一个类被卸载 就是 这个类对应的 Class 对象被 GC。

使用自定义类加载器加载的类才可能被卸载，被 jvm 自带的类加载器加载的类是不会被卸载的（JDK的 BootstrapClassLoader、ExtClassLoader、AppClassLoader）。

* 类的所有实例都被GC。
* 这个类没有被任何地方引用。
* 类加载器的实例也被GC。

## 内存分配方式

### 指针碰撞

指针碰撞是用于堆中不存在内存碎片的情况下，即内存很整齐。对应使用 **标记-整理** 算法的 GC，例如Serial, ParNew。

在已使用过的内存和没使用过的内存中间存在一个分界指针，分配内存只需要就是将**分界指针 向未使用内存方向 移动指定内存大小的位置**即可。

### 空闲列表

空闲列表就是用于存在内存碎片的场景。对应使用 **标记-清除** 算法的GC，例如 CMS。

虚拟机维护了一张记录表，里面记录了可用的内存块，分配内存就是在记录表中**查找一块符合大小的内存块分配给对象**，然后更新一下记录即可。

### 如何保证内存分配过程是线程安全的？

* **CAS + 自旋锁**：通过CAS 保证操作的原子性，若更新失败则会通过自旋锁的方式进行失败重试，直到成功。

* **TLAB**：预先为每一个线程在 Eden 区分配一块内存，这样就能先各用各的，当TLAB的内存不够分配时，再使用 CAS的方式分配。

