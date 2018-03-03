---
layout:     post
title:      "spring mvc 总结一"
subtitle:   "spring mvc 总结一"
date:       2018-03-03 6:00:00
author:     "julyerr"
header-img: "img/web/spring/mvc/mvc.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - web
    - springmvc
---

>本文按照先前一样的流程，先对springmvc工作原理进行总结，而后总结常见的使用方式。

### SpringMVC工作原理

Spring MVC是Spring提供的一个强大而灵活的web框架。其中M代表model，V代表view，C代表controller。<br>

**SpringMVC工作原理**<br>
![](/img/web/spring/mvc/springmvc-workflow.jpeg)

- 用户发送的请求由前置控制器DispatcherServlet来决定哪一个页面的控制器进行处理；
- 再由HandlerMapping将请求映射为HandlerExecutionChain对象(包含Handler处理器对象（页面控制器），多个HandlerInterceptor对象即拦截器)；
- 再返回给DispatcherServlet，DispatcherServlet再次发送请求给HandlerAdapter，HandlerAdapter将处理器包装为适配器，调用处理器相应功能处理方法，Handler返回ModelAnView给HandlerAdapter；
- HandlerAdapter发送给DispatcherServlet进行视图的解析（ViewResolver）；
- ViewResolver将逻辑视图解析为具体的视图，返回给DispatcherServlet；
- 再进行视图的渲染（View），返回给DispatcherServlet，最后通过DispatcherServlet将视图返回给用户。

DispatcherServlet 是整个Spring MVC的核心，主要工作

