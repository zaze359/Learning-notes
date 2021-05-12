# Gradle 

Tags : zaze android

---

[TOC]

---

## 1. 依赖模式

### 1.1 implementation
```
- 该依赖方式所依赖的库不会传递(只会在当前module中生效)。
- 远程库依赖时依然存在依赖传递
```

### 1.2 api

```
该依赖方式会传递所依赖的库。
```

### 1.3 compileOnly
```
只在编译时有效，不参与打包。
```

```
使用场景:
- 单模块调试时, 将其他模块标志为compileOnly
- 处理依赖冲突
- 动态加载jar?
```

### 1.4 runtimeOnly
```
编译时不参与, 只参与apk打包
```


### 编译错误

---
```
A problem occurred configuring project ':app'.
> Failed to notify project evaluation listener.
   > com.android.build.gradle.tasks.factory.AndroidJavaCompile.setDependencyCacheDir(Ljava/io/File;)V

```
```
- 原因
gradle-wrapper.properties和gradle 版本不兼容问题
- 处理方式
更新配置到最新
使用项目本身的 gradlew 编译
```

---

### 依赖库发生冲突
```
android {
configurations.all {
    resolutionStrategy.force "com.android.support:appcompat-v7:$rootProject.supportLibraryVersion"
    resolutionStrategy.force "com.android.support:support-v4:$rootProject.supportLibraryVersion"
    resolutionStrategy.force "com.android.support:support-v13:$rootProject.supportLibraryVersion"
    resolutionStrategy.force "com.android.support:recyclerview-v7:$rootProject.supportLibraryVersion"
    resolutionStrategy.force "com.android.support:support-annotations:$rootProject.supportLibraryVersion"
    resolutionStrategy.force "com.android.support:design:$rootProject.supportLibraryVersion"
}
```
---

### SNAPSHOT更新问题

```
configurations.all {
    resolutionStrategy.cacheChangingModulesFor 1, 'seconds'
    resolutionStrategy.cacheDynamicVersionsFor 1, 'seconds'
}
```
---
### ClassNotFoundException

```
- 高版本正常运行 低版本报错
- 检查是否分包（multiDexEnabled = true）
若分包了则添加依赖
1. compile 'com.android.support:multidex:1.0.2'
2. 继承MultiDexApplication或者 Application中添加以下代码
@Override
protected void attachBaseContext(Context base) {
    super.attachBaseContext(base);
    MultiDex.install(this);
}
```

