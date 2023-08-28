# Android之数据序列化

## 对象序列化

对象序列化就是把一个 Object 对象所有的信息表示成一个**字节序列**，包括了 Class 信息、继承关系信息、访问权限、变量类型以及数值信息等。

### Serializable

Java自带的序列化接口，使用简单但是性能较差。可以将对象序列化到本地存储或用于网络传输。

* 序列化过程中**使用反射机制**。性能较差且生成的序列化文件也会比Class文件更大。
* 不仅会序列化了对象本身，还会递归序列化引用的其他对象。所以内部的成员变量也需要是可序列化的。
* **需要显示声明serialVersionUID**，防止InvalidClassException 异常。
*  **static 变量 无法被序列化**，因为static 变量是属于类而不是对象的。
* `@Transient`注解修饰的成员变量也不会被序列化。反序列化时获取到null。
* Serializable 的反序列化默认不会执行构造函数。当静态变量仅在构造函数中赋值时，可能发生问题。

它可以通过 `ObjectOutputStream` 来实现序列化，通过 `ObjectInputStream` 来实现反序列化：

```java
private void writeFieldValues(Object obj, ObjectStreamClass classDesc)  {
    for (ObjectStreamField fieldDesc : classDesc.fields()) {
        // ...
        Field field = classDesc.checkAndGetReflectionField(fieldDesc);
        //...
    }
}
```

>  Serializable 的序列化与反序列化的调用流程

```shell
# 序列化
writeReplace
writeObject
# 反序列化
readObject
readResolve
```

* 定制序列化方法：通过实现`writeObject` 和 `readObject` 方法实现。
* 自定义返回的序列化实例实现版本兼容：通过`writeReplace` 和 `readResolve` 方法实现。

---

### Parcelable

Android提供的序列化方式，性能较高。需要手动实现写入和读取操作，从而避免了反射。在类版本升级中需要注意写入的顺序及字段类型的兼容。

* **默认在内存中进行序列化操作**，不会将数据存储到磁盘中。

借助 Android Studio 我们可以很方便的创建一个 Parcelable 。

```kotlin
class IpcMessage() : Parcelable {
    var id: Int = 0
    var message: String? = null

    constructor(parcel: Parcel) : this() {
        id = parcel.readInt()
        message = parcel.readString()
    }

    override fun writeToParcel(parcel: Parcel, flags: Int) {
        parcel.writeInt(id)
        parcel.writeString(message)
    }

    override fun describeContents(): Int {
        return 0
    }
	
    // 关键是这个
    companion object CREATOR : Parcelable.Creator<IpcMessage> {
        override fun createFromParcel(parcel: Parcel): IpcMessage {
            return IpcMessage(parcel)
        }

        override fun newArray(size: Int): Array<IpcMessage?> {
            return arrayOfNulls(size)
        }
    }

    override fun toString(): String {
        return "IpcMessage(id=$id, message=$message)"
    }
}
```







### Serial

Twitter 开源的高性能序列化方案



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