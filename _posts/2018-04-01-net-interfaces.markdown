---
layout:     post
title:      "常见虚拟网卡设备及CNI简介"
subtitle:   "常见虚拟网卡设备及CNI简介"
date:       2018-03-31 12:00:00
author:     "julyerr"
header-img: "img/linux/net/interfaces.png"
header-mask: 0.5
catalog: 	true
tags:
    - linux
---

### linux中常见（虚拟）网络设备

网络虚拟化有多种实现方式，可以依靠虚拟机实现，也可以在同一台主机上分离出多个TCP/IP协议栈实现;现在流行的容器技术，独立的网络虚拟化同时还利用了linux提供的net namespace技术。<br>

- **loopback**<br>
	本地回环设备，主要是同一主机上应用进行通信，不需要经过外网。

- **TUN**<br>
	普通的网卡通过网线收发数据包，但是TUN设备通过一个文件收发数据包。所有对这个文件的写操作会通过 TUN 设备转换成一个数据包送给内核；当内核发送一个包给 TUN 设备时，通过读这个文件可以拿到包的内容。
		
![](/img/linux/net/tun.png)	

- **TAP**<br>
	TAP设备与 TUN 设备工作方式完全相同，区别在于： 
    - TUN 设备的 /dev/tunX 文件收发的是 IP 层数据包，只能工作在 IP 层，无法与物理网卡做 bridge，但是可以通过三层交换（如 ip_forward）与物理网卡连通;
    - TAP 设备的 /dev/tapX 文件收发的是 MAC 层数据包，拥有 MAC 层功能，可以与物理网卡做 bridge，支持 MAC 层广播.

- **veth**<br>
	每创建一个veth会出现一对veth设备如veth0和veth1,这两个veth设备是物理相通的,可以理解为一根网线的两端相连,因此可以使用namespace将一个veth放入某一个网络环境,那么两个veth所在的两个环境就可以互通了。

![](/img/linux/net/veth.png)	

- **bridge**<br>
	Linux中的网桥是一种虚拟设备，需要将一个或者多个真实的网卡设备绑定到网桥设备上工作。可以为网桥配置一个IP地址，而它的MAC地址则是它管理的所有从设备中最小的那个MAC地址。绑定在网桥上的从设备不再需要IP地址及MAC，且他们被设置为可以接受任何数据包（设置网卡为混杂模式），然后统一交给网桥设备来决定数据包的去向：接受、转发、丢弃。 

![](/img/linux/net/bridge.jpg)	
	
**网桥和交换机的区别**
|比较项|网桥|交换机|
|--|
|交换的形式      |   软件          |          硬件(使用ASIC) (注1)
|数据帧转发方式   |  存储转发               | 存储转发、直接转发 (注2)
|端口数量    |       较少2~16          |      端口密集度较大，很可能几百个
|双工模式    |       半双工           |       半双工和全双工
|广播域       |      1个            |         每VLAN 1个

- **macvlan**<br>
	macvlan 允许在主机的一个网络接口上配置多个虚拟的网络接口，这些网络 interface 有自己独立的 mac 地址，也可以配置上 ip 地址进行通信。macvlan 下的虚拟机或者容器网络和主机在同一个网段中，共享同一个广播域。
	macvlan具体有四种工作模式，详细可以google一下。

![](/img/linux/net/macvlan.png)	

- **ipvlan**<br>
	IPVlan 和 macvlan类似，都是从一个主机接口虚拟出多个虚拟网络接口。一个重要的区别就是所有的虚拟接口都有相同的 macv 地址，而拥有不同的 ip 地址。两种工作模式：
	- **L2** ipvlan L2 模式和 macvlan bridge 模式工作原理很相似，父接口作为交换机来转发子接口的数据。同一个网络的子接口可以通过父接口来转发数据，而如果想发送到其他网络，报文则会通过父接口的路由转发出去。
	- **L3** ipvlan在各个虚拟网络和主机网络之间进行不同网络报文的路由转发工作,如下所示。
		
![](/img/linux/net/linux-ipvlan-l3-mode.png)	


