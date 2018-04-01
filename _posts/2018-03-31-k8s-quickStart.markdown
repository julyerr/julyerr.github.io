---
layout:     post
title:      "k8s 简介和框架介绍"
subtitle:   "k8s 简介和框架介绍"
date:       2018-03-31 12:00:00
author:     "julyerr"
header-img: "img/k8s/k8s.png"
header-mask: 0.5
catalog: 	true
tags:
    - k8s
---

>k8s事实上已经成为容器调度管理的行业标准，本文对k8s(kurbenetes)做一个overview。

### k8s架构 

![](/img/k8s/arch.jpeg)

分布式环境，整体的架构有很多类似之处，一个master对应多个slave，只是各个架构的名称有所不同

### k8s中主要概念

- **Pod**
![](/img/k8s/pod.PNG)

    - Pod是在K8s集群中运行部署应用或服务的最小单元，可以支持多容器的;
    - Pod的设计理念是支持多个容器在一个Pod中共享网络地址和文件系统，可以通过进程间通信和文件共享这种简单高效的方式组合完成服务。目前K8s中的业务主要可以分为长期伺服型（`long-running`）、批处理型（`batch`）、节点后台支撑型（`node-daemon`）和有状态应用型（`stateful application`）；分别对应的小机器人控制器为`Deployment`、`Job`、`DaemonSet`和`PetSet`.<br>

- **部署(Deployment)**<br>
部署表示用户对K8s集群的一次更新操作。

- **任务（Job）**<br>
	Job是K8s用来控制批处理型任务的API对象。批处理业务与长期伺服业务的主要区别是批处理业务的运行有头有尾，而长期伺服业务在用户不停止的情况下永远运行。

- **复制控制器（Replication Controller，RC）**<br>
	监控运行中的Pod，保证只运行指定数目的Pod副本。RC是K8s较早期的技术概念，只适用于长期伺服型的业务类型

- **副本集（Replica Set，RS）**<br>
	RS是新一代RC，提供同样的高可用能力，能支持更多中的匹配模式。

- **后台支撑服务集（DaemonSet）**<br>
	长期伺服型和批处理型服务的核心在业务应用，而后台支撑型服务的核心关注点在K8s集群中的节点（物理机或虚拟机）。典型的后台支撑型服务包括，存储，日志和监控等在每个节点上支持K8s集群运行的服务。

- **有状态服务集（PetSet）**<br>
	RC和RS主要是控制提供无状态服务的，名字变了、名字和启动在哪儿都不重要，重要的只是Pod总数，一般不挂载存储或者挂载共享存储，保存的是所有Pod共享的状态;
    - PetSet是用来控制有状态服务，PetSet中的每个Pod的名字都是事先确定的，如果一个Pod出现故障，从其他节点启动一个同样名字的Pod，要挂在上原来Pod的存储继续以它的状态提供服务;
    - 适合于PetSet的业务包括数据库服务MySQL和PostgreSQL，集群化管理服务Zookeeper、etcd等有状态服务。

- **服务**
![](/img/k8s/service.PNG)
	服务发现完成的工作，是针对客户端访问的服务，找到对应的的后端服务实例。每个Service会对应一个集群内部有效的虚拟IP，集群内部通过虚拟IP访问一个服务。在K8s集群中微服务的负载均衡是由Kube-proxy实现的。

- **标签（Lable)**<br>
	为pod添加的可用于搜索或关联的一组key/value标签，而service和replicationController正是通过label来与pod关联的。

![](/img/k8s/label.png)		

- **API**<br>
	每个API对象都有3大类属性：元数据metadata、规范spec和状态status。
    - 元数据是用来标识API对象的，每个对象都至少有3个元数据：namespace，name和uid;
    - status描述了系统实际当前达到的状态（Status）;
    - 所有的配置都是通过API对象的spec去设置的，也就是用户通过配置系统的理想状态来改变系统，这是k8s重要设计理念之一，即所有的操作都是声明式（Declarative）的而不是命令式（Imperative）的。在分布式环境中，声明式操作比命令式操作更可靠。

