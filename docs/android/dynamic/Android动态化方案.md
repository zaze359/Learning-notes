# Android动态化方案

* Web容器增强：基于H5，代表方案有 PWA、腾讯的 VasSonic、淘宝的 zCache 以及大部分的小程序方案。
* 虚拟运行环境：使用独立的虚拟机运行，但最终使用原生控件渲染，代表方案有 React Native、Weex、快应用等。
* 业务插件化：基于 Native 的组件化开发，代表方案有阿里的 Atlas、360 的 RePlugin、滴滴的 VirtualAPK 、微信的 Tinker、美团的 Robust、阿里的 AndFix。
* 布局动态化：预设布局配置，如阿里的 Tangram、Facebook 的 Yoga。



> 宿主：主项目App。
>
> 插件：需要加载的功能组件。一般就是 apk类文件。
>
> 补丁：需要修复bug的文件。`.patch`、`.apk`、`.dex` 等。



## 动态加载的作用

* 快速修复线上bug。
* 加快项目编译速度，减小APK体积，将部分模块剥离成插件。
* 项目解耦，并行开发，快速集成。
* 灰度更新 体验部分功能。

## 动态加载的实现

1. 基于 ClassLoader 实现动态加载。
   * 对于 重复的类，会优先使用 先加载的类。通过反射将修复文件插入到`dexElements`数组的最前面。
   * 对于已加载的类 需要重启应用后才能生效修改。
2. 基于Jni Hook，直接修改应用运行时的内存地址，不需要重启应用就能生效修改。



