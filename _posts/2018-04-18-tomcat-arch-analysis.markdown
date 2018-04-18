---
layout:     post
title:      "tomcat总体架构"
subtitle:   "tomcat总体架构"
date:       2018-04-18 6:00:00
author:     "julyerr"
header-img: "img/web/tomcat/tomcat.png"
header-mask: 0.5
catalog:    true
tags:
    - tomcat
---

>这一阵子打算好好啃下几本有深度的书籍，同时整理好读书笔记。<br>

tomcat作为一个开源web容器有很多内容值得去学习，例如工作流程、运行维护、整个架构包括设计模式等。虽然以前用过tomcat，但是总是感觉缺少点深度。知乎上推荐相关的[资料](https://www.zhihu.com/question/19896154)，准备从《tomcat架构解析》、《深入剖析tomcat》以及部分源码的分析方面研究tomcat。<br>

个人认为《tomcat架构解析》写得非常好，内容跟进最新tomcat版本，同时总结精简，有深度。下面是各个章节主要内容

- 第1章 tomcat简单介绍，安装、启动、部署以及目录结构
- 第2章 介绍tomcat容器、链接器各组件基本概念
- 3-5 8-9章节 架构以及相关模块深入分析
- 6-7章节 tomcat管理以及web服务器集成
- 10章 性能优化
- 11章 附加功能，嵌入式启动、JNDI等实现

其实任何一个框架都可以从下面三方面分析

- 基本设计
- 架构及工作原理
- 各个模块的特性及使用方式

### tomcat介绍

**历史、不同版本特性**

![](/img/web/tomcat/analysis/second/versions.png)

- tomcat7.x开始支持websocket、servlet 3.1；
- tomcat8.x开始支持nio2和http2协议；
- tomcat9.x开始支持servlet 4.0
	
**安装、启动和应用部署**<br>
单机版安装部署还是较为简单的，需要注意的就是设置环境变量；spring开发还需要在idea配置tomcat<br>
	
**tomcat目录结构**

![](/img/web/tomcat/analysis/second/conf.png)

---
### tomcat总体架构

下面针对各个实际问题慢慢演变出tomcat现在架构<br>

**Server**<br>
如果编写过socket的服务器、客户端通信的话，很好理解Server工作模型

![](/img/web/tomcat/analysis/second/arch0.png)

为了适配多种网络协议，同时保证web应用不需要做任何变更，可以将网络协议和请求处理概念上分离。一个Server包含多个Service（相互独立），一个Service负责维护多个Connector和Container（Engine），如下

![](/img/web/tomcat/analysis/second/arch1.png)

应用服务器是用来部署并运行web应用的，是一个运行环境，而不是独立业务处理系统。因此，需要包含多个web应用，tomcat中使用context表示web应用，并且一个Engine可以包含多个Context。Context也有start（）和stop（）方法，在启动时加载资源以及在停止时释放资源。

![](/img/web/tomcat/analysis/second/arch2.png)

如果一台主机，承担了服务多个域名的服务。可以将每个域名视为一个虚拟主机，每个虚拟主机下包含多个web应用

![](/img/web/tomcat/analysis/second/arch3.png)

一个web应用中，可包含多个Servlet实例处理不同链接的请求，tomcat中使用wrapper表示Servlet。

![](/img/web/tomcat/analysis/second/arch4.png)

容器作用就是处理接受自客户端请求并返回响应数据，使用Container表示容器，container可以添加并维护子容器。下图中组合关系使用虚线，体现某些应用场景可不必支持多web应用，也反映了tomcat的灵活性

![](/img/web/tomcat/analysis/second/arch5.png)

tomcat中的container另一个重要功能就是后台处理，在Container中定义backgroundProcess()方法，并在基础抽象类ContainerBase中确保启动组件同时异步启动后台处理，各个容器仅需要使用backgroundProcess()方法，而不需要考虑创建异步线程。

#### LifeCycle
针对所有拥有生命周期管理特性的组件抽象了LifeCycle通用接口

- init() 初始化组件
- start() 启动组件
- stop() 停止组件
- destroy() 销毁组件

每个生命周期方法影响组件状态并且触发相关事件
![](/img/web/tomcat/analysis/second/life-event.png)

![](/img/web/tomcat/analysis/second/lifecycle.png)

默认三个状态无关事件类型，PERIODIC_EVENT 用于container的后台定时处理，每次调用后触发该事件，CONFIGURE_START_EVENT CONFIGURE_STOP_EVENT见后文讲解

#### Pipeline和Value	
责任链模式通常用于增强组件的灵活性和可扩展性，tomcat使用责任链模式实现客户端请求处理。
	
- pipeline接口用于构造责任链，value接口代表责任链上每个处理器；
- pipeline中维护了基础的value，位于pipeline的末端（最后执行），通过addValue（）方法可以为pipeline添加其他的value（按照添加顺序执行）；
- tomcat每个层级的容器（Engine、Host、Context、Wrapper）均有对应的value实现，并且维护了pipeline实例

![](/img/web/tomcat/analysis/second/pipeline.png)
	

引入lifycycle和pipeline、value整体架构如下

![](/img/web/tomcat/analysis/second/pipeline-val.png)

#### Connector设计
Connector的功能

- 监听服务器端口，读取客户端请求
- 数据按照指定协议解析
- 请求地址匹配正确容器处理
- 返回响应	

![](/img/web/tomcat/analysis/second/connector.png)

ProtocolHandler代表协议处理器（Http11NioProtocol），包含Endpoint（Nio2Endpoint）用于启动Socket监听，还包含Processor,用于按照指定协议读取数据，并交由容器处理（Http11NioProcessor)。Connector启动之后，Endpoint会启动线程监听服务器端口，并在接收到请求后调用Processor进行数据读取。<br>

