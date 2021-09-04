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

