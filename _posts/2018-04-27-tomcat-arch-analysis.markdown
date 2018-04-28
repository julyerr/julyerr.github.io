---
layout:     post
title:      "tomcat集群配置"
subtitle:   "tomcat集群配置"
date:       2018-04-27 6:00:00
author:     "julyerr"
header-img: "img/web/tomcat/tomcat.png"
header-mask: 0.5
catalog:    true
tags:
    - tomcat
---

### web服务器和应用服务器的区别

- web服务器是处理HTTP请求的计算机系统，看重系统的吞吐量、并发量的支持，通常提供了反向代理、负载均衡、静态缓存等服务，例如常见的Apache HTTP Server、Nginx等web服务器；
- 应用服务器则是一个服务层模型，为软件开发人员提供了一套可访问的组件api，让开发人员注重业务逻辑实现，如常见的tomcat web应用服务器。

**集成应用场景**<br>
为了综合提高服务器整体性能，通常将web服务器和应用服务器集成，常见的架构如下

![](/img/web/tomcat/analysis/sixth/web-arch.png)

其中web服务器主要负责如下功能

- 静态资源优化：web服务器对静态资源处理能力普遍高于应用服务器
- 负载均衡：将客户端请求按照一定规则合理分发到当前应用服务器实例上

---
### tomcat集群

tomcat默认提供的集群方案并不能适应大规模的集群环境。当集群规模较大的时候，可以通过分组的方式（每个集群提供一组相同的服务），将其分隔为多个集群组。

![](/img/web/tomcat/analysis/sixth/tomcat-lb.png)

#### tomcat集群架构实现方案

![](/img/web/tomcat/analysis/sixth/relations.png)

- org.apache.catalina.Cluster作为catalina容器集群组件的接口，定义了与容器相关的行为，高可用行为由org.apache.catalina.ha.CatalinaCluster定义,默认实现为org.apache.catalina.ha.tcp.SimpleTcpCluter。cluster通过容器(engine或者Host)上的Valve追踪web应用的请求：
	- ReplicationValve
		在HTTP请求结束时通知集群，确定集群中是否存在数据复制
	- JvmRouteBinderValve
		当集群一个节点宕机，该valve会覆盖Cookie中的jsessionid，然后将路由改为备份节点的jvmRoute，后续请求直接作用于备份节点ClusterListener监听集群中消息的接收，负责接受来自集群中其他节点复制会话消息，交给当前节点会话管理器进行处理
- channel负责各个节点之间的通信，cluter定义了tomcat集群应用层的行为，通过channel进行消息发送和接受；
- org.apache.catalina.ha.ClusterManager 定义了集群会话管理器接口，提供了两个实现类
    - org.apache.catalina.ha.session.DeltaManager 将会话中增量数据复制到集群中所有成员
	- org.apache.catalina.ha.session.BackupManager 会话数量复制到一个备份节点
- org.apache.catalina.ha.ClusterDeployer 支持web应用的集群部署


### Apache Tribes
是用于组通信的消息框架，支持两种类型的消息传递

- 并发消息传递
- 平行消息传递

**tribes提供的特性(以下只是部分)**

- **不同消息保证级别**
	支持3个不同级别的消息传递保证：
	- NO_ACK
		只要消息发送到socket缓冲区并接受即认为消息发送成功，速度快、可靠性低
	- ACK
		当远程节点接收到消息后，会返回给发送者一个确认，表示消息接受成功。
	- SYNC_ACK
		远程节点收到消息，并且处理成功后会返回发送者一个确认，性能最差。
- **基于拦截器的消息处理**
	拦截器可以在消息发送过程中根据消息属性作出相关的处理
- **无线程的拦截器栈**
	tribes不需要单独的线程来执行消息操作，只有MessageDispatchInterceptor在单独的线程中排队并发送消息，以便进行异步消息传递。

#### 组件结构

![](/img/web/tomcat/analysis/sixth/tribes-arch.png)

- **应用层**
	- ChannelListener
			监听和接受来自channel的集群消息
	- MembershipListener
			用于监听成员的添加和移除
	- ChannnelInterceptor栈用于拦截消息处理，允许在发送和接受消息的时候修改消息		
- **io层**
	- MembershipService用于维护活动集群节点的列表
	- 支持bio和nio两种方式
	- ChannelSender消息发送、ChannelReceiver消息接受

#### Channel的默认实现 GroupChannel

**发送消息**

![](/img/web/tomcat/analysis/sixth/message-send.png)
	
上面这张图已经将所有涉及的中流程讲解非常清晰，下面对一些不太明晰的过程进行讲解。Channel.send()方法发送消息，参数包括目的成员列表、消息以及选项参数，支持的选项参数如下

![](/img/web/tomcat/analysis/sixth/channel-opts.png)