Processor读取客户端请求之后，按照请求地址映射到具体的容器进行处理。Mapper维护容器映射信息，MapperListener实现ContainerListener和LifeCycleListener接口，用在容器状态或者生命周期发生变化时，注册或者取消对应的容器映射信息。tomcat7.x版本之前，由container维护mapper模块，8.x之后由service维护（关系更加密切）。<br>

使用adapter模式实现了Connector和Mapper、Container解耦,主要是考虑部分开发者可能只希望使用tomcat的Connector模块，自己开发容器部分。

![](/img/web/tomcat/analysis/second/connector-server.png)


#### Executor	
为提高应用服务器性能、资源利用率等，并发是非常重要的一个方面。tomcat中Executor由Service维护（如果配置线程池的话），同一个Service组件可以共享一个线程池；
如果没有定义线程池，相关组件（Endpoint等）会自动创建线程池，此时线程池不共享

![](/img/web/tomcat/analysis/second/executor.png)

#### Boostrap 和 Catalina
使用boostrap和catilina方便系统的可配置性。

- Catalina类提供shell程序，解析server.xml创建各个组件，同时负责启动、停止应用服务器；
- boostrap依赖于JRE并且为tomcat应用服务器创建共享类加载器，构造catalina（反射方式）以及整个tomcat服务器。

boostrap和catalina的分离，实现了启动入口和核心环境的解耦，可以非常灵活组织中间件产品结构，例如可以将Tomcat嵌入到自己应用系统中进行启动。<br>

下面是tomcat的整体架构

![](/img/web/tomcat/analysis/second/whole-arch.png)

---
#### tomcat启动
统一按照生命周期管理接口lifecycle定义进行启动，下面是简略图，详细在后序blog中分析
![](/img/web/tomcat/analysis/second/start-1.png)

### 请求处理过程
请求处理开始于监听socket端口接收到数据，结束于将服务处理结果写入socket输出流，下面是简略图，详细在后序blog中分析

![](/img/web/tomcat/analysis/second/request.png)

---	
### tomcat类加载器

jvm中三种类加载器，父委托机制。为了方便使用最新的类库，java中提供Endorsed Standands机制，用来替换部分java中的核心类库(将lib包复制到$JAVA_HOME/lib/endorsed/下，将优先于JVM的类加载)。<br>

应用服务器自行创建类加载器，主要从以下几个方面考虑

- **隔离性**
	各个web应用类库互相分离,每个web应用程序使用独立的类加载器加载应用所依赖的类库，不会发生jar包版本之间冲突等；
- **灵活性**
	可以针对不同web应用使用不同的jar包
- **性能**
	加载lib数量少，加载和查找Class等开销降低

![](/img/web/tomcat/analysis/second/classloader.png)

- **Common**：加载路径common.loader,默认指向$CATALINE_HOME/lib，加载tomcat内部应用服务器和web应用均可见的类
- **Catalina**: 加载路径server.loader，默认为空，使用common加载器加载应用服务器，只加载tomcat应用服务内部可见的类
- **shared**：加载路径shared.loader,默认为空，使用common加载器加载应用服务器，
- **web应用**：加载/WEB-INF/classes目录下Class和资源文件以及/WEB-INF/lib目录下的jar包

web应用类加载默认加载顺序如下

- 缓存中加载
- 如果没有，从JVM的boostrap类加载器中加载
- 如果没有从当前类加载器（WEB-INF/classes、WEB-INF/lib顺序）
- 如果没有，从父类加载器加载，System、Common、Shared

java核心类库、Servlet规范相关类库无法无法覆盖。如果需要覆盖注入java提供的包，例如XML工具包，只能通过endorsed方式实现。

---
### 参考资料
- 《tomcat架构解析》