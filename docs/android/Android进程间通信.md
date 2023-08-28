# Android进程间通信

android中进程间通信的方式主要有以下几种：

* **Bundle**：主要是通过Intent来传递Bundle数据。常用于四大组件间的进程间通信。
* **Messenger**：和Handler、Service结合使用。它是以**串行的方式处理请求**，**不适用于需要处理多线程的高并发IPC通信场景**。
* **AIDL**：Android接口定义语言，它是基于Binder的一套封装。支持一对多的并发实时通信同时也支持RPC，实现也比较复杂。适用于存在多应用访问服务，并在服务中需要多线程处理的场景。
* **Socket**：功能强大，支持一对多的并发实时通信，就是实现比较繁琐，且不支持RPC，以字节流方式传输。
* **ContentProvider**：
* **文件共享**：
* **共享内存**： Ashem



## Messenger

Messenger适用于不需要处理多线程的低并发IPC通信场景，它不支持RPC调用，只能通过 Message进行传输。

* 首先创建Service和Client。
* 在Service中使用Handler构建Messenger实例。
* 通过`Messenger.getBinder()`获取IBinder，并通过Service的 `onBind()`方法中返回 。
* 在Client中定义ServiceConnection来连接服务，并适用服务端返回的IBinder来创建Messenger，通过它可以向Service发送Message消息。
* 另外，Client还可以定义一个自己的Messenger 并通过`msg.replyTo`将它传给Service，这样服务端就能给客户端发送消息。

> 通过 Message.setData 来设置 Bundle数据进行传输，需要保证序列化。

### 定义服务端

> MessengerService
>
> 将服务放于单独的进程，模拟跨进程场景。

```xml
<service
         android:name=".ipc.MessengerService"
         android:process=":ipc" />
```

```java
package com.zaze.demo.debug;

/**
 * Description :
 *
 * @author : ZAZE
 * @version : 2018-04-25 - 15:31
 */
public class MessengerService extends Service {

    private static HandlerThread handlerThread = new HandlerThread("test_thread");

    static {
        handlerThread.start();
    }

    @Override
    public void onCreate() {
        super.onCreate();
    }
	// 服务端messenger
    Messenger messenger = new Messenger(new Handler(handlerThread.getLooper()) {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            ZLog.i(ZTag.TAG_DEBUG, "handleMessage");
            Message msgToClient = Message.obtain(msg);
            // 需要使用Bundle来封装数据
            bundle.putString("replay", msgToClient.what + " is reached");
            msgToClient.setData(bundle);
            try {
                // 向客户端发送回执。
                msg.replyTo.send(msgToClient);
            } catch (RemoteException e) {
                e.printStackTrace();
            }
        }
    });

    @Override
    public IBinder onBind(Intent intent) {
        // 返回给客户端
        return messenger.getBinder();
    }
}

```

---

### 定义客户端

> IPCActivity

```kotlin
package com.zaze.demo.component.ipc

/**
 * Description :
 * @author : zaze
 * @version : 2021-07-15 - 14:38
 */
class IPCActivity : AbsActivity() {
    private var messengerThread = HandlerThread("messenger_thread").apply { start() }
    // 传给服务端，向客户端发送消息
    private val clientMessenger = Messenger(object : Handler(messengerThread.looper) {
        override fun handleMessage(msg: Message) {
            super.handleMessage(msg)
            ZLog.i(ZTag.TAG_DEBUG, "receiver messenger reply message")
            replayToService()
        }
    })
    // 向服务端发送消息
    private var serviceMessenger: Messenger? = null
    private val serviceConnection: ServiceConnection = object : ServiceConnection {
        override fun onServiceDisconnected(name: ComponentName?) {
            serviceMessenger = null
        }

        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            serviceMessenger = Messenger(service)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 绑定服务
        bindService(
            Intent(this, MessengerService::class.java),
            serviceConnection,
            Context.BIND_AUTO_CREATE
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        unbindService(serviceConnection)
    }
    
    private fun replayToService() {
        val msg = Message.obtain()
        msg.replyTo = clientMessenger
        serviceMessenger?.send(msg)
    }
}
```

---

## AIDL

AIDL 默认支持下列数据类型：

