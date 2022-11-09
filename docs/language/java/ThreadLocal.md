

# ThreadLocal

## 相关类UML图

![ThreadLocal](ThreadLocal.assets/ThreadLocal.png)

## 概述

>  线程局部变量(ThreadLocal)
>
> 它实际时为了``方便每个线程处理自己的状态``而引入的一个机制。
>
> 每一个Thread对象中都有一个成员变量``ThreadLocalMap``，map的``key``就是``ThreadLocal实例``, 且为一个弱引用，``value``则是ThreadLocal<?>``范型类型的某个值``，是强引用关系。
>
> 所以ThreadLocal对象实际是起到了一个``索引的作用``。

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

