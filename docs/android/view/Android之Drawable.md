# Android之Drawable

## Drawable的种类

Drawable 表示一种可以在Canvas上绘制的概念，并不是一个UI控件，也不可以交互。一般作为ImageView的图像 或者 View的背景使用。





### BitmapDrawable

| 属性                |          |                                                              |
| ------------------- | -------- | ------------------------------------------------------------ |
| `android:antialias` | 抗锯齿   | 开启后可以减少图片的锯齿感，变得更加平衡，会略微降低图片的清晰度。 |
| `android:dither`    | 抖动     | 当图片的像素和手机屏幕的像素不一致时，开启后可以优化高质量的图片在低质量的屏幕上的显示效果。 |
| `android:filter`    | 过滤     | 当图片尺寸被拉伸或者压缩时，开启后可以保持较好的显示效果。   |
| `android:gravity`   |          | 调整图片位置用。                                             |
| `android:tileMode`  | 平铺模式 | 可以设置平铺模式，开启后 gravity失效。disabled：不启用；clamp：扩散图片周边像素；repeat：重复图形平铺；mirror：镜像方式平铺 |
| `android:mipMap`    | 纹理映射 |                                                              |



### ShapeDrawable

| 属性            |        |                                                              |
| --------------- | ------ | ------------------------------------------------------------ |
| `android:shape` | 形状   | 指定 ShapeDrawable的形状。rectangle：矩形；oval：椭圆；line：横线；ring：圆环。 |
| `<corner>`      | 圆角   | 可以设置 shape四个角的圆角。                                 |
| `<gradient>`    | 渐变   | 可以给shape 设置渐变色。                                     |
| `<solid>`       | 填充   | 可以给shape填充纯色，和 `gradient` 互斥。                    |
| `<stroke>`      | 描边   | 用于设置 shape 边线的属性。                                  |
| `<padding>`     | 内边距 |                                                              |
| `<size>`        | 尺寸   | 表示shape的固有宽高。                                        |



### LevelListDrawable

可以在 xml中通过 `<level-list>` 来定义一个 LevelListDrawable。

一个`<level-list>`包含多个item，每一个item表示一个Drawable且有对应的等级范围。这个等级范围的数值限制是：0 ~ 10000。

使用时可以通过 `drawable.setLevel()` 来修改等级，从而切换到对应等级的Drawable，和Log中的Level 类似。



### LayerListDrawable

可以在 xml中通过 `<layer-list>` 来定义一个 LayerListDrawable。

一个`<layer-list>`包含多个item，每一个item表示一个Drawable。通过放在不同的层上面从而形成多个Drawable叠加的效果



## Drawable的宽高

可以通过以下API 获取Drawable的宽高，不过并不是所有的Drawable都是宽高，图片形成的Drawable 宽高就是图片的宽高，纯颜色形成的Drawable则没有宽高，大小为-1。

* getIntrinsicWidth()：获取宽度。

* getIntrinsicHeight()：获取高度。



## Drawable的缓存机制

* **DrawableCache**：管理Drawable缓存，实际上保持的是Drawable的状态（**ConstantState**）。
  * 存在两个DrawableCache，一个是管理ColorDrawable，另一个是管理非ColorDrawable的。
* **ConstantState**：用于管理Drawable的状态，并且可以通过状态来创建Drawable对象。一般情况下同一个资源生成的Drawable对象是共享同一个状态的。
  * 最常见的子类有 `BitmapState`，内部持有一个Bitmap对象。

