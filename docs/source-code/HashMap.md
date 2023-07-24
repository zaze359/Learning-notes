# HashMap源码学习

* 底层结构：数组 + 链表 + 红黑树。

> Java 中 HashMap。
>
> 长度为 2的幂次，

```java
public class HashMap<K,V> extends AbstractMap<K,V> implements Map<K,V>, Cloneable, Serializable {
    private static final long serialVersionUID = 362498820763181265L;
    /**
     * The maximum capacity, used if a higher value is implicitly specified
     * by either of the constructors with arguments.
     * MUST be a power of two <= 1<<30.限制最大长度
     */
    static final int MAXIMUM_CAPACITY = 1 << 30;
    
    static final int hash(Object key) {
        int h;
        return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
    }
    
    // 插入
    public V put(K key, V value) {
        return putVal(hash(key), key, value, false, true);
    }
    final V putVal(int hash, K key, V value, boolean onlyIfAbsent, boolean evict) {}
    
    // 长度一定是2的幂次
    static final int tableSizeFor(int cap) {
        int n = cap - 1;
        n |= n >>> 1;
        n |= n >>> 2;
        n |= n >>> 4;
        n |= n >>> 8;
        n |= n >>> 16;
        return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
    }
}
```

> hash() 哈希函数有时被称为 扰动函数
>
> hashCode返回Int值，最高32位，直接作为下标，近40亿长度的数组，内存中是存不下的。
>
> 通过将高16位和低16位进行异或运算混合，高位的变化会反应到地位中，也保证一定随机性。
>
> 16位的长度，最大为65536。

```java
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```



> 在插入删除中存在类似 (length - 1) & hash 结构的计算。
>
> 目的是计算index并保证index均匀分布。
>
> **实现原理：**
>
> 【除留余数法】等式：`A % B = A & (B - 1)`, 当且仅当**B = 2的指数**时成立。
>
> HashMap的长度是2的幂次，此时 (length - 1)，相当于低位掩码,  从而只保留hash的低位，并用来做数组下标。
>
> 最终结果就是相当于根据长度取余，保证了均匀分布。

```java
i = (n - 1) & hash]
```

> put()

```java
 // 插入
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}
final V putVal(int hash, K key, V value, boolean onlyIfAbsent, boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    // i = (n - 1) & hash],计算index
    if ((p = tab[i = (n - 1) & hash]) == null)
        tab[i] = newNode(hash, key, value, null);
    else {
        Node<K,V> e; K k;
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            e = p;
        else if (p instanceof TreeNode)
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        else {
            for (int binCount = 0; ; ++binCount) {
                if ((e = p.next) == null) {
                    p.next = newNode(hash, key, value, null);
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash);
                    break;
                }
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    break;
                p = e;
            }
        }
        if (e != null) { // existing mapping for key
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;
            afterNodeAccess(e);
            return oldValue;
        }
    }
    ++modCount;
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}
```

