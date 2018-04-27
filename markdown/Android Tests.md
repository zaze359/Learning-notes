# Anroid 测试用例

Tags ： zazen android

---

[TOC]

---

## 配置

```
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
    androidTestCompile     androidTestImplementation "com.android.support.test:runner:$rootProject.runnerVersion"
    androidTestCompile "com.android.support.test:rules:$rootProject.rulesVersion"
    androidTestImplementation "com.android.support.test.espresso:espresso-core:$rootProject.espressoVersion"
}
```



## 语法

- **@Test**注解
表示一个测试用例方法


