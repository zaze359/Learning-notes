## Flutter 常用库

[Dart packages (pub.dev)](https://pub.dev/)



[Flutter常用第三方框架 - 简书 (jianshu.com)](https://www.jianshu.com/p/89d27f220933)

```
flutter pub add xxx
flutter pub remove xxx
```

## 文件路径

```shell
flutter pub add path_provider
```

> path\_provider api

| Flutter                            | Android                   | IOS                           | 备注           |
| ---------------------------------- | ------------------------- | ----------------------------- | :------------- |
| getTemporaryDirectory()            | getCacheDir()             | NSCachesDirectory             | 临时缓存文件夹 |
| getApplicationDocumentsDirectory() | AppData目录               | NSDocumentDirectory           |                |
| getExternalStorageDirectory()      | getExternalFilesDir(null) | UnsupportedError              | 外部存储目录   |
| getApplicationSupportDirectory()   | getFilesDir()             | NSApplicationSupportDirectory |                |

Documents目录：

```dart
Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

```

## 文件选择器

`flutter pub add file_picker`

选择文件夹：

```dart
String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
if (selectedDirectory != null) {
  var dir = Directory(selectedDirectory);
  dir.listSync().forEach((element) {
    print("selectedDirectory listSync: ${element.path}");
  });
}
```

选择文件：

> 此处获取到的文件路径是拷贝后的文件路径。
>
> 可直接返回数据内容或者Stream

```dart
var pickResult = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: false,
    onFileLoading: (filePickerStatus) {
      print("filePickerStatus name: ${filePickerStatus.name}");
      print(
          "filePickerStatus runtimeType: ${filePickerStatus.runtimeType}");
    });
pickResult?.paths.forEach((element) {
  print("pickResult paths: ${element}");
});
pickResult?.files.forEach((element) {
  print("pickResult files path: ${element.path}");
});
```

## 权限管理

```shell
flutter pub add permission_handler
```

## 图片

[cached_network_image | Flutter Package (pub.dev)](https://pub.dev/packages/cached_network_image)

````shell
flutter pub add cached_network_image
````

## 相机

```shell
flutter pub add camera
```

## 网络请求

```shell
flutter pub add http
```

```shell
flutter pub add dio
```

## HTML解析

```shell
flutter pub add html
```

## JSON解析

[json_serializable | Dart Package (pub.dev)](https://pub.dev/packages/json_serializable)

依赖组件

```shell
flutter pub add json_annotation
flutter pub add json_serializable --dev
flutter pub add build_runner --dev
```

先写Json模版

```dart
// 需要指定自动生成的dart文件
part 'book_source.g.dart';

// 标明根据此类生产Json处理相关模版类
@JsonSerializable()
class BookSource {
  // 映射具体的json key
  @JsonKey(name: "bookUrl")
  String url;
  String name;
  String? tags;
  String? comment;
  BookUrl searchUrl = BookUrl();
  SearchRule searchRule = SearchRule();
  int lastUpdateTime = 0;

  BookSource({this.url = "", this.name = ""})
      : lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
}
```

生成模版类:

> 执行完成后会在此文件同目录下多个 `book_source.g.dart`文件。
>
> 内部就是处理Json相关的辅助方法。

```shell
flutter pub run build_runner build
```

```dart
BookSource _$BookSourceFromJson(Map<String, dynamic> json) => BookSource(
      url: json['url'] as String? ?? "",
      name: json['name'] as String? ?? "",
    )
      ..tags = json['tags'] as String?
      ..comment = json['comment'] as String?
      ..searchUrl = BookUrl.fromJson(json['searchUrl'] as Map<String, dynamic>)
      ..searchRule = SearchRule.fromJson(json['searchRule'])
      ..lastUpdateTime = json['lastUpdateTime'] as int;

Map<String, dynamic> _$BookSourceToJson(BookSource instance) =>
    <String, dynamic>{
      'url': instance.url,
      'name': instance.name,
      'tags': instance.tags,
      'comment': instance.comment,
      'searchUrl': instance.searchUrl,
      'searchRule': instance.searchRule,
      'lastUpdateTime': instance.lastUpdateTime,
    };
```

完整样例

```dart
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:shosai/utils/log.dart';
import 'package:html/dom.dart';

part 'book_source.g.dart';

@JsonSerializable()
class BookSource {
  String url;
  String name;
  String? tags;
  String? comment;
  BookUrl searchUrl = BookUrl();
  SearchRule searchRule = SearchRule();
  int lastUpdateTime = 0;

  BookSource({this.url = "", this.name = ""})
      : lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

  factory BookSource.fromJson(Map<String, dynamic> json) =>
      _$BookSourceFromJson(json);

  Map<String, dynamic> toJson() => _$BookSourceToJson(this);
}
```

## 加密/解密

> md5、SHA-1等

```shell
flutter pub add crypto
```

## URL跳转

```shell
flutter pub add url_launcher
```

```dart
final Uri _url = Uri.parse('https://flutter.dev');
Future<void> _launchUrl() async {
  if (!await launchUrl(_url)) {
    throw 'Could not launch $_url';
  }
}
```

## 国际化和本地化功能库

> 消息翻译、复数和性别、日期/数字格式和解析以及双向文本

```shell
flutter pub add intl
```

时间格式化：

```dart
DateFormat.yMMMMEEEEd().format(aDateTime);
  ==> 'Wednesday, January 10, 2012'
DateFormat('EEEEE', 'en_US').format(aDateTime);
  ==> 'Wednesday'
DateFormat('EEEEE', 'ln').format(aDateTime);
  ==> 'mokɔlɔ mwa mísáto'
      
DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
  ==> '2022-10-14 22:18:17'
```

数字格式化：

```dart
var f = NumberFormat('###.0#', 'en_US');
print(f.format(12.345));
  ==> 12.34

```



## Toast提示

> 支持Android 、IOS。Web测试无效
>
> 官方提供的是 SnackBar

```shell
flutter pub add fluttertoast
```

## 轮播效果

[card_swiper | Flutter Package (pub.dev)](https://pub.dev/packages/card_swiper)

```shell
flutter pub add card_swiper
```

