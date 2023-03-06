# Http协议

HTTP 利用 TCP/IP 协议栈逐层打包再拆包。

>  默认端口：80

* 灵活可扩展。
* 可靠传输，TCP保证。
* 明文传输。
* 不安全：缺乏机密性、身份认证还有完整性校验
* 请求-应答模式。
* 应用层协议。



## 域名系统（Domain Name System）

### 1. 域名的格式

> 级别从左到右逐级升高，层级从右到左依次递减，域名以`.`分割；
>
> 最左边为`主机名`, 例如`www：万维网服务`、`mail：邮件服务`等；

【主机名】.【...】.【二级域名】.【顶级域名】

```tex
// 主机名：www
// 二级域名：baidu
// 顶级域名：com
www.baidu.com
```

> 每个域名都是独一无二。
>
> Java的包机制使用的是域名的反序。

### 2. 域名解析

> DNS协议：使用UDP发送

域名最终会被`DNS服务器`转成IP地址，这个过程就是`域名解析`。

域名解析的顺序：**从右到左**。

* **根域名服务器（Root DNS Server）**

  管理顶级域名服务器，返回顶级域名服务器（com、cn）的IP地址。

* **顶级域名服务器（Top-level DNS Server）**

  管理各自域名下的权威域名服务器，`com顶级域名服务器`可以返回`baidu.com`域名服务器的IP地址。

* **权威域名服务器（Authoritative DNS Server）**

  管理自己域名下主机的 IP 地址，`baidu.com权威域名服务器`可以返回`www.baidu.com`的IP地址。

---

## URI/URL

### URI：统一资源标识符

URI（Uniform Resource Identifier），唯一的**标记**互联网上的资源。

格式：

```http
scheme://host:port/path?quary#fragment
```

```http
http://a.b.com/cn/readme.html
```

* **协议名（scheme）**：即访问该资源应当使用的协议，在这里是`http`。
* **主机名（host:port）**：即互联网上主机的标记，可以是域名或 IP 地址，在这里是`a.b.com`；
* **路径（path）**：即资源在主机上的位置，使用`/`分隔多级目录，在这里是`/cn/readme.html`。
* **参数（query）**：对资源的额外要求。以`?`开始，参数为 `key-value`格式的字符串，多个参数间通过`&`进行连接。
* **锚点（#fragment）**：仅在客户端中使用。用于在获取到资源后进行跳转。

### URL：统一资源定位符

URL（Uniform Resource Locator）即网址，它是URI的子集。



## Http报文

> HTTP/1的报文时文本格式，是ACSII码。

* **起始行（start line）**：描述请求或响应的基本信息。
* **头部字段集合（header）**：key-value 格式的信息，用于描述报文。HTTP/1中不区分大小写，HTTP/2中限制只能小写。。
* **空行(`CRLF`、`0D0A`)**：必须存在，且在header 之后。空行之后可以存在正文。用于区分头和正文。
* **消息正文（entity/body）**：传输的数据。文本或图片、视频等二进制。

> Header：起始行 + header + 空行。必须有。
>
> Body：消息在正文。可以没有

![image-20230124214549844](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230124214549844.png)

![image-20230124220123230](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230124220123230.png)



### 起始行（start line）

> 请求行（request line）：请求报文的起始行。
>

```http
GET / HTTP/1.1\r\n
```

* **请求方法**：表示对资源的操作。如 `GET`。
* **请求目标**：通常是一个 URI，标记了请求方法要操作的资源。如 `/`
* **版本号**：表示报文使用的 HTTP 协议版本。如 `HTTP/1.1` 。
* **CRLF空行**：表示结尾。

![img](./HTTP%E5%8D%8F%E8%AE%AE.assets/36108959084392065f36dff3e12967b9.png)

> 状态行（status line）：响应报文的起始行。

```http
HTTP/1.1 200 OK\r\n
```

* **版本号**： HTTP 协议版本；如`HTTP/1.1`
* **状态码**：三位数，表示处理的结果，比如 `200`是成功；
* **原因**：作为状态码补充，是更详细的解释文字，帮助人理解原因。如 `OK`。
* **CRLF空行**：表示结尾。

![img](./HTTP%E5%8D%8F%E8%AE%AE.assets/a1477b903cd4d5a69686683c0dbc3300.png)

### 头部字段

头字段允许自定义扩展。

> 格式：key: value + CRLF

```http

Host: 127.0.0.1\r\n
```

注意点：

* key 不区分大小写。
* key 不能 出现 空格 和下划线`_`。使用 `-`连接。
* key后接`:`。；两者间不能存在空格。

头字段大致分为四大类：

- 通用字段：在请求头和响应头中都能使用。
- 请求字段：仅能用于请求头
- 响应字段：仅能用于响应头
- 实体字段：专用于描述body，属于通用字段

| 字段           | 类型     |                                     |
| -------------- | -------- | ----------------------------------- |
| Host           | 请求字段 | 指定由哪个主机处理。                |
| Use-Agent      | 请求字段 | 表示请求的客户端是谁。              |
| Content-type   | 实体字段 | body的类型。                        |
| Content-Length | 实体字段 | body的长度                          |
| Date           | 通用字段 | 表示HTTP报文创建时间。              |
| Server         | 响应字段 | 表示当前响应的服务信息。`名称/版本` |
| Location       | 响应字段 | 重定向时指明跳转的URI               |
| Set-Cookie     | 响应字段 | 服务端添加Cookie                    |
| Cookie         | 请求字段 | 客户端将Cookie发还给服务端          |



