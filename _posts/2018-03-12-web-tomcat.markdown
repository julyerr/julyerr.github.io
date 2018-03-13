---
layout:     post
title:      "Tomcat 总结一"
subtitle:   "Tomcat 总结一"
date:       2018-03-11 8:00:00
author:     "julyerr"
header-img: "img/web/tomcat/tomcat.png"
header-mask: 0.5
catalog:    true
tags:
    - web
    - tomcat
---

>tomcat是java web开发中比较常用的servlet容器，本文将对tomcat各个组件、整体架构、启动流程以及常见的配置优化等进行简单介绍(笔者也是初学者，文章很多内容参考后文给出的链接)。

### 各个组件及整体架构

![](/img/web/tomcat/tomcat-arch.png)

**Server**<br>

Server接口负责管理Tomcat中的Service集合。通过Server接口，tomcat实现管理和运行service，对外部暴露应用。<br>

**Service**<br>

Service是一个接口，负责管理Connector和Container。其标准实现类StandardService由Connector和Container组成。Service接口同时也继承了LifeCycle接口，方便对tomcat中各个组件的整体生命周期进行管理。<br>

**Connector**<br>

connector主要用于监听各种协议的发送的请求，并创建出请求响应的Request和Response对象。随后创建一个处理该请求的线程，传入request和response对象，并提交到container中，等待container执行。

![](/img/web/tomcat/connector-workflow.png)

Container是所有容器的父接口，具有四个子容器Engine、Host、Context、Wrapper，它们也是父子继承关系。

![](/img/web/tomcat/tomcat-arch-detail.png)

**Engine**<br>

是Service的请求处理器，负责处理和分发Connector接收的所有请求，是最上层的Container。包含一或多个Host<br>

**Host**<br>

代表一个虚拟主机，例如Engine会把请求传递给HTTP请求头的host对应的Host容器。包含一或多个Context。<br>

**Context**<br>

代表一个web应用，维护了servlet和url的对应关系，Host会根据请求URI的路径把请求传递给相应的Context容器，Context会继续把请求传递给Wrapper(Servlet)。Wrapper是对Servlet原生对象的包装，Wrapper便于对LifeCycle生命周期进行管理<br>

**LifeCycle接口**<br>

tomcat几乎所有的组件都实现了该接口，在tomcat的启动和关闭过程中，可以直接通过责任链设计模式Lifecycle接口实现对所有对象的生命周期管理，同时每个对象可以在各个子接口中实现自己的功能。（具体参见后文的启动流程分析）


---
### 启动流程

![](/img/web/tomcat/tomcat_sequence.jpg)

