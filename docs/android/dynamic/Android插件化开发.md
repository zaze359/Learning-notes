# Android插件化开发

[alibaba/dexposed: dexposed enable 'god' mode for single android application. (github.com)](https://github.com/alibaba/dexposed)

[Tencent/Shadow: 零反射全动态Android插件框架 (github.com)](https://github.com/Tencent/Shadow)



## 插件化原理

### 类加载

#### 多ClassLoader

> RePlugin

每一个插件单独一个DexClassLoader。插件的ClassLoader先加载类，基座通过反射调用插件

#### 单ClassLoader

> Small

将插件合并到 基座的 DexClassLoader中。

直接使用类名访问即可，需要避免库版本冲突

### 资源加载



## Tencent/Shadow

### 一、clone项目

[Tencent/Shadow: 零反射全动态Android插件框架 (github.com)](https://github.com/Tencent/Shadow)

```shell
#
git clone git@github.com:Tencent/Shadow.git
## 清理项目
./gradlew clean
```

### 二、项目结构