### Body

| 头字段           |                      |                       |
| ---------------- | -------------------- | --------------------- |
| Accept           | 客户端可理解的格式   | `text/html`等         |
| Content-Type     |                      |                       |
| -                |                      |                       |
| Accept-Encoding  | 客户端支持的压缩格式 | `gzip, deflate, br`等 |
| Content-Encoding | 实际使用的压缩格式   |                       |
| -                |                      |                       |
| Accept-Language  | 客户端可理解的语言   | `zh-CN`等             |
| Content-Language | 实际语言类型         |                       |
| -                |                      |                       |
|                  |                      |                       |



#### 数据类型

> MIME（Multipurpose Internet Mail Extensions）
>
> 格式：type/subtype

| 类型        |                                            |                                         |
| ----------- | ------------------------------------------ | --------------------------------------- |
| text        | 文本                                       | `text/html` , `text/css` 等             |
| image       | 图像                                       | `image/gif` , `image/jpeg`等            |
| audio       | 音频                                       | `audio/mpeg`等                          |
| vedio       | 视频                                       | `vedio/mp4`等                           |
| application | 格式不固定（文本、二进制等），由应用处理。 | `application/json`, `application/pdf`等 |

> Accept：客户端可理解的格式。

```http
GET / HTTP/1.1

Accept: text/html,application/xml
```

> Content-Type：实体数据的真正类型。

```http
GET / HTTP/1.1

Content-Type: text/html
```

#### 压缩类型

指定数据的压缩格式，节约带宽。

| Encoding type |                          |
| ------------- | ------------------------ |
| gzip          | GNU zip                  |
| deflate       | zlib（deflate）          |
| br            | 专门为HTTP优化的压缩算法 |
| ...           |                          |

> Accept-Encoding：客户端支持的压缩格式

```http
GET / HTTP/1.1

Accept-Encoding: gzip, deflate, br
```

> Content-Encoding 头字段：实际使用的压缩格式

```http
GET / HTTP/1.1

Content-Encoding: gzip
```

#### 语言类型

协商数据的使用的语言

> Accept-Language：客户端支持的语言
>
> 格式：type-subtype

```http
GET / HTTP/1.1

Accept-Language: zh-CN, zh, en
```

> Content-Language：实际语言类型

```http
GET / HTTP/1.1

Content-Language: zh-CN
```

#### 字符集

协商数据的编码格式

> Accept-Charset：支持的类型

```http
GET / HTTP/1.1

Accept-Charset: gbk, utf-8
```

> Content-Type：charset=utf-8。数据的字符类型

```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
```

#### 内容协商补充

> q：权重，默认为1，最小0.01
>
> html：1
>
> xml：0.8
>
> 其他：0.7

```http
GET / HTTP/1.1

Accept: text/html,application/xml;q=0.8,*/*;q=0.7
```

---

## Http状态码

RFC标准中状态码是三位数（000~999）。同时将状态码分为了5类，主要是为了便于扩展。

* 1xx：提示信息。是一个中间状态，还存在后续。
* 2xx：成功。如 `200 OK`。
* 3xx：重定向。资源位置发生变动，需要重新发起请求。如 `301 Moved Permanently`。
* 4xx：客户端错误。
* 5xx：服务端错误。

| 状态码                         | 说明                                                         |
| ------------------------------ | ------------------------------------------------------------ |
| 200                            | 表示请求成功。                                               |
| 204 No Content                 | 和200基本相同，区别是没有body。                              |
| 206 Partial Content            | 是HTTP 分块下载或断点续传的基础。和200的区别是body中是部分内容。 |
| -                              |                                                              |
| 301 Moved Permanently          | 永久重定向。表示请求的资源已不存在，需要用新的URI访问。      |
| 302 Found（Moved Temporarily） | 临时重定向。请求的资源存在，但是目前需要临时用另一个URI访问。比如维护升级时。 |
| 304 Not Modified               | 缓存重定向。表示资源未修改，用于缓存控制。也不需要跳转。     |
| -                              |                                                              |
| 400 Bad Request                | 请求的报文存在错误。                                         |
| 403 Forbidden                  | 服务器禁止访问资源。                                         |
| 404 Not Found                  | 资源未找到。                                                 |
| 405 Method Not Allowed         | 不允许使用某些操作。比如支持 POST。                          |
| -                              |                                                              |
| 500 Internal Server Error      | 服务端内部发生了某些错误。                                   |
| 501 Not Implemented            | 当前功能暂未支持。                                           |
| 502 Bad Gateway                | 一般是网关返回的错误。表示服务器自身正常，但是访问后端服务器时发生了错误。 |
| 503 Service Unavailable        | 服务器较忙，暂时无法响应。                                   |

## Http传输

### 数据压缩：Content-Encoding

> 利用`Accept-Encoding`, `Content-Encoding` 字段，指定压缩算法。

比较**适合文本数据**，对于音视频这类本身高度压缩的格式并不适用。

### 分块传输：chunked

> `Transfer-Encoding: chunked`
>
> 和 `Content-Length` 互斥。

化整为零，将数据分块逐个发送，可以防止网络被大文件占据，可以节省带宽、内存等资源。浏览器会自动组装数据

