---
layout:     post
title:      "docker常见命令以及docker machine介绍"
subtitle:   "docker常见命令以及docker machine介绍"
date:       2018-03-19 6:00:00
author:     "julyerr"
header-img: "img/docker/docker.png"
header-mask: 0.5
catalog: 	true
tags:
    - docker
---

>有了上篇文章关于docker内部运行机制的基础，这篇文章来看看docker常见命令以及docker machine的使用。<br>

### docker常见命令

**docker server信息**

```shell
# 查看docker版本
docker version
# 显示docker系统的信息
docker info
# 日志信息
docker logs
```

#### 容器相关操作

**运行一个docker**

```shell
docker run [options] imageId
```

常见参数如下

- --name 设置容器的名称
- -h 设置hostname
- -e 表示为容器设置对应的环境变量
- -i 是否开启交互模式，通常和-t结合使用
- -t 是否为容器分配伪命令行终端
- -d 和-it不能同时使用，表示容器运行在后台，不分配命令行终端
- --link 用于连接两个容器，例如`--link=mysql_server:db`,其中的容器可以使用db别名访问到mysql_server
- --rm=false 容器退出之后，是否自动删除容器
- --restart=`no|always` 容器退出之后，是否重启该容器
- -net=bridge 设置容器的网络运行模式（docker内置四种网络模式bridge、host、container、none）
- -v 设置容器的挂载卷的位置,具体参见后文使用
- -p 将容器端口映射到主机端口,hostPort:containerPort
- -m 限制容器使用的内存大小
- --cpuset-cpus 限制docker只能在指定的cpu上运行（从0开始编号）
- --privileged 设置是否允许容器运行在特权模式下（特权模式下的容器能够查看部分主机的文件，会对宿主机安全产生影响）


**查看容器的状态信息**

```shell
# 默认只输出正在运行的容器
docker ps [options] 
# 输出所有容器（包括已经退出的容器）
docker ps -a
# -q 只输出docker id
docker ps -q

# 查看容器详细信息
docker inspect id
# 得到docker服务器的实时的事件
docker events 
# 查看容器的日志输出
docker logs -f dockerId 
# 显示容器的端口映射
docker port
# 显示容器的进程信息
docker top 
#显示容器文件系统的前后变化
docker diff 
```

**和容器交互**

```shell
# 交互的方式进入容器命令行界面,命令行退出不会导致整个容器退出
docker exec -it dockerId 
# 可以交互的方式进入容器，但是命令行退出之后整个容器就会退出
docker attach dockerId
```

**其他常见的容器生命周期操作**

```shell
# 创建一个容器但是不启动
docker create 
# 启动|停止|重启 某个容器
docker start|stop|restart [id] 
# 暂停|恢复 某一容器
docker pause|unpause [id]
# 杀死一个或多个指定容器
docker kill -s KILL [id]
# 杀掉全部运行的容器
docker kill -s KILL `docker ps -q`
# 删除一个容器
docker rm [容器id]
```


**镜像管理操作**

```shell
# 登入到镜像仓库
docker login
# 列出本地所有镜像
docker images
# 搜索镜像
docker search name
# 拉取镜像
docker pull name:tag
# 为镜像做标记
docker tag image name:tag
# 上传镜像
docker push imageId
# 本地移除一个或多个指定的镜像
docker rmi
# 移除本地全部镜像
docker rmi `docker images -a -q`
# 将镜像 ubuntu:14.04 保存为 ubuntu14.04.tar 文件
docker save -o ubuntu14.04.tar ubuntu:14.04
# 上面命令的意思是将 ubuntu14.04.tar 文件载入镜像中
docker load -i ubuntu14.04.tar
# 根据dockerfile构建镜像，具体参见下面介绍
docker build -t <镜像名> <Dockerfile路径>
```

**挂载卷操作**<br>

由于容器退出之后，所使用的数据信息也会被删除，如果需要保留的话，可以通过volume挂载的方式（容器退出，但是volume还是会保存）。有两种volume挂载方式

- `-v [host-dir:]container-dir:[rw|wo]` 将主机上的文件挂载到容器中，如果指定的文件在容器中存在则会覆盖容器中的文件，后面可以添加属性,限制容器对文件是可读可写还是可读写。如果没有指定host-dir，则会自动创建一个文件夹挂载到容器中。可以通过docker inspect dockerId获取到文件挂载信息。


- --volume-from dockerId 共享其他容器的volume

```shell
# 指定名称创建一个volume
docker volume create
# 查看volume的详细信息	
docker volume inspect
# 列举所有volume
docker volume ls
# 删除所有未使用的volume
docker volume prune
# 删除指定的volume
docker volume rm
```

docker支持很多命令，一般使用的时候，只需要记住常见的命令即可，类似linux下的man，遇到不是很常见的功能，可以查看命令解释说明。

---
### dockerfile中常见指令总结 

dockerfile用于快速有序且直观地完成对镜像的定制，相对于dockercommit一个镜像，可以清晰明白该容器镜像的构建过程，便于分享和自定义修改镜像等。<br>

- **FROM** 说明需要构建的镜像依赖的基础镜像，如果不依赖任何基础镜像，`FROM scatch`表示将可执行文件复制进镜像
- **RUN** 用来执行命令，每一条RUN指令就会新增一层image（最大不超过127层）.有两种格式`shell:RUN<命令>`或者使用`exec：RUN ["可执行文件","参数1","参数2"]`。使用shell格式，后面连接的命令默认作为sh -c 参数，新建的进程作为shell的子进程，推荐使用CMD格式。<br>
- 
可以将多个命令串联写在一行，如下：