| 支持的类型   | 说明                                                         |
| ------------ | ------------------------------------------------------------ |
| 所有基础类型 | `int`、`long`、`char`、`boolean` 等                          |
| String       |                                                              |
| CharSquence  |                                                              |
| Parcelable   | 实现了Parcelable接口的类                                     |
| -            |                                                              |
| List         | List中的元素必须是支持的类型。例如：`List<String>`。接收方获取的始终是ArrayList |
| Map          | Map中的元素必须是支持的类型。例如：`Map<String, Integer>`。接收方获取的始终是HashMap |

在aidl文件中有时需要指定数据方向，它存在以下几种：

| 修饰符 | 数据方向                       |                                                              |
| ------ | ------------------------------ | ------------------------------------------------------------ |
| in     | 表示输入参数。客户端 -> 服务端 | 默认为in，会将客户端的数据读取并传给服务端。服务端修改后不会影响客户端。 |
| out    | 表示输出参数。服务端 -> 客户端 | 客户端发送时并不会读取数据，服务端会在binder调用的返回过程中新建一个对象并写入数据，最后通过 reply 返回给我们 |
| inout  | 客户端、服务端都可设置         | 客户端发送时会读取并发送给服务端，服务端修改后会回复给客户端。 |
|        |                                |                                                              |



**oneway**：表示这个接口异步调用，oneway修饰后的接口不可以使用 in、out，并且也不能有返回值。常用于不关心binder状态和返回的接口。

* 由于没有返回值，所以通讯过程中不会生成 reply 局部变量。
* 异步调用，调用oneway修饰的方法不会发生阻塞。

### AIDL通信大致流程

![image-20230302220037955](./Android%E8%BF%9B%E7%A8%8B%E9%97%B4%E9%80%9A%E4%BF%A1.assets/image-20230302220037955.png)



### 定义服务端

#### 创建.aidl文件

直接使用 Android Studio来创建AIDL文件。

![image-20230302122349879](./Android%E8%BF%9B%E7%A8%8B%E9%97%B4%E9%80%9A%E4%BF%A1.assets/image-20230302122349879.png)

创建完成后会生成一个模板文件：

> `IRemoteService.aidl `
>
> 修改以下这个模块

```java
// IRemoteService.aidl
package com.zaze.demo;

interface IRemoteService {
    /**
     * Demonstrates some basic types that you can use as parameters
     * and return values in AIDL.
     */
    void basicTypes(int anInt, long aLong, boolean aBoolean, float aFloat,
            double aDouble, String aString);
	
    // 定义一个接口
    String getMessage();
}
```

项目编译后 在 `app/generated/aidl_source_output_dir/debug or release/out/`目录下会自动生成 `IRemoteService.java`。它内部封装了一套默认的Binder通信架构，我们的 Service 和 Client 也是在这个类的基础上开发的。

#### 创建Service

> 继承 IRemoteService.Stub 来实现Binder Service的具体功能。
>
> 此处的Service类只是我们实现Binder Service的一个载体。
>
> binder 才指向真正的Binder Service，需要在 Service.onBind() 函数中返回 binder 的实例，供外部调用服务。

```kotlin
package com.zaze.demo.ipc

class RemoteService : Service() {
	// 继承Stub，实现具体的功能，此处使用匿名内部类
    private val binder = object : IRemoteService.Stub() {

        override fun basicTypes(
            anInt: Int,
            aLong: Long,
            aBoolean: Boolean,
            aFloat: Float,
            aDouble: Double,
            aString: String
        ) {
            // Does nothing
        }

        override fun getMessage(): String {
            return "aidl message $count; pid=${android.os.Process.myPid()}"
        }
    }
	
    // 将Binder返回
    override fun onBind(intent: Intent?): IBinder? {
        return binder
    }
}
```

### 定义客户端

> 客户端使用时需要将服务端的 aidl文件全部拷贝过来，才能访问对应接口
>
> * 通过 ``IRemoteService.Stub.asInterface(service)`` 来获取 Proxy实例 访问远程服务。