```http
HTTP/1.1 200 OK

length1 + CRLF
data1 + CRLF
length2 + CRLF
data2 + CRLF
0 + CRLF
CRLF
```

```shell
HTTP/1.1 200 OK

e
chunked data 1
e
chunked data 2
e
chunked data 3
0
# 此处是 空数据 + CRLF
```

### 范围请求：Range

获取文件的一段或多段数据。使用场景有视频的拖拽、断点续传、多段下载等。服务端返回 `206 Partial Content`

> Range：客户端范围请求
>
> 格式：`bytes=x-y`。x, y 为偏移量，从0开始。

```http
GET / HTTP/1.1

Range: bytes=0-99
```

* `0-`：整个文件，从开始到结尾。
* `10-`：从第10个字节到末尾。
* `-1`：表示最后1个字节。
* `-10`：获取末尾后10个字节。

> Accept-Ranges：服务端告知客户端支持范围请求
>
> 不支持时用 none，或者不发送
>
> 可以通过HEAD请求来验证并且获取文件大小。

```http
HTTP/1.1 206 Partial Content

Accept-Ranges: bytes
```

> Content-Range：服务端返回的数据范围
>
> 格式：`bytes x-y/length`。实际范围数据和资源总大小。

```http
HTTP/1.1 206 Partial Content

Content-Range: bytes 0-99/120
```

> 多段请求：``bytes=x1-y1, x2-y2``

```http
GET / HTTP/1.1

Range: bytes=0-9, 10-15
```

> 服务端返回格式：
>
> multipart/byterange：表示返回的是多段数据。
>
> boundary：指定多段数据间的分割符。
>
> `--boundary` 开始并分割多段，``--boundary--``表示结束

```http
HTTP/1.1 206 Partial Content

Content-Type: multipart/byteranges; boundary=11111
Accept-Ranges: bytes

--11111
Content-Type: text/plain
Content-Range: bytes 0-9/99

0123456789
--11111
Content-Type: text/plain
Content-Range: bytes 10-15/99

012345
--11111--
```

---

## Http连接管理

Http底层的数据传输基于TCP/IP，所以连接时存在TCP的三次握手，断开时有四次挥手流程。

### 短链接（0.9/1.0）

**在Http 1.0 之前为短链接**，每次请求都会先和服务器进行连接，报文发送完成后就断开连接。即每次都要执行TCP的三次握手和四次挥手，效率很低。所以后续提出了 **长连接**的通信方式。

### 长连接(1.1~)

长连接 即连接复用，由于TCP的连接和关闭成本被均摊，传输效率得到了提高。不过长连接可能会导致服务端资源耗尽，所以需要做一定策略关闭连接。

> 开启长连接：`Connection:keep-alive`
>
> 在 Http 1.1后默认开启

客户端可以使用 ``Connection:keep-alive`` 明确要求使用长连接。同时服务端也会返回同样的  ``Connection:keep-alive`` 表示支持长连接。

> 关闭长连接：`Connection: close`

请求头添加 `Connection: close`后服务端在发送玩报文后会主动关闭TCP连接。

### 队头阻塞

队头阻塞是由于Http通信方式为 请求-应答模式导致的。即用一个TCP连接发起请求后必然要等待报文的响应，后续的请求只能排队等待。

优化方式有：

* **并发请求**：针对一个域名开启多个连接。不过客户端一般会存在数量限制。
* **域名分片（domain sharding）**：使用多个域名指向同个服务器以进一步增加上限。

## 重定向

重定向是指由服务端发起，用户无法控制的跳转。常见的有301（永久重定向）/302（临时重定向）。使用场景有域名变更、系统维护、登录验证等。还有就是可以增加访问入口，比如`baidu.com`等，将多个URI指向同一个地址。

服务端会在响应头中会使用 `Location: /xxx` 指定跳转的URI。

> 301和302的主要区别是，浏览器会针对301进行优化，重新访问时会直接跳转到新的URI，节省了一次跳转的成本。
>
> 使用重定向时需要主要循环跳转。

---

## Cookie

Http默认是无状态的，不同请求间不存在关联，而**Cookie就是为了使Http变为有状态**。它由服务端发送给客户端，客户端在下次请求时带上整个Cookie，服务端就能识别客户端的身份。

* `Set-Cookie`：服务端添加 Cookie，格式为`key=value`。
* `Cookie`：客户端将Cookie 发还给服务端。

![image-20230207210744490](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230207210744490.png)

### 用途

* **身份识别**：用户登录后保存用户信息，后续的请求中将身份Cookie发送给服务端表明身份。
* **广告跟踪**：当用户点击广告链接时会被贴上广告商发送的Cookie，后续访问同个商家的广告时会将Cookie带上，这样就能获取到用户的行为路径。

### 安全

* **设置有效期**：可以使用 `Expires` 或 `Max-Age` 属性来设置Cookie的有效期。`Max-Age`的优先级较高。不设置时仅运行时生效，关闭浏览器后失效。**时效是从报文接收到的实际开始计算。**

  ```http
  Set-Cookie: Max-Age=10; Expires=Tue, 07-Feb-23 13:24:56 GMT
  ```

* **限制作用域**：限制浏览器仅发送给特定的服务器和URI，`Domain` 和 `Path`指定了所属的域名和路径，浏览器发送时会对比此部分，匹配时才发送Cookie。

  ```http
  Set-Cookie: Domain=www.baidu.com; Path=/
  ```

