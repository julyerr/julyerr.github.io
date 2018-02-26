---
layout:     post
title:      "spring系列 综述篇"
subtitle:   "spring系列 综述篇"
date:       2018-02-26 6:00:00
author:     "julyerr"
header-img: "img/web/spring/spring.png"
header-mask: 0.5
catalog:    true
tags:
    - web
    - spring
---

>前一阵子主要总结了cs和java中比较重要的内容，从这篇blog开始对应用开发使用到的技术作总结。本人比较喜欢web开发，java框架中ssm作为当下比较流行的开发框架，自然是必备技能之一。<br>
spring家族涉及内容较多，因此打算写一个系列专栏总结。水平尚浅，各方面sum up难免出错，欢迎大家吐槽，共同进步。本文很多内容摘抄自[1]，总结非常好。

#### web中常见术语
- **应用程序** 是能完成我们所需要功能的成品；
- **框架** 是能完成一定功能的半成品，比如我们可以使用框架进行购物网站开发；框架做一部分功能，我们自己做一部分功能，这样应用程序就创建出来了。而且框架规定了你在开发应用程序时的整体架构，提供了一些基础功能，还规定了类和对象的如何创建、如何协作等，从而简化我们开发，让我们专注于业务逻辑开发；
- **非侵入式设计** 从框架角度可以这样理解，无需继承框架提供的类，这种设计就可以看作是非侵入式设计，如果继承了这些框架类，就是侵入设计，如果以后想更换框架之前写过的代码几乎无法重用，如果非侵入式设计则之前写过的代码仍然可以继续使用。
- **轻量级&重量级** 轻量级是相对于重量级而言的，轻量级一般就是非入侵性的、所依赖的东西非常少、资源占用非常少、部署简单等等，其实就是比较容易使用，而重量级正好相反。
- **POJO（Plain Old Java Objects）**简单的Java对象，它可以包含业务逻辑或持久化逻辑，但不担当任何特殊角色且不继承或不实现任何其它Java框架的类或接口。
- **Bean** 一般指容器管理对象，在Spring中指Spring IoC容器管理对象
- **容器** 在日常生活中容器就是一种盛放东西的器具，从程序设计角度看就是装对象的的对象，因为存在放入、拿出等操作，所以容器还要管理对象的生命周期。
- **控制反转(IoC)** 即Inversion of Control，缩写为IoC，控制反转还有一个名字叫做依赖注入（Dependency Injection），就是由容器控制程序之间的关系，而非传统实现中，由程序代码直接操控。
- **面向切片（AOP）** 允许将应用的业务逻辑和系统级服务（例如审计(auditing)和事务(transaction)管理等）分离开来各自开发。

---
### spring 框架
简单来说，Spring是一个轻量级控制反转(IoC)和面向切片(AOP)的容器框架。

![](/img/web/spring/spring-framework.png)
Spring Framework差不多有20个模块组成，这些模块分为核心容器、数据访问/集成、Web、AOP、Instrumentation，消息传递和测试等。<br>

- **Core Container**<br>
	包含spring-beans、spring-core、spring-context、spring-expression四个方面
	- **spring-core和spring-beans**提供了框架的基础部分，包括反转控制和依赖注入功能。将所有应用程序对象及对象间关系由框架BeanFactory管理。
	- **spring-context**模块建立在core和bean模块提供坚实的基础上，集成Beans模块功能并添加资源绑定、数据验证、国际化、Java EE支持、容器生命周期、事件传播等；核心接口是ApplicationContext。
	- **spring-expression** 提供强大的表达式语言支持，支持访问和修改属性值，方法调用，支持访问及修改数组、容器和索引器，命名变量，支持算数和逻辑运算，支持从Spring 容器获取Bean，它也支持列表投影、选择和一般的列表聚合等。
- **AOP 、Instrumentation 、 Messaging**<br>	
    - **spring-aop** Spring AOP模块提供了符合 AOP Alliance规范的面向方面的编程（aspect-oriented programming）实现，提供比如日志记录、权限控制、性能统计等通用功能和业务逻辑分离的技术，并且能动态的把这些功能添加到需要的代码中；这样各专其职，降低业务逻辑和通用功能的耦合；
	- **spring-instrument** 在特定的应用程序服务器中支持类和类加载器的实现，比如Tomcat；
	- **Messaging** 从Spring Framework 4开始集成了MessageChannel, MessageHandler等，用于消息传递的基础
