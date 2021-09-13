---
Anroid 测试用例
---

# Anroid 测试用例

Tags ： zaze android

---

[TOC]

---

## 配置

```groovy
android {
    ....
    defaultConfig {
            ....
            testInstrumentationRunner "android.support.test.runner.AndroidJUnitRunner"
    }
    ....
}

dependencies {
    ...
    testCompile 'junit:junit:4.12'
    androidTestImplementation "com.android.support.test:runner:$rootProject.runnerVersion"
    androidTestCompile "com.android.support.test:rules:$rootProject.rulesVersion"
    androidTestImplementation "com.android.support.test.espresso:espresso-core:$rootProject.espressoVersion"
}
```



## 语法

- **@Test**注解
表示一个测试用例方法

## jar

```bash
    # 仍然在\Android-sdk\tools\目录下，运行命令：
    android create uitest-project -n <name> -t <android-sdk-ID> -p <path>
    # 比如：
    android create uitest-project -n AutoRunner -t 6 -p e:\workspace\AutoRunner
    # 上面的name就是将来生成的jar包的名字，可以自己定义，android-sdk-ID就是上面看到的6；path是Eclipse新建的工程的路径；运行命令后，将会在工程的根目录下生成build.xml文件。如果没生成，检查上面的步骤。
```

## 编译生成jar

```
    CMD进入项目的工程目录，然后运行ant build，将使用ant编译生成jar，成功将会提示：
    然后会在bin目录下生成jar文件。
```

## push并运行jar

```bash
    adb push <jar文件路径> data/local/tmp
    adb shell uiautomator runtest <jar文件名> -c <工程中的类名，包含包名>
    # 比如：
    adb push e:\workspace\AutoRunner\bin\AutoRunner.jar data/local/tmp
    adb shell uiautomator runtest AutoRunner.jar -c com.Runner
```
