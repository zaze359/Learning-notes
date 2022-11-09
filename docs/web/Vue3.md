# Vue3

```shell
// 安装webpack
npm install -g webpack 
// 
npm init
//
npm i webpack vue vue-loader

```

## 项目环境搭建

[安装Node.js](./NodeJs.md)

使用Vite创建项目：

```shell
npm init vite
```

安装项目依赖：

```shell
npm install
```

运行项目：

```shell
npm run dev
```

其他配置：

```shell
# 路由
npm install vue-router@next vuex@next
```

项目结构参考：

```
├── src
│   ├── api            数据请求
│   ├── assets         静态资源
│   ├── components     组件
│   ├── pages          页面
│   ├── router         路由配置
│   ├── store          vuex数据
│   └── utils          工具函数
```

> 浏览器安装`vue-devtools`插件可以查看vue的组件层级