- **联合集群服务（Federation）**<br>
	在云计算环境中，服务的作用距离范围从近到远一般可以有：同主机（Host，Node）、跨主机同可用区（Available Zone）、跨可用区同地区（Region）、跨地区同服务商（Cloud Service Provider）、跨云平台。

	当用户通过Federation的API Server创建、更改API对象时，Federation API Server会在自己所有注册的子K8s Cluster都创建一份对应的API对象。在提供业务请求服务时，K8s Federation会先在自己的各个子Cluster之间做负载均衡，而对于发送到某个具体K8s Cluster的业务请求，会依照这个K8s Cluster独立提供服务时一样的调度模式去做K8s Cluster内部的负载均衡。

- **存储卷**<br>
	K8s集群中的存储卷跟Docker的存储卷有些类似，只不过Docker的存储卷作用范围为一个容器，而K8s的存储卷的生命周期和作用范围是一个Pod。支持多种公有云平台的存储，包括AWS，Google和Azure云；支持多种分布式存储包括GlusterFS和Ceph；也支持较容易使用的主机本地目录hostPath和NFS。
    - **持久存储卷（Persistent Volumn，PV）** pv是资源的提供者
	- **持久存储卷声明（Persistent Volumn Claim，PVC）** pvc是资源的使用者

- **安全相关的技术点**
	- **秘盒对象** Secret是用来保存和传递密码、密钥、认证凭证这些敏感信息的对象。
	- **用户帐户（User Account）和服务帐户（Service Account）** 用户帐户对应的是人的身份，人的身份与服务的namespace无关，所以用户账户是跨namespace的；而服务帐户对应的是一个运行中程序的身份，与特定namespace是相关的。
	- **名字空间（Namespace）** 名字空间为K8s集群提供虚拟的隔离作用，初始化的时候存在两个命名空间，分别是默认名字空间default和系统名字空间kube-system
	- **RBAC模式授权和ABAC模式授权** 在ABAC中，K8s集群中的访问策略只能跟用户直接关联；而在RBAC中，访问策略可以跟某个角色关联，具体的用户在跟一个或多个角色相关联。

---
### k8s中的构件

上面的概念还是比较抽象的，结合下面的k8s构件也许更好理解一点。

![](/img/k8s/components.jpeg)		


### kube-master
Master由API Server、Scheduler以及Registry等组成。

#### API Server

作为kubernetes系统的入口，封装了核心对象的增删改查操作，以RESTFul接口方式提供给外部客户和内部组件调用。其他所有组件都必须通过它提供的API来操作资源数据.<br>
**作用**

- 保证集群状态访问的安全
- 隔离了集群状态访问的方式和后端存储实现的方式。

![](/img/k8s/api-registry.png)		

上图展示了master的工作流程

- Kubecfg将特定的请求，比如创建Pod，发送给Kubernetes Client;
- Kubernetes Client将请求发送给API server;
- API Server根据请求的类型，比如创建Pod时storage类型是pods，然后依此选择何种RE- ST Storage API对请求作出处理;
- REST Storage API对的请求作相应的处理;
- 将处理的结果存入高可用键值存储系统Etcd中;
- 在API Server响应Kubecfg的请求后，Scheduler会根据Kubernetes;
- Client获取集群中运行Pod及Minion/Node信息;
- 依据从Kubernetes Client获取的信息，Scheduler将未分发的Pod分发到可用的Minion/Node节点上.

- **Minion Registry**<br>
    Minion Registry负责跟踪Kubernetes集群中Minion(Host)信息。Kubernetes将Minion Registry封装成实现Kubernetes API Server的RESTful API接口，并把Minion的相关配置信息存储到etcd。通过这些API，我们可以对Minion Registry做Create、Get、List、Delete操作，由于Minon只能被创建或删除，所以不支持Update操作。除此之外，Scheduler根据Minion的资源容量来确定是否将新建Pod分发到该Minion节点。

