# Android广播机制

## 广播的类型

### 标准广播 （Normal broadcasts）

**异步执行的广播**，所有广播接收器会在**同时收到广播消息**，所以传播效率高。

* 广播接收器之间没有先后关系。
* 广播无法被截断。

### 有序广播 （Ordered broadcasts）

**同步执行的广播**，同一时刻只会有一个广播接收器收到广播消息，只有当当前的接收器处理完成后才会继续向下传播消息。

* 广播接收器之间存在先后关系。根据优先级来决定顺序。
* 广播可以通过 `abortBroadcast()`截断广播，这要就不会往后面继续传播消息了。



## 如何使用广播

### 创建接收器（BroadcastReceiver）

Android提供了 `BroadcastReceiver` 类来供我们创建一个广播接收器。它可以接收广播消息。

* 继承 `BroadcastReceiver` 自定义广播接收器。
* 重写 `onReceive()`方法来处理广播消息。**需要避免耗时操作，否则会导致ANR**。

```java
public class TestBroadcastReceiver extends BroadcastReceiver {
    public static final String ACTION = "android.intent.action.message.testappid";
    public static final String TEST = "test";
    public static final String ID = "id";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        ZLog.v(ZTag.TAG_DEBUG, "onReceive: " + action);
        if (TextUtils.equals(action, ACTION)) {
            int id = intent.getIntExtra(ID, -1);
            ZLog.v(ZTag.TAG_DEBUG, "onReceive id : " + id);
        }
    }
}
```

### 注册广播

广播的注册分为**静态注册** 和 **动态注册**。

#### 静态注册

#### 动态注册

```java
IntentFilter intentFilter = new IntentFilter();
intentFilter.addAction(TestBroadcastReceiver.ACTION);
registerReceiver(new TestBroadcastReceiver(), intentFilter);
```

