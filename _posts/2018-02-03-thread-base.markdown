---
layout:     post
title:      "java 多线程基础"
subtitle:   "java 多线程基础"
date:       2018-02-03 12:00:00
author:     "julyerr"
header-img: "img/thread/thread-base.jpg"
header-mask: 0.5
catalog:    true
tags:
    - java
    - thread
    - thread-base
---

>Java线程在JDK 1.2之前是基于用户线程实现的([详细参见](http://julyerr.club/2018/01/29/os-process-thread/#线程的实现))，而JDK1.2后，线程模型替换为基于操作系统原生线程来实现。

#### 创建线程的两种方式
- **实现Runnable接口**<br>
	- void run() 中执行逻辑处理;
    - 使用的时候，需要作为参数传入Thread构造方法中运行
```java
    Thread(Runnable target)
```
- **扩展Thread类**<br>
	重写该方法
```java
    public void run()
```    
- **启动线程**<br>
	调用start()方法而不是run()方法。
    - 调用start()会启动新线程将run()的执行权交给该线程；
    - 然而调用run()不会启动新线程，运行效果类似于正常调用方法			


---
#### 线程状态转换
![](/img/thread/states.jpg)

- **睡眠**<br>
	Thread.sleep(long millisecond) 使线程睡眠多少毫秒
- **让步**<br>
	Thread.yield() 暂停当前线程，将cpu执行权交给其他线程(如果存在的话)
- **join**<br>
	Thread.join()  让其他线程先运行完成，再执行当前线程;t1.join() 让t1线程先运行完成
- **wait/notify 和 suspend/resume 对比**<br>
	- wait/notify是Object类的方法，线程调用wait()会进入等待队列，释放所有的资源，需要依靠其他的线程调用notify或notifyAll()才能被唤醒，唤醒后的线程只有获取到锁资源才能运行;其中涉及到锁的操作，因此wait()/notify()必须在synchronized代码段中，否则抛出`IllegalMonitorStateException`的异常。
	- suspend/resume是Thread方法，线程调用suspend()并不会释放占用的锁，直接进入挂起状态，需要其他的线程调用resume方法唤醒。

---

#### 线程优先级
- 可以设置取值范围为1-10
		Thread.setPriority(priority)		
- 宏定义	
	- static int MAX_PRIORITY 线程可以具有的最高优先级。 
	- static int MIN_PRIORITY 线程可以具有的最低优先级。 
	- static int NORM_PRIORITY 分配给线程的默认优先级。	

---
#### 守护线程

守护线程就是用户程序在运行的时候后台提供的一种通用服务的线程，比如jvm中的gc线程。

- 如果不存在用户线程的话，守护线程也就没有存在的必要，jvm就会退出
- 开启守护线程需要在线程启动之前调用Thread.setDaemon(true) 设置

---
#### 线程中断
Thread.interrupt()方法并不能中断线程，起到的作用只是通知该线程外部有中断请求，是否真正实现中断还是取决于线程自己。可以通过Thread.isInterrupted()方法判断是否发生了中断。

```java
public class Interrupt {
    public static void main(String[] args) {
        Thread t = new interrupt();
        t.start();
        System.out.println("is start.......");
        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {

        }
        System.out.println("start interrupt..." + System.currentTimeMillis());
        t.interrupt();
        System.out.println("end interrupt ..." + System.currentTimeMillis());
    }
}

class interrupt extends Thread{
    @Override
    public void run() {
        while (!this.isInterrupted()) {
            System.out.println("没有中断");
            try {
                Thread.sleep(10000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        System.out.println("已经结束了..." + System.currentTimeMillis());
    }
}

//is start.......
//没有中断
//start interrupt...1517829225700
//end interrupt ...1517829225701
//已经结束了...1517829225701	
```
**notes**<br>
如果发生中断进行了异常接受的话，isInterrupted标志会清空,需要自己再次触发中断。上面这种方式只能支持能够实现自我中断的线程，对于不能实现自我中断的线程，需要重写interrupt()方法，具体请[参看](http://developer.51cto.com/art/201508/487231.htm)。


### 参考资料
- [JVM中线程的状态转换图](http://blog.csdn.net/zolalad/article/details/38903179)
- [Java多线程编程专题总结](http://blog.csdn.net/shb_derek1/article/details/26929249)
- [Java中的Daemon线程--守护线程](http://blog.csdn.net/lcore/article/details/12280027)
- [深入分析Java线程中断机制](http://developer.51cto.com/art/201508/487231.htm)