---
layout:     post
title:      "goroutine 和 channel 简析"
subtitle:   "goroutine 和 channel 简析"
date:       2018-04-02 12:00:00
author:     "julyerr"
header-img: "img/go/golang.png"
header-mask: 0.5
catalog: 	true
tags:
    - golang
---


### 并发背后的系统知识

#### 系统调用
系统调用是操作系统将内存管理、文件管理、进程管理、外设管理等内部模块功能提供给应用程序调用的一种方式。<br>

**语言运行库**<br>
语言运行库对系统调用封装了参数准备和返回值格式转换、以及出错处理和错误代码转换等工作，例如c语言上对应的cglibc,java的JRE，这些“其他语言”的运行库通常最终还是调用glibc或kernel32。但任何一门语言，包括其运行库和运行环境，都不可能创造出操作系统不支持的功能，Go语言也是这样，不管它的特性描述看起来多么炫丽，那必然都是其他语言也可以做到的，只不过Go提供了更方便更清晰的语义和支持，提高了开发的效率。<br>

**并发**<br>
并发指的是程序的逻辑结构，如果某个程序有多个独立的逻辑控制流，也就是可以同时处理(deal)多件事情，我们就说这个程序是并发的。有两种方式

- 显式地定义并触发多个代码片段，也就是逻辑控制流，由应用程序或操作系统对它们进行调度;
- 隐式地放置多个代码片段，在系统事件发生时触发执行相应的代码片段，也就是事件驱动的方式，譬如某个端口或管道接收到了数据(多路IO的情况下)，再譬如进程接收到了某个信号(signal)。

**并行**<br>
多个程序同时运行,常见四个层面的实现

- 多台机器
- 多CPU
- 单CPU核里的ILP(Instruction-level parallelism)，指令级并行
- 单指令多数据(Single instruction, multiple data. SIMD)


#### 线程调度

线程是并发的直观实现，操作系统针对不同的情况，有具体的实现策略<br>

**单核单CPU**<br>
通常，内核会在时钟中断里或系统调用返回前(考虑到性能，通常是在不频繁发生的系统调用返回前)，对整个系统的线程进行调度，计算当前线程的剩余时间片，如果需要切换，就在“可运行”的线程队列里计算优先级，选出目标线程后，则保存当前线程的运行环境，并恢复目标线程的运行环境，其中最重要的，就是切换堆栈指针ESP，然后再把EIP指向目标线程上次被移出CPU时的指令。<br>

内核并没有控制权，内核并不是一个进程或线程，内核只是以实模式运行的，代码段权限为RING 0的内存中的程序，只有当产生中断或是应用程序呼叫系统调用的时候，控制权才转移到内核，在内核里，所有代码都在同一个地址空间，为了给不同的线程提供服务，内核会为每一个线程建立一个内核堆栈，这是线程切换的关键。<br>

**多核多CPU**<br>
在多处理器的情况下，线程切换的原理和流程其实和单处理器时是基本一致的，内核代码只有一份，当某个CPU上发生时钟中断或是系统调用时，该CPU的CS:EIP和控制权又回到了内核，内核根据调度策略的结果进行线程切换。但在这个时候，如果我们的程序用线程实现了并发，那么操作系统可以使我们的程序在多个CPU上实现并行。


#### 并发编程框架实现简介

- 比较直观的想法，维护一个任务的列表，根据我们定义的策略，先进先出或是有优先级等，每次从列表里挑选出一个任务，然后恢复各个寄存器的值，并且JMP（jump)到该任务上次被暂停的地方，所有这些需要保存的信息都可以作为该任务的属性，存放在任务列表里。<br>

- 需要为每个任务单独分配堆栈，并且把其堆栈信息保存在任务属性里，在任务切换时也保存或恢复当前的SS:ESP。任务堆栈的空间可以是在当前线程的堆栈上分配，也可以是在堆上分配，但通常是在堆上分配比较好：几乎没有大小或任务总数的限制、堆栈大小可以动态扩展,便于把任务切换到其他线程。<br>

- 运行在用户态，是没有中断或系统调用这样的机制来打断代码执行的。只有靠任务主动调用schedule()，我们才有机会进行调度，所以这里的**任务不能像线程一样依赖内核调度从而毫无顾忌的执行，我们的任务里一定要显式的调用schedule()，这就是所谓的协作式(cooperative)调度**。<br>

- 只有内核才有调度CPU的权限，所以，我们还是必须通过系统调用创建线程，才可以实现并行。

**可能出现问题**<br>