```kotlin
package com.zaze.demo.ipc

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.*
import com.zaze.common.base.AbsActivity
import com.zaze.common.base.ext.myViewModels
import com.zaze.demo.IRemoteService

/**
 * Description :
 * @author : zaze
 * @version : 2021-07-15 - 14:38
 */
class IPCActivity : AbsActivity() {
    var remoteService: IRemoteService? = null

    private val remoteServiceConnection: ServiceConnection = object : ServiceConnection {
        override fun onServiceDisconnected(name: ComponentName?) {
            remoteService = null
        }

        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            // 通过asInterface() 获取到IRemoteService接口，用于访问服务接口
            remoteService = IRemoteService.Stub.asInterface(service)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        bindService(
            Intent(this, RemoteService::class.java),
            remoteServiceConnection,
            Context.BIND_AUTO_CREATE
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        unbindService(remoteServiceConnection)
    }
}
```

### 传递对象

想要通过IPC来传递某个类，那么该类需要实现Parcelable接口。

* 定义类，并实现Parcelable接口。Android Studio能够自动生成。关键是要存在CREATOR。
* 定义.aidl文件，使用`parcelable`关键字定义类，它的名字和包名需要和定义的类相同。
* 在之前定义的IRemoteService.aidl中 import 这个类。
* 客户端使用是需要拷贝相应文件。

> IpcMessage.kt

```kotlin
package com.zaze.demo.parcel

import android.os.Parcel
import android.os.Parcelable

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

    companion object CREATOR : Parcelable.Creator<IpcMessage> {
        override fun createFromParcel(parcel: Parcel): IpcMessage {
            return IpcMessage(parcel)
        }

        override fun newArray(size: Int): Array<IpcMessage?> {
            return arrayOfNulls(size)
        }
    }
}
```

> IpcMessage.aidl

```java
// IpcMessage.aidl
// 包名一致
package com.zaze.demo.parcel;

// Declare Rect so AIDL can find it and knows that it implements
// the parcelable protocol.
// 类名一致
parcelable IpcMessage;
```

> 修改后的 IRemoteService.aidl

```java
// IRemoteService.aidl
package com.zaze.demo;
// 导入该类
import com.zaze.demo.parcel.IpcMessage;

interface IRemoteService {

    void basicTypes(int anInt, long aLong, boolean aBoolean, float aFloat,
            double aDouble, String aString);

    IpcMessage getMessage();
}
```

### 使用注意点

* 客户端服务端.aidl文件最好能够保持一致。
  * 客户端使用旧的.aidl，一般来说并不会有影响。但是服务端使用旧的aidl将会导致新接口无法调用。
  * 若变更AIDL中函数的定义顺序，两端.aidl文件不一致时将会导致函数调用错乱。因为接口是通过code来访问的，而**接口的code是按照定义顺序来定义的**。**所以不要变更AIDL中函数的定义顺序。**
* 服务端可以将定义.aidl文件及一些Parcelable类一起打包成 aar给客户端使用，保证两端一致。
* 当存在多个不同的业务服务需要支持时，考虑创建一个 **Binder连接池服务**来统一管理这些服务。

### Binder连接池服务

通过定义一个 aidl 来同一管理多个 aidl，即这个连接池服务返回就是其他的 aidl接口对象。同时也可以避免每个AIDL都需要创建一个Service的问题。

> 许多系统服务也是这么实现，最典型的就是ServiceManager，我们通过它来返回各种系统服务的IBinder对象。

定义连接池服务ADIL：

```java
// 连接池服务
interface IRemoteService {
    // 返回消息服务
    IMessageService getMessageService();
}
```

定义消息服务ADIL：

```java
interface IMessageService {
    String getMessage();
}
```

定义 Service 实现服务功能：

```java
/**
 * 这里 aidl的服务端，实现了对应的服务功能
 */
class RemoteService : Service() {

    /** 匿名内部类，实现IRemoteService接口 **/
    private val binder = object : IRemoteService.Stub() {
        override fun getMessageService(): IMessageService {
           	// 返回 MessageService 服务实例，使用一个单例实现即可。
            return MessageService.instance
        }
    }

    override fun onBind(intent: Intent?): IBinder {
        super.onBind(intent)
        return binder
    }
}
```

客户端使用：

```kotlin
```

