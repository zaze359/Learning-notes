## ~~maven~~

```
apply plugin: 'maven'
apply plugin: 'signing'

version = VERSION_NAME
group = GROUP

def loadProperties(Properties properties, List<String> files) {
    if (files != null && !files.isEmpty()) {
        for (String fileName : files) {
            File propertiesFile = project.file(rootProject.file(fileName))
            if (propertiesFile.exists()) {
                println("properties.load: " + fileName)
                properties.load(propertiesFile.newDataInputStream())
            }
        }
    }
}

Properties properties = new Properties()
loadProperties(properties, Arrays.asList('maven.properties', 'local.properties'))

def isReleaseBuild() {
    return VERSION_NAME.contains("SNAPSHOT") == false
}

def getReleaseRepositoryUrl(Properties properties) {
    return properties.getProperty('RELEASE_REPOSITORY_URL', "http://localhost:8081/repository/maven-releases/")
}

def getSnapshotRepositoryUrl(Properties properties) {
    return properties.getProperty('SNAPSHOT_REPOSITORY_URL', "http://localhost:8081/repository/maven-snapshots/")
}

def getRepositoryUsername(Properties properties) {
    return properties.getProperty('NEXUS_USERNAME', "zaze")
}

def getRepositoryPassword(Properties properties) {
    return properties.getProperty('NEXUS_PASSWORD', "123456")
}

afterEvaluate { project ->
    uploadArchives {
        repositories {
            mavenDeployer {
                beforeDeployment { deployment -> signing.signPom(deployment) }
                pom.groupId = GROUP
                pom.artifactId = POM_ARTIFACT_ID
                pom.version = VERSION_NAME
                repository(url: getReleaseRepositoryUrl(properties)) {
                    authentication(userName: getRepositoryUsername(properties), password: getRepositoryPassword(properties))
                }
                snapshotRepository(url: getSnapshotRepositoryUrl(properties)) {
                    authentication(userName: getRepositoryUsername(properties), password: getRepositoryPassword(properties))
                }
                pom.project {
                    name POM_NAME
                    packaging 'aar'
                    description POM_DESCRIPTION
                    url ''

                    scm {
                        url ''
                        connection ''
                        developerConnection ''
                    }

                    licenses {
                        license {
                            name properties.getProperty("POM_LICENCE_NAME")
                            url properties.getProperty("POM_LICENCE_URL")
                            distribution properties.getProperty("POM_LICENCE_DIST")
                        }
                    }

                    developers {
                        developer {
                            id properties.getProperty("POM_DEVELOPER_ID")
                            name properties.getProperty("POM_DEVELOPER_NAME")
                            email properties.getProperty("POM_DEVELOPER_EMAIL")
                        }
                    }
                }
            }
        }
    }
//
    signing {
        required { isReleaseBuild() && gradle.taskGraph.hasTask("uploadArchives") }
        sign configurations.archives
    }
//
    task androidSourcesJar(type: Jar) {
        classifier = 'sources'
        from 'src/main/java'
    }

    artifacts {
        archives androidSourcesJar
//        archives androidJavadocsJar
    }
//
//    android.libraryVariants.all { variant ->
//        def name = variant.buildType.name
//        if (!name.equals("debug")) {
//            def task = project.tasks.create "jar${name.capitalize()}", Jar
//            task.dependsOn variant.javaCompile
//            task.from variant.javaCompile.destinationDir
//            artifacts.add('archives', task)
//        }
//    }
}
```





## maven-publish