* **限制Cookie读取**：通过 `HttpOnly` 限制Cookie仅允许Http协议传输。这样类似 `document.cookie`这样的方式就无法获取Cookie了。

  ```http
  Set-Cookie: HttpOnly
  ```

* **限制跨站发送**：`SameSite=Strike`：完全不能跨站发送。`Lax`：允许`GET/HEAD`等读取操作，禁止`POST`。

  ```http
  Set-Cookie: SameSite=Strike
  ```

* **仅能用于HTTPS**：通过`Secure`禁止明文的HTTP协议发送，仅能HTTPS。

---

## 缓存和代理

### 缓存控制

> 注意：刷新操作会发送 ``Cache-Control: max-age=0``，请求的最新资源，返回200。所以不会并没有使用缓存。
>
> 前进、后退、跳转时会使用缓存。

使用Http获取资源的成本比较高，所以通过增加缓存的方式进行复用，可以降低成本，并加快响应速度。

Http中的缓存控制是在头字段中添加 `Cache-Control`。**服务端和客户端都可以指定此头字段。**

* **缓存时效**：`max-age`，例如缓存30秒。**时效是从报文创建开始计算, 和Cookie不同**。

  ```http
  Cache-Control: max-age=30
  ```

* **缓存策略**：`no-store（不允许缓存）`， `no-cache（需要去服务器验证，优先使用最新，其次缓存）`，`must-revalidate（优先缓存，失效就去服务端验证）`。

### 条件请求

条件请求是为了优化去服务端验证缓存的流程。使用条件请求的前提是，在第一次的响应报文中存在 `Last-modified（最后修改实际）` 或者 `ETag（资源唯一标识）`。然后在后续的请求中会带上这个值，用于判断资源是否变化。没有变化则返回 `304 Not Modified`并应用缓存。

| if条件            | 值            |                                                         |
| ----------------- | ------------- | ------------------------------------------------------- |
| if-Modified-Since | Last-modified |                                                         |
| If-None-Match     | ETag          | 强ETagu要求字节级别匹配。`W/`标记弱ETag仅要求语义级别。 |
|                   |               |                                                         |

### 代理服务

> 位于客户端和服务端直接，可以转发客户端的请求，也可以转发服务器的应答。
>
> 常见的有：HAProxy, Squid, Nginx等。

#### 分类

* **匿名代理**：完全“隐匿”了被代理的机器，外界看到的只是代理服务器；
* **透明代理**：顾名思义，它在传输过程中是“透明开放”的，外界既知道代理，也知道客户端；
* **正向代理**：靠近客户端，代表客户端向服务器发送请求；
* **反向代理**：靠近服务器端，代表服务器响应客户端的请求；

#### 作用

> 代理虽然提供了很多扩展性功能，但是也增加了请求链路的长度带来了一定的性能损耗。

* **负载均衡**：把访问请求均匀分散到多台机器，实现访问集群化；
* **内容缓存**：暂存上下行的数据，减轻后端的压力；
* **安全防护**：隐匿 IP, 使用 WAF 等工具抵御网络攻击，保护被代理的机器；
* **数据处理**：拦截数据，提供压缩、加密等额外的功能。
* **加密卸载**：对外使用SSL/TLS加密，对内则不加密，消除服务端加解密的成本。
* **健康检查**：监控后端服务器，将故障机器踢出集群，保证服务的高可用。

#### 识别

* **Via**：头字段中可能存在`Via: proxy1, proxy2` 顺序记录链路中经过代理。可以知道存在哪些代理。但不一定存在此字段。

* **X-Forwarded-For**：记录请求方的IP，会顺序记录追加。

* **X-Real-IP**：记录客户端 IP 地址。

* **PROXY（代理协议**）：位于起始行上方，格式为：PROXY + IP地址类型 + 请求端IP 接收端IP + 请求方端口 + 接收方端口。可以不必解析Http直接获取到客户端地址。

  ```http
  PROXY TCP4 1.1.1.1 2.2.2.2 512345 80
  GET / HTTP/1.1
  ```


### 缓存代理

由一个代理服务来实现服务端的HTTP缓存。例如 CND。

缓存控制的部分属性如下：

| 属性             |                                                              |                                                    |
| ---------------- | ------------------------------------------------------------ | -------------------------------------------------- |
| private          | 缓存只能在客户端保存，缓存代理服务不可缓存。                 |                                                    |
| public           | 完全开发，都可以缓存。                                       |                                                    |
| -                |                                                              |                                                    |
| must-revalidate  | 只要过期就必须回源服务器验证。                               |                                                    |
| proxy-revalidate | 只要求代理的缓存过期后必须验证。客户端不必回源验证。         |                                                    |
| -                |                                                              |                                                    |
| max-age          | 客户端的缓存时效。                                           |                                                    |
| s-maxage         | 限定在代理服务上的缓存时效。                                 |                                                    |
| -                |                                                              |                                                    |
| no-transform     | 不允许代理对数据进行处理。                                   |                                                    |
| -                |                                                              |                                                    |
| max-stale        | 允许的最大过期时间。即代理缓存过期了也接受，但是不能超过n 秒。 |                                                    |
| min-fresh        | 需求的最小有效期。即代理缓存必须有效，且至少还有 n 秒。      |                                                    |
| -                |                                                              |                                                    |
| only-if-cached   | 只接受缓存代理的数据，不接受源服务器的响应。                 | 缓存代理无缓存或过期时，返回504（Gateway Timeout） |



