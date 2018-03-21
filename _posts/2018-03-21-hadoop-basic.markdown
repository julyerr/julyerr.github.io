---
layout:     post
title:      "hadoop家族之hdfs、mapreduce、yarn简介"
subtitle:   "hadoop家族之hdfs、mapreduce、yarn简介"
date:       2018-03-21 6:00:00
author:     "julyerr"
header-img: "img/hadoop/hadoop.png"
header-mask: 0.5
catalog: 	true
tags:
    - hadoop
---

>hadoop是Apache基金会所开发的分布式系统基础架构，其核心组成部分为HDFS、MapReduce和YARN，但是hadoop的生态却是十分庞大的.

![](/img/hadoop/hadoop-env.jpg)

### HDFS

hadoop分布式文件系统，适用于将海量数据存储在廉价的机器上

![](/img/hadoop/hdfs-arch.jpg)

hdfs中有三种角色，namenode、datanode和client。

#### namenode
NameNode是分布式文件系统中的管理者，主要负责管理文件系统的命名空间、集群配置信息和存储块的复制等。具体操作会被记录在EditLog的事务日志中；同时整个文件系统的名字空间，包括数据块到文件的映射、文件的属性等，都存储在一个称为 FsImage 的文件中。下次namenode重启的时候，才会将edit logs合并到fsimage文件形成文件系统最新的快照。
	
![](/img/hadoop/hdfs-process.png)

#### secondary namenode

namenode通常运行的时间比较长，edit logs变得很大，但是fsimage存储的还是启动时候的数据。如果此时，namenode宕机了，意味着会丢失很多改动而且下次namenode启动的时候，可能合并两个文件需要较长的时间。secondary namenode的作用就是合并NameNode的edit logs到fsimage文件中，保证系统的可靠性、低延迟。

![](/img/hadoop/sec-namenode.png)

上图展示了secondary namenode工作过程，定时到NameNode去获取edit logs，并更新到fsimage上。

#### datanode
DataNode是文件存储的基本单元，它将Block存储在本地文件系统中，保存了Block的Meta-data，同时周期性地将所有存在的Block信息发送给NameNode。

#### 客户端和hdfs具体交互过程分析

**写数据**

- Client向NameNode发起文件写入的请求；
- NameNode根据文件大小和文件块配置情况，返回给Client它所管理部分DataNode的信息；
- Client将文件划分为多个Block，根据DataNode的地址信息，按顺序写入到每一个DataNode块中。

**读数据**

- Client向NameNode发起文件读取的请求；
- NameNode返回文件存储的DataNode的信息；
- Client读取文件信息。

**文件块的复制**<br>

为了保证数据的可靠性，通常一份数据有两份冗余备份（为了防止整个rack上的机器宕掉造成数据丢失，数据备份会存在不同的rack上）。客户端程序只需要上传一份数据块信息，datanode之间会互相进行复制。<br>

**hdfs比较明显的特点**

- 数据流和控制流分离，客户端和datanode之间交互是以数据流形式进行的，但是数据流没有经过namenode，减小了namenode的负担；
- 文件副本，通过冗余策略尽可能减少数据丢失可能性；
- 为了防止namenode单点故障，通常使用zookeeper等分布式锁服务实现多个namenode的HA.

---
### MapReduce

为了更好理解mapreduce过程，先从经典的word count实例看起

![](/img/hadoop/word-count.jpg)

- 先将文件中的单词划分为三部分，每部分交给一个map线程去处理，得到的结果是很多个map entry，键为单词，值为1；
- map entry经过shuffle操作，将相同的键放在一个桶中，交给reduce过程处理；
- reduce将相同的单词合并，并且统计次数进行输出。

下图较好的描述了上述过程

![](/img/hadoop/map-reduce-internal.jpg)


#### mapreduce架构

![](/img/hadoop/map-reduce-arch.jpg)

MapReduce包含四个组成部分，分别为Client、JobTracker、TaskTracker和Task:

**client**

- 将应用程序以及配置参数Configuration打包成JAR文件存储在HDFS中；
- 并把路径提交到 JobTracker 的 master 服务中
- 然后由 master 创建每一个 Task（即 MapTask 和 ReduceTask） 将它们分发到各个 TaskTracker 服务中去执行

**JobTracke** <br>
负责资源监控和作业调度。JobTracker监控所有TaskTracker与job的健康状况，一旦发现失败，就将相应的任务转移到其他节点；同时，JobTracker会跟踪任务的执行进度、资源使用量等信息，并将这些信息告诉任务调度器，而调度器会在资源出现空闲时，选择合适的任务使用这些资源。<br>

**TaskTracker**<br>
周期性地通过Heartbeat将本节点上资源的使用情况和任务的运行进度汇报给JobTracker，同时接收JobTracker发送过来的命令并执行相应的操作（如启动新任务、杀死任务等）。<br>

