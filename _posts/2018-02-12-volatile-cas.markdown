---
layout:     post
title:      "java 内存模型及volatile、cas总结"
subtitle:   "java 内存模型及volatile、cas总结"
date:       2018-02-12 12:00:00
author:     "julyerr"
header-img: "img/thread/thread-base.jpg"
header-mask: 0.5
catalog:    true
tags:
    - thread
    - thread-advance
---


### java内存模型(JMM)

![](/img/thread/jmm.jpg)
JMM并不存在，只是抽象概念，涵盖了缓存，写缓冲区，寄存器以及其他的硬件和编译器优化方面内容。
线程之间的共享变量存储在主内存中，每个线程都有本地内存（实际并不存在，也是JMM的抽象概念）.<br>
对于一个实例对象中的成员方法而言

- 如果方法中包含本地变量是基本数据类型（boolean,byte,short,char,int,long,float,double），将直接存储在工作内存的帧栈结构中;
- 但本地变量是引用类型，那么该变量的引用会存储在功能内存的帧栈中;
- 对象实例以及实例的成员变量（基本数据类型、包装类型以及引用类型等）都会被存储到堆区
- static变量以及类本身相关信息将会存储在主内存中。

![](/img/thread/cache.jpg)
为保证多个CPU(线程运行调度单位)缓存一致性，有两种方式（为了效率，通常硬件支持）

- 总线锁机制，锁住总线的同时，其他的CPU无法访问内存，效率低下
- 缓存一致性，CPU操作共享变量的同时，通知其他的CPU将该变量设置无效状态，下次其他CPU读取时能够从主内存中重新读取。