- 如果某个任务发起了一个系统调用，譬如长时间等待IO，那当前线程就被内核放入了等待调度的队列，岂不是让其他任务都没有机会执行？<br>
    如果我们采用多线程来构造我们整个的程序，那么我们可以封装系统调用的接口，当某个任务进入系统调用时，我们就**把当前线程留给它(暂时)独享，并开启新的线程来处理其他任务**。

- **任务同步**<br>
    在单线程的情况下，我们可以定义一个结构，其中**有变量用于存放交互数据本身，以及数据的当前可用状态，以及负责读写此数据的两个任务的编号**。然后我们的并发编程框架再提供read和write方法供任务调用
    - 在read方法里，我们循环检查数据是否可用，如果数据还不可用，我们就调用schedule()让出CPU进入等待；
    - 在write方法里，我们往结构里写入数据，更改数据可用状态，然后返回；
    - 在schedule()里，我们检查数据可用状态，如果可用，则激活需要读取此数据的任务，该任务继续循环检测数据是否可用，发现可用，读取，更改状态为不可用，返回。代码的简单逻辑如下：

```c
struct chan {
    bool ready,
    int data
};

int read (struct chan *c) {
    while (1) {
        if (c->ready) {
            c->ready = false;
            return c->data;
        } else {
            schedule();
        }
    }
}

void write (struct chan *c, int i) {
    while (1) {
        if (c->ready) {
            schedule(); 
        } else {
            c->data = i;
            c->ready = true;
            // optional
            schedule(); 
            return;
        }
    }
}
```

很显然，如果是多线程的话，我们需要通过线程库或系统调用提供的同步机制来保护对这个结构体内数据的访问.

---
### goroutine 实现分析

go非常简洁而又巧妙的方式实现了自己的并发框架

#### go runtime的调度器

**为什么go实现自己的调度器？**<br>

- POSIX的方案在很大程度上是对Unix process进场模型的一个逻辑描述和扩展，两者有很多相似的地方。Thread有自己的信号掩码，CPU affinity等。但是很多特征对于Go程序来说都是累赘，尤其是context上下文切换的耗时。
- Go的垃圾回收需要所有的goroutine停止，使得内存在一个一致的状态。垃圾回收的时间点是不确定的，如果依靠OS自身的scheduler来调度，那么会有大量的线程需要停止工作。


支撑整个调度器的主要有4个重要结构，分别是M、G、P、Sched，

![](/img/go/goroutine/schedule-parts.jpg)

- M代表内核级线程，一个M就是一个线程，goroutine就是跑在M之上的；M是一个很大的结构，里面维护小对象内存cache（mcache）、当前执行的goroutine、随机数发生器等等非常多的信息。
- P全称是Processor，处理器，它的主要用途就是用来执行goroutine的，所以它也维护了一个goroutine队列，里面存储了所有需要它来执行的goroutine。
- G就是goroutine实现的核心结构了，G维护了goroutine需要的栈、程序计数器以及它所在的M等信息。
- Sched结构就是调度器，它维护有存储M和G的队列以及调度器的一些状态信息等。

M就可以看作图中的地鼠，P就是小车，G就是小车里装的砖。

![](/img/go/goroutine/golang-compare.jpg)

### go程序启动分析

- 启动过程中的调度器初始化runtime·schedinit函数主要根据用户设置的GOMAXPROCS值来创建一批小车(P)，不管GOMAXPROCS设置为多大，最多也只能创建256个小车(P);
- 接下来调用runtime·newproc创建出第一个goroutine，这个goroutine将执行的函数是runtime·main。主goroutine开始执行后，做的第一件事情是创建了一个新的内核线程(地鼠M)，不过这个线程是一个特殊线程，它在**整个运行期专门负责做特定的事情——系统监控(sysmon)**;
- 接下来就是进入Go程序的main函数开始Go程序的执行。在Go程序开始运行后，就会向调度器添加goroutine.


**创建goroutine**<br>

go关键字对应到调度器的接口就是runtime·newproc。runtime·newproc干的事情很简单，就负责制造一块砖(G)，然后将这块砖(G)放入当前这个地鼠(M)的小车(P)中。<br>

G结构的sched字段维护了栈地址以及程序计数器等信息，这个goroutine放弃cpu的时候需要保存这些信息，待下次重新获得cpu的时候，需要将这些信息装载到对应的cpu寄存器中。<br>

**内核线程的创建**<br>
只能由runtime根据实际情况去创建。通过调用newm函数（内部调用clone系统函数）创建一个内核线程，每个内核线程的开始执行位置都是runtime·mstart函数。参数p就是一辆空闲的小车(p)。地鼠(M)去拿小车(P)这个过程就是acquirep,地鼠(M)拿到属于自己的小车(P)后，就进入工场开始干活了.