## Https基础

> HTTP over SSL/TLS
>
> 默认端口：443
>
> Let’s Encrypt：免费颁发CA证书。

由于 Http 是不安全的，所以引入了 Https。

Https 运行在安全的 SSL/TLS 协议上，通过专门的安全接口进行收发报文。

所以 https 和 http 在除了明文、安全性、默认端口之外，其他方面基本是相同的。相当于是给HTTP 套了一个安全的外壳。

* SSL：安全套接层，Secure Sockets Layer
* TLS：传输层安全，Transport Layer Security

SSL/TLS 使用了密码学前沿技术来保证通信的安全。使用的算法组合称为 **密码套件**。例如 `TLS_AES_128_GCM_SHA256`



### 安全通信特征

它具备安全通信的四个特征：

* **机密性（Secrecy/Confidentiality）**：数据加密，不能随便被看到。**（如对称加密AES）**。
* **完整性（Integrity: 一致性）**：数据传输过程中不会被篡改。**（摘要算法：如SHA384）**
* **身份认证（Authentication）**：确认通信双方的身份，保证消息不会发送给错误的对象。**（数字签名、非对称加密：如RSA）**
* **不可否认（Non-repudiation/Undeniable）**：为了保证真实性。**（数字签名、非对称加密）**



### 机密性

对数据进行加密从而保证数据的**机密性**。

* 明文：未加密前的数据。
* 密文：加密后的数据。
* 密钥：用于加解密的关键信息。

按照密钥的使用方式，分为 **对称加密** 和 **非对称加密**。

#### 对称加密

加密和解密使用同一个密钥。常见的算法有 `AES`、`ChaCha20`等。

密钥一次只能处理特定长度的数据，所以对于很长的数据需要进行分组然后再迭代处理。**这个迭代方式就是加密分组模式**。可以让算法用固定长度的密钥加密任意长度的明文。常见的由`GCM`、`CCM` 、`Poly1305`等。

对称加密算法：`AES128-GCM`就是指：密钥长度128的AES算法，并且采用 GCM 分组模式。

> 存在问题 **密钥交换** 的问题。可能被窃取。

#### 非对称加密

存在两个密钥，不存在密钥交换的问题。这两个密钥间存在**单向性**，即**公钥加密的数据只能对应的私钥解密，私钥加密的数据只能对应的公钥解密**。

* **私钥（private key）**：不公开，需要严格保密。
* **公钥（public key）**：可以公开给任何人是使用。

常见的非对称加密有：`RSA`、`ECC`等。

> 存在问题：性能低下，和对称加密相差几百倍。

#### 混合加密

结合对称加密和非对称加密的优点。

* 先使用非对称加密 解决对称加密的密钥交换问题。
* 后续通讯使用 对称加密 兼顾性能。



### 完整性

机密性保证了没有密钥时，密文不会被破解。但也不是绝对的，可以通过收集大量数据，然后进行修改、重组，不断尝试来破解（涉及密码学）。所以需要**通过完整性来使得服务器可以判断数据是否被篡改**。不过单独的摘要算法只保证了原文和摘要的一一对应关系，它可能会被整体替换，这时候需要再结合加密算法保证机密性。

保证完整性的主要手段是**摘要算法（Digest Algorithm）**。常见的有 MD5、SHA-1、**SHA-2**等。

* **长度固定**：任意长度的数据都会被处理成固定长度的字符串。
* **唯一性**：一般情况下都是唯一的，除非发生了散列冲突。
* **单向性（不可逆）**：加密后不能逆推出原文。
* **雪崩效应**：原文微小的改动，加密后也将迥然不同。

> 哈希消息认证码（HMAC）
>
> 发起方：（明文 + 摘要）打包一起使用会话密钥加密。
>
> 接收方：使用会话密钥解密等到 明文和摘要，然后再将明文使用相同的摘要算法进行计算，最后和解密得到的摘要进行比对。
>
> 保证了通讯阶段的安全。

### 身份认证（数字签名）

> 加密算法结合摘要算法保证了通讯过程中的机密性和完整性，但前提是和你通讯的人就是你本应通讯的人，而不是黑客伪装的。所以在这之前还需要进行身份的认证。

**非对称加密中的私钥只有本人持有，可以代表身份**。发送方对数据使用**私钥签名**发送，然后接收方使用**公钥验签**，来验证发送端的身份。由于非对称加密效率太差，所以**只对摘要加密**即可。

使用 私钥 + 摘要算法 生成的 **数字签名** 就可以实现身份认证。

### 不可否认

**数字签名**同时也保证了不可否认。

### 数字证书

**数字证书**是为了解决 **公钥的信任** 问题。

比如你发行了公钥，如何判断这个公钥属于你？此时需要借助第三方来做一个公证。比如 **CA（Certificate Authority，证书认证机构）**。

 CA 对公钥进行签名认证后最终会打包成 **数字证书**。

在浏览器中可以直接查看证书，一般包括：公钥、序列号、颁发者、有效时间、签名算法等。

![image-20230211150802990](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230211150802990.png)

![image-20230211150732490](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230211150732490.png)



> 证书体系（PKI，Public Key Infrastructure）
>
> 认证流程：

