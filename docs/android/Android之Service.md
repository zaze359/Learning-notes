# Android之Service

[绑定服务概览  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/components/bound-services?hl=zh-cn#Creating)



## 基础介绍

Service是一种可在后台执行长时间运行操作而不提供界面的应用组件。

* Service默认在主线程中运行。
* 即使用户切换到其他应用，Service仍可在后台继续运行。

### 常用使用场景

* 下载文件等网络事务。
* 播放音乐。
* 执行文件I/O。
* 与ContentProvider交互。
* ..等等

### 常见的服务类型

* **前台服务**：调用`startForegroundService()`启动前台服务。会显示在通知栏中，被用户感知到，并且和用户进行交互，即使用户停止与应用的交互，前台服务仍会继续运行。例如播放音乐。
* **后台服务**：调用`startService()`开启后台服务。后台服务执行的操作对用户是无感的。例如在后台执行文件压缩操作。
  * API >= 26后，对后台服务进行了限制，需要应用在前台时才能启动后台服务。
* **绑定服务**：客户端调用`bindService()`绑定服务。服务端会返回一个IBinder实例供客户端来进行交互。所有的客户端取消绑定后，服务将被销毁。
  * 可以和`startService()`配合使用，这样可以使服务一直在后台运行。

### 重要的回调方法

|                    |                                                              |                                                              |
| ------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `onStartCommand()` | 调用`startService()`时此函数会被调用。                       | 它的返回值可以设置服务被销毁后的重启策略。<br />1. START_NOT_STICKY：终止后除非有待传递的挂起 Intent，否则系统*不会*重建服务。<br />2. START_STICKY：终止后会重新创建服务并调用`onStartCommand()`。但*不会*重新传递最后一个 Intent，会将挂起 Intent 传递。<br />3. START_REDELIVER_INTENT：终止后会重新创建服务并调用`onStartCommand()`。并会重新传递最后一个 Intent。所有挂起 Intent 也均依次传递。 |
| `onBind()`         | 调用`bindService()`时此函数被调用。                          | 不希望绑定时应返回 null。可以返回自定义的Binder、Messager等。 |
| `onUnBind()`       | 所有的客户端都调用了`unbindService()`后被调用。              |                                                              |
| `onRebind()`       | `onUnBind()`被调用后又有客户端来绑定时会被调用。             |                                                              |
| `onCreate()`       | **首次创建服务时调用**，服务启动后不在调用此方法。适用于做一些初始化操作。 | 在`onStartCommand()`和 `onBind()`之前被调用。                |
| `onDestory()`      | 服务不在使用准备销毁时调用。此时应该释放资源。               | 1. 未执行过`onStartCommand()`且所有绑定的服务都取消绑定时会被调用。<br />2. 调用了 `stopSelf()`。<br />3. 调用了 `stopService()`。 |

![image-20230302004848380](./Android%E4%B9%8BService.assets/image-20230302004848380.png)



## 使用方式

### 声明服务

> AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.zaze.tribe.music">
	
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

    <application>
        <service android:name=".service.MusicService" />
    </application>

</manifest>

```

### 创建服务

可以通过 Service 和 IntentService来创建服务。前者比较通用，后者适合处理简单的请求。但是两者的使用方式是相同的。

* Service：是所有服务的基类，它默认在主线程中执行。
* IntentService：适合处理简单的请求，它有自己的工作线程，且在任务执行完成会自动退出。

```kotlin
/**
 * Description :
 * @author : ZAZE
 * @version : 2018-08-31 - 10:26
 */
class MusicService : Service(), IPlayer, MyMediaPlayer.MediaCallback {

    // ------------------------------------------------------
    private lateinit var mediaPlayer: MyMediaPlayer
    private lateinit var playerHandlerThread: HandlerThread
    private lateinit var playerHandler: PlayerHandler
    // ------------------------------------------------------
    private val serviceBinder = ServiceBinder()
	
    // 初始化参数
    override fun onCreate() {
        super.onCreate()
        mediaPlayer = MyMediaPlayer(this).apply {
            mediaCallback = this@MusicService
        }
        playerHandlerThread = HandlerThread("playerHandlerThread")
        playerHandlerThread.start()
        playerHandler = PlayerHandler(this, playerHandlerThread.looper)
        playerHandler.obtainMessage(RESTORE).sendToTarget()
        musicNotification.initialize(this)
    }

    // 释放资源
    override fun onDestroy() {
        super.onDestroy()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            playerHandlerThread.quitSafely()
        } else {
            playerHandlerThread.quit()
        }
    }

    // 处理服务绑定
    override fun onBind(intent: Intent?): IBinder? {
        setupMediaSession()
        return serviceBinder
    }
	
    // 处理服务解绑
    override fun onUnbind(intent: Intent?): Boolean {
        mediaSession?.isActive = false
        stop()
        stopForeground(true)
        return true
    }

    // 处理客户端发送过来的请求
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.action?.let {
           ...
        }
        return START_STICKY
    }

    // ------------------------------------------------------
    inner class PlayerHandler(musicService: MusicService, looper: Looper) : Handler(looper) {
        private val serviceRef = WeakReference<MusicService>(musicService)

        override fun handleMessage(msg: Message) {
            super.handleMessage(msg)
            ...
        }
    }
    // ------------------------------------------------------
	// 自定义的Binder供客户端调用
    inner class ServiceBinder : Binder(), IPlayer {
        
        fun setPlayerCallback(callback: PlayerCallback) {
            this@MusicService.callback = callback
        }

        ....
        // 
        override fun playAt(position: Int) {
            playerHandler.removeMessages(PLAY)
            playerHandler.obtainMessage(PLAY, position, 0).sendToTarget()
        }
		.....
    }

}
```

### 启动服务

```kotlin
/**
 * Description :
 *
 * @author : ZAZE
 * @version : 2018-09-30 - 0:37
 */
