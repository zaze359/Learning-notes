# NativeHook

Native Hook比较常用的技术有`GOT/PLT Hook`、`Trap Hook`以及`Inline Hook`。

## GOT/PLT Hook

> 外部函数调用的Hook
>
> Facebook的Profilo使用

关于`GOT/PLT Hook`，首先需要了解一下[ELF文件](/docs/linux/ELF文件.md)。他们分别对应ELF中的`GOT表`和`PLT表`。

`GOT Hook`技术就是修改GOT记录，`PLT Hook`就是修改PLT记录。不过GOT/PLT表示他们都是用于访问外部函数的，所以无法对内部函数进行Hook，关于内部函数的Hook，主要就是`Trap Hook`或`Inline Hook`。

## Trap Hook

## Inline Hook

