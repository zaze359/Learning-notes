# ARouter路由框架

## 基本使用

### 添加依赖

```kotlin
@Suppress("DSL_SCOPE_VIOLATION") // TODO: Remove once KTIJ-19369 is fixed
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kapt)
    alias(libs.plugins.hilt)
}
android {
   
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
  	// 需要配置 module_name
    kapt {
        arguments {
            arg("AROUTER_MODULE_NAME", project.name)
        }
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = libs.versions.compose.compiler.get()
    }
}

dependencies {
  	// 依赖
    implementation(libs.arouter.api)
    kapt(libs.arouter.compiler)
}
```



### SDK初始化

```kotlin
class App : Application() { 
  
    override fun onCreate() {
      super.onCreate()
      initRouter()
  	}
  
    private fun initRouter() {
        if (BuildConfig.DEBUG) { // 这两行必须写在init之前，否则这些配置在init过程中将无效
            // 打印日志
            ARouter.openLog()
            // 开启调试模式(如果在InstantRun模式下运行，必须开启调试模式！线上版本需要关闭,否则有安全风险)
            ARouter.openDebug()
        }
        ARouter.init(this)
    }
}
```



### 路由跳转

```kotlin
```



### 问题处理

#### Androidx兼容配置

`AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.zaze.apps">

    <application
        ...
        android:appComponentFactory="androidx.core.app.CoreComponentFactory"
        tools:replace="android:appComponentFactory"
        tools:targetApi="p">
  </application>
</manifest>
```

`grade.properties` 

```properties
# 将 support 转为 androidx
android.enableJetifier=true
```

#### 路由无法跳转

1. 尝试卸载应用后重新安装。

2. 检查模块的Gradle配置: 主要是 kapt的配置，arouter.compiler、AROUTER_MODULE_NAME

3. 检查类的path： message模块下的 路由path, 需要已 `/message/xxx` 的形式

   



## 原理分析

ARouter怎么实现接口调用？

ARouter怎么实现页面拦截？