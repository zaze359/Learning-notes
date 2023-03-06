# 搭建本地HTTP实验环境

* 操作系统：Windows 11

* 网络抓包工具：Wireshark

  [Wireshark · Go Deep.](https://www.wireshark.org/)

* 浏览器：Chrome

* 虚拟终端：Telnet（win自带需启用）

  Windows中直接搜索 `Telnet` 即可。

  ![image-20230123202106825](./HTTP%E6%9C%AC%E5%9C%B0%E5%AE%9E%E9%AA%8C%E7%8E%AF%E5%A2%83.assets/image-20230123202106825.png)

  

* 网关：OpenResty

  [OpenResty® - Open source](http://openresty.org/en/)



## Wireshark

### 1. 选择loopback 抓取本地数据包。

![image-20230123212816151](./HTTP%E6%9C%AC%E5%9C%B0%E5%AE%9E%E9%AA%8C%E7%8E%AF%E5%A2%83.assets/image-20230123212816151.png)

### 2. 选择合适的过滤器

> Http：tcp.port == 80 || udp.port == 80

### ![image-20230123212913760](./HTTP%E6%9C%AC%E5%9C%B0%E5%AE%9E%E9%AA%8C%E7%8E%AF%E5%A2%83.assets/image-20230123212913760.png)

> Https：tcp.port == 443

### 3. 执行请求获取数据包

![image-20230123213037720](./HTTP%E6%9C%AC%E5%9C%B0%E5%AE%9E%E9%AA%8C%E7%8E%AF%E5%A2%83.assets/image-20230123213037720.png)



## 数据包分析

### 使用TCP建立连接

客户端通过 IP地址 和 服务端建立TCP 连接（若是域名会先进行NDS解析）。最开始的 三个数据包 对应 TCP的 `三次握手` 。

* SYN：客户端发送 SYN(seq=0) 到服务端。客户端进入 SYN_SEND状态。
* SYN/ACK：服务端接收客户端的 SYN(seq=0)后，对seq进行校验，然后发出应答 ACK 和SYN ，即 SYN(seq=0)+ACK(ack=1)。服务端进入 SYN_RECV 状态。
* ACK：客户端接收到服务端的 SYN(seq=0)+ACK(ack=1) 后，对seq进行校验, 并发出应答 ACK(ack=seq+1)。

![image-20230124171405330](./HTTP%E6%9C%AC%E5%9C%B0%E5%AE%9E%E9%AA%8C%E7%8E%AF%E5%A2%83.assets/image-20230124171405330.png)

### 客户端发送HTTP报文

建立了 TCP 连接后，客户端和服务端将使用 TCP协议进行通信。使用浏览器访问站点即可

1. 客户端按照 HTTP协议，使用 TCP发送了一条 HTTP 请求报文。
2. 服务端在 TCP协议层上，会回复一个 ACK，表示收到了请求报文，不过对于 HTTP 它是不可见的。
3. 服务端在HTTP层面上，根据 HTTP 协议对请求报文进行解析，处理对于的逻辑，并将结果封装成 HTTP报文格式。并将 响应报文 通过 TCP 返回给 客户端。
4. 客户端在 TCP 协议层同样会回复一个 ACK给服务端，表示收到了响应报文。
5. 客户端解析 响应报文，处理对于数据。

![image-20230124180626511](./HTTP%E6%9C%AC%E5%9C%B0%E5%AE%9E%E9%AA%8C%E7%8E%AF%E5%A2%83.assets/image-20230124180626511.png)

### HTTPS 报文明文配置

* 新建 `sslkey.log`文件。

* Windows环境变量中添加 系统变量 `SSLKEYLOGFILE`。

  值为 `sslkey.log` 的路径。

  ![image-20230212161526308](./HTTP%E6%9C%AC%E5%9C%B0%E5%AE%9E%E9%AA%8C%E7%8E%AF%E5%A2%83.assets/image-20230212161526308.png)

* 在WireShark的 `首选项 -> Protocols -> TLS` 添加 (Pre)-Master-Secret log filename。选择 `sslkey.log` 。

  ![image-20230212161255424](./HTTP%E6%9C%AC%E5%9C%B0%E5%AE%9E%E9%AA%8C%E7%8E%AF%E5%A2%83.assets/image-20230212161255424.png)

* 重启电脑。



## Telnet发送报文

1. `Win + R` 输入 `telnet` 运行。

2. 建立连接。

   ```shell
   # 连接
   open ip port
   ```

3. `CTRL + ]` 进入报文编辑模式

4. 编写报文

   ```http
   GET /16-1 HTTP/1.1
   Host: www.chrono.com

