---
layout:     post
title:      "Jasper以及tomcat常见应用配置"
subtitle:   "Jasper以及tomcat常见应用配置"
date:       2018-04-24 6:00:00
author:     "julyerr"
header-img: "img/web/tomcat/tomcat.png"
header-mask: 0.5
catalog:    true
tags:
    - tomcat
---

>jasper是tomcat中使用的jsp引擎，tomcat采用后台线程的方式定期检测JSP页面是否更新，如果更新，重新编译JSP页面并加载。

### JSP编译方式

#### 运行时编译

tomcat在客户端第一次请求时才编译需要访问的JSP文件

![](/img/web/tomcat/analysis/fifth/jspservlet.png)

**获取JSP文件路径有以下几种方式**

- 指定了JSPFile属性，该属性值即为JSP文件路径（除非所有请求均定向单一的JSP页面，否则多数不会配置该属性）；
- 请求中javax.servlet.include.servlet_path属性不为空，则在其属性值上添加javax.servlet.include.path_info属性值作为jsp文件路径（主要用于RequestDispatcher的include操作或<jsp:include>）；
- HttpServletRequest.getServletPath加上HttpServletRequest.getPathInfo作为JSP路径（常用方式）。

**根据JSP文件构造JSPServletWrapper对象**

- 每个JSP页面对应一个JSPServletWrapper实例（tomcat会缓存JSPServletWrapper，同时对于一段时间未使用的页面对象会将其删除），它负责编译、加载JSP文件并完成请求处理。
- 如果当前是开发环境或者是首次加载，会调用JSPCompilationContext的compile（）方法进行编译，然后加载并实例化JSP编译成功后对应的Servlet类。

**编译结果**<br>

jsp页面编译结果通过配置存放在不同的位置

- ServletContext初始化参数scratchdir,指定存放位置

```xml
<context-param>
	<param-name>scratchdir<param-name>
	<param-value>web-app/tmp/jsp/</param-value>
</context-param>
```

- 若没有配置scratchdir，默认在当前web应用之下，$CATALINA_BASE/work/Catalina/localhost/webappName/


#### 预编译
在web应用启动时，提前将所有的jsp文件编译成对应的servlet。


**JSP编译原理**

![](/img/web/tomcat/analysis/fifth/jsp-compiler.png)

JSPCompilationContext只是封装了JSP页面编译过程中的信息，具体的编译工作由Compiler类实现（JDTCompiler和AntCompiler）。整个编译过程较为繁琐，如果感兴趣可以尝试阅读源码，这里就不在展开。


![](/img/web/tomcat/analysis/fifth/compiler-workflow.png)

---
### tomcat配置管理

tomcat配置管理涉及内容较多，下面主要就服务器和web应用配置层次介绍

**JVM配置** 针对JVM常见的优化配置等

### 服务器配置 

#### server.xml

tomcat应用服务器核心配置文件，可以对容器所有组件进行配置。

**Server**

```xml
<Server port="8005" shutdown="SHUTDOWN">
...
<Server>
```

Server中可以内嵌子元素，Service、GlobalNamingResource和Listener。

- GlobalNamingResource定义全局命名服务
- Listener为Server添加生命周期监听器


#### Service

可以内嵌的子元素，Listener、Executor、Connector、Engine。

- Listener用于为Service添加生命周期管理器
- Executor 用于Service的共享线程池配置，默认没有开启，则Catalina的各组件（如Connector)在用到线程池时候自动创建，此时线程池不能被其他组件共享。

```xml
<Executor name="tomcatThreadPool" namePrefix="catalina-exec-" maxThreads="150" minSpareThreads="4" />
```

#### Connector 
用于创建链接器，默认配置了两个链接器，一个支持HTTP协议，一个支持AJP协议。

