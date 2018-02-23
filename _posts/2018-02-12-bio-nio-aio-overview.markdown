---
layout:     post
title:      "BIO-NIO-AIO总概"
subtitle:   "BIO-NIO-AIO总概"
date:       2018-02-12 12:00:00
author:     "julyerr"
header-img: "img/lib/io/java-net-io.jpeg"
header-mask: 0.5
catalog: 	true
tags:
    - io
    - java
---

>本文主要就网络通信中io不同方式进行总结,主要内容参考该[blog](http://blog.csdn.net/historyasamirror/article/details/5778378),然后简要引入java中对bio和nio以及aio的支持,详细内容参见后续blog.

通信一方发起网络数据读取操作经过两个阶段

- 等待数据准备好
- 将数据从内核拷贝到进程

不同阶段的不同处理方式决定了IO Model的不同	

---
#### 阻塞IO(BIO)
![](/img/lib/io/bio.gif)	
bio 中recvfrom和copy datagram两个阶段均阻塞

#### 非阻塞IO(nio)
![](/img/lib/io/nio.gif)

- nio 在recvfrom阶段发现如果数据没有准备好的话,直接返回error
- 用户进程可以多次调用recvfrom获知数据准备情况
- copy datagram阶段也是阻塞的

#### 多路复用IO(IO multiplexing)
![](/img/lib/io/multiplex-io.gif)

- 通常select负责多个socket,进程调用select进入阻塞状态,直到任意一个socket数据准备成功
- 而后调用recvfrom读取数据
- copy datagram阶段还是阻塞的.

**notes**<br>
	整个过程进行了两次系统调用(select,recvfrom)开销比较大,如果请求数量不是很多的话,select/epoll的web server不一定比使用multi-threading + blocking IO的web server性能更好.

#### 信号驱动IO(SIGIO)	
![](/img/lib/io/sigio.jpg)		

- 对信号驱动IO安装信号驱动函数
- 等待数据读取过程并不阻塞
- 数据准备好时，线程会收到一个SIGIO信号，可在信号处理函数中调用I/O操作函数处理数据


#### 异步IO(Asynchronous I/O)
![](/img/lib/io/aio.gif)		

- 进程发起数据读取请求之后可以直接返回,两阶段均没有发生阻塞
- 只是在数据复制成功之后发送一个成功的信号.

除了AIO之外,前三种io方式均在不同阶段发生了阻塞,因此不能称为aio也就是所谓的`同步io`.


java中java.net的Socket的实现就是阻塞模式
	![](/img/lib/io/java-bio.png)
jdk 1.4加入NIO对多路复用IO的支持
	![](/img/lib/io/java-nio.png)
jdk1.7 加入NIO2.0(AIO)对异步IO的实现
	![](/img/lib/io/java-aio.png)

#### 几种IO总结和比较
![](/img/lib/io/io-compare.jpg)


#### 参考资料

- [系统间通讯方式之（Java NIO多路复用模式）（四）](http://blog.csdn.net/u010963948/article/details/78507255)
- [IO - 同步，异步，阻塞，非阻塞 （亡羊补牢篇）](http://blog.csdn.net/historyasamirror/article/details/5778378)