# WebView

## WebView优化

* WebView预加载：建立一个 WebView 缓存池，存储预加载的WebView，优化WebView的初始化时间。
  * 利用 IdleHandler 再空闲时执行预加载。
  * 可以先使用 MutableContextWrapper 作为context，Activity使用WebView时再替换成 Activity。
  * 缓存池中的WebView还可以进行复用。
* 预置离线包，将通用的JS、CSS、模板文件等文件提前打包进APK中，避免每次都网络请求下载。
* 使用 `WebViewClient.shouldInterceptRequest()` 拦截请求，统一处理。
  * 过滤、替换资源；使用本地离线包资源 和 使用APP中的所有资源。
  * 资源网络访问代理。
* 利用 Http 缓存策略，减少网络访问次数。
* NDS优化，尽量和客户端采用相同的主域名。
* CDN 加速资源获取速度。



## 内存泄露问题

### 解决方法

* 避免WebView持有外部的Activity的Context，考虑手动创建WebView并使用 Application的Context，不在xml 使用 `<WebView>` 标签创建。
* 先将WebView从父容器中移除，在调用 destroy() 销毁。

* 使用独立进程，使用完毕后直接将该进程kill 即可。

## 白屏检测

* 调用 `View.getDrawingCache()` 获取WebView视图的bitmap对象。
* 缩放后遍历像素点，判断非白色像素的占比，从而判断是否是白屏，例如 非白色像素 大于 5%则不是白屏。