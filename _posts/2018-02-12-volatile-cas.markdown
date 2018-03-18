---
layout:     post
title:      "java volatile和cas总结"
subtitle:   "java volatile和cas总结"
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
线程之间的共享变量存储在主内存中，每个线程都有本地内存（实际并不存在，也是JMM的抽象概念）。
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
	**指令重排**<br>
		处理器为了提高程序运行效率，会对输入代码进行优化，虽不保证各个语句执行先后顺序和代码顺序相同，但是保证执行结果和代码顺序执行效果相同。单线程指令重排不会影响结果但是多线程则可能影响结果

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
线程1执行语句1、语句2没有依赖关系，经过指令重排之后可能优先执行语句2；此时线程2运行的话，由于初始化未成功，后面可能出现意想不到的结果。

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