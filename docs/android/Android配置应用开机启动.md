# Android配置应用开机启动

[TOC]

Android设备启动后会发送``android.intent.action.BOOT_COMPLETED``

广播。

## 一、代码配置

1. manifest配置

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<receiver android:name=".receiver.BootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED" />
    <action android:name="android.intent.action.ACTION_SHUTDOWN" />
    <action android:name="android.intent.action.REBOOT" />

    <category android:name="android.intent.category.LAUNCHER" />
  </intent-filter>
</receiver>
```

2. 添加广播类BootReceiver

```java
public class BootReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent != null) {
            String action = intent.getAction();
            if (Intent.ACTION_BOOT_COMPLETED.equals(action)) {
                show(context, "收到系统启动广播");
            } else if (Intent.ACTION_SHUTDOWN.equals(action)) {
                show(context, "收到系统关机广播");
            }
        }
    }

    private void show(Context context, String message) {
        ZLog.i(ZTag.TAG, message);
        ToastUtil.toast(context, message);
    }
}
```



## 二、没有接收到广播？

1. 应用安装完成后没有启动过，此时是无法接收到广播的。