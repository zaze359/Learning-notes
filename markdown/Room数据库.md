# Room数据库

Tags : zaze android

---

[TOC]

---

## Entity文件

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

- **@Entity(tableName = 'favorites') 必须**
```
声明表 : tableName
外键相关
foreignKeys = @ForeignKey(entity = A.class,parentColumns = "aid" ,childColumns = "aid"
- parentColumns : 外键约束类的主键
- childColums : 外键
- onDelete = CASCADE属性, 外键相关联的数据删除时, 该表中的对应外键id数据也会被删除
```

- **@PrimaryKey(autoGenerate=true) 必须**
```
声明主键(必须声明)
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



## Dao文件

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