```java
public class ResourcesImpl {
    // 非 ColorDrawable 的缓存
    private final DrawableCache mDrawableCache = new DrawableCache();
    // ColorDrawable 的缓存
    private final DrawableCache mColorDrawableCache = new DrawableCache();
    
	Drawable loadDrawable(@NonNull Resources wrapper, @NonNull TypedValue value, int id,
            int density, @Nullable Resources.Theme theme)
            throws NotFoundException {
        // 这里会判断图片资源的density是否和我们当前的densityDpi 匹配
        // 不过我们加载资源是 density传入的是0，表示密度未定义,此时会启动缓存
        final boolean useCache = density == 0 || value.density == mMetrics.densityDpi;
        // 这里会给 value.density 赋值成 dpi。
        if (density > 0 && value.density > 0 && value.density != TypedValue.DENSITY_NONE) {
            if (value.density == density) { // 和显示密度相同，直接使用 densityDpi
                value.density = mMetrics.densityDpi;
            } else { // 不同，此时将 dpi 按比例缩放
                value.density = (value.density * mMetrics.densityDpi) / density;
            }
        }

        try {
            final boolean isColorDrawable;
            final DrawableCache caches;
            final long key;
            // 根据是否是 ColorDrawable，使用不同的 DrawableCache
            // 这里还生成了一个key，它就是缓存的key
            if (value.type >= TypedValue.TYPE_FIRST_COLOR_INT
                    && value.type <= TypedValue.TYPE_LAST_COLOR_INT) {
                isColorDrawable = true;
                caches = mColorDrawableCache;
                key = value.data;
            } else {
                isColorDrawable = false;
                caches = mDrawableCache;
                key = (((long) value.assetCookie) << 32) | value.data;
            }

            // 查询是否已存在缓存，存在则会根据状态重新创建一个 Drawable对象，然后依照主题修改配置后返回
            if (!mPreloading && useCache) {
                // 根据状态新建一个Drawable对象。
                final Drawable cachedDrawable = caches.getInstance(key, wrapper, theme);
                if (cachedDrawable != null) {
                    cachedDrawable.setChangingConfigurations(value.changingConfigurations);
                    return cachedDrawable;
                }
            }

			
            final Drawable.ConstantState cs;
            // 根据Key 来获取 Drawable 对应的 ConstantState
            // 所以相同资源使用的是同一个状态。
            if (isColorDrawable) {
                cs = sPreloadedColorDrawables.get(key);
            } else {
                cs = sPreloadedDrawables[mConfiguration.getLayoutDirection()].get(key);
            }

            Drawable dr;
            boolean needsNewDrawableAfterCache = false;
            if (cs != null) {
                dr = cs.newDrawable(wrapper);
            } else if (isColorDrawable) {
                dr = new ColorDrawable(value.data);
            } else {
                dr = loadDrawableForCookie(wrapper, value, id, density);
            }
            // DrawableContainer' constant state has drawables instances. In order to leave the
            // constant state intact in the cache, we need to create a new DrawableContainer after
            // added to cache.
            if (dr instanceof DrawableContainer)  {
                needsNewDrawableAfterCache = true;
            }

            // Determine if the drawable has unresolved theme attributes. If it
            // does, we'll need to apply a theme and store it in a theme-specific
            // cache.
            final boolean canApplyTheme = dr != null && dr.canApplyTheme();
            if (canApplyTheme && theme != null) {
                dr = dr.mutate();
                dr.applyTheme(theme);
                dr.clearMutated();
            }

            // If we were able to obtain a drawable, store it in the appropriate
            // cache: preload, not themed, null theme, or theme-specific. Don't
            // pollute the cache with drawables loaded from a foreign density.
            if (dr != null) {
                dr.setChangingConfigurations(value.changingConfigurations);
                if (useCache) {
                    cacheDrawable(value, isColorDrawable, caches, theme, canApplyTheme, key, dr);
                    if (needsNewDrawableAfterCache) {
                        Drawable.ConstantState state = dr.getConstantState();
                        if (state != null) {
                            dr = state.newDrawable(wrapper);
                        }
                    }
                }
            }

            return dr;
        } catch (Exception e) {
            String name;
            try {
                
                name = getResourceName(id);
            } catch (NotFoundException e2) {
                name = "(missing name)";
            }

            // The target drawable might fail to load for any number of
            // reasons, but we always want to include the resource name.
            // Since the client already expects this method to throw a
            // NotFoundException, just throw one of those.
            final NotFoundException nfe = new NotFoundException("Drawable " + name
                    + " with resource ID #0x" + Integer.toHexString(id), e);
            nfe.setStackTrace(new StackTraceElement[0]);
            throw nfe;
        }
    }
    
}
```

## mutate()：独立Drawable

默认情况下同一个资源加载得到的 Drawable 对象会共享状态（ConstantState），所以修改其中一个Drawable的状态时其他同资源的 Drawable也会受到影响。

若我们想要修改一个Drawable对象但是又不影响其他对象，此时可以使用 `Drawable.mutate()` 方法来得到一个Drawable，此时我们再对其进行修改时就不会影响到其他Drawable。

原理就是这个函数会给Drawable单独新建一个ConstantState，这样就不再和其他同资源的Drawable共享状态了，所以也就不会互相影响。

> 代码验证 mutate() 的效果。
>
> * 使用 mutate() ：对Drawable的修改不会影响后续同资源创建的Drawable。
> * 未使用 mutate()：对Drawable的修改后，后续同资源创建的Drawable 也都会受到影响。

```kotlin
	override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityDrawableBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // 先创建三个drawable
        val originDrawable = loadDrawable()
        val tintDrawable = loadDrawable()
        val mutateDrawable = loadDrawable()?.mutate()
        //
        binding.drawableFirstIv.setImageDrawable(originDrawable)
        binding.drawableSecondIv.setImageDrawable(originDrawable)
        binding.drawableThirdIv.setImageDrawable(originDrawable)
        binding.drawableFourthIv.setImageDrawable(originDrawable)

        binding.drawableFirstIv.setOnClickListener {
            tintDrawable?.let {
                DrawableCompat.setTint(it, Color.BLACK)
                it.alpha = 50
                binding.drawableSecondIv.setImageDrawable(it)
            }
            mutateDrawable?.let {
                // 这里修改透明度，并不会影响其他Drawable。
                it.alpha = 200
                binding.drawableThirdIv.setImageDrawable(it)
            }
//            binding.drawableFirstIv.setImageDrawable(originDrawable)
            loadDrawable()?.let {
                // 这里是在修改了状态后创建的 drawable，会发现创建的 drawable 也被修改了
                // 它和 tintDrawable 是相同的
                binding.drawableFourthIv.setImageDrawable(it)
            }
        }
    }
```



