# OkHttp和Retrofit



## OkHttp

| body         |                                       |      |
| ------------ | ------------------------------------- | ---- |
| RequestBody  | 基础的提交方式，需要我们指定MediaType |      |
| FormBody     | 表单格式                              |      |
| MutipartBody | 文件上传                              |      |



源码分析

| 接口/类      |                                                              |      |
| ------------ | ------------------------------------------------------------ | ---- |
| OkHttpClient | 它是OkHttp提供的请求客户端，负责创建 Call 发起http请求 。建议使用单例。 |      |
| Call         | 定义http请求的接口。例如`execute()`、`enqueue()`等。         |      |
| RealCall     | 是Call 接口的实现类。内部会通过 Dispatcher来调度请求。       |      |
| AsyncCall    | 表示一个异步请求任务，实质就是一个Runnable。首先会放入到队列中，最终会被调度到线程池中执行。这里真正的发起了请求并获取响应。 |      |
| Dispatcher   | 任务调度器，队列负责调度任务队列中的请求。内部 等待队列和执行队列 这两个队列。 |      |

### 双任务队列机制

OkHttp采用双任务队列机制实现异步请求，并通过 Dispatcher来调度任务。而Dispatcher采用的是双任务队列机制进行调度。它是OkHttp的核心运行机制。

主要包含两个队列：

* **等待队列（readyAsyncCalls）**：
* **执行队列（runningAsyncCalls）**：
  * 可执行队列（executableCalls）：这是一个临时队列，存在于`promoteAndExecute()`方法执行期间。保存刚加入到runningAsyncCalls 中的任务，这样就可以在任务添加完后就释放锁，使用这个临时队列来遍历调度新的请求任务。

运行机制：

1. 通过 `client.enqueue()`添加的异步任务 AsyncCall，这个新任务会被加入到 `readyAsyncCalls` 中。

2. 然后通过 `promoteAndExecute()` 将等待队列的任务放到执行队列中并执行。在这里会遍历 `readyAsyncCalls` ，判断是否能够加入到 `runningAsyncCalls`中。

   * runningAsyncCalls 的数量**不超过最大并发数**。默认64，最多允许64个并发请求。超过就不再遍历。

   * 域名对应的连接**不超过Host最大并发数**。默认5，即每个域名最多5个并发连接。超过会继续遍历，添加其他域名的请求任务。

3. 满足上述2个条件的任务，会从等待队列 转移到 runningAsyncCalls 中，直至塞满执行队列或遍历结束，并使用线程池执行任务。

   * 这里最终会调用 `getResponseWithInterceptorChain()` 通过责任链的方式层层处理请求和响应。

4. AsyncCall 在线程中无论执行成功还是失败，最终都会调用 `dispatcher.finish()`，这个函数内部重新调用了 `promoteAndExecute()`回到了第2步，有任务完成空出了一个位置就可以重新尝试将等待队列中的任务放到执行队列中。

![image-20230720120500857](./OkHttp%E5%92%8CRetrofit.assets/image-20230720120500857.png)

#### Dispatcher

```kotlin
class Dispatcher constructor() {
    // 最大并发请求数
	@get:Synchronized var maxRequests = 64
    // 每个域名最大并发请求连接数
    @get:Synchronized var maxRequestsPerHost = 5
  
  // 请求任务要执行一定会调用这个函数，起到推进或者执行的作用
  // 从等待队列中将任务移交给执行队列，并执行。
  private fun promoteAndExecute(): Boolean {
    this.assertThreadDoesntHoldLock()
	// 创建一个临时队列，用于遍历。
    val executableCalls = mutableListOf<AsyncCall>()
    val isRunning: Boolean
    synchronized(this) {
      val i = readyAsyncCalls.iterator()
      while (i.hasNext()) {
        val asyncCall = i.next()
		// 不超过最大并发数
        if (runningAsyncCalls.size >= this.maxRequests) break // Max capacity.
        // 不超过Host最大并发数
        if (asyncCall.callsPerHost.get() >= this.maxRequestsPerHost) continue // Host max capacity.
		// 从等待队列移除
        i.remove()
        asyncCall.callsPerHost.incrementAndGet()
        // 添加到执行队列和临时队列
        executableCalls.add(asyncCall)
        runningAsyncCalls.add(asyncCall)
      }
      // 存在请求
      isRunning = runningCallsCount() > 0
    }
	// 先解锁 在遍历可执行临时队列
    for (i in 0 until executableCalls.size) {
      val asyncCall = executableCalls[i]
      asyncCall.executeOn(executorService)
    }
	// 返回当前是否有执行请求
    return isRunning
  }
  
  // ---------
  internal fun finished(call: RealCall) {
    finished(runningSyncCalls, call)
  }
  private fun <T> finished(calls: Deque<T>, call: T) {
    val idleCallback: Runnable?
    synchronized(this) {
       // 从执行队列中移除执行完毕的请求
      if (!calls.remove(call)) throw AssertionError("Call wasn't in-flight!")
      idleCallback = this.idleCallback
    }
	// 重新调用了 promoteAndExecute()
    val isRunning = promoteAndExecute()
	// 没有可执行任务时，触发闲置回调
    if (!isRunning && idleCallback != null) {
      idleCallback.run()
    }
  }
}
```



