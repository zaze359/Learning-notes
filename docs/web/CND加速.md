# CDN网络加速

> 内容分发网络：CDN（Content Delivery Network / Content Distribution Network）

CDN是为了避免网络链路过长而导致的时间损耗而诞生的网络应用服务。它不生成内容，主要负责内容的缓存和分发。后续也增加了 SSL加速、内容优化（数据压缩）、资源防盗链、WAF 安全防护等功能

常见的网络链路的损耗：

* 地理位置间的距离导致的传输损耗；

* 各个网络间的跨网传输损耗；

* 网络内路由、网关中二、三层解析转发的损耗

CDN的主要作用：

* 就近访问：用户可以优先访问最近的CDN节点而不是源网站（边缘节点）。

* 缓存代理：利用 HTTP 缓存代理技术，将源网站数据逐级缓存到CDN网络节点中。配置了`Cache-Control`的允许缓存的静态资源（超文本、图片、视频等）。



## 负载均衡

**全局负载均衡 GSLB**（Global Sever Load Balance），负责在CDN网络中选出最佳节点。最常见的就是 **DNS 负责均衡**。

* 加入CDN后，**DNS解析返回 CNAME( Canonical Name ) 别名记录，指向CDN的 GSLB**，而不是源网站IP。
* 



## 缓存代理

命中 回源