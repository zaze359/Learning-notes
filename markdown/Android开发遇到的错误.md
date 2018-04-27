
## Gradle 

Tags : zazen

### 一、编译错误

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

- 依赖库发生冲突
```
android {
configurations.all {
        resolutionStrategy.force 'com.test.utils:util:1.1.1'
    }
}

```


- ClassNotFoundException

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