
## Gradle 

### 一、编译错误

```
A problem occurred configuring project ':app'.
> Failed to notify project evaluation listener.
   > com.android.build.gradle.tasks.factory.AndroidJavaCompile.setDependencyCacheDir(Ljava/io/File;)V

```
``gradle-wrapper.properties``和gradle 版本不兼容问题

* 更新配置到最新
* 使用项目本身的 gradlew 编译

