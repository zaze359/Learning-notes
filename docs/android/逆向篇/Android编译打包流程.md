#  Android编译打包流程

学习资料：[Android Apk 编译打包流程，了解一下~ - 掘金 (juejin.cn)](https://juejin.cn/post/7113713363900694565)

> 编译工具主要位于`sdk/build-tools`下

[配置 build  | Android 开发者  | Android Developers](https://developer.android.com/studio/build?hl=zh-cn)

![img](./Android%E7%BC%96%E8%AF%91%E6%89%93%E5%8C%85%E6%B5%81%E7%A8%8B.assets/build-process_2x.png)

## 编译源代码和资源文件

* 将项目源代码、三方库(jar, aar) 转换为 DEX文件。

* 其他所有内容转换为编译后的资源（Complied Resources）。

### 1.编译资源文件

由`AAPT/AAPT2`编译处理资源文件。`AGP3.0.0`之后默认通过`AAPT2`来编译资源。编译生成**针对Android平台进行过优化的二进制文件**。

资源包括：

* `AndroidManifest.xml`配置文件。
* `res`目录下的所有资源文件。
* `assets`目录下的所有文件。

产物：

* `R.java` ：**记录了 资源索引ID**，格式：0xpptteeee ；`PackageId(8位) + TypeId（8位） + EntryId(16位)`
  * 例如`R.drawable.xxx = 0x7f080057`  

* `resources.arsc`：资源索引表。**根据资源索引ID查询到对应的文件路径或者具体的数据值**。
  * 例如 0x7f080057 对应 `./res/drawable/xx.png`
* `res`：drawable、layout、color等资源目录。

### 2.编译源代码生成class

通过编译器（Compiler）将所有`.java/.kt`文件编译成`.class`文件。

注解处理器(`APT/KAPT`)生成代码也在此时，标记为`CLASS`的注解会在编译class文件时生效，生成对应的java代码和class字节码。

* 将R文件编译成class：aapt2 资源打包是生成。
* 将AIDL编译成class：通过`aidl.exe`工具，将项目中的aidl文件编译为java文件。
* 将项目源码编译成class。
* 使用 dex 命令将 上述 class 和 三方库代码。

### 3.将class打包成Dex

使用 `D8`编译器 和 `R8` 工具将 上述**编译生成的class文件** 和 **三方库的class文件** 转换为虚拟机（5.0前是Dalvik，之后为ART）所需的Dex文件。

* ~~Dx~~：AGP3.0.1之前使用的编译器，将class打包成DEX。
* **D8**：AGP3.0.1之后取代 Dx。
  * 速度更快、编译时占用内存更少、生成的Dex文件更小，运行时性能得到提升。


* ~~ProGuard~~：用于代码压缩和混淆的工具。
* **R8**：AGP3.4.0默认使用R8替代了ProGuard。
  * 把 `desugaring`、`shrinking`、`obfuscating`、`optimizing` 和 `dexing` 都合并到一步进行执行。不再像之前先通过ProGuard压缩混淆，在执行`dexing`、`desugaring`等操作。

## 打包APK

### 1.生成APK文件

APK Packager将 DEX Files 和 Complied Resources 组合成APK或AAB。

旧版本为`apkbuilder`，AGP3.6.0后为使用`zipflinger` 构建 生成 apk 文件

* Dex文件。
* aapt 生成的 resources.arsc 和 res文件。
* manifest。
* assets 资源。

### 2.对应APK签名

[Android开发应该知道的签名知识！ - 掘金 (juejin.cn)](https://juejin.cn/post/7111116047960244254)

使用签名工具对 APK 进行签名。

* `jarsigner`：v1签名。JDK提供

* `apksigner`：v2、v3、v4签名。Google专门为Android所提供。

| 签名方式 |                                                              | 存在问题                                                     |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| v1       | 1. 将`META-INFO`之外的所有文件生成摘要写入`MANIFEST.MF`。<br />2. 生成`MANIFEST.MF`的摘要写入`CERT.SF`。<br />3. 计算`CERT.SF`的摘要，并使用私钥计算签名，将签名和开发者证书写入到`CERT.RSA`中。 | 速度慢：需要对apk中所有文件进行校验<br />存在安全隐患：`META-INFO`文件夹不会被签名 |
| v2       | Android 7.0 引入，在文件数据区和中央目录中插入一个`apk签名分块`。 |                                                              |
| v3       | Android 9.0 引入，基于v2, 解决在更新过程中更改签名密钥的问题 |                                                              |
| v4       | Android 11.0 引入。支持ADB增量APK安装                        | 验证流程：v4不过 -> v3不过 -> v2不过 -> v1不过 ->失败        |

### 3.字节对齐

Packager会使用`zipalign`工具对应用进行优化，以减少其在设备上运行时所占用的内存。

`zipalign`会对apk中未压缩的数据进行**4字节对齐**。保证APK包中的所有资源文件距离文件起始偏移为4字节的整数倍，方便后续使用`mmap`函数直接读取文件，否则需要显示读取文件。

zipalign 在使用不同的签名方式下 触发时机会不同：

* `jarsigner`：在**签名前**执行对齐。
* `apksigner`：在**签名后**执行对齐。



## 分析项目打包做了什么

### 执行一次gradle编译

```bash
./gradlew app:assembleDebug --console=plain >> ~/Downloads/build.txt 2>&1
```

```shell
> Task :app:preBuild UP-TO-DATE
> Task :app:preDebugBuild UP-TO-DATE
> Task :app:compileDebugAidl NO-SOURCE
> Task :app:compileDebugRenderscript NO-SOURCE
> Task :app:dataBindingMergeDependencyArtifactsDebug UP-TO-DATE
> Task :app:dataBindingMergeGenClassesDebug UP-TO-DATE
> Task :app:generateDebugResValues UP-TO-DATE
> Task :app:generateDebugResources UP-TO-DATE
> Task :app:mergeDebugResources UP-TO-DATE
> Task :app:dataBindingGenBaseClassesDebug UP-TO-DATE
> Task :app:dataBindingTriggerDebug UP-TO-DATE
> Task :app:generateDebugBuildConfig UP-TO-DATE
> Task :app:writeDebugApplicationId UP-TO-DATE
> Task :app:generateSafeArgsDebug UP-TO-DATE
> Task :app:checkDebugAarMetadata UP-TO-DATE
> Task :app:createDebugCompatibleScreenManifests UP-TO-DATE
> Task :app:extractDeepLinksDebug UP-TO-DATE
> Task :app:processDebugMainManifest UP-TO-DATE
> Task :app:processDebugManifest UP-TO-DATE
> Task :app:processDebugManifestForPackage UP-TO-DATE
> Task :app:processDebugResources UP-TO-DATE
> Task :app:kaptGenerateStubsDebugKotlin UP-TO-DATE
> Task :app:kaptDebugKotlin UP-TO-DATE
> Task :app:compileDebugKotlin UP-TO-DATE
> Task :app:compileDebugJavaWithJavac UP-TO-DATE
> Task :app:compileDebugSources UP-TO-DATE
> Task :app:mergeDebugNativeDebugMetadata NO-SOURCE
> Task :app:mergeDebugShaders UP-TO-DATE
> Task :app:compileDebugShaders NO-SOURCE
> Task :app:generateDebugAssets UP-TO-DATE
> Task :app:mergeDebugAssets UP-TO-DATE
> Task :app:compressDebugAssets UP-TO-DATE
> Task :app:processDebugJavaRes NO-SOURCE
> Task :app:mergeDebugJavaResource UP-TO-DATE
> Task :app:checkDebugDuplicateClasses UP-TO-DATE
> Task :app:desugarDebugFileDependencies UP-TO-DATE
> Task :app:mergeExtDexDebug UP-TO-DATE
> Task :app:mergeLibDexDebug UP-TO-DATE
> Task :app:transformDebugClassesWithAsm UP-TO-DATE
> Task :app:dexBuilderDebug UP-TO-DATE
> Task :app:mergeProjectDexDebug UP-TO-DATE
> Task :app:mergeDebugJniLibFolders UP-TO-DATE
> Task :app:mergeDebugNativeLibs UP-TO-DATE
> Task :app:stripDebugDebugSymbols NO-SOURCE
> Task :app:validateSigningDebug UP-TO-DATE
> Task :app:writeDebugAppMetadata UP-TO-DATE
> Task :app:writeDebugSigningConfigVersions UP-TO-DATE
> Task :app:packageDebug UP-TO-DATE
> Task :app:assembleDebug UP-TO-DATE

Deprecated Gradle features were used in this build, making it incompatible with Gradle 7.0.
Use '--warning-mode all' to show the individual deprecation warnings.
See https://docs.gradle.org/6.7.1/userguide/command_line_interface.html#sec:command_line_warnings

BUILD SUCCESSFUL in 1s
37 actionable tasks: 37 up-to-date

```

| Task                                     | 说明                                                         |                                                              |
| ---------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| preBuild                                 |                                                              |                                                              |
| preDebugBuild                            |                                                              |                                                              |
| compileDebugAidl                         | 编译aidl，转为java文件                                       |                                                              |
| compileDebugRenderscript                 | 编译Renderscript                                             |                                                              |
| dataBindingMergeDependencyArtifactsDebug |                                                              |                                                              |
| dataBindingMergeGenClassesDebug          |                                                              |                                                              |
| generateDebugResValues                   | 获取gradle中配置的资源文件                                   |                                                              |
| generateDebugResources                   |                                                              |                                                              |
| mergeDebugResources                      | AAPT2编译阶段，合并资源                                      | 解压所有的aar包输出到app/build/intermediates/exploded-aar，并且把所有的资源文件合并到app/build/intermediates/res/merged/debug |
| dataBindingGenBaseClassesDebug           |                                                              |                                                              |
| dataBindingTriggerDebug                  |                                                              |                                                              |
| generateDebugBuildConfig                 | 生成BuildConfig文件                                          |                                                              |
| writeDebugApplicationId                  |                                                              |                                                              |
| generateSafeArgsDebug                    |                                                              |                                                              |
| checkDebugAarMetadata                    |                                                              |                                                              |
| createDebugCompatibleScreenManifests     |                                                              |                                                              |
| extractDeepLinksDebug                    |                                                              |                                                              |
| processDebugMainManifest                 | 处理主Manifest                                               |                                                              |
| **processDebugManifest**                 | 合并AndroidManifest                                          | 把所有aar包里的AndroidManifest.xml中的节点，合并到项目的AndroidManifest.xml中，并根据app/build.gradle中当前buildType的manifestPlaceholders配置内容替换manifest文件中的占位符，最后输出到app/build/intermediates/manifests/full/debug/AndroidManifest.xml |
| processDebugManifestForPackage           |                                                              |                                                              |
| **processDebugResources**                | AAPT2链接阶段，生成R.java和resources.arsc。并合并所有已编译的文件。 | 1.调用aapt生成项目和所有aar依赖的R.java,输出到app/build/generated/source/r/debug目录<br/>2.生成资源索引文件app/build/intermediates/res/resources-debug.ap_<br/>3.把符号表输出到app/build/intermediates/symbols/debug/R.txt |
| kaptGenerateStubsDebugKotlin             |                                                              |                                                              |
| kaptDebugKotlin                          |                                                              |                                                              |
| compileDebugKotlin                       | 编译Kotlin                                                   |                                                              |
| compileDebugJavaWithJavac                | 编译Java                                                     |                                                              |
| compileDebugSources                      |                                                              |                                                              |
| mergeDebugNativeDebugMetadata            |                                                              |                                                              |
| mergeDebugShaders                        |                                                              |                                                              |
| compileDebugShaders                      |                                                              |                                                              |
| generateDebugAssets                      |                                                              |                                                              |
| mergeDebugAssets                         | 合并assets资源                                               |                                                              |
| compressDebugAssets                      | 压缩assets资源                                               |                                                              |
| processDebugJavaRes                      |                                                              |                                                              |
| mergeDebugJavaResource                   |                                                              |                                                              |
| checkDebugDuplicateClasses               |                                                              |                                                              |
| desugarDebugFileDependencies             |                                                              |                                                              |
| mergeExtDexDebug                         |                                                              |                                                              |
| mergeLibDexDebug                         |                                                              |                                                              |
| transformDebugClassesWithAsm             |                                                              |                                                              |
| dexBuilderDebug                          | 将class转换为dex                                             |                                                              |
| mergeProjectDexDebug                     |                                                              |                                                              |
| mergeDebugJniLibFolders                  |                                                              |                                                              |
| mergeDebugNativeLibs                     |                                                              |                                                              |
| stripDebugDebugSymbols                   |                                                              |                                                              |
| validateSigningDebug                     |                                                              |                                                              |
| writeDebugAppMetadata                    |                                                              |                                                              |
| writeDebugSigningConfigVersions          |                                                              |                                                              |
| packageDebug                             | 打包apk并签名                                                |                                                              |
| assembleDebug                            |                                                              |                                                              |

