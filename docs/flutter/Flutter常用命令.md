# Flutter常用命令记录

```shell
# 检测
flutter doctor
flutter doctor -v

flutter --version

# 运行flutter项目
flutter run
flutter run -d windows

# aar, apk, windows, appbundle bundle web
flutter build windows

# 给当前项目添加 桌面端支持
flutter create --platforms=windows,macos,linux .

# 根据json生成 model类
flutter packages pub run json_model
```

## Flutter SDK 分支 管理

```shell
# 查看所有分支
flutter channel
# 切换分支
flutter channel master
```

## 更新

```shell
# 更新flutter sdk 和依赖包
flutter upgrade
# 仅更新packages
flutter pub upgrade
# 查看需要更新内容
flutter pub outdated
```

## 查看可用设备

```bash
flutter devices

# 查看可用模拟器
flutter emulators
# 启动指定模拟器
flutter emulators --launch apple_ios_simulator
# macos也可使用一下命令打开ios模拟器
open -a Simulator

```

## 依赖

```shell
# 添加指定依赖
flutter pub add xxx
```

## 发布packages

```shell
# 检验
flutter pub publish --dry-run

# 若发布时设置了，需要给终端设置代理，否则即使认证了，终端也会无相应
$env:http_proxy=127.0.0.1:7890
$env:https_proxy=127.0.0.1:7890

# 发布packages
flutter pub publish
# 设置了中国镜像时 使用这条发布
flutter packages pub publish --server=https://pub.dartlang.org
```

## 国际化

```shell
# 将 arb 国际化配置文件 生成为 dart类。
# 生成文件位于 ${FLUTTER_PROJECT}/.dart_tool/flutter_gen/gen_l10n
# 需要手动导包： import 'package:flutter_gen/gen_l10n/app_localizations.dart';
flutter gen-l10n

flutter pub add flutter_localizations --sdk=flutter
flutter pub add intl:any
```

