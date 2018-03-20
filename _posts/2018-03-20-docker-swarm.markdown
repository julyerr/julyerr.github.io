---
layout:     post
title:      "docker swarm运行原理和常见使用总结"
subtitle:   "docker swarm运行原理和常见使用总结"
date:       2018-03-20 6:00:00
author:     "julyerr"
header-img: "img/docker/swarm/swarm.png"
header-mask: 0.5
catalog: 	true
tags:
    - docker
---

>前面几篇文章总结了常见docker单机版的使用，幸好docker公司提供了强大的docker集群管理工具--docker swarm用以解决docker多主机。虽然Google提出了k8s的容器调度方案，但是docker原生的docker swarm和docker兼容和稳定性还是很不错的，先了解docker swarm后面再学习kubernetes哈。<br>

**docker swarm 请求处理流程**

![](/img/docker/swarm/docker-swarm-workflow.png)

Swarm Node表示加入Swarm集群中的一个Docker Engine实例，具体划分为Manager Node和Worker Node两类

- **Manager Node** 负责调度Task,编排容器和集群管理功能。
- **Worker Node** 接收由Manager Node调度并指派的Task，启动Docker容器来运行指定的服务；同时向Manager Node汇报Task的执行状态。

#### 服务发现

每一个docker容器都有一个域名解析器，用来把域名查询请求转发到docker engine；docker engine内部dns的服务器收到请求后就会在发出请求的容器所在的所有网络中检查域名对应的是不是一个容器或者是服务，如果是，docker引擎就会从存储的key-value建值对中查找这个容器名、任务名、或者服务名对应的IP地址，并把这个IP地址或者是服务的虚拟IP地址返回给发起请求的域名解析器。如果目的容器或服务和源容器不在同一个网络里面，Docker引擎会把这个DNS查询转发到配置的默认DNS服务 .

![](/img/docker/swarm/docker-dns.png)

上图展示了task1.client请求两个不同资源dns返回的不同结果。

#### 负载均衡

**内部负载均衡**<br>

当在docker swarm集群模式下创建一个服务时，会自动在服务所属的网络上给服务额外的分配一个虚拟IP，当解析服务名字时就会返回这个虚拟IP。对虚拟IP的请求会通过overlay网络自动负载到这个服务所有的健康任务上。

![](/img/docker/swarm/lb-service-vip.jpg)

如果在创建服务的时候通过--endpoint-mode=dnsrr，则服务不会创建vip，service的DNS entry对应一组具体服务IP，通过round-robin轮询各个IP来达到LB的效果。

![](/img/docker/swarm/lb-service-dnsrr.jpg)

**外部负载均衡**

创建服务时，利用--publish选项把一个服务暴露到外部，此时集群中所有的节点都会监听这个端口。当访问一个监听了端口但是并没有对应服务运行在其上的节点时，使用预先定义过的Ingress overlay网络，把请求转发给服务对应的虚拟IP。

![](/img/docker/swarm/lb-external.png)

多种负载均衡混合使用需要注意非dnsrr的internal LB和ingress LB可以同时使用，但配置dnsrr时，不能使用ingress LB，即不能published port。 

---
### docker swarm中网络模型简析

docker在早前的时候没有考虑跨主机的容器通信，要实现跨主机的通信，通常使用第三方工具如flannel、weave和pipework等来搭建overlay网络。在docker1.9中，自带的overlay网络被添加进来。<br>

使用overlay网络需要满足以下几种条件

- key-value 存储服务，比如 consul、etcd、zookeeper等；
- 可以访问到 key-value 服务的主机集群；集群中每台机器都安装并运行 docker daemon；
- 集群中每台机器的 hostname 都是唯一的，因为 key-value 服务是通过 hostname 标识每台主机的。

![](/img/docker/swarm/swarm-arch.jpeg)

创建一个服务，通常会在所有的node上建立overlay网络、ingress网络。ingress网络主要用来实现外部的负载均衡

![](/img/docker/swarm/overlay.jpg)

容器连接到docker_gwbridge 虚拟网桥，该网卡主要负责容器和外部的通信工作。<br>

overlay才是跨主机容器通信的关键，首先docker会为每个overlay 网络创建一个独立的 networknamespace，其中有一个linux虚拟网桥br0，endpoint使用veth pair实现，一端连接到容器中（即 eth0），另一端连接到 namespace 的 br0 上。br0 除了连接所有的 endpoint，还会连接一个 vxlan 设备，用于与其他 host 建立 vxlan tunnel，容器之间的数据就是通过这个 tunnel 通信的。vxlan是`mac in udp`技术的实现，具体可以[参考](http://blog.sina.com.cn/s/blog_e01321880101i7lw.html).<br>

---

### 常见使用（CMD)

#### swarm 集群的构建

**设置master节点**

```shell
docker swarm init --advertise-addr <MANAGER-IP>
```

**增加worker节点到集群**

```shell
docker swarm join --token token-id <MANAGET-IP>
```

如果需要增加新的Manager到节点，然后有后面的提示信息

```shell
docker swarm join-token <MANAGER-IP> 	
```

多个master之间可以实现HA

![](/img/docker/swarm/swarm-multiple-manager-architecture.png)

Swarm使用了Raft协议来保证多个Manager之间状态的一致性。假设Swarm集群中有个N个Manager Node，那么整个集群可以容忍最多有(N-1)/2个节点失效。

#### node 状态管理

**查看node信息**

```shell
docker node ls
```

Node的AVAILABILITY有三种状态：Active、Pause、Drain，前两者比较容易理解，后面的Drain表示某个Manager只具有管理功能，但是不运行Task。

```shell
docker node update --availability drain MANAGER_NODE
```

**Node提权/降权**

```shell
# 将Worker Node装换成Manager Node
docker node promote work_node
# 将Manager Node转换成Worker Node
docker node demote manager_node
```

**退出swarm集群**

```shell
# worker node或者没有其他的worker node存在的Manager node退出集群
docker swarm node node_name 
# 如果还存在其他worker node的Manager node退出集群，加上参数
docker swarm node node_name leave --force
```

#### 服务管理

![](/img/docker/swarm/services-diagram.png)

上图非常形象的展现了service、task和container三者之间的关系,service 是对外的提供的服务，服务内部支持负载均衡（可以根据不同的策略）.

```shell
docker service create --name  service-name image-name cmd 
# 使用--replicas 指定启动多少容器运行指定命令
```

**服务扩容和缩容**<br>

运行的服务有两种模式，默认的replicated表示可以运行指定数量的服务，global则是在每个node上运行Task。可以通过scale参数对Task的数量进行调整

```shell
docker service scale service-id=service-number
```

**服务更新**

```
docker service update [Options] service-name
# --update-delay 指定服务更新的延迟时间，每成功部署一个服务延迟一定时间然后进行下一次更新
```

**删除服务**

```shell
docker service rm service-id
```

---
### 参考资料
- [深入浅出Swarm](http://blog.daocloud.io/swarm_analysis_part1/)
- [Docker Swarm架构、特性与基本实践](http://shiyanjun.cn/archives/1625.html)
- [docker swarm-服务发现与负载均衡原理分析](http://fengyilin.iteye.com/blog/2400949)
- [docker swarm mode的服务发现和LB详解](https://zhuanlan.zhihu.com/p/25954203)
- [docker 跨主机网络：overlay 简介](http://cizixs.com/2016/06/13/docker-overlay-network)
- [【学习Docker】 之 网络通信篇](http://wongbingming.me/2018/1/28/Docker-Network.html)