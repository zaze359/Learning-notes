---
title: MySQL
date: 2020-07-17 15:42
---

# MySQL
## 常用命令
```bash
创建授权
grant select on 数据库.* to 用户名@登录主机 identified by \"密码\" 
删除授权
revoke select,insert,update,delete om *.* from test2@localhost; 

```
### mysql操作
- 连接
```bash
mysql -h主机地址 -u用户名 －p用户密码
```
- 断开
```bash
exit
```
- 修改密码
```bash
mysqladmin -u用户名 -p旧密码 password 新密码 
```

### 数据库操作
- 基础操作
```bash
显示数据库 : show databases; 
显示数据表 : show tables; 
显示表结构 : describe 表名; 
创建库: create database 库名; 
删除库: drop database 库名; 
使用库: use 库名; 
创建表：create table 表名 (字段设定列表); 
删除表：drop table 表名; 
修改表：alter table t1 rename t2 
查询表：select * from 表名; 
清空表：delete from 表名; 
```
- 修改
```bash
增加列：ALTER TABLE t2 ADD c INT UNSIGNED NOT NULL AUTO_INCREMENT,ADD INDEX (c); 
修改列：ALTER TABLE t2 MODIFY a TINYINT NOT NULL, CHANGE b c CHAR(20); 
删除列：ALTER TABLE t2 DROP COLUMN c; 
```
- 备份修复
```bash
备份表: mysqlbinmysqldump -h(ip) -uroot -p(password) databasename tablename > tablename.sql 
恢复表: mysqlbinmysql -h(ip) -uroot -p(password) databasename tablename < tablename.sql（操作前先把原来表删除） 
备份数据库：mysql\bin\mysqldump -h(ip) -uroot -p(password) databasename > database.sql 
恢复数据库：mysql\bin\mysql -h(ip) -uroot -p(password) databasename < database.sql 
复制数据库：mysql\bin\mysqldump --all-databases > all-databases.sql 
修复数据库：mysqlcheck -A -o -uroot -p54safer 
```
- 导入
```bash
文本数据导入： load data local infile \"文件名\" into table 表名; 
数据导入导出：mysql\bin\mysqlimport database tables.txt
```
