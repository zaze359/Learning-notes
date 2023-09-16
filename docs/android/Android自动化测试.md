# Android 自动化测试

---

[TOC]

## 基本的测试类型

> 大型保证整体流程
>
> 中型保证部分流程
>
> 小型保证单个功能
>
> 新应用：小 -> 中 -> 大
>
> 旧应用：先  大 -> 中 -> 小，保证过渡，后续采用 小 -> 中 -> 大流程。

[AndroidX Test](https://developer.android.google.cn/training/testing) 

测试金字塔的级别：

* **小型测试-单元测试（Unit test）70%**：用于验证应用行为，**一次验证一个类**。
* **中型测试-集成测试（Integration test）20%**：用于验证**模块内堆栈级别之间的互动或相关模块之间的互动**。
* **大型测试-端到端测试（End-to-end test）10%**：端到端测试主要用于验证跨越了应用的多个模块的**用户操作流程**。
* 以及仅靠 JVM 无法完成应用功能验证的其他测试。

他们的关系如下图（来自Google官方）：

![Tests can be either small, medium, or big.](./Android%E8%87%AA%E5%8A%A8%E5%8C%96%E6%B5%8B%E8%AF%95.assets/test-scopes.png)



## 小型测试-单元测试

用于验证应用行为，一次验证一个类。通过运行小型测试来测试应用的每个单元，保证单元功能的正常。

### 测试环境

#### 目录结构

在Android项目中存在两类测试：`androidTest`和`test`。

* `androidTest`：在真机或模拟器运行的测试用例。
* `test`：同java的单元测试（Unit test），可以直接在本地开发设备上运行的用例。

![image-20230214143741429](./Android%E8%87%AA%E5%8A%A8%E5%8C%96%E6%B5%8B%E8%AF%95.assets/image-20230214143741429.png)



#### 添加配置依赖

> 一般项目创建时默认就配置好了

```groovy
android {
    ....
    defaultConfig {
    	....
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }
    testOptions {
        unitTests {
            // 测试依赖于资源时开启
            includeAndroidResources = true
            // 处理错误：Error: "Method ... not mocked"
            unitTests.returnDefaultValues = true
        }
    }
    ....
}

dependencies {
    ....
    testImplementation "junit:junit:$junitVersion"

    androidTestImplementation 'androidx.test:runner:1.4.0'
    androidTestImplementation 'androidx.test.ext:junit:1.1.3'
    androidTestImplementation 'androidx.test.espresso:espresso-intents:3.4.0'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.4.0'
}
```



### 基础语法

#### @Test：测试用例

表示一个测试用例方法

```kotlin
@Test
fun testButtonClickOnOreoAndLower() {
    // ...
}
```

#### @SdkSuppress：SDK适配

```kotlin
@Test
@SdkSuppress(maxSdkVersion = 27)
fun testButtonClickOnOreoAndLower() {
    // ...
}

@Test
@SdkSuppress(minSdkVersion = 28)
fun testButtonClickOnPieAndHigher() {
    // ...
}
```

#### assert：断言

```kotlin
// 断言值
assertEquals(0, 0)

val result = intArrayOf(1, 2, 3, 4, 5, 6)
// 断言内容而不是对象
assertContentEquals(intArrayOf(1, 2, 3, 4, 5, 6), result)

```



### 执行测试

![image-20230214165340338](./Android%E8%87%AA%E5%8A%A8%E5%8C%96%E6%B5%8B%E8%AF%95.assets/image-20230214165340338.png)

也可以使用gradle 脚本运行：

```shell
# 运行 test 目录下的单元测试
./gradlew test
```

### 测试报告

测试报告将输出在 ``/build/reports/tests``、``/build/reports/androidTests``中。

![image-20230214192122403](./Android%E8%87%AA%E5%8A%A8%E5%8C%96%E6%B5%8B%E8%AF%95.assets/image-20230214192122403.png)

可以查看每个用例具体的执行情况和执行时间。

![image-20230214192046503](./Android%E8%87%AA%E5%8A%A8%E5%8C%96%E6%B5%8B%E8%AF%95.assets/image-20230214192046503.png)

### 打包成jar

```bash
# 仍然在\Android-sdk\tools\目录下，运行命令：
android create uitest-project -n <name> -t <android-sdk-ID> -p <path>

# 比如：name就是将来生成的jar包的名字，可以自己定义，android-sdk-ID 就是上面看到的6；path是Eclipse新建的工程的路径；运行命令后，将会在工程的根目录下生成build.xml文件。如果没生成，检查上面的步骤。
android create uitest-project -n AutoRunner -t 6 -p e:\workspace\AutoRunner
```

#### 编译生成jar

CMD进入项目的工程目录，然后运行ant build，将使用ant编译生成jar，成功将会提示。然后会在bin目录下生成jar文件。

#### push并运行jar

```shell
adb push <jar文件路径> data/local/tmp
adb shell uiautomator runtest <jar文件名> -c <工程中的类名，包含包名>
# 比如：
adb push e:\workspace\AutoRunner\bin\AutoRunner.jar data/local/tmp
adb shell uiautomator runtest AutoRunner.jar -c com.Runner
```



### Rules

> rule库提供了一系列类，帮助我们测试。
>
> `androidTestImplementation 'androidx.test:rules:1.1.0'`

```kotlin
// 测试Service
@get:Rule
val serviceRule = ServiceTestRule()

// 测试Intent
@get:Rule
val intentsTestRule = IntentsTestRule(MyActivity::class.java)

// 测试Activity生命周期
@get:Rule var activityScenarioRule = activityScenarioRule<MyActivity>()
```



### Truth

>  Guava 团队提供的一个名为 [Truth](https://google.github.io/truth/) 的 断言库。

```groovy
testImplementation "com.google.truth:truth:1.1.3"
```

```kotlin
assertThat(object).hasFlags(FLAGS)
assertThat(object).doesNotHaveFlags(FLAGS)
assertThat(intent).hasData(URI)
assertThat(extras).string(string_key).equals(EXPECTED)
```



## 中型测试-集成测试

除了必要的单元测试之外，还需要进行集成测试，它用于验证模块内堆栈级别之间的互动或相关模块之间的互动。从模块级别来验证应用的行为是否正常。

* 视图的交互

常用的框架有 Espresso、Robolectric。



### Espresso

> [Espresso  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/testing/espresso)

Espresso 是 Google 官方提供的界面测试框架。它提供的 API 能方便地进行元素的定位、执行操作和断言等操作。

需要添加一下依赖：

```groovy
// 核心和基本的 View 匹配器、操作和断言
androidTestImplementation 'androidx.test.espresso:espresso-core:3.4.0'
// 其他参考官网
```

Espresso的主要包括：

* **Espresso** ：查找视图交互入口。`onView()`、 `onData()`
* **ViewMatchers** ：一个匹配规则集合，如`withId()`、`withText()`等。传递给`onView()`使用。
* **ViewActions**：视图操作集合，例如`click()`。传递给`perform()`使用。
* **ViewAssertions**：一组断言集合，如`matches(isDisplayed())`，传递给`check()`应用断言。

#### Espresso基本测试流程

1. **查找视图：onView()**

   > onView是查找视图层级中是否存在符合的视图，所以查找到视图不一定处于当前可见状态。

   ```kotlin
   // 多条件匹配
   onView(allOf(withId(R.id.my_view), withText("Hello!")))
   // not，排除指定规则的内容
   onView(allOf(withId(R.id.my_view), not(withText("Unwanted"))))
   ```

   >  检查适配器视图中的数据加载，例如ListView。所有项并未都加载到视图中.
   >
   >  Espresso提供`onData()`方法处理。它会强制将所有元素放入到视图层级中。

   ```kotlin
   onData(allOf(`is`(instanceOf(String::class.java)),
                `is`("Americano"))).perform(click())
       
   ```

2. **操作视图：perform()**

   > 查找定位到具体的元素后，使用perform() 来操作 视图元素。

   ```kotlin
   // 执行点击
   onView(...).perform(click())
   // 执行多项操作
   onView(...).perform(typeText("Hello"), click())
   // 滑动到视图位置，再操作
   onView(...).perform(scrollTo(), click())
   ```

3. **执行断言：check()**

   >  matches 断言当前选定视图的状态。

   ```kotlin
   // 断言当前视图中包含"Hello!"
   onView(...).check(matches(withText("Hello!")))
   ```

   > 注意区分 `断言未显示某个视图` 与 `断言视图层次结构中不存在某个视图之间` 的区别。

   ```kotlin
   // 断言包含"Hello!"的视图是可见的
   onView(allOf(withId(...), withText("Hello!"))).check(matches(isDisplayed()))
       
   ```

   

#### Espresso-Intents

> 用于对封闭测试的 intent 进行验证和打桩的扩展

添加依赖：

```groovy
androidTestImplementation 'androidx.test.espresso:espresso-intents:3.1.0'
androidTestImplementation 'androidx.test:runner:1.1.0'
androidTestImplementation 'androidx.test:rules:1.1.0'
androidTestImplementation 'androidx.test.espresso:espresso-core:3.1.0'
```

指定规则：

```kotlin
@get:Rule
val intentsTestRule = IntentsTestRule(MyActivity::class.java)
```

intent 验证：

```kotlin
// 验证内容
assertThat(intent).hasAction(Intent.ACTION_VIEW)
assertThat(intent).categories().containsExactly(Intent.CATEGORY_BROWSABLE)
assertThat(intent).hasData(Uri.parse("www.google.com"))
assertThat(intent).extras().containsKey("key1")
assertThat(intent).extras().string("key1").isEqualTo("value1")
assertThat(intent).extras().containsKey("key2")
assertThat(intent).extras().string("key2").isEqualTo("value2")
```

> 测试验证当用户在被测应用中 启动“contacts”Activity 时，是否会显示相应的联系人电话号码。
>
> `intending()`用于打桩。

```kotlin
@Test fun activityResult_DisplaysContactsPhoneNumber() {
    // 构建返回结果
    val resultData = Intent()
    val phoneNumber = "123-345-6789"
    resultData.putExtra("phone", phone	Number)
    val result = Instrumentation.ActivityResult(Activity.RESULT_OK, resultData)
    
    // 当发现给"com.android.contacts"发送Intent的时，返回我们构建结果
    intending(toPackage("com.android.contacts")).respondWith(result)

    // 用户操作，触发`startActivityForResult()` 打开contacts。
    onView(withId(R.id.pickButton)).perform(click())
    
    // 验证 发送给"com.android.phone"的intent是否被发送
	// intended(toPackage("com.android.phone"))
    
    // 验证返回结果
    onView(withId(R.id.phoneNumber)).check(matches(withText(phoneNumber)))
}
    
```



#### Espresso 备忘单

> 官方提供的Espresso 备忘单

![onView()、onData()、intended() 和 intending() 可用方法的列表](./Android%E8%87%AA%E5%8A%A8%E5%8C%96%E6%B5%8B%E8%AF%95.assets/espresso-cheatsheet.png)



### Robolectric

可以使用 [Robolectric](http://robolectric.org/) 在由 JVM 驱动的开发计算机上运行的测试，而**无需使用真机或模拟器**。Robolectric 支持 Android 平台的以下几个方面：

- 组件生命周期
- 事件循环
- 所有资源

```groovy
dependencies {
  // Optional -- Robolectric environment
  testImplementation "androidx.test:core:$androidXTestVersion"
}
```



## 大型测试-端到端测试

端到端测试主要用于验证跨越了应用的多个模块的用户操作流程。针对的是 **跨应用**的复杂场景。常用的框架有 `UI Automator`。

### UI Automator 

> 官方推荐仅当应用需要和系统界面或外部应用交互时才使用。
>
> 交互应用升级发生发生变化时需要同步适配修正测试。

UI Automator 是一个界面测试框架，它可以与设备上的**可见元素进行互动**，而不管获得焦点的是哪个 Activity 或 Fragment。适用于黑盒自动化测试，不依赖于应用的内部实现。

* 打开设置。
* 返回桌面
* 启动应用
* .....

#### 添加依赖

```groovy
dependencies {
    ...
        androidTestImplementation 'androidx.test.uiautomator:uiautomator:2.2.0'
}
```

#### 测试类

需要添加 `@RunWith(AndroidJUnit4.class)` 注解。

* 使用 `UiDevice.getInstance` 初始化 `UiDevice`。

  ```kotlin
  uiDevice = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
  ```

* 调用 `findObject()` 获取界面组件。

  ```kotlin
  
  ```

#### 常用API

|                              |                    |      |
| ---------------------------- | ------------------ | ---- |
| uiDevice.pressHome()         | 返回桌面           |      |
| uiDevice.launcherPackageName | 获取启动器的包名。 |      |
|                              |                    |      |

```kotlin
@RunWith(AndroidJUnit4::class)
class AppTest {
    private val packageName = "com.zaze.demo"

    lateinit var uiDevice: UiDevice

    @Before
    fun startApp() {
        val context: Context = ApplicationProvider.getApplicationContext()
        uiDevice = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
        // 回到桌面
        uiDevice.pressHome()
        val launcher = uiDevice.launcherPackageName
        println("launcherPackageName: $launcher")
        // 等待
        uiDevice.wait(Until.hasObject(By.pkg(launcher).depth(0)), 10_000);
        // 启动应用
        val intent: Intent? = context.packageManager
            .getLaunchIntentForPackage(packageName)
            ?.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK)
        context.startActivity(intent)
        // 等待启动完成
        uiDevice.wait(Until.hasObject(By.pkg(packageName).depth(0)), 10_000);
    }

    @Test
    fun doSomeThing() {
        uiDevice.findObject(By.res(packageName, "mainTestBtn"))?.text = "测试修改"
    }

}
```



### uiautomatorviewer 查看界面属性

> Mac

```shell
cd ~/Library/Android/sdk/tools/bin

uiautomatorviewer
```

报错: 

```shell
-Djava.ext.dirs=/Users/zhaozhen/Library/Android/sdk/tools/lib/x86_64:/Users/zhaozhen/Library/Android/sdk/tools/lib is not supported.  Use -classpath instead.
Error: Could not create the Java Virtual Machine.
Error: A fatal exception has occurred. Program will exit.
```

1. jdk降为 1.8

```shell
# 创建 runuiautomatorviewer.sh
vi runuiautomatorviewer.sh

#######################
# 填写以下内容
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_231.jdk/Contents/Home
export PATH=${PATH}:$JAVA_HOME:${JAVA_HOME}/bin
./uiautomatorviewer
#######################

# 执行
./runuiautomatorviewer.sh
```

2. 若上述命令 启动后卡死，则clone [cmlanche/uiautomatorviewer-standalone: UIAutomatorViewer独立包工程 (github.com)](https://github.com/cmlanche/uiautomatorviewer-standalone)

   ```shell
   # clone 
   git clone git@github.com:cmlanche/uiautomatorviewer-standalone.git
   
   # 安装 mvn
   brew install maven
   
   # 打包
   mvn clean package
   # copy jar 到 adb的同级目录
   cp target/uiautomatorviewer-standalone-1.1-all.jar ~/Library/Android/sdk/platform-tools/.
   # 启动
   cd ~/Library/Android/sdk/platform-tools/
   java -XstartOnFirstThread -jar ./uiautomatorviewer-standalone-1.1-all.jar
   ```

   

> Window

```shell
# `..\Android\Sdk\tools\bin\uiautomatorviewer`
# windows
./uiautomatorviewer.bat
```



点击 **Device Screenshot**，将会对当前界面截屏。

![image-20230214162351551](./Android%E8%87%AA%E5%8A%A8%E5%8C%96%E6%B5%8B%E8%AF%95.assets/image-20230214162351551.png)





## 测试替身（Test Double）

当测试应用 依赖从网络上获取数据或者依赖其他第三方服务时，为了排除网络和其他服务的影响，可以利用测试替身来替换依赖项。

测试替身不仅可以隔离依赖，还可以加速测试流程、模拟特殊场景等，使得测试流程更加高效全面。

常见的测试替身类型有：

| 类型  | 说明                                                         | 框架                      |
| ----- | ------------------------------------------------------------ | ------------------------- |
| Dummy | 仅填充参数，帮助通过编译，不在测试中起任何作用。             | 自己模拟即可              |
| Stub  | 插桩数据，准备好返回数据，在测试中使用测试数据代替真实的数据。 | Mockito、mockk等          |
| Spy   | 在 Stub的基础上，增加了一些信息记录。如调用次数、调用顺序、入参等。 | Mockito、mockk等          |
| Mock  | 按照一定期望 来构建特定的测试对象，验证交互是否符合预期。如测试调用顺序、调用次数等是否符合期望。结合 Spy，Stub的功能。 | Mockito、mockk等          |
| Fake  | 伪造一个和真实对象等效的具体实现，但是更简单、轻量。如在本地实现一个远端的简易服务来代替真实服务。 | Retrofit的 MockServer等。 |



## Mock

按照期望构建特定的测试对象，并替换依赖项。可用于测试调用顺序、调用次数等是否符合期望。

例如Mock一个类的实现，然后进行 Stub 来模拟数据。

### 添加mock依赖

```groovy
dependencies {
  // Required -- JUnit 4 framework
  testImplementation "junit:junit:$jUnitVersion"

    
  // Optional -- Robolectric environment
  testImplementation "androidx.test:core:$androidXTestVersion"
  // Optional -- Mockito framework
  testImplementation "org.mockito:mockito-core:$mockitoVersion"
  // Optional -- mockito-kotlin
  testImplementation "org.mockito.kotlin:mockito-kotlin:$mockitoKotlinVersion"
  // Optional -- Mockk framework
  testImplementation "io.mockk:mockk:$mockkVersion"
}
```

### 测试用例

```kotlin
import android.content.Context
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.junit.MockitoJUnitRunner
import org.mockito.kotlin.doReturn
import org.mockito.kotlin.mock

private const val FAKE_STRING = "HELLO WORLD"

// 使用mock测试
@RunWith(MockitoJUnitRunner::class)
class MockedContextTest {

  // 表示mock对象
  @Mock
  private lateinit var mockContext: Context

  @Test
  fun readStringFromContext_LocalizedString() {
    // Given a mocked Context injected into the object under test...
    val mockContext = mock<Context> {
        on { getString(R.string.name_label) } doReturn FAKE_STRING
    }

    val myObjectUnderTest = ClassUnderTest(mockContext)

    // ...when the string is returned from the object under test...
    val result: String = myObjectUnderTest.getName()

    // ...then the result should be the expected one.
    assertEquals(result, FAKE_STRING)
  }
}
```





## 插桩测试

* 主线程：界面交互和 Activity 生命周期事件发生在此线程上。
* 插桩线程：大多数测试都在此线程上运行。

使用`@UiThreadTest`可以使测试运行在主线程上。



## 测试Service

```kotlin
// 指定规则
@get:Rule
val serviceRule = ServiceTestRule()

@Test
@Throws(TimeoutException::class)
fun testWithBoundService() {
  // Create the service Intent.
  val serviceIntent = Intent(
      ApplicationProvider.getApplicationContext<Context>(),
      LocalService::class.java
  ).apply {
    // Data can be passed to the service via the Intent.
    putExtra(SEED_KEY, 42L)
  }

  // Bind the service and grab a reference to the binder.
  val binder: IBinder = serviceRule.bindService(serviceIntent)

  // Get the reference to the service, or you can call
  // public methods on the binder directly.
  val service: LocalService = (binder as LocalService.LocalBinder).getService()

  // Verify that the service is working correctly.
  assertThat(service.getRandomInt(), `is`(any(Int::class.java)))
}

```









## 参考资料

[在 Android 平台上测试应用  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/testing)
