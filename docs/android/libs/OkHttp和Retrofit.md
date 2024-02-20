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

OkHttp采用双任务队列机制实现异步请求，并通过 Dispatcher来调度任务。它是OkHttp的核心运行机制。

主要包含两个队列：

* **等待队列（readyAsyncCalls）**：异步请求会先进入等待队列，之后在转到执行队列。
* **执行队列（runningAsyncCalls）**：同步请求直接进入执行队列中。
  * 可执行队列（executableCalls）：这是一个临时队列，存在于`promoteAndExecute()`方法执行期间。保存刚加入到runningAsyncCalls 中的任务，这样就可以在任务添加完后就释放锁，使用这个临时队列来遍历调度新的请求任务。

运行机制：

1. 通过 `client.enqueue()`添加的异步任务 AsyncCall，这个新任务会被**加入到 等待队列 中**。

2. 然后通过 `promoteAndExecute()` 将等待队列的任务放到执行队列中并执行，这里会遍历等待队列 ，判断是否能够加入到执行中。

   * 执行队列的数量**不超过最大并发数**。默认64，最多允许64个并发请求。超过就不再遍历。

   * 域名对应的连接**不超过Host最大并发数**。默认5，即每个域名最多5个并发连接。超过会继续遍历，添加其他域名的请求任务。

3. 满足上述2个条件的任务会从等待队列 转移到 执行队列 中，直至塞满执行队列或遍历结束，并使用线程池执行任务。

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

OkHttp为了避免将网络请求和请求响应的不同处理逻辑耦合在一起，使用了责任链模式来进行解耦，每种处理需求都抽象成一个拦截器，并且将这些拦截器组合成一条链Chain，这个请求会在这条链上层层传递，直到某个拦截器消费了请求并且不再传递。（和View的事件分发很相似）。

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
| @PUT("/xx")       | 函数 | 新建或更新资源，对应UPDATE。一般是全量更新                   | 幂等、不安全     |
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

### 使用方式

#### 创建 Retrofit 实例

```kotlin
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        // 通过 Builder 创建 Retrofit实例
        return Retrofit.Builder()
            .baseUrl("http://192.168.56.1:8080/") // 默认的 URL
            .client(okHttpClient) // 设置okhttpClient
            .addConverterFactory(GsonConverterFactory.create()) // 请求/响应数据解析转换
            .addCallAdapterFactory(RxJava2CallAdapterFactory.create()) // 添加Rxjava适配器，支持返回RxJava格式
            .build()
    }
```

#### 定义服务接口

```kotlin
interface RetrofitService {
    @GET("/api/v1/app/all")
    fun get(): Call<ResponseBody>
}
```

#### 动态代理服务接口

```kotlin
val service = retrofit.create(RetrofitService::class.java)
```



### 自定义Converter（数据类型转换）

我们可以通过自定义 `Converter.Factory` 来对 请求/响应数据进行转换。转换的是返回数据的类型。

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



### 自定义CallAdapter（响应结构转换）

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



### 动态代理机制

#### Retrofit.create()

`create()` 函数是使用的 JDK动态代理的方式创建服务接口实例。

这里有一个关键函数 `loadServiceMethod()` ，这个函数会解析接口上的注解并转换成http请求。

```java
public <T> T create(final Class<T> service) {
    validateServiceInterface(service);
    return (T)
        Proxy.newProxyInstance(
            service.getClassLoader(),
            new Class<?>[] {service},
            new InvocationHandler() {
              private final Platform platform = Platform.get();
              private final Object[] emptyArgs = new Object[0];

              @Override
              public @Nullable Object invoke(Object proxy, Method method, @Nullable Object[] args)
                  throws Throwable {
                // 函数被调用时执行
                // If the method is a method from Object then defer to normal invocation.
                if (method.getDeclaringClass() == Object.class) {
                  return method.invoke(this, args);
                }
                args = args != null ? args : emptyArgs;
                // 调用 loadServiceMethod 处理并执行方法,default 修饰的接口单独处理。
                // loadServiceMethod() 返回的是一个 CallAdapted:HttpServiceMethod
                // invoke() 执行 ServiceMethod.adapt(), 发起请求
                return platform.isDefaultMethod(method)
                    ? platform.invokeDefaultMethod(method, service, proxy, args)
                    : loadServiceMethod(method).invoke(args);
              }
            });
  }

```

#### Retrofit.loadServiceMethod()

首先会从 缓存中获取，若缓存未命中，则会根据 接口上的注解执行解析，得到一个加工得到的服务方法 ServiceMethod，然后添加到缓存中。

```java
  ServiceMethod<?> loadServiceMethod(Method method) {
    // 首先从缓存中获取
    ServiceMethod<?> result = serviceMethodCache.get(method);
    if (result != null) return result;

    synchronized (serviceMethodCache) {
      result = serviceMethodCache.get(method);
      if (result == null) {
        // 解析接口注解得到一个 ServiceMethod
        result = ServiceMethod.parseAnnotations(this, method);
        serviceMethodCache.put(method, result);
      }
    }
    return result;
  }
```

#### ServiceMethod.parseAnnotations()

最终调用的HttpServiceMethod.parseAnnotations()

