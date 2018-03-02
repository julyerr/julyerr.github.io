---
layout:     post
title:      "spring系列 IOC"
subtitle:   "spring系列 IOC"
date:       2018-02-27 6:00:00
author:     "julyerr"
header-img: "img/web/spring/ioc/spring-ioc.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - web
    - spring
    - IoC
---

>spring ioc是spring框架的核心之处，本文就IOC的实现原理和IOC在spring应用进行总结,很多内容参考[1]和[2],原作者总结很不错。

### spring IOC原理

>IoC(Inversion Of Control) 反转资源获取的方向, 传统的资源查找方式要求组件向容器发起请求查找资源,使用IoC之后容器主动地将资源推送给它所管理的组件, 组件所要做的仅是选择一种合适的方式来接受资源。

---
#### IOC 容器
spring ioc容器能够通过配置文件实例化bean并解析bean之间的依赖关系；除此之外，还提供了 Bean 实例缓存、生命周期管理、 Bean实例代理、事件发布、资源装载等高级服务。<br>

BeanFactory 是面向Spring本身的基础设施，ApplicationContext面向开发人员。

- **BeanFactory**<br>
	![](/img/web/spring/ioc/bean-factory.jpeg)
	- **BeanDefinitionRegistry** Spring配置文件中每一个节点元素在Spring 容器里都通过一个 BeanDefinition 对象表示，它描述了 Bean 的配置信息。而 BeanDefinitionRegistry 接口提供了向容器手工注册 BeanDefinition 对象的方法。
	- **BeanFactory** 接口位于类结构树的顶端，它最主要的方法就是 getBean(String beanName)，该方法从容器中返回特定名称的 Bean，BeanFactory 的功能通过其他的接口得到不断扩展：
	- **ListableBeanFactory** 该接口定义了访问容器中Bean基本信息的若干方法，如查看Bean 的个数、获取某一类型 Bean 的配置名、查看容器中是否包括某一 Bean 等方法；
	- **HierarchicalBeanFactory** 父子级联 IoC 容器的接口，子容器可以通过接口方法访问父容器； 通过 HierarchicalBeanFactory 接口， Spring 的 IoC容器可以建立父子层级关联的容器体系，子容器可以访问父容器中的 Bean，但父容器不能访问子容器的Bean。Spring使用父子容器实现了很多功能，比如在 Spring MVC 中，展现层 Bean 位于一个子容器中，而业务层和持久层的 Bean 位于父容器中。这样，展现层 Bean 就可以引用业务层和持久层的 Bean，而业务层和持久层的 Bean 则看不到展现层的 Bean。
	- **ConfigurableBeanFactory** 是一个重要的接口，增强了 IoC容器的可定制性，它定义了设置类装载器、属性编辑器、容器初始化后置处理器等方法；
	- **AutowireCapableBeanFactory** 定义了将容器中的 Bean 按某种规则（如按名字匹配、按类型匹配等）进行自动装配的方法；
	- **SingletonBeanRegistry** 定义了允许在运行期间向容器注册单实例 Bean 的方法；

- **ApplicationContext**<br>
	在BeanFactory 中，很多功能需要以编程的方式实现，而在 ApplicationContext 中则可以通过配置的方式实现。
	![](/img/web/spring/ioc/application-context.jpeg)
	- **ApplicationEventPublisher** 让容器拥有发布应用上下文事件的功能，包括容器启动事件、关闭事件等。实现了 ApplicationListener 事件监听接口的 Bean 可以接收到容器事件 ， 并对事件进行响应处理 。 在 ApplicationContext 抽象实现类AbstractApplicationContext 中，我们可以发现存在一个ApplicationEventMulticaster，它负责保存所有监听器，以便在容器产生上下文事件时通知这些事件监听者。
	- **MessageSource** 为应用提供 i18n 国际化消息访问的功能；
	- **ResourcePatternResolver** 所有 ApplicationContext 实现类都实现了类似于PathMatchingResourcePatternResolver 的功能，可以通过带前缀的 Ant 风格的资源文件路径装载 Spring 的配置文件。
	- **LifeCycle** 该接口是 Spring 2.0 加入的，该接口提供了 start()和 stop()两个方法，主要用于控制异步处理过程。在具体使用时，该接口同时被 ApplicationContext 实现及具体 Bean 实现， ApplicationContext 会将 start/stop 的信息传递给容器中所有实现了该接口的 Bean，以达到管理和控制 JMX、任务调度等目的。

