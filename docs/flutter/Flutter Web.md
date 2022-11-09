# Flutter Web开发

[构建和发布为 Web 应用 - Flutter 中文文档 - Flutter 中文开发者网站 - Flutter](https://flutter.cn/docs/deployment/web#deploying-to-the-web)

## 项目配置

### 新建web项目

```shell
# 已当前目录为项目
flutter create --org com.zaze .
# 当前目录下新建 一个hello项目
flutter create --org com.zaze hello
```

### 已有项目添加web支持

```shell
# 会构建所有平台的支持
# .表示当前项目
flutter create .
```

## 运行调试

运行时可能发生`SocketException`

> 方式一、命令运行时指定指定端口
>
> -d debug

```shell
# chrome
flutter run -d Chrome --web-port=8080 --web-hostname=127.0.0.1
# edge
flutter run -d Edge --web-port=8080 --web-hostname=127.0.0.1
```

> 方式二、AndroidStudio中修改run配置：

![image-20221012211207722](./Flutter%20Web.assets/image-20221012211207722.png)

## 编译打包

### 编译

```shell
flutter build web
# --release
flutter build web --release
# --web-renderer canvaskit  使用 CanvasKit 渲染器构建应用
# --web-renderer html   使用 HTML 渲染器构建应用
flutter build web --web-renderer canvaskit --release
```

构建产物在：`[app]/build/web`

### 本地运行

进入`[app]/build/web`目录下，执行以下命令：

```shell
python -m http.server 8000
```

访问`localhost:8000`查看是否正常。

## 部署

[Docker部署web服务](../web/Docker部署web服务.md)

## 开发

### 配置 Web 应用的 URL 策略

[配置 Web 应用的 URL 策略 - Flutter 中文文档 - Flutter 中文开发者网站 - Flutter](https://flutter.cn/docs/development/ui/navigation/url-strategies)