* 操作系统和浏览器都内置了各大 CA 的根证书。
* 服务器发送证书链。
* 客户端使用内置的根证书来逐层验证。

>  证书有效性

* **CRL**（Certificate revocation list，证书吊销列表）：由CA发布，包含了被撤销的证书序号。不过这个文件会越来越大，且需要下载。
* **OCSP**（在线证书状态协议，Online Certificate Status Protocol）：向CA发送请求，检查证书的有效性。需要网络访问。
* **OCSP Stapling**：一种优化方案。由服务器预先访问 CA 获取 OCSP 响应结果，然后在握手时随着证书一起发给客户端，免去了客户端连接 CA 服务器查询的时间。

创建自签名证书：

```shell
openssl req -x509 -days 365 -out zaze.test.crt -keyout zaze.test.key \
  -newkey rsa:2048 -nodes -sha256 \
    -subj '/CN=zaze.test' -extensions EXT -config <( \
       printf "[dn]\nCN=zaze.test\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:zaze.test\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
```





## TLS协议

* **记录协议（Record Protocol）**：规定了TLS 收发数据的基本单位：**记录（record）**。多个记录会组合成一个 TCP 包发送。

* **警报协议（Alert Protocol）**：当发生问题时，向对方发出警报。（bad_certificate）

* **握手协议（Handshake Protocol）**：负责协商并交换密钥。

* **变更密码规范协议（Change Cipher Spec Protocol）**：表示后续的数据都将使用加密保护。没有发送此通知前都是明文通讯的。

* **扩展协议（Extension Protocol）**：TLS1.3时新增的协议，主要是为了兼容老的TLS1.2、1.1。可以通过在记录后面添加扩展字段来实现新的功能。在`Hello`消息中会添加`supported_versions`来标记TLS的版本。

  | 扩展字段             |                    |                  |
  | -------------------- | ------------------ | ---------------- |
  | supported_versions   | 标记TLS的版本      | TLS 1.3、TLS 1.2 |
  | supported_groups     | 支持的曲线         | P-256、x25519    |
  | key_share            | 曲线对应的公钥参数 |                  |
  | signature_algorithms | 签名算法           |                  |

  

> TLS1.3 中的密钥交换算法只有 ECDHE 和 DHE。
>
> ECDHE 在每次握手时都会临时生成私钥和公钥，即一次一密，保证了前向安全（以后的报文即使破解了也不会影响历史报文）。RSA不具备前向安全。
>
> 密码套件格式：密钥交换算法 + 签名算法 + 对称加密算法 + 摘要算法。
>
> 一下1.3中的密码条件没有指定 密钥交换算法，签名算法是由于 这些算法被放在了 扩展字段中。supported_groups、key_share、signature_algorithms

| 密码套件                     | 代码        |
| ---------------------------- | ----------- |
| TLS_AES_128_GCM_SHA256       | {0x13,0x01} |
| TLS_AES_256_GCM_SHA384       | {0x13,0x02} |
| TLS_CHACHA20_POLY1305_SHA256 | {0x13,0x03} |
| TLS_AES_128_CCM_SHA256       | {0x13,0x04} |
| TLS_AES_128_CCM_8_SHA256     | {0x13,0x05} |



### TLS握手流程

> TLS 1.3 在 `Hello`  完成了密钥交换。

![image-20230211162213861](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230211162213861.png)

* **TCP三次握手建立连接**。

* **客户端发送 `Client Hello` 消息**。主要包含版本(version)、支持的密码套件(Cipher Suites)、**随机数(Random)**、**1.3扩展字段**(支持的曲线、曲线对应的公钥参数)等。随机数是用于后续生成会话密钥的。

  ![image-20230211163813914](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230211163813914.png)

* **服务端接收到后回复 `Server Hello` 消息**。包含版本(version)、本次通讯使用的密码套件(Cipher Suite)、**随机数(Random)**、**1.3扩展字段**（协商的曲线、曲线对应的公钥参数）等。

  ![image-20230211165529168](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230211165529168.png)

* **客户端验证证书**：逐级验证证书链，确认证书的有效性。

* ~~TLS 1.2 是在证书之后交换密钥：根据使用的算法不同（ECDHE、RSA），交换流程会存在一些小小差异。不过都会通过 `Key Exchange` 消息的来交换`Pre-Master`。最后更加 **Client Random + Server Random + Pre-Master** 来生成会话使用的主密钥。~~

* 进行加密通信。

> 双向认证
>
> 基于上述的 单向认证，认证了服务端后，再添加客户端的证书认证。一般是在 `Server Hello Done` 消息后，`Client Key Exchange ` 之前发送`Client Certificate`。服务端接收后会验证证书链。

### SNI（Server Name Indication）

在 HTTPS 里，TLS 握手时需要使用域名对应的证书，但是请求头只有在 TLS 握手之后才能发送，所以握手期间无法获取到域名只能用IP地址来区分。导致每个 HTTPS 域名必须使用独立的 IP 地址。

后来利用 TLS扩展，客户端会在 `Client Hello` 中添加了 `SNI（Server Name Indication）` 带上域名信息，才解决了这个问题。

```tex
Extension: server_name (len=19)
    Server Name Indication ext
    nsion
        Server Name Type: host_name (0)
        Server Name: www.xxxxxx.com
```

### 会话复用（TLS session resumption）