**ConfigurableApplicationContext**扩展于ApplicationContext，它新增加了两个主要的方法： refresh()和 close()，让 ApplicationContext 具有启动、刷新和关闭应用上下文的能力。在应用上下文关闭的情况下调用 refresh()即可启动应用上下文，在已经启动的状态下，调用 refresh()则清除缓存并重新装载配置信息，而调用close()则可关闭应用上下文。这些接口方法为容器的控制管理带来了便利，但作为开发者，我们并不需要过多关心这些方法。<br>
**ClassPathXmlApplicationContext**默认从类路径加载配置文件<br>
**FileSystemXmlApplicationContext**默认从文件系统中装载配置文件

- **WebApplicationContext**<br>
	WebApplicationContext 是专门为 Web 应用准备的，它允许从相对于 Web 根目录的路径中装载配置文件完成初始化工作。
	![](/img/web/spring/ioc/webApplication-context.jpeg)
	web容器需要为web应用提供全局context即ServletContext,可以在 web.xml 中配置自启动的 Servlet 或定义 Web 容器监听器（ ServletContextListener），借助这两者中的任何一个就可以完成启动 Spring Web 应用上下文的工作。Spring 分别提供了用于启动 WebApplicationContext 的 Servlet 和 Web 容器监听器：`org.springframework.web.context.ContextLoaderServlet`,
	`org.springframework.web.context.ContextLoaderListener`.<br>
	WebApplicationContext是一个接口类，具体实现类是XmlWebApplicationContext，这个就是spring的IoC容器，对应的Bean定义的配置由web.xml中的context-param标签指定;IoC容器初始化完毕之后，spring容器以`WebApplicationContext.ROOTWEBAPPLICATIONCONTEXTATTRIBUTE`为属性Key，将其存储到ServletContext中便于获取
	![](/img/web/spring/ioc/web-spring-context.jpeg)
	contextLoaderListener监听器初始化完毕后，开始初始化web.xml中配置的Servlet。这个servlet可以配置多个，以最常见的DispatcherServlet为例（SpringMVC），这个servlet实际上是一个标准的前端控制器，用以转发、匹配、处理每个servlet请求。<br>DispatcherServlet上下文在初始化的时候会建立自己的IoC上下文容器，用以持有spring mvc相关的bean，这个servlet自己持有的上下文默认实现类也是XmlWebApplicationContext。在建立DispatcherServlet自己的IoC上下文时，会利用`WebApplicationContext.ROOTWEBAPPLICATIONCONTEXTATTRIBUTE`先从ServletContext中获取之前的根上下文(即WebApplicationContext)作为自己上下文的parent上下文。有了这个parent上下文之后，再初始化自己持有的上下文（这个DispatcherServlet初始化自己上下文的工作在其initStrategies方法中可以看到，大概的工作就是初始化处理器映射、视图解析等）。<br>
	初始化完毕后，spring以与servlet的名字相关(此处不是简单的以servlet名为Key，而是通过一些转换)的属性为属性Key，也将其存到ServletContext中，以便后续使用。这样每个servlet就持有自己的上下文，即拥有自己独立的bean空间，同时各个servlet共享相同的bean，即根上下文定义的那些bean。

---
#### Bean加载和生命周期

**Bean加载**<br>
![](/img/web/spring/ioc/bean-load.jpeg)

