# Android的数据序列化

## 对象序列化

> 对象序列化就是把一个 Object 对象所有的信息表示成一个**字节序列**，这包括 Class 信息、继承关系信息、访问权限、变量类型以及数值信息等。

### Serializable

> Java原生的序列化机制，性能较差。

* 类的static 变量，默认不被序列化。
* 显示声明serialVersionUID, 防止InvalidClassException 异常。
* Serializable 的反序列默认不会执行构造函数，当静态变量仅在构造函数中赋值时，可能发生问题。



原理是通过 ObjectInputStream 和 ObjectOutputStream 来实现的：

```java
private void writeFieldValues(Object obj, ObjectStreamClass classDesc)  {
    for (ObjectStreamField fieldDesc : classDesc.fields()) {
        ...
        Field field = classDesc.checkAndGetReflectionField(fieldDesc);
        ...
```

序列化过程中使用反射机制，不仅序列化了对象本身，还会递归序列化引用的其他对象，性能较差且生成的序列化文件也会比Class文件更大。

>  Serializable 的序列化与反序列化的调用流程

```
// 序列化
writeReplace
writeObject
// 反序列化
readObject
readResolve
```

* 定制序列化方法：通过实现`writeObject` 和 `readObject` 方法。
* 自定义返回的序列化实例实现版本兼容：`writeReplace` 和 `readResolve` 方法。



### Parcelable

> 默认只会在内存中进行序列化操作，不会将数据存储到磁盘中。

需要手动实现写入和读取操作，从而避免了反射。在类版本升级中需要注意写入的顺序及字段类型的兼容。



### Serial

> Twitter 开源的高性能序列化方案



## 数据序列化 

### JSON

* 可读性高。
* 使用方便，支持跨平台。



### Protocol Buffers

> Google 开源的跨语言编码协议

* 二进制编码压缩，体积更小，速度更快。
* 不支持继承和引用类型。
* 开发成本较高。
* 跨平台、跨语言支持。

### FlatBuffers

* 压缩率更高