```java
static <T> ServiceMethod<T> parseAnnotations(Retrofit retrofit, Method method) {
    // 解析
    RequestFactory requestFactory = RequestFactory.parseAnnotations(retrofit, method);

    Type returnType = method.getGenericReturnType();
    if (Utils.hasUnresolvableType(returnType)) {
      throw methodError(
          method,
          "Method return type must not include a type variable or wildcard: %s",
          returnType);
    }
    if (returnType == void.class) {
      throw methodError(method, "Service methods cannot return void.");
    }
	// HttpServiceMethod
    return HttpServiceMethod.parseAnnotations(retrofit, method, requestFactory);
  }
```

#### HttpServiceMethod.parseAnnotations()

* 创建符合返回类型的 CallAdapter。之前调用`addCallAdapterFactory()` 添加了对应的工厂类来创建。
* 创建符合响应数据类型的 ResponseConverter。之前调用`addConverterFactory()` 添加了对应的工厂类来创建。
* 最终会创建一个 `CallAdapted: HttpServiceMethod`，返回给我们。内部持有上面获取到的 CallAdapter、ResponseConverter以及 RequestFactory
  * 会首先判断是否是 kotlin的挂起函数，挂起函数会特殊处理。


```java
static <ResponseT, ReturnT> HttpServiceMethod<ResponseT, ReturnT> parseAnnotations(
      Retrofit retrofit, Method method, RequestFactory requestFactory) {
    boolean isKotlinSuspendFunction = requestFactory.isKotlinSuspendFunction;
    boolean continuationWantsResponse = false;
    boolean continuationBodyNullable = false;

    Annotation[] annotations = method.getAnnotations();
    Type adapterType;
    if (isKotlinSuspendFunction) { // 挂起函数特殊处理
      Type[] parameterTypes = method.getGenericParameterTypes();
      Type responseType =
          Utils.getParameterLowerBound(
              0, (ParameterizedType) parameterTypes[parameterTypes.length - 1]);
      if (getRawType(responseType) == Response.class && responseType instanceof ParameterizedType) {
        // Unwrap the actual body type from Response<T>.
        responseType = Utils.getParameterUpperBound(0, (ParameterizedType) responseType);
        continuationWantsResponse = true;
      } else {
        // TODO figure out if type is nullable or not
        // Metadata metadata = method.getDeclaringClass().getAnnotation(Metadata.class)
        // Find the entry for method
        // Determine if return type is nullable or not
      }

      adapterType = new Utils.ParameterizedTypeImpl(null, Call.class, responseType);
      annotations = SkipCallbackExecutorImpl.ensurePresent(annotations);
    } else {
      adapterType = method.getGenericReturnType();
    }
	// 查找 CallAdapter
    CallAdapter<ResponseT, ReturnT> callAdapter =
        createCallAdapter(retrofit, method, adapterType, annotations);
    Type responseType = callAdapter.responseType();
    if (responseType == okhttp3.Response.class) {
      throw methodError(
          method,
          "'"
              + getRawType(responseType).getName()
              + "' is not a valid response body type. Did you mean ResponseBody?");
    }
    if (responseType == Response.class) {
      throw methodError(method, "Response must include generic type (e.g., Response<String>)");
    }
    // TODO support Unit for Kotlin?
    if (requestFactory.httpMethod.equals("HEAD") && !Void.class.equals(responseType)) {
      throw methodError(method, "HEAD method must use Void as response type.");
    }
	// 查找 ResponseConverter
    Converter<ResponseBody, ResponseT> responseConverter =
        createResponseConverter(retrofit, method, responseType);

    okhttp3.Call.Factory callFactory = retrofit.callFactory;
    
    // 这里判断是否是 kotlin的挂起函数，挂起函数会特殊处理。
    if (!isKotlinSuspendFunction) {
      // 非挂起函数，一般都在这。返回一个 CallAdapted。
      return new CallAdapted<>(requestFactory, callFactory, responseConverter, callAdapter);
    } else if (continuationWantsResponse) { 
      //noinspection unchecked Kotlin compiler guarantees ReturnT to be Object.
      return (HttpServiceMethod<ResponseT, ReturnT>)
          new SuspendForResponse<>(
              requestFactory,
              callFactory,
              responseConverter,
              (CallAdapter<ResponseT, Call<ResponseT>>) callAdapter);
    } else {
      //noinspection unchecked Kotlin compiler guarantees ReturnT to be Object.
      return (HttpServiceMethod<ResponseT, ReturnT>)
          new SuspendForBody<>(
              requestFactory,
              callFactory,
              responseConverter,
              (CallAdapter<ResponseT, Call<ResponseT>>) callAdapter,
              continuationBodyNullable);
    }
  }
```

#### HttpServiceMethod.invoke()

在上面创建的代理中 最终调用的是 `CallAdapted.invoke()`，具体实现在父类 HttpServiceMethod 中。

* 创建了一个 OkHttpCall
* 调用 `adapt()`， CallAdapted实现了这个抽象方法，会调用 `callAdapter.adapt(call)` 来决定返回类型。

```java
  @Override
  final @Nullable ReturnT invoke(Object[] args) {
    // 创建了一个 OkHttpCall，这个Call是 Retrofit中的类，并不是okhttp中的。
    Call<ResponseT> call = new OkHttpCall<>(requestFactory, args, callFactory, responseConverter);
    // adapt中调用的是  callAdapter.adapt(call)
    return adapt(call, args);
  }
```



## 协程的支持

retrofit 对于 Kotlin 协程进行了支持。

当定义的接口 是一个挂起函数时，会自动开启一个使用`Dispatchs.IO`调度器的协程去执行网络访问。