#### 并发编程三问题
- **原子性**<br>
一个操作或者多个操作全部执行完成或者全不执行。intel处理器通过总线锁定和缓存锁两种方式保证原子性操作；java中可通过锁和循环CAS的方式实现原子操作
	- **CAS(Compare and Swap)**<br>
		涉及三个参数，一个当前内存值V、旧的预期值A、即将更新的值B，当且仅当预期值A和内存值V相同时，将内存值修改为B并返回true，否则什么都不做，并返回false。
		- **存在的三大问题**<br>
		    - **ABA问题**<br>
				如果一个值原来是A，变成了B，又变成了A，那么使用CAS进行检查时会发现它的值没有发生变化，但是实际上却变化了。通常在变量修改之前加上**版本号**，那么A－B－A就会变成1A-2B－3A；`AtomicStampedReference`可以用来解决ABA问题。
		    - **循环时间开销大**<br>
				如果多次判断失败的话，循环时间开销比较大。
			- **只能保证一个共享变量的原子操作**<br>
				Java1.5开始JDK提供了AtomicReference类来保证引用对象之间的原子性，可以把多个变量放在一个对象里来进行CAS操作。
	- **锁(Lock)**<br>
		只有获取到锁的线程才能对锁定区域进行操作，除了偏向锁，其他的锁均在底层使用了CAS机制实现。
			[详细参见](http://julyerr.club/2018/02/05/syn-lock/)
- **可见性**<br>
	一个线程修改了共享变量的值，其他线程都能立即看到修改后的值。更多内容参见下文的volatile关键字。
- **有序性**<br>
	程序执行代码顺序按照代码的先后顺序执行<br>

#### 指令重排
处理器为了提高程序运行效率，会对输入代码进行优化，虽不保证各个语句执行先后顺序和代码顺序相同，但是保证执行结果和代码顺序执行效果相同。<br>

**单线程as-if-serial语义**

```java
double r = 2.3d;//(1)
double pi =3.1415926; //(2)
double area = pi* r * r; //(3)
```

r与pi之间没有依赖关系，可以交换顺序，但是area计算依赖与pi和r,因此需要在最后执行。<br>

**多线程 happens-before原则**<br>

为什么需要happens-before原则,参看下面这个例子

```java
//线程1:
context = loadContext();   //语句1
inited = true;             //语句2

//线程2:
while(!inited ){
  sleep() 
}
doSomethingwithconfig(context);
```

线程1执行语句1、语句2没有依赖关系，经过指令重排之后可能优先执行语句2；此时线程2运行的话，由于初始化未成功，后面可能出现意想不到的结果。<br>

happens-before原则规定如果一个操作happens-before另一个操作，那么第一个操作的执行结果将对第二个操作可见，而且第一个操作的执行顺序排在第二个操作之前；两个操作之间存在happens-before关系，并不意味着一定要按照happens-before原则制定的顺序来执行。如果重排序之后的执行结果与按照happens-before关系来执行的结果一致，那么这种重排序并不非法。<br>

**八大原则**

- 程序次序规则：一个线程内，按照代码顺序，书写在前面的操作先行发生于书写在后面的操作；
- 传递规则：如果操作A先行发生于操作B，而操作B又先行发生于操作C，则可以得出操作A先行发生于操作C；
- 锁定规则：一个unLock操作先行发生于后面对同一个锁额lock操作；
volatile变量规则：对一个变量的写操作先行发生于后面对这个变量的读操作；
- 线程启动规则：Thread对象的start()方法先行发生于此线程的每个一个动作；
- 线程中断规则：对线程interrupt()方法的调用先行发生于被中断线程的代码检测到中断事件的发生；
- 线程终结规则：线程中所有的操作都先行发生于线程的终止检测，我们可以通过Thread.join()方法结束、Thread.isAlive()的返回值手段检测到线程已经终止执行；
- 对象终结规则：一个对象的初始化完成先行发生于他的finalize()方法的开始；

**扩展的规则**

- 将一个元素放入一个线程安全的队列的操作Happens-Before从队列中取出这个元素的操作
- 将一个元素放入一个线程安全容器的操作Happens-Before从容器中取出这个元素的操作
- 在CountDownLatch上的倒数操作Happens-Before CountDownLatch#await()操作
- 释放Semaphore许可的操作Happens-Before获得许可操作
- Future表示的任务的所有操作Happens-Before Future#get()操作
向Executor提交一个Runnable或Callable的操作Happens-Before任务开始执行操作		


---
### volatile关键字
被volatile关键字修饰的变量具有两层含义

- 该变量在多线程环境下是可见的;
- 禁止指令重排，不能将volatile变量之前的语句放在其后面执行，也不能把volatile变量后面的语句放到其前面执行

**实现原理**<br>
	添加volatile关键字之后，会增加lock前缀指令（内存屏障）：

- 它确保指令重排序时不会把其后面的指令排到内存屏障之前的位置，也不会把前面的指令排到内存屏障的后面；即在执行到内存屏障这句指令时，在它前面的操作已经全部完成；
- 会强制将对缓存的修改操作立即写入主存；
- 如果进行写操作，它会导致其他CPU中对应的缓存行无效。

**不能保证原子性**<br>
```
public class Test {
	public volatile int inc = 0;
	
	public void increase() {
		inc++;
	}
	
	public static void main(String[] args) {
		final Test test = new Test();
		for(int i=0;i<10;i++){
			new Thread(){
				public void run() {
					for(int j=0;j<1000;j++)
						test.increase();
				};
			}.start();
		}
		
		while(Thread.activeCount()>1)  //保证前面的线程都执行完
			Thread.yield();
		System.out.println(test.inc);
	}
}
```			
上面执行结果均小于10000。i++并不是一步操作：先获取i，i+1操作，写回原变量内存；多个线程并发中，线程A、线程B均读取i到本地缓存，线程A加一操作完毕之后退出，线程B同样加一写回原内存，结果覆盖A的操作。两次加一操作，实际上只执行了一次增量操作。
	
**使用场景**<br>

- **修饰状态变量**<br>

```java
volatile boolean inited = false;
//线程1:
context = loadContext();   
inited = true;             

//线程2:
while(!inited ){
	sleep() 
}
doSomethingwithconfig(context);	
```

- **double-check**

```java
public class Singleton {  
    private volatile Singleton instance = null;  
    public Singleton getInstance() {  
        if (instance == null) {  
            synchronized(Singleton.class) {  
                if (instance == null) {  
                    instance = new Singleton();  
                }  
            }  
        }  
        return instance;  
    }  
}  
```

如果instance之前不添加volatile关键字修饰的话，参见注释

```java
public class Singleton {  
    private Singleton instance = null;  
    public Singleton getInstance() {  
        if (instance == null) {  
            synchronized(Singleton.class) {  
                if (instance == null) {  
                    instance = new Singleton();  
                }
/*
instance  = new Singleton()有两个步骤:
    1.初始化Singleton实例的内存区域；
    2.将实例对象赋值给instance
单线程中两个步骤交换顺序没有影响；但是多线程中，线程A先执行2，线程B发现instance！=null的话，直接返回；
但是获取的可能是一个没有完全初始化的对象实例，对后续操作带来风险。

添加了volatile关键字，禁止指令重排，保证线程A先执行1后执行2
* */                
            }  
        }  
        return instance;  
    }  
}  
```

---
#### volatile和synchronized的区别
- volatile本质是在告诉jvm当前变量在寄存器（工作内存）中的值是不确定的，需要从主存中读取；synchronized则是锁定当前变量，只有当前线程可以访问该变量，其他线程被阻塞住。
- volatile仅能使用在变量级别；synchronized则可以使用在变量、方法、和类级别的
- volatile仅能实现变量的修改可见性，不能保证原子性；而synchronized则可以保证变量的修改可见性和原子性
- volatile不会造成线程的阻塞；synchronized可能会造成线程的阻塞。
- volatile标记的变量不会被编译器优化；synchronized标记的变量可以被编译器优化

---
#### 参考资料
- [Java并发编程：volatile关键字解析](https://www.cnblogs.com/dolphin0520/p/3920373.html)
- [全面理解Java内存模型](http://blog.csdn.net/suifeng3051/article/details/52611310)
- [聊聊并发（五）——原子操作的实现原理](http://www.infoq.com/cn/articles/atomic-operation)
- [volatile和synchronized的区别](http://blog.csdn.net/suifeng3051/article/details/52611233)
- [双重检查锁失效是因为对象的初始化并非原子操作？](https://www.zhihu.com/question/35268028)
- 《java并发编程实战》
- [【死磕Java并发】—–Java内存模型之happens-before](http://cmsblogs.com/?p=2102)