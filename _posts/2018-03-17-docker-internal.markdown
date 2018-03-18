---
layout:     post
title:      "docker架构和实现原理简析"
subtitle:   "docker架构和实现原理简析"
date:       2018-03-17 6:00:00
author:     "julyerr"
header-img: "img/docker/docker.png"
header-mask: 0.5
catalog: 	true
tags:
    - docker
---

>正式接触docker已经有段时间了，上半年忙于整理java核心方面的知识，现在可以好好看看docker这个云计算界的宠儿。<br>

### docker与常见组件交互

![](/img/docker/docker-process.png)

- docker是一个可执行文件，通过参数决定运行的是docker client还是docker server
- docker server提供容器服务，包括镜像管理、容器隔离等后台的工作
- docker client（docker命令） 用来和docker server打交道，例如创建一个新的容器等
- docker machine 是为了在多平台（mac,windows)上方便管理docker server的工具，例如管理一个运行在众多服务器上的docker server集群。

下面我们分别看看各个不同组件的具体组成部分

#### docker server

先了解docker server的运行机制后，docker client提供的功能理解起来更简单一点。

![](/img/docker/docker-server-arch.jpeg)

docker server由不同的模块组成，各个模块各司其职（非常好的软件编码和管理风格，因此golang开发人员好好看看docker源码对自己提升很大）。<br>

**路由分发**

![](/img/docker/service-dispatcher.jpeg)

docker client的请求首先通过路由(gorilla/mux实现)分发到不同的handler，服务器开启一个go routine处理该请求，并且将该响应返回给用户。

**Docker Engine**

![](/img/docker/engine-job.jpeg)

Engine是docker的执行引擎，而job(类似linux下的进程)则是engine内部的基本执行单元，实现上而言，前端的路由分发也是一个job.<br>

**docker registry**是众多docker image的存储场所，可以方便的拉取他人制作的镜像或者上传镜像.<br>

**graph**
![](/img/docker/graph.jpeg)

- registry保存的不同类别的镜像，比如ubuntu和apline;repository保存同种类型的不同版本镜像，例如ubuntu:14.04.ubuntu:17.04等。
- 镜像是以层次的方式存储的，最上层是读写层，下面层次均为只读层。这样做主要可以让镜像底层实现共享，大大减少多个镜像出现重复存储的空间浪费，具体原理还会在下面介绍。
- GraphDB是一个构建在SQLite之上的小型图数据库，用来提高查询效率

**graphdriver**主要用来存储与获取容器镜像

![](/img/docker/graph-driver.jpeg)

**networkdriver**用来配置容器的网络环境

![](/img/docker/network-driver.jpeg)

**executordrice**为容器内部进程的运行提供支持

![](/img/docker/executor-driver.jpeg)

**libcontainer**是一个函数库，方便上层对namespace、cgroups、apparmor、网络设备以及防火墙规则等进行操作

![](/img/docker/libcontainer.jpeg)

有了上述技术的支持，可以形式上交付给用户一个完整容器环境。

![](/img/docker/container.jpeg)

---
### docker使用的核心技术

命名空间 (namespaces)是Linux提供的用于分离进程树、网络接口、挂载点以及进程间通信等资源的方法，具体提供了如下七种命名空间：`CLONE_NEWIPC`、`CLONE_NEWNET`、`CLONE_NEWNS`、`CLONE_NEWPID`、`CLONE_NEWUSER`、`CLONE_NEWUTS`和`CLONE_NEWCGROUP`。通过为进程设置不同的命名空间，可以将对应的资源和宿主机器进行隔离。<br>

- **IPC namespace**<br>
隔离进程间的通信资源，不同 namespace 进程不能互相通信

- **NET namespace**<br>
隔离的是和网络相关的资源，包括网络设备、路由表、防火墙(iptables)、socket（ss、netstat）、 /proc/net 目录、/sys/class/net 目录、网络端口(network interfaces)等.一个物理网络设备只能出现在最多一个网络 namespace 中，不同网络 namespace 之间可以通过创建 veth pair 提供类似管道的通信。

- **Mount namespace**
隔离的是 mount points（挂载点），也就是说不同namespace下面的进程看到的文件系统结构是不同的.

- **PID namespace**
隔离的是进程的 pid 属性，也就是说不同的namespace中的进程可以有相同的 pid。	

![](/img/docker/pid.png)

- **User namespace**
隔离的是用户和组信息，在不同的namespace中用户可以有相同的UID和GID，它们之间互相不影响。

- **UTS namespace**
隔离进程所在的hostname 和 NIS domain name。

- **CGroup namespace**
和上面命名空间有点不同之处，主要是用来限制、控制与分离一个进程组群的资源（如CPU、内存、磁盘输入输出等）。具体[参见](https://coolshell.cn/articles/17049.html)

linux内核提供的功能一般都会以系统调用的方式供上层应用程序使用，和上述namespace**相关的系统调用**主要有以下三个：

- **clone** 创建新进程并设置它的namespace

```c
int clone(int (*fn)(void *), void *child_stack,
         int flags, void *arg, ...
         /* pid_t *ptid, struct user_desc *tls, pid_t *ctid */ );
```

其中flag配置子进程启动的信息，如命名空间等

- **setns** 让进程加入已经存在 namespace

```c
int setns(int fd, int nstype);
```

- **unshare** 让进程加入新的 namespace,并且脱离原有的命名空间

```c
int unshare(int flags);
```

---
### 部分驱动

#### 网络驱动

docker提供了以下四种不同的网络模式：

- **Bridge模式**

![](/img/docker/bridge.png)	
	主机网卡eth0加入docker0网桥，同一网桥内容器可以通信，也可以通过nat将容器中的端口映射到主机端口，向外提供服务。

- **Host模式**

![](/img/docker/host.png)	
	容器共享主机网络设备以及协议栈等资源

- **Container模式**

![](/img/docker/container.png)	
	新建立的容器使用已有容器的网络设备以及协议栈等资源

- **None模式**
	容器不配置任何网络环境，只能使用loopback网络设备

### 存储驱动
	
**docker镜像组成**

![](/img/docker/image-layer.png)	
	每一个镜像层都是建立在另一个镜像层之上的，同时所有的镜像层都是只读的，只有每个容器最顶层的容器层才可以被用户直接读写。所有的容器都建立在一些底层服务（Kernel）上，包括命名空间、控制组、rootfs等等，这种容器的组装方式提供了非常大的灵活性，只读的镜像层通过共享也能够减少磁盘的占用。<br>

**驱动种类**<br>
Docker支持了不同的存储驱动，如aufs、devicemapper、overlay2、zfs 和 vfs 等，在最新的 Docker 中，overlay2 取代了 aufs成为了推荐的存储驱动，但是在没有 overlay2 驱动的机器上仍然会使用 aufs 作为 Docker 的默认驱动。<br>


本文由于篇幅问题，将docker常见命令使用总结移至下篇文章。


---
### 参考资料
- 《docker源码解析》
- [Docker 架构](http://www.runoob.com/docker/docker-architecture.html)
- [Docker 核心技术与实现原理](https://draveness.me/docker)
- [Docker源码分析（一）之整体架构图](http://blog.csdn.net/huwh_/article/details/71308236)
- [docker 容器基础技术：linux namespace 简介](http://cizixs.com/2017/08/29/linux-namespace)
- [docker中容器的四种网络模式详解](http://blog.csdn.net/parameter_/article/details/77131815)