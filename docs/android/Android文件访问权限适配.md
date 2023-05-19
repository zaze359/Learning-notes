# Android文件访问权限适配

[权限申请流程](../Android中的权限.md)

## Android 6.0之前

仅需要`AndroidManifest.xml`中声明权限即可。

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

## Android 6.0 ~ Android 10

1. `AndroidManifest.xml`中声明权限：

    ```xml
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    ```

2. 运行时申请权限



## Android 10

在之前的基础上增加了限制。

1. `AndroidManifest.xml`中声明权限：

   > 需要配置： `android:requestLegacyExternalStorage="true"`
   >
   > 应用target < 29：默认带有此属性
   >
   > 应用target = 29： 允许andorid 应用已旧的存储方式访问

   ```xml
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   <application
   	android:requestLegacyExternalStorage="true">
   ```

2. 运行时申请权限

## Android 11 及以上

从Android11开始 将强制执行分区存储。限制的更加严格。

**只能访问系统为应用提供目录（`getExternalFilesDirs()`）**。应用自身基本将无法在其他外部存储上进行访问操作。

**无法访问其他应用的数据目录**（即使设置了低版本的`target`也无法访问）。

需要及时做数据迁移。

[Android 11 中的存储机制更新  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/about/versions/11/privacy/storage#scoped-storage)

1. `AndroidManifest.xml`中声明权限：

   >  `android:requestLegacyExternalStorage="true"`配置也被废弃。
   >
   > 应用target < 29：默认带有此属性
   >
   > 应用target = 29： 允许andorid 应用已旧的存储方式访问
   >
   > 应用target >= 30：并运行在 Android 11以上，系统忽略此属性，**应用需做数据迁移**。

   ```xml
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   <application
   	android:requestLegacyExternalStorage="true">
   ```

2. 运行时申请权限



> 在Android11及以上版本仅能操作媒体文件和图片

- target < 29 默认带有此属性
- target=29:允许andorid 应用已旧的存储方式访问
- target >=30 并运行在 android 11以上，系统忽略此属性，应用需做数据迁移。



### 所有文件访问权限配置

[管理存储设备上的所有文件  |  Android 开发者  |  Android Developers](https://developer.android.com/training/data-storage/manage-all-files)

> `AndroidManifest.xml`中声明权限
> 在Android11及以上版本仅能操作媒体文件和图片
>
> 若需要获取所有文件管理权限

```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

```xml
<!-- 以下配置在 Android 11 之后需要声明，以便管理所有文件-->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

使用：

```kotlin
// 判断是否有文件管理权限
Environment.isExternalStorageManager()
// 跳转设置打开权限
val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
context.startActivity(intent)

```







## 后续版本适配

文件访问的权限访问后续会更加严格，参考官方文档适配即可。

[Android Releases  | Android 各个版本](https://developer.android.google.cn/about/versions)

[Android 13 功能和变更列表  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/about/versions/13/summary?hl=zh-cn)

Android 13 开始 `READ_EXTERNAL_STORAGE` 也将没用了，访问媒体的权限进一步细分。

| 媒体类型   | 请求权限                                                     |
| :--------- | :----------------------------------------------------------- |
| 图片和照片 | [`READ_MEDIA_IMAGES`](https://developer.android.google.cn/reference/android/Manifest.permission?hl=zh-cn#READ_MEDIA_IMAGES) |
| 视频       | [`READ_MEDIA_VIDEO`](https://developer.android.google.cn/reference/android/Manifest.permission?hl=zh-cn#READ_MEDIA_VIDEO) |
| 音频文件   | [`READ_MEDIA_AUDIO`](https://developer.android.google.cn/reference/android/Manifest.permission?hl=zh-cn#READ_MEDIA_AUDIO) |