```

apply plugin: 'maven-publish'
apply plugin: 'signing'

version = VERSION_NAME
group = GROUP

def loadProperties(Properties properties, List<String> files) {
    if (files != null && !files.isEmpty()) {
        for (String fileName : files) {
            File propertiesFile = project.file(rootProject.file(fileName))
            if (propertiesFile.exists()) {
                println("properties.load: " + fileName)
                properties.load(propertiesFile.newDataInputStream())
            }
        }
    }
}

Properties properties = new Properties()
loadProperties(properties, Arrays.asList('maven.properties', 'local.properties'))

def isReleaseBuild() {
    return VERSION_NAME.contains("SNAPSHOT") == false
}

def getReleaseRepositoryUrl(Properties properties) {
    return properties.getProperty('RELEASE_REPOSITORY_URL', "http://localhost:8081/repository/maven-releases/")
}

def getSnapshotRepositoryUrl(Properties properties) {
    return properties.getProperty('SNAPSHOT_REPOSITORY_URL', "http://localhost:8081/repository/maven-snapshots/")
}

def getRepositoryUsername(Properties properties) {
    return properties.getProperty('NEXUS_USERNAME', "zaze")
}

def getRepositoryPassword(Properties properties) {
    return properties.getProperty('NEXUS_PASSWORD', "123456")
}

def configurePom(pom) {
    pom.name = POM_NAME
    pom.packaging = POM_PACKAGING
    pom.description = POM_DESCRIPTION
    pom.url = POM_URL

    pom.scm {
        url = POM_SCM_URL
        connection = POM_SCM_CONNECTION
        developerConnection = POM_SCM_DEV_CONNECTION
    }

    pom.licenses {
        license {
            name = POM_LICENCE_NAME
            url = POM_LICENCE_URL
            distribution = POM_LICENCE_DIST
        }
    }

    pom.developers {
        developer {
            id = POM_DEVELOPER_ID
            name = POM_DEVELOPER_NAME
        }
    }
}

afterEvaluate { project ->
    publishing {
        repositories {
            maven {
                def releasesRepoUrl = getReleaseRepositoryUrl(properties)
                def snapshotsRepoUrl = getSnapshotRepositoryUrl(properties)
                url = isReleaseBuild() ? releasesRepoUrl : snapshotsRepoUrl

                println("url: " + url)
                credentials(PasswordCredentials) {
                    username = getRepositoryUsername(properties)
                    password = getRepositoryPassword(properties)
                    println("username: " + username)
                    println("password: " + password)
                }
            }
        }
    }

    if (project.getPlugins().hasPlugin('com.android.application') ||
            project.getPlugins().hasPlugin('com.android.library')) {

        task androidJavadocs(type: Javadoc) {
            source = android.sourceSets.main.java.source
            classpath += project.files(android.getBootClasspath().join(File.pathSeparator))
            excludes = ['**/*.kt']
        }

        task androidJavadocsJar(type: Jar, dependsOn: androidJavadocs) {
            classifier = 'javadoc'
            from androidJavadocs.destinationDir
        }

        task androidSourcesJar(type: Jar) {
            classifier = 'sources'
            from android.sourceSets.main.java.source
        }
    }

    if (JavaVersion.current().isJava8Compatible()) {
        allprojects {
            tasks.withType(Javadoc) {
                options.addStringOption('Xdoclint:none', '-quiet')
            }
        }
    }

    if (JavaVersion.current().isJava9Compatible()) {
        allprojects {
            tasks.withType(Javadoc) {
                options.addBooleanOption('html5', true)
            }
        }
    }

    artifacts {
        if (project.getPlugins().hasPlugin('com.android.application') ||
                project.getPlugins().hasPlugin('com.android.library')) {
            archives androidSourcesJar
            archives androidJavadocsJar
        }
    }

    android.libraryVariants.all { variant ->
        tasks.androidJavadocs.doFirst {
            classpath += files(variant.javaCompileProvider.get().classpath.files.join(File.pathSeparator))
        }
    }

    publishing.publications.all { publication ->
        publication.groupId = GROUP
        publication.version = VERSION_NAME

        publication.artifact androidSourcesJar
        publication.artifact androidJavadocsJar

        configurePom(publication.pom)
    }

    signing {
        publishing.publications.all { publication ->
            sign publication
        }
    }
}
```

