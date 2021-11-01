# 一些常用的Intent跳转

## 应用详情界面

显示应用详情，常用于权限被永久拒绝时，引导用户打开权限

```kotlin
val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
intent.setData(Uri.fromParts("package", packageName, null))
```

## 应用使用量

申请获取应用使用权限

```kotlin
val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
```

