---
layout:     post
title:      "《java并发编程》AQS、原子变量和非阻塞同步机制"
subtitle:   "《java并发编程》AQS、原子变量和非阻塞同步机制"
date:       2018-04-15 1:00:00
author:     "julyerr"
header-img: "img/lib/concurrent/concurrent.png"
header-mask: 0.5
catalog:    true
tags:
    - concurrent
---

### 状态依赖性管理

类库中包含了许多状态依赖性（一些操作需要依赖具体状态进行的）的类如FutureTask、Semaphore和BlockingQueue等，通常只需要在类库中现有状态依赖类基础上进行构造;如果功能无法满足，可以使用java底层机制构造自己的同步机制，如内置条件队列、显示Condition对象以及AbstractQueuedSynchronizer框架等。<br>

如果没有使用条件队列的话，通常采用**循环轮询**

```java
public void put(V v) throws InterruptedException{
    while(true){
        synchronized(this){
            if(!isFull()){
                doPut(v);
                return;
            }
        }
        Thread.sleep(SLEEP_TIME);
    }
}

public V take() throws InterruptedException{
    while(true){
        synchronized(this){
            if(!isEmpty()){
                return doTake();
            }
        }
        Thread.sleep(SLEEP_TIME);
    }
}
``` 

使用**内置条件队列**构建生产者消费者模型，以下是一个demo

```java
public class WaitNotify {
    private Integer count = 0;
    private final Integer FULL = 10;
    private String LOCK = "lock";

    public static void main(String[] args){
        WaitNotify waitNotify = new WaitNotify();
        new Thread(waitNotify.new Producer()).start();
        new Thread(waitNotify.new Consumer()).start();
        new Thread(waitNotify.new Consumer()).start();
    }

    class Producer implements Runnable{
        @Override
        public void run() {
            for (int i = 0; i < 10; i++) {
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                synchronized (LOCK){
                    while(count == FULL){
                        try {
                            LOCK.wait();
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                    count++;
                    System.out.println(Thread.currentThread().getName()+" 生产，目前共有："+count);
                    LOCK.notifyAll();
                }
            }
        }
    }

    class Consumer implements Runnable{
        @Override
        public void run() {
            for (int i = 0; i < 10; i++) {
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                synchronized (LOCK){
                    while(count == 0){
                        try {
                            LOCK.wait();
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                    count--;
                    System.out.println(Thread.currentThread().getName()+" 消费，目前共有："+count);
                    LOCK.notifyAll();
                }
            }
        }
    }
}
``` 
    
使用内置条件队列有一大问题就是，notify/notifyAll激活的是当前对象等待的所有线程，不能实现针对性的激活某些线程;**Condition的显示条件**队列可以明确激活某些线程，使用方法参见下面的demo

```java
public class LockImpl {
    private Integer count = 0;
    private final Integer FULL = 10;
    final Lock lock = new ReentrantLock();
    final Condition notFull = lock.newCondition();
    final Condition notEmpty = lock.newCondition();

    public static void main(String[] args) {
        LockImpl lockImpl = new LockImpl();
        new Thread(lockImpl.new Producer()).start();
        new Thread(lockImpl.new Consumer()).start();
        new Thread(lockImpl.new Consumer()).start();
    }

    class Producer implements Runnable {
        @Override
        public void run() {
            for (int i = 0; i < 10; i++) {
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                try {
                    lock.lock();
                    while (count == FULL) {
                        try {
                            notFull.await();
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                    count++;
                    System.out.println(Thread.currentThread().getName() + " 生产，目前共有：" + count);
                    notEmpty.signalAll();
                } finally {
                    lock.unlock();
                }
            }
        }
    }

    class Consumer implements Runnable {
        @Override
        public void run() {
            for (int i = 0; i < 10; i++) {
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                try {
                    lock.lock();
                    while (count == 0) {
                        try {
                            notEmpty.await();
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    }
                    count--;
                    System.out.println(Thread.currentThread().getName() + " 消费，目前共有：" + count);
                    notFull.signalAll();
                } finally {
                    lock.unlock();
                }
            }
        }
    }
}
``` 

---
### 构建自定义同步工具AQS 

AQS是一个构建锁和同步器的框架，ReentrantLock和Semaphore等都是其子类,可以使用ReentrantLock实现Semaphore，如下的一个demo

```java
public class SemaphoreOnLock {
    private final Lock lock = new ReentrantLock();
    private final Condition permitsAvailable = lock.newCondition();
    private int permits;

    public SemaphoreOnLock(int permits) {
        lock.lock();
        try{
            this.permits = permits;
        }finally {
            lock.unlock();
        }
    }
    
    public void acquire() throws InterruptedException{
        lock.lock();
        try{
            while(permits<=0){
                permitsAvailable.await();
            }
            --permits;
        }finally {
            lock.unlock();
        }
    }
    
    public void release(){
        lock.lock();
        try {
            ++permits;
            permitsAvailable.signal();
        }finally {
            lock.unlock();
        }
    }
}
```