- Channel先将消息封装为一个ChannnelData对象，然后交由ChannnelInterceptor栈发送，具体消息发送由ChannelCoordinator完成
- ReplicationTransmitter 并不负责具体的发送工作，消息发送通过自身维护的多点发送器MultiPoint-Sender完成。MultiPointSender对于每个Member构造DataSender实例进行消息发送，DataSender通过具体的io方式，将消息发送到指定的Member。基于不同的DataSender，提供了4个MultiPointSender实现：
    - 基于BIO的多点MultipointBioSender；
    - 基于池的BIO多点发送PooledMultiSender；
    - 并行NIO发送ParallelNioSender；
    - 基于池的并行NIO发送PooledParallelSender。

**接收消息**

![](/img/web/tomcat/analysis/sixth/message-receive.png)

Tribes接收消息通过ChannelListener完成，事先需要将监听器实例到Channel上

- Channel启动的时候，会同时启动一个ChannelReceiver用以接收消息，当接收到消息之后，会调用ChannelCoordinator的messageReceived进行消息接受处理，根据io方式不同分为BioReceiver和NioReceiver两个ChannelReceiver实现；
- ChannelCoordinator将消息交由ChannelInterceptor栈处理（栈的处理顺序和并发消息正好相反），最后执行ChannelInterceptor的为Channel自身；
- Channel触发ChannelListener监听器完成消息接受。


#### Tribes成员添加和删除

![](/img/web/tomcat/analysis/sixth/tribes-elem-changes.png)

通过自身维护的MembershipService负责，内部启动一个发送线程和接收线程

- 发送线程会定时轮询以广播的方式将一个特定的数据包（包含该成员基本信息）发送给其他成员，表明当前成员变量处于有效的状态。同时，检测本地维护成员信息是否过期，对于过期的成员处理方式和接收到成员移除的消息的处理方式相同;
- 接受线程会轮询接受其他成员发送来的广播数据包，如果是成员添加或者移除消息，通过ChannelCoordinator和ChannelInterceptor栈会最终触发MembershipListener监听器的memberAdded和memberDisappeared方法。

---
### tomcat集群组件实现
Cluster通过封装集成底层通信框架，为tomcat容器中支持集群各个组件（会话管理器、集群部署组件）提供支持，使容器与具体通信框架解耦。SimpleTcpCluster作为tomcat提供的默认实现，基于Tribes实现。

![](/img/web/tomcat/analysis/sixth/simpleTcpCluster-arch.png)

- 继承自生命周期管理基础抽象类LifecycleMBeanBase，会随着上级容器组件的启动而启动；
- 如果会话管理器模板为DeltaManager，为SimpleTcpCluster添加ClusterSessionListener监听器，用于接受来自其他节点的会话消息；
- 为SimpleTcpCluster添加JvmRouteBinderValve和ReplicationValve两个Valve（SimpleTcpCluster启动时，会将持有的Valve添加到所属容器持有的Pipeline上）；
- 为持有的Channel添加MessageDispatchInterceptor和TcpFailureDetector拦截器


通过SimpleTcpCluster.send()方法向集群节点发送消息；<br>
接收消息时，调用ClusterListener进行处理（如果希望在容器中监听消息接受，只需要为SimpleTcpCluster添加一个ClusterListener子类）。

#### tomcat集群配置

在server.xml中配置集群，最简单的使用默认配置如下

```xml
<Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster" />
```

具体的默认配置如下

![](/img/web/tomcat/analysis/sixth/cluster-default-config.png)

其中tribes支持的拦截器

![](/img/web/tomcat/analysis/sixth/tribes-interceptor.png)

---
### 集群会话同步

tomcat提供了两个集群会话的管理器实现：DeltaManager和BackManager

**DeltaManager**<br>
当SimpleTcpCluster创建会话管理器DeltaManager时，自动添加一个ClusterSessionListener（只监听和接受节点的SessionMessage类型的消息）。

- 如果接收到SessionMessage未设置管理器名称，会将消息发送给Cluster维护的所有会话管理器；
- 如果指定了管理器的名称，将消息交由指定管理器处理。

启动时，DeltaManager会向集群中主节点获取当前集群中有效的会话。<br>


**BackupManager**<br>
采用本地会话存储管理，实际上是一个有状态、可复制的Map（LazyReplicatedMap），通过该Map,BackupManager仅将会话的增量数据复制到一个备份节点，集群中其他节点知道该备份节点的信息。


**替代方案**<br>
针对实际出现的大规模的环境，tomcat自身的会话管理器显得力不从心，可以采用高速缓存替代（Redis、Memcached等），或者自定义实现Tomcat的会话管理器org.apache.catalina.session.StoreBase。

---
### 集群部署原理及其配置方式

![](/img/web/tomcat/analysis/sixth/tomcat-lb.png)

![](/img/web/tomcat/analysis/sixth/deploy-arch.png)

集群部署基于文件消息实现，依赖于Apache Tribes通信模块。ClusterDeployer定义了集群部署组件，默认实现类为FarmWarDeployer。FarmWarDeployer实现了ClusterListener接口，在启动的时候，会自动将自己作为监听器注册到Cluster上。只接受和发送以下两类消息

- FileMessage：文件消息，用于传输部署包的文件。
- UpdeployMessage：卸载消息，用于卸载web应用。

---
### 参考资料
- 《tomcat架构解析》