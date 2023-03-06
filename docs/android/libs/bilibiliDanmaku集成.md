# bilibiliDanmaku集成

[bilibili/DanmakuFlameMaster: Android开源弹幕引擎·烈焰弹幕使 ～ (github.com)](https://github.com/bilibili/DanmakuFlameMaster)

## 使用总结

### 1. 声明DanmakuView

承载弹幕的主体

```xml
    <master.flame.danmaku.ui.widget.DanmakuView
        android:id="@+id/sv_danmaku"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
```

```java
IDanmakuView mDanmakuView = (IDanmakuView) findViewById(R.id.sv_danmaku);
```



### 2. 配置DanmakuContext

弹幕上下文设置一些基础的配置, 

```java
mContext = DanmakuContext.create();
mContext.setDanmakuStyle(IDisplayer.DANMAKU_STYLE_STROKEN, 3)
        .setDuplicateMergingEnabled(false) // 设置是否启用合并重复弹幕
        .setScrollSpeedFactor(1.2f) // 设置弹幕滚动速度系数,只对滚动弹幕有效
        .setScaleTextSize(1.2f)
        .setCacheStuffer(new SpannedCacheStuffer(), mCacheStufferAdapter) // 图文混排使用SpannedCacheStuffer
//      .setCacheStuffer(new BackgroundCacheStuffer(), mCacheStufferAdapter)  // 绘制背景使用BackgroundCacheStuffer
        .setMaximumLines(maxLinesPair)
        .preventOverlapping(overlappingEnablePair).setDanmakuMargin(40);	
```

### 3. 设置回调监听

```java
mDanmakuView.setCallback(new DrawHandler.Callback() {
    @Override
    public void updateTimer(DanmakuTimer timer) {
    }

    @Override
    public void drawingFinished() {

    }

    @Override
    public void danmakuShown(BaseDanmaku danmaku) {
        Log.d("DFM", "danmakuShown(): text=" + danmaku.text);
    }

    @Override
    public void prepared() {
        mDanmakuView.start();
    }
});
mDanmakuView.setOnDanmakuClickListener(new IDanmakuView.OnDanmakuClickListener() {

    @Override
    public boolean onDanmakuClick(IDanmakus danmakus) {
        Log.d("DFM", "onDanmakuClick: danmakus size:" + danmakus.size());
        BaseDanmaku latest = danmakus.last();
        if (null != latest) {
            Log.d("DFM", "onDanmakuClick: text of latest danmaku:" + latest.text);
            return true;
        }
        return false;
    }

    @Override
    public boolean onDanmakuLongClick(IDanmakus danmakus) {
        return false;
    }

    @Override
    public boolean onViewClick(IDanmakuView view) {
        mMediaController.setVisibility(View.VISIBLE);
        return false;
    }
});

```

### 4. 预加载一些弹幕

```java
mParser = createParser(this.getResources().openRawResource(R.raw.comments));
mDanmakuView.prepare(mParser, mContext); // 准备一些
mDanmakuView.showFPS(true);
mDanmakuView.enableDanmakuDrawingCache(true);
```

