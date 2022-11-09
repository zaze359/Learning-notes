# Docker部署Web服务

>  使用 docker + nginx的方式部署

## Docker安装配置

[docker 配置](../env/Docker配置.md)

## Nginx配置

安装nginx：

```shell
docker pull nginx
```

在本机80端口映射到nginx容器内部的80的，并运行nginx服务器：

```
docker run -p 80:80 -d nginx
```

浏览器打开服务地址验证是否生效:

```shell
# 例如 我本地为192.168.56.101
192.168.56.101
```

![image-20221013184320965](./Docker%E9%83%A8%E7%BD%B2web%E6%9C%8D%E5%8A%A1.assets/image-20221013184320965.png)



nginx配置：

>  使用默认配置即可

反向代理配置样例：代理到`172.17.0.3`

```shell
server {
  listen 80;
  default_type text/html;

  location / {
      proxy_http_version 1.1;
      proxy_set_header Host $host;
      proxy_pass http://172.17.0.3;
  }
}
```

代理后挂在配置：

```shell
# -v 将配置文件挂载到nginx的conf.d下
docker run -d --rm \
    -p 80:80 \
    -v `pwd`/wp.conf:/etc/nginx/conf.d/default.conf \
    nginx:alpine
```

## 拷贝Web项目到服务器

```shell
scp -r ./build/web z@192.168.56.101:/home/z/nginx
```

```shell
# 查看nginx containerId
docker ps 

# 将nginx的默认网站替换为我们的网站
docker cp /home/z/nginx/web/. 8f2c9830675e:/usr/share/nginx/html
# 有配置需要修改也可替换nginx的默认配置
docker cp /home/z/nginx/default.conf 8f2c9830675e:/etc/nginx/conf.d/default.conf
```