![](/img/go/goroutine/golang-workflow.jpg)
上图非常形象的表示了goroutine声明周期的主要活动<br>

```
static void
schedule(void)
{
	G *gp;

	gp = runqget(m->p);
	if(gp == nil)
		gp = findrunnable();

	if (m->p->runqhead != m->p->runqtail &&
		runtime·atomicload(&runtime·sched.nmspinning) == 0 &&
		runtime·atomicload(&runtime·sched.npidle) > 0)  
		wakep();

	execute(gp);
}
```

- runqget, 地鼠(M)试图从自己的小车(P)取出一块砖(G)，当然结果可能失败，也就是这个地鼠的小车已经空了，没有砖了;
- findrunnable, 如果地鼠自己的小车中没有砖,就会试图跑去工场仓库取一块砖来处理；如果工场仓库没砖会随机盯上一个小伙伴(地鼠)，然后从它的车里试图偷一半砖到自己车里。如果多次尝试偷砖都失败了，那说明实在没有砖可搬了，这个时候地鼠就会把小车还回停车场，然后睡觉休息了，对应的线程也就sleep了;
- wakep 地鼠发现自己小车里有好多砖，自己根本处理不过来；如果此时有睡觉的其他小伙伴，就会唤醒他们一起工作;有时候，地鼠发现没有在睡觉的小伙伴，只好请工场老板赶紧从别的工场借个地鼠来帮忙吧。最后工场老板就搞来一个新的地鼠干活了;
- execute，地鼠拿着砖放入火种欢快的烧练起来。	

### 调度点

执行的goroutine不可能永久占用CPU,在以下情况会发生调度

- 对channel读写操作的时候会触发调用runtime·park函数，这个goroutine就会被设置位waiting状态，放弃cpu。被park的goroutine处于waiting状态，并且这个goroutine不在小车(P)中，如果不对其调用runtime·ready，它是永远不会再被执行的;
- 除了channel操作外，定时器中，网络poll等都有可能park goroutine(参见下篇文章对golang中网络模型实现的分析);
- 除了park可以放弃cpu外，调用runtime·gosched函数也可以让当前goroutine放弃cpu，但和park完全不同；gosched是将goroutine设置为runnable状态，然后放入到调度器全局等待队列（也就是上面提到的工场仓库）;
- 有些系统调用也会触发重新调度。Go语言完全是自己封装的系统调用，进入系统调用的时候执行entersyscall，退出后又执行exitsyscall函数。只有封装了entersyscall的系统调用才有可能触发重新调度，它将改变小车(P)的状态为syscall。上面提及的sysmon的系统监控线程会扫描所有的小车(P)，发现一个小车(P)处于了syscall的状态，就知道这个小车(P)遇到了goroutine在做系统调用，于是系统监控线程就会创建一个新的地鼠(M)去把这个处于syscall的小车给抢过来，开始干活，这样这个小车中的其他的砖块(G)就可以绕过之前系统调用的等待了(如下图）。被抢走小车的地鼠等系统调用返回后，发现自己的车没，不能继续干活了，于是只能把执行系统调用的goroutine放回到工场仓库，自己睡觉去了。

![](/img/go/goroutine/context-change.jpg)

#### 现场保存

保存现场就是在goroutine放弃cpu的时候，将相关寄存器的值给保存到内存中；恢复现场就是在goroutine重新获得cpu的时候，需要从内存把之前的寄存器信息全部放回到相应寄存器中去。<br>

goroutine在主动放弃cpu的时候(park/gosched)，都会涉及到调用runtime·mcall函数，主要将goroutine的栈地址和程序计数器保存到G结构的sched字段中，mcall就完成了现场保存。恢复现场的函数是runtime·gogocall，这个函数主要在execute中调用，就是在执行goroutine前，需要重新装载相应的寄存器。<br>

---
对比并发框架实现原理和golang支持并发操作细节，可以发现，golang非常简洁而且高效地处理了上文中提及的多线程阻塞和同步两个问题。<br>
Notes:和所有其他并发框架里的协程一样，goroutine里所谓“无锁”的优点只在单线程下有效，如果$GOMAXPROCS > 1并且协程间需要通信，Go运行库会负责加锁保护数据(这也是为什么sieve.go这样的例子在多CPU多线程时反而更慢的原因)。


---
### 参考资料
- [Golang 的 goroutine 是如何实现的？](https://www.zhihu.com/question/20862617)
- [Golang中goroutine的调度器详解](https://blog.csdn.net/heiyeshuwu/article/details/51178268)