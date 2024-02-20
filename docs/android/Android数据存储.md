# Android数据存储

## 前言

> 数据存储的六要素：正确性、时间开销、空间开销、安全、开发成本和兼容性。

### 文件系统

- 虚拟文件系统（VFS）：主要作用是对应用层屏蔽具体的文件系统，并提供统一的接口。

- 文件系统（File System）：例如ext4, F2FS等。

  ```shell
  # 查看系统可以识别的文件系统
  /proc/filesystems
  ```

- 页缓存（Page Cache）：文件系统对数据的缓存，如果已在Page Cache中就不会去读取磁盘。读/写操作都会使用到。


### 磁盘

- 通用块层：位于内核空间。

  系统中能够堆积访问固定大小数据块的设备称为块设备，例如SSD和硬盘等。
  通用块层的主要作用是接收上层发出的磁盘请求，并发出I/O请求。让上层不必关系底层硬件的具体实现。

- I/O调度层：根据调度算法对请求进行合并和排序，从而降低真正的磁盘I/O。

  ```shell
  /sys/block/[disk]/queue/nr_requests      // 队列长度，一般是 128。
  /sys/block/[disk]/queue/scheduler        // 调度算法
  ```

- 块设备驱动层：根据具体的物理设备，选择对应的驱动程序操作硬件设备完成I/O请求。

  * 闪存：电子擦写存储数据。
  * 光盘：激光烧录存储。

## SharedPreferences

> 使用方便，开发成本低，兼容性好。目前已不推荐使用，而是使用`DataStore`。

### 使用场景

* 适合存储一些比较简单、轻量的键值对数据；文件不易过大。

### 存在的问题

* **可能阻塞主线程**。文件加载时使用了异步线程，且加载线程没有设置线程优先级，所以当主线程读取数据时，需要等待加载线程的结束。导致了**主线程等待低优先级线程锁的问题**。
  * 可以使用提前异步线程预加载来优化。

* **跨进程不安全**。没有跨进程锁，在跨进程时 每个进程都是全量读写，频繁读写时容易导致数据全部丢失。
* **全量写入**。sp的任何改动调用`commit()`或`apply()`时都是全量写入的。且为**多次提交多次全量写入**。
* **类型不安全**：相同的Key，可以使用不同的数据类型存入，获取数据时会进行类型强制转换。
* **apply()可能导致卡顿或ANR**。由于`apply()`提供的是异步落盘机制，为了尽量避免在崩溃或异常时导致数据丢失，当应用**收到系统广播**或者**onPause()被调用**等一些时机时, 系统会强制把所有的sp数据落到磁盘中。如果没有落地完成，主线程就会被阻塞发生卡顿，甚至ANR。

### 一些使用方式

#### 替换系统默认实现方式

```java
public class MyApplication extends Application {
  @Override
  public SharedPreferences getSharedPreferences(String name, int mode)        
  {
     return SharedPreferencesImpl.getSharedPreferences(name, mode);
  }
}
```

---

## DataStore