```xml
<Connector port="8080" executor="sharedThreadPool" enableLookups="false"
	redirectPort="8443" acceptCount="100" connectionTimeout="2000" URIEncoding="UTF-8"
	compression="on" compressionMinSize="2048" noCompressionUserAgents="gozilla,traviate"
	compressableMimeType="text/html,text/xml,text/javascript,text/css,text/plain" />
```

- executor 增加线程池配置提升服务器请求处理并发数量（指定的线程池需要事先配置好）
- maxConnections 用于控制服务器线程池可处理最大链接数
- acceptCount 用于控制Socket中排队链接中的最大个数，排队个数大于acceptCount时，服务器将拒绝新的链接请求。因此服务器可以接受请求总数为maxConnections+acceptCount。
- redirectPort 如果当前链接接受一个符合<security-constrains>约束的请求，需要ssl传输，将自动将请求重定向到指定端口
- enableLokups 设置为true，request.getRemoteHost()将执行DNS查询返回客户端实际主机名称;设置为false，直接返回ip。通常设置为false，提高性能。


#### Engine 
支持嵌入元素，Cluster、Listener、Realm、Valv和Host。

- Cluster用于集群配置
- Listener 用于为Engine添加生命周期监听器
- Realm 用于安全配置
- Valve 用于拦截Engine一级的请求处理

#### Host 
用于配置一个虚拟主机，支持Alias、Cluter、Listener、Valva、Realm和Context元素的嵌入。

```xml
<Host name="localhost" appBase="webapps" unpackWARS="true" autoDeploy="true">
</Host>
```

- appBase 当前Host应用基础目录，其他的web应用均在该目录下，默认为webapps
- unpackWARS 设置为true，则会在Host启动时，将appBase目录下的WAR包解压为目录;设置为false，Host将直接从WAR文件中启动Web应用
- autoDeploy 设置为true，tomcat定期检测appBase和xmlBase目录，部署发现新的Web应用或者Context描述文件；重载更新的web应用或者context描述文件
- context配置和context.xml中配置一致，具体参见下文context.xml配置

---
### context.xml

Context 配置一个Web应用，支持内嵌元素为：CookieProcessor、Loader、Manager、Realm、Resources、WarchedResource、JarScaner、Valve。<br>

**CookieProcessor**
用于将HTTP头中Cookie信息与javax.servlet.http.Cookie对象的相互转换，默认提供了LegacyCookieProcessor（严格按照Cookie规范处理）和Rfc265CookieProcessor两个实现类。

#### Loader 
配置Context当前的web类加载器，tomcat默认先加载web应用中的类，然后再从父类开始加载。

```xml
<Context docBase="myApp" path="/myApp">
<Load loaderClass="org.apache.catalina.loader.ParallelWebappClassLoader" reloadable="true" />
</Context>
```
- tomcat中提供了两个loaderClass类，WebappClassLoader（单线程）和ParallelWebappClassLoader（并行加载器），默认为并行加载器。
- reloadable 属性设置为true，catalina将监控/WEB-INF/classes和/WEB-INF/lib下的变更，在检测变化时重新加载web应用。

#### Manager 
用于配置web应用会话管理器，tomcat提供了两种独立会话管理器方案，StandardManager和PersistentManager。

- StandardManager 是一种简单会话存储方案，在tomcat停止时（正常停止）会将所有会话串行化到一个文件中，启动时，将从该文件中加载有效的会话。
- PersistentManager 提供了一套统一API，封装了会话持久化处理策略。如果需要保存到不同存储系统上，不需要重写会话管理器，只需要编写一个Store接口（会话的保存、移除、加载、清空、得到等）即可。

```xml
<Context docBase="myApp" path="/myApp">
<Manager className="org.apache.catalina.session.PersistentManager" saveOnRestart="true"
	maxActiveSession="-1" minIdleSwap="0" maxIdleSwap="30" maxIdleBackup="0">
<Store className="org.apache.catalina.session.FileStore" directory="sessions"/>
</Manager>
</Context>
```	

