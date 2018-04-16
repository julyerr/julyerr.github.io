---
layout:     post
title:      "《java并发编程》任务执行"
subtitle:   "《java并发编程》任务执行"
date:       2018-04-06 12:00:00
author:     "julyerr"
header-img: "img/lib/concurrent/concurrent.png"
header-mask: 0.5
catalog: 	true
tags:
    - concurrent
---

>构建一个高并发的应用通常从任务启动、执行、关闭、取消等方面进行考虑，由于篇幅的原因，本文就任务的启动和执行进行总结，在下篇文章中会对任务的取消和关闭进行总结。

### 任务执行

**串行创建任务**

```java
public class SingleThreadWebServer {
    public static void main(String[] args) throws IOException {
        ServerSocket socket = new ServerSocket(80);
        while (true) {
            Socket connection = socket.accept();
            handleRequest(connection);
        }
    }

    public static void handleRequest(Socket connection) {
    }
}
```

**每个任务一个线程**

```java
public class ThreadPerTaskWebServer {
    public static void main(String[] args) throws IOException {
        ServerSocket socket = new ServerSocket(80);
        while (true) {
            final Socket connection = socket.accept();
            Runnable task = new Runnable() {
                @Override
                public void run() {
                    handleRequest(connection);
                }
            };
            new Thread(task).start();
        }
    }
}
```

无限制创建线程缺点

- 线程生命周期开销大
- 资源消耗 大量空闲的线程会占用许多内存，而且多个线程之间竞争CPU等资源会产生较大的性能开销
- 稳定性 系统对线程数量有一定的限制，破坏了这些限制可能抛出OutOfMemoryError等异常



### Executor框架

java类库提供了线程池，简化了线程的管理工作。Excutor是java.util.concurrent下线程池的一种实现，基于生产者-消费者模式，提交任务操作相当于生产者，执行任务的线程相当于消费者。执行单元为Executor而不是Task。

```java
public interface Executor{
    void execute(Runnable command);
}
```

**使用Executor框架的web服务器**

```java
public class TaskExecutionWebServer {
    private static final int NTHREADS = 100;
    private static final Executor exec = Executors.newFixedThreadPool(NTHREADS);

    public static void main(String[] args) throws IOException{
        ServerSocket socket = new ServerSocket(80);
        while(true){
            final Socket connection = socket.accept();
            Runnable task = new Runnable() {
                @Override
                public void run() {
                    SingleThreadWebServer.handleRequest(connection);
                }
            };
            exec.execute(task);
        }
    }
}
```

类库提供了一些**默认的配置**

- newFixedThreadPool 固定长度的线程池
- newCachedThreadPool 超过需求会回收空闲的线程，需求增加，添加新的线程
- newSingleThreadExecutor 单线程的Executor
- newScheduledThreadPool创建固定长度的线程池，延迟或者定时的方式来执行任务，类似timer

**生命周期**<br>
Executor扩展了 ExecutorService接口，添加了生命周期管理的方法

```java
public interface ExecutorService extends Executor{
    //平缓的关闭服务，不接受新任务，等待正在执行的任务执行完成
    void shudown();
    //立即关闭服务，不接受新任务，终止正在运行的任务，并且返回影响的任务列表
    List<Runnable> shutdownNow();
    boolean isShutdown();
    boolean isTerminated();
    //等待指定时间然后调用shutdown
    bolean awaitTermination(long timeout,TimeUnit unit) throws InterruptionException;
}
```

下面是封装了ExecutorService的类，可以提供参数控制服务器关闭的功能

```java
public class LifecycleWebServer {
    private final ExecutorService exec = Executors.newFixedThreadPool(10);

    public void start() throws IOException{
        ServerSocket serverSocket = new ServerSocket(80);
        while(!exec.isShutdown()){
            final Socket connection = serverSocket.accept();
            exec.execute(new Runnable() {
                @Override
                public void run() {
                    handleRequest(connection);
                }
            });
        }
    }

    public void stop(){
        exec.shutdown();
    }

    void handleRequest(Socket connection){
        Request request = readRequest(connection);
        if(isShutdownRequest(request)){
            stop();
        }else{
            dispathRequest(request);
        }
    }

    class Request{}
    private Request readRequest(Socket socket){
        return new Request();
    }

    private void dispathRequest(Request request){

    }

    private boolean isShutdownRequest(Request request){
        return false;
    }
}
```

**延迟任务**

- Timer只启动一个线程执行任务，如果某个任务执行时间过长，将破坏其他线程的定时精确性;
- TimerTask抛出异常之后，Timer并不捕获异常，而是终止整个定时线程。如果要使用调度服务可以考虑使用ScheduledThreadPoolExecutor提供的调度功能，保证任务的可靠性。

