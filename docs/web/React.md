# React

## 基础

### 项目搭建

首先需要配置node js 环境。

然后 创建 workspaces 工作目录，并通过 CRA命令 创建 `my-react` 项目：

```shell
mkdir /Users/zhaozhen/Documents/workspaces
cd /Users/zhaozhen/Documents/workspaces
# CRA 命令创建 React 项目框架
npx create-react-app my-react
```

创建成功后启动项目：

```shell
cd my-react
npm start
```



---

#### {}

在html中，使用 `{}` 可以直接混写 JS表达式

```html
<ul>
  {
    new Array(10).fill('').map(item => (
      <li className='card'>
        <div className='card-title'>this is title</div>
        <div className='card-status'>this is status</div>
      </li>
    ))
  }
</ul>
```



### JSX语法

### React组件

### 虚拟DOM

### MVI单向数据流



## 函数组件

## Hooks

## 其他

### 类组件