AQS减少了构建同步器实现的工作量，并且较好的优化代码，提高效率。自定义同步工具优先考虑使用AQS，处理ReentrantLock和Semaphore使用了AQS框架，CountDownLatch、FutureTask以及ReentrantReadWriteLock同样基于AQS扩展而来。<br>

继承自AQS类可以重写其中的tryAcquire、tryRelease等方法决定实现共享还是互斥锁的功能，使用getState()、setState()和compareAndSetState()等来检查和更新状态信息。<br>

下面是一个二元闭锁的实现，tryAcquireShared返回一个负值表示操作失败，返回0表示独占方式获取，返回正值表示非独占方式获取

```java
public class OneShotLatch {
    private final Sync sync = new Sync();

    public void signal() {
        sync.tryReleaseShared(1);
    }

    public void await() throws InterruptedException {
        sync.acquireInterruptibly(1);
    }

    private class Sync extends AbstractQueuedLongSynchronizer {
        @Override
        protected boolean tryReleaseShared(long arg) {
            setState(1);
            return true;
        }

        @Override
        protected long tryAcquireShared(long arg) {
            return (getState() == 1) ? 1 : -1;
        }
    }
}
```

---
### 原子变量与非阻塞同步机制
上篇文章也提及锁的一些缺点，例如线程因为锁而频繁进行上下文切换开销大，优先级反转（高优先级线程等待低优先级释放锁）等。原子变量和非阻塞算法是对锁的补充

#### CAS（比较并交换）
cas是CPU指令级别的支持，包含三个操作数，需要读写内存位置V、进行比较的值A和拟写入新值的B。当且仅当V值等于A时，cas才会通过原子方式用B来更新V值。cas是一种乐观锁，但是CAS中可能出现ABA问题，可以使用引用加版本的方式解决AtomicStampedReference “对象-引用（包含版本号）“,具体[参见](http://julyerr.club/2018/02/12/volatile-cas/#并发编程三问题)。

#### 原子变量
原子变量通过将竞争的范围缩小到单个变量上，是比锁粒度更细、更加轻量级的并发机制。AtomicLong、AtomicReference（对复杂类型的原子操作）提供常见的get、set以及compareAndSet等方法。

- 高强度竞争条件下，锁能够避免竞争，提高性能；
- 适度情况下（实际情况），原子变量更好的性能和扩展性。

#### 非阻塞算法
可以使用原子变量（AtomicInteger和AtomicRefenrence）构建高效的非阻塞算法。可以使多个线程在竞争相同数据时不会发生阻塞，而不存在死锁和其他活跃性问题。<br>

**非阻塞栈**

```java
public class ConcurrentStack<E> {
    AtomicReference<Node<E>> top = new AtomicReference<>();

    public void push(E item) {
        Node<E> newHead = new Node(item);
        Node<E> oldHead = null;
        do {
            oldHead = top.get();
            newHead.next = oldHead;
//            自从上次读取以来，元素没有发生改变
        } while (!top.compareAndSet(oldHead, newHead));
    }

    public E pop() {
        Node<E> oldHead;
        Node<E> newHead;
        do {
            oldHead = top.get();
            if (oldHead == null) {
                return null;
            }
            newHead = oldHead.next;
        } while (!top.compareAndSet(oldHead, newHead));
        return oldHead.item;
    }

    private static class Node<E> {
        public final E item;
        public Node<E> next;

        public Node(E item) {
            this.item = item;
        }
    }
}
```

**非阻塞链表**<br>
链接队列支持对头结点和尾节点的快速访问，实现起来更加复杂。其中需要注意的是插入典型的两种情况，如下图所示

![](/img/lib/concurrent/concurrentList_Push.png)    

```java
public class LinkedQueue<E> {
    private static class Node<E> {
        final E item;
        final AtomicReference<Node<E>> next;

        public Node(E item, AtomicReference<Node<E>> next) {
            this.item = item;
            this.next = next;
        }
    }

    private final Node<E> dummy = new Node<>(null, null);
    private final AtomicReference<Node<E>> head =
            new AtomicReference<>(dummy);
    private final AtomicReference<Node<E>> tail =
            new AtomicReference<>(dummy);

    public boolean put(E item) {
        Node<E> newNode = new Node<>(item, null);
        while (true) {
            Node<E> curTail = tail.get();
            Node<E> tailNext = curTail.next.get();
            if (curTail == tail.get()) {
//                队列处于中间状态，推进尾节点
                if (tailNext != null) {
                    tail.compareAndSet(curTail, tailNext);
                } else {
//                    处于稳定状态，尝试插入新节点
                    if (curTail.next.compareAndSet(null, newNode)) {
                        tail.compareAndSet(curTail, newNode);
                    }
                    return true;
                }
            }
        }
    }
}
```    

---
### 参考资料
- 《Java并发编程实战》