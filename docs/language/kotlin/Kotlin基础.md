# Kotlin 基础





## 泛型

- 5.4 泛型：让类型更安全

  - 5.4.1 泛型：类型安全的利刃

    - 在编译时期进行类型检查，提前发现错误。

    - 自动类型转换。

    - 更加语义化。

    - 能写出更加通用化的代码。

  - 5.4.2 如何在kotlin中使用泛型
    class Plate<T>(val t: T)

  - 5.4.3 类型约束：设定类型上界

    class FruitPlate<T: Fruit>(val t : T>

    - Kotlin使用 : (上界约束)

    - 使用 where 关键字 实现对泛型参数类型添加多个约束条件
      class Watermelon(weight:Double): Fruit(weight), Ground
      ​fun <T> cut(t:T) where T:Fruit, T : Ground {}

- 5.5 泛型的背后: 类型擦除

  - 5.5.1 Java为什么无法声明一个泛型数组

    - 泛型是类型擦除的，无法在程序运行时获取到一个对象的具体类型。

    -  Java的数组是协变的，加入泛型就无法满足协变的原则。

    - kotlin泛型机制和java相同。泛型是类型擦除的，无法在程序运行时获取到一个对象的具体类型。数组支持泛型

  - 5.5.2 向后兼容的罪

    - java 为了兼容1.5之前的版本，采用泛型擦除的方式，实现了泛型。新老版本编译后字节码是相同的。

    - 类型检查是编译器在编译前帮我们检查的，所以类型擦除不会影响它。

    - 自动转换是通过强制类型转化实现的。

  - 5.5.3 类型擦除的矛盾

    - 无法获取一个泛型的类型。

    - 利用匿名内部类的方式在运行时获取泛型参数的类型。

  - 5.5.4 使用内联函数获取泛型
    - Kotlin的内联函数在编译的时候编译器会将相应函数的字节码插入调用的地方。

- 5.6 打破泛型不变

  - 5.6.1 为什么List<String>不能赋值给List<Object>

    - 将不能保证类型安全

    - 不过kotlin中的list允许List<String>赋值给List<Any>

  - 5.6.2 一个支持协变的List

    - 协变：假如类型A是类型B的子类型，那么Generic<A> 也是Generic<B>的子类型

    - kotlin中通过out关键字<out T>,表面泛型类及泛型方法是协变的。 Java <? extend T>

    - 为了保证类型安全，只能作为消费者，只能读取不能添加

  - 5.6.3 一个支持逆变的Comparator

    - 逆变：假如类型A是类型B的子类型，那么Generic<B> 是Generic<A>的子类型

    - Kotlin <in T> ; Java <? super T>

    - 只能作为生产者，只能添加，读写受限。

  - 5.6.4 协变和逆变

    - out代表泛型参数类型协变，父子关系相同; 范围向外扩展（多），支持子类型。

    - in代表泛型参数类型逆变 ，父子关系相反; 范围向内收拢（少），支持父类型。

    - 进一步增加了泛型的灵活性



## 多态和扩展



### 扩展

> 可以为类添加方法、属性。

#### 扩展函数

格式：`fun A.method() { }` 。

表示给A 添加了 `method()` 方法。

* A：接收者类型（recievier type），通常是类或接口。
* 扩展函数的 this 就是接收者类型的对象。

```kotlin
// AppCompatActivity 添加了 setupActionBar(..) 函数
fun AppCompatActivity.setupActionBar(
    toolbar: Toolbar,
    action: ActionBar.(toolbar: Toolbar) -> Unit = {}
) {
    // this 就是 AppCompatActivity
    this.setSupportActionBar(toolbar)
    supportActionBar?.run {
        action(toolbar)
    }
}

```

> Kotlin的的扩展函数其实是一个静态方法，不会带来额外的性能消耗。



## expect 和 actual 修饰词的作用

常出现在 kotlin sdk 的源码中，是用来实现跨平台的。

expect 和 actual 是一一对应的，他们同名。

* expect（接口）：期望调用的类、成员变量或方法。

* actual（实现）： 实际调用的类、成员变量或方法。

> IDEA 代码跳转的是 `kotlin-stdlib-comom:x.xx.xx` 下，若是跨平台的函数，它对应的具体实现在 `kotlin-stdlib:x.xx.xx`下。（具体的平台名字可能有差异）
>
> 一般在IDEA中直接搜索 `xxxJvm.kt` 对应的 `xxxJvm.kt`文件即 是源码实现。
>
> 如 `class SafeContinuation` ，那么就搜索 `SafeContinuationJvm.kt`