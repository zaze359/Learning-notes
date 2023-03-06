# pom文件

## 节点说明

* `<repositories>` ：内配置代码依赖仓库

```xml
<repositories>
```



## 自定义 dependencyManagement

我们可以通过 `<dependencyManagement>` 节点来代替 `<parent>` 从而自定义版本管理。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	
	<groupId>zaze.spring.demo</groupId>
	<artifactId>demo</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<name>demo</name>
	<description>Demo project for Spring Boot</description>
	<properties>
		<java.version>1.8</java.version>
		<kotlin.version>1.7.22</kotlin.version>
	</properties>

    <!-- 自定义dependencyManagement -->
    <dependencyManagement>
		<dependencies>
			<dependency>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-starter-parent</artifactId>
				<version>2.3.1.RELEASE</version>
				<type>pom</type>
				<scope>import</scope>
			</dependency>
		</dependencies>
	</dependencyManagement>
    
	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>

    <build>
		<sourceDirectory>${project.basedir}/src/main/kotlin</sourceDirectory>
		<testSourceDirectory>${project.basedir}/src/test/kotlin</testSourceDirectory>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
                <!-- start 需要指定在打包时介入 -->
				<version>2.3.1.RELEASE</version>
				<executions>
					<execution>
						<goals>
							<goal>
								repackage
							</goal>
						</goals>
					</execution>
				</executions>
                <!-- end -->
			</plugin>
		
		</plugins>
	</build>

</project>

```

