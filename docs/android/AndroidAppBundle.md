# Android App Bundle



判断应用是否是已aab 方式安装?

判断 `ApplicationInfo.splitSourceDirs` 是否存在文件，它是 Android App Bundle(拆分式APK) 中资源包路径。

也可以使用  `PackageInfo.splitSourceDirs` ，仅返回文件名。

