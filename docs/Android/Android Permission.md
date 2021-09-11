# Android Permission

[TOC]

## 权限类型

[Android 中的权限  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/permissions/overview)

[Manifest.permission  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/reference/android/Manifest.permission)

### 安装时权限(Install-time permissions)

应用声明了安装时权限，系统会在用户安装应用时自动授予应用相应权限。Android 提供多个安装时权限子类型，包括**普通权限**和**签名权限**。

#### 普通权限(Normal permissions)

对用户隐私及对其他应用的操作带来的风险非常小。

系统会为普通权限分配**“normal”**保护级别。

只需要在AndroidManifest.xml中简单声明这些权限就好，安装时就授权。不需要每次使用时都检查权限，而且用户不能取消以上授权

```
android.permission.ACCESS_LOCATION_EXTRA_COMMANDS
android.permission.ACCESS_NETWORK_STATE
android.permission.ACCESS_NOTIFICATION_POLICY
android.permission.ACCESS_WIFI_STATE
android.permission.ACCESS_WIMAX_STATE
android.permission.BLUETOOTH
android.permission.BLUETOOTH_ADMIN
android.permission.BROADCAST_STICKY
android.permission.CHANGE_NETWORK_STATE
android.permission.CHANGE_WIFI_MULTICAST_STATE
android.permission.CHANGE_WIFI_STATE
android.permission.CHANGE_WIMAX_STATE
android.permission.DISABLE_KEYGUARD
android.permission.EXPAND_STATUS_BAR
android.permission.FLASHLIGHT
android.permission.GET_ACCOUNTS
android.permission.GET_PACKAGE_SIZE
android.permission.INTERNET
android.permission.KILL_BACKGROUND_PROCESSES
android.permission.MODIFY_AUDIO_SETTINGS
android.permission.NFC
android.permission.READ_SYNC_SETTINGS
android.permission.READ_SYNC_STATS
android.permission.RECEIVE_BOOT_COMPLETED
android.permission.REORDER_TASKS
android.permission.REQUEST_INSTALL_PACKAGES
android.permission.SET_TIME_ZONE
android.permission.SET_WALLPAPER
android.permission.SET_WALLPAPER_HINTS
android.permission.SUBSCRIBED_FEEDS_READ
android.permission.TRANSMIT_IR
android.permission.USE_FINGERPRINT
android.permission.VIBRATE
android.permission.WAKE_LOCK
android.permission.WRITE_SYNC_SETTINGS
com.android.alarm.permission.SET_ALARM
com.android.launcher.permission.INSTALL_SHORTCUT
com.android.launcher.permission.UNINSTALL_SHORTCUT
```



#### 签名权限(Signature permissions)

当应用声明了其他应用已定义的签名权限时，如果两个应用使用同一证书进行签名，系统会在安装时向前者授予该权限。否则，系统无法向前者授予该权限。

系统会为签名权限分配**“signature”**保护级别

### 运行时权限(Runtime permissions)

允许应用执行对系统和其他应用具有更严重影响的受限操作。需要先在应用中[请求运行时权限](https://developer.android.google.cn/training/permissions/requesting)，然后才能访问受限数据或执行受限操作。

系统会为运行时权限分配“dangerous”保护级别

### 特殊权限(Special permissions)



## 获取运行时权限

### EasyPermissions

[googlesamples/easypermissions: Simplify Android M system permissions (github.com)](https://github.com/googlesamples/easypermissions)

```
dependencies {
    // For developers using AndroidX in their applications
    implementation 'pub.devrel:easypermissions:3.0.0'
 
    // For developers using the Android Support Library
    implementation 'pub.devrel:easypermissions:2.0.1'
}
```