**PersistentManager**<br>
PersistentManager会话分为两部分，内存中的会话和Store中的持久化会话。PersistentManager后台任务除定期检测内存中会话是否过期外，还会做如下工作

- 将空闲超过一定时间(maxIdleSwap)的会话持久化到Store并从内存中移除；
- 如果内存超过maxActiveSessions配置数量，会将空闲时间超过minIdleSwap的会话swapOut
- 对于内存中空闲时间超过maxIdleBackup的会话，进行持久化备份（并不从内存中移除）
- 将Store中过期的会话移除
    
也可以将会话信息报存到数据库中，实现需要确保$CATALINA_BASE/lib下防止JDBC驱动程序。

```xml
<Context docBase="myApp" path="/myApp">
<Manager className="org.apache.catalina.session.PersistentManager" saveOnRestart="true"
	maxActiveSession="-1" minIdleSwap="0" maxIdleSwap="30" maxIdleBackup="0">
<Store className="org.apache.catalina.session.JDBCStore" 
	driverName="com.mysql.jdbc.Driver"
	connectionURL="jdbc:mysql://localhost:3306/sessionsDB/user=tomcat&password="
	sessionTable="session_table"
	sessionIdCol="session_id"
	sessionDataCol="session_data"
	sessionValidCol="session_valid"
	sessionMaxInactiveCol="max_inactive"
	sessionLastAccessedCol="last_accessed"
	sessionAppCol="myApp"
/>
</Manager>
</Context>
```	

#### Resources 
配置web应用的静态资源。tomcat资源实现了javax.naming.directory.DirContext接口，可以将web应用存放到各种介质上（如WAR文件，JDBC数据库等)。


对于<Resources>，tomcat会创建一个WebResourceRoot实例用于维护，其维护的资源分为4部分，Pre、Main、JAR、Post。查询资源时，处理顺序也是按照该顺序进行的。


除Main资源通过Context的docBase属性配置，其他三部分通过内嵌元素进行配置，同时分别创建一个WebResourceSet实例。需要注意的是，只有主资源支持包含META-INF/context.xml文件和写操作。

```xml
<Context docBase="myApp" path="/myApp" >
<Resources>
	<PreResources className="org.apache.catalina.webresources.FileResourceSet"
		base="/Users/liuguangrui/Documents/sample" webAppMount="/app" />
</Resources>
</Context>
```

经过以上配置，可以通过http://localhost:8080/myApp/app访问到sample目录中的内容。<br>

**WatchedResource** 用于配置自动加载文件检测，默认检测文件为WEB-INF/web.xml、$CATALINA_BASE/conf/web.xml

#### JarScanner 
用于配置web应用jar包以及目录扫描器，扫描web应用的TLD以及web-fragment.xml

---
### web应用配置

web.xml是web应用的部署描述文件，包括$CATALINA_BASE/conf/web.xml的默认配置和web应用下的WEB-INF/web.xml下的定制配置。支持内容较多，下面就常见的配置进行总结<br>

**ServletContext初始化参数**

```xml
<context-param>
	<param-name>name</param-name>
	<param-value>value</param-value>
</context-param>
```

应用程序可以通过javax.servlet.ServletContext.getInitParameter()方法获取值

#### 会话配置

`<session-config>`配置会话信息将覆盖server.xml和context.xml中的配置



```xml
<session-config>
	<session-timeout>30</session-timeout>
	<cookie-config>
		<name>JESSIONID</name>
		<domain>sample.myApp.com</domain>
		<path>/</path>
		<http-only>true</http-only>
		<secure>true</secure>
		<max-age>3600</max-age>
	</cookie-config>
	<tracking-mode>COOKIE</tracking-mode>
</session-config>
```

