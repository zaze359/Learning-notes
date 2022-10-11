# Dex文件

* Android中的 dalvik 和 art 虚拟机运行的都是`.dex`文件。
* dex文件内容和class文件内容相同，结构不同。
  * class流式结构。
  * dex分区结构（对class进行了去重处理）。
* 一个dex包含多个class文件

| 分区         |      |      |
| ------------ | ---- | ---- |
| Dex Header区 |      |      |
| 索引区       |      |      |
|              |      |      |

