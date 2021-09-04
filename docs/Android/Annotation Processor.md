---
title: Annotation Processor
date: 2020-07-24 13:53
---

[TOC]

# Annotation Processor(Java编译时注解处理器)

## 项目结构
```table
模块|类型|备注|
annotation|Java Library|存放自定义注解|
compiler|Java Library|注解处理器,依赖annotation模块|
app|项目|使用annotationProcessor依赖compiler模块|
```
## 使用实例

## @AutoService
```
implementation 'com.google.auto.service:auto-service:1.0-rc3'
```
## AbstractProcessor

###  init(ProcessingEnvironment processingEnvironment)
- ProcessingEnvironment(注解处理工具集合)
```table
类|说明|
Filer|编写新文件|
Messager|打印错误信息|
Elements|处理Element的工具类|
```
- Element
包、类、方法或者一个变量
```table
类|说明|
PackageElement|表示包,提供相关包以及成员其信息的访问|
TypeElement|表示类或接口, 提供相关类型及成员信息的访问|
ExecutableElement|类或接口的方法、构造方法等|
VariableElement|表示字段、enum常量、参数、局部变量、异常参数等|
```


