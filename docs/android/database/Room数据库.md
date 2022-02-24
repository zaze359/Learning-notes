# Room数据库

[使用 Room 持久保留数据  | Android Developers](https://developer.android.com/codelabs/basic-android-kotlin-training-persisting-data-room?hl=zh_cn&continue=https%3A%2F%2Fcodelabs.developers.google.com%2F%3Fcat%3Dandroid#0)



## Room使用

### 数据实体:Entity

实体类，表示一张表

```
@Entity(tableName = "favorites")
public class Favorites {

    @PrimaryKey(autoGenerate=true)
    private long id;

    @ColumnInfo(name = "title") 
    private String title;

    private String intent;

    private int itemType;
    
    private int aid;
}
```

- **@Entity(tableName = 'favorites') **
```
声明表 : tableName
外键相关
foreignKeys = @ForeignKey(entity = A.class,parentColumns = "aid" ,childColumns = "aid"
- parentColumns : 外键约束类的主键
- childColums : 外键
- onDelete = CASCADE属性, 外键相关联的数据删除时, 该表中的对应外键id数据也会被删除
```

- **@PrimaryKey(autoGenerate=true) **
```
1声明主键(必须声明一个字段为主键)
- autoGenerate = true 自增
```

- @ColumnInfo(name = "title") 
```
- 选用
- 可以手动设置字段名,默认为变量名
```

- @Ignore 
```
忽略这个字段，即不在表中生成
```

- @Embedded
```
嵌套对象时用
```



### Dao文件

- @Query
```
可以用于构建自定义Sql语句
```

- @Insert
```
```

- @Update
```
```

- @Delete
```
```



## Room 和 Flow

使用room返回flow，当表数据发生变更时，将会直接收到变化后的数据。

例如:

```
@Query("SELECT * FROM app_detail")
fun loadAllApps(): Flow<List<AppDetail>>
```

### Flow创建和通知流程

通过查看xxxDao_Impl可知主要逻辑集中在``CoroutinesRoom.createFlow()``这个方法中, ``callable``实质是个一次对应sql的执行

```kotlin
@JvmStatic
public fun <R> createFlow(
  db: RoomDatabase,
  inTransaction: Boolean,
  tableNames: Array<String>,
  callable: Callable<R>
): Flow<@JvmSuppressWildcards R> = flow {
  // Observer channel receives signals from the invalidation tracker to emit queries.
  val observerChannel = Channel<Unit>(Channel.CONFLATED)
  val observer = object : InvalidationTracker.Observer(tableNames) {
    override fun onInvalidated(tables: MutableSet<String>) {
      // 数据失效，channel中发生一个事件
      observerChannel.offer(Unit)
    }
  }
  observerChannel.offer(Unit) // Initial signal to perform first query.
  val flowContext = coroutineContext
  val queryContext = coroutineContext[TransactionElement]?.transactionDispatcher
  ?: if (inTransaction) db.transactionDispatcher else db.queryDispatcher
  withContext(queryContext) {
    db.invalidationTracker.addObserver(observer)
    try {
      // Iterate until cancelled, transforming observer signals to query results to
      // be emitted to the flow.
      for (signal in observerChannel) {
        // 收到事件后执行一次sql,并发送最新结果
        val result = callable.call()
        withContext(flowContext) { emit(result) }
      }
    } finally {
      db.invalidationTracker.removeObserver(observer)
    }
  }
}
```

### 何时执行``onInvalidated()``?

数据更新插入或者删除时最终都会调用``__db.endTransaction();``

```kotlin
@Override
public void insertOrUpdateApps(final List<AppDetail> apps) {
  __db.assertNotSuspendingTransaction();
  __db.beginTransaction();
  try {
    __insertionAdapterOfAppDetail.insert(apps);
    __db.setTransactionSuccessful();
  } finally { // 此处
    __db.endTransaction();
  }
}
```

通过查看``RoomDatabase``类，得知调用链``endTransaction()`` ->  ``internalEndTransaction()`` ；

```kotlin
@Deprecated
public void endTransaction() {
  if (mAutoCloser == null) {
    internalEndTransaction();
  } else {
    mAutoCloser.executeRefCountingFunction(db -> {
      internalEndTransaction();
      return null;
    });
  }
}
```

```kotlin
private void internalEndTransaction() {
  mOpenHelper.getWritableDatabase().endTransaction();
  if (!inTransaction()) {
    // enqueue refresh only if we are NOT in a transaction. Otherwise, wait for the last
    // endTransaction call to do it.
    mInvalidationTracker.refreshVersionsAsync();
  }
}
```

最终调用了 ``InvalidationTracker.refreshVersionsAsync()``

```kotlin
public void refreshVersionsAsync() {
  // TODO we should consider doing this sync instead of async.
  if (mPendingRefresh.compareAndSet(false, true)) {
    if (mAutoCloser != null) {
      // refreshVersionsAsync is called with the ref count incremented from
      // RoomDatabase, so the db can't be closed here, but we need to be sure that our
      // db isn't closed until refresh is completed. This increment call must be
      // matched with a corresponding call in mRefreshRunnable.
      mAutoCloser.incrementCountAndEnsureDbIsOpen();
    }
    mDatabase.getQueryExecutor().execute(mRefreshRunnable);
  }
}
```

再来查看``mRefreshRunnable``中做了什么

```kotlin
@VisibleForTesting
Runnable mRefreshRunnable = new Runnable() {
  @Override
  public void run() {
    // ....
    if (invalidatedTableIds != null && !invalidatedTableIds.isEmpty()) {
      synchronized (mObserverMap) {
        for (Map.Entry<Observer, ObserverWrapper> entry : mObserverMap) {
          entry.getValue().notifyByTableInvalidStatus(invalidatedTableIds);
        }
      }
    }
  }

  // ...
};
```

在``notifyByTableInvalidStatus()``里最终调用了``onInvalidated()``

```kotlin
void notifyByTableInvalidStatus(Set<Integer> invalidatedTablesIds) {
  Set<String> invalidatedTables = null;
  final int size = mTableIds.length;
  for (int index = 0; index < size; index++) {
    final int tableId = mTableIds[index];
    if (invalidatedTablesIds.contains(tableId)) {
      if (size == 1) {
        // Optimization for a single-table observer
        invalidatedTables = mSingleTableSet;
      } else {
        if (invalidatedTables == null) {
          invalidatedTables = new HashSet<>(size);
        }
        invalidatedTables.add(mTableNames[index]);
      }
    }
  }
  if (invalidatedTables != null) {
    mObserver.onInvalidated(invalidatedTables);
  }
}
```