- 截获符合特定格式的URL请求。 
- 初始化DispatcherServlet上下文对应WebApplicationContext，并将其与业务层、持久化层的WebApplicationContext建立关联。 
- 初始化Spring MVC的各个组成组件，并装配到DispatcherServlet中。
具体工作流程[参见](http://julyerr.club/2018/02/27/spring-ioc/#ioc-容器)标签下的WebApplicationContext。


---
### SpringMVC 使用

基于XML配置方式在实际项目中使用的情况比较多，基于注解和javaConfig方式也是类似

#### 基于XML配置spring mvc
- **web.xml**<br>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd"
         version="3.1">
    <!--spring 配置文件-->
    <context-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>classpath:applicationContext.xml</param-value>
    </context-param>

    <!--配置spring监听-->
    <listener>
        <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    </listener>

    <!-- 创建分发Servlet -->
    <servlet>
        <servlet-name>springmvc</servlet-name>
        <!--自动找到WEB-INF下的｛servlet-name｝-servlet.xml,可以通过ContextConfigLocation进行设置-->
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value>classpath:dispather-servlet.xml</param-value>
        </init-param>
    </servlet>
    <servlet-mapping>
        <servlet-name>springmvc</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>
</web-app>
```

- **dispather-servlet.xml**<br>
    名称可以修改

```xml
<?xml version="1.0" encoding="UTF-8"?>

<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context" xmlns:p="http://www.springframework.org/schema/p"
       xmlns:mvc="http://www.springframework.org/schema/mvc"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd  http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd http://www.springframework.org/schema/mvc http://www.springframework.org/schema/mvc/spring-mvc.xsd">

    <!--springmvc 注解支持-->
    <mvc:annotation-driven />

    <!--扫描springmvc bean-->
    <context:component-scan base-package="com.julyerr.springmvcdemo.controller"/>

    <!--spring mvc视图解析-->
    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver" p:prefix="/WEB-INF/views/" p:suffix=".jsp" />

</beans>
``` 

- **编写controller**

```java
@Controller
public class User1Controller {

    @RequestMapping("")
    public String Create(Model model) {
        return "create";
    }

    @RequestMapping("/save")
    public String Save(@ModelAttribute("form") User1 user, Model model) { 
        // user:视图层传给控制层的表单对象；model：控制层返回给视图层的对象
        model.addAttribute("user", user);
        return "detail";
    }
}
```

- **编写视图文件**
    在WEB-INF下新建views然后分别创建create.jsp和detail.jsp文件,上面所涉及的工程代码[参见](https://github.com/julyerr/springdemo/tree/master/src/main/java/com/julyerr/springmvcdemo)

---
#### 基于注解和java配置spring mvc

- **RootConfig.java**替代applicationContext.xml

```java
@ComponentScan(basePackages = "com.julyerr",
excludeFilters = {
//        spring mvc专门配置加载信息
        @ComponentScan.Filter(type= FilterType.ANNOTATION, value=EnableWebMvc.class),
        @ComponentScan.Filter(type=FilterType.ANNOTATION, value=Controller.class)
})
@Configuration
public class RootConfig {   
}
```

- **WebConfig.java**替代dispather-servlet.xml

```java
@Configuration
@EnableWebMvc
@ComponentScan(basePackages = "com.julyerr.springmvcdemo.controller")
public class WebConfig extends WebMvcConfigurerAdapter{
    /*
    * 配置JSP视图解析器
    * */
    @Bean
    public ViewResolver viewResolver(){
        InternalResourceViewResolver resourceViewResolver = new InternalResourceViewResolver();
        resourceViewResolver.setPrefix("/WEB-INF/views/");
        resourceViewResolver.setSuffix(".jsp");

        return resourceViewResolver;
    }
}
```

- **WebAppInitializer.java** 替代web.xml<br>
    **工作原理**<br>
    在Servlet 3.0环境中，容器会在类路径中查找实现`javax.servlet.ServletContainerInitializer`接口的类，如果能发现的话，就会用来配置Servlet容器。Spring用`SpringServletContainerInitializer`提供了该接口的实现，这个类反过来又会查找实现`WebApplicationInitializer`的类并将配置的任务交给它们来完成。Spring 3.2又引入了一个便利的`WebApplicationInitializer`基础实现，也就是`AbstractAnnotationConfigDispatcherServletInitializer`。

```java
public class WebXmlAppInitializer extends AbstractAnnotationConfigDispatcherServletInitializer {
    //    spring 容器配置
    @Override
    protected Class<?>[] getRootConfigClasses() {
        return new Class<?>[]{RootConfig.class};
    }

    //    spring mvc 配置
    @Override
    protected Class<?>[] getServletConfigClasses() {
        return new Class<?>[]{WebConfig.class};
    }

    //    映射关系
    @Override
    protected String[] getServletMappings() {
        return new String[]{"/"};
    }

    @Override
    public void onStartup(javax.servlet.ServletContext servletContext) throws ServletException {
        super.onStartup(servletContext);
    }
}
``` 

- **编写视图文件**
运行之前需要将WEB-INF/web.xml文件删除，不然报错` One or more listeners failed to start`，
基于javaConfig的代码文件[参见](https://github.com/julyerr/springdemo/tree/master/src/main/java/com/julyerr/springmvcdemo/javaConfig)

---

#### spring mvc常见使用
上面以demo的形式展示了spring mvc的基本配置，springmvc还有如下常见的使用方式，参考[原作者](http://blog.csdn.net/ZWX2445205419/article/details/52551648)的总结<br>

**跳转方式**<br>

- 服务器端跳转

![](/img/web/spring/mvc/forward.png)
```java
@RequestMapping("/hello2.do")
public String hello5(){
    return "forward:index.jsp";
}
```

- 重定向

![](/img/web/spring/mvc/redirect.png)
```java
@RequestMapping("/hello3.do")
public String hello6(){
    //重定向
    return "redirect:index.jsp";
}
```

- 视图解析

```java
@RequestMapping("/hello1.do")
public String hello4(){
    //转发
    return "hello";
}
```

**数据处理**<br>

- 提交的域和处理方法的参数名一致

![](/img/web/spring/mvc/paramSame.png)
```java
@RequestMapping("/hello.do")
public String hello(String name){
    System.out.println(name);
    return "redirect:index.jsp";
}
```

- 提交的域名称与函数中的参数名不一致

![](/img/web/spring/mvc/paramNotSame.png)
```java
@RequestMapping("/hello.do")
public String hello(@RequestParam("uname")String name){
    System.out.println(name);
    return "redirect:index.jsp";
}
```

- 提交一个对象

![](/img/web/spring/mvc/paramObj.png)
```java
@RequestMapping("/user.do")
public String user(User user){
    System.out.println(user);
    return "hello";
}
```

**restful风格的URL**<br>

```java
@RequestMapping("/delete/{uid}/{id}")
public String hello(@PathVariable int uid,@PathVariable int id){
    System.out.println("uid:"+uid);
    System.out.println("id:"+id);
    return "hello";
}
```

**将数据显示到UI层**<br>

- 通过ModelAndView，需要视图解析器

```java
@RequestMapping("/hello.do")
public ModelAndView hello(){
    ModelAndView mav = new ModelAndView();
    mav.addObject("msg", "hello");
    mav.setViewName("hello");
    return mav;
}
```    

- 通过ModelMap,不需要视图解析器 

```java
@RequestMapping("/hello.do")
public String hello(String name, ModelMap model){
    //相当于request.setAttribute("name",name);
    model.addAttribute("name", name);
    return "forward:index.jsp";
}
```    

**解决中文乱码**<br>
基于xml，在web.xml中配置

```xml
<filter>
<filter-name>CharacterEncodingFilter</filter-name>
<filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>
<init-param>
    <param-name>encoding</param-name>
    <param-value>utf-8</param-value>
</init-param>
</filter>
<filter-mapping>
<filter-name>CharacterEncodingFilter</filter-name>
<url-pattern>*</url-pattern>
</filter-mapping>
<!-- 过滤器放在servlet之前 -->
```

基于javaConfig配置，在onStartUp()函数中书写逻辑

```java
@Override
public void onStartup(ServletContext servletContext) throws ServletException {
    super.onStartup(servletContext);
    
    FilterRegistration.Dynamic encodingFilter = servletContext.addFilter("characterEncodingFilter", new CharacterEncodingFilter());
    encodingFilter.setInitParameter("encoding", "UTF-8");
    encodingFilter.setInitParameter("forceEncoding", "true");
    encodingFilter.addMappingForUrlPatterns(null, true, "/*");
    
}
```

**静态资源映射**<br>
xml方式（dispatcher-servlet.xml配置）

```xml
<mvc:resources mapping="/static/**" location="/static/"/>
```
javaConfig(WebConfig.java)

```java
@Override
public void addResourceHandlers(ResourceHandlerRegistry registry) {
    registry.addResourceHandler("/resources/**").addResourceLocations("/resources/");
}
```    

**实现文件上传**<br>
    主要总结基于xml的配置方式,基于javaConfig不太常用<br>
    实现文件上传，其实就是解析一个Mutipart请求。DispatchServlet自己并不负责去解析mutipart 请求，而是委托一个实现了MultipartResolver接口的类来解析mutipart请求。在Spring3.1之后Spring提供了两个现成的MultipartResolver接口的实现类

- CommonMutipartResolver: 利用Commons FileUpload来解析mutipart 请求
        部署的容器不是Servlet3.0，我们还可以使用CommonMutipartResolver
        在dispatcher-servlet.xml直接配置即可

```xml
<bean id="multipartResolver" class="org.springframework.web.multipart.commons.CommonsMultipartResolver">
       <property name="maxUploadSize" value="100000" />
       <property name="maxInMemorySize" value="100000" />
</bean>
```

- StandardServletMutipartResolver： 依赖Servlet3.0来解析mutipart请求

    - 首先在web.xml的springmvc的servket中配置
    - 然后在dispatcher-servlet.xml中配置

```xml
<multipart-config>
    <!--上传文件的临时路径，必须提前设置而且为绝对路径-->
    <location>/home/julyerr/github/springdemo/fileOut</location>
    <max-file-size>2097152</max-file-size>
    <max-request-size>4194304</max-request-size>
</multipart-config>
```

```xml
<bean id="multipartResolver" class="org.springframework.web.multipart.support.StandardServletMultipartResolver"/>
```      
    
实现多文件传输[参见](https://www.jianshu.com/p/96cc3e869646)<br>
    
**json格式数据返回**<br>
    导入jackson依赖的包
![](/img/web/spring/mvc/jsonPackages.png)    

```java
@Controller
public class JsonController {
    @RequestMapping("/json")
    @ResponseBody
    public List<User1> JsonUser() {
        List<User1> rt = new ArrayList<User1>();
        rt.add(new User1(1, "julyerr1"));
        rt.add(new User1(2, "julyerr2"));
        return rt;
    }
}
```

上面总结的是比较常用spring mvc使用方法，其他高级使用例如拦截器等后面有blog添加进来.
上面涉及的[代码参见](https://github.com/julyerr/springdemo/tree/master/src/main/java/com/julyerr/springmvcdemo).

---
### 参考资料
- [SpringMVC工作原理](https://www.jianshu.com/p/ce85b9e7d650)
- [Spring MVC原理及配置详解](http://blog.csdn.net/jianyuerensheng/article/details/51258942)
- [SpringMVC知识点总结](http://blog.csdn.net/ZWX2445205419/article/details/52551648)
- [告别xml——基于Java的Spring MVC配置](http://irmlab.ruc.edu.cn/2016/12/07/spring-java-config.html)
- [Spring MVC 上传文件(upload files)](http://blog.csdn.net/suifeng3051/article/details/51659731)