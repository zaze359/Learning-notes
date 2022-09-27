# Android中的数据库

> SQLite

## 数据库框架

> ORM（Object Relational Mapping）对象关系映射

* greenDAO
* [Room](./Room数据库.md)

## 并发问题

> 在进程与线程的并发中常出现的`SQLiteDatabaseLockedException`问题。

### 多进程并发

> SQLite默认通过文件锁来控制多进程并发。粒度是DB文件。

多进程可以同时获取 SHARED 锁来读取数据，但是只有一个进程可以获取 EXCLUSIVE 锁来写数据库。

EXCLUSIVE模式下，数据库连接在断开前都不会释放 SQLite 文件的锁。

```ini
PRAGMA locking_mode = EXCLUSIVE
```



### 多线程并发

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

## 优化

### 索引

>可以提升 SQLite 的查询速度 ：BETWEEN、LIKE、OR 这些操作符导致索引无法生效。

### 页大小与缓存大小

> SQLite 使用 B+树 存储一个表

调整默认的页大小和缓存大小，可以提升 SQLite 的整体性能。

### 修复

[微信 SQLite 数据库修复实践 (qq.com)](https://mp.weixin.qq.com/s/N1tuHTyg3xVfbaSd4du-tw)