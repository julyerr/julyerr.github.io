---
layout:     post
title:      "java 线程池、Future & Callable"
subtitle:   "java 线程池、Future & Callable"
date:       2018-02-16 8:00:00
author:     "julyerr"
header-img: "img/thread/thread-pool.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - java
    - thread-support
---

### 线程池工作原理

![](/img/thread/thread-pool-inherit.jpg)
图为线程池继承关系<br>
**ThreadPoolExecutor最重要的一个构造方法**<br>
```java
public class ThreadPoolExecutor extends AbstractExecutorService {
    public ThreadPoolExecutor(int corePoolSize,
                              int maximumPoolSize,
                              long keepAliveTime,TimeUnit unit,
                              BlockingQueue<Runnable> workQueue,
                              ThreadFactory threadFactory,
                              RejectedExecutionHandler handler);
}
```
- corePoolSize(线程池基本大小)：提交一个任务便创建一个线程来执行任务。不超过maximumPoolSize值时，线程池中最多有corePoolSize个线程工作;
- maximumPoolSize（线程池最大数量）：线程池允许创建的最大线程数，如果使用无界任务队列，此参数无意义;
- keepAliveTime(线程活动保持时间)：线程池的工作线程空闲后，保持存活的时间；任务执行时间较短，可以调大时间增加线程利用率;
- TimeUnit(线程活动保持时间单位)：天（DAYS）、小时（HOURS）、分钟（MINUTES）、毫秒（MILLISECONDS）、 微秒（MICROSECONDS， 千分之一毫秒） 和纳秒（NANOSECONDS， 千分之一微秒）；
- runnableTaskQueue（任务队列）：用于保存等待执行的任务的阻塞队列,可选择如下队列
    - ArrayBlockingQueue:基于数组结构的有界阻塞队列,按FIFO对元素进行排序;
	- LinkedBlockingQueue:基于链表结构的阻塞队列，按FIFO排序元素。吞吐量通常高于ArrayBlockingQueue，静态工厂方法Executors.newFixedThreadPool()使用了这个队列；
	- SynchronousQueue：不存储元素的阻塞队列，每个插入操作必须等到另一个线程调用移除操作。吞吐量通常高于LinkedBlockingQueue，静态工厂方法Executors.newCachedThreadPool使用了这个队列。
- ThreadFactory:创建线程的工厂，可以配置更加有意义的名称；
- RejectedExecutionHandler（饱和策略）：当队列和线程池都满时候，对于新添加进行的任务，需要采取的策略。有以下四种，默认是AbortPolicy;
	- AbortPolicy：直接抛出异常；
	- CallerRunsPolicy：使用调用者所在线程来运行任务；
	- DiscardOldestPolicy：丢弃队列里最近的一个任务， 并执行当前任务；
	- DiscardPolicy：直接丢弃任务。

**线程池工作流程**<br>
![](/img/thread/thread-pool-flow.png)
图为线程池工作流程，流程比较清晰。首先在corePool大小范围内创建线程；如果线程数量超过corePool，新创建的线程加入BlockQueue<Runnable>中；如果阻塞队列已满，则继续在maximumPool大小范围内创建线程；如果还有线程加入，按照RejectedExecutionHandler处理。
以下为示例代码
```java
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

public class ThreadPoolTest implements Runnable {

    @Override
    public void run() {
        synchronized (this) {
            System.out.println(Thread.currentThread().getName());
            try {
                Thread.sleep(3000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public static void main(String[] args) {
        BlockingQueue<Runnable> queue = new ArrayBlockingQueue<Runnable>(5);
        ThreadPoolExecutor executor = new ThreadPoolExecutor(3, 6, 1,
                TimeUnit.DAYS, queue);
        for (int i = 0; i < 12; i++) {
            executor.execute(new Thread(new ThreadPoolTest(), "TestThread"
                    .concat("" + i)));
            int threadSize = queue.size();
            System.out.println("线程队列大小为-->" + threadSize);
        }
        executor.shutdown();
    }
}
```
开始3个线程被创建出来运行，后面的5个线程加入阻塞队列，`maximumPoolSize-corePoolSize`大小即3个线程被创建出来运行，最后一个线程直接抛出异常。<br>

可以重写ThreadPoolExecutor中`beforeExecute`、`afterExecute`和`terminated`方法自定义操作。

**关闭线程池**<br>
	shutdown()和shutdownNow()均能关闭线程池，两者的区别如下：
	
