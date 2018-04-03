---
layout:     post
title:      "多路复用io及golang 网络模型分析"
subtitle:   "多路复用io及golang 网络模型分析"
date:       2018-04-02 12:00:00
author:     "julyerr"
header-img: "img/go/net/go-net.png"
header-mask: 0.5
catalog: 	true
tags:
    - golang
---


开始本文之前可以先看看linux中五种[io模型](http://julyerr.club/2018/02/12/bio-nio-aio-overview/)

### 多路复用io

I/O多路复用就是通过一种机制，一个进程可以监视多个描述符，一旦某个描述符就绪（一般是读就绪或者写就绪），能够通知程序进行相应的读写操作。与多进程和多线程技术相比，I/O多路复用技术的最大优势是系统开销小，系统不必创建进程/线程，也不必维护这些进程/线程，从而大大减小了系统的开销。<br>

select、poll、epoll等都能提供多路I/O复用的解决方案。在现在的Linux内核里有都能够支持，其中epoll是Linux所特有，而select则是POSIX所规定，一般操作系统均有实现。

#### select工作原理

![](/img/go/net/select.png)

- select先创建3个文件描述符集，并将这些文件描述符拷贝到内核中，这里限制了文件句柄的最大的数量为1024（注意是全部传入，第1次拷贝）；
- 内核针对读缓冲区和写缓冲区来判断是否可读可写,这个动作和select无关；
- 当内核检测到文件句柄可读/可写时就产生中断通知监控者select，select被内核触发之后，就返回可读可写的文件句柄的总数；
- select会将之前传递给内核的文件句柄再次从内核传到用户态（第2次拷贝），select返回给用户态的只是可读可写的文件句柄总数，再使用FD_ISSET宏函数来检测哪些文件I/O可读可写（遍历）；
- select对于事件的监控是建立在内核的修改之上的，也就是说经过一次监控之后，内核会修改位，因此再次监控时需要再次从用户态向内核态进行拷贝（第N次拷贝）

通过select执行过程，可以发现其存在很多问题

- 需要维护一个用来存放大量fd的数据结构，用户空间和内核空间在传递该结构时复制开销大;
- 对socket进行扫描时是线性扫描，即采用轮询的方法，套接字较多时，遍历花费的时间大。

**poll**本质上和select没有区别，它将用户传入的数组拷贝到内核空间，然后查询每个fd对应的设备状态，如果设备就绪则在设备等待队列中加入一项并继续遍历，如果遍历完所有fd后没有发现就绪设备，则挂起当前进程，直到设备就绪或者主动超时，被唤醒后它又要再次遍历fd,这个过程经历了多次无谓的遍历。<br>

从上面看，select和poll都需要在返回后，通过遍历文件描述符来获取已经就绪的socket。当套接字比较多的时候，会浪费很多CPU时间。事实上，同时连接的大量客户端在一时刻可能只有很少的处于就绪状态。如果能给**套接字注册某个回调函数，当他们活跃时，自动完成相关操作**，那就避免了轮询，这正是epoll与kqueue做的。

#### epoll工作原理

- 首先执行epoll_create在内核专属于epoll的高速cache区，并在该缓冲区建立红黑树和就绪链表，用户态传入的文件句柄将被放到红黑树中（第一次拷贝）;
- 内核针对读缓冲区和写缓冲区来判断是否可读可写，这个动作与epoll无关；
- epoll_ctl执行add动作时除了将文件句柄放到红黑树上之外，还向内核注册了该文件句柄的回调函数，内核在检测到某句柄可读可写时则调用该回调函数，回调函数将文件句柄放到就绪链表;
- epoll_wait只监控就绪链表就可以，如果就绪链表有文件句柄，则表示该文件句柄可读可写，并返回到用户态（少量的拷贝）;
- 由于内核不修改文件句柄的位，因此只需要在第一次传入就可以重复监控，直到使用epoll_ctl删除，否则不需要重新传入。

epoll支持水平触发和边缘触发两种方式：

- LT(水平触发)模式：当epoll_wait检测到描述符事件发生并将此事件通知应用程序，应用程序可以不立即处理该事件。下次调用epoll_wait时，会再次响应应用程序并通知此事件。
- ET(边缘触发)模式：当epoll_wait检测到描述符事件发生并将此事件通知应用程序，应用程序必须立即处理该事件。如果不处理，下次调用epoll_wait时，不会再次响应应用程序并通知此事件。


---
### 传统高性能服务器工作模式

目前的高性能服务器很多都用的是reactor模式，即non-blocking IO+IO multiplexing的方式。通常主线程只做event-loop，通过epoll_wait等方式监听事件，而处理客户请求是在其他工作线程中完成。

![](/img/go/net/traditional.jpg)

- server端在bind&listen后，将listenfd注册到epollfd中，最后进入epoll_wait循环;
- 循环过程中若有listenfd上的event,则调用socket.accept，并将connfd加入到epollfd的IO复用队列;
- 当connfd上有数据到来或写缓冲有数据可以出发,epoll_wait便返回（这里读写IO都是非阻塞IO），然后等待工作线程处理。


go借助自身调度器和协程将非阻塞io方式转换成了阻塞模式，大大降低了并发编程的难度。

```
package main

import (
	"log"
	"net"
)

func main() {
	ln, err := net.Listen("tcp", ":8080")
	if err != nil {
        	log.Println(err)
        	return
	}
	for {
        	conn, err := ln.Accept()
        	if err != nil {
            	log.Println(err)
            	continue
        	}

        	go echoFunc(conn)
	}
}

func echoFunc(c net.Conn) {
	buf := make([]byte, 1024)

	for {
        	n, err := c.Read(buf)
        	if err != nil {
            	log.Println(err)
            	return
        	}

        	c.Write(buf[:n])
	}
}
```

上图是go常见的利用协程编写高并发方式。

---
### go将多路复异步io转成阻塞io原理

具体可以参考这部分golang的实现源码。因为Go语言需要跑在不同的平台上，有Linux、Unix、Mac OS X和Windows等，所以需要靠事件驱动的抽象层来为网络库提供一致的接口，从而屏蔽事件驱动的具体平台依赖实现。<br>

主要的接口：创建事件驱动实例、添加fd、删除fd、等待事件以及设置DeadLine。`runtime_pollServerInit`负责创建事件驱动实例，`runtime_pollOpen`将分配一个PollDesc实例和fd绑定起来，然后将fd添加到epoll中，`runtime_pollClose`就是将fd从epoll中删除，同时将删除的fd绑定的PollDesc实例删除，`runtime_pollWait`接口一般是在非阻塞读写发生EAGAIN错误的时候调用，作用就是park当前读写的goroutine。<br>

netpoll_epoll.c文件是Linux平台使用epoll作为网络IO多路复用的实现代码，只有4个函数，分别是`runtime·netpollinit`、`runtime·netpollopen`、`runtime·netpollclose`和`runtime·netpoll`。init函数就是创建epoll对象，open函数就是添加一个fd到epoll中，close函数就是从epoll删除一个fd，netpoll函数就是从epoll wait得到所有发生事件的fd，并将每个fd对应的goroutine(用户态线程)通过链表返回。<br>


**PollDesc是整个抽象层的核心结构**

```
struct PollDesc
{
	PollDesc* link;	// in pollcache, protected by pollcache.Lock
	Lock;		// protectes the following fields
	uintptr	fd;
	bool	closing;
	uintptr	seq;	// protects from stale timers and ready notifications
	G*	rg;	// G waiting for read or READY (binary semaphore)
	Timer	rt;	// read deadline timer (set if rt.fv != nil)
	int64	rd;	// read deadline
	G*	wg;	// the same for writes
	Timer	wt;
	int64	wd;
};
```

每个添加到epoll中的fd都对应了一个PollDesc结构实例，PollDesc维护了读写此fd的goroutine。**当在一个fd上读写遇到EAGAIN错误的时候，就将当前goroutine存储到这个fd对应的PollDesc中，同时将goroutine给park住，直到这个fd上再此发生了读写事件后，再将此goroutine给ready激活重新运行。**<br>

pollDesc对象最需要关注的就是其Init方法，这个方法通过一个sync.Once变量来调用了runtime_pollServerInit函数，也就是创建epoll实例的函数。

```c
var serverInit sync.Once

func (pd *pollDesc) Init(fd *netFD) error {
	serverInit.Do(runtime_pollServerInit)
	ctx, errno := runtime_pollOpen(uintptr(fd.sysfd))
	if errno != 0 {
		return syscall.Errno(errno)
	}
	pd.runtimeCtx = ctx
	return nil
}
```


网络编程中的所有socket fd都是通过netFD对象实现的，netFD是对网络IO操作的抽象

```
// Network file descriptor
type netFD struct {
	// locking lifetime of sysfd + serialize access to Read and Write methods
	fdmu fdMutex

	// immutable until Close
	sysfd       int
	family      int
	sotype      int
	isConnected bool
	net         string
	laddr       Addr
	raddr       Addr

	// wait server
	pd pollDesc
}
```

netFD对象的init函数仅仅是调用了pollDesc实例的Init函数，作用就是将fd添加到epoll中，如果这个fd是第一个网络socket fd的话，这一次init还会担任创建epoll实例的任务。


```
for {
	n, err = syscall.Read(int(fd.sysfd), p)
	if err != nil {
		n = 0
		if err == syscall.EAGAIN {
			if err = fd.pd.WaitRead(); err == nil {
				continue
			}
		}
	}
	err = chkReadErr(n, err, fd)
	break
}
```

重点关注这个for循环中的syscall.Read调用的错误处理。

- 当有错误发生的时候，会检查这个错误是否是syscall.EAGAIN，如果是，则调用WaitRead将当前读这个fd的goroutine给park住，直到这个fd上的读事件再次发生为止;
- 当这个socket上有新数据到来的时候，WaitRead调用返回，继续for循环的执行。

这样的实现，就让调用netFD的Read的地方变成了同步“阻塞”方式编程，不再是异步非阻塞的编程方式了。netFD的Write方法和Read的实现原理是一样的，都是在碰到EAGAIN错误的时候将当前goroutine给park住直到socket再次可写为止。



---
### 参考资料
- [聊聊IO多路复用之select、poll、epoll详解](https://my.oschina.net/xianggao/blog/663655)
- [深入Go语言网络库的基础实现](https://blog.csdn.net/xiaolei1982/article/details/53562858)
- [IO多路复用与Go网络库的实现](https://ninokop.github.io/2018/02/18/IO%E5%A4%9A%E8%B7%AF%E5%A4%8D%E7%94%A8%E4%B8%8EGo%E7%BD%91%E7%BB%9C%E5%BA%93%E7%9A%84%E5%AE%9E%E7%8E%B0/)
