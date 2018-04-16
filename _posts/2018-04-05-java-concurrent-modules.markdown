---
layout:     post
title:      "《java并发编程》并发模块"
subtitle:   "《java并发编程》并发模块"
date:       2018-04-05 12:00:00
author:     "julyerr"
header-img: "img/lib/concurrent/concurrent.png"
header-mask: 0.5
catalog: 	true
tags:
    - concurrent
---

>java平台类库包含了丰富的并发基础构建模块，可以使用这些基础模块构建并发应用程序。


#### 同步容器类
同步容器虽然对容器内部元素操作使用同步机制，但是对常见的复合操作：迭代，跳转（根据指定顺序找到当前元素的下一个元素）以及条件运算需要额外进行同步操作

```java
public static Object getLast(Vector list){
    int lastIndex = list.size() - 1;
    return list.get(lastIndex);
}

public static void deleteLast(Vector list){
    int lastIndex = list.size()-1;
    list.remove(lastIndex);
}
```

上面若不添加同步机制可能出现如下情形
![](/img/lib/concurrent/vector-outofbounds.png)


```java
public static Object getLast(Vector list){
    synchronized(this){
        int lastIndex = list.size() - 1;
        return list.get(lastIndex);
    }
}

public static void deleteLast(Vector list){
    synchronized(this){
        int lastIndex = list.size()-1;
        list.remove(lastIndex);
    }
}
```

**隐藏的迭代过程**

```java
private final Set<Integer> set = new HashSet<Integer>();

public synchronized void add(Integer i){
    set.add(i);
}

public synchronized void remove(Integer i){
    set.remove(i);
}

public void addTenThings(){
    Random r = new Random();
    for(int i =0 ;i<10;i++){
        add(r.nextInt());
    }
    //toString发生迭代操作,多线程操作可能抛出ConcurrentModificationException
    System.out.println("DEBUG: "+set)
}
```