- **Pod Registry**<br>
    Pod Registry负责跟踪Kubernetes集群中有多少Pod在运行，以及这些Pod跟Minion是如何的映射关系。将Pod Registry和Cloud Provider信息及其他相关信息封装成实现Kubernetes API Server的RESTful API接口REST。通过这些API，我们可以对Pod进行Create、Get、List、Update、Delete操作，并将Pod的信息存储到etcd中，而且可以通过Watch接口监视Pod的变化情况，比如一个Pod被新建、删除或者更新。

- **Service Registry**<br>
    Service Registry负责跟踪Kubernetes集群中运行的所有服务。根据提供的Cloud Provider及Minion Registry信息把Service Registry封装成实现Kubernetes API Server需要的RESTful API接口REST。利用这些接口，我们可以对Service进行Create、Get、List、Update、Delete操作，以及监视Service变化情况的watch操作，并把Service信息存储到etcd。

- **Controller Registry**<br>
    Controller Registry负责跟踪Kubernetes集群中所有的Replication Controller，Replication Controller维护着指定数量的pod 副本(replicas)拷贝。通过封装Controller Registry为实现Kubernetes API Server的RESTful API接口REST， 利用这些接口，我们可以对Replication Controller进行Create、Get、List、Update、Delete操作，以及监视Replication Controller变化情况的watch操作，并把Replication Controller信息存储到etcd。

- **Endpoints Registry**<br>
    Endpoints Registry负责收集Service的endpoint，比如`Name："mysql"，Endpoints: ["10.10.1.1:1909"，"10.10.2.2:8834"]`，同Pod Registry，Controller Registry也实现了Kubernetes API Server的RESTful API接口，可以做Create、Get、List、Update、Delete以及watch操作。

- **Binding Registry**<br>      
    Binding包括一个需要绑定的Pod的ID和Pod被绑定的Host，Scheduler写Binding Registry后，需绑定的Pod被绑定到一个host。Binding Registry也实现了Kubernetes API Server的RESTful API接口，但Binding Registry是一个write-only对象，所有只有Create操作可以使用， 否则会引起错误。


- **Etcd Registry**<br>
    etcd并不是k8s的一部分，而是作为一个高可用的分布式键值对数据库。

#### Controller Manager

实现集群故障检测和恢复的自动化工作，负责执行各种控制器，主要有
- **endpoint-controller**：定期关联service和pod(关联信息由endpoint对象维护)，保证service到pod的映射总是最新的。
- **replication-controller**：定期关联replicationController和pod，保证replicationController定义的复制数量与实际运行pod的数量总是一致的。

### Scheduler

收集和分析当前Kubernetes集群中所有Minion/Node节点的资源(内存、CPU)负载情况，然后依此分发新建的Pod到Kubernetes集群中可用的节点。

### kube-node

1. 负责Node节点上pod的创建、修改、监控、删除等全生命周期的管理;
2. 定时上报本Node的状态信息给API Server

![](/img/k8s/kubelet.png)


### Proxy 
Kube-proxy是K8s集群内部的负载均衡器。它是一个分布式代理服务器，在K8s的每个节点上都有一个。每创建一种Service，Proxy主要从etcd获取Services和Endpoints的配置信息（也可以从file获取），然后根据配置信息在Node上启动一个Proxy的进程并监听相应的服务端口,提供了Service转发服务端口对外提供服务的能力，Proxy后端使用了随机、轮循负载均衡算法.



---
### 参考资料
- [Kubernetes总架构图](https://blog.csdn.net/huwh_/article/details/71308171)
- [《K8s与云原生应用》之K8s的系统架构与设计理念](http://chuansong.me/n/481097351563)
- [开源容器集群管理系统Kubernetes架构及组件介绍](https://yq.aliyun.com/articles/47308?spm=5176.100240.searchblog.19.jF7FFa)