---
### CNI(Container Network Interface)
目的是提供容器管理平台（docker、k8s、mesos等）和容器网络解决方案(flannel、calico、weave等）的标准

![](/img/k8s/cni/Chart_Container-Network-Interface-Drivers.png)	

一旦有新的网络方案出现，只要它能满足这个标准的协议，那么它就能为同样满足该协议的所有容器平台提供网络功能.<br>

#### CNI工作原理
CNI的工作主要是从容器管理系统处获取运行时信息，包括network namespace的路径，容器ID以及network interface name，再从容器网络的配置文件中加载网络配置信息，再将这些信息传递（环境变量和标准输入两种方式）给对应的插件，由插件进行具体的网络配置工作，并将配置的结果再返回到容器管理系统中。<br>

以下常见的配置信息通过**环境变量**进行传递：

- CNI_COMMAND：要执行的操作，可以是ADD（把容器加入到某个网络）、DEL（把容器从某个网络中删除）
- CNI_CONTAINERID：容器的 ID，比如 ipam 会把容器 ID 和分配的IP地址保存下来。可选的参数，但是推荐传递过去。需要保证在管理平台上是唯一的，如果容器被删除后可以循环使用
- CNI_NETNS：容器的 network namespace 文件，访问这个文件可以在容器的网络 namespace 中操作
- CNI_IFNAME：要配置的 interface 名字，比如 eth0
- CNI_ARGS：额外的参数，是由分号;分割的键值对，比如 “FOO=BAR;hello=world”
- CNI_PATH：CNI 二进制查找的路径列表，多个路径用分隔符 : 分隔

网络信息主要通过**标准输入**，作为 JSON 字符串传递给插件，必须的参数如下：

- cniVersion：CNI 标准的版本号。因为 CNI 在演化过程中，不同的版本有不同的要求
- name：网络的名字，在集群中应该保持唯一
- type：网络插件的类型，也就是 CNI 可执行文件的名称
- args：额外的信息，类型为字典
- ipMasq：是否在主机上为该网络配置 IP masquerade
- ipam：IP 分配相关的信息，类型为字典
- dns：DNS 相关的信息，类型为字典

插件接到这些数据，从输入和环境变量解析到需要的信息，根据这些信息执行程序逻辑，然后把结果返回给调用者，返回的结果中一般包括这些参数：

- IPs assigned to the interface：网络接口被分配的 ip，可以是 IPv4、IPv6 或者都有
- DNS 信息：包含 nameservers、domain、search domains 和其他选项的字典

#### CNI插件
官方提供的插件目前分成三类：main、meta 和 ipam。main是主要的实现了某种特定网络功能的插件；meta本身并不会提供具体的网络功能，它会调用其他插件，或者单纯是为了测试；ipam 是分配 IP 地址的插件。插件功能说明如下
	
- main:
    - loopback：这个插件很简单，负责生成 lo 网卡，并配置上 127.0.0.1/8 地址
    - bridge：和 docker 默认的网络模型很像，把所有的容器连接到虚拟交换机上
    - macvlan：使用 macvlan 技术，从某个物理网卡虚拟出多个虚拟网卡，它们有独立的 ip 和 mac 地址
    - ipvlan：和 macvlan 类似，区别是虚拟网卡有着相同的 mac 地址
    - ptp：通过 veth pair 在容器和主机之间建立通道
- meta:
    - flannel：结合 bridge 插件使用，根据 flannel 分配的网段信息，调用 bridge 插件，保证多主机情况下容器
- ipam:
    - host-local：基于本地文件的 ip 分配和管理，把分配的 IP 地址保存在文件中
    - dhcp：从已经运行的 DHCP 服务器中获取 ip 地址
		

---
### 参考资料
- [网桥(bridge) 和 交换机(switch) 之异同  ](http://keendawn.blog.163.com/blog/static/88880743201151042319573/)
- [Linux协议栈--网桥设备的实现](http://cxd2014.github.io/2016/11/08/linux-bridge/)
- [常见的虚拟网卡技术](http://hurdonkey.leanote.com/post/%E5%B8%B8%E7%94%A8%E7%9A%84%E8%99%9A%E6%8B%9F%E7%BD%91%E7%BB%9C%E6%8A%80%E6%9C%AF)
- [linux 网络虚拟化： macvlan](http://cizixs.com/2017/02/14/network-virtualization-macvlan)
- [linux 网络虚拟化： ipvlan](http://cizixs.com/2017/02/17/network-virtualization-ipvlan)
- [理解Kubernetes网络之Flannel网络](https://tonybai.com/2017/01/17/understanding-flannel-network-for-kubernetes/)