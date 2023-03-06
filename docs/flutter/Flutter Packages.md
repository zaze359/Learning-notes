# Flutter Package

[Flutter Packages 的开发和提交 - Flutter 中文文档 - Flutter 中文开发者网站 - Flutter](https://flutter.cn/docs/development/packages-and-plugins/developing-packages#step-1-create-the-package-1)

package方便创建共享的模块化代码。

## 创建package

原生插件 package 创建需要使用  `--template=plugin` 标志创建。

```shell
# -org：指定包名，用于android 和 ios
# --platforms：指定平台
# -a：指定android的开发语言; java kotlin
# -i：指定ios的开发语言；objc swift 
flutter create --org com.example --template=plugin --platforms=android,ios -a kotlin hello

```

例如创建一个 atoolbox 的 package。

```shell
flutter create --org com.zaze --template=plugin --platforms=android,ios,web -a kotlin atoolbox
```

使用命令后会自动创建`atookbox` 项目，内部包含了必要的目录和文件。

![image-20230209160835730](./Flutter%20Packages.assets/image-20230209160835730.png)

| 文件         |                                                              |      |
| ------------ | ------------------------------------------------------------ | ---- |
| example      | 样例项目,和我们正常创建的flutter 项目一样，可以直接运行。主要用于说明如何使用 package。 |      |
| android      | 存放 android端的实现代码                                     |      |
| ios          | 存放ios端的实现代码                                          |      |
| lib          | 存放dart实现代码                                             |      |
| test         | 测试用例                                                     |      |
| pubspec.yaml | 配置 package                                                 |      |
|              |                                                              |      |

## 配置Package

### 指定支持的平台

配置 `pubspec.yaml` 可以指定 package 支持的平台。

```yaml
flutter:
	# 支持的平台
    platforms:
      android:
      	# 对应的实现文件
        package: com.zaze.atoolbox
        pluginClass: AtoolboxPlugin
      ios:
      	# 对应的实现文件
        pluginClass: AtoolboxPlugin
      web:
      	# 对应的实现文件
        pluginClass: AtoolboxWeb
        fileName: atoolbox_web.dart
```



### 配置 Package 的依赖

例如 依赖了 `url_launcher`。	需要在 `pubspec.yaml`中添加依赖。

```yaml
dependencies:
  url_launcher: ^5.0.0
```

## 阐述许可条款

需要配置 项目下的 `LICENSE` 文件。

* 项目根目录新建 `LICENSE` 文件。
* 若已有LICENSE，直接拷贝内容即可。
* 若无已Github为例：，在新建 `LICENSE(文件名必须是这个)` 文件时，选择 `Choose a license template` 。

![image-20230209172401430](./Flutter%20Packages.assets/image-20230209172401430.png)

![image-20230209172346985](./Flutter%20Packages.assets/image-20230209172346985.png)

## 发布到pub.dev

检验：

```shell
flutter pub publish --dry-run
```

发布：

```shell
flutter pub publish
```

> 若设置了中国镜像，则需要指定发布地址。国内的镜像不支持 package 上传。
>
> 可能还需要用到终端代理。

```shell
#需要给终端设置代理，否则即使认证了，终端也会无相应
$env:http_proxy=127.0.0.1:7890
$env:https_proxy=127.0.0.1:7890

# 若设置了中国镜像时 使用这条发布
flutter packages pub publish --server=https://pub.dartlang.org
```