#### AsyncCall

```kotlin
internal inner class AsyncCall() : Runnable{
    // 外部调度请求时调用的方法，将这个任务分配到对应线程池中执行
    fun executeOn(executorService: ExecutorService) {
      client.dispatcher.assertThreadDoesntHoldLock()

      var success = false
      try {
          // 执行请求
        executorService.execute(this)
        success = true
      } catch (e: RejectedExecutionException) {
        val ioException = InterruptedIOException("executor rejected")
        ioException.initCause(e)
        noMoreExchanges(ioException)
        responseCallback.onFailure(this@RealCall, ioException)
      } finally {
        if (!success) { // 失败则调用 finished() 
          client.dispatcher.finished(this) // This call is no longer running!
        }
      }
    }

    // 真正执行请求的地方
    override fun run() {
      threadName("OkHttp ${redactedUrl()}") {
        var signalledCallback = false
        timeout.enter()
        try {
          // 发起请求 并获取到响应
          val response = getResponseWithInterceptorChain()
          signalledCallback = true
          responseCallback.onResponse(this@RealCall, response)
        } catch (e: IOException) {
          if (signalledCallback) {
            // Do not signal the callback twice!
            Platform.get().log("Callback failure for ${toLoggableString()}", Platform.INFO, e)
          } else {
            responseCallback.onFailure(this@RealCall, e)
          }
        } catch (t: Throwable) {
          cancel()
          if (!signalledCallback) {
            val canceledException = IOException("canceled due to $t")
            canceledException.addSuppressed(t)
            responseCallback.onFailure(this@RealCall, canceledException)
          }
          throw t
        } finally {
          // 请求成功则 调用finished()
          client.dispatcher.finished(this)
        }
      }
    }
}
```

### 责任链

OkHttp为了避免将请求和多个请求处理逻辑耦合在一起，使用了责任链模式来进行解耦，每种处理需求都抽象成一个拦截器，并且将这些拦截器组合成一条链Chain，这个请求会在这条链上层层传递，直到某个拦截器消费了请求并且不再传递。（和View的事件分发很相似）。

我们可以通过添加自定义拦截器来对请求添加自定义的处理逻辑。自定义拦截器是在最上层请求链的最上层，会被优先调用。

| 拦截器                                   |                                                              |
| ---------------------------------------- | ------------------------------------------------------------ |
| `interceptors: List<Interceptor>`        | 我们自定义的拦截器。默认为空                                 |
| RetryAndFollowUpInterceptor              | 重定向                                                       |
| BridgeInterceptor                        | 添加必要的基础请求头信息。                                   |
| CacheInterceptor                         | 缓存                                                         |
| ConnectInterceptor                       | 连接                                                         |
| `networkInterceptors: List<Interceptor>` | 面向非WebSocket的拦截器，默认为空。可以通过做一些网络相关的拦截处理， |
| CallServerInterceptor                    | 访问服务器，真正请求服务器的地方                             |



