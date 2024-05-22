# React学习笔记

## 项目搭建

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

## JSX语法

JSX (JavaScript XML) ，旨在 JS代码中加入 类XML的语法扩展，本质还是 JS，它是语法糖。 JSX源码最终会通过工具编译成由若干 ``React.createElement()``函数组成的 JS 代码，然后就能在浏览器中正常执行。

> props 就是 组件的标签信息，它是 key-value 格式。

```jsx
React.createElement(type)
React.createElement(type, props)
React.createElement(type, props, ...children)

<Component className="card-title">{title}</div>
// type: div
// props-key: className
// props-value: card-title
// children: {title}

// 组件名： 大驼峰
// 其中声明是 ({}) 是解构写法，将props解构，参数和标签名对应即可
// = ，表示默认值
// 访问 prop 用 {}
const Component = ({ className, size = 100 }) => {
  return (
    <ul>
      <li>{className}</li>
    </ul>
  );
};
```

### 命名规范

|           |                                      |           |
| --------- | ------------------------------------ | --------- |
| 组件      | 大驼峰                               | MyApp     |
| props属性 | 小驼峰，注意是区分大小写的。aA != aa | className |
|           |                                      |           |

### 子元素类型

| 类型                          |                                                |      |
| ----------------------------- | ---------------------------------------------- | ---- |
| 字符串                        | 最终会被渲染成 HTML 标签里的字符串             |      |
| 另一段 JSX                    | 会嵌套渲染                                     |      |
| JS 表达式                     | 会在渲染过程中执行，并让返回值参与到渲染过程中 |      |
| 布尔值、null 值、undefined 值 | 不会被渲染出来                                 |      |
| 以上各种类型组成的数组        |                                                |      |

### 支持混写 JS 表达式：{}

使用 `{}` 可以直接混写 JS表达式，注释也需要使用它包裹。 

> class属性 这里使用 className表示，主要是由于 class 是 JS中的保留字。

```jsx
{/* 作为props-value: handleAdd */}
<h2>待处理<button onClick={handleAdd} disabled={showAdd}>&#8853; 添加新任务</button></h2>

{/* 作为子元素: title */}
<div className="card-title">{title}</div>
{/* js表达式*/}
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

### 注意事项

返回JSX 时添加 ``()`` 可以防止由于 JS自动添加分号导致出现问题：

```jsx
function App() {
  return ( ..... );
}

function App() {
  // 这里发生换行，JS编译器会自动在 return后添加; 导致函数短路，后续代码不执行。
  return 
   ....
}
```



## 函数组件

以 函数的方式表示一个 组件，返回 JSX。

### 函数组件的创建方式

```jsx
// 定义组件, 组件名使用大驼峰
// children 就是组件便签内部的子元素，它是隐式传递
const KanbanColumn = ({ children, className, title }) => {
  const combinedClassName = `kanban-column ${className}`;
  return (<section className={combinedClassName}>
    <h2>${title}</h2>
    <ul>
      {children}
    </ul>
  </section>);
}
```

### 组件的使用

```jsx
<KanbanColumn className="column-todo" title={
    // 此处传递一串 jsx, 需要使用 fragments <></> 进行包裹
    <>
      待处理<button onClick={handleAdd} disabled={showAdd}>&#8853; 添加新任务</button>
    </>
  }>
    {/* ... 语法，将props这个对象的所有属性传给KanbanCard组件 */}
    {
      todoList.map(props => <KanbanCard {...props} />)
    }
  </KanbanColumn>
