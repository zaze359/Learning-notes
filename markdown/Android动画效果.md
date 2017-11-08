# Android动画效果

### 复古风格

``overridePendingTransition(enterAnim, exitAnim);``


### Android Material Animations

1. 平移

```
跟overridePendingTransition效果是一样的
ActivityOptionsCompat.makeCustomAnimation(Context context, int enterResId, int exitResId)
```

2. 放大过渡

```
将一个控件平滑的放大过渡到第二个activity，一般用于相册的具体照片的查看
ActivityOptionsCompat.makeScaleUpAnimation(View source,int startX, int startY, int startWidth, int startHeight)
```

3. makeThumbnailScaleUpAnimation

```
ActivityOptionsCompat.makeThumbnailScaleUpAnimation(View source,Bitmap thumbnail, int startX, int startY)
```

4. 平移过渡

```
平滑的将一个控件平移的过渡到第二个activity
ActivityOptionsCompat.makeSceneTransitionAnimation(Activity activity, View sharedElement, String sharedElementName)
```

5. 多个控件平移过渡

```
平滑的将多个控件平移的过渡到第二个activity
ActivityOptionsCompat.makeSceneTransitionAnimation(Activity activity,Pair<View, String>… sharedElements)
```