# Flutter单元测试

[单元测试介绍 | Flutter 中文文档 | Flutter 中文开发者网站](https://flutter.cn/docs/cookbook/testing/unit/introduction)



## 1. 添加依赖

> 在yaml中添加依赖。

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # 模拟设备
  flutter_driver:
    sdk: flutter
    
  flutter_lints: ^2.0.0
  # mock对象
  mockito: ^5.2.0
```



## 集成测试

```
flutter drive --target=test/file_test.dart
```

