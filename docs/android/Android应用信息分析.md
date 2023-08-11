# Android应用信息分析

## 基础属性

### PackageInfo

此类主要是应用apk相关的信息， 我们可以通过``PackageManager``获取。

- 从已安装应用中获取

  ```kotlin
      fun getPackageInfo(context: Context, flag: Int = 0): PackageInfo? {
          return try {
              context.packageManager.getPackageInfo(context.packageName, flag)
          } catch (e: PackageManager.NameNotFoundException) {
              ZLog.e(ZTag.TAG_DEBUG, "PackageManager.NameNotFoundException : ${context.packageName}")
              null
          }
      }
  ```

- 从apk文件中获取

  ```kotlin
      fun getPackageArchiveInfo(context: Context, fileName: String?): PackageInfo? {
          if (fileName.isNullOrEmpty()) {
              return null
          }
          return context.packageManager.getPackageArchiveInfo(fileName, 0)
      }
  ```


### ApplicationInfo

包含应用的一些基础信息，对应项目``AndroidManifest.xml``文件下 ``<application>``标签中的内容

|                    |                                     |      |
| ------------------ | ----------------------------------- | ---- |
| sourceDir          | 应用安装后，APK文件在系统中的路径。 |      |
| resourceDirs       | overlay Package的路径               |      |
| nativeLibraryDir   | so库路径。                          |      |
| sharedLibraryFiles | 资源共享库                          |      |



## 应用使用情况统计