```kotlin
class RealCall() : Call{
    
  internal fun getResponseWithInterceptorChain(): Response {
    // Build a full stack of interceptors.
    val interceptors = mutableListOf<Interceptor>()
    interceptors += client.interceptors	// 自定义拦截器
    interceptors += RetryAndFollowUpInterceptor(client) // 重定向
    interceptors += BridgeInterceptor(client.cookieJar) // 基础头信息
    interceptors += CacheInterceptor(client.cache)	// 缓存
    interceptors += ConnectInterceptor	// 连接
    if (!forWebSocket) {
      interceptors += client.networkInterceptors
    }
    interceptors += CallServerInterceptor(forWebSocket)

    val chain = RealInterceptorChain(
        call = this,
        interceptors = interceptors,
        index = 0,
        exchange = null,
        request = originalRequest,
        connectTimeoutMillis = client.connectTimeoutMillis,
        readTimeoutMillis = client.readTimeoutMillis,
        writeTimeoutMillis = client.writeTimeoutMillis
    )

    var calledNoMoreExchanges = false
    try {
      val response = chain.proceed(originalRequest)
      if (isCanceled()) {
        response.closeQuietly()
        throw IOException("Canceled")
      }
      return response
    } catch (e: IOException) {
      calledNoMoreExchanges = true
      throw noMoreExchanges(e) as Throwable
    } finally {
      if (!calledNoMoreExchanges) {
        noMoreExchanges(null)
      }
    }
  }
}
```

### 连接池复用

利用的就是Http协议中的 KeepAlive机制，这个机制可以保证在数据传输完毕后依然保持连接，需要时可以直接复用这个连接来传输数据，不需要再重新建立TCP连接（降低TCP的三次握手和四次挥手的频率，从而优化请求速度）。

默认保持5个连接，存活时间为5分钟。

|                    |                                        |      |
| ------------------ | -------------------------------------- | ---- |
| RealConnection     | 持有连接信息的类                       |      |
| RealConnectionPool | 连接池，持有一个 RealConnection 队列。 |      |
|                    |                                        |      |



## Retrofit

Retrofit 基于 OkHttp，是OkHttp的上层封装，方便使用。

* 支持 RESTful API
* 支持注解配置。
* 支持配置数据的序列化和解析。

### 常用注解

| 注解              | 修饰 |                                                              |                  |
| ----------------- | ---- | ------------------------------------------------------------ | ---------------- |
| @GET("/xx/{a}/x") | 函数 | 获取资源，对应SELECT。                                       | 幂等、安全。     |
| @POST("/xx")      | 函数 | 上传新建资源，一般对应INSERT                                 | 非幂等、不安全。 |
| @PUT("/xx")       | 函数 | 更新资源，对应UPDATE                                         | 幂等、不安全     |
| @DELETE("/xx")    | 函数 | 删除资源，对应DELETE                                         | 幂等、不安全     |
| -                 |      |                                                              |                  |
| @Path("a")        | 参数 | 将修饰的参数值填充到URI Path中被`{}`修饰的同名参数。         |                  |
| -                 |      |                                                              |                  |
| @Query("name")    | 参数 | 作为query参数，会拼接在url后面。key为name，value为参数的值。 |                  |
| @Field            | 参数 | 会以From表单的格式提交，需要配合`@FormUrlEncoded`使用。      |                  |
| @FieldMap         | 参数 | 也是也From表单格式提交，不过参数需求是Map。需要配合`@FormUrlEncoded`使用。 |                  |
| @Body             | 参数 | 参数是某一具体的类型。                                       |                  |
| -                 |      |                                                              |                  |
| @Mutipart         | 函数 | 表示是一个上传文件请求，格式是表单格式。                     |                  |
| @Part             | 参数 | 和 @Mutipart 结合使用。                                      |                  |
| @PartMap          | 参数 | 用于多文件上传。                                             |                  |



### Converter

我们可以通过自定义 `Converter.Factory` 来对 请求/响应数据进行转换。

转换的是返回的数据类型，例如 ResponseBody 。

例如常见的 `GsonConverterFactory` 。