## tint()

* tint：指定图像着色器的颜色。修改的是 src 、bitmap指定的图片。
* tintMode：图像着色类型，包含 add、multiply、screen、src_over、src_in、src_atop 这六种。
* backgroundTint：指定背景着色器的颜色。修改的是 background 指定的背景。
* backgroundTintMode：指定背景着色器的着色类型

为了兼容不同版本，我们一般会使用 `DrawableCompat` 来处理图片。

>  使用

```kotlin
val tintDrawable = DrawableCompat.wrap(drawable)
DrawableCompat.setTint(tintDrawable, Color.BLACK)
```

> 原理
>
> tint的核心就是 ColorFilter

```java
class BitmapDrawable {
    //
    private BlendModeColorFilter mBlendModeFilter;
    
    @Override
    public void setTintList(ColorStateList tint) {
        // 实际就是创建了一个 ColorFilter
        final BitmapState state = mBitmapState;
        if (state.mTint != tint) {
            state.mTint = tint;
            mBlendModeFilter = updateBlendModeFilter(mBlendModeFilter, tint,
                      mBitmapState.mBlendMode);
            invalidateSelf();
        }
    }
    
    @Override
    public void draw(Canvas canvas) {
        final Bitmap bitmap = mBitmapState.mBitmap;
        if (bitmap == null) {
            return;
        }

        final BitmapState state = mBitmapState;
        final Paint paint = state.mPaint;
        if (state.mRebuildShader) {
            final Shader.TileMode tmx = state.mTileModeX;
            final Shader.TileMode tmy = state.mTileModeY;
            if (tmx == null && tmy == null) {
                paint.setShader(null);
            } else {
                paint.setShader(new BitmapShader(bitmap,
                        tmx == null ? Shader.TileMode.CLAMP : tmx,
                        tmy == null ? Shader.TileMode.CLAMP : tmy));
            }

            state.mRebuildShader = false;
        }

        final int restoreAlpha;
        if (state.mBaseAlpha != 1.0f) {
            final Paint p = getPaint();
            restoreAlpha = p.getAlpha();
            p.setAlpha((int) (restoreAlpha * state.mBaseAlpha + 0.5f));
        } else {
            restoreAlpha = -1;
        }

        final boolean clearColorFilter;
        // 将 setTint() 时的ColorFilter 设置给 paint
        if (mBlendModeFilter != null && paint.getColorFilter() == null) {
            paint.setColorFilter(mBlendModeFilter);
            clearColorFilter = true;
        } else {
            clearColorFilter = false;
        }

        updateDstRectAndInsetsIfDirty();
        final Shader shader = paint.getShader();
        final boolean needMirroring = needMirroring();
        if (shader == null) {
            if (needMirroring) {
                canvas.save();
                // Mirror the bitmap
                canvas.translate(mDstRect.right - mDstRect.left, 0);
                canvas.scale(-1.0f, 1.0f);
            }

            canvas.drawBitmap(bitmap, null, mDstRect, paint);

            if (needMirroring) {
                canvas.restore();
            }
        } else {
            updateShaderMatrix(bitmap, paint, shader, needMirroring);
            canvas.drawRect(mDstRect, paint);
        }

        if (clearColorFilter) {
            paint.setColorFilter(null);
        }

        if (restoreAlpha >= 0) {
            paint.setAlpha(restoreAlpha);
        }
    }
    
}
```

## ColorFilter

ColorFilter 是一个色彩过滤器，我们可以通过它来操作图像的每一个像素。tint着色器就是依靠它来实现的。

### ColorMatrixColorFilter

可以通过颜色矩阵来调整图像像素点的色彩。

ColorMatrix 是一个 4 * 5的矩阵。它表示HSI模型的颜色，相当于我们电脑上画图软件的调色板。



![image-20230610204552147](./Android%E4%B9%8BDrawable.assets/image-20230610204552147.png)

```java
ColorMatrix colorMatrix = new ColorMatrix();
// argb 取值 1表示不变，
colorMatrix.set(new float[]{
    r, 0, 0, 0, 0,
    0, g, 0, 0, 0,
    0, 0, b, 0, 0,
    0, 0, 0, a, 0,
});
paint.setColorFilter(new ColorMatrixColorFilter(colorMatrix));
```

### LightingColorFilter

用于模拟照明效果。不过仅能修改 RGB 的值，无法修改alpha。

```java
paint.setColorFilter(new LightingColorFilter(0xffffff, 0));
```

​	

### PorterDuffColorFilter

它的作用是进行颜色混合，混合方式则由 PorterDuff.Mode 决定

[PorterDuff.Mode  | Android Developers](https://developer.android.com/reference/android/graphics/PorterDuff.Mode)





### BlendModeColorFilter

Tint时使用的过滤器，专用于着色。





### 
