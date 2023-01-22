# Android程序分析

## 编写一个Android程序

## 破解Android程序

### 1. 反编译APK

### 2. 分析APK文件

反编译后 会在当前的 outdir 下生成一系列目录和文件。

| 文件  |                  |      |
| ----- | ---------------- | ---- |
| smail | 所有的反汇编代码 |      |
| res   | 所有的资源文件   |      |
|       |                  |      |

* 一般可以从 界面的文案、信息提示等方面着手，确认一段文本。

* 从 `res/values/strings.xml` 中搜索对应文本，找到定义的 `name`。
* 从 `res/values/public.xml` 中查到`name` 对应的 `id`。