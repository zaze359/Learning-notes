---

---
# VS Code

## 插件安装

### Markdown

Office Viewer

## Spring Boot

### 初始化

- DevTools（代码修改热更新，无需重启）

- [X] Web（集成tomcat、SpringMVC） @2020-11-03 10:07:00

- Lombok（智能生成setter、getter、toString等接口，无需手动生成，代码更简介）
- Thymeleaf （模板引擎）。
  YAML

### Vue

```
// 安装webpack
npm install -g webpack 
// 
npm init
//
npm i webpack vue vue-loader

// npm audit fix无法修复问题
// 使用淘宝镜像源修复
npm i -g nrm
nrm use taobao
```

## 问题处理记录

### 控制台乱码

终端中输入 ``chcp``查看当前编码格式。

| 编码格式 | 代码  |
| -------- | ----- |
| GBK      | 936   |
| UTF-8    | 65001 |
| GB2312   | 20936 |

修改编码

```shell
# chcp + 代码
chcp 65001
```
