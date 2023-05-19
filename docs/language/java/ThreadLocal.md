

# ThreadLocal

ThreadLocal（线程局部变量） 时 **TLS( 线程局部变量存储空间)** 机制的一种实现，它是**为了方便每个线程处理自己的状态而引入的一个机制**。每个线程都存在一个私有的空间，线程间不共享。

## UML

![ThreadLocal](ThreadLocal.assets/ThreadLocal.png)

---

## 源码

* 每一个Thread对象中都有一个成员变量``ThreadLocalMap``。
  * **key**：就是ThreadLocal实例，且为一个弱引用。
  * **value**：是 `ThreadLocal<?>`  范型类型的某个值，是强引用关系。

* ThreadLocal对象实际是**起到了一个索引的作用**。

```java
public class ThreadLocal<T> {
    public T get() {
        Thread t = Thread.currentThread();
        ThreadLocalMap map = getMap(t);
        if (map != null) {
            ThreadLocalMap.Entry e = map.getEntry(this);
            if (e != null)
                return (T)e.value;
        }
        return setInitialValue();
    }
}

public void set(T value) {
  Thread t = Thread.currentThread();
  ThreadLocalMap map = getMap(t);
  if (map != null)
    map.set(this, value);
  else
    createMap(t, value);
}

 ThreadLocalMap getMap(Thread t) {
   return t.threadLocals;
 }
```
