# AndroidX


## AndroidX概述
```
    AndroidX是一个开源项目，Android团队使用它在Jetpack中开发、测试、打包、版本和发布库。
    AndroidX是对最初的Android Support库的一个重大改进。与Support库一样，AndroidX独立于Android操作系统发布，并在Android版本之间提供向后兼容性。AndroidX通过提供特性奇偶校验和新的库完全取代了support库。此外，AndroidX还包括以下功能:
    AndroidX中的所有包都位于一个以AndroidX开头的一致命名空间中。Support库包已经映射到相应的androidx.*中。
    与support库不同，AndroidX包是单独维护和更新的。androidx包从1.0.0版本开始使用严格的语义版本。您可以在项目中独立地更新AndroidX库。
    所有新的支持库开发都将在AndroidX库中进行。这包括维护原有的support库构件和引入新的Jetpack组件。
```

## 如何迁移到AndroidX

[如何迁移][link_AndroidX]

```
    如果要在新项目中使用AndroidX，需要将编译SDK设置为Android 9.0 (API级别28)或更高，并在Gradle中设置以下两个Android Gradle插件标志为true。属性文件。
    android.useAndroidX:当设置为true时，Android插件使用适当的AndroidX库而不是支持库。如果没有指定标志，则默认为false。
    android.enableJetifier:当设置为true时，Android插件会自动迁移现有的第三方库，通过重写它们的二进制文件来使用AndroidX。如果没有指定标志，则默认为false。
```




[link_AndroidX]: https://developer.android.google.cn/jetpack/androidx/migrate