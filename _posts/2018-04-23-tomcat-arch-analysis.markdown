---
layout:     post
title:      "Coyote"
subtitle:   "Coyote"
date:       2018-04-23 6:00:00
author:     "julyerr"
header-img: "img/web/tomcat/tomcat.png"
header-mask: 0.5
catalog:    true
tags:
    - tomcat
---

Coyote接受来自客户端的请求，按照既定协议（HTTP等）进行解析，然后交由Servlet容器处理。

![](/img/web/tomcat/analysis/four/coyote-request.png)

#### tomcat链接器基础知识

**应用通信协议**

- **HTTP1.1**:绝大部分web应用采用的协议
- **AJP**：用于和Web服务器（如Apache HTTP Server)集成,用于静态资源优化和集群部署
- **HTTP2.0**：下一代HTTP协议，tomcat8.5开始支持

**IO模型**

- **NIO**:java多路复用io类库
- **NIO2**：java异步IO类库
- **APR**：Apache可移植运行库（采用C/C++编写），需要单独安装APR库

tomcat8.0之前采用BIO的方式，之后改用NIO,无论NIO、NIO2还是APR性能均优于BIO

![](/img/web/tomcat/analysis/four/protocols.png)


### Web请求处理

**Connector核心接口、抽象类**

![](/img/web/tomcat/analysis/four/connector-arch.png)

- **Endpoint**:传输层的抽象，提供了抽象类AbstractEndpoint，根据IO方式不同，提供了NioEndpoint(NIO)、AprEndpoint(APR)以及Nio2Endpoint(NIO2)三个实现（tomcat8.0之前还有JIoEndpoint-BIO）

- **Processor**:应用层的抽象，负责构建Request和Response对象，并通过Adapter提交到Catalina容器处理。三个实现类
Http11Processor(HTTP/1.1)，AjpProcessor(AJP)、StreamProcessor(HTTP/2.0)，还提供了两个升级协议处理实现：
UpgradeProcessorInternal(处理内部升级协议如HTTP/2.0和WebSocket)和UpgradeProcessorExternal(扩展升级协议)。Processor接口是单线程的，可以在同一次连接中复用。

- **ProtocolHandler**:封装了Endpoint和Processor，针对具体协议进行处理。根据协议和IO不同，提供了6个实现类：
HTTP11NioProtocol，HTTP11AprProtocol、Http11Nio2Protocol、AjpNioProtocol、AjpAprProcotol、
AjpNio2Protocol。

- **UpgradeProtocol**:表示HTTP升级协议

#### tomcat connector请求处理的简化版实现

![](/img/web/tomcat/analysis/four/request.png)

#### NIO请求过程

![](/img/web/tomcat/analysis/four/request-nio.png)

1. Connector启动时，启动持有的Endpoint实例，每个Endpoint运行多个线程，每个线程（运行AbstractEndpoint.Acceptor）对端口进行监听;
2. 请求来临时，Acceptor将Socket封装成SocketWrapper实例，交由SocketProcessor对象处理;
3. SocketProcessor是线程池worker实例，每个IO方式均有自己实现，先判断Socket状态然后提交到ConnnectionHandler进行处理;
    - 每个有效链接都会缓存Processor对象，在链接关闭时，Processor对象还会被释放到一个回收队列（升级协议不会回收）；
    - 处理请求时，先尝试从链接中获取Processor对象，如果没有可用对象，由具体协议创建一个Processor使用。
    - 如果存在协商协议，获取到的Processor对象还需要协商协议。

4. ConnectionHandler调用Processor.process()方法，如果不是协商协议，Processor直接调用service方法将其提交到catalina容器处理；
如果是协商协议请求，ConnectionHandler会从Processor得到UpgradeToken对象，构造升级的Processor实例（HTTP/2和WebSocket使用UpgradeProcessorInternal，否则UpgradeProcessorExternal)替换当前Processor，然后进行后续处理。

---
### HTTP、AJP、HTTP/2.0协议知识

#### AJP

在Servlet容器前端部署专门的web服务器，可以提高整体的性能，优势如下

1. web服务器提供负载均衡机制，大大降低单台服务器的负载，提升请求处理效率
2. 充分利用web服务器静态资源处理上的优势

为尽可能提高web服务器和servlet容器之间传输数据的效率，两者使用tcp链接通信（替代昂贵的socket创建过程），同时采用二进制格式进行传输。

![](/img/web/tomcat/analysis/four/ajp-request.png)

web服务器和servlet容器之间链接不能被多路复用。<br>

由于web服务器和servlet容器采用二进制进行通信，因此两者需要协商好请求和响应消息格式，涉及内容较为繁琐，这里就不展开讨论

#### HTTP/2

与HTTP/1.1相比，HTTP/2.0在以下方面进行了改进

- 采用二进制格式传输数据而非文本格式
- 对消息头采用了HPACK压缩，提升传输效率
- 基于帧和流的多路复用，真正实现了基于一个链接的多请求并发处理
- 支持服务器推送

HTTP/2.0中，基本的协议单元是帧

![](/img/web/tomcat/analysis/four/frame.png)

按照用途的不同，可以分为不同类型的帧，如HEADERSs和DATA帧用于HTTP请求和响应，而如SETTING、WINDOWN_UPDATE等则用于HTTP/2.0的特性，HTTP/1.1和HTTP/2.0转换和对应关系如下

![](/img/web/tomcat/analysis/four/http-compare.png)

Stream是客户端和服务器段通过HTTP/2.0链接交换的独立的、双向的帧序列

![](/img/web/tomcat/analysis/four/stream.png)

具有如下特性

