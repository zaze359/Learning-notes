---
title: MySQL
date: 2020-07-17 15:42
---
# MySQL学习笔记

参考文档: [MySQL 教程 | 菜鸟教程 (runoob.com)](https://www.runoob.com/mysql/mysql-tutorial.html)

## MySQL安装

### Windows上安装MySQL

[MySQL Installer for Windows](https://dev.mysql.com/downloads/installer/)

`Developer defalut`

`execute`



### 环境配置

用户变量的PATH中添加以下内容:

```shell
C:\Program Files\MySQL\MySQL Shell 8.0\bin
```

系统变量Path中添加以下内容:

```shell
C:\Program Files\MySQL\MySQL Server 8.0\bin
```



Schema

Schema 包括ables、Views、Stored Procedures、Functions四大块。

创建一个Schema就是创建一个Database，基本等同于Database，可以认为是拥有特定规范的一种Database模式。



## 常用命令

```shell
# 数据库连接
mysql -u root -p

# 显示数据库
show databases; 
# 显示数据表 
show tables; 
# 显示表结构 : 
describe 表名;
# 创建库: 
create database 库名; 
# 删除库: 
drop database 库名; 
# 使用库: 
use 库名; 
# 创建表：
create table 表名 (字段设定列表); 
# 删除表：
drop table 表名; 
# 修改表：
alter table t1 rename t2 
# 查询表：
select * from 表名; 
# 清空表：
delete from 表名; 
```

```shell
创建授权
grant select on 数据库.* to 用户名@登录主机 identified by \"密码\" 
删除授权
revoke select,insert,update,delete om *.* from test2@localhost; 

```

### 连接数据库

| 参数 | 说明                 |
| ---- | -------------------- |
| -h   | 需要登陆的主机地址   |
| -u   | 用户名               |
| -p   | 表示需要使用密码登录 |

```shell
mysql -u root -p
```

![](./MySQL.assets/1647444035572.png)

### 断开数据库

```bash
exit
```

### 修改密码

```bash
mysqladmin -u 用户名 -p 旧密码 password 新密码 
```

### 数据库表修改

```bash
增加列：ALTER TABLE t2 ADD c INT UNSIGNED NOT NULL AUTO_INCREMENT,ADD INDEX (c); 
修改列：ALTER TABLE t2 MODIFY a TINYINT NOT NULL, CHANGE b c CHAR(20); 
删除列：ALTER TABLE t2 DROP COLUMN c; 
```

### 数据库表备份和修复

```bash
备份表: mysqlbinmysqldump -h(ip) -uroot -p(password) databasename tablename > tablename.sql 
恢复表: mysqlbinmysql -h(ip) -uroot -p(password) databasename tablename < tablename.sql（操作前先把原来表删除） 
备份数据库：mysql\bin\mysqldump -h(ip) -uroot -p(password) databasename > database.sql 
恢复数据库：mysql\bin\mysql -h(ip) -uroot -p(password) databasename < database.sql 
复制数据库：mysql\bin\mysqldump --all-databases > all-databases.sql 
修复数据库：mysqlcheck -A -o -uroot -p54safer 
```

### sql文件导入

```bash
文本数据导入： load data local infile \"文件名\" into table 表名; 
数据导入导出：mysql\bin\mysqlimport database tables.txt
```



数据插入

格式

```sql
INSERT INTO table_name (column1, column2, column3, ...) VALUES (value1, value2, value3, ...);
```

```sqlite
INSERT INTO showcase(id, create_time,img_url,info,tags,title,update_time,url) VALUES(0,1667563332562,null,'info','Game','明日方舟',1667563332562,'https://ak.hypergryph.com/');

INSERT INTO showcase(id, create_time,img_url,info,tags,title,update_time,url) VALUES(3,1667563332562,null,'333','Game','明日方舟',1667563332562,'https://ak.hypergryph.com/');

```

```sqlite
SELECT * FROM showcase WHERE info='info' and (tags, title) in (select tags,title FROM showcase);
```



## binlog

| 模式      |                               | 优点                         | 缺点                                            |
| --------- | ----------------------------- | ---------------------------- | ----------------------------------------------- |
| statement | 记录每一天会修改数据的SQL语句 | 日志文件小。性能高           | 一致性较差，不支持部分系统函数的复制。now()等。 |
| row       | 记录每行数据的变更            | 强一致性。                   | 日志文件很大，导致较大的网络IO和磁盘IO。        |
| mixed     | statement和row的混合模式。    | 一致性强，日志文件大小适中。 | 可能导致主从不一致。                            |

查看是否开启

```shell
show variables like 'log_%'; 

# log_bin ON
```

查看binlog日志

```shell
# 显示日志列表
show binary logs;
# 默认查看第一个binlog文件的内容。
show binlog events;
# 指定文件
show binlog events in 'xxx';
# 查看当前正在写入的binlog
show master status;
```

