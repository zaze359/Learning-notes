# FAQ

## MacBook

[如何重置 Mac 的 SMC - Apple 支持 (中国)](https://support.apple.com/zh-cn/HT201295)



## python3软连接方式处理python无法运行的问题

```shell
sudo ln -s /usr/local/bin/python3 python
```

## CocoaPods错误

error:
```
CDN: trunk URL couldn't be downloaded
```

修改``/etc/hosts``文件
```
199.232.4.133 raw.githubusercontent.com
```



## Android相关

### Console控制台乱码

`Help->Edit Custom VM Options`添加以下内容：

```tex
-Dfile.encoding=UTF-8
```



### 编译时提示 `编码 GBK 的不可映射字符`

> 需要`build.gradle`

```groovy
tasks.withType(JavaCompile) {
    options.addStringOption('Xdoclint:none', '-quiet')
    options.encoding = "UTF-8"
}
```

### JavaDoc导出编码错误

> Tools -> Generate JavaDoc

```shell
# Other command line arguments
-encoding utf-8 -charset utf-8
```





### 依赖模式

1. implementation

```
- 该依赖方式所依赖的库不会传递(只会在当前module中生效)。
- 远程库依赖时依然存在依赖传递
```

2. api

```
该依赖方式会传递所依赖的库。
```

3. compileOnly

```
只在编译时有效，不参与打包。
```

```
使用场景:
- 单模块调试时, 将其他模块标志为compileOnly
- 处理依赖冲突
- 动态加载jar?
```

4. runtimeOnly

```
编译时不参与, 只参与apk打包
```

### Gradle编译错误

---

```groovy
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

报错资源无法找到

```
AAPT: error: resource drawable/default_background (aka com.xxxx:drawable/xxxx.xml
```

检查对应的xml文件是否正确, 例如下面 ``<?xml>``标签重复出现了2次

```xml
<?xml version="1.0" encoding="utf-8"?><?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    .....
</layer-list>
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

### Maven仓库无法更新错误

错误信息:``Using insecure protocols with repositories, without explicit opt-in,``

处理方式：

1. 若支持https，将地址改为https即可。
2. 设置 ``allowInsecureProtocol = true``

```groovy
maven {
  allowInsecureProtocol = true
  url 'http://localhost:8081/repository/maven-public'
}
```

### .9问题

```
..... file failed to compile ...
```

```
# build.gradle  defaultConfig 下添加
aaptOptions.cruncherEnabled=false
aaptOptions.useNewCruncher=false
```

> 还是自己根据原图编辑.9比较靠谱

---

## 浏览器相关清理

### 清理站点数据

- 进入**开发者工具**(F12)
- 选择**应用程序**
- 点击**存储**

![image-20210910151720488](问题处理备份.assets/image-20210910151720488.png)

### DNS清理

```http
chrome://net-internals/#dns
edge://net-internals/#dns
```

![image-20210910151556761](问题处理备份.assets/image-20210910151556761.png)

## markdown

### 强制换页

```
<div STYLE="page-break-after: always;"></div>
```

## cmd相关

### npm

修改仓库地址

```shell
npm config set registry "https://registry.npm.taobao.org"
```

### 在此系统上禁止运行脚本

```
PS C:\WINDOWS\system32> docsify
docsify : 无法加载文件 C:\Users\zaze\AppData\Roaming\npm\docsify.ps1，因为在此系统上禁止运行脚本
```

以管理员权限打开PowerShell，修改执行策略

```shell
## 1
set-ExecutionPolicy RemoteSigned
## 2 根据提示
A
```

### homebrew

```
Error: Another active Homebrew update process is already in progress.
```
处理方式:
```
rm -rf /usr/local/var/homebrew/locks
```



## SQL

```bash
unrecognized token: "xxxx"
```

字符串字段使用时注意增加 单引号。

```sqlite
SELECT * FROM books WHERE url='$url'
```
