# Flutter学习笔记

## 参考资料

[Flutter - Build apps for any screen](https://flutter.dev/)

[Flutter中文网 (flutterchina.club)](https://flutterchina.club/)

[第二版序 | 《Flutter实战·第二版》 (flutterchina.club)](https://book.flutterchina.club/)

以下内容部分摘自以上资料。

## 一、Flutter简介

### 1.1 特性

- 使用Dart开发。
- 使用自己的渲染引擎自绘UI，不依赖于原生控件。
- 跨平台，支持Android、IOS、Windows等众多平台。



### 1.2 框架结构

![Flutter框架结构](https://guphit.github.io/assets/img/1-1.82c25693.png)

Framework层：

| 模块                                      | 分类       | 包                                                           |
| ----------------------------------------- | ---------- | ------------------------------------------------------------ |
| Foundation、Animation、Painting、Gestures | dart UI 层 | 它是Flutter Engine暴露的底层UI库，提供动画、手势及绘制功能。 |
| Rendering                                 | 渲染层     | 构建渲染树，对变化部分进行更新渲染。                         |
| Widgets                                   | 基础组建库 | 基础组建库。                                                 |
| Material、Cupertino                       | 风格组件   | 基于Material和IOS设计规范的组建库                            |

Engine层：

主要由C/C++实现，包括了 Skia 引擎、Dart 运行时、文字排版引擎等。实现真正的绘制和显示。

Embedder层：

调用所在平台的操作系统的API。



## 二、Flutter环境搭建

[1.3 搭建Flutter开发环境 | 《Flutter实战·第二版》 (flutterchina.club)](https://book.flutterchina.club/chapter1/install_flutter.html#_1-3-1-安装flutter)

mac下使用brew安装：

```shell
brew install --cask flutter
```

检测依赖：

```shell
flutter doctor
```

Android Studio插件安装：

- Flutter插件
- Dart插件

Flutter SDK分支：

```shell
# 查看所有分支
flutter channels
# 切换分支
flutter channel master
# 更新flutter sdk 和依赖包
flutter upgrade
```