---
### 并发容器
#### ConcurrentHashMap
作为并发的map容器，允许多线程同时读，对于写操作，jdk1.7及之前基于分段锁的实现，jdk1.8改用cas实现，具体[参见](http://julyerr.club/2018/02/19/collection-map/#concurrenthashmap).<br>

**提供的复合操作**

```java
//K没有响应的value映射的时候才添加
V putIfAbsent(K key,V value);
//K被映射到V才进行删除
boolean remove(K key,V value);
//只有K映射到oldValue才替换成newValue
boolean replace(K key,V oldValue,V newValue);
//k被映射到某个值才替换
V replace(K key,V newValue);
```

#### CopyOnWriteArrayList|CopyOnWriteArraySet
每次修改容器都会重新创建一个新的容器副本<br>

#### 阻塞队列和生产者消费者模式

**BlockingQueue接口**

- LinkedBlockingQueue 链表实现
- ArrayBlockingQueue 数组实现
- PriorityBlockQueue 优先级阻塞队列
- SynchronousQueue  没有存储空间，put和take都会阻塞

一个简单的桌面搜索demo

```java
public class FileCrawler implements Runnable {
    private final BlockingQueue<File> fileBlockingQueue;
    private final FileFilter fileFilter;
    private final File root;

    public FileCrawler(BlockingQueue<File> fileBlockingQueue, FileFilter fileFilter, File root) {
        this.fileBlockingQueue = fileBlockingQueue;
        this.fileFilter = fileFilter;
        this.root = root;
    }

    @Override
    public void run() {
        try {
            crawl(root);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void crawl(File root) throws InterruptedException {
        File[] entries = root.listFiles(fileFilter);
        if (entries != null) {
            for (File entry :
                    entries) {
//                逐个目录进行爬取
                if (entry.isDirectory()) {
                    crawl(entry);
                } else if (!isAlreadyIndex(entry)) {
                    fileBlockingQueue.put(entry);
                }
            }
        }
    }

    private boolean isAlreadyIndex(File entry){
        return false;
    }
}

public class Indexer implements Runnable {
    private final BlockingQueue<File> queue;

    public Indexer(BlockingQueue<File> queue) {
        this.queue = queue;
    }

    @Override
    public void run() {
        try {
            while(true){
                indexFile(queue.take());
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void indexFile(File entry){

    }
}

public class StartSearch {
    private static final int BOUND = 10;
    private static final int N_CONSUMERS = 10;

    public static void startIndexing(File[] roots){
        BlockingQueue<File> queue = new LinkedBlockingDeque<>(BOUND);
        FileFilter fileFilter = new FileFilter() {
            @Override
            public boolean accept(File pathname) {
                return true;
            }
        };

        for (File file :
                roots) {
            new Thread(new FileCrawler(queue,fileFilter,file)).start();
        }
        for (int i = 0; i < N_CONSUMERS; i++) {
            new Thread(new Indexer(queue)).start();
        }
    }
}
```

**Deque接口**

- ArrayDeque
- LinkedBlockingDeque 每个消费者拥有自己的双端队列，当一个线程完成自己的任务之后，可以从其他线程任务队列中获取资源，使所有的线程都有工作

**中断**<br>
java中中断是一种协作机制，一个线程不能强制其他线程停止正在执行的操作，而只是设置为该线程设置一个中断标志位，抛出一个中断异常（抛出异常，中断标志位会恢复）。通常有两种处理机制

- 传递异常 将中断异常抛给方法调用者
- 恢复中断  

```java
public class TaskRunnable implements Runnable{
    BlockingQueue<Task> queue;

    public void run(){
        try{
            processTask(queue.take());
        }catch(InterruptedException e){
            Thread.currentThread().interrupt();
        }
    }
}
``` 

更加高级的中断处理参见后文，例如针对不支持中断的线程操作（socketio等）参见后文。

---
### 同步工具类

#### CountDownLatch
保证一个或者多个线程等待一组事件发生

```java
public class CountDownLatchDemo {
    public long timeTasks(int nThreads, final Runnable task) throws InterruptedException {
        final CountDownLatch startGate = new CountDownLatch(1);
        final CountDownLatch endGate = new CountDownLatch(nThreads);

        for (int i = 0; i < nThreads; i++) {
            Thread t = new Thread() {
                @Override
                public void run() {
                    try {
                        startGate.await();
                        try {
                            task.run();
                        } finally {
                            endGate.countDown();
                        }
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            };
            t.start();
        }
        long start = System.nanoTime();
//        所有的线程开始执行
        startGate.countDown();
        long end = System.nanoTime();
        return end - start;
    }
}
```

#### FutureTask

Call 相对Run而言更具有通用性，可以返回结果和运行中的异常信息  
Future 
    任务抛出异常，封装成ExecutionException并重新抛出，可以通过getCause来获取被封装的结果；
    如果任务取消，抛出CancellationException.

```java
public interface Callable<V> {
    V call() throws Exception;
}

public interface Future<V> {
    boolean cancel(boolean var1);
    boolean isCancelled();
    boolean isDone();
    V get() throws InterruptedException, ExecutionException;
    V get(long var1, TimeUnit var3) throws InterruptedException, ExecutionException, TimeoutException;
}
``` 

调用ExecutorService submit方法将返回一个Future对象，而且显式创建某个Runnable或Callable也可以实例化一个FutureTask.
ExecutorService的newTaskFor也可以返回一个FutureTask对象


异步处理,提交的任务可以处于以下三种状态：等待运行、正在运行和运行完成。
Future.get取决于任务的状态，如果任务完成，get直接返回结果;否则阻塞到结果返回或者抛出异常。

```java
public class Preloader {
    private final FutureTask<ProductInfo> futureTask = new FutureTask<>(new Callable<ProductInfo>() {
        @Override
        public ProductInfo call() {
            return loadProductInfo();
        }
    });

    private final Thread thread = new Thread(futureTask);

    public void start() {
        thread.start();
    }

    public ProductInfo get() throws InterruptedException, DataLoadException {
        try {
            return futureTask.get();
        } catch (ExecutionException e) {
            Throwable cause = e.getCause();
            if (cause instanceof DataLoadException) {
                throw (DataLoadException) cause;
            } else {
                throw launderThrowable(cause);
            }
        }
    }

    class ProductInfo {

    }

    private ProductInfo loadProductInfo() {
        return new ProductInfo();
    }

    private class DataLoadException extends Exception {

    }

    public static RuntimeException launderThrowable(Throwable t) {
        if (t instanceof RuntimeException) {
            return (RuntimeException) t;
        } else if (t instanceof Error) {
            throw (Error) t;
        } else {
            throw new IllegalStateException("unchecked ", t);
        }
    }
}
```     

#### Semphore 
用来控制同时访问某个特定资源的操作数量，acquire获得许可，release将返回一个许可。使用Semaphore可以将任何一种容器变成有界阻塞容器

```java
public class DoundedHashSet<T> {
    private final Set<T> set;
    private final Semaphore sem;

    public DoundedHashSet(int bound) {
        this.set = (Set<T>) Collections.synchronizedCollection(new HashSet<>());
        this.sem = new Semaphore(bound);
    }

    public boolean add(T o) throws InterruptedException{
        sem.acquire();
        boolean wasAdded = false;
        try{
            wasAdded = set.add(o);
            return wasAdded;
        }finally {
            if(!wasAdded){
                sem.release();
            }
        }
    }

    public boolean remove(Object o){
        boolean wasRemoved = set.remove(o);
        if(wasRemoved){
            sem.release();
        }
        return wasRemoved;
    }
}
```

#### CyclicBarrier 
和CountDownLatch区别在于，闭锁等待的是事件但是CyclicBarrier等待的是线程，而且栅栏可以被重复使用，可以在栅栏准备好的情况之下设置一个触发函数。

```java
public class CyclicBarrierDemo {
    private final Board mainBoard;
    private final CyclicBarrier barrier;
    private final Worker[] workers;


    private int computeValue(int x, int y) {
        return 0;
    }

    public CyclicBarrierDemo(final Board mainBoard) {
        this.mainBoard = mainBoard;
        int count = Runtime.getRuntime().availableProcessors();
        this.barrier = new CyclicBarrier(count, new Runnable() {
            @Override
            public void run() {
                mainBoard.commitNewValues();
            }
        });
        this.workers = new Worker[count];
        for (int i = 0; i < count; i++) {
            workers[i] = new Worker(mainBoard.getSubBoard(count, i));
        }
    }

    private class Worker implements Runnable {
        private final Board board;

        public Worker(Board board) {
            this.board = board;
        }

        @Override
        public void run() {
            while (!board.hasConverged()) {
                for (int i = 0; i < board.getMaxX(); i++) {
                    for (int j = 0; j < board.getMaxY(); j++) {
                        board.setNewValue(i, j, computeValue(i, j));
                    }
                }
            }
            try {
                barrier.await();
            } catch (InterruptedException e) {
                return;
            } catch (BrokenBarrierException e) {
                return;
            }
        }
    }
}
``` 

#### 构建高效且可伸缩的结果缓存

```java
public class MemoizerSynchronized<A, V> implements Computable<A, V> {
    private final Map<A, V> cache = new HashMap<>();
    private final Computable<A, V> c;


    public MemoizerSynchronized(Computable<A, V> c) {
        this.c = c;
    }

    // 计算过程花费时间过大，后续的任务只能阻塞等待
    @Override
    public synchronized V compute(A arg) throws InterruptedException {
        V result = cache.get(arg);
        if (result == null) {
            result = c.compute(arg);
            cache.put(arg, result);
        }
        return result;
    }
}
```

![](/img/lib/concurrent/mem-synchronized.png)

```java
//...
@Override
public V compute(A arg) throws InterruptedException {
    V result = cache.get(arg);
    if (result == null) {
        result = c.compute(arg);
        cache.put(arg, result);
    }
    return result;
}
```

上面这种改进，仍然较大几率出现重复计算的可能性

![](/img/lib/concurrent/mem-concurrent.png)

**使用FutureTask进行改进**

```java
public class MemoizerFutureBefore<A,V> implements Computable<A,V> {
    private final Map<A,Future<V>> cache = new ConcurrentHashMap<>();
    private final Computable<A,V> c;

    public MemoizerFutureBefore(Computable<A, V> c) {
        this.c = c;
    }

    @Override
    public V compute(final A arg) throws InterruptedException {
        Future<V> f = cache.get(arg);
//        仍然可能出现计算的重复操作
        if(f == null){
            Callable<V> eval = new Callable<V>() {
                @Override
                public V call() throws Exception {
                    return c.compute(arg);
                }
            };
            FutureTask<V> ft = new FutureTask<>(eval);
            f = ft;
            cache.put(arg,ft);
            ft.run();
        }
        try {
            return f.get();
        } catch (ExecutionException e) {
            throw Preloader.launderThrowable(e.getCause());
        }
    }
}
```

出现重复计算的可能性大大降低，但是仍然无法消除重复计算的情况

![](/img/lib/concurrent/mem-future-before.png)


**ConcurrentHashMap中提供的复合操作消除重复计算情形**

```java
public class Memoizer<A, V> implements Computable<A, V> {
    private final ConcurrentMap<A, Future<V>> cache =
            new ConcurrentHashMap<A, Future<V>>();
    private final Computable<A, V> c;

    public Memoizer(Computable<A, V> c) {
        this.c = c;
    }

    public V compute(final A arg) throws InterruptedException {
        while (true){
            Future<V> f = cache.get(arg);
            if (f == null) {
                Callable<V> eval = new Callable<V>() {
                    public V call() throws InterruptedException {
                        return c.compute(arg);
                    }
                };
                FutureTask<V> ft = new FutureTask<V>(eval);
//                concurrentHashMap提供的操作                
                f = cache.putIfAbsent(arg, ft);
                if (f == null) {
                    f = ft;
                    ft.run();
                }
            }
            try {
                return f.get();
            } catch (CancellationException e) {
                cache.remove(arg, f);
            } catch (ExecutionException e) {
                throw launderThrowable(e.getCause());
            }
        }
    }
}
```

---
### 参考资料
- 《Java并发编程实战》