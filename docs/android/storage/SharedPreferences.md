# SharedPreferences

> 使用方便，开发成本低，兼容性好。

## 使用场景

* 适合存储一些比较简单、轻量的键值对数据；文件不易过大。

## 存在的问题

* **加载慢**。文件加载时使用了异步线程，且加载线程没有设置线程优先级，所以当主线程读取数据时，需要等待加载线程的结束。导致了**主线程等待低优先级线程锁的问题**。可以使用提前异步线程预加载来优化。
* **跨进程不安全**。没有跨进程锁，在跨进程频繁读写时容易导致数据全部丢失。
* **全量写入**。sp的任何改动调用`commit`或`apply`时都是全量写入的。且为**多次提交多次全量写入**。
* **apply导致卡顿或ANR**。由于`apply`提供的是异步落盘机制，为了尽量避免在崩溃或异常时导致数据丢失，当应用`收到系统广播或者被调用onPause等`一些时机时, 系统会强制把所有的sp数据落到磁盘中。如果没有落地完成，主线程就会被阻塞发生卡顿，甚至ANR。

## 一些使用方式

### 替换系统默认实现方式

```java
public class MyApplication extends Application {
  @Override
  public SharedPreferences getSharedPreferences(String name, int mode)        
  {
     return SharedPreferencesImpl.getSharedPreferences(name, mode);
  }
}
```





