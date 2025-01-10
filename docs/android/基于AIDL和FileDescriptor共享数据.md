# 基于AIDL和FileDescriptor共享数据

在 Linux 中一切皆文件，所以系统在运行时有大量的文件操作，内核为了高效管理已被打开的文件会创建索引，用来指向被打开的文件，这个索引即是FileDescriptor（文件描述符） 可以被用来表示开放文件、开放套接字等。

## FileProvider

> FileProvider 可以主动分享文件给其他应用，

### 分享端

#### 定义共享文件范围

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <!-- root-path:   / -->
    <!-- files-path:   /data/data/files -->
    <!-- cache-path:   /data/data/cache -->
    <!-- external-path:   /sdcard -->
    <!-- external-files-path:   /sdcard/Android/data/files -->
    <!-- external-cache-path:   /sdcard/Android/data/cache -->
    <root-path
        name="root_path"
        path="." />
    <files-path
        name="file_path"
        path="." />
    <external-path
        name="external_storage_root"
        path="." />
    <external-cache-path
        name="my_external_cache_path"
        path="." />
    <external-files-path
        name="my_external_cache_path"
        path="." />
</paths>
```

#### 声明 FileProvider

```xml
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileProvider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
```

#### 授权分享

- 将文件映射为 Uri。
- 对Uri 授权。
- 将Uri 分享给他人。

```kotlin
private fun authority(context: Context) = "${context.packageName}.fileProvider"

fun share() {
  val outputImage = File(context.externalCacheDir, "image_test.jpg")
  val imageUri = FileProviderHelper.getUriForFile(context, outputImage)
  Intent().let {intent->
      intent.setComponent(ComponentName("com.zaze.demo2", "com.zaze.demo.MainActivity"))
      // 临时授予读取权限
      intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
      intent.setDataAndType(imageUri, "*/jpg")
      launcher.launch(intent)
  }
}
```

### 接收端

```java
try {
    Intent intent = getIntent();
    Uri uri = intent.getData();
  	// 使用 ContentProvider 来获取文件描述符，存在权限校验
    ParcelFileDescriptor fd = FileProviderHelper.INSTANCE.openFileDescriptor(getActivityContext(), uri, "r");
    //
    FileUtil.INSTANCE.write(new FileInputStream(fd.getFileDescriptor()), new FileOutputStream(new File(getActivityContext().getExternalCacheDir(), "aaa.jpg")));
} catch (Throwable e) {
    e.printStackTrace();
}
```



## AIDL + FileDescriptor

[如何使用AIDL](./Android进程间通信.md)

- Binder 支持传输 文件描述符，所以我们可以定义AIDL 接口来返回。
- 创建一个 Pipe，并使用 AutoCloseOutputStream 或 AutoCloseInputStream 来读写文件。

> 优势：可以直接快速灵活的将应用私有数据分享给他人。
>
> 缺点：安全性问题

```kotlin
override fun read(fileName: String?): ParcelFileDescriptor? {
    if (fileName.isNullOrEmpty()) return null
    val file = File("/data/data/com.zaze.demo/files/shared/$fileName")
    val pipe = ParcelFileDescriptor.createPipe()
    val write = ParcelFileDescriptor.AutoCloseOutputStream(pipe[1])
    ThreadPlugins.runInIoThread(Runnable {
        FileUtil.write(
            FileInputStream(file),
            write
        )
    })
    return pipe[0]
}

override fun writeFile(fileDescriptor: ParcelFileDescriptor?, fileName: String?) {
    fileDescriptor ?: return
    if (fileName.isNullOrEmpty()) return
    ZLog.i(ZTag.TAG_DEBUG, "RemoteService: $fileName")
    ThreadPlugins.runInIoThread(Runnable {
        val read = ParcelFileDescriptor.AutoCloseInputStream(fileDescriptor)
        val file = File("/data/data/com.zaze.demo/files/shared/$fileName")
        FileUtil.createFileNotExists(file)
        val outputStream =
            FileOutputStream(file)
        FileUtil.write(read, outputStream)
    })
}
```