将在TLS握手过程中生成的 主密钥（Master Sercet）缓存复用。

* ~~`Session ID(TLS1.3已废弃)`~~：连接后服务端和客户端各自保存一个ID，下次新建立连接时将ID发送过去，ID存在就直接用内存中缓存的主密钥恢复会话，从而跳过了验证和密钥交换。（服务端必须保存每一个客户端的会话数据，体量大时负担很重）。

* ~~`Session Ticket(TLS1.3已废弃)`~~：服务端发送 `New Session Ticket` 发送给 Session Ticket 给客户端，并**由客户端存储**，重连时客户端使用扩展字段 `session_ticket` 发送 `Ticket`，服务端解密验证，通过就恢复会话。

  ![image-20230212163812918](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230212163812918-1676448853480-4.png)

  ![image-20230212163927395](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230212163927395-1676448853481-5.png)

* **PSK（预共享密钥,Pre-shared Key）**：TLS1.3中会话复用的实现方案，做到了0-RTT。可以认为是 `Session Ticket` 的升级版，原理就是 客户端在发送 Ticket 的同时带上数据，免去了服务端验证。存在重放攻击的问题。可以通过`SameSite=Strike`，限制仅允许GET/HEAD方法调用、增加时间戳等方式解决。

## HTTP/2