- **Data Access/Integration**<br>
	包括了JDBC、ORM、OXM、JMS和事务管理
	- **事务模块** 该模块用于Spring管理事务，只要是Spring管理对象都能得到Spring管理事务的好处，无需在代码中进行事务控制了，而且支持编程和声明性的事物管理;
	- **spring-jdbc** 提供了一个JBDC的样例模板，使用这些模板能消除传统冗长的JDBC编码还有必须的事务控制，而且能享受到Spring管理事务的好处;
	- **spring-orm** 提供与流行的“对象-关系”映射框架的无缝集成，包括Hibernate、JPA、Ibatiss等。而且可以使用Spring事务管理，无需额外控制事务;
	- **spring-oxm** 提供了一个对Object/XML映射实现，将java对象映射成XML数据，或者将XML数据映射成java对象，Object/XML映射实现包括JAXB、Castor、XMLBeans和XStream;
	- **spring-jms** 用于JMS(Java Messaging Service)，提供一套 “消息生产者、消息消费者”模板用于更加简单的使用JMS，JMS用于用于在两个应用程序之间，或分布式系统中发送消息，进行异步通信。

- **web**<br>
	包含了spring-web, spring-webmvc, spring-websocket, and spring-webmvc-portlet几个模块
	- **spring-web** 提供了基础的web功能。例如多文件上传、集成IoC容器、远程过程访问（RMI、Hessian、Burlap）以及Web Service支持，并提供一个RestTemplate类来提供方便的Restful services访问;
	- **spring-webmvc**  提供了一个Spring MVC Web框架和REST Web服务的实现。Spring的MVC框架提供了领域模型代码和Web表单之间分离，并与Spring框架的所有其他功能集成;
	- **spring-webmvc-portlet** 提供了在Portlet环境中使用MVC实现，并且反映了spring-webmvc模块的功能。

**典型应用场景**<br>

- Web应用场景
	![](/img/web/spring/spring-web-app.png)
- 远程访问应用场景
	![](/img/web/spring/spring-remote-app.png)

**使用spring好处**<br>	

- **轻量级的容器** 以集中的、自动化的方式进行应用程序对象创建和装配，负责对象创建和装配，管理对象生命周期，能组合成复杂的应用程序。Spring容器是非侵入式的（不需要依赖任何Spring特定类），而且完全采用POJOs进行开发，使应用程序更容易测试、更容易管理。而且核心JAR包非常小，Spring3.0.5不到1M，而且不需要依赖任何应用服务器，可以部署在任何环境（Java SE或Java EE）。
- **AOP** AOP是Aspect Oriented Programming的缩写，意思是面向切面编程，提供从另一个角度来考虑程序结构以完善面向对象编程（相对于OOP），即可以通过在编译期间、装载期间或运行期间实现在不修改源代码的情况下给程序动态添加功能的一种技术。通俗点说就是把可重用的功能提取出来，然后将这些通用功能在合适的时候织入到应用程序中；比如安全，日记记录，这些都是通用的功能，我们可以把它们提取出来，然后在程序执行的合适地方织入这些代码并执行它们，从而完成需要的功能并复用了这些功能。
- **简单的数据库事务管理** 在使用数据库的应用程序当中，自己管理数据库事务是一项很让人头疼的事，而且很容易出现错误，Spring支持可插入的事务管理支持，而且无需JEE环境支持，通过Spring管理事务可以把我们从事务管理中解放出来来专注业务逻辑。
- **JDBC抽象及ORM框架支持** Spring使JDBC更加容易使用；提供DAO（数据访问对象）支持，非常方便集成第三方ORM框架，比如Hibernate等；并且完全支持Spring事务和使用Spring提供的一致的异常体系。
- **灵活的Web层支持** pring本身提供一套非常强大的MVC框架，而且可以非常容易的与第三方MVC框架集成，比如Struts等。
简化各种技术集成：提供对Java Mail、任务调度、JMX、JMS、JNDI、EJB、动态语言、远程访问、Web Service等的集成。

---
	
**学习路线**<br>
Spring核心是IoC容器，所以一定要透彻理解什么是IoC容器，以及如何配置及使用容器，其他所有技术都是基于容器实现的；理解好IoC后，接下来是面向切面编程，首先还是明确概念，基本配置，最后是实现原理，接下来就是数据库事务管理，其实Spring管理事务是通过面向切面编程实现的，所以基础很重要，IoC容器和面向切面编程搞定后，其余都是基于这俩东西的实现，学起来就更加轻松了。

- Spring的Ioc
- Spring的AOP , AspectJ
- Spring的事务管理 , 三大框架的整合.

---
### 参考资料
[1]:https://www.jianshu.com/p/7b6a070119c7
- [Spring 学习之路](http://blog.csdn.net/column/details/15933.html?&page=1)
- [Spring框架简介](https://www.jianshu.com/p/7b6a070119c7)