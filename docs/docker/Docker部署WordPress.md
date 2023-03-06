# Docker搭建WordPress

## 安装镜像

* WordPress：网站框架。
* MariaDB：数据存储
* Nginx：反向代理

```shell
docker pull wordpress:5
docker pull mariadb:10
docker pull nginx:alpine
```



## 启动 MariaDB

```shell
docker run -d --rm \
    --env MARIADB_DATABASE=db \
    --env MARIADB_USER=wp \
    --env MARIADB_PASSWORD=123 \
    --env MARIADB_ROOT_PASSWORD=123 \
    mariadb:10
```

验证数据库是否正常：

```shell
# 登录数据库
docker exec -it 8f7 mysql -u wp -p

show databases;
show tables;

# 查看容器ip
docker inspect 8f7 |grep IPAddress
```



## 运行WordPress

WORDPRESS_DB_HOST = MariaDB的ip地址：

```shell
docker run -d --rm \
    --env WORDPRESS_DB_HOST=172.17.0.2 \
    --env WORDPRESS_DB_USER=wp \
    --env WORDPRESS_DB_PASSWORD=123 \
    --env WORDPRESS_DB_NAME=db \
    wordpress:5
```



## 配置Nginx反向代理

`wp.conf`配置, proxy_pass=WordPress的ip。

```nginx
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

端口映射到 Nginx 容器内部的 80 端口：

```shell
docker run -d --rm \
    -p 80:80 \
    -v `pwd`/wp.conf:/etc/nginx/conf.d/default.conf \
    nginx:alpine
```



