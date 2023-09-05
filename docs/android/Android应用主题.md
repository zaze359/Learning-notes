# Android应用主题

[样式和主题背景  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/ui/look-and-feel/themes?hl=zh-cn)

[支持刘海屏  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/display-cutout?hl=zh-cn#never_render_content_in_the_display_cutout_area)



## Google Material设计

[Material 组件和布局  | Jetpack Compose  | Android Developers](https://developer.android.com/jetpack/compose/layouts/material)

[Material Design](https://m3.material.io/)

[颜色 - 样式 - Material design 中文文档，指南，翻译 (mdui.org)](https://www.mdui.org/design/style/color.html#color-usability)

### Material 色值

[🎨 Material Design Colors, Color Palette | Material UI](https://materialui.co/colors)

就是指项目中定义的 `purple_200`、`purple_A200`等类似的色值，[200] 指饱和度

谷歌建议用 [500] 作为Primary color，其它的颜色作为Accent color（强调色）。

* [*00]：推荐用于 Primary 系，建议用 [500] 作为Primary color，500是基础值，数值减小就是变浅，变大就是加深
* [A*00] ：推荐用于 secondary系（强调色**A**ccent）

```xml
<color name="purple_200">#FFBB86FC</color>
<color name="purple_500">#FF6200EE</color>
<color name="purple_700">#FF3700B3</color>
```

### 属性

* Primary：主色，应用中出现最频繁的颜色。
* OnPrimary：Primary上内容（图片、文字等）的色调。
* Secondary：次级色，和 Primary互补，作为交互色。
* Accent：强调色。

![image-20230825213455974](./Android%E5%BA%94%E7%94%A8%E4%B8%BB%E9%A2%98.assets/image-20230825213455974.png)

![image-20230823213039436](./Android%E5%BA%94%E7%94%A8%E4%B8%BB%E9%A2%98.assets/image-20230823213039436.png)

| 属性                         |                                                              |                                  |
| ---------------------------- | ------------------------------------------------------------ | -------------------------------- |
|                              |                                                              |                                  |
| colorPrimary                 | 主色调，AppBarLayout 等UI 元素的颜色                         |                                  |
| colorOnPrimary               | 和Primary 对应，Primary上元素的颜色。                        | Primary 上的图片、文字等。       |
| colorPrimaryDark             | 状态栏 颜色。                                                |                                  |
| colorPrimaryVariant          | 状态栏的阴影色。                                             |                                  |
| colorAccent                  | 强调色。                                                     | CheckBox、EditText选中时的颜色。 |
|                              |                                                              |                                  |
| colorSecondary               | 次级色，和 Primary互补，作为交互色。                         | Button、CheckBox、EditText等     |
| colorOnSecondary             | 和 colorSecondary对应，colorSecondary上内容的颜色。          |                                  |
| colorSecondaryVariant        |                                                              |                                  |
|                              |                                                              |                                  |
| colorControlNormal           | 组件的默认颜色。CheckBox、RadioButton等控件。                |                                  |
| colorBackground              | 背景色                                                       |                                  |
| colorForeground              | 前景色                                                       |                                  |
| navigationBarColor           | 导航栏颜色                                                   |                                  |
| textColorLink                | 链接(link, herf)的颜色                                       |                                  |
| `android:textColorHint`      | 提示文字的颜色                                               |                                  |
| `android:textColorPrimary`   | 主要文字颜色                                                 |                                  |
| `android:textColorSecondary` | 次要文字颜色，ActionBar SubTitle、EditText的光标下划线颜色等 。 |                                  |
|                              |                                                              |                                  |
|                              |                                                              |                                  |
|                              | 通用型文本颜色。浅色 -> 黑色，深色 ->白色                    |                                  |
| colorControlNormal           | 通用图标颜色                                                 |                                  |
| colorSurface                 | 表明颜色。页面背景、CardView背景等。                         |                                  |
| colorOnSurface               |                                                              |                                  |



## 适配深色主题

[深色主题背景  | Android 开发者  | Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/ui/look-and-feel/darktheme?hl=zh-cn)

```xml
<style name="AppTheme" parent="Theme.MaterialComponents.DayNight">
```





## fitsSystemWindows

若为 true，则将View的大小 增加上 系统窗口的大小（例如状态栏的高度、输入法弹窗的高度等），当作padding使用，常用于实现沉浸式效果。

原理就是控件内部 检测到属性 `fitsSystemWindows=true` 时会调整控件大小，若控件内部没有处理则不支持，因此并不是所有的View都支持这个属性的。

* FrameLayout、LinearLayout这些控件是不支持的。
* CoordinatorLayout、AppBarLayout等控件支持。

> 摘录 部分 AppBarLayout 代码
>
> 测量时 根据 fitsSystemWindows 获取 系统顶部高度，扩展到高度上，相当于padding的作用。

```java
  @Override
  protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
    super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    final int heightMode = MeasureSpec.getMode(heightMeasureSpec);
    if (heightMode != MeasureSpec.EXACTLY
        && ViewCompat.getFitsSystemWindows(this) // fitsSystemWindows=true
        && shouldOffsetFirstChild()) {
      int newHeight = getMeasuredHeight();
      switch (heightMode) {
        case MeasureSpec.AT_MOST:
          // For AT_MOST, we need to clamp our desired height with the max height
          newHeight =
              clamp(
                  getMeasuredHeight() + getTopInset(), 0, MeasureSpec.getSize(heightMeasureSpec));
          break;
        case MeasureSpec.UNSPECIFIED:
          // For UNSPECIFIED we can use any height so just add the top inset
          newHeight += getTopInset();
          break;
        case MeasureSpec.EXACTLY:
        default: // fall out
      }
      setMeasuredDimension(getMeasuredWidth(), newHeight);
    }

    invalidateScrollRanges();
  }
```

## 软键盘显示配置

通过配置 `android:windowSoftInputMode` 来改变软键盘的显示形式。

| flag               | 说明                                                         |      |
| ------------------ | ------------------------------------------------------------ | ---- |
| stateUnspecified   | 默认行为，由当前使用的主题决定。                             |      |
| stateUnChanged     | 页面打开时，保持之前页面的键盘状态。                         |      |
| stateHidden        | 页面打开时默认隐藏，若页面已打开重新返回时则不一定是隐藏的。 |      |
| stateAlwaysHidden  | stateHidden的增强，无论是什么方式进入页面，键盘都隐藏。      |      |
| stateVisible       | 页面打开时默认打开，但是从栈返回时不一定。                   |      |
| stateAlwaysVisible | stateVisible的增强，无论是什么方式进入页面，键盘都打开。     |      |
| -                  |                                                              |      |
| adjustUnspecified  | 默认行为。存在滚动布局：adjustResize; 否则：adjuestPen       |      |
| adjustResize       | 会改变页面大小，顶部不变，底部被抬高腾出空间显示输入法。键盘不会覆盖住布局内容。 |      |
| adjustPan          | 不改变页面大小，通过移动布局的方式腾出空间显示输入法。键盘会覆盖住布局内容。 |      |
| adjustNothing      | 键盘直接盖在布局上面，会遮挡住布局内容。                     |      |