- ResourceLoader从存储介质中加载Spring配置信息，并使用Resource表示这个配置文件的资源；
- BeanDefinitionReader读取Resource所指向的配置文件资源，然后解析配置文件。配置文件中每一个解析成一个BeanDefinition对象，并保存到BeanDefinitionRegistry中；
- 容器扫描BeanDefinitionRegistry中的BeanDefinition，使用Java的反射机制自动识别出Bean工厂后处理后器（实现BeanFactoryPostProcessor接口）的Bean，然后调用这些Bean工厂后处理器对BeanDefinitionRegistry中的BeanDefinition进行加工处理。主要完成以下两项工作：
	- 对使用到占位符的元素标签进行解析，得到最终的配置值，这意味对一些半成品式的BeanDefinition对象进行加工处理并得到成品的BeanDefinition对象；
	- 对BeanDefinitionRegistry中的BeanDefinition进行扫描，通过Java反射机制找出所有属性编辑器的Bean（实现java.beans.PropertyEditor接口的Bean），并自动将它们注册到Spring容器的属性编辑器注册表中（PropertyEditorRegistry）；<br>
	**notes**<br>
	Spring 在 DefaultSingletonBeanRegistry 类中提供了一个用于缓存单实例 Bean 的缓存器，它是一个用 HashMap 实现的缓存器，单实例的 Bean 以 beanName 为键保存在这个HashMap 中。
- Spring容器从BeanDefinitionRegistry中取出加工后的BeanDefinition，并调用InstantiationStrategy着手进行Bean实例化的工作；
- 在实例化Bean时，Spring容器使用BeanWrapper对Bean进行封装，BeanWrapper提供了很多以Java反射机制操作Bean的方法，它将结合该Bean的BeanDefinition以及容器中属性编辑器，完成Bean属性的设置工作；
- 利用容器中注册的Bean后处理器（实现BeanPostProcessor接口的Bean）对已经完成属性设置工作的Bean进行后续加工，直接装配出一个准备就绪的Bean。

**生命周期**<br>

- 实例化;  
- 设置属性值;  
- 如果实现了BeanNameAware接口,调用setBeanName设置Bean的ID或者Name;  
- 如果实现BeanFactoryAware接口,调用setBeanFactory 设置BeanFactory;  
- 如果实现ApplicationContextAware,调用setApplicationContext设置ApplicationContext  
- 调用BeanPostProcessor的预先初始化方法, BeanPostProcessor 在 Spring 框架中占有重要的地位，为容器提供对 Bean 进行后续加工处理的切入点， Spring 容器所提供的各种“神奇功能”（如 AOP，动态代理等）都通过 BeanPostProcessor 实施;  
- 调用InitializingBean的afterPropertiesSet()方法;  
- 调用定制init-method方法；  
- 调用BeanPostProcessor的后初始化方法;  

**Spring容器关闭过程**<br>

- 调用DisposableBean的destroy();  
- 调用定制的destroy-method方法;

**pring 后置处理器BeanFactoryPostProcessor和BeanPostProcessor的用法和区别**<br>

- BeanFactoryPostProcessor：对容器本身进行处理，并总是在容器实例化其他任何Bean之前读取配置文件的元数据并可能修改
- BeanPostProcessor：即当Spring容器实例化Bean实例之后进行的增强处理。

**bean作用范围**<br>

- scope = "prototype" 将Bean 返回给调用者，调用者负责 Bean 后续生命的管理， Spring 不再管理这个 Bean 的生命周期。
- scope = "singleton" 将Bean 放入到 Spring IoC 容器的缓存池中，并将 Bean引用返回给调用者， Spring 继续对这些 Bean 进行后续的生命管理

---
### spring ioc 应用

#### 不同方式配置bean比较
spring提供了基于XML、基于注解、基于JAVA类、基于Groovy四种方式配置bean