class MainActivity : BaseActivity() {
    
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceDisconnected(name: ComponentName?) {
            ZLog.e(ZTag.TAG_DEBUG, "onServiceDisconnected : $name")
            MusicPlayerRemote.mBinder = null
        }

        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            ZLog.i(ZTag.TAG_DEBUG, "onServiceConnected : $name")
            // 获取到Service返回的自定义Binder对象。
            MusicPlayerRemote.mBinder = service as MusicService.ServiceBinder
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MusicPlayerRemote.bindService(this, serviceConnection)
    }

    override fun onDestroy() {
        MusicPlayerRemote.unbindService(this, serviceConnection)
        unregisterReceiver(debugReceiver)
        super.onDestroy()
    }
}
```



```kotlin
package com.zaze.tribe.music

/**
 * Description :
 * @author : ZAZE
 * @version : 2018-07-06 - 00:38
 */
object MusicPlayerRemote {
    /**
     * 当前播放 Music Data
     */
    @JvmStatic
    val curMusicData = MutableLiveData<Music>()
    
    /**
     * 是否在播放中
     */
    @JvmStatic
    val isPlaying = ObservableBoolean(false)
    //
    var mBinder: MusicService.ServiceBinder? = null
        set(value) {
            field = value
            field?.setPlayerCallback(object : MusicService.PlayerCallback {
                override fun onStart(music: Music) {
                    ZLog.i(ZTag.TAG_DEBUG, "onStart : $music")
                    curMusicData.set(music)
                    isPlaying.set(true)
                }

                override fun onPause() {
                    ZLog.i(ZTag.TAG_DEBUG, "onPause")
                    isPlaying.set(false)
                }
            })
        }

    // ------------------------------------------------------

    @JvmStatic
    fun bindService(context: Context, serviceConnection : ServiceConnection) {
        // 启动服务，保证解绑后依然运行
        context.startService(Intent(context, MusicService::class.java))
        // 绑定服务
        context.bindService(Intent(context, MusicService::class.java), serviceConnection, Context.BIND_AUTO_CREATE)
    }

    @JvmStatic
    fun unbindService(context: Context, serviceConnection : ServiceConnection) {
        // 解绑服务
        context.unbindService(serviceConnection)
    }

    @JvmStatic
    fun playAt(position: Int) {
        mBinder?.playAt(position)
    }

}
```