```

### 受控组件

受控组件是指以 React state 为单一事实来源（Single Source of Truth），并用 React 合成事件处理用户交互的组件。

```jsx
const KanbanNewCard = ({ onSubmit }) => {
  const [title, setTitle] = useState('');
  const handleChange = (evt) => {
    setTitle(evt.target.value);
  };

  return (
    <li>
      <h3>添加新卡片</h3>
      <div>
        <input type="text" value={title} onChange={handleChange} />
      </div>
    </li>
  );
};
```



## React 的渲染机制

React在运行时会先将声明的组件渲染成虚拟DOM，接着React 框架会再将虚拟DOM渲染成真正的DOM

### 虚拟DOM

虚拟 DOM（Virtual DOM） 是相对于 HTML DOM 更轻量的JS模型。

它的轻量来源于 通过算法过滤掉了大量没有必要的真实 DOM API调用。

### 协调（Reconciliation）

每次有 props、state 、context等数据变动时，组件会渲染出新的元素树，React 框架会与之前的树做 Diffing 对比，将元素的变动最终体现在浏览器页面的 DOM 中。



## Hooks

[Hook API 索引 – React (reactjs.org)](https://zh-hans.legacy.reactjs.org/docs/hooks-reference.html)

Hooks 是一套为函数组件设计的，用于访问 React 内部状态(state、context等)或执行副作用操作，以函数形式存在的 React API。目前官方 推荐 使用 函数组件 + Hooks，这个组合优于 类组件。

**函数组件的 Hooks 是以 单向链表的方式保存在 FiberNode中的，它们是按照顺序来获取上一次的状态的**。

因此 使用 Hooks 的存在以下几个限制：

* **只能在 React 的函数组件中调用 Hooks：** 不在React 内使用，就无法保存到链表中。
* **只能在组件函数的最顶层调用 Hooks：**不能在循环、条件分支中或者任何 return 语句之后调用 Hooks，因为可能会导致 Hooks 无法和链表中的Hooks 对应。

### useState

State 是绑定在渲染产生的虚拟DOM上，即FiberNode上。对于函数组件来说是外部状态。

useState 是用于操作 state 的 hook，useState 返回的是数组，其中  `[]` 解构语法，来获取数组内容。

```jsx
import React, { useState } from 'react';
const Component = ({a, b}) => {
  // 定义了名为 title 的 state
  // 只读变量 title；修改函数 setTitle；默认值为 a
	const [title, setTitle] = useState(a); 
  return (
    <ul>
      <li>{title}</li>
    </ul>
  );
}
```

### useReducer



### useEffect

第一个参数是副作用回调函数：只在组件挂载的提交阶段执行，类似 `componentDidMount` 生命周期函数。这里可以 return 一个清除函数，在组件重新提交前 或者 组件销毁前会被调用，类似 `componentWillUnmount` 生命周期函数，可以用来释放资源。

第二个参数 依赖值数组：React 渲染组件时会记录下这个依赖值，并与上一次的值做比较，**仅当依赖值数组发生变化时才会在提交阶段执行副作用回调函数**。相等于 key，设置为`[]` 空数组时这个useEffect 就仅会执行一次。而当这个参数不传时就每次都会执行。

```jsx
// 第一个参数: {} 表示 回调函数
// 第二个参数: [] 表示 依赖值数组
useEffect(() => {/* ... */}, [var1, var2]);

