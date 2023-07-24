# RxJava学习笔记

Tags : zaze

---
[TOC]

|                 |                                                              |      |
| --------------- | ------------------------------------------------------------ | ---- |
| `Observable<T>` | 可以发射0个或多个数据。                                      |      |
| `Flowable<T>`   | 可以发射0个或多个数据。支持Backpressure，可以控制发射的速度。 |      |
| `Maybe<T>`      | 可以发射0或1个数据。                                         |      |
| `Single<T>`     | 可以发射单个数据。                                           |      |
| `Completable`   | 没有泛型参数，不发射数据，类似Runnable。                     |      |



## 线程调度器

- **Schedulers.immediate()**
直接在当前线程运行

- **Schedulers.newThread()**
总是启动一个新的线程

- **Schedulers.io()**
内部实现是用一个无数量上限的线程池
I/O操作,不要把计算工作放在io(),可以避免创建不必要的线程

- **Schedulers.computation()**
使用的固定的线程池，大小为cpu核数;
计算时使用的Scheduler;
不会被I/O等操作限制性的操作;
不要用于IO操作;

- **Schedulers.from(executor)**
指定的Executor作为调度器

- **Schedulers.trampoline()**
在当前线程排队开始执行

- **AndroidSchedulers.mainThread()**
Android主线程

## 线程切换

- subscribeOn()
指定**被观察者Observable** 在哪里运行
- observeOn()
指定**观察者Observer** 在哪里运行;
observeOn() 指定的是之后的操作所在的线程

## 操作符

|                 |                                                              |
| --------------- | ------------------------------------------------------------ |
| map()           | 主要用于转换数据                                             |
| flatMap()       | 分发成多个新的Observable对象并转换数据，最后合并为一个Observale。**合并后的结果是无序的**。 |
| concatMap()     | 基本等同flatMap，区别是 concatMap最后的结果是有序的          |
| filter()        | 过滤数据； true 继续, false 被过滤。                         |
| merge()         | 合并 : 多输入，单输出                                        |
| take()          | 指定最多输出几个结果                                         |
| firstElement()  | 发射第一个元素或者结束                                       |
| doOnNext()      | 对每次输出做一定对预处理。调试、缓存网络结果等               |
| doOnSubscribe() | 在订阅时的回调。即使在之前调用observeOn(), 也以 subscribe() 所在线程中为准；若后面有 subscribeOn(), 则变更线程; |

## 运行机制

Flowable 和 Observable 执行流程基本相同，区别在于 Flowable支持背压。

```java
	Flowable.create(new FlowableOnSubscribe<List<String>>() {
            @Override
            public void subscribe(FlowableEmitter<List<String>> e) throws Exception {
                e.onNext(Arrays.asList("W", "X", "S", "I", "L", "U"));
                e.onComplete();
            }
        }, BackpressureStrategy.BUFFER)
                .subscribeOn(scheduler)
                .flatMap(new Function<List<String>, Publisher<String>>() {
                    @Override
                    public Publisher<String> apply(List<String> strings) throws Exception {
                        return Flowable.fromIterable(strings);
                    }
                })
                .map(new Function<String, String>() {
                    @Override
                    public String apply(String s) throws Exception {
                        ZLog.i(ZTag.TAG_DEBUG, "apply : " + s);
                        try {
                            Thread.sleep(500L);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        return s;
                    }
                })
                .observeOn(AndroidSchedulers.mainThread())
                .toList()
                .map(new Function<List<String>, String>() {
                    @Override
                    public String apply(List<String> strings) throws Exception {
                        StringBuilder builder = new StringBuilder();
                        for (String str : strings) {
                            builder.append(str);
                        }
                        return builder.toString();
                    }
                })
                .toFlowable()
                .subscribe(new Subscriber<String>() {
                    private Subscription subscription;

                    @Override
                    public void onSubscribe(Subscription s) {
                        ZLog.i(ZTag.TAG_DEBUG, "onStart");
                        subscription = s;
                    }

                    @Override
                    public void onNext(String s) {
                        ZLog.i(ZTag.TAG_DEBUG, "onNext : " + s);
                        subscription.request(1); // 发送一个数据
                    }

                    @Override
                    public void onError(Throwable t) {
                        ZLog.i(ZTag.TAG_DEBUG, "onError : " + t.toString());
                    }

                    @Override
                    public void onComplete() {
                        ZLog.i(ZTag.TAG_DEBUG, "onComplete");
                    }

                });
```



构造期间

* 首先创建一个 Flowable，传入的一个 FlowableOnSubscribe 接口实例。

* 通过调用`Flowable`对象的操作函数，并传入一个执行操作对应的回调函数，例如 Consumer、Function等。

* 每通过一个操作符，会重新创建一个对应操作的 `Flowable`  ，并将之前的 `Flowable`  作为内部成员变量 source。是一个层层嵌套包裹的过程。**先创建的是上游，后创建的是下游。**

执行期间：

* 调用 `Flowable.subscribe(Subscriber)` 后进行订阅，整个流开始执行。
  * 在这里传入的一个 Subscriber接口实例，开始调用最下游的`Flowable.subscribeActual()`。
* `Flowable.subscribeActual()`函数内部实现为调用 source 的`Flowable.subscribe()`函数，会重新创建一个对应操作的Subscriber并作为参数传入，这个新创建的Subscriber 持有当前 `Flowable` 实例的 Subscriber。
* 最终层层剥开向上游传递，调用到最初创建Flowable实例的  `Flowable.subscribeActual()`。
* 接着内部会创建一个 Emitter 用于发射数据。
* 然后先调用 `Subscriber.onSubscribe()` 回调通知订阅开始，再调用 `FlowableOnSubscribe.subscribe(emitter)`回调初始化数据。
* 我们会在 `FlowableOnSubscribe.subscribe(emitter) `中 开始向下游发送数据。
* 最终就是回调到订阅处的 Subscriber的 `onNext()`、`onError()`等回调接口。



## backpressure（背压）

在数据流从上游生产者向下游消费者传输的过程中，**上游生产速度大于下游消费速度，导致下游的 Buffer 溢出**，这种现象就叫做 `Backpressure`。 可理解为下游无法承受时的一种反馈机制。