- 基于XML配置 Bean实现类来源于第三方类库，如DataSource，JdbcTemplate等，类中注解和代码耦合性过高，为了维护和升级方便，通过XML配置方式较好;
- 基于注解配置 Bean的实现类是当前项目开发的，可以直接在Java类中使用基于注解的配置
- 基于Java类配置 可以通过代码方式控制Bean初始化的整体逻辑，适用于Bean实例化逻辑比较复杂的情况中
- 基于Groovy的配置 通过Groovy脚本灵活控制Bean初始化的过程，适用于bean逻辑较为复杂的情况当中
实际项目开发中，DataSource、SessionFactory等资源Bean通过XML方式配置，其他bean常采用注解方式配置和
JAVA类配置方式。

![](/img/web/spring/ioc/bean-config-ways.png)

[1]以demo的方式总结了常见的bean基于XML的配置方式，如下
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xmlns:util="http://www.springframework.org/schema/util"
 xmlns:p="http://www.springframework.org/schema/p"
 xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
  http://www.springframework.org/schema/util http://www.springframework.org/schema/util/spring-util-4.0.xsd">
  
 <!-- 配置一个 bean 一个bean标签代表给容器添加了一个对象.class用全类名表示通过反射方式实例化对象,所以类中需要一个无参的构造函数,-->
 <bean id="helloWorld" class="com.atguigu.spring.helloworld.HelloWorld">
  <!-- 为属性赋值 -->
  <property name="user" value="Jerry"></property>
 </bean>
  
 <!-- 配置一个 bean -->
 <bean id="helloWorld2" class="com.atguigu.spring.helloworld.HelloWorld">
  <!-- 为属性赋值 -->
  <!-- 通过属性注入: 通过 setter 方法注入属性值 -->
  <property name="user" value="Tom"></property>
 </bean>
  
 <!-- 通过构造器注入属性值 -->
 <bean id="helloWorld3" class="com.atguigu.spring.helloworld.HelloWorld">
  <!-- 要求: 在 Bean 中必须有对应的构造器.  -->
  <constructor-arg value="Mike"></constructor-arg>
 </bean>
  
 <!-- 若一个 bean 有多个构造器, 如何通过构造器来为 bean 的属性赋值 -->
 <!-- 可以根据 index 和 value 进行更加精确的定位. (了解) -->
 <bean id="car" class="com.atguigu.spring.helloworld.Car">
  <constructor-arg value="KUGA" index="1"></constructor-arg>
  <constructor-arg value="ChangAnFord" index="0"></constructor-arg>
  <constructor-arg value="250000" type="float"></constructor-arg>
 </bean>
  
 <bean id="car2" class="com.atguigu.spring.helloworld.Car">
  <constructor-arg value="ChangAnMazda"></constructor-arg>
  <!-- 若字面值中包含特殊字符, 则可以使用 CDATA 来进行赋值. (了解) -->
  <constructor-arg>
   <value><![CDATA[<ATARZA>]]></value>
  </constructor-arg>
  <constructor-arg value="180" type="int"></constructor-arg>
 </bean>
  
 <!-- 配置 bean -->
 <bean id="dao5" class="com.atguigu.spring.ref.Dao"></bean>
 <bean id="service" class="com.atguigu.spring.ref.Service">
  <!-- 引用类型用ref -->
  <property name="dao" ref="dao5"></property>
 </bean>
  
 <!-- 用bean标签来配置内部bean -->
 <bean id="service2" class="com.atguigu.spring.ref.Service">
  <property name="dao">
   <!-- 内部 bean, 类似于匿名内部类对象. 不能被外部的 bean 来引用, 也没有必要设置 id 属性 -->
   <bean class="com.atguigu.spring.ref.Dao">
    <property name="dataSource" value="c3p0"></property>
   </bean>
  </property>
 </bean>
  
 <bean id="action" class="com.atguigu.spring.ref.Action">
  <property name="service" ref="service2"></property>
  <!-- 设置级联属性(了解) -->
  <property name="service.dao.dataSource" value="DBCP2"></property>
 </bean>
  
 <bean id="dao2" class="com.atguigu.spring.ref.Dao">
  <!-- 为 Dao 的 dataSource 属性赋值为 null, 若某一个 bean 的属性值不是 null, 使用时需要为其设置为 null(了解) -->
  <property name="dataSource"><null/></property>
 </bean>
  
 <!-- 装配集合属性 -->
 <bean id="user" class="com.atguigu.spring.helloworld.User">
  <property name="userName" value="Jack"></property>
  <property name="cars">
   <!-- 集合属性就用个list标签 -->
   <list>
    <ref bean="car"/>
    <ref bean="car2"/>
   </list>
  </property>
 </bean>
  
 <!-- 用util命名空间将一个集合作为一个工具,其他类可以指向它 -->
 <util:list id="cars">
  <ref bean="car"/>
  <ref bean="car2"/>
 </util:list>
  
 <bean id="user2" class="com.atguigu.spring.helloworld.User">
  <property name="userName" value="Rose"></property>
  <!-- 引用外部声明的 list -->
  <property name="cars" ref="cars"></property>
 </bean>
 <!--使用p命名空间,能简化书写-->
 <bean id="user3" class="com.atguigu.spring.helloworld.User"
  p:cars-ref="cars" p:userName="Titannic"></bean>
   
 <!-- 用parent可以在配置文件中继承配置 --> 
 <bean id="user4" parent="user" p:userName="Bob"></bean>
  
 <bean id="user6" parent="user" p:userName="维多利亚"></bean>
  
 <!--depends-on,那么创建这个对象之前必须先创建好depengs-on的对象 --> 
 <bean id="user5" parent="user" p:userName="Backham" depends-on="user6"></bean>
  