- shutdown()不允许添加新的任务，等池中所有的任务执行完毕之后再关闭线程池。
- shutdownNow()不允许添加新的任务，立刻关闭线程池。不管池中是否还存在正在运行的任务，尝试关闭当前正在运行的任务。然后返回待完成任务的清单。

---
#### 四种线程池
Executors提供的系列工厂方法
```java
// 创建固定数目线程的线程池。
public static ExecutorService newFixedThreadPool(int nThreads)

// 创建一个可缓存的线程池
public static ExecutorService newCachedThreadPool()

// 创建一个单线程化的Executor
public static ExecutorService newSingleThreadExecutor()

// 创建一个支持定时及周期性的任务执行的线程池，多数情况下可用来替代Timer类
public static ScheduledExecutorService newScheduledThreadPool(int corePoolSize)
```
- **newCachedThreadPool()**<br>
	如果以前线程可用，调用execute将重用以前构造的线程;如果现有线程没有可用的，则创建一个新线 程并添加到池中；终止并从缓存中移除那些已有60秒钟未被使用的线程。因此缓存线程池通常用于执行生存期较短的任务。

- **newFixedThreadPool(int)**<br>
	任意时刻，最多只能有固定数目的线程存在;多余的线程要建立只能放在另外的队列中等待。由于没有IDLE机制，通常用于服务器上的任务中。

#### 线程数量优化
通常，假设服务器中CPU个数为N

- 如果是CPU密集型应用，则线程池大小设置为N+1
- 如果是IO密集型应用，则线程池大小设置为2N+1
	
并发过程中合理使用线程池有以下优势

- 减小系统开销，重复利用已经创建好的线程
- 提高响应速度，任务直接在已经创建好的线程上运行
- 更好对资源进行管理，线程池能够统一分配、调优和监控资源

---
#### Callable、Future、FutureTask
**Runnable**<br>
```java
public interface Runnable {
    public abstract void run();
}
```
**Callable**<br>
```java
public interface Callable<V> {
    V call() throws Exception;
}
```
功能类似Runnable，但是更加强大，支持返回值(与Future结合使用)而且能够抛出异常.<br>
**Future**
```java
public interface Future<V> {

    boolean cancel(boolean mayInterruptIfRunning);

    boolean isCancelled();

    boolean isDone();
   
    V get() throws InterruptedException, ExecutionException;

    V get(long timeout, TimeUnit unit)
        throws InterruptedException, ExecutionException, TimeoutException;
}
```
用于对Callable执行结果取消、完成以及获取结果等操作<br>
**FutureTask**
```java
public class FutureTask<V> implements RunnableFuture<V> 
public interface RunnableFuture<V> extends Runnable, Future<V> 
```
既可以作为Runnable被线程执行，又可以作为Future得到Callable的返回值。
以下为一个示例
```java
public class CallableAndFuture {
    public static void main(String[] args) {
        Callable<Integer> callable = new Callable<Integer>() {
            public Integer call() throws Exception {
                return new Random().nextInt(100);
            }
        };
        FutureTask<Integer> future = new FutureTask<Integer>(callable);
        new Thread(future).start();
        try {
            Thread.sleep(3000);// 可能做一些事情
            System.out.println(future.get());
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (ExecutionException e) {
            e.printStackTrace();
        }
    }
}
```

**ExecutorService对Callable的支持**<br>
Future<T> submit(Callable<T> target)：向线程池提交target任务，返回包装成的FutureTask任务。
List<Future<T>> invokeAll(Collection<Callable<T>> tasks)：批量提交任务，当所有任务都完成时，返回包装成的FutureTask任务组成的列表。

以下是一个示例
```java
public class FutureTest {
    public static void main(String[] args) throws ExecutionException, InterruptedException {
        ExecutorService executorService = Executors.newCachedThreadPool();
        Future<String> future = executorService.submit(new MyCallable());
        System.out.println("do something...");
        System.out.println("fetch the output "+future.get());
        System.out.println("done!");
        executorService.shutdown();
    }
}

class MyCallable implements Callable<String>{
    @Override
    public String call() throws Exception {
        System.out.println("in call ");
        Thread.sleep(3000);
        return "ok";
    }
}    
```
### 参考资料
- [Java线程池的使用总结](http://blog.csdn.net/fuzhongmin05/article/details/71512385)
- [Java线程池总结](https://www.cnblogs.com/aheizi/p/6851416.html)
- [Java线程：Runnable、Callable、Future、FutureTask](https://www.jianshu.com/p/cf12d4244171)
- [java多线程总结笔记3——Callable和Future](http://blog.csdn.net/wolfdrake/article/details/37767153)