> [使用 Preferences DataStore (google.cn)](https://developer.android.google.cn/codelabs/android-preferences-datastore?hl=zh_cn#0)

用于解决 `SharedPreferences`存在的一些缺陷而提供的机制，同样适用于存储简单的数据集。

* 支持Kotlin 协程和 Flow。
* 事务的方式更新数据。
* Key  绑定了Value 数据类型。
* 能够监听操作结果。

### Preference DataStore

类似 SharedPreferences，并提供了类似 `Map`的API。

```groovy
implementation "androidx.datastore:datastore-preferences:1.0.0"
```

使用案例：

```kotlin
package com.zaze.demo.feature.storage.datastore

// 文件名
private const val USER_PREFERENCES_NAME = "user_preferences"
private object PreferencesKeys {
    // 表示 key 对应的数据是 string 类型
    val USERNAME = stringPreferencesKey("username")
}
// 委托方式获取dataStore
private val Context.dataStore by preferencesDataStore(
    name = USER_PREFERENCES_NAME
)

@HiltViewModel
class DataStoreViewModel @Inject constructor(application: Application) : AbsAndroidViewModel(application) {
    private val dataStore = application.dataStore

    val userPreferencesFlow: Flow<String> = dataStore.data
        .catch { exception ->
            // 处理异常
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }
        .map { preferences ->
            preferences[PreferencesKeys.USERNAME]?: "empty"
        }

    fun update() {
        viewModelScope.launch {
            // 插入/更新数据
            dataStore.edit { preferences ->
                preferences[PreferencesKeys.USERNAME] = "zaze"
            }
        }
    }

    fun remove() {
        viewModelScope.launch {
            dataStore.edit { preferences ->
                // 删除指定数据
                preferences.remove(PreferencesKeys.USERNAME)
            }
        }
    }

    fun clear() {
        viewModelScope.launch {
            dataStore.edit { preferences ->
                // 清空
                preferences.clear()
            }
        }
    }
}
```

> 生成的文件在 `data/data/com.xx.xx/files/datastore/` 下面。

![image-20230401171328074](./Android%E6%95%B0%E6%8D%AE%E5%AD%98%E5%82%A8.assets/image-20230401171328074.png)



### Proto DataStore





## 文件存储

## 数据库（sqlite）

Android 内置了sqlite数据库，并提供了 `SQLiteOpenHelper` 类供我们来操作数据库。

### 使用方式

> 定义数据库

```java
public class DBOpenHelper extends SQLiteOpenHelper {

    private static final String DATABASE_NAME = "zaze_provider.db"; //数据库名称
    private static final int DATABASE_VERSION = 1;//数据库版本

    public DBOpenHelper(Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
        // 配置数据库参数
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        // 数据库不存在，新建时调用。
        //
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        // 数据库升级时调用。
        // 处理数据库升级逻辑
    }
}

```

> 操作数据库

```kotlin
package com.zaze.core.database.sqlite;

/**
 * Description :
 *
 * @author : ZAZE
 * @version : 2017-03-30 - 00:28
 */
public class UserDao extends BaseDao<UserEntity> {
    
    public static class Properties {
        public final static String TABLE_NAME = "user";
        public final static String ID = "_id";
        public final static String USER_ID = "user_id";
        public final static String USER_NAME = "user_name";
    }
    
    private SQLiteDatabase db;

    public UserDao(SQLiteDatabase db) {
        this.db = db;
    }

    public void createTable() {
        db.execSQL("CREATE TABLE IF NOT EXISTS " + Properties.TABLE_NAME +
                "(" + Properties.ID + " INTEGER PRIMARY KEY AUTOINCREMENT" +
                ", " + Properties.USER_ID + " LONG" +
                ", " + Properties.USER_NAME + " VARCHAR" +
                ")");
    }

    public void updateTable() {
    }
    
    public void insert(UserEntity userEntity) {
        ContentValues values = new ContentValues();
        values.put(Properties.USER_ID, userEntity.getUserId());
        values.put(Properties.USER_NAME, userEntity.getUsername());
        // 插入数据
        db.insert(Properties.TABLE_NAME, null, values);
    }

    public void update(UserEntity userEntity) {
        ContentValues values = new ContentValues();
//        values.put(Properties.USER_ID, userEntity.getUserId());
        values.put(Properties.USER_NAME, userEntity.getUsername());
        // 数据更新
        db.update(Properties.TABLE_NAME, values, Properties.USER_ID + "=?", new String[]{userEntity.getUserId() + ""});
    }

    public UserEntity dealCursor(Cursor cursor) {
        UserEntity user = new UserEntity();
        user.setId(getLong(cursor, Properties.ID));
        user.setUserId(getLong(cursor, Properties.USER_ID));
        user.setUsername(getString(cursor, Properties.USER_NAME));
        return user;
    }
}
```





> `data/data/com.zaze.demo/zaze_user.db`

```shell
# 打开数据库
sqlite3 zaze_user.db
# 显示数据库表
.table
# 查看建表语句
.schema
```





### 常用的数据库框架

* greenDAO：三方提供 的 ORM（Object Relational Mapping）对象关系映射数据库框架。

* [Room](./Android数据库之Room.md)：Google 官方提供的数据库框架

### 并发问题

> 在进程与线程的并发中常出现的`SQLiteDatabaseLockedException`问题。

#### 多进程并发

> SQLite默认通过文件锁来控制多进程并发。粒度是DB文件。

多进程可以同时获取 SHARED 锁来读取数据，但是只有一个进程可以获取 EXCLUSIVE 锁来写数据库。

EXCLUSIVE模式下，数据库连接在断开前都不会释放 SQLite 文件的锁。

```ini
PRAGMA locking_mode = EXCLUSIVE
```

#### 多线程并发

> SQLite默认开启了多线程并发模式。粒度是DB文件。

```ini
PRAGMA SQLITE_THREADSAFE = 2
```

多线程可以同时读取数据库数据，但是写数据库依然是互斥的。

多个写并发有可能会出现 `SQLiteDatabaseLockedException`。

> 通过 打开WAL（Write-Ahead Logging）模式读和写可以完全地并发执行，不会互相阻塞，提供高并发性能。

```ini
PRAGMA schema.journal_mode = WAL
```



> 同一个句柄同一时间只有一个线程在操作。可以指定连接池的大小进行优化

```
public static SQLiteDatabase openDatabase (String path, 
                    SQLiteDatabase.CursorFactory factory, 
                    int flags, 
                    DatabaseErrorHandler errorHandler, 
                    int poolSize)
```

### 优化

#### 索引

>可以提升 SQLite 的查询速度 ：BETWEEN、LIKE、OR 这些操作符导致索引无法生效。

#### 页大小与缓存大小

> SQLite 使用 B+树 存储一个表

调整默认的页大小和缓存大小，可以提升 SQLite 的整体性能。

#### 修复

[微信 SQLite 数据库修复实践 (qq.com)](https://mp.weixin.qq.com/s/N1tuHTyg3xVfbaSd4du-tw)





## 开源存储方案

MMKV

## ContentProvider

ContentProvider 是一种支持不同进程或应用程序之间**共享数据的机制**，具体的数据存储方式可以是内存或者上面那些持久化方式。相册、日历、音频等系统模块使用了这个机制开放数据。

### Uri

ContentProvider 的 **Uri** 参数 和 网络中的Uri是一样的格式，用来唯一标识一个ConentProvider，都可以通过 `Uri.parse()` 来解析，主要分为以下几个部分：

| 组成部分          |                       |                                                              |
| ----------------- | --------------------- | ------------------------------------------------------------ |
| 协议名（scheme）  | ``content://``        | 表示协议。                                                   |
| 主机名或authority | ``com.zaze.provider`` | 用于唯一标识这个ContentProvider，外部应用需要根据这个标识来找到它。 |
| 路径（path）      | `/user`               | 用于区分不同的表。                                           |

### ContentResolver

用于执行 `ContentProvider` 操作，包括添加、删除、修改和查询操作等操作。它和`ContentProvider`中的实现相对应。

可以使用``Context.getContentResolver()``方法获取对象。

```java
// 用于查询指定Uri的ContentProvider，返回一个Cursor
public Cursor query(Uri, String[], String, String[], String) 

// 用于添加数据到指定Uri的ContentProvider中
public Uri insert(Uri, ContentValues)

// 用于更新指定Uri的ContentProvider中的数据
public int update(Uri, ContentValues, String, String[])

// 用于从指定Uri的ContentProvider中删除数据
public int delete(Uri, String, String[]) 

// 用于返回指定的Uri中的数据的MIME类型
public String getType(Uri) 
```



### 定义ContentProvier

> 创建 ContentProvier 类
>
> 此处共享了数据库中内容。

```java
package com.zaze.demo.component.provider;

public class ZazeProvider extends ContentProvider {
    // --------------------------------------------------
    public static final int MULTIPLE_PEOPLE = 1;
    public static final int SINGLE_PEOPLE = 2;

    public static final String AUTHORITY = "com.zaze.user.provider";
    public static final String PATH_SINGLE = "user/#";
    public static final String PATH_MULTIPLE = "user";
    public static final String CONTENT_URI_STRING = "content://" + AUTHORITY + "/" + PATH_MULTIPLE;

    //
    public static final Uri CONTENT_URI = Uri.parse(CONTENT_URI_STRING);
    public static final UriMatcher URI_MATCHER;

    static {
        URI_MATCHER = new UriMatcher(UriMatcher.NO_MATCH);
        URI_MATCHER.addURI(AUTHORITY, PATH_SINGLE, SINGLE_PEOPLE);
        URI_MATCHER.addURI(AUTHORITY, PATH_MULTIPLE, MULTIPLE_PEOPLE);
    }

    private DBOpenHelper dbOpenHelper;
    private SQLiteDatabase db;

    // 在创建ContentProvider时调用
    @Override
    public boolean onCreate() {
        this.dbOpenHelper = new DBOpenHelper(this.getContext());
        db = dbOpenHelper.getWritableDatabase();
        return true;
    }

    // 查询数据，返回一个Cursor
    @Override
    public Cursor query(Uri uri, String[] projection, String selection, String[] selectionArgs, String sortOrder) {
        SQLiteQueryBuilder queryBuilder = new SQLiteQueryBuilder();
        queryBuilder.setTables(UserDao.Properties.TABLE_NAME);
        switch (URI_MATCHER.match(uri)) {
            case MULTIPLE_PEOPLE:
                ZLog.i(ZTag.TAG_PROVIDER, "MULTIPLE_PEOPLE");
                break;
            case SINGLE_PEOPLE:
                queryBuilder.appendWhere(UserDao.Properties.USER_ID + "=" + uri.getPathSegments().get(1));
                ZLog.i(ZTag.TAG_PROVIDER, "SINGLE_PEOPLE");
                break;
            default:
                break;
        }
        return queryBuilder.query(
                db, projection, selection,
                selectionArgs, null, null, sortOrder
        );
//        return dbOpenHelper.getUserDao().query(projection, selection, selectionArgs, null, null, sortOrder);
    }

    // 用于返回MIME类型, 主要是 用于隐式启动 Activity的
    // intent.setData(Uri) 这里传入的 ContentProvider Uri会经过getType()转为MIME，然后去匹配对应Action的Activity
    @Override
    public String getType(Uri uri) {
        switch (uriMatcher.match(uri)) {
            case MULTIPLE_PEOPLE:
                // 多条
                return "vnd.android.cursor.dir/com.zaze.user.provider.user";
            case SINGLE_PEOPLE:
                // 单条
                return "vnd.android.cursor.item/com.zaze.user.provider.user";
        }
        return null;
    }


    // 添加数据
    @Override
    public Uri insert(Uri uri, ContentValues values) {
        long insertId = dbOpenHelper.getUserDao().insert(values);
        Uri newUri = ContentUris.withAppendedId(CONTENT_URI, insertId);
        getContext().getContentResolver().notifyChange(newUri, null);
        return newUri;
    }
    
	// 删除数据
    @Override
    public int delete(Uri uri, String selection, String[] selectionArgs) {
        return dbOpenHelper.getUserDao().delete(selection, selectionArgs);
    }

    @Override
    public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) {
        return dbOpenHelper.getUserDao().update(values, selection, selectionArgs);
    }
}

```



> 在AndroidManifest.xml 中声明

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.zaze.demo"> 
    <provider
		android:name="com.zaze.demo.component.provider.ZazeProvider"
		android:authorities="com.zaze.user.provider"
		android:enabled="true"
		android:exported="true" />
    
</manifest>
```



### 实现机制

ContentProvider 在进行跨进程数据传递时，利用了 **Binder** 和 **匿名共享内存(ashmem)** 机制。

通过`Binder`传递`CursorWindow`对象内部的匿名共享的文件描述符，从而使用文件描述符来操作同一块匿名内存，达到不同进程访问相同数据的目的。

![image-20220919160109522](./Android%E6%95%B0%E6%8D%AE%E5%AD%98%E5%82%A8.assets/image-20220919160109522.png)

### 生命周期

ContentProvider 的生命周期在` Application onCreate() `之前，而且是在主线程创建的，所以在初始化时需要避免耗时操作，导致启动速度变慢。

![image-20220919160851695](./Android%E6%95%B0%E6%8D%AE%E5%AD%98%E5%82%A8.assets/image-20220919160851695.png)

* 如果操作的数据属于集合类型，那么MIME类型字符串应该以`vnd.android.cursor.dir/`开头。

```
例如：要得到所有person记录的Uri为content://contacts/person，
那么返回的MIME类型字符串为"vnd.android.cursor.dir/person"。
```

* 如果要操作的数据属于非集合类型数据，那么MIME类型字符串应该以`vnd.android.cursor.item/`开头。

```
例如：要得到id为10的person记录的Uri为content://contacts/person/10，
那么返回的MIME类型字符串应为"vnd.android.cursor.item/person"。
```

