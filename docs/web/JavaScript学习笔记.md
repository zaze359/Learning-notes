# JavaScript 学习笔记

## 语法

### 数据类型

* `Undefined` 类型 表示未定义，任何变量在赋值前都是`Undefined` ，且这个类型只有一个值。建议用 `void 0` 来获取，而不是直接使用 `undefined` 这个变量。不过一般也不会特意去赋值为 `undefined`
* `Null` 表示定义了，但是是空。

### 字符串

* 字符串由 `''` 或`""`包裹。

* `\`：转义字符。
* `\u####`：表示一个Unicode字符

### 变量定义

```javascript
var x = 1;
```

### 数组

数组中可以包含任意数据类型。

```javascript
// 定义
var arr = [1, 2, 3.14, 'Hello', null, true];
// 访问
arr[1] = 99;
```

### 条件判断

```javascript
var age = 3;
if (age >= 18) {
    alert('adult');
} else if (age >= 6) {
    alert('teenager');
} else {
    alert('kid');
}
```

### 循环

> for

```javascript
var i;
for (i=1; i<=10000; i++) {
    console.log(i);
}

// for .. in
for (var key in o) {
    console.log(key);
}
```

> while

```javascript
var n = 99;
while (n > 0) {
    n = n - 2;
    console.log(n);
}

// do .. while
var n = 0;
do {
    n = n + 1;
} while (n < 100);
```

### 日志输出

#### Console

```javascript
console.log("123123");
```

### 函数

> 函数体内可以使用 `arguments` 数组来获取所有参数。
>
> 函数可以赋值给变量。

* `function` ：定义函数。
* `abc`：函数名。
* `(x, y)`：声名两个参数，x和y。传入的参数可以比定义的多也可以少，多出的参数不会被用到，少的参数为`undefined`。
* `{ ... }` ：函数体。
* `return`：返回值。没有时返回 `undefined`。
* `...rest`：任意多的参数。（java object...）

```javascript
function abc(x, y) {
    // ...
    return x + y;
}

// 作为变量。
var abcd = function (x, y, ...rest) {
    // ...
    return x + y;
};

// 函数调用
abc(1, 2);
abcd(1, 2);
```