</beans>
 
 <!-- 自动装配: 只声明 bean, 而把 bean 之间的关系交给 IOC 容器来完成 -->
 <!--  
  byType: 根据类型进行自动装配. 但要求 IOC 容器中只有一个类型对应的 bean, 若有多个则无法完成自动装配.
  byName: 若属性名和某一个 bean 的 id 名一致, 即可完成自动装配. 若没有 id 一致的, 则无法完成自动装配
 -->
 <!-- 在使用 XML 配置时, 自动转配用的不多. 但在基于 注解 的配置时, 自动装配使用的较多.  -->
 <bean id="dao" class="com.atguigu.spring.ref.Dao">
  <property name="dataSource" value="C3P0"></property>    
 </bean>
  
 <!-- 默认情况下 bean 是单例的! -->
 <!-- 但有的时候, bean 就不能使单例的. 例如: Struts2 的 Action 就不是单例的! 可以通过 scope 属性来指定 bean 的作用域 -->
 <!--  
  prototype: 原型的. 每次调用 getBean 方法都会返回一个新的 bean. 且在第一次调用 getBean 方法时才创建实例
  singleton: 单例的. 每次调用 getBean 方法都会返回同一个 bean. 且在 IOC 容器初始化时即创建 bean 的实例. 默认值 
 -->
 <bean id="dao2" class="com.atguigu.spring.ref.Dao" scope="prototype"></bean>
  
 <bean id="service" class="com.atguigu.spring.ref.Service" autowire="byName"></bean>
  
 <bean id="action" class="com.atguigu.spring.ref.Action" autowire="byType"></bean>
  
 <!-- 因为有些对象的属性是需要改变的,为了维护的方便,将配置信息写在外部的资源文件当中
      导入classpath下名字叫db.properties的资源文件 -->
 <context:property-placeholder location="classpath:db.properties"/>
  
 <!-- 配置数据源 用${配置文件中的属性名}引入-->
 <bean id="dataSource" class="com.mchange.v2.c3p0.ComboPooledDataSource">
  <property name="user" value="${jdbc.user}"></property>
  <property name="password" value="${jdbc.password}"></property>
  <property name="driverClass" value="${jdbc.driverClass}"></property>
  <property name="jdbcUrl" value="${jdbc.jdbcUrl}"></property>
   
  <property name="initialPoolSize" value="${jdbc.initPoolSize}"></property>
  <property name="maxPoolSize" value="${jdbc.maxPoolSize}"></property>
 </bean>
  
 <!--spring表达式语言SpEL:使用 #{…} 作为定界符，所有在大框号中的字符都将被认为是 SpEL
 可以为属性进行动态的赋值,
 调用静态方法或静态属性：通过 T() 调用一个类的静态方法，它将返回一个 Class Object，
 然后 再调用相应的方法或属性
 支持运算符
 引用bean,和bean的属性和方法 -->
 <bean id="girl" class="com.atguigu.spring.helloworld.User">
  <property name="userName" value="周迅"></property>
 </bean>
  
 <bean id="boy" class="com.atguigu.spring.helloworld.User" init-method="init" destroy-method="destroy">
  <property name="userName" value="#{T(java.lang.MATH).PI*20}"></property>
  <property name="userName" value="高胜远"></property>
  <property name="wifeName" value="#{girl.userName}"></property>
 </bean>
  
 <!-- 配置 bean 后置处理器: 不需要配置 id 属性, IOC 容器会识别到他是一个 bean 后置处理器, 并调用其方法 -->
 <bean class="com.atguigu.spring.ref.MyBeanPostProcessor"></bean>
