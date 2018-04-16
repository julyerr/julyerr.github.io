---
layout:     post
title:      "《java并发编程》任务取消"
subtitle:   "《java并发编程》任务取消"
date:       2018-04-08 12:00:00
author:     "julyerr"
header-img: "img/lib/concurrent/concurrent.png"
header-mask: 0.5
catalog:    true
tags:
    - concurrent
---

>一个行为良好的软件能够完善的处理失败、关闭和取消等过程，java没有提供任何机制安全终止线程，但是提供了中断这种协作机制。


### 取消与关闭

#### 设置标志位
比较容易想到的是通过设置标志位的方式取消任务

```java
public class PrimeGenerator implements Runnable {
    private final List<BigInteger> primes = new ArrayList<>();
    private volatile boolean cancelled;

    @Override
    public void run() {
        BigInteger p = BigInteger.ONE;
        while (!cancelled) {
            p = p.nextProbablePrime();
            synchronized (this) {
                primes.add(p);
            }
        }
    }

    public void cancel() {
        cancelled = true;
    }

    public synchronized List<BigInteger> getPrimes() {
        return new ArrayList<>(primes);
    }
}
```

设置标志位有个缺陷就是，如果当前线程已经被阻塞不能获取到阻塞的状态的话，这种方式就会失效

```java
public class BrokenPrimeProducer extends Thread{
    private final BlockingQueue<BigInteger> queue;
    private volatile boolean cancelled = false;

    BrokenPrimeProducer(BlockingQueue<BigInteger> queue){
        this.queue = queue;
    }

    @Override
    public void run() {
        BigInteger p = BigInteger.ONE;
        while(!cancelled){
            try {
            //put调用的时候发生阻塞
                queue.put(p = p.nextProbablePrime());
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
```

#### 使用中断

通常认为中断是取消线程的最好的方法：<br>
java中中断并不能立即停止某个线程，而是给该线程设置了一个中断标志位，至于具体的处理还需要自己handle。抛出异常之后，中断标志位已经清空，可以再次触发中断，Thread.current.interrupt()

```java
public class PrimeProducer extends Thread {
    private final BlockingQueue<BigInteger> queue;

    PrimeProducer(BlockingQueue<BigInteger> queue) {
        this.queue = queue;
    }

    @Override
    public void run() {
        BigInteger p = BigInteger.ONE;
        try {
            while (!Thread.currentThread().isInterrupted()) {
                queue.put(p = p.nextProbablePrime());
            }
        } catch (InterruptedException e) {
//            线程退出
        }
    }
    
    public void cancel(){
        interrupt();
    }
}
```    

**响应中断有两种实用的策略**

- 传递异常

```java
public Task getNextTask() throws InterruptedException{
    return queue.take();
}
```

- 恢复中断状态

```java
public Task getNextTask(BlockingQueue<Task> queue){
    boolean interrupted = false;
    try{
        while(true){
            try{
                return queue.take();
            }catch (InterruptedException e){
                interrupted = true;
                //重新尝试
            }
        }
    }finally{
        if(interrupted){
            Thread.currentThread().interrupt();
        }
    }
}
```    

#### 计时运行

```java
private static final ScheduledExecutorService cancelExec = ...;
public static void timedRun(Runnable r,long timeout,TimeUnit unit){
    final Thread taskThread = Thread.currentThread();
    cancelExec.schedule(new Runnable(){
        public void run(){ taskThread.interrupt();}
        },timeout,unit);
    r.run();
}
```

上面这种处理有一定的风险，函数没有处理中断策略。如果任务在超时之前完成，线程此时运行的状态未知，触发中断可能出现意想不到的结果。<br>

**通过Future**

```java
public static void timedRun(final Runnable r,long timeout,TimeUnit unit) throws InterruptedException{
    Future<?> task = taskExec.submit(r);
    try{
        task.get(timeout,unit);
    }catch(TimeoutException e){
        //任务取消
    }catch (ExecutionException e){
        throw launderThrowable(e.getCause());
    }finally{
        //如果任务已经取消的话，执行下面这步不会有其他的操作
        //如果任务正在运行，那么线程将被中断
        task.cancel(true);
    }
}
```

Future.cancel(boolean mayInterruptIfRunning) 参数设置为true,表示如果线程正在运行，那么中断线程；线程未启动，则
不启动该线程。

---
### 处理不可中断阻塞
对于不能响应中断的任务，有不同的策略，例如重写interrupt()方法，在该方法中处理逻辑，然后对可能抛出的异常进行捕获

- 同步Socket I/O
    可以关闭底层套接字，read或者write将抛出SocketException
- 同步I/O
    - 中断InterruptibleChannel上等待的线程，将抛出ClosedByInterruption；
    - 关闭InterruptibleChannel通道，线程将抛出AsynchronousClosedException；
- Select的异步io
    中断线程，将抛出ClosedSelectorException