```java
public final class GsonConverterFactory extends Converter.Factory {
  public static GsonConverterFactory create() {
    return create(new Gson());
  }

  @SuppressWarnings("ConstantConditions") // Guarding public API nullability.
  public static GsonConverterFactory create(Gson gson) {
    if (gson == null) throw new NullPointerException("gson == null");
    return new GsonConverterFactory(gson);
  }

  private final Gson gson;

  private GsonConverterFactory(Gson gson) {
    this.gson = gson;
  }
  // 将响应数据ResponseBody 通过Gson转换成具体的对象
  @Override
  public Converter<ResponseBody, ?> responseBodyConverter(
      Type type, Annotation[] annotations, Retrofit retrofit) {
    TypeAdapter<?> adapter = gson.getAdapter(TypeToken.get(type));
    return new GsonResponseBodyConverter<>(gson, adapter);
  }

  // 将对象实例转为json格式，再构造成一个RequestBody。
  @Override
  public Converter<?, RequestBody> requestBodyConverter(
      Type type,
      Annotation[] parameterAnnotations,
      Annotation[] methodAnnotations,
      Retrofit retrofit) {
    TypeAdapter<?> adapter = gson.getAdapter(TypeToken.get(type));
    return new GsonRequestBodyConverter<>(gson, adapter);
  }
}
```



### CallAdapter

Retrofit 提供给我们了一种自定义Call的适配器的方式，就是传入自定义的 `CallAdapter.Factory `，可以将接口返回自定义成我们需要的形式。转换的是返回值的调用形式，默认是 Call。

常见的转为Rxjava格式就是通过这中方式实现的，同理，我们就可以改为 LiveData等格式。

```java
public final class RxJava2CallAdapterFactory extends CallAdapter.Factory {

  public static RxJava2CallAdapterFactory create() {
    return new RxJava2CallAdapterFactory(null, false);
  }

  public static RxJava2CallAdapterFactory createAsync() {
    return new RxJava2CallAdapterFactory(null, true);
  }

  @SuppressWarnings("ConstantConditions") // Guarding public API nullability.
  public static RxJava2CallAdapterFactory createWithScheduler(Scheduler scheduler) {
    if (scheduler == null) throw new NullPointerException("scheduler == null");
    return new RxJava2CallAdapterFactory(scheduler, false);
  }

  private final @Nullable Scheduler scheduler;
  private final boolean isAsync;

  private RxJava2CallAdapterFactory(@Nullable Scheduler scheduler, boolean isAsync) {
    this.scheduler = scheduler;
    this.isAsync = isAsync;
  }

  @Override
  public @Nullable CallAdapter<?, ?> get(
      Type returnType, Annotation[] annotations, Retrofit retrofit) {
    Class<?> rawType = getRawType(returnType);
	// Completable 是没有参数化的所以特殊处理。
    if (rawType == Completable.class) {
      return new RxJava2CallAdapter(
          Void.class, scheduler, isAsync, false, true, false, false, false, true);
    }
	// 判断返回类型是 RxJava中的哪种
    boolean isFlowable = rawType == Flowable.class;
    boolean isSingle = rawType == Single.class;
    boolean isMaybe = rawType == Maybe.class;
    if (rawType != Observable.class && !isFlowable && !isSingle && !isMaybe) {
      return null;
    }

    boolean isResult = false;
    boolean isBody = false;
    Type responseType;
    if (!(returnType instanceof ParameterizedType)) {
      String name =
          isFlowable ? "Flowable" : isSingle ? "Single" : isMaybe ? "Maybe" : "Observable";
      throw new IllegalStateException(
          name
              + " return type must be parameterized"
              + " as "
              + name
              + "<Foo> or "
              + name
              + "<? extends Foo>");
    }

    Type observableType = getParameterUpperBound(0, (ParameterizedType) returnType);
    Class<?> rawObservableType = getRawType(observableType);
    if (rawObservableType == Response.class) {
      if (!(observableType instanceof ParameterizedType)) {
        throw new IllegalStateException(
            "Response must be parameterized" + " as Response<Foo> or Response<? extends Foo>");
      }
      responseType = getParameterUpperBound(0, (ParameterizedType) observableType);
    } else if (rawObservableType == Result.class) {
      if (!(observableType instanceof ParameterizedType)) {
        throw new IllegalStateException(
            "Result must be parameterized" + " as Result<Foo> or Result<? extends Foo>");
      }
      responseType = getParameterUpperBound(0, (ParameterizedType) observableType);
      isResult = true;
    } else {
      responseType = observableType;
      isBody = true;
    }

    return new RxJava2CallAdapter(
        responseType, scheduler, isAsync, isResult, isBody, isFlowable, isSingle, isMaybe, false);
  }
}
```