```

**Bean 实例化方式**<br>
上面的demo展示了无参数的构造器实例化，spring还支持静态工厂实例化和实例工厂实例化两种方式
![](/img/web/spring/ioc/staticFac.png)
![](/img/web/spring/ioc/ins-fac.png)
![](/img/web/spring/ioc/fac-imp.png)
不太常用的factoryBean方式配置bean
![](/img/web/spring/ioc/factory-bean.png)
![](/img/web/spring/ioc/factory-bean-usage.png)

---
#### 常见基于注解方式的配置使用
- @Configuration 作用于类上，说明此类相当于一个xml配置文件；
- @ComponentScan(basePackages="xxx") 配置扫描包
- @Bean 作用于方法上，相当于xml配置中的<bean>；
- @Component 描述Spring框架中Bean
- @Respository 用于对DAO实现类进行标注
- @Service 用于对Service实现类进行标注
- @Controller 用于对Controller实现类进行标注
- @Autowired 给属性加这个注解,spring就会自动给这个属性赋值,如果出现多个符合条件的情况，允许@Qualifiter已指定注入Bean的名称
	
**读取外部的资源配置文件**<br>
@PropertySource可以指定读取的配置文件，通过@Value注解获取值
```java
@PropertySource(value={"classpath:jdbc.properties","xxx"},ignoreResourceNotFound=true)
@Configuration
@ComponentScan(basePackages="xxx")
@PropertySource(value={"classpath:jdbc.properties","xxx"},ignoreResourceNotFound=true)
public class SpringConfig {

    @Value("${jdbc.url}")
    private String jdbcUrl;
}
```
关于数据库连接池等高级配置使用后面专门的blog详细介绍。


---
### 参考资料
[1]:http://blog.51cto.com/s5650326/1717012
[2]:https://www.jianshu.com/p/9fe5a3c25ab6
- [Spring学习之IOC](http://blog.51cto.com/s5650326/1717012)
- [Spring IOC原理总结](https://www.jianshu.com/p/9fe5a3c25ab6)
- [Spring IOC知识点总结](http://blog.csdn.net/Java_Jsp_Ssh/article/details/78516023)
- [Spring-不同配置方式的比较](http://blog.csdn.net/yangshangwei/article/details/76742165)