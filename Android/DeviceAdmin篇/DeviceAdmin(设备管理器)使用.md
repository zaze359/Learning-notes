# DeviceAdmin(设备管理器)使用

[TOC]

## 如何使用

1. res/xml/device_admin , 声明所需的设备管理器功能

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <device-admin xmlns:android="http://schemas.android.com/apk/res/android">
       <uses-policies>
           <!-- 限制密码类型 -->
           <limit-password />
           <!-- 重置密码 -->
           <reset-password />
           <!-- 设置密码有效期 -->
           <expire-password />
           <!-- 监控屏幕解锁 -->
           <watch-login />
           <!-- 锁屏 -->
           <force-lock />
           <!-- 恢复出厂设置 -->
           <wipe-data />
   
           <encrypted-storage />
           <disable-keyguard-features />
   
           <disable-camera />
       </uses-policies>
   </device-admin>
   ```

2. 定义AdminReceiver, 继承DeviceAdminReceiver, 接收设备管理器相关广播。

   ```kotlin
   class MyAdminReceiver : DeviceAdminReceiver() {
       override fun onEnabled(context: Context?, intent: Intent?) {
           super.onEnabled(context, intent)
           Log.i("MyAdminReceiver", "MyAdminReceiver onEnable")
       }
   
       override fun onDisabled(context: Context?, intent: Intent?) {
           super.onDisabled(context, intent)
           Log.w("MyAdminReceiver", "MyAdminReceiver onDisabled")
       }
   }
   ```

   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <manifest xmlns:android="http://schemas.android.com/apk/res/android"
       package="com.zaze.admin">
       <application>
           <!-- 设备管理器权限，注册权限监听器 -->
           <receiver
               android:name=".MyAdminReceiver"
               android:permission="android.permission.BIND_DEVICE_ADMIN">
               <meta-data
                   android:name="android.app.device_admin"
                   android:resource="@xml/device_admin" />
   
               <intent-filter>
                   <action android:name="android.app.action.DEVICE_ADMIN_ENABLED" />
               </intent-filter>
           </receiver>
       </application>
   </manifest>
   ```

3. 获取DevicePolicyManager

   ```kotlin
   private fun getDevicePolicyManager(context: Context): DevicePolicyManager {
     return context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
   }
   ```

4. 添加设备管理器

   ```kotlin
   fun addDeviceAdmin(context: Activity, requestCode: Int): Boolean {
     val isActive = getDevicePolicyManager(context).isAdminActive(ComponentName(context, MyAdminReceiver::class.java))
     if (isActive) {
       ZLog.i(TAG, "设备管理器已激活!")
       return true
     }
     try {
       val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
       intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, ComponentName(context, MyAdminReceiver::class.java))
       // 提示文本
       intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "test txt")
       context.startActivityForResult(intent, requestCode)
       ZLog.i(TAG, "请求启动设备管理器...")
     } catch (e: Exception) {
       ZLog.w(TAG, "启动设备管理器 发生异常", e)
       return false
     }
     return true
   }
   ```

5. 移除设备管理器

   ```kotlin
   fun removeDeviceAdmin(context: Context) {
     try {
       ZLog.i(TAG, "请求解锁设备管理器")
       getDevicePolicyManager(context).removeActiveAdmin(ComponentName(context, MyAdminReceiver::class.java))
     } catch (e: Exception) {
       ZLog.w(TAG, "解锁设备管理器 发生异常!", e)
     }
   }
   ```



## ProfileOwner/DeviceOwner

```bash
dpm set-device-owner --name Test com.action.deviceadmin/.DPMTestReceiver
```