```java
public class TimerWrong {
    public static void main(String[] args) throws InterruptedException {
        Timer timer = new Timer();
        timer.schedule(new ThrowTask(), 1);
        Thread.sleep(1000);
        timer.schedule(new ThrowTask(), 1);
        Thread.sleep(1000);
    }

    static class ThrowTask extends TimerTask {
        @Override
        public void run() {
            throw new RuntimeException();
        }
    }
}
```

---
### 找到程序的并发性
开发一个高并发的程序需要首先找到应用程序的并行性，下面以一个具体的下载网页然后渲染的过程讲解如何提高应用的并发性。<br>

网页渲染的demo,下面先呈现出网页内容，后面加载图片（串行）

```java
public class SingleThreadRenderer {

    public void renderTesxt(CharSequence source){
    }
    public void renderImage(ImageData data){
    }
    public List<ImageInfo> scanForImageInfo(CharSequence source){
        return new ArrayList<>();
    }

    public void renderPage(CharSequence source){
        renderTesxt(source);
        List<ImageData> imageData = new ArrayList<>();
        for (ImageInfo imageInfo:
             scanForImageInfo(source)) {
            imageData.add(imageInfo.downloadImage());
        }
        for (ImageData data :
                imageData) {
            renderImage(data);
        }
    }

    class ImageData{}
    class ImageInfo{
        private ImageData downloadImage(){
            return new ImageData();
        }
    }
}
```

渲染网页内容和下载图片是两个相对独立的过程，可以并发进行    

```java
public class FutureRender {
    private final ExecutorService executorService = Executors.newFixedThreadPool(10);

    void renderPage(CharSequence source) {
        final List<ImageInfo> imageInfos = scanForImageInfo(source);
        Callable<List<ImageData>> task = new Callable<List<ImageData>>() {
            @Override
            public List<ImageData> call() throws Exception {
                List<ImageData> result = new ArrayList<>();
                for (ImageInfo imageInfo :
                        imageInfos) {
                    result.add(imageInfo.downloadImage());
                }
                return result;
            }
        };
        Future<List<ImageData>> future = executorService.submit(task);
        renderTesxt(source);
        try {
            List<ImageData> imageData = future.get();
            for (ImageData data :
                    imageData) {
                renderImage(data);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
//                取消执行过程
            future.cancel(true);
        } catch (ExecutionException e) {
            throw Preloader.launderThrowable(e.getCause());
        }
    }
}
``` 

但是上面这种操作还是不能尽可能发挥多线程的并行性，下载不同的图片的过程也可以是同时进行的。可以将每个下载任务放到线程池中运行，但是获取结果需要轮询每个任务较为繁琐。java类库提供了 CompletionService方便这种操作,CompletionService 是Executor和BlockingQueue的功能融合者，使用Executor执行任务，将执行的结果保存在队列中，然后通过take和poll等方法获得已经完成的结果。

```java
public class CompleteRenderer {
    private final ExecutorService executorService;

    public CompleteRenderer(ExecutorService executorService) {
        this.executorService = executorService;
    }

    public void renderPage(CharSequence source) {
        List<ImageInfo> info = scanForImageInfo(source);
        CompletionService<ImageData> completionService = new ExecutorCompletionService<>(executorService);
        for (final ImageInfo imageInfo :
                info) {
            completionService.submit(new Callable<ImageData>() {
                @Override
                public ImageData call() throws Exception {
                    return imageInfo.downloadImage();
                }
            });
        }
        renderTesxt(source);
        try {
            for (int i = 0, n = info.size(); i < n; i++) {
//                获取执行完成的结果
                Future<ImageData> f = completionService.take();
                ImageData imageData = f.get();
                renderImage(imageData);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } catch (ExecutionException e) {
            throw Preloader.launderThrowable(e.getCause());
        }
    }
}
``` 

**程序的并行性说明**<br>
只有大量相互独立且同构的任务可以并发进行处理，才能体现程序分配到多个任务性能提升<br>

**为任务设置时限**<br>

指定时间内获取广告信息

```java
Page renderPageWithAd() throws InterruptedException{
    long endNanos = System.nanoTime() + TIME_BUDGET;
    Future<Ad> f = exec.submit(new FetchAdTask);
    Page page = renderPageBody();
    Ad ad;
    try{
        long timeLeft = endNanos - System.nanoTime();
        ad = f.get(timeLeft,NANOSECONDS);
    }catch(ExecutionException e){
    }cath(TimeoutException e){
        ad = DEFAULT_AD;
        f.cancel(true);
    }
    page.setAd(ad);
    return page;
}
```


---
### 参考资料
- 《Java并发编程实战》