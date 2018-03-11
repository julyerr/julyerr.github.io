---
layout:     post
title:      "Servlet 总结"
subtitle:   "Servlet 总结"
date:       2018-03-11 8:00:00
author:     "julyerr"
header-img: "img/web/servlet/servlet.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - web
    - servlet
---

### Servlet简介

**Servlet是什么**<br>

Java Servlet 是运行在 Web 服务器或应用服务器上的程序，它是作为来自 Web 浏览器或其他 HTTP 客户端的请求和 HTTP 服务器上的数据库或应用程序之间的中间层。

![](/img/web/servlet/servlet-arch.jpg)


**servlet优势**<br>

- 使用单线程响应用户请求，性能较好
- 使用java编写，可以跨平台运行。
- 服务器上的 Java 安全管理器执行了一系列限制，以保护服务器计算机上的资源。
- Java 类库的全部功能对 Servlet 来说都是可用的。它可以通过 sockets 和 RMI 机制与 applets、数据库或其他软件进行交互。


**Servlet 生命周期**<br>

1.Servlet实例创建于用户第一次调用该Servlet的URL时(也可以通过配置文件指定Servlet在服务器第一次启动时被加载)，此时Servlet的init()方法被调用（后续每次用户请求时不再调用）.init(ServletConfig)方法简单地创建或加载一些数据，这些数据将被用于 Servlet 的整个生命周期.

```xml
<loadon-startup>1</loadon-startup>
```	

2.对于一个客户端的请求，Server创建一个请求对象、一个响应对象和一个新的线程，该线程调用Servlet的service()方法，传递请求和响应对象作为参数来响应用户的请求。service()方法可能激活其它方法以处理请求，如doGet()或doPost()或程序员自己开发的新的方法。

3.当Server不再需要Servlet时(一般当Server关闭时)，Server调用Servlet的Destroy()方法。

![](/img/web/servlet/life-time.jpg)

---
### Servlet应用开发

#### 环境部署

servlet需要运行在具体的web服务器中，下面就以idea中配置servlet为例。<br>

1.**使用maven创建web-app的项目**

![](/img/web/servlet/ins-maven.jpg)

2.**配置运行环境**(当然首先需要从官网下载tomcat服务器，然后在idea中配置tomcat路径)

![](/img/web/servlet/ins-run.png)

3.**配置maven源**

```xml
<dependency>
    <groupId>javax.servlet</groupId>
    <artifactId>javax.servlet-api</artifactId>
    <version>3.0.1</version>
    <scope>provided</scope>
</dependency>
```

4.**编写逻辑处理代码**

Servlet是服务HTTP请求并实现`javax.servlet.Servlet`接口的Java类,通常编写Servlet的扩展实现类`javax.servlet.http.HttpServlet`，并实现Servlet接口的抽象类专门用来处理 HTTP 请求。（具体参数等分析参加后文）

```java
public class HelloWorld extends HttpServlet {
    private String message;

    public void init() throws ServletException {
        // 执行必需的初始化
        message = "Hello World";
    }

    public void doGet(HttpServletRequest request,
                      HttpServletResponse response)
            throws ServletException, IOException {
        // 设置响应内容类型
        response.setContentType("text/html");

        // 实际的逻辑是在这里
        PrintWriter out = response.getWriter();
        out.println("<h1>" + message + "</h1>");
    }

    public void destroy(){
        // 什么也不做
    }
}
```


5.**servlet 路径映射**

```xml
<!--具体处理类-->
    <servlet>
        <servlet-name>HelloWorld</servlet-name>
        <servlet-class>com.julyerr.interviews.servlet.HelloWorld</servlet-class>
    </servlet>

<!--servlet路径映射-->
    <servlet-mapping>
        <servlet-name>HelloWorld</servlet-name>
        <url-pattern>/HelloWorld</url-pattern>
    </servlet-mapping>
```

请求访问`http://localhost:8080/HelloWorld`,上文所涉及代码[参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/servlet)

---
#### Servlet中常见的对象以及方法

**Servlet**

