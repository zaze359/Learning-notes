# Maven私有仓库搭建

| maven仓库类型 | 具体说明                                     |
| :------------ | :------------------------------------------- |
| hosted        | 宿主类型，本地存储。一般当作内部项目的仓库。 |
| proxy         | 代理类型，提供代理其它仓库的类型。           |
| group         | 组类型，能够组合多个仓库为一个地址提供服务。 |

## Docker + Nexus  搭建本地仓库

### 1.下载Nexus

```shell
docker pull sonatype/nexus3
```

### 2. 创建Nexus的挂载文件夹(可选)

```shell
# mac
mkdir /usr/local/nexus-data && chown -R 200 /usr/local/nexus-data
```

### 3. 启动容器

```shell
docker run -d -p 8081:8081 --name nexus -v /usr/local/nexus-data:/nexus-data --restart=always sonatype/nexus3
docker run -d -p 8081:8081 --name nexus --restart=always sonatype/nexus3
```



---

## 发布到远程Maven中央仓库

[OSSRH Guide - The Central Repository Documentation (sonatype.org)](https://central.sonatype.org/publish/publish-guide/#releasing-to-central)

### 1. 注册sonatype账号

[sonatype注册地址]([https://issues.sonatype.org/secure/Dashboard.jspa)

### 2. 新建一个issues提交并等待审核。

![image-20210908010451062](Maven%E7%A7%81%E6%9C%89%E4%BB%93%E5%BA%93%E6%90%AD%E5%BB%BA.assets/image-20210908010451062.png)



![image-20210908010309978](Maven%E7%A7%81%E6%9C%89%E4%BB%93%E5%BA%93%E6%90%AD%E5%BB%BA.assets/image-20210908010309978.png)

![image-20210908010332122](Maven%E7%A7%81%E6%9C%89%E4%BB%93%E5%BA%93%E6%90%AD%E5%BB%BA.assets/image-20210908010332122.png)

### 3. 根据对方的回复进行操作。

会让你在github上建立一个指定名称的项目来验证身份。一步步操作即可。

![image-20210908010842300](Maven%E7%A7%81%E6%9C%89%E4%BB%93%E5%BA%93%E6%90%AD%E5%BB%BA.assets/image-20210908010842300.png)

### 4. [GPG 相关配置](docs/SecretKey/GPG.md)



## 项目配置Gradle上传脚本

[使用 Maven Publish 插件  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/studio/build/maven-publish-plugin?hl=zh-cn)

>  [maven.gradle参考](https://github.com/zaze359/test/blob/master/maven.gradle)

新建**maven.properties**配置自己的仓库信息

```properties
signing.keyId=CExxxx
signing.password=xxxxx
signing.secretKeyRingFile=~/.gnupg/secret.gpg
RELEASE_REPOSITORY_URL="release仓库地址"
SNAPSHOT_REPOSITORY_URL="snapshot仓库地址"
NEXUS_USERNAME="账号"
NEXUS_PASSWORD="密码"
```

新建 **maven-publish.gradle**，配置打包脚本

```groovy
apply plugin: 'maven-publish'

def loadProperties(Properties properties, List<File> files) {
    if (files != null && !files.isEmpty()) {
        for (File propertiesFile : files) {
            if (propertiesFile.exists()) {
                println("properties.load: " + propertiesFile.absolutePath)
                properties.load(propertiesFile.newDataInputStream())
            } else {
                println("properties not found: " + propertiesFile.absolutePath)
            }
        }
    }
}

Properties mavenProperties = new Properties()
loadProperties(mavenProperties, Arrays.asList(rootProject.file("buildscripts/maven.properties"), rootProject.file("local.properties")))

def isReleaseBuild() {
    return VERSION_NAME.endsWith("SNAPSHOT") == false
}

static def getReleaseRepositoryUrl(Properties properties) {
    return properties.getProperty('RELEASE_REPOSITORY_URL', "http://localhost:8081/repository/maven-releases/")
}

static def getSnapshotRepositoryUrl(Properties properties) {
    return properties.getProperty('SNAPSHOT_REPOSITORY_URL', "http://localhost:8081/repository/maven-snapshots/")
}

static def getRepositoryUsername(Properties properties) {
    return properties.getProperty('NEXUS_USERNAME', "zaze")
}

static def getRepositoryPassword(Properties properties) {
    return properties.getProperty('NEXUS_PASSWORD', "123456")
}


def configurePom(mavenProperties, pom) {
    pom.name = mavenProperties.getProperty("POM_NAME")
    pom.packaging = mavenProperties.getProperty("POM_PACKAGING")
    pom.description = mavenProperties.getProperty("POM_DESCRIPTION")
    pom.url = mavenProperties.getProperty("POM_URL")

    pom.scm {
        url = mavenProperties.getProperty("POM_SCM_URL")
        connection = mavenProperties.getProperty("POM_SCM_CONNECTION")
        developerConnection = mavenProperties.getProperty("POM_SCM_DEV_CONNECTION")
    }

    pom.licenses {
        license {
            name = mavenProperties.getProperty("POM_LICENCE_NAME")
            url = mavenProperties.getProperty("POM_LICENCE_URL")
            distribution = mavenProperties.getProperty("POM_LICENCE_DIST")
        }
    }

    pom.developers {
        developer {
            id = mavenProperties.getProperty("POM_DEVELOPER_ID")
            name = mavenProperties.getProperty("POM_DEVELOPER_NAME")
        }
    }
}

afterEvaluate { project ->
    publishing {
        // 配置仓库地址
        repositories {
            maven {
                allowInsecureProtocol = true
                def releasesRepoUrl = getReleaseRepositoryUrl(mavenProperties)
                def snapshotsRepoUrl = getSnapshotRepositoryUrl(mavenProperties)
                url = isReleaseBuild() ? releasesRepoUrl : snapshotsRepoUrl
                println("publishing repositories: " + url)
                credentials(PasswordCredentials) {
                    username = getRepositoryUsername(mavenProperties)
                    password = getRepositoryPassword(mavenProperties)
                }
            }
        }

        publications {
            // Creates a Maven publication called "release".
            release(MavenPublication) {
                from components.release
                groupId = GROUP
                artifactId = POM_ARTIFACT_ID
                version = VERSION_NAME
                configurePom(mavenProperties, pom)
            }
            // Creates a Maven publication called “debug”.
//            debug(MavenPublication) {
//                from components.debug
//                groupId = GROUP
//                artifactId = POM_ARTIFACT_ID
//                version = VERSION_NAME + "-SNAPSHOT"
//                configurePom(mavenProperties, pom)
//            }
        }

    }
}

if (JavaVersion.current().isJava8Compatible()) {
    allprojects {
        tasks.withType(Javadoc) {
            options.addStringOption('Xdoclint:none', '-quiet')
            options.encoding = "UTF-8"
        }
    }
}

task androidJavadocs(type: Javadoc) {
    source = android.sourceSets.main.java.source
    classpath += project.files(android.getBootClasspath().join(File.pathSeparator))
    excludes = ['**/*.kt']
}

task androidJavadocsJar(type: Jar, dependsOn: androidJavadocs) {
    classifier = 'javadoc'
    from androidJavadocs.destinationDir
}

// 配置源码路径
task androidSourcesJar(type: Jar) {
    classifier = 'sources'
    from android.sourceSets.main.java.source
}

// 将源码打包到 aar
artifacts {
    archives androidSourcesJar
//            archives androidJavadocsJar
}

```



## 使用MavenLocal

> * debug：对应 SNAPSHOT 版本。
> * release：对应正式版本。
>
> 需要注意的是上传release编译产物时，模块自身不能存在debug版本依赖库，否则无法上传。
>
> 所以一般不配置 debug，直接使用 release即可
>
> 本地位置：`~/.m2/repository`

```shell
# 将 debug 产物，上传到 MavenLocal
./gradlew :util:publishDebugPublicationToMavenLocal --info
# 将 release 产物，上传到 MavenLocal
./gradlew :util:publishReleasePublicationToMavenLocal --info
# 同时上传debug、release产物
./gradlew :util:publishToMavenLocal --info
```



### 如何引用MavenLocal

```groovy
buildscript {
    repositories {
		// 添加 mavenLocal() 即可
        mavenLocal()
        google()
        mavenCentral()
    }
}
```

### SNAPSHOT更新问题

```groovy
configurations.all {
    resolutionStrategy.cacheChangingModulesFor 1, 'seconds'
    resolutionStrategy.cacheDynamicVersionsFor 1, 'seconds'
}
```