- 一个HTTP/2.0链接可以并发的打开多个流，并可以从多个流的任意端点交换帧
- 流可以被任意端点关闭
- 流通过一个整数唯一标志（由初始化流的端点分配）
- 流是相互独立的，任意个流的阻塞或者停止请求不会影响其他流的处理

---
### NIO、NIO2、ARP三种IO方式以及web请求过程

#### NIO

相对于BIO的新的概念

- **通道（Channel）**
通道是双向的，传统的BIO的基于流的方式是单向的（一个流要么用于读、要么用于写）

- **缓冲区（Buffer）**
发送给通道的所有对象必须先放到缓冲区中，同样从通道中读取数据都要先读取到缓冲区中

- **选择器（Selector）**
同时监听多个通道的事件以实现异步IO

![](/img/web/tomcat/analysis/four/nio-request-first.png)

1. NioEndpoint根据pollerThreadCount创建Poller线程，Poller线程是单独启动不会占用请求处理的线程池
2. Acceptor接收到链接后，将获取到的socketChannel置为非阻塞，构造NioChannel对象，通过轮转法获取poller实例，并将NioChannel注册到PollerEvent事件队列
3. poller运行时，将PollerEvent事件取出，并将socketChannel读事件注册到poller持有的selector上，然后执行selector.select。当捕获读事件，构造socketProcessor，并提交到线程池进行请求处理。

NioSelectorPool提供了一个线程池，可以配置是否所有的SocketChannel共享一个Selector实例，如果SocketChannel没有共享一个Selector实例，相当于SocketChannel分散注册到SelectorPool的不同对象中，可以避免因大量SocketChannel集中注册事件到同一个Selector对象而影响服务器性能。


NioSelectorPool读写信息分为阻塞和非阻塞两种方式，在阻塞方式下进行读写时并没有立即监听OP_READ/OP_WRITE事件，而是在第一次操作没有成功时再进行注册（乐观设计）。


#### NIO2

JDK7新增的文件以及网络IO特性，最重要的便是异步IO（AIO）的支持

- **通道**
 AIO中需要实现接口AsynchronousChannel，JDK7中提供三个通道实现类，
AsynchronousFileChannel（用于文件传输）、
AsynchronousServerSocketChannel和AsynchronousSocketChannel（用于网络io）。

- **缓冲区**
 与nio类似

- **Future和CompletionHandler**
 Future需要自己检测io状态，CompletionHandler则由JDK检测状态，并调用自己设置的方法。

无论是接受socket请求还是读写操作，返回的Future对象表示io等待状态（isDone判断是否完成、get等待完成并取得操作结果），接受请求，get返回的是AsynchronousSocketChannel，读写操作时，get返回的是读写操作结果。


CompletionHandler在io完成时，调用接口的completed（）方法；操作失败时，调用failed（）方法。

#### 异步通道组
每个异步通道均属于一个指定的异步通道组，同一个通道组内的通道共享一个线程池。线程池内线程接受指令来执行io事件并将结果分发到CompletionHandler。


JVM为了一个系统范围的通道组实例，作为默认通道组。默认通道组通过两个系统属性完成配置

- java.nio.channels.DefaultThreadPool.threadFactory，属性为java.util.concurrent.ThreadFactory类，由系统加载并实例化；
- java.nio.channels.DefaultThreadPool.initialSize用于指定线程池初始化大小。

**自定义通道组**，通过AsynchronousChannelGroup提供的三个方法

- **withFixedThreadPool** 用于创建固定大小的线程池，比较适合简单场景：一个线程等待io事件、完成io事件、执行CompletionHandler（内核将事件分发给这些线程）。如果CompletionHandler没有及时完成，会发生阻塞的情况。最糟糕的是，线程没有被释放，内核将不再执行任何操作。可以通过缓冲线程池和设置超时时间来解决该问题。

- **withCachedThreadPool** 其中线程池只是简单执行CompletionHandler，具体的io操作由一个或者多个内部线程处理并将事件分发到缓存线程池。

- **withThreadPool** 用于根据java.util.concurrent.ExecutorService创建线程池，配置线程池需要支持切换或者无边界队列。

![](/img/web/tomcat/analysis/four/nio2-request-first.png)

与BIO、NIO类似，tomcat仍采用Acceptor线程池方式接收客户端请求。在Acceptor采用Future接受请求，使用future方式实现阻塞读写，采用CompletionHandler实现非阻塞读写。


- Nio2Endpoint创建异步通道时，指定了自定义异步通道组（使用的是请求处理线程池）；
- 接受请求采用多线程处理，以Future方式阻塞调用（只有在读取请求头时采用非阻塞方式，读取请求体和写响应时均采用阻塞方式）；
- 接受请求后，构造Nio2SocketWrapper以及SocketProcessor并提交到请求处理线程池。


#### APR（Apache Portable Runtime）

Apache可移植运行库，主要目标是创建和维护一套软件库，以便在不同操作系统底层实现的基础上提供统一的API。


tomcat启动时，会自动检测系统安装了APR，如果安装，自动采用APR进行IO处理（除非Connector的protocol被指定）。

![](/img/web/tomcat/analysis/four/apr-request-first.png)

APREndpoint的Acceptor线程以阻塞形式监听请求链接，有新的请求链接时，构造SocketWithOptionsProcessor对象提交到请求处理线程池。

- 如果对象设置了TCP_DEFER_ACCEPT标识，直接调用Handler处理请求；
- 否则，将当前Socket添加到Poller线程的轮询队列，poller线程轮询检测socket状态，根据检测结果构造socketProcessor对象并提交到请求处理线程池（socketProcessor对象调用handler进行请求处理）。

---
### 参考资料
- 《tomcat架构解析》