上图是[原作者](http://www.fanyilun.me/2016/10/10/Tomcat%E7%9A%84%E5%90%AF%E5%8A%A8%E5%88%86%E6%9E%90/)手绘的一张图，非常详细的介绍了tomcat整个启动流程中执行的关键过程（对于初学者而言，不必深究每个具体步骤，只需要知道整体的流程，随着学习的深入再慢慢了解哈）。<br>

在执行启动脚本catalina.sh之后，会主要执行`org.apache.catalina.startup.Bootstrap`对象的三个方法

#### bootstrap.init()

主要功能是初始化tomcat的classLoader-Common类加载器，然后加载${catalina.base}/lib和 ${catalina.home}/lib目录下后续流程将会使用的相关类。

![](/img/web/tomcat/tomcat_classloader.jpg)

#### bootstrap.load()

- 先解析了conf/server.xml文件，找到用户配置tomcat的各种组件和层级关系，然后创建Server、Service、Engine、Host及Connector对象
- 然后通过调用catalina.init()，依次执行了server.init()、service.init()、engine.init()和container.init();每个container在init()方法中都会创建自己startStopExecutor，用于在start/stop时控制子container的启动或终止。其中比较重要的是，Connector如果检测到用户配置了线程池（默认不启用），则会创建好线程池。

#### bootstrap.start()

- 同样通过调用catalina.start()会因此调用各个子container的start方法
- host容器start方法会触发web应用的部署
	- 解析context.xml文件 配置该web应用全局的参数等
	- 创建WebAppClassLoader,每个web应用都有自己的类加载器WebAppClassLoade，其父加载器为Common ClassLoader;为了各个应用服务使用类不发生冲突，WebAppClassLoader的类加载规则默认不直接委托（delegate=false），而是在保障Java核心类(boostrap)的基础上优先加载项目路径提供的类，其加载类的顺序（如下列表，自上而下查找，找到类即返回）
        - 缓存
		- BootstrapLoader
		- `/WEB-INF/classes`
		- `/WEB-INF/lib/*.jar`
		- 委托至父类加载器（Bootstrap–>Extension–>System–>Common）
	- 解析web.xml 读取各种部署描述符文件，合并并应用到容器中，主要配置如下参数：session配置、servlet配置和映射、filter配置和映射、监听应用生命周期的listener、首页和错误页面配置、安全配置等。具体扫描过程如下
        - 使用WebXmlDigester，将web.xml的数据解析到WebXml对象中
		- 扫描/WEB-INF/lib下每个Jar包内的/META-INF/web-fragment.xml并解析，根据一定的规则排序，并放入Set中
		- 扫描/WEB-INF/lib下每个Jar包内的/META-INF/services/目录下的ServletContainerInitializer实现类，放入StandardContext.initializers中（后续将执行其onStartup方法）
		- 扫描/WEB-INF/classes下的servlet注解并添加相应配置
		- 将第一步解析的应用web.xml和第二步解析的web-fragment.xml以及全局的web.xml文件(conf/web.xml 、web.xml.default)合并到WebXml对象中
		将合并后的WebXml配置到Context中，例如为每个Servlet创建Wrapper并作为Context的子容器

	- web应用初始化

		根据上一步对`*.jar/META-INF/services/ServletContainerInitializer`的扫描结果，调用他们的ServletContainerInitializer.onStartup()方法,实例化listener，并调用listener.contextInitialized(),实例化filter，并调用filter.init(),对于配置load-on-startup的servlet，实例化servlet并执行servlet.init()

- 启动connector接受网络请求


---
### 配置

**tomcat目录结构**<br>
tomcat中目录顾名思义，需要注意的是下面几个文件，详细内容[参见](http://www.cnblogs.com/z-sm/p/5477715.html)<br>

**执行命令**

- `bin/startup.sh` 启动Tomcat脚本
- `bin/shutdown.sh` 关闭Tomcat脚本
- `bin/catalina.sh` 脚本文件，可以编辑配置诸如jdk，jvm等参数信息

**配置文件**

- `conf/server.xml` Tomcat 的全局配置文件
- `conf/web.xml` 为不同的Tomcat配置的web应用设置的缺省值的文件
- `conf/context.xml` tomcat的默认context容器
- `conf/tomcat-users.xml` Tomcat用户认证的配置文件

**应用部署** `webapps/`<br>
每个部署的web应用中Web-INF/*不能直接被外部访问，但是当下目录的其他文件可以直接通过前缀访问到

- `Web-INF/web.xml` 是一个Web应用程序的描述文件
- `Web-INF/classes/` 这个目录及其下的子目录应该包括这个Web应用程序的所有JavaBean及Servlet等编译好的Java类文件（*.class）文件
- `Web-INF/lib/`包含应用使用到的第三方包 

---
#### 部署web应用的常见方法

**静态部署**指启动tomcat服务器之前部署好我们的web应用程序

1. **自动部署** 直接将应用程序复制到\$CATALINA_HOME/webapps/下。由于默认设置autoDeploy="true",tomcat启动将会加载该web应用
2. **修改server.xml文件** 在Host标签中添加`<Context  path ="/Test"  reloadable ="false"  docBase ="/webapps"/>`,其中path表示http访问路径前缀，docBase表示该web应用所在相对\$CATALINA_HOME路径，reloadable表示是否在应用文件内容发生变化的时候重新载入。
3. **自定义web部署文件** 在$CATALINA_HOME/conf/Catalina/localhost/添加一个xml文件描述该web应用，内容和配置方式二相同。

**动态部署**
通过tomcat提供的后台管理界面配置web应用，具体请自行google.


---
#### tomcat常见配置

影响tomcat性能的因素很多，下面主要从内存、并发、缓存等方面进行配置<br>

**内存** 可以从catalinash.sh启动脚本中设置java_OPTS参数

- -server 启用jdk 的 server 版； 
- -Xms java虚拟机初始化时的最小内存； 
- -Xmx java虚拟机可使用的最大内存； 
- -XX: PermSize 内存永久保留区域 
- -XX:MaxPermSize 内存最大永久保留区域 

```shell
JAVA_OPTS=’-Xms1024m -Xmx2048m -XX: PermSize=256M -XX:MaxNewSize=256m -XX:MaxPermSize=256m’
```

**线程池、缓存等配置**

- maxThreads 客户请求最大线程数 
- minSpareThreads Tomcat初始化时创建的socket线程数 
- maxSpareThreads Tomcat连接器的最大空闲socket线程数 
- enableLookups 若设为true, 则支持域名解析，可把ip地址解析为主机名 
- redirectPort 在需要基于安全通道的场合，把客户请求转发到基于SSL的redirectPort端口 
- acceptAccount 监听端口队列最大数，满了之后客户请求会被拒绝（不能小于maxSpareThreads ） 
- connectionTimeout 连接超时
- minProcessors 服务器创建时的最小处理线程数 
- maxProcessors 服务器同时最大处理线程数 
- compression 打开压缩功能 
- compressionMinSize 启用压缩的输出内容大小，这里面默认为2KB 
- compressableMimeType 压缩类型 

```xml
<Connector port="9027"
protocol="HTTP/1.1"
maxHttpHeaderSize="8192"
maxThreads="1000"
minSpareThreads="100"
maxSpareThreads="1000"
minProcessors="100"
maxProcessors="1000"
enableLookups="false"
compression="on"
compressionMinSize="2048"
compressableMimeType="text/html,text/xml,text/javascript,text/css,text/plain"
connectionTimeout="20000"
URIEncoding="utf-8"
acceptCount="1000"
redirectPort="8443"
disableUploadTimeout="true"/>
```

**session配置**<br>

大量session会消耗服务器内存，影响服务器性能，可以通过在conf/web.xml中设置自动删除session的时间

```xml
<session-config>
	<session-timeout>30</session-timeout>
<session-config>
```


这里需要注意的是，jsp中有自动创建session的机制，如果不需要在jsp中使用到session,可以关闭。

```jsp
<%  @page session="false"%>
```


---
### 参考资料
- [Tomcat整体架构简析](https://www.jianshu.com/p/bf7c0b73b849)
- [Tomcat的启动分析](http://www.fanyilun.me/2016/10/10/Tomcat%E7%9A%84%E5%90%AF%E5%8A%A8%E5%88%86%E6%9E%90/)
- [Tomcat目录结构](https://www.jianshu.com/p/81ec9c51435e)
- [如何优化tomcat配置(从内存、并发、缓存4个方面)优化](http://blog.csdn.net/centre10/article/details/50639693)
- [jsp在悄悄的创建session ！！！](http://blog.csdn.net/u014143369/article/details/60480326)