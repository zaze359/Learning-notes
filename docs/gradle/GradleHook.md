## Gradle Hook

![img](GradleHook.assets/428ff3d7635e4dc8b16fbdca8e60e9d6~tplv-k3u1fbpfcp-zoom-in-crop-mark:3024:0:0:0.awebp)

| Hook点            | 说明                                                         |
| ----------------- | ------------------------------------------------------------ |
| settingsEvaluated | 在 `setting script` 被执行完毕后回调。                       |
| projectsLoaded    | 回调时各个模块的project对象已被创建，但是`build script`仍未执行，所以无法获取到配置信息。 |
| afterEvaluate     | `build.gradle`执行完毕后回调。此时当前`build.gradle`中的所有配置项都能够被访问到。 |
| projectsEvaluated | 所有的project配置结束后回调。                                |
| graphPopulated    | task graph生成后回调。                                       |
| buildFinished     | 所有的task执行完毕后回调。                                   |

