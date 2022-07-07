# Flutter数据持久化

## 一、文件读写

### 权限配置

```shell
# 获取文件路径
flutter pub add path_provider
# 权限申请
flutter pub add permission_handler
# 文件选择
flutter pub add file_picker
```

### Android文件读写权限配置

[管理存储设备上的所有文件  |  Android 开发者  |  Android Developers](https://developer.android.com/training/data-storage/manage-all-files)

> `AndroidManifest.xml`中声明权限
> 在Android11及以上版本仅能操作媒体文件和图片

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
 <application
        android:requestLegacyExternalStorage="true">

```

> 若需要获取所有文件管理权限

```xml
<!-- 以下两个配置在 Android 11 之后需要声明，以便管理所有文件-->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION" />
```

### 权限请求流程

```dart
await Permission.storage.request();
```

> // 高版本获取所有文件管理权限
```dart
await Permission.manageExternalStorage.request();
```


## 二、SQlite数据库

[用 SQLite 做数据持久化 | Flutter 中文文档 | Flutter 中文开发者网站](https://flutter.cn/docs/cookbook/persistence/sqlite)

### 权限配置

`sqflite` 提供了丰富的类和方法，以便你能便捷实用 SQLite 数据库。
`path` 提供了大量方法，以便你能正确的定义数据库在磁盘上的存储位置。

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite:
  path:
```

### 数据库创建、升级和降级
```dart

openDatabase(
  join(await getDatabasesPath(), "book.db"),
  onCreate: (db, version) {
    return db.execute(
      'CREATE TABLE books(id TEXT PRIMARY KEY, name TEXT, extension TEXT, bookUrl TEXT)',
    );
  },
  onUpgrade: (db, oldVersion, newVersion) {},
  onDowngrade: (db, oldVersion, newVersion) {
  },
  version: 1,
);

```

### 数据插入

```dart
/// tableName, 数据为kv结构
db.insert(_bookTable, book.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace));
```

### 数据更新
```dart
db.update(
    _bookTable,
    book.toMap(),
    where: 'id = ?',
    whereArgs: [book.id],
  );
```

### 查询
```dart
db.query(_bookTable);
```

### 删除

```dart
db.delete(
    _bookTable,
    book.toMap(),
    where: 'id = ?',
    whereArgs: [book.id],
  );
```

### 批量操作

```dart
Future<void> batchInsert(Database db, List<T> list) async {
  MyLog.d("Table", "${getTableName()} batchInsert: ${list.length}");
  Batch batch = db.batch();
  // 批量插入
  // 也可以增加更新、删除等其他操作。
  for (var element in list) {
    batch.insert(getTableName(), toMap(element),
                 conflictAlgorithm: ConflictAlgorithm.replace);
  }

  List<Object?> result = await batch.commit();
  for(var res in result) {
    MyLog.d("Table", "${getTableName()} result: ${res}");
  }
}
```

### 字段更新

```
db.execute("ALTER TABLE books ADD md5 TEXT");
```






## 三、Key-Value键值对数据

[存储键值对数据 | Flutter 中文文档 | Flutter 中文开发者网站](https://flutter.cn/docs/cookbook/persistence/key-value)

> 只能用于基本数据类型： int、double、bool、string 和 stringList。

> 不适用于大量数据的存储。


```bash
flutter pub add shared_preferences 
```

### 保存数据

```dart
// obtain shared preferences
final prefs = await SharedPreferences.getInstance();

// set value
prefs.setInt('counter', counter);
```

### 读取数据

```dart
final prefs = await SharedPreferences.getInstance();

// Try reading data from the counter key. If it doesn't exist, return 0.
final counter = prefs.getInt('counter') ?? 0;
```

### 删除

```dart
final prefs = await SharedPreferences.getInstance();

prefs.remove('counter');
```