- session-timeout用于配置会话超时时间，单位分钟；
- cookie-config用于配置会话追踪Cookie，只有当前会话追踪模式为Cookie时，才会生效;
- tracking-mode 配置会话追踪模式，servlet3.1支持3种追踪模式
    - COOKIE：最为常见的会话追踪机制
    - URL：通过URL回写的方式进行，当客户端不支持cookie时，将标志session的sessionid信息追加到url路径路径参数中
    - SSL：对于ssl请求，通过ssl会话标志确定请求会话标志。


#### Servlet声明以及映射

```xml
<servlet>
<servlet-name>name<servlet-name>
<servlet-class>org.myapp.servlet.MainServlet</servlet-class>
	<init-param>
		<param-name>name</param-name>
		<param-value>value</param-value>
	</init-param>
	<load-on-startup>1</load-on-startup>
	<multipart-config>
		<max-file-size>10485760</max-file-size>
		<max-request-size>10485760</max-request-size>
		<file-size-threshold>10485760</file-size-threshold>
	</multipart-config>
</servlet>
```

- init-param 指定Servlet初始化参数，在应用中可以通过javax.servlet.http.HttpServlet.getInitParameter获取
- load-on-startup 控制在web应用启动时，该servlet被自动加载而不是在用户第一次访问时才加载
- async-supported 指定当前servlet是否启动异步处理（异步处理有利于在并发量较大的情况下及早释放servlet资源）
- multipart-config 用于制定servlet上传文件请求配置，包括文件大小限制、请求大小限制以及文件写入磁盘的阈值


**应用生命周期监听器**
监听器需要实现javax.servlet.ServletContextListener接口，在应用启动时会调用监听器的contextInitialized()方法，停止时调用contextDestroy（）方法。<br>

**Filter定义及映射**
用于配置web应用过滤器，过滤资源请求及响应，经常用于认证、日志、加密、数据转换（tomcat中默认的filter介绍，参见下文）<br>

**MIME类型映射**
为当前web应用指定MIME映射，tomcat默认在$CATALINA_BASE/conf/web.xml中为绝大多数文档类型指定了MIME映射，可以不需要配置<br>

**欢迎文件列表**
通常在访问web应用的根文件路径，没有找到匹配的文件，会使用欢迎列表中的文件<br>

**错误页面**
制定访问异常定向到的页面<br>

**本地化及编码映射**
指定本地化与响应编码的映射关系

```xml
<welcome-file-list>
	<welcome-file>index.do</welcome-file>
	<welcome-file>index.jsp</welcome-file>
	<welcome-file>index.html</welcome-file>
</welcome-file-list>

<error-page>
	<error-code>404</error-code>
	<location>404.html</location>
</error-page>
<error-page>
	<exception-type>java.lang.Exception</exception-type>
	<location>/error.jsp</location>
</error-page>

<locale-encoding-mapping-list>
	<locale-encoding-mapping>
		<locale>zh</locale>
		<encoding>GBK</encoding>
	</locale-encoding-mapping>
</locale-encoding-mapping-list>
```

**安全配置**
可以为web应用增加页面访问的权限，详细介绍会在后续blog介绍。

#### web应用过滤器
tomcat针对常见的一些web应用需求（跨域资源共享、访问控制、设置请求响应编码等）提供了系列Filter实现，项目中只需要直接添加web应用配置即可。

- CorsFilter 是跨域资源共享规范的一个实现，主要是在HttpServletResponse中增加Access-Control-*头，
同时保护HTTP响应避免拆分。
- CsrfPreventionFilter 为web应用提供基本的CSRF保护。
- ExpiresFilter 负责设置服务器响应头的Expires头和Cache-Control头的max-age。
- RemoteHostFilter 比较提交请求的客户端主机名是否符合指定的正则表达式，确定是否允许继续处理请求
- RemoteIpFilter 对于通过HTTP代理或者负载均衡访问的请求，如果服务器需要获取到客户端真实地址，可以使用该过滤器，而不必
手动解析X-Forward-For的值。
- SetCharacterEncodingFilter 设置请求和响应的字符编码


---
### 参考资料
- 《tomcat架构解析》