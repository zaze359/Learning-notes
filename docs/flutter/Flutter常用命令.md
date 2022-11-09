# Flutter常用命令记录

Flutter SDK分支：

```shell
# 查看所有分支
flutter channel
# 切换分支
flutter channel master
```

> 检测

```shell
flutter doctor
```

> 更新

```shell
# 更新flutter sdk 和依赖包
flutter upgrade
# 仅更新packages
flutter pub upgrade
# 查看需要更新内容
flutter pub outdated
```

> 查看可用设备

```shell
 flutter devices
```

```bash
# 查看可用模拟器
flutter emulators
# 启动指定模拟器
flutter emulators --launch apple_ios_simulator
# macos也可使用一下命令打开ios模拟器
open -a Simulator
# 运行flutter项目
flutter run

```

> 依赖

```shell
# 添加指定依赖
flutter pub add xxx
```

> 发布packages

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