- 获取某个锁
    lockInterruptibly方法支持       
- ExecutorService中可以为任务重写cancel方法

下面是一个关闭套接字的demo

```java
public class ReaderThread extends Thread {
    private final Socket socket;
    private final InputStream in;

    public ReaderThread(Socket socket) throws IOException{
        this.socket =socket;
        this.in = socket.getInputStream();
    }

    public void interrupt(){
        try {
            socket.close();
        } catch (IOException e) {

        }finally {
//            中断该线程
            super.interrupt();
        }
    }

    @Override
    public void run() {
        byte[] buf = new byte[1024];
        try {
            while(true){
                int count = in.read(buf);
                if(count<0){
                    break;
                }else if(count>0){
                    processBuffer(buf,count);
                }
            }
        } catch (IOException e) {
//            允许线程退出
        }
    }

    private void processBuffer(byte[] buf,int count){
    }
}
```    

也可以自定义Future来取消任务

```java
public interface CancellableTask<T> extends Callable<T> {
    void cancel();
    RunnableFuture<T> newTask();
}

public abstract class SocketUsingTask<T> implements CancellableTask<T> {
    private Socket socket;

    protected synchronized void setSocket(Socket s) {
        socket = s;
    }

    public synchronized void cancel() {
        if (socket != null) {
            try {
                socket.close();
            } catch (IOException e) {
            }
        }
    }

    public RunnableFuture<T> newTask() {
        return new FutureTask<T>(this) {
            public boolean cancel(boolean mayInterruptIfRunning) {
                try {
                    SocketUsingTask.this.cancel();
                } finally {
                    return super.cancel(mayInterruptIfRunning);
                }
            }
        };
    }
}

public class CancellingExecutor extends ThreadPoolExecutor {

    protected <T> RunnableFuture<T> newTaskFor(Callable<T> callable){
        if(callable instanceof CancellableTask){
            return ((CancellableTask<T>) callable).newTask();
        }else{
            return super.newTaskFor(callable);
        }
    }

    public CancellingExecutor(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue) {
        super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue);
    }
}
```

---
### 关闭基于线程的服务

为了更好的封装，应用程序可以拥有服务，服务可以拥有工作线程，但是应用程序不能拥有工作线程。那么服务应该提供关闭自己以及相应的工作线程的方法。<br>

下面是一个日志打印的demo，也是多生产者单消费者模型

```java
//可以保证多个线程同时操作日志信息的书写
public class LogService {
    private final BlockingQueue<String> queue;
    private final LoggerThread loggerThread;
    private final PrintWriter writer;
    private boolean isShutdown;
    private int reservation;

    public LogService(BlockingQueue<String> queue, LoggerThread loggerThread, PrintWriter writer) {
        this.queue = queue;
        this.loggerThread = loggerThread;
        this.writer = writer;
    }

    public void start() {
        loggerThread.start();
    }

    public void stop() {
        synchronized (this) {
            isShutdown = true;
        }
        loggerThread.interrupt();
    }

//    通过一个计数器保证即使关闭服务的时候同时也能保证所有的日志信息依然能够打印完成
    public void log(String msg) throws InterruptedException {
        synchronized (this) {
            if (isShutdown) {
                throw new IllegalStateException();
            }
            ++reservation;
        }
        queue.put(msg);
    }

    private class LoggerThread extends Thread {
        public void run() {
            try {
                while (true) {
                    synchronized (LogService.this) {
                        if (isShutdown && reservation == 0) {
                            break;
                        }
                    }
                    String msg = queue.take();
                    synchronized (LogService.this) {
                        --reservation;
                    }
                    writer.println(msg);
                }
            } catch (InterruptedException e) {
            } finally {
                writer.close();
            }
        }
    }
}
``` 

可以使用封装ExecutorService对象，进行操作

```java
public class LogServiceExec {
    private final ExecutorService executorService = Executors.newSingleThreadExecutor();
    private static final int TIMEOUT = 10000;
    private static final TimeUnit UNIT = TimeUnit.SECONDS;
    public void start(){
        
    }
    
    public void stop() throws InterruptedException{
        try {
            executorService.shutdown();
            executorService.awaitTermination(TIMEOUT,UNIT);
        } finally {
            writer.close();
        }
    }
    
    public void log(String msg){
        try {
            executorService.execute(new WriterTask(msg));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

**毒丸对象**<br>
通常使用在队列消息中，在任务结束的时候提交一个特殊的对象，处理的时候判断是否为特殊对象并结束自己任务（FIFO结构保证所有的任务已经全部运行完成）


#### shutdownNow局限性
shutdownNow关闭服务时，尝试取消正在执行的任务，返回所有已提交但尚未开始的任务。对于那些已经开始但尚未结束的任务，需要自身进行检查。<br>

下面以简单的爬虫程序为例，保存关闭时仍然处于运行中的任务

```java
public class TrackingExecutor extends AbstractExecutorService {
    //...
    private final ExecutorService exec;