useEffect(() => {/* ... */ return () => { /* 这里是清除函数的内容 */ } }, [var1, var2]);
```

> useLayoutEffect 和 useEffect功能类似，区别在于 useLayoutEffect 更早被调用，且是在 真实 DOM 变更之后同步执行的，而useEffect则是异步执行的。

### useContext



### useRef

可变值：内部存在一个 可读写的 current属性，current 改变不会触发组件的重新渲染。

```jsx
const Component = () => {
  // ref对象: myRef
  // myRef.current的默认值 为 null
  const myRef = useRef(null);
  // 读取可变值
  const value = myRef.current;
  // 更新可变值
  myRef.current = newValue;
  return (<div></div>);
};
```



### 其他Hooks

* useRef
* useMemo 和 useCallback：用于优化性能，减少不必要的渲染。
* useReducer：处理复杂state。

#### useMemo 和 useCallback

它们用于优化性能，减少不必要的渲染。

useMemo 在渲染阶段执行，useCallback 在提交阶段执行。它也是仅当 依赖值数组变化时 才会重新执行，只不过函数的执行结果会被缓存，并且能够直接获取到。

```jsx
const [num, setNum] = useState('0');
const sum = useMemo(() => {
  const n = parseInt(num, 10);
  return fibonacci(n);
}, [num]);
```

useCallback 则是直接返回 传入的回调函数，避免回调函数重复创建。

```jsx
// 返回值是 第一个参数 回调函数。
const callbackFun = useCallback(() => {/* ... */}, [a, b]);
```



## 合成事件

标准的 DOM API 中，提供了完整的 DOM 事件体系，利用 DOM 事件（例如冒泡和捕获），可以实现很多复杂交互。

React 内部则建立一套 **合成事件（SyntheticEvent）**的事件系统。合成事件 底层还是基于 DOM事件的，**通过封装提供了一套统一规范的接口，屏蔽了DOM的复杂性和跨浏览器的不一致性**。

### 合成事件和原生DOM事件的区别

HTML中的原生的DOM事件：

```html
<button onclick="handleClick()">按钮</button>
<input type="text" onkeydown="handleKeyDown(event)" />
```

JS中的DOM事件：

```js
// 给事件属性赋值
document.getElementById('btn').onclick = handleClick;
// 设置监听，需要手动 removeEventListener 防止内存泄漏
document.getElementById('btn').addEventListener('click', handleClick);
// 第三个参数true，表示 以捕获到方式监听事件
div.addEventListener('click', handleClick, true);
```

React JSX中的合成事件：属性以小驼峰规范命名

> evt 就是合成事件，它一定会作为第一个参数传递进来，不一定需要在调用处显示传递。

```jsx
const Component = () => {
  const handleClick = (evt) => {
    /* evt 就是合成事件，它一定会作为第一个参数传递进来，不一定需要在调用处显示传递 */
  };
  // 当然也是可以忽略不管的
  // const handleClick = () => {/*  */};
  
  const handleKeyDown = evt => {
    /* ... */
  };
  
  return (
    <>
      <button onClick={handleClick}>按钮</button>
      <input type="text" onKeyDown={evt => handleKeyDown(evt)} />
    </>
  );
};

// 若需要以捕获到方式监听事件，添加 Capture 即可，默认不加是冒泡
() => (<div onClickCapture={handleClick}>...</div>);
```

### React 的事件代理模式

React 在事件处理上 使用了事件代理模式，React上的 root 根元素 会监听所有自己支持的原生DOM事件，当事件触发时再根据事件类型和目标元素 找到对应的FiberNode 和 事件处理函数，接着创建相应的合成事件并调用事件处理函数。

所以 合成事件的 `evt.nativeEvent.currentTarget` 会执行 root 元素，当然其他的target 则是 指向真实的元素。





## MVI单向数据流





## 其他

### 类组件

### 访问浏览器本地存储：LocalStorage

```jsx
const data = window.localStorage.getItem(DATA_KEY);
```



### CSS-in-JS

在JS中写CSS，主要用于 组件间样式的隔离。

#### Emotion框架

[Emotion – Introduction](https://emotion.sh/docs/introduction)

安装:

```shell
npm i @emotion/react
```

使用:

```jsx
import { css } from '@emotion/react'

const color = 'white'

// 单独定义，只要将内容包裹在 css`` 中即可。
const styles = css`
    padding: 32px;
    background-color: hotpink;
    font-size: 24px;
    border-radius: 4px;
    &:hover {
      color: ${color};
    }
`;

render(
  <div
    css={css`
      padding: 32px;
      background-color: hotpink;
      font-size: 24px;
      border-radius: 4px;
      &:hover {
        color: ${color};
      }
    `}
  >
    Hover to change color.
  </div>
)
```

#### Styled-components

#### CSS Modules

#### StyleX