```java
//初始化方法
init()
//得到一个ServletConfig对象，利用这个参数可以得到初始化参数
getServletConfig()
//servlet对于请求的一个响应
service()
//返回servlet的相关信息
getServletInfo()
//销毁Servlet
destroy()
```


**ServletContext**<br>

整个web应用的上下文,初始化参数配置(不属于具体的servlet,不能写在`servlet`内部)

```xml
<context-param>
</context-param>
```

常见的方法

```java
//初始化参数
getInitParameter(String)
getInitpatameterNames()
//获取/设置属性
getAttribute(String)
getAttributeNames()
setAttribute(String,Object)
removeAttribute(String)
//有关服务器（及容器）信息
getMajorVersion()
getServerInfo()
//返回web资源上的一个URL对象
getResource(String path)
//获取到服务器上的绝对路径信息
getRealPath()
//获取servlet转发器
getRequestDispatcher(String)
//request.getRequestDispatcher("/url").forward(request, response) 请求转发，地址栏不会发生变化，效率较高
//记录服务器日志信息
log(String)
```


**ServletConfig**<br>

具体的Servlet配置对象,servlet初始化的时候作为参数传入

```java
//初始化参数等信息
getInitParameter(String)
Enumeration getInitParameterNames()
//获取到servletContext的引用
getServletContext()
//servlet名称
getServletName()
```

![](/img/web/servlet/api.png)

一个http请求到来，容器将请求封装成servlet中的request对象；在request中你可以得到所有的http信息，然后可以取出来操作，最后再把数据封装成servlet的response对象，应用容器将respose对象解析之后封装成一个http response。<br>


**ServletRequest**

```java
getInputStream() //获取输入流
getAtribute() //获取对应的属性
getLocalPort()  //最终发送到某个线程监听的端口号
getServerPort() //获取服务器监听的端口号
getParameter(String) //发送表单的时候获取其中的内容
getParameterNames()  //发送表单的名称
getParameterValues()  //发送表单的值
```


**ServletResponse**

```java
getOutputStream() //获取输出流
getWriter()  //输出writer对象
getBufferSize() //缓存的大小
setContentType()
```

**HttpServletRequest**

```java
getContextPath() //项目的相对路径
getCookies()     //获取cookie
getSession()     //获取session
getIntHeader(String) // 请求头中对于字段转换成int 
getMethod()  //请求方法
getQueryString() //请求的query string
```

**HttpServletResponse**

```java
addCookie() //设置cookie
addHeader() //增加http 头
encodeURL(String) //将属性值添加到URL路径中
setStatus() //设置响应状态
sendError() //发送错误信息
sendRedirect() //重定向，地址栏会发生变换，相当于客户端重新发起一次请求
```

