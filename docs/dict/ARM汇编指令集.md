# ARM汇编指令集

| 指令 |                  | 说明                                                         |
| ---- | ---------------- | ------------------------------------------------------------ |
| MOV  |                  | 从一个寄存器或者移位的寄存器或者立即数的值传递到另外一个寄存器。<br />mov只能在寄存器之间移动数据，或者把立即数移动到寄存器 |
| LDR  |                  | 将内存中的值读取到寄存器中(load register)                    |
|      | LDR r0,[r1]      | 将存储器地址为R1的数据读入寄存器r0                           |
|      | LDR r0,[r1],r2   | 将存储器地址为r1的数据读入寄存器r0，并将r1+r2的值存入r1      |
|      | LDR r0，[r1，#8] | 将存储器地址为r1+8的数据读入寄存器r0                         |
| STR  |                  | 将寄存器内容存入内存空间中(store register)                   |
|      | str r0, [r1]     | 寄存器间接寻址。把r0中的数写入到r1中的数为地址的内存中去     |
| B    |                  | 简单的程序跳转，跳转到到目标标号                             |
| BL   |                  | 带链接程序跳转，也就是要带返回地址                           |

## 学习资料

[Writing ARM Assembly (Part 1) | Azeria Labs (azeria-labs.com)](https://azeria-labs.com/writing-arm-assembly-part-1/)

[VisUAL - A highly visual ARM emulator (salmanarif.bitbucket.io)](https://salmanarif.bitbucket.io/visual/index.html)
