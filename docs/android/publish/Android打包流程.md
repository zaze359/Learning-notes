#  Android 打包流程



## 分析项目打包做了什么

### 执行一次gradle编译

```bash
./gradlew app:assembleDebug --console=plain >> ~/Downloads/build.txt 2>&1
```

```bash
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

| Task                                     | 说明             |      |
| ---------------------------------------- | ---------------- | ---- |
| preBuild                                 |                  |      |
| preDebugBuild                            |                  |      |
| compileDebugAidl                         | 编译aidl         |      |
| compileDebugRenderscript                 | 编译Renderscript |      |
| dataBindingMergeDependencyArtifactsDebug |                  |      |
| dataBindingMergeGenClassesDebug          |                  |      |
| generateDebugResValues                   |                  |      |
| generateDebugResources                   |                  |      |
| mergeDebugResources                      |                  |      |
| dataBindingGenBaseClassesDebug           |                  |      |
| dataBindingTriggerDebug                  |                  |      |
| generateDebugBuildConfig                 |                  |      |
| writeDebugApplicationId                  |                  |      |
| generateSafeArgsDebug                    |                  |      |
| checkDebugAarMetadata                    |                  |      |
| createDebugCompatibleScreenManifests     |                  |      |
| extractDeepLinksDebug                    |                  |      |
| processDebugMainManifest                 |                  |      |
| processDebugManifest                     |                  |      |
| processDebugManifestForPackage           |                  |      |
| processDebugResources                    |                  |      |
| kaptGenerateStubsDebugKotlin             |                  |      |
| kaptDebugKotlin                          |                  |      |
| compileDebugKotlin                       |                  |      |
| compileDebugJavaWithJavac                |                  |      |
| compileDebugSources                      |                  |      |
| mergeDebugNativeDebugMetadata            |                  |      |
| mergeDebugShaders                        |                  |      |
| compileDebugShaders                      |                  |      |
| generateDebugAssets                      |                  |      |
| mergeDebugAssets                         |                  |      |
| compressDebugAssets                      |                  |      |
| processDebugJavaRes                      |                  |      |
| mergeDebugJavaResource                   |                  |      |
| checkDebugDuplicateClasses               |                  |      |
| desugarDebugFileDependencies             |                  |      |
| mergeExtDexDebug                         |                  |      |
| mergeLibDexDebug                         |                  |      |
| transformDebugClassesWithAsm             |                  |      |
| dexBuilderDebug                          |                  |      |
| mergeProjectDexDebug                     |                  |      |
| mergeDebugJniLibFolders                  |                  |      |
| mergeDebugNativeLibs                     |                  |      |
| stripDebugDebugSymbols                   |                  |      |
| validateSigningDebug                     |                  |      |
| writeDebugAppMetadata                    |                  |      |
| writeDebugSigningConfigVersions          |                  |      |
| packageDebug                             |                  |      |
| assembleDebug                            |                  |      |

