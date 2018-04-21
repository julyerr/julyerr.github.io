---
layout:     post
title:      "catalina"
subtitle:   "catalina"
date:       2018-04-19 6:00:00
author:     "julyerr"
header-img: "img/web/tomcat/tomcat.png"
header-mask: 0.5
catalog:    true
tags:
    - tomcat
---

下面主要介绍tomcat的servlet容器实现--Catalina。catalina包含所有容器组件，涉及tomcat启动入口、shell程序以及安全、会话、集群等多个方面。

![](/img/web/tomcat/analysis/third/catalina-arch.png)

tomcat是servlet容器，catalina是核心，其他模块都是为其提供支撑，Coyote提供链接通信、Jasper提供JSP引擎、Naming提供JNDI服务，Juli提供日志服务。

### Digester
catalina通过Digester解析XML（server.xml)配置文件并创建应用服务器,下面简单介绍一下xml解析过程。

#### xml解析工具Digester

Digester是SAX（事件驱动XML处理工具）高层次封装，是Apache Commons中一个项目。工作原理核心是**匹配模式**和**处理规则**，通过xml文件流，识别出特定xml节点会执行特定动作，或者创建java对象，或执行对象某个方法。tomcat中直接包含Digester代码，因此不需要引入Apache Commons的依赖包。<br>

**模式匹配**

- a/b 匹配所有父节点为"a"名称为"b"的节点
- */a 处理所有名称为"b"的节点

**处理规则**<br>
org.apache.commons.digester.Rule接口定义了模式匹配触发的事件方法

- begin():读取到匹配节点，将节点所有属性作为参数传入
- body():读取匹配集诶单内容时调用
- end():读取到匹配节点结束部分调用
- finish():整个parse()方法完成时调用

![](/img/web/tomcat/analysis/third/digester.png)
    
一般只需要使用Digester默认提供处理规则即可,以下是一个digester的解析demo

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<department name="department" code="deptcode001">
    <user name="username001" code="usercode001"></user>
    <user name="username002" code="usercode001"></user>
    <extension>
        <property-name>directory</property-name>
        <property-value>joke</property-value>
    </extension>
</department>
``` 

```java
public class User {
    private String name,code;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }
}

public class Department {
    private String name, code;
    private Map<String, String> extension = new HashMap<>();
    private List<User> users = new ArrayList<>();

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public void addUser(User user) {
        users.add(user);
    }

