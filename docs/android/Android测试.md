# Anroid 测试

---

[TOC]



## 基础知识

在Android项目中存在两类测试：`androidTest`和`test`。

* `androidTest`：包含在真机或模拟器运行的测试。有集成测试（Integration test）、端到端测试（End-to-end test），以及仅靠 JVM 无法完成应用功能验证的其他测试。
* `test`：同java的单元测试（Unit test），可以直接在本地开发设备上运行。

![Tests can be either small, medium, or big.](./Android%E6%B5%8B%E8%AF%95.assets/test-scopes.png)



### 添加配置依赖

> [AndroidX Test](https://developer.android.google.cn/training/testing) 

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





### 单元测试语法

- **@Test**注解
表示一个测试用例方法

### jar

```bash
# 仍然在\Android-sdk\tools\目录下，运行命令：
android create uitest-project -n <name> -t <android-sdk-ID> -p <path>
# 比如：
android create uitest-project -n AutoRunner -t 6 -p e:\workspace\AutoRunner
# 上面的name就是将来生成的jar包的名字，可以自己定义，android-sdk-ID就是上面看到的6；path是Eclipse新建的工程的路径；运行命令后，将会在工程的根目录下生成build.xml文件。如果没生成，检查上面的步骤。
```

### 编译生成jar

```
    CMD进入项目的工程目录，然后运行ant build，将使用ant编译生成jar，成功将会提示：
    然后会在bin目录下生成jar文件。
```

### push并运行jar

```bash
    adb push <jar文件路径> data/local/tmp
    adb shell uiautomator runtest <jar文件名> -c <工程中的类名，包含包名>
    # 比如：
    adb push e:\workspace\AutoRunner\bin\AutoRunner.jar data/local/tmp
    adb shell uiautomator runtest AutoRunner.jar -c com.Runner
```



### SDK版本差异的适配

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

>  Guava 团队提供的一个名为 [Truth](https://google.github.io/truth/) 的流利断言库。

```groovy
testImplementation "com.google.truth:truth:1.1.3"
```

```kotlin
assertThat(object).hasFlags(FLAGS)
assertThat(object).doesNotHaveFlags(FLAGS)
assertThat(intent).hasData(URI)
assertThat(extras).string(string_key).equals(EXPECTED)
```







## 本地测试

添加依赖：

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

测试用例：

```kotlin
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class EmailValidatorTest {
  @Test fun emailValidator_CorrectEmailSimple_ReturnsTrue() {
    assertTrue(EmailValidator.isValidEmail("name@email.com"))
  }
}

```



## Mock使用方式

添加mock相关依赖：

```groovy
dependencies {
  // Optional -- Mockito framework
  testImplementation "org.mockito:mockito-core:$mockitoVersion"
  // Optional -- mockito-kotlin
  testImplementation "org.mockito.kotlin:mockito-kotlin:$mockitoKotlinVersion"
  // Optional -- Mockk framework
  testImplementation "io.mockk:mockk:$mockkVersion"
}
```

测试用例：

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

## Espresso

> [Espresso  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/testing/espresso)



```groovy
androidTestImplementation 'androidx.test.espresso:espresso-core:3.4.0'
```



Espresso的主要包括：

* **Espresso** ：查找视图交互入口。`onView()`、 `onData()`
* **ViewMatchers** ：一个匹配规则集合，如`withId()`、`withText()`等。传递给`onView()`使用。
* **ViewActions**：视图操作集合，例如`click()`。传递给`perform()`使用。
* **ViewAssertions**：一组断言集合，如`matches(isDisplayed())`，传递给`check()`应用断言。

### 查找视图

> onView是查找视图层级中是否存在符合的视图，所以查找到视图不一定处于当前可见状态。

```kotlin
// 多条件匹配
onView(allOf(withId(R.id.my_view), withText("Hello!")))
// not，排除指定规则的内容
onView(allOf(withId(R.id.my_view), not(withText("Unwanted"))))
```

>  检查适配器视图中的数据加载，例如ListView。所有项并未都加载到视图中.
>
> Espresso提供`onData()`方法处理。它会强制将所有元素放入到视图层级中。

```kotlin
onData(allOf(`is`(instanceOf(String::class.java)),
             `is`("Americano"))).perform(click())
    
```

### 操作视图

```kotlin
// 执行点击
onView(...).perform(click())
// 执行多项操作
onView(...).perform(typeText("Hello"), click())
// 滑动到视图位置，再操作
onView(...).perform(scrollTo(), click())
```

### 执行断言

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



### Espresso-Intents

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







### Espresso 备忘单

> 官方提供的Espresso 备忘单

![onView()、onData()、intended() 和 intending() 可用方法的列表](./Android%E6%B5%8B%E8%AF%95.assets/espresso-cheatsheet.png)



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





## Robolectric

可以使用 [Robolectric](http://robolectric.org/)在由 JVM 驱动的开发计算机上运行的测试，而无需使用模拟器。Robolectric 支持 Android 平台的以下几个方面：

- 组件生命周期
- 事件循环
- 所有资源

```groovy
dependencies {
  // Optional -- Robolectric environment
  testImplementation "androidx.test:core:$androidXTestVersion"
}
```



## UI Automator 

> 可以与设备上的可见元素进行互动，而不管获得焦点的是哪个 Activity 或 Fragment。

官方推荐仅当应用需要和系统界面或外部应用交互时才使用。当交互对象发生变化时需要同步适配。

## 参考资料

[在 Android 平台上测试应用  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/training/testing)