cookie和session原理性简介[参见](http://julyerr.club/2018/03/06/http/#状态信息保留)<br>

**Cookie**

```java
//创建Cookie对象
Cookie(String name,String value)
//设置cookie的有效路径,只在此路径下才会发送session到服务器端
setPath(java.lang.String uri)   　　
//设置值
setValue()
//设置cookie的有效时长
setMaxAge()
```

**Session**

```java
//session访问
getsession()
//true:得不到session对象，创建 新的session对象,false:如果得不到session对象，返回null
getSession(boolean create)

//会话数据操作

setAttribute(String,Object)
getAttibute(String)
removeAttribute(String)


//session细节

//得到session对象的编号
getId()
//设置session有效时长
setMaxInactiveInterval(int interval)
//销毁session
invalidate()
```

---
#### 过滤器（Filter)

在用户访问某个目标资源之前，对访问的请求和响应进行拦截，从而实现一些特殊功能，如编码设置、URL级别的权限访问控制等。

![](/img/web/servlet/filter.png)

filter使用和配置与servlet非常类似<br>

**生命周期**<br>

1.**init(FiterConfig)**<br>
过滤器在web应用启动的时候就会创建，与servlet有点不同；可以通过FilterConfig对象获取到配置信息<br>

2.**doFilter(ServletRequest,ServletResponse,FilterChain chain)**<br>

- FilterChain：web应用允许存在多个Filter，执行顺序和web.xml中配置顺序相同，这些Filter组合起来类似链条.
- 如果允许用户访问资源需要在代码中调用`chain.doFilter(request, response)`,默认是不执行该代码，即不允许用户访问资源。
- 实际开发中方法中,参数request和response通常转换为HttpServletRequest和HttpServletResponse类型进行处理

3.**destroy()**<br>
在Web容器卸载 Filter 对象之前被调用<br>


下面是一个字符编码的demo<br>

**字符编码**<br>
主机和客户端不能直接传输文本，需要转换成对应的byte流才能在网络上传输。但是通常人们习惯操作以GB2312、UTF-8等格式编码的文本串;因此需要一种机制，发送方将文本串转换成	byte，然后接收方将byte转换成文本串。前一个过程称为编码，后一过程称为解码，一般只有两者的编码方式一致才能正确显示原始文本串。<br>

#### servlet中处理字符串编码问题

浏览器和服务器通信的时候，商量好使用的字符编码接口。

**就response而言**

```java
//设置http响应头
response.setHeader("content-type","text/html;charset=UTF-8");
...
//对reponse进行操作，同样设置编码方式
response.setCharacterEncoding("UTF-8");
```

**就request而言**<br>

常见的中文浏览器默认的字符编码方式为GB2312，servlet如果不进行编码设置的话，解码方式通常是`ISO-8859-1`,这样就会显示乱码,[这篇文章讲解不错](http://blog.csdn.net/xiazdong/article/details/7217022)。

```java
request.setCaracterEncoding(“gb2312”);
request.getParameter("varName");

//或者
String varName = request.getParameter("varName");
varName = new String(varName.getBytes("ISO-8859-1"),"gb2312");
```	

Filter实现字符编码设置，更多filter的[常见应用参见](https://www.jianshu.com/p/cd2b02ce9bee).<br>

**编写filter实现类**

```java
public class EncodingFilter implements Filter {
    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        System.out.println("execute when the web app started");
    }

    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        servletResponse.setCharacterEncoding("UTF-8");
        servletResponse.setContentType("text/html;charset=utf-8");
        servletRequest.setCharacterEncoding("UTF-8");
        filterChain.doFilter(servletRequest,servletResponse);
    }

    @Override
    public void destroy() {

    }
}
```

**编写servlet**

```java
public class EncodingFilterTest extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String user = req.getParameter("user");
        System.out.println(user);
        PrintWriter printWriter = resp.getWriter();
        printWriter.write("测试正常");
        printWriter.flush();
    }
}
```

**filter配置**

```xml
<!--servlet路径映射-->
<servlet>
        <servlet-name>EncodingFilterTest</servlet-name>
        <servlet-class>com.julyerr.interviews.servlet.filter.EncodingFilterTest</servlet-class>
    </servlet>
<servlet-mapping>
    <servlet-name>EncodingFilterTest</servlet-name>
    <url-pattern>/filter</url-pattern>
</servlet-mapping>

<filter>
    <filter-name>EncodingFilter</filter-name>
    <url-pattern>/*</url-pattern>
</filter>

<filter-mapping>
    <filter-name>EncodingFilter</filter-name>
    <servlet-name>EncodingFilterTest</servlet-name>
    <!--默认是请求，也可以限制forward,error等-->
    <dispatcher>REQUEST</dispatcher>
</filter-mapping>
```

---
#### 监听器(Listener)

Listener监听器就是一个实现特定接口的普通Java程序，这个程序专门用于监听一个java对象的方法调用或属性改变，当被监听对象发生上述事件后，监听器某个方法将立即被执行

![](/img/web/servlet/listener.jpg)

servlet中有八种监听器接口，可以分为一下三种：

- 监听 Session、request、context的创建于销毁，分别为HttpSessionLister、ServletContextListener、ServletRequestListener
- 监听对象属性变化，分别为HttpSessionAttributeLister、ServletContextAttributeListener、ServletRequestAttributeListener 
- 监听Session 内的对象，分别为HttpSessionBindingListener和HttpSessionActivationListener。与上面六类不同，这两类Listener监听的是Session 内的对象，而非 Session本身，不需要在web.xml中配置，session内的对象需要实现该接口。

listener使用和配置相对简单一点，下面以HttpSessionListener为例讲解使用，其他使用类似，可以参看[这篇文章](http://blog.csdn.net/u012228718/article/details/41730799)。<br>

**自定义监听器**

```java
public class ListenerTest implements HttpSessionListener {
    @Override
    public void sessionCreated(HttpSessionEvent httpSessionEvent) {
        System.out.println("session created:"+httpSessionEvent.getSession().getId());
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent httpSessionEvent) {
        System.out.println("session removed:"+httpSessionEvent.getSession().getId());
    }
}
```

**在需要访问的servlet中添加一下代码**

```java
//        session
HttpSession httpSession = request.getSession();
httpSession.setAttribute("name", "julyerr");
//        手动销毁session
httpSession.invalidate();
```

**Listener配置**

```xml
<!--listener测试-->
<listener>
    <listener-class>com.julyerr.interviews.servlet.listener.ListenerTest</listener-class>
</listener>
```

---
#### servlet中的并发

**变量类型**

- **实例变量** 实例变量在类中定义,该类的所有对象都能访问到该变量。
- **局部变量** 局部变量在方法中定义，只在该对象的该方法中有效，为对象私有。

Servlet容器为了保证能同时响应多个客户对同一个Servlet的HTTP请求，通常会为每个请求分配一个工作线程，这些工作线程并发执行同一个Servlet对象的service()方法，多线程之间会发生并发的一些问题。<br>

以下是一个demo<br>

**用于多线程测试的servlet**

```java
public class MultiThreadCount extends HttpServlet {
//    实例变量
    int count = 0;
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String countStr = req.getParameter("count");
        int tmpCount = 0;
        if(countStr!=null){
            tmpCount+= Integer.parseInt(countStr);
        }
        PrintWriter printWriter = resp.getWriter();
        printWriter.println("<html><head><title>ConcurrentServlet</title></head><body><h1>");
        //        同步代码块
        synchronized (this){
            count+=tmpCount;
            try {
                Thread.sleep(3000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            printWriter.write("奖池总数："+count);
        }
        printWriter.write("</h1></body></html>");
        printWriter.flush();
        printWriter.close();
    }
}
```


**servlet 配置**

```xml
<!--并发访问测试-->
<servlet>
    <servlet-name>MultiThreadTest</servlet-name>
    <servlet-class>com.julyerr.interviews.servlet.multiThread.MultiThreadCount</servlet-class>
</servlet>

<servlet-mapping>
    <servlet-name>MultiThreadTest</servlet-name>
    <url-pattern>/count</url-pattern>
</servlet-mapping>
```

同时对`http://localhost:8080/count`发起请求，后面接不同参数得到结果不同

![](/img/web/servlet/multithread-1.png)
![](/img/web/servlet/multithread-2.png)
![](/img/web/servlet/multithread-3.png)

但是不填加synchronized进行对象同步，输出的结果如下

![](/img/web/servlet/multithread-4.png)



---
### 参考资料

- [Servlet是什么](https://www.jianshu.com/p/bacb8df6fc24)
- [Servlet 教程](http://www.runoob.com/servlet/servlet-intro.html)
- <<Head First Servlet JSP>>
- [Java Web之Filter](https://www.jianshu.com/p/cd2b02ce9bee)
- [Servlet 中文乱码问题及解决方案剖析](http://blog.csdn.net/xiazdong/article/details/7217022)
- [Servlet学习笔记（九）：监听器Listener详解](http://blog.csdn.net/u012228718/article/details/41730799)
- [JavaWeb之Servlet：Cookie 和 Session会话](http://www.cnblogs.com/vmax-tam/p/4130589.html)
- [Servlet中的并发问题](http://blog.csdn.net/Goskalrie/article/details/51240482)