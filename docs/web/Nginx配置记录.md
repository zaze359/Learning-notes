# Nginx配置记录

## HTTP配置

```nginx
server {
  # 开启 fastopen，在初次握手时就传输数据。
  listen 80 deferred reuseport backlog=4096 fastopen=1024; 

  # 长连接配置
  keepalive_timeout  60;
  keepalive_requests 10000;
  
  # 动静分离
  location ~* \.(png)$ {
    root /var/images/png/;
  }
  
  location ~* \.(php)$ {
    proxy_pass http://php_back_end;
  }
}
```





### 配置HTTPS

> 在443端口启用 SSL加密

```nginx
server {
    listen       443 ssl;


    server_name  www.xxx.com;


    ssl_certificate         xxx.crt;
    ssl_certificate_key     xxx.key;
```



### 配置 HTTP/2

基于原先的HTTPS配置，添加一个 `http2`即可。

> 在443端口启用 SSL加密，同时启用 http2

```nginx
server {
    listen       443 ssl http2;


    server_name  www.xxx.com;


    ssl_certificate         xxx.crt;
    ssl_certificate_key     xxx.key;
```

> 配置服务器推送

```nginx
http2_push         /style/xxxxx.css;
http2_push_preload on;
```