```shell
RUN buildDeps='gcc libc6-dev make' \
    && apt-get update \
    && apt-get install -y $buildDeps \
    && wget -O redis.tar.gz "http://download.redis.io/releases/redis-3.2.5.tar.gz" \
    && mkdir -p /usr/src/redis \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    && rm -rf /var/lib/apt/lists/* \
    && rm redis.tar.gz \
    && rm -r /usr/src/redis \
    && apt-get purge -y --auto-remove $buildDeps
```

- **MAINTAINER** 指定作者
- **LABEL** 为镜像添加标签，`LABEL <key>=<value> <key>=<value> ...`
- **COPY** 将宿主机文件拷贝至镜像内的指定路径,需要注意的是copy之后的文件权限和原始权限相同。
- **ADD** 资源添加到镜像中，如果源文件是压缩包或者超链接，构建过程会尝试解压或者从链接下载内容然后复制到容器内部。通常推荐使用COPY，ADD可能存在不安全因素。
- **WORKDIR** 容器的运行目录（工作目录）
- **ENV** 设置容器的环境变量，然后启动镜像的时候可以通过参数-e传入
- **ARG** 功能和ENV类似，只是ARG表示构建镜像的时候指定的参数，可以通过--build-arg进行覆盖
- **USER** 指定用户（用户需要存在），如果需要改变用户身份，可以使用工具gosu

```shell
# 建立 redis 用户，并使用 gosu 换另一个用户执行命令
RUN groupadd -r redis && useradd -r -g redis redis
# 下载 gosu
RUN wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64" \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
# 设置 CMD，并以另外的用户执行
CMD [ "exec", "gosu", "redis", "redis-server" ]
```

- **VOLUME** "路径名",指定容器启动时，将自动创建文件并挂载到容器的文件路径，也可以通过-v指定
- **暴露端口** `EXPOSE <端口1> [<端口2>...]`,指定容器内部暴露的端口，启动时通过-P自动端口映射或者`-p host-port:container-port`指定映射到主机的某个端口（不能发生冲突）

**启动配置**<br>

类似上面的RUN也有shell和CMD两种方式，推荐使用后者，因为启动shell进程之后，后序docker服务后台发送的一些信号传递给了shell,本身执行的进程接受不到信号；而且还会忽略cmd和run传入的参数。

```shell
CMD 
	CMD ["executable","param1","param2"]
ENTRYPOINT
	ENTRYPOINT [“executable”, “param1”, “param2”]
```

两者的区别

- CMD可以被docker run的参数覆盖，例如docker -it ubuntu bash ,则原来的CMD无效；指定的ENTRYPOINT默认不会被覆盖，需要覆盖时使用--entrypoint.
- CMD和传入的参数可以作为ENTRYPOINT参数，例如：
	
```shell
ENTRYPOINT ["/bin/echo"]
CMD ["this is a echo test"] # 如果docker run期间如果没有参数的传递，会默认CMD指定的参数
docker run -it new_image "this is a test"
```

- **ONBUILD** ONBUILD [instruction],使用该dockerfile生成的镜像A，并不执行ONBUILD中命令，如再来个dockerfile基础镜像为镜像A时，生成的镜像B时就会执行ONBUILD中的命令

---
### docker machine

docker machine是用来管理安装或者已经安装好了docker engine的主机。

![](/img/docker/docker-machine.png)

#### docker machine常见命令

**创建一个host**

```shell
# 指定使用的驱动如virtualbox
docker-machine create --driver virtualbox dev
# 添加已经安装好docker server的主机
docker-machine create --url=tcp://50.134.234.20:2376 custombo
```

**其他常见命令**

```shell
//移除虚拟机
docker-machine rm [OPTIONS] [arg...]
//登录虚拟机
docker-machine ssh [arg...]
//docker客户端配置环境变量
docker-machine env [OPTIONS] [arg...]
	//为方便本地操作，通过环境变量覆盖
	eval $(docker-machine env node-1)
//检查机子信息
docker-machine inspect
//查看虚拟机列表
docker-machine ls [OPTIONS] [arg...]
//查看虚拟机状态
docker-machine status [arg...]  //一个虚拟机名称
//启动虚拟机
docker-machine start [arg...]  //一个或多个虚拟机名称
//停止虚拟机
docker-machine stop [arg...]  //一个或多个虚拟机名称
//重启虚拟机
docker-machine restart [arg...]  //一个或多个虚拟机名称
//获取machine 的ip
docker-machine ip
//激活指定的machine
docker-machine active machine-name
```

docker-compose 作为容器的编排工具，用于在Docker上定义并运行复杂应用的工具，以后也会添加文章进行总结，可以参考[这篇文章](https://www.hi-linux.com/posts/12554.html).

---
### 参考资料
- [Docker 常用命令与操作](https://www.jianshu.com/p/adaa34795e64)
- [初次学习 Docker Volume 的基本使用 (四)](https://segmentfault.com/a/1190000011209501)
- [Dockerfile-常用指令总结](https://www.jianshu.com/p/2a90fc6ee383?utm_campaign=maleskine&utm_content=note&utm_medium=seo_notes&utm_source=recommendation)
- [Dockerfile 的 ENTRYPOINT 与 CMD](https://beginor.github.io/2017/10/21/dockerfile-cmd-and-entripoint.html)
- [Dockerfile使用总结](https://www.jianshu.com/p/275db10a6f22)
- [docker-machine常用命令](http://blog.csdn.net/cnleocc/article/details/56513004)
- [【翻译】Docker Machine用户指南](http://liuhong1happy.lofter.com/post/1cdb27c8_60292ee)