|                                                              |      |             |                                                              | 优点     | 缺点                                         |
| ------------------------------------------------------------ | ---- | ----------- | ------------------------------------------------------------ | -------- | -------------------------------------------- |
| [dynamic-load-apk](https://github.com/singwhatiwanna/dynamic-load-apk) |      |             |                                                              |          |                                              |
| Dexposed                                                     | 阿里 | jni hook    | 基于Xposed的AOP框架，方法级粒度。支持AOP编程、插桩、热补丁、SDK hook等功能 |          |                                              |
| AndFix                                                       | 阿里 | jni hook    | 通过修改 ArtMethod 结构体 直接进行方法替换。                 |          | 厂商可能改写了 ArtMethod的结构导致无法生效。 |
| Tinker                                                       | 腾讯 | ClassLoader | 将修复dex文件插入到 `DexPathList`前面，起到修复的作用。      |          | 需要重启；                                   |
| Robust                                                       | 美团 |             | 在编译期为每个方法插入了一段逻辑代码，为每个类创建了一个ChangeQuickRedirect 静态成员变量，当它不为空会转入新的代码逻辑达到修复bug的目的。 | 兼容性高 | 增加应用体积                                 |
| [DroidPlugin](https://github.com/Qihoo360/DroidPlugin)       | 360  |             |                                                              |          |                                              |
|                                                              |      |             |                                                              |          |                                              |





## Android中的类加载器

类加载器 ClassLoader 的作用就是将 class文件加载到虚拟机中，从而就能创建这个class对应的实体对象。它是实现动态加载的基础。

| 类加载器                                                     |                                                              |      |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ---- |
| BootClassLoader                                              | 加载一些系统Framework层级需要的类                            |      |
| [PathClassLoader.java](https://cs.android.com/android/platform/superproject/main/+/main:libcore/dalvik/src/main/java/dalvik/system/PathClassLoader.java) | 只能加载Android系统 已安装的 apk。是应用的默认类加载器，LoadedApk中被创建。 |      |
| [DexClassLoader.java](https://cs.android.com/android/platform/superproject/main/+/main:libcore/dalvik/src/main/java/dalvik/system/DexClassLoader.java) | 可以加载任意位置的`jar、dex、apk`文件。热修复就是使用的这个。 |      |
| [BaseDexClassLoader.java](https://cs.android.com/android/platform/superproject/main/+/main:libcore/dalvik/src/main/java/dalvik/system/BaseDexClassLoader.java) | PathClassLoader 和 DexClassLoader的父类。                    |      |
|                                                              |                                                              |      |
|                                                              |                                                              |      |
|                                                              |                                                              |      |

### ClassLoader

* ClassLoader 调用 `loadClass()`  执行类加载时，会**优先通过自身 判断类是否已加载**，若没加载，则会委派给 parent 处理。
* 若传递到最顶层 ClassLoader 也没加载，则会去加载对应类，**优先 parent 来加载类**，然后再层层回传。
* 若 parent ClassLoader 无法加载，才会由 子ClassLoader加载。

```java
public abstract class ClassLoader {

    static private class SystemClassLoader {
        public static ClassLoader loader = ClassLoader.createSystemClassLoader();
    }
    private final ClassLoader parent;
    // 创建 PathClassLoader
    private static ClassLoader createSystemClassLoader() {
        String classPath = System.getProperty("java.class.path", ".");
        String librarySearchPath = System.getProperty("java.library.path", "");
        // TODO Make this a java.net.URLClassLoader once we have those?
        return new PathClassLoader(classPath, librarySearchPath, BootClassLoader.getInstance());
    }
    
    // 加载类，先查找，再加载
    // 此处实现双亲委派，优先 parent加载。
    protected Class<?> loadClass(String name, boolean resolve)
        throws ClassNotFoundException
    {
            // First, check if the class has already been loaded
            Class<?> c = findLoadedClass(name);
            if (c == null) {
                try {
                    if (parent != null) {
                        // 交由 parent加载，相当于递归，也是先判断是否已加载
                        c = parent.loadClass(name, false);
                    } else {
                        // 交由最顶层 BootstrapClass 去加载
                        c = findBootstrapClassOrNull(name);
                    }
                } catch (ClassNotFoundException e) {
                    // ClassNotFoundException thrown if class not found
                    // from the non-null parent class loader
                }
				// 若未加载，则
                if (c == null) {
                    // If still not found, then invoke findClass in order
                    // to find the class.
                    // 找到类
                    c = findClass(name);
                }
            }
        	// 回调结果
            return c;
    }
    // 判断是否已加载
    protected final Class<?> findLoadedClass(String name) {
        ClassLoader loader;
        if (this == BootClassLoader.getInstance())
            loader = null;
        else
            loader = this;
        // native，根据ClassLoader 和 name 定位class
        return VMClassLoader.findLoadedClass(loader, name);
    }
    // 这里由子类重载来实现具体的类加载逻辑。看 BaseDexClassLoader
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        throw new ClassNotFoundException(name);
    }
}
```

### BaseDexClassLoader

* dexPath：需要加载的 dex文件路径。也支持apk、jar等。
* librarySearchPath：加载 dex 时需要用到的库路径
* ~~optimizedDirectory~~：已经废弃了，出于安全考虑，这个路径由系统自行设置。
* sharedLibraryLoaders：会优先从这些ClassLoader中加载类，找不到时才会从当前ClassLoader自身查找。
* sharedLibraryLoadersAfter：优先级最低，若当前ClassLoader找不到则会从这里查找。

```java
public class BaseDexClassLoader extends ClassLoader {
    
    private final DexPathList pathList;
    
     public BaseDexClassLoader(String dexPath, File optimizedDirectory,
            String librarySearchPath, ClassLoader parent) {
        this(dexPath, librarySearchPath, parent, null, null, false);
    }
    
    public BaseDexClassLoader(String dexPath,
            String librarySearchPath, ClassLoader parent, ClassLoader[] sharedLibraryLoaders,
            ClassLoader[] sharedLibraryLoadersAfter,
            boolean isTrusted) {
        super(parent);
        this.sharedLibraryLoaders = sharedLibraryLoaders == null
                ? null
                : Arrays.copyOf(sharedLibraryLoaders, sharedLibraryLoaders.length);
        
        // 从这里查找类
        this.pathList = new DexPathList(this, dexPath, librarySearchPath, null, isTrusted);
		
        this.sharedLibraryLoadersAfter = sharedLibraryLoadersAfter == null
                ? null
                : Arrays.copyOf(sharedLibraryLoadersAfter, sharedLibraryLoadersAfter.length);
        // Run background verification after having set 'pathList'.
        this.pathList.maybeRunBackgroundVerification(this);
        reportClassLoaderChain();
    }
    
    // 这里实现了 如何进行类加载
    @Override
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        // First, check whether the class is present in our shared libraries.
        if (sharedLibraryLoaders != null) {
            for (ClassLoader loader : sharedLibraryLoaders) {
                try {
                    return loader.loadClass(name);
                } catch (ClassNotFoundException ignored) {
                }
            }
        }
        // Check whether the class in question is present in the dexPath that
        // this classloader operates on.
        List<Throwable> suppressedExceptions = new ArrayList<Throwable>();
        Class c = pathList.findClass(name, suppressedExceptions);
        if (c != null) {
            return c;
        }
        // Now, check whether the class is present in the "after" shared libraries.
        if (sharedLibraryLoadersAfter != null) {
            for (ClassLoader loader : sharedLibraryLoadersAfter) {
                try {
                    return loader.loadClass(name);
                } catch (ClassNotFoundException ignored) {
                }
            }
        }
        // 报错
        if (c == null) {
            ClassNotFoundException cnfe = new ClassNotFoundException(
                    "Didn't find class \"" + name + "\" on path: " + pathList);
            for (Throwable t : suppressedExceptions) {
                cnfe.addSuppressed(t);
            }
            throw cnfe;
        }
        return c;
    }
    
}
```

### DexClassLoader/PathClassLoader

```java
// 热修复、插件化时 构建的就是这个 ClassLoader
public class DexClassLoader extends BaseDexClassLoader {
    public DexClassLoader(String dexPath, String optimizedDirectory,
            String librarySearchPath, ClassLoader parent) {
        super(dexPath, null, librarySearchPath, parent);
    }
}
```

```java
// LoadedApk中创建，应用的默认类加载
public class PathClassLoader extends BaseDexClassLoader {
    /**
     * dexPath：System.getProperty("java.class.path", ".");
     * librarySearchPath: System.getProperty("java.library.path", "")
     * parent: BootClassLoader.getInstance()
     **/
    public PathClassLoader(String dexPath, String librarySearchPath, ClassLoader parent) {
        super(dexPath, null, librarySearchPath, parent);
    }
}
```



## 动态加载SO

将需要 动态库 文件拷贝到 `/data` 目录下，Android不允许动态加载外部存储的 so。

```java
const val soLibName = "libmynative-lib.so"
val soPath = "${dir}/so/${soLibName}"
    
fun loadSo(context: Context) {
    ZLog.i(ZTag.TAG_DEBUG, "loadSo")
    val soInData = copyLibToData(context, soPath)
    System.load(soInData)

}
// 拷贝到 data 下加载
private fun copyLibToData(context: Context, sourcePath: String): String {
    val soDir = File(context.filesDir, "so")
        if (!soDir.exists()) {
            soDir.mkdirs()
        }
    val soFile = File(soDir.absolutePath, soLibName)
        if (soFile.exists()) {
            soFile.delete()
        }
    // copy
    FileUtil.copy(File(sourcePath), soFile)
    return soFile.absolutePath
}
```





## 动态加载类

直接使用 DexClassLoader 即可。

```kotlin
val apkFile = File(apkAbsPath)
val odexDir = File(apkFile.parent, apk.name + "_odex")
val libDir = File(apkFile.parent, apk.name + "_lib")
val pluginClassLoader = DexClassLoader(
    apkAbsPath,
    odexDir.absolutePath,
    libDir.absolutePath,
    hostAppContext.classLoader
)
```



## 动态加载资源

创建 APK 对应的 Resources 对象

```kotlin
fun createResource(hostAppContext: Context, apkAbsPath: String):Resources? {
    val packageInfo =
    AppUtil.getPackageArchiveInfo(hostAppContext.applicationContext, apkAbsPath) ?: return null
    val applicationInfo = packageInfo.applicationInfo ?: ApplicationInfo().also {
        it.packageName = packageInfo.packageName
    }
    // 创建 resources
    // 需要先添加资源路径，才能正常的获取到资源
    applicationInfo.sourceDir = apkAbsPath
    applicationInfo.publicSourceDir = apkAbsPath
    return hostAppContext.packageManager.getResourcesForApplication(applicationInfo)
}
```



## 动态加载UI界面

需要处理的问题：

* Activity、Service等组件需要在Manifest文件中注册后才可以使用。由于无法修改Mainfest 导致无法启动插件中的Activity 等组件。
* Activity、Service等组件生命周期的管理。
* 插件Activity 无法访问 Res 资源。在应用中我们通过 `R.string.xxx`的方式从 Resources 中获取资源，对于动态加载的插件，无法通过 ID来访问res资源。

### 仅动态加载代码

不修改Manifest，也不更新资源，仅更新代码调整逻辑，主项目中预先存放所有的res资源，并在Manifest中声明好所有需要的组件。

采用 代码创建布局 或者 Fragment的方式更新UI。

适用于UI变化少的项目。

### 代理Activity

* 宿主 和 插件 需要接入一套共同的框架。
* 宿主 APK 先在Manifest 中注册一个 空壳的 ProxyActivity。
* 使用 ProxyActivity 来代理 插件的 中的Activity，转发生命周期。

存在问题，由于无法修改Manifest，所以需要Manifest配置的功能也无法实现  :

* 运行的实际都是 ProxyActivity，仅支持特定的Activity配置(LauncherMode)。
* 不支持静态广播。
* 无法新增权限。
* 需要使用特定的框架开发插件，并不是所有APK都能加载。

### 动态创建Activity

利用 运行时字节码操作 实现，例如 dexmaker（生成dex）、asmdex（生成class）。

* 宿主注册一个不存在的 DynamicActivity。
* 启动插件中的Activity时，动态生成一个DynamicActivity 并继承 目标类的所有功能，DynamicActivity和在宿主中提前注册的包名类名一致，从而就能正常启动Activity了。
  * 自定义ClassLoader，启动插件中的Activity 时，加载利用 dexmaker、asmdex 等工具 动态生成 DynamicActivity，替换目标Activity。
  * 也可以选择 动态代理 Instrumentation ，在 `execStartActivity()` 函数中 处理。

存在的问题  和 代理 Activity 类似。



### Compose 动态化？

Compose 界面布局 不涉及 xml，是由代码实现的，且除了MainActivity， 其他页面都可以使用 Compose实现，不涉及 Activity 的跳转。那么利用 compose 框架来做插件化，应该是有一定可行性的。



动态加载资源：换肤

动态加载类：热修复、功能调整

动态加载四大组件：新的业务模块



## 问题处理

### CLASS_ISPREVERIFIED问题

通过动态加载类后，运行加载类的时可能会报 preverified错误，主要是由于在将 dex 转化成 odex 的过程中，`DexVerify.cpp`会校验 class 和它直接引用到的类 是否在同一个dex中，若是 则会打上CLASS_ISPREVERIFIED标志，表示会被提前验证和优化。

* 假如类A及其引用的类都在同一个dex中，那么A会被标记CLASS_ISPREVERIFIED。

此时若我们的修复dex 调用了A，由于不再同一个dex中就会 发生 preverified 错误。

处理方式：

* Q-zone插桩：通过修改字节码，每个类的构造方法中引用单独dex中的HackCode.class，这样就使得不会被打上 `CLASS_ISPREVERIFIED` 标志，但会导致 preverify失效，损失性能。

* Tinker：采用全量合成的方式，将补丁类与引用类放在同一个dex中。