**Task**<br>
分为Map Task和Reduce Task两种，均由TaskTracker启动。MapReduce计算框架并没有直接调用CPU和内存等多维度资源，它把多维度资源抽象为"slot",slot可以分为map slot和reduce slot。从一定程度上，slot可以看做"任务运行并行度"。如果某个节点配置了5个map slot，那么这个节点最多运行5个Map Task；如果某个节点配置了3个reduce slot，那么该节点最多运行3个Reduce Task。<br>

mapreduce为解决分布式集群提供了很好的方案。但是mapreduce也存在如下的**不足**：

- JobTracker完成任务太多，容易造成很多资源浪费，也是框架的单点故障；
- 对资源的划分太过粗糙；
- 源代码层面功能实现较为混乱，维护和改善非常麻烦。

于是在hadoop2.x中推出了yarn新一代的分布式资源管理系统和MRv2。

---
### yarn

Yarn是一个分布式的资源管理系统,并不是分布式计算系统，但是可以在yarn上运行多种分布式计算系统例如MRv2、spark等，于是有人形象将yarn看成是分布式操作系统。<br>

#### yarn 架构

Yarn/MRv2最基本的想法是将原JobTracker主要的资源管理和job调度/监视功能分开作为两个单独的守护进程

![](/img/hadoop/yarn-arch.png)

ResourceManager(RM)和NodeManager(NM)组成了基本的数据计算框架,ResourceManager协调集群的资源利用;ApplicatonMaster是一个框架特殊的库，对于MapReduce框架而言有它自己的ApplicationMaster(AM)实现，用户也可以实现自己的AM;每个Application有一个AM，Application相当于map-reduce job或者DAG jobs。<br>

**ResourceManager**<br>
主要由两个组件构成，Scheduler和ApplicationsManager(AsM)。
	
- **Scheduler** 
    - 负责分配最少但满足application运行所需的资源量给Application
    - 周期性接受来自NM资源使用率的监控信息
    - applicationMaster可以从Scheduler得到属于它的已完成的container的状态信息。
- **ApplicationsManager**
    - 负责处理client提交的job
    - 协商第一个container以供applicationMaster运行
    - 并且监控AM的存活情况，在applicationMaster失败的时候会重新启动applicationMaster
    - client也可以从ASM获取到AM的状态信息。

**NodeManager**<br>
负责启动RM分配给AM的container以及代表AM的container，并且会监视container的运行情况，如果container占用资源过多，则会kill该container。<br>

**ApplicationMaster**<br>
是一个框架特殊的库，对于Map-Reduce计算模型而言有它自己的ApplicationMaster实现，对于其他的想要运行在yarn上的计算模型而言，必须得实现针对该计算模型的ApplicationMaster用以向RM申请资源运行task。

![](/img/hadoop/yarn-mr2-procedure.png)

上图展示了MRv2运行在yarn上的运行流程<br>

1. 用户向Yarn提交应用程序，其中包括用户程序、相关文件、启动ApplicationMaster命令、ApplicationMaster程序等;
2. ResourceManager为该应用程序分配第一个Container，并且与Container所在的NodeManager通信，并且要求该NodeManager在这个Container中启动应用程序对应的ApplicationMaster;
3. ApplicationMaster首先会向ResourceManager注册，这样用户才可以直接通过ResourceManager查看到应用程序的运行状态，然后它为准备为该应用程序的各个任务申请资源，并监控它们的运行状态直到运行结束，即重复后面4~7步骤;
4. ApplicationMaster采用轮询的方式通过RPC协议向ResourceManager申请和领取资源;
5. 一旦ApplicationMaster申请到资源后，便会与申请到的Container所对应的NodeManager进行通信，并且要求它在该Container中启动任务;
6. NodeManager为要启动的任务配置好运行环境，包括环境变量、JAR包、二进制程序等，并且将启动命令写在一个脚本里，通过该脚本运行任务;
7. 各个任务通过RPC协议向其对应的ApplicationMaster汇报自己的运行状态和进度，以让ApplicationMaster随时掌握各个任务的运行状态，从而可以再任务运行失败时重启任务;
8. 应用程序运行完毕后，其对应的ApplicationMaster会向ResourceManager通信，要求注销和关闭自己。


hadoop生态比较适合离线海量数据处理和分析，实时计算框架可以参考spark。

---
### 参考资料
- [Hadoop学习笔记：Hadoop及其生态系统简介](https://zhuanlan.zhihu.com/p/31515809)
- [hadoop知识点总结](http://blog.csdn.net/wuwenxiang91322/article/details/47324095)
- [NameNode 和 Secondary NameNode 的区别和作用](http://blog.csdn.net/remote_roamer/article/details/50675059)
- [初步掌握MapReduce的架构及原理](https://www.cnblogs.com/codeOfLife/p/5410423.html)
- [更快、更强——解析Hadoop新一代MapReduce框架Yarn](https://www.csdn.net/article/2014-02-10/2818355)
- [Hadoop Yarn详解](http://blog.csdn.net/suifeng3051/article/details/49486927)
- [Yarn大体框架和工作流程研究](http://blog.51cto.com/zengzhaozheng/1433986)