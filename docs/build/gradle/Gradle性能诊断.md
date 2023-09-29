# Gradle性能诊断

执行检测前先清除gradle的缓存和优化。

```shell
gradlew --profile --recompile-scripts --offline --rerun-tasks assembleDebug
```

## Profile report

> 旧

```shell
./gradlew assembleDebug --profile
```

![image-20221006191240015](./Gradle%E6%80%A7%E8%83%BD%E8%AF%8A%E6%96%AD.assets/image-20221006191240015.png)

|                       |                    |                                                              |
| --------------------- | ------------------ | ------------------------------------------------------------ |
| Summary               | 构建概况           |                                                              |
| Configuration         | 各个模块的配置时间 |                                                              |
| Dependency Resolution | 依赖关系解析时间   |                                                              |
| Artifact Transforms   | Transform耗时      |                                                              |
| Task Execution        | 各个task执行时间   | 此处整体任务耗时相加得出的，而实际上多模块的任务是并行的，会比这里的total小。 |



## Build Scan

> 官方提供的应用构建过程诊断工具

```shell
./gradlew build --scan 
```

第一次执行完成后打开链接需要使用邮箱激活Build Scan。

打开诊断页

![image-20221006200030971](./Gradle%E6%80%A7%E8%83%BD%E8%AF%8A%E6%96%AD.assets/image-20221006200030971.png)

## Gradle一些优化配置

### 使用本地的Gradle环境

> 创建一个本地的Gradle环境，节约开发设备的内存

* 每一个版本的Gradle都会对应一个Daemon进程，使用同一个版本的进程可以节约配置
* 即使使用同一个版本的Gradle, 也会因为VM配置不同而启动多个Daemon进程。

### 项目模块整理
- 去除冗余的模块。
- 将不常改动的模块改为aar 或者maven依赖。
- 尽量保持模块的独立性，减少互相依赖(大大拖慢编译速度)。

### 查找耗时任务
```groovy
public class BuildTimeListener implements TaskExecutionListener, BuildListener {
    private Clock clock
    private times = []

    @Override
    void beforeExecute(Task task) {
        clock = new org.gradle.util.Clock()
    }

    @Override
    void afterExecute(Task task, TaskState taskState) {
        def ms = clock.timeInMs
        times.add([ms, task.path])

        //task.project.logger.warn "${task.path} spend ${ms}ms"
    }

    @Override
    void buildFinished(BuildResult result) {
        println "Task spend time:"
        for (time in times) {
            if (time[0] >= 50) {
                printf "%7sms  %s\n", time
            }
        }
    }

    ......
}

project.gradle.addListener(new BuildTimeListener())
```