    private final Set<Runnable> tasksCancelledAtShutdown = Collections.synchronizedSet(new HashSet<Runnable>());

    public TrackingExecutor(ExecutorService executorService) {
        exec = executorService;
    }

    public List<Runnable> getCancelledTasks() {
        if (!exec.isTerminated()) {
            throw new IllegalStateException();
        }
        return new ArrayList<>(tasksCancelledAtShutdown);
    }

    @Override
    public void execute(final Runnable command) {
        exec.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    command.run();
                } finally {
                    if (isShutdown() && Thread.currentThread().isInterrupted()) {
                        tasksCancelledAtShutdown.add(command);
                    }
                }
            }
        });
    }
}

public abstract  class WebCrawler {
    private final int TIMEOUT = 100;
    private final TimeUnit TIMEUNIT = TimeUnit.SECONDS;

    private volatile TrackingExecutor executor;
    private final Set<URL> urls = new HashSet<>();

    public synchronized void start(){
        executor = new TrackingExecutor(Executors.newCachedThreadPool());
        for (URL url :
                urls) {
            submitCrawlTask(url);
        }
    }

    public synchronized void stop() throws InterruptedException{
        try {
            saveUncrawled(executor.shutdownNow());
            if(executor.awaitTermination(TIMEOUT,TIMEUNIT)){
                saveUncrawled(executor.getCancelledTasks());
            }
        } finally {
            executor = null;
        }
    }

    protected abstract List<URL> processPage(URL url);

    private void saveUncrawled(List<Runnable> uncrawled){
        for (Runnable task :
                uncrawled) {
            urls.add(((CrawlTask)task).getPage());
        }
    }

    private void submitCrawlTask(URL url){
        executor.execute(new CrawlTask(url));
    }

    private class CrawlTask implements Runnable{
        private final URL url;

        private CrawlTask(URL url) {
            this.url = url;
        }

        public void run(){
            for (URL link :
                    processPage(url)) {
                if(Thread.currentThread().isInterrupted()){
                    return;
                }
                submitCrawlTask(url);
            }
        }

        public URL getPage(){
            return url;
        }
    }
}
```

---
### 捕获线程异常
捕获线程异常的错误，线程非正常退出结果可能是良性也可能是恶性的。在线程池中丢失一个线程可能只是对性能带来一点影响，但是在GUI应用中，一个GUI线程退出，那么将可能出现窗口卡死的状态。因此，线程应该考虑失败情况，并且在try-catch或者try-finally进行处理。

```java
public void run(){
    Throwable thrown = null;
    try{
        while(!isInterrupted()){
            runTask(getTaskFromWorkQueue());
        }catch (Throwable e){
            thrown = e;
        }finally{
            threadExited(this,thrown);
        }
    }
}
```

对于未捕获的异常,Thread API提供了**UncaughtExceptionHandler**异常处理器,如果没有提供实现，默认行为是输出到System.err。

```java
public interface UncaughtExceptionHandler{
    void uncaughtException(Thread t,Throwable e);
}
```

只有通过execute提交的任务才能将抛出的异常交给未捕获异常处理器，通过submit提交的任务由于异常而结束，将被Future.get封装在ExecutionException。

---
### JVM关闭
**钩子函数**<br>
关闭钩子是指通过Runtime.addShutdownHook注册的但尚未开始的线程。这些钩子可以用于实现服务或者应用程序的清理工作，例如删除临时文件，或者清除无法由操作系统自动清除的资源。<br>
在正常关闭中，JVM首先调用所有已注册的关闭钩子（并发进行，需要保证钩子线程的安全性），但是不能保证关闭钩子的调用顺序。<br>
如果JVM由于内部错误崩溃、Runtime.halt()或者`kill -9`等强制停止的指令之后，shutdownHook可能没有执行完毕。因此需要正确编写shutdownHook程序，确保不会造成死锁，并且能够尽快退出程序。

```java
public void start(){
    Runtime.getRuntime().addShutdownHook(new Thread(){
        public void run(){
            try{
                LogService.this.stop();}
            catch(InterruptionException e){}
        }});
}
```

**守护线程**<br>

- java中线程分为普通线程和守护线程两种，两者区别在于，jvm退出的时候，如果存在普通线程不会直接退出；反之，只存在守护线程的话，直接退出;
- JVM启动时，除主线程之外的线程均是普通线程（子线程继承父线程的守护状态），可以通过setDaemon(true)设置某个线程为守护线程;
- 守护线程通常用于周期性的操作，例如周期性将内存缓存移除逾期的数据。<br>

**终结器**<br>
通常用于资源回收，在jvm正常关闭，所有关闭钩子执行结束时，如果runFinalizersOnExit为true，那么JVM将运行终结器。实际场景中尽量避免使用终结器。

---
### 参考资料
- 《Java并发编程实战》