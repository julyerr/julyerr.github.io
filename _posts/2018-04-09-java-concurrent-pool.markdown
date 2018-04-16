---
layout:     post
title:      "《java并发编程》线程池及锁"
subtitle:   "《java并发编程》线程池及锁"
date:       2018-04-08 12:00:00
author:     "julyerr"
header-img: "img/lib/concurrent/concurrent.png"
header-mask: 0.5
catalog:    true
tags:
    - concurrent
---

>在前面[读书笔记](http://julyerr.club/2018/04/06/java-concurrent-programming/)中提及线程池,本文就线程池配置、高级使用和锁的特性总结。

### 任务与执行策略的隐形耦合

线程池中运行的线程并不是完全分离的，发现线程之间的关联对使用线程池起到至关重要的作用。

#### 线程饥饿死锁
单线程Executor中，如果一个任务将另一个任务提交到同一个Executor中，通常会发生死锁。因为第二个任务等待第一个任务完成，第一个任务等待第二个任务完成，于是发生死锁。如下是一个demo

```java
public class ThreadDeadLock{
	ExecutorService exec = Executors.newSingleThreadExecutor();

	class RenderPageTask implements Callable<String>{
		public String call() throws Exception{
			Future<String> header,footer;
			header = exec.submit(new LoadFileTask("header.html"));
			footer = exec.submit(new LoadFileTask("footer.html"));
			String page = renderBody();
			//发生死锁
			return header.get()+page+footer.get();
		}
	}
}
```		

#### 运行较长时间任务
任务执行时间过长，即使不出现死锁，响应性也非常糟糕。可以限定任务等待资源的时间，如果等待超时，可以将任务标志为失败，然后中止任务或者将任务重新放回队列以便随后执行。

### 配置ThreadPoolExecutor

```java
public ThreadPoolExecutor(
	int corePoolSize,
	int maximumPoolSize,
	long keepAlive,
	TimeUnit unit,
	BlockingQueue<Runnable> workQueue,
	ThreadFactory threadFactory,
	RejectedExecutionHandler handler){}
```	

笔者也总结过ThreadPoolExecutor工作原理和常见配置，[具体参见](http://julyerr.club/2018/02/16/threadPool/#线程池工作原理)。下面是一个控制任务工作效率的demo

```java
public class BoundedExecutor {
    private final Executor executor;
    //使用semphore控制并发运行的数量
    private final Semaphore semaphore;

    public BoundedExecutor(Executor executor, Semaphore semaphore) {
        this.executor = executor;
        this.semaphore = semaphore;
    }
    
    public void submitTask(final Runnable command) throws InterruptedException {
        semaphore.acquire();
        try {
            executor.execute(new Runnable() {
                @Override
                public void run() {
                    try {
                        command.run();
                    } finally {
                        semaphore.release();
                    }
                }
            });
        } catch (RejectedExecutionException e) {
            semaphore.release();
        }
    }
}
```	

#### 扩展ThreadPoolExecutor
如果需要对任务进行日志记录、计时、监视或统计信息收集等功能，可以扩展ThreadPoolExecutor。线程池中任务将调用beforeExecute和afterExecute、terminated等方

- 如果beforeExecute中发生抛出RuntimeException后面过程均不会调用；
- afterExecute不论是正常还是异常均会被调用；
- 调用terminate方法，会释放Executor在生命周期中分配的各种资源。
	
下面是为线程池添加统计信息的一个demo

```java
public class TimingThreadPool extends ThreadPoolExecutor {

    public TimingThreadPool(int corePoolSize, int maximumPoolSize, long keepAliveTime,
                            TimeUnit unit, BlockingQueue<Runnable> workQueue) {
        super(corePoolSize, maximumPoolSize, keepAliveTime, unit, workQueue);
    }

    private final ThreadLocal<Long> startTime = new ThreadLocal<>();
    private final Logger logger = Logger.getLogger("TimingThreadPool");
    private final AtomicLong numTasks = new AtomicLong();
    private final AtomicLong totalTime = new AtomicLong();

    protected void beforeExecute(Thread t, Runnable r) {
        super.beforeExecute(t, r);
        logger.fine(String.format("Thread %s:start %s", t, r));
        startTime.set(System.nanoTime());
    }

    protected void afterExecute(Runnable r, Throwable t) {
        try {
            long endTime = System.nanoTime();
            long taskTime = endTime - startTime.get();
            numTasks.incrementAndGet();
            totalTime.addAndGet(taskTime);
            logger.fine(String.format("Thread %s:end %s, time = %dns", t, r, taskTime));
        } finally {
            super.afterExecute(r, t);
        }
    }

    protected void terminated() {
        try {
            logger.info(String.format("Terminated:avg time = %dns", totalTime.get() / numTasks.get()));
        } finally {
            super.terminated();
        }
    }
}
```	

---
笔者在以前的文章对java中的锁也进行了部分[总结](http://julyerr.club/2018/02/05/syn-lock/)，为了节省篇幅，这里主要以例子补充说明常见的使用方法。

### Lock

#### 轮询锁

下面一个转账的demo说明问题，转账过程封装成了一个函数，A->B表示A转账给B。如果两个线程分别调用该转账函数，传递的参数正好相反。那么可能因为线程1先获取A的锁，线程2获取了B的锁，线程1然后需要获取B的锁，线程2需要获取A的锁，互相等待便发生动态死锁。可以使用tryLock避免这种现象

```java
public boolean transferMoney(Account from,Account to,DollarAmount amount,
	long timeout,TimeUnit unit) throws InsufficientFundsException,InterruptionException{
		long fixedDelay = getFixedDelayComponentNanos(timeout,unit);
		long randMod = getRandomDelayModulesNanos(timeout,unit);
		long stopTime = System.nanoTime() + unit.toNanos(timeout);

		while(true){
			if(from.lock.trylock()){
				try{
					if(to.lock.trylock()){
						try{
							if(from.getBalance().compareTo(amout)<0){
								throw new InsufficientFundsException();
							}else{
								from.debit(amount);
								to.credit(amount);
							}
						}finally{
							to.lock.unlock();
						}
					}
				}finally{
					from.lock.unlock();
				}
			}
			if(System.nanoTime() < stopTime ){
				return false;
			}
			NANOSECONDS.sleep(fixedDelay + rand.nextLong() % randMod);
		}
	}
```

#### 定时锁

直接看使用模板

```java
public boolean trySendOnSharedLine(String message,long timeout,
	TimeUnit unit) throws InterruptedException{
		long nanosToLock = unit.toNanos(timeout) - estimatedNanosToSend(message);
		if(!lock.tryLock(nanosToLock,NANOSECONDS)){
			return false;
		}
		try{
			return sendOnSharedLine(message);
		}finally{
			lock.unlock();
		}
	}
```	

#### 中断锁

常见的使用模板

```java
public boolean sendOnSharedLine(String message)
	throws InterruptedException{
		lock.lockInterruptibly();
		try{
			return cancellableSendOnSharedLine(message);
		}finally{
			lock.unlock();
		}
}

private boolean cancellableSendOnSharedLine(String message) throws InterruptedException{
	//...
}
```	

**使用读写锁封装线程安全map**

```java
public class ReadWriteMap<K,V> {
    private final Map<K,V> map;
    private final ReadWriteLock lock = new ReentrantReadWriteLock();
    private final Lock r = lock.readLock();
    private final Lock w = lock.writeLock();

    public ReadWriteMap(Map<K, V> map) {
        this.map = map;
    }
    
    public V put(K key,V value){
        w.lock();
        try{
            return map.put(key,value);
        }finally {
            w.unlock();
        }
    }
    
    //对remove、putAll、clear等执行相同的操作
    public V get(Object key){
        r.lock();
        try{
            return map.get(key);
        }finally {
            r.unlock();
        }
    }
}
```

### 死锁

**常见死锁的几种情况**

- 执行的顺序不当
- 动态死锁<br>
    上文中转账的对象A,B提供给外部的调用对象，先需要获取各自的锁，然后转账。但是可能出现参数传递相反，发生死锁的情况。
- 协作过程出现死锁
- 资源死锁

### 性能与可伸缩性

**减少锁的竞争** 使用锁可以保证多线程并发的安全性，同时也会带来很多风险和开销,可能保证线程安全的情况下，尽可能少涉及到锁的操作.

- 线程因为等待锁可能发生阻塞，浪费CPU时钟等；
- 多线程之间内存同步，内存失效等；
- 线程之间的上下文切换带来的开销都是很大的。

通常有以下几种锁优化策略

- **锁消除**
    编译器去除锁、锁粒度的粗化

```java
public String getStoogeNames(){
	//局部变量中没有必要使用同步容器，编译器会自动消除锁
	List<String> stooges = new Vector<String>();
	stooges.add("Moe");
	stooges.add("Larry");
	stooges.add("Curly");
	return stooges.toString();
}
```



- **缩小锁的范围**

```java
private final Map<String,String> attributes = new HashMap<String,String>();
public boolean userLocationMatches(String name,String regexp){
	String key = "users."+name+".location";
	String location;
	//相对于同步方法而言，只有此步需要同步操作
	synchronized(this){
		location = attributes.get(key);
	}
	if(location == null){
		return false;
	}else{
		return Pattern.matches(regexp,location);
	}
}
```		

- **减小锁的粒度** 采用多个相互独立的锁保护独立的状态变量

```java
public class ServerStatus {
    public final Set<String> users;
    public final Set<String> queries;

    public ServerStatus(Set<String> users, Set<String> queries) {
        this.users = users;
        this.queries = queries;
    }

    public synchronized void addUser(String u) {
        users.add(u);
    }

    public synchronized void addQuery(String q) {
        queries.add(q);
    }
    //...
}
```

- **锁分段** ConcurrentHashMap在jdk1.7中使用了分段锁机制，提高并发度

---
### 参考资料
- 《Java并发编程实战》