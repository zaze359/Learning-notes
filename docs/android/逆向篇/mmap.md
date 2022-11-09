# mmap

[Michael Kerrisk - man7.org](https://man7.org/)

[mmap(2) - Linux manual page (man7.org)](https://man7.org/linux/man-pages/man2/mmap.2.html)

```c++
/**
 * addr		：映射到哪个地址。
 * size		：映射大小，不是实际大小。mmap会做一个页边界对齐的上取整，补0。
 * prot		：属性
 *				PROT_READ 可读
 *				PROT_WRITE 可写
 *				PROT_EXEC 可执行
 * flags	：
 *				MAP_PRIVATE私有不共享
 *				MAP_SHARED共享
 *				MAP_FIXED传入的地址无法分配时直接失败,所以此时传入的addr一定是4k页对齐的地址。
 *			
 * fd		：
 * offset	：
 *
 * @return 返回的地址一定是页边界对齐的
 **/
void* mmap(void* addr, size_t size, int prot, int flags, int fd, off_t offset) {
  return mmap64(addr, size, prot, flags, fd, static_cast<off64_t>(offset));
}
```

> Linux一页大小默认为4KB = 4096B = 0x1000 >> 0x0000 ~ 0x0fff
>
> 

## addr

映射到哪个地址。

实际映射的地址不一定是传入的地址，返回值才是真正的地址。

## size

需要映射大小。

实际映射的大小不一定等于传入的大小，实际的大小mmap会做一个页边界对齐的上取整，多余部分补0。

## port

* PROT_READ 可读

 *				PROT_WRITE 可写
 *				PROT_EXEC 可执行

## flags

 * MAP_PRIVATE私有不共享
 * MAP_SHARED共享
 * MAP_FIXED传入的地址无法分配时直接失败,所以此时传入的addr一定是4k页对齐的地址。