[HTTP/2 (http2.github.io)](https://http2.github.io/)

HTTP/2的目标是改进性能，同时它也兼容HTTP/1。在使用上对用户是无感的。由浏览器或者服务器来自定升降级。

* 兼容HTTP/1，对用户无感。
* HTTP/2支持头部压缩，而HTTP/1只支持body的压缩。
* 报文使用二进制格式格式。
* 流传输：解决了HTTP的队头阻塞问题（TCP的未解决），支持多路复用。
* 由于支持多路复用，所以要求一个域名（或者 IP）只用一个 TCP 连接，但是由于上下行带宽都能充分利用，效率比HTTP/1高很多（HTTP/1，上下行不能同时进行，需要等待）。

> 问题

* TCP重连会导致HPACK字典失效，需要重新积累。
* 由于只有一个连接，所以当这个连接出问题时，将会受到较大的影响。

### HTTP、HTTPS、HTTP/2

使用HTTP/2时我们看到的URL中的协议还是 `http`或`https`。

![image-20230212220532814](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230212220532814.png)



### 连接前言

TLS握手成功后，客户端发送**连接前言（connection preface）**消息来确认建立 HTTP/2 连接。

抓包时看到的 `Magic` 消息就是 连接前言。

![image-20230213130946168](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230213130946168.png)

`Magic`的内容是固定格式：

![image-20230213152016377](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230213152016377.png)

```htt
PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n
```



### 头部压缩(HPACK)

HTTP/2 废弃了报文的起始行，将起始行中的 请求方法、URI、状态码等以 **伪头字段** 的方式转换为头字段的形式，以`:` 开头，且规定头字段必须都是小写。这样报文头就都时 `Key-Value`格式了，方便统一管理和压缩。

![image-20230213131545479](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230213131545479.png)

Header中可能存在很多字段，但有些请求Body却可能就几十字节（GET），所以对头字段使用的是 `HPACK` 算法，进行压缩和消除冗余字段来节省带宽。

`HPACK` 需要客户端和服务端各自维护一份索引表，用于压缩和解压缩。只需要查表就能知道字段名和对于的值。

常用的字段被定义为一份 **静态表**，它是只读的。静态表后面就是 **动态表**，收发个一张，它会在编解码时随时更新。 一开始发送的是具体的字段，后续则只需要发送对应的编码即可。随着发送的报文增多，字典也会越来越丰富，大大节省了带宽。

> TCP连接重新建立后，动态表将会清空，需要重新累计。

> 表大体样式

```tex
# index :name value

2 :method GET
```



### 二级制帧和流传输

HTTP/2参照 TCP/TP，全面采用二进制格式，使用字节、位来表示信息，而不是 ASCII码。以**帧（Frame）**为单位。一帧默认上限`2^14 = 16K`, 最大 `2^24 = 16M`。一个报文可以由多个帧组成。

同时还定义了一个 **流** 的概念，**他是二进制帧的双向传输序列**，**同一个消息往返的帧会被分配同一个流ID**，且同一个流内部的帧是有序的。

即在一个TCP连接中，消息的以帧为单位发送的，不过收发的顺序是乱序的。服务端接收到后按照流ID进行分组，组内按序拼接还原成流。

**一个流代表了 请求-应答 的完整过程**，但是流是可以并发的，所以解决了 HTTP/1的队头阻塞问题(TCP 的队头阻塞依然存在) ，同时也实现了 多路复用 ，提高连接的利用率。

**流的特性：**

* **双向性**：同一个流内，包含了数据的发送和接收。
* **有序性**：流内的帧是有序发送和有序接收的。此处由TCP保证。
* **并发性**：不同流间的帧是并行传输的，依靠流ID来区分。可以理解为CPU的时间片切换。
* **优先级**：客户端可以设置优先级（PRIORITY），从而服务端会将高优先级的资源先发送。

![image-20230212202447422](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230212202447422.png)

> 帧格式
>
> 帧由 **帧头**和**帧数据**组成。
>
> 帧头固定 9字节，由 **帧长度、帧类型、标志位、流标识符**4部分组成。
>
> 帧的大小 = 9 + 帧长度。

![image-20230213154540801](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230213154540801.png)

* **帧长度(3bytes)**：表示当前帧内容的长度(不包括头)。HTTP/2的帧默认上限`2^14 = 16K`, 最大 `2^24 = 16M`

* **帧类型(1bytes)**：表明帧的用途，一般可分为数据帧和控制帧。允许自定义扩展。
  * **数据帧**：存放HTTP报文。如`HEADERS帧`和`DATA帧`。
  * **控制帧**：用于管理流。如 `SETTINGS`、`PING`、`PRIORITY（优先）`、`RST_STREAM（中断流）`等。
  * 其他
* **标志位(1bytes)**：一些简单的控制信息，8位，每位都代表一个标志，可以保存8个标志。
  * **END_HEADERS**：表示头数据结束。类似HTTP/1的`CRLF空行`。
  * **END_STREAM**：某一方数据发送结束（End of Steam），类似 HTTP/1里面 Chunked分块结束标志。客户端和服务都发送 EOS 后表示该次流结束。
* **流标识符(4bytes)**：表示帧所属的流。最高位保留不用，其余31位用于流ID。这31位奇数由客户端使用，所以客户端最多能用 `2^30` 个。ID用完了 可以发送控制帧`GOAWAY`，关闭TCP。

> 帧长度 Length：486；0x0001e6
>
> 帧类型 Type：值是1，表示HEADERS。 0x01
>
> 标志位Flags：0x25 = 0010 0101。这三个1 分别表示某个标志的启用。
>
> 流标志符：Reserved: 0x0 表示最高位保留，后面的 Steam Identifier : 1 就是流标识符。

![image-20230213155302322](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230213155302322.png)

> HTTP/2 还支持**服务端推送**：主动向客户端推送消息，可以预下发一些资源文件（CSS，JS），从而能够更快的显示。

> HTTP/2 的流存在状态的流转，仅是维护这一次 请求-应答里流的状态，不同请求间并没有关联，所以依然是无状态的。

### 应用层协议协商（ALON）

TLS 扩展中存在 `Application Layer Protocol Negotiation`用来于服务端协商应用层协议。在`Client Hello` 消息中发送。服务端会在 `Server Hello`消息中回复结果。

客户端支持的协议，优先级：自上而下，从高到低。

> 优先 h2 ，其次 http/1.1。
>
> h2：HTTP/2密文；h2c：HTTP/2明文
>
>  Chrome等浏览器只支持h2，不支持h2c

![image-20230213201318104](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230213201318104.png)



## HTTP/3

> 2022年6月6日正式发布。
>
> HTTP over QUIC

HTTP/3 解决了TCP的队头阻塞问题。

### QUIC协议

QUIC是传输层协议，和TCP同级。

* 基于UDP实现了可靠传输。
* 内部包含了 TLS1.3，而不是架设在 TLS1.3之上。

* 基本数据传输单位是**包（packet）**和**帧（frame）**，一个包由多个帧组成，包面向的是 连接，帧面向的是 流。包中的帧可以来自不同的流，它只是做了一个整合。

* 使用**连接ID**取代了 **IP + 端口**，来进行绑定，支持**连接转移**。即使由于网络变化变更了IP地址，也不需要像TCP那样进行重连

#### QUIC的流

QUIC的流分为双向和单向。由流ID的低位控制。

流ID的最低两位用作标志。

* 第一位：标识发起者。0客户端，1服务端。且客户端ID都是偶数。
* 第二位：标识流的方向。0双向流，1单向流。

### 协议升级-建立连接

> Http/3没有默认端口号。

* 先用 HTTP/2协议连接服务器。
* 服务器在建立HTTP/2连接后发送一个扩展帧 `Alt-Svc`帧，里面包含`h3=host:port`。
* 浏览器接收到 `Alt-Svc` 后，使用QUIC连接给定的端口。连接成功就改用HTTP/3，并端口HTTP/2。

## WebSocket

**WebSocket 是全双工的通信协议**， 主要是为了优化 HTTP/1 的 请求-应答 模式导致的 半双工问题，也导致 HTTP 难以应用到实时通信领域（即时消息，网络游戏等）。

* 全双工的通信协议。
* 采用二进制帧结构。
* 默认端口：80,443。
* 需要自己管理连接、缓存、状态等，开发复杂度高于 HTTP。

### WebSocket 的握手

利用了 HTTP 协议升级的特性，握手阶段使用 HTTP GET请求来完成协议升级。

* `Upgrade: websocket`：表示升级成 websocket。
* `Connection: Upgrade`：请求协议升级。
* `Sec-WebSocket-Key`：简单的认证密钥。Base64 编码的 16 字节随机数。
* `Sec-WebSocket-Version`：协议版本

![image-20230215130558424](./HTTP%E5%8D%8F%E8%AE%AE.assets/image-20230215130558424.png)



#### WebSocket 应用领域

WebSocket 使用于实时通信的场景：

* IM通信
* 数据实时同步
* 页游

#### 和 HTTP/2的区别

* WebSocket 侧重于实时通信，HTTP/2侧重传输效率。
* HTTP/2 存在流、多路复用、服务端推送，实质还是流内请求-应答模式。WebSocket 没有流、和多路复用等特性，且由于是全双工的，可以同时收发数据，所有也不需要 服务端推送这个功能。
