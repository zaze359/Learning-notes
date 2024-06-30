# Android项目迁移至KMP

了解了KMP + CMP 项目的基本结构后，开始尝试将旧项目迁至新项目中。

## 迁移步骤

* 新建项目
* 拷贝 Jetpack Compose 实现的UI
* 拷贝 使用kotlin 实现的业务代码，其中包含的一些平台特定代码需要调整
* 调整平台特定代码。

## 需要调整的平台特定代码

|            | Android           | KMP  |
| ---------- | ----------------- | ---- |
| Context    |                   |      |
| 网络请求   | OkHttp + Retrofit |      |
| 数据持久化 | Room              |      |