    public void putExtension(String name, String value) {
        extension.put(name, value);
    }
}
```

---
### catalina标准创建过程

#### Server 解析
具体可以参见实现代码，主要过程

1. 创建Server实例
2. 创建全局J2EE企业命名上下文
3. 为Server添加生命周期监听器
4. 构建Service实例
5. 为Service添加生命周期监听器
6. 为Service添加Executor，Catalina中Executor线程共享Service,默认没有配置Executor，即自定义Executor不共享Service
7. 为Service添加Connector
8. 为Connector添加虚拟主机SSL配置
9. 为Connector添加生命周期监听器
10. 为Connector添加升级协议，用于支持HTTP/2
11. 为子元素添加元素解析规则，包括GlobalNamingResources、Engine、Host、Context等（如下分析)

#### Engine解析

1. 创建Engine实例（默认实现为StandardEngine），并且添加到Service实例中，添加一个生命周期监听器EngineConfig（创建时默认添加，并非server.xml配置实现）,该生命周期监听器用于打印Engine启动和停止日志
2. 为Engine添加集群配置
3. 为Engine添加生命周期监听器
4. 为Engine添加安全配置(RealmRuleSet)以及拦截器Value

#### Host解析

1. 创建Host实例（默认为StandardHost),并且添加到Engine上，添加生命周期监听器HostConfig(catalina创建时默认添加，并非server.xml配置实现)，此监听器做了大量工作（参见下文分析）
2. 为Host添加集群，集群可以配置在Engine级别，也可以在Host级别
3. 为Host添加生命周期管理
4. 为Host添加安全配置以及拦截器，Host默认添加拦截器为AccessLogValue,用于记录访问日志

#### Context解析
catalita的context配置可以来自多处，这里介绍server.xml中的配置

1. context实例化，通过server.xml配置Context，会自动创建context实例（默认StandardContext，还添加了ContextConfig的生命周期监听器ContextConfig，用于解析web.xml，配置context);若没有通过server.xml配置context，HostConfig会自动扫描部署目录，创建context，此时仅需要解析子节点;
2. 为context添加生命周期监听器
3. 为context指定类加载器
4. 为context添加会话管理器（默认实现为StandardManager)，同时制定会话存储方式和会话标志生成器
5. 为context添加初始化参数
6. 为context添加安全配置以及web资源配置，tomcat8新增了PreResources、JarResources、PostResources三种资源配置（具体参见下文）
7. 为context添加资源链接，用于J2EE命名服务
8. 为Context添加拦截器Value
9. 为Context添加守护资源配置
    - WatchedResource用于监视资源，资源变化时，web应用为重新加载（默认为WEB-INF/web.xml);
    - WrapperListener用于监听容器，添加到Wrapper上;
    - JarScanner（默认实现为StandardJarScanner)，扫描web应用和类加载器层级的jar包，主要用于TLD扫描和web-fragment.xml扫描
10. 为Context添加Cookie处理器
    tomcat8.5.6版本之前默认实现为LegacyCookieProcessor，之后改为Rfc6265CookieProcessor    

---
### 加载web应用

StandardHost加载Context有两个入口

- 一个入口是在catalina构造Server实例，如果Host元素存在Context子元素，Context作为Host容器子容器添加到Host实例中，并在Host启动时启动
- 另一个入口则是HostConfig自动扫描部署目录，创建Context实例并启动

![](/img/web/tomcat/analysis/third/webapp-load.png)
大体流程如上图所示，下面具体分析<br>

catalina对web应用的加载主要由StandardHost、HostConfig、StandardContext、ContextConfig和StandardWrapper完成

#### StandardHost

StandardHost启动过程如下 

1. 如果配置集群组件Cluster,则启动;
2. 如果配置安全组件Realm,则启动;
3. 启动子节点（通过server.xml中<context>创建的StandardContext实例）
4. 启动Host持有Pipeline组件
5. 设置Host状态为STARTING,触发START_EVENT生命周期事件，HostConfig监听此事件，扫描web部署目录，创建StandardContext实例，添加到Host并启动
6. 启动后台任务处理，cluster后台处理、readlm后台处理，Pipeline中value后台处理等



#### HostConfig
server.xml默认没有context配置，只包含Host配置

```xml
<Host name="localhost" appBase="webapps" unpackWARS="true" autoDeploy="true"></host>
```

HostConfig是LifecycleListener实现，由catalina添加到Host实例上，处理生命周期事件包括：START_EVENT、PERIODIC_EVENT、STOP_EVENT。<br>

**START_EVENT事件处理**包含以下三部分

- **Context描述文件部署**
    tomcat支持独立Context描述文件配置web应用，默认在$CATALINE_BASE/conf/<Engine名称>/<Host名称>下，配置方式同server.xml。对该目录下每个配置文件，由线程池完成解析部署
    1. 使用Digester解析配置文件，创建Context实例
    2. 更新context实例名称、路径
    3. 为context添加contextConfig生命周期监听器
    4. 将context实例添加到host，如果host已经启动，直接启动context
    5. 将context描述文件、web应用目录以及web.xml等添加到守护资源，在文件发生变更时，重新加载或者部署应用。

- Web目录部署
    将Web应用所有资源（js,jsp，jar,WEB-INF/web.xml等）复制到appBase目录下;
    如果需要自定义context，可以在META-INF/context.xml来自定义context，接下来的部署过程和上面十分类似
- WAR包部署
    只是将web目录进行了jar打包和压缩，执行过程也类似


**PERIODIC_EVENT事件**

- catalina容器支持定期执行自身及其子容器后台处理过程（容器父类ContainerBase中的backgroundProcess()方法定义，默认由Engine维护后台任务处理线程）。通常用于定时扫描web应用的变更，并重新加载，后台任务处理完成之后，触发PERIODIC_EVENT事件。
- HostConfig通过DeployedApplication维护了两个守护资源列表，redeployResources(重新部署资源)和reloadResources（重新加载资源）。重载和重新部署区别在于，前者context对象重启，后者创建context对象。如context描述文件变更，重新部署应用，web.xml文件变更，重新加载context即可。
- HostConfig接收到 PERIODIC_EVENT事件,检查守护资源变更情况，重新加载或者部署应用（serviced维护web应用列表，修改某个应用会通过同步方式添加到该列表，操作完毕同步方式从列表中移除）。


#### StandardContext

web容器相关静态结构

![](/img/web/tomcat/analysis/third/web-container.png)

- tomcat提供的ServletContext实现类为ApplicationContext，web应用使用的是其门面类ApplicationContextFacade
- FilterMap用于存储filter-mapping配置;
- FilterConfig实现类为ApplicationFilterConfig，同时也负责Filter的实例化。
- NamingResources用于存储web应用声明的命名服务（JDNI），StandardContext通过servletMappings存储servlet-mapping配置。

启动过程
1. 发布正在启动的JMX通知
2.启动当前Context维护的JNDI资源
3. 初始化当前Context使用的WebResourceRoot并启动
4. 创建web应用类加载器（webapploader),此类还提供background-Process，用于Context后台处理。当检测到
web资源发生变化时，重新加载Context
5. 没有设置cookie处理器，则创建Rfc265CookieProcessor
6. 设置字符集映射
7. 初始化临时目录
8. web应用依赖检测
9. 如果当前Context使用JNDI，为其添加NamingContexListener
10. 启动类加载器，真正创建webappClassLoader实例
11. 启动安全组件
12. 发布CONFIGURE_START_EVENT事件，ContextConfig监听该事件完成Servlet的创建
13. 启动Context子节点（Wrapper）
14. 启动Context维护的Pipeline
15. 创建会话管理器（如果配置集群组件，由集群组件创建）
16. 将Context的web资源添加到ServletContext属性
17. 创建实例管理器，用于创建对象实例，如Servlet、filter等
18. 将jar包扫描器添加到ServletContext属性
19. 合并ServletContext初始化参数和Context组件中的ApplicationParameter，ApplicationParameter配置为可以覆盖，只有当ServletContext没有相关参数或者相关参数为空时添加；如果配置为不可覆盖，忽略ServletContext同名参数，强行添加ApplicationParameter参数；
20. 启动添加到当前Context的ServletContainerInitializer（由ContextConfig查找并添加），主要用于可编程方式添加web应用的配置；
21. 实例化应用监听器（ApplicationListener），分为生命周期监听器（HttpSessionListener、ServletContextListener）和事件监听器（ServletContextAttributeListener、ServletRequestAttributeListener、HttpSessionAttributeLister、ServletRequestListener、HttpSessionIdListener）；
22. 检测未覆盖HTTP方法安全约束
23. 启动会话管理器
24. 实例化FilterConfig、Filter，并调用Filter.init初始化
25. 对于loadOnStart>=0的wrapper，调用Wrapper.load()，负责实例化Servlet
26. 启动后台定时处理线程
27. 发布正在运行的JMX通知
28. 调用WebResourceRoot.gc()释放资源（WebResourceRoot加载资源时，为了提高性能会缓存某些信息）
29. 设置Context状态，启动成功，设置为STARTING


#### ContextConfig
context创建时会默认添加一个生命周期监听器（ContextConfig），共处理6类事件，和Context关系重大的有以下三类

- **AFTER_INIT_EVENT事件**
    属于Context初始化阶段，用于context属性配置工作；
    Context属性根据执行顺序，优先级为configFile、Config/<Engine名称>/<Host名称>/context.xml.default、conf/context.xml

- **BEFORE_START_EVENT事件**
    在context启动之前触发，用于更新Context的docbase属性和解决web目录所的问题
- **CONFIGURE_START_EVENT事件**
    真正用于创建Wrapper的事件

#### web容器初始化
web应用部署描述可来源WEB-INF/web.xml、Web应用JAR包META-INF/web-fragment.xml和META-INF/services/javax.servlet.ServletContainerInitializer。

1. 解析默认配置，生成默认webXml对象;
2. 解析Web应用的web.xml文件;
3. 扫描web应用所有JAR包，如果包含META-INF/web-fragment.xml，则解析文件并创建WebXml对象;
4. 将web-fragment.xml创建的WebXml对象按照Servlet规范进行排序，将排序结果对应的JAR文件名列表设置到ServletContext属性中（排序顺序决定了Filter等执行顺序）；
5. 查找ServletContainerInitializer实现，分为Web应用下的包和容器包两部分；
6. 根据ServletContainerInitializer查询结果以及javax.servlet.annotation.HandlesTypes注解配置，初始化typeInitializerMap和initializerClassMap两个映射，前者表示类对应的ServletContainerInitializer集合，后者表示ServletContainerInitializer对应类的集合；
7. 当"主WebXml"的metadataCompleta为false,或者typeInitializerMap不为空，处理WEB-INF/classes和JAR包内javax.servlet.annotation.HandlesTypes注解，将javax.servlet.annotationWebServlet、javax.servlet.annotation.WebFilter、javax.servlet.annotation.WebListener注解配置合并到"片段WebXml";
8. "主WebXml"的metadataComplete为false，将所有"片段WebXml"按照顺序合并到"主WebXml"
9. 将"默认WebXml"合并到"主WebXml";
10. 配置JspServlet,将JspFile属性不为空Servlet设置为Servlet初始化参数，同时名称为"jsp"的servlet初始化参数也复制到该Servlet中;
11. 使用"主WebXml"配置StandardContext（Servlet、Filter、Listener等），对于Servlet，创建StandardWrapper子对象，并添加到StandardContext实例，对于ServletContext层级对象直接由StandardContext维护；
12. 将合并后的WebXml保存到ServletContext属性中（org.apache.tomcat.util.scan.MergedWebXml），以便后续使用;
13. 查找JAR中"META-INF/resources/"下的静态资源，添加到StandardContext;
14. 将ServletContainerInitializer扫描结果添加到StandardContext，以便StandardContext启动时使用。

#### 应用程序注解配置

StandardContext的ignoreAnnotations为false,支持如下接口命名服务注解配置，添加相关JNDI资源引用，以便实例化相关接口，进行JNDI资源依赖注入

- java.servlet.*:
    - ServletContextAttributeListener
    - ServletRequestListener
    - ServletRequestAttributeListener
    - HttpSessionAttributeListener
    - HttpSessonListener
    - ServletContextListener
    - Filter
    - Servlet
- 类
    javax.annotation.Resource、javax.annotation.Resources
- 属性和方法
    javax.annotation.Resource  


#### StandardWrapper
当ContextConfig完成web容器初始化后，调用StandardWrapper.start设置状态为STARTED;对于启动时加载的Servlet，调用StandardWrapper.load完成Servlet加载
    
1. 创建Servlet实例，如果添加JNDI资源注解，进行依赖注入;
2. 读取javax.servlet.annotation.MultipartConfig注解配置，用于处理multipart/form-data请求处理（临时文件路径存储、上传文件最大字节数等）
3. 读取javax.servlet.annotation.ServletSecurity()注解配置，添加Servlet安全
4. 调用javax.servlet.Servlet.init()方法进行初始化


整个流程大体图，如下(查看[大图](http://julyerr.club/img/web/tomcat/tomcat_sequence.jpg))

![](/img/web/tomcat/tomcat_sequence.jpg)

---
### 处理请求过程
Mapper维护了请求链接和Host、Context、Wrapper等Container映射，MapperListener监听器监听所有Host、Context、Wrapper组件，在相关组件启动、停止时注册或者移除相关映射。

![](/img/web/tomcat/analysis/second/whole-arch.png)

**CoypteAdapter将Connector与Mapper、Container联系起来**<br>

当Connnector读取数据，调用 CoyoteAdapter.service()方法完成请求处理，具体如下

1. 根据Connector请求和响应创建Servlet请求和响应
2. 转换请求参数并完成请求映射
    - 请求URL解码，初始化请求路径参数；
    - 检测URI是否合法，如果非法，返回响应状态码400；
    - 请求映射，映射结果保存到mappingData，最终根据URI定位到有效的Wrapper
    - 如果映射结果MappingData的redirectPath属性不为空，则调用sendRedirect发送重定向并结束
    - 执行连接器的认证及授权
3. 得到当前Engine第一个Value并执行，完成客户端请求处理
4. 如果为异步请求
    - 获得请求读取事件监听器
    - 如果请求读取结束，触发ReadListener.onAllDataRead
5. 如果为同步请求
    - Flush并关闭请求输入流
    - Flush并关闭响应输出流

#### 请求映射
分为两部分

- 一部分CoyoteAdapter.postParseRequest负责根据请求路径的结果按照会话等信息获取到最终的映射结果，
- 另一部分，通过Mapper.map负责完成具体的请求路径的匹配。

**CoyoteAdapter.postParseRequest** 整个请求流程，确保得到如下结果

- 匹配请求路径
- 如果有有效会话，则为包含会话的最新版本
- 如果没有有效会话，则为所有匹配请求的最新版本
- Context必须是有效的

**Mapper.map** 根据具体的请求路径进行匹配，其中使用到MapperWrapper映射到具体的wrapper。<br>

**MapperWrapper映射**<br>
ContextVersion将MappedWrapper分为：默认Wrapper、精确Wrapper、前缀加通配符匹配Wrapper和扩展名匹配Wrapper。<br>
先精确查找exactWrappers,如果查找失败，则进行前缀查找;如果查找失败，进行扩展名查找;如果未找到，尝试匹配欢迎文件列表。


#### Catalina请求处理
tomcat通过责任链模式来处理客户端请求，每一层Container维护一个pipeline实例，每一层容器提供了基础Value实现，位于责任链末端。

![](/img/web/tomcat/analysis/third/request-chain.png)


#### DefaultServlet和JspServlet
tomcat在$CATALINA_BASE/conf/web.xml中定义了两个Servlet:DefaultServlet和JspServlet<br>

- **DefautlServlet**
    url-pattern为"/",主要用于处理静态资源
- **JspServlet**
    - JspServlet的url-pattern为*.jsp和*.jspx，用于处理JSP文件请求
    - 根据JSP文件生成对应Servlet的JAVA代码；
    - 将JAVA代码编译成JAVA类（支持Ant和JDT两种方式，默认JDT）
    - 构造Servlet类实例并执行请求
如果指定jsp-file，自动将servlet-class设置为JspServlet，并将JspServlet中设置初始化参数添加到当前Servlet

---
### 参考资料
- 《tomcat架构解析》