# Android中的页面导航

[Jetpack 导航 (android.com)](https://developer.android.com/codelabs/android-navigation#0)



选项菜单

onCreateOptionsMenu

onOptionsItemSelected



底部导航

BottomNavigationView



## 1. NavigationView


### 1.1 开始使用

![image_1do1lq7ig1p6i64q1r8v1ak317fj9.png-15.9kB][1]

- activity_main
```xml
<com.google.android.material.navigation.NavigationView
    android:id="@+id/mainNav"
    android:layout_width="wrap_content"
    android:layout_height="match_parent"
    android:layout_gravity="start"
    app:headerLayout="@layout/header_layout"
    app:menu="@menu/drawer_actions" />
```

- header_layout.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="192dp"
    android:background="?attr/colorPrimaryDark"
    android:padding="16dp"
    android:theme="@style/ThemeOverlay.AppCompat.Dark">

    <ImageView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="center"
        android:src="@mipmap/ic_launcher" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom|center_horizontal"
        android:text="Developer"
        android:textAppearance="@style/TextAppearance.AppCompat.Body1" />

</FrameLayout>

```

```xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/drawer_github_menu_item"
        android:icon="@mipmap/ic_github_circle_white_24dp"
        android:title="@string/github_link" />

    <item
        android:id="@+id/drawer_setting_menu_item"
        android:icon="@mipmap/ic_settings_black_24dp"
        android:title="@string/setting" />

    <item
        android:id="@+id/drawer_clear_menu_item"
        android:icon="@mipmap/ic_settings_black_24dp"
        android:title="清除数据" />
</menu>
```



## 2. BottomNavigationBar(导航栏)

### 2.1. 依赖
```groovy
implementation "com.google.android.material:material:1.0.0"
```

### 2.2. 重要属性介绍

#### 2.2.1 Mode

| 类型          | 说明                                                         |
| :------------ | :----------------------------------------------------------- |
| MODE_DEFAUL   | Item <=3 就会使用MODE_FIXED模式，否则使用MODE_SHIFTING模式   |
| MODE_FIXED    | 固定大小;<br/>未选中的Item会显示文字，没有切换动画;<br/>宽度=总宽度/action个数;<br/>最大宽度: 168dp;<br/>最小宽度: 80dp;<br/>Padding：6dp（8dp）、10dp、12dp;<br/>字体大小：12sp、14sp |
| MODE_SHIFTING | 不固定大小;<br/>有切换动画;<br/>选中的会显示文字,未选中的Item不会显示文字 |

#### 2.2.2 Background Style

- 修改背景色
```java
bottomNavigationBar.setMode(BottomNavigationBar.MODE_FIXED);
bottomNavigationBar.setBackgroundStyle(BottomNavigationBar.BACKGROUND_STYLE_STATIC);
bottomNavigationBar.setBarBackgroundColor(R.color.black);
```

- BACKGROUND_STYLE_DEFAULT

  ```
  - MODE_FIXED : BACKGROUND_STYLE_STATIC
  - MODE_SHIFTING : BACKGROUND_STYLE_RIPPLE
  ```
- BACKGROUND_STYLE_STATIC

  - 点击的时候没有水波纹效果

  - 背景色默认是白色：通过 `setBarBackgroundColor()` 方法修改背景色

- BACKGROUND_STYLE_RIPPLE
  - 点击的时候有水波纹效果。
  - 背景色：通过  `setActiveColorResource()` 方法修改背景色。
#### 2.2.3 Badge

> 一般用作消息提醒
> BottomNavigationItem 添加 Badge

------

![image_1do1j2lt21fkribd13q61i2617vc9.png-14.4kB][2]


### 2.3 开始使用

- activity_main.xml
```xml
<com.google.android.material.bottomnavigation.BottomNavigationView
    android:id="@+id/mainBottomNav"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_alignParentBottom="true"
    app:labelVisibilityMode="labeled"
    app:menu="@menu/main_nav_bottom" />
```

- main_nav_bottom.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/action_home"
        android:enabled="true"
        android:icon="@mipmap/ic_home_white_24dp"
        android:title="@string/home" />
    <item
        android:id="@+id/action_reader"
        android:enabled="true"
        android:icon="@mipmap/ic_book_white_24dp"
        android:title="@string/reader" />
    <item
        android:id="@+id/action_music"
        android:enabled="true"
        android:icon="@mipmap/music_note_white_24dp"
        android:title="@string/music" />
    <item
        android:id="@+id/action_game"
        android:enabled="true"
        android:icon="@mipmap/ic_videogame_asset_white_24dp"
        android:title="@string/game" />
</menu>

```

- MainActivity.kt
```kotlin
private fun initNavigationBar() {
    mainBottomNav.run {
        setOnNavigationItemReselectedListener {
            ZLog.i(ZTag.TAG_DEBUG, "ItemReselected : ${it.itemId}")
        }
        setOnNavigationItemSelectedListener {
            ZLog.i(ZTag.TAG_DEBUG, "ItemSelected : ${it.itemId}")
            true
        }
        selectedItemId = xxId
    }
}
```



## NavHostFragment

### Fragment重建问题

需要注意的是Fragment直接 **导航跳转时Fragment将会重新创建**, app上的表现可能为跳转卡顿，重复请求等。主要是Google官方实现方式为 `new and replace`。

相关代码：

```java
// FragmentNavigator.navigate()
public NavDestination navigate(xxxxxx){
	...
    // 新建一个Fragment
        final Fragment frag = instantiateFragment(mContext, mFragmentManager,
                className, args);
        frag.setArguments(args);
        final FragmentTransaction ft = mFragmentManager.beginTransaction();
        int enterAnim = navOptions != null ? navOptions.getEnterAnim() : -1;
        int exitAnim = navOptions != null ? navOptions.getExitAnim() : -1;
        int popEnterAnim = navOptions != null ? navOptions.getPopEnterAnim() : -1;
        int popExitAnim = navOptions != null ? navOptions.getPopExitAnim() : -1;
        if (enterAnim != -1 || exitAnim != -1 || popEnterAnim != -1 || popExitAnim != -1) {
            enterAnim = enterAnim != -1 ? enterAnim : 0;
            exitAnim = exitAnim != -1 ? exitAnim : 0;
            popEnterAnim = popEnterAnim != -1 ? popEnterAnim : 0;
            popExitAnim = popExitAnim != -1 ? popExitAnim : 0;
            ft.setCustomAnimations(enterAnim, exitAnim, popEnterAnim, popExitAnim);
        }
		// relpace
        ft.replace(mContainerId, frag);
	...
}
```

> 解决方案

* 通过自定义重写FragmentNavigator的解决方案。
  * 将内部改为hide() 和 show()的方式。不过此方式将会导致同一个页面永远只有一个实例，无法重复创建。比如 `AFragment -> BFragment#1 -> BFragment#2 -> BFragment#3`， 页面上展示的内容不同, 此场景下BFragment#3无法导航回BFragment#2, 而是直接直接回到了AFragment。

* 另一种方式就是**使用ViewModel等方式将数据和视图分离，保存好数据，并优化Fragment的渲染时间**。

## safe args



1. 打开项目 build.gradle

   ```groovy
   dependencies {
           classpath "androidx.navigation:navigation-safe-args-gradle-plugin:$navigationVersion"
       //...
       }
   ```

2. 打开 ``app/build.gralde``

   ```groovy
   apply plugin: 'com.android.application'
   apply plugin: 'kotlin-android'
   apply plugin: 'androidx.navigation.safeargs.kotlin'
   
   android {
      //...
   }
   ```

   

[1]: http://static.zybuluo.com/zaze/a5vsslsv3de6wso1uvpersh9/image_1do1lq7ig1p6i64q1r8v1ak317fj9.png
[2]: http://static.zybuluo.com/zaze/y91aywbbx9twv6lm2b96nkp0/image_1do1j2lt21fkribd13q61i2617vc9.png