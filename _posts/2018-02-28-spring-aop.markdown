---
layout:     post
title:      "spring系列 AOP"
subtitle:   "spring系列 AOP"
date:       2018-02-27 6:00:00
author:     "julyerr"
header-img: "img/web/spring/aop/aop.jpeg"
header-mask: 0.5
catalog:    true
tags:
    - web
    - spring
    - AOP
---

>上篇[文章](http://julyerr.club/2018/02/27/spring-ioc/)总结了spring ioc内容，这篇总结
spring两大特性的另一者--AOP.

### AOP 原理

#### AOP简介
AOP(Aspect-Oriented Programming, 面向切面编程)是对传统OOP的补充，主要编程对象是切面(aspect)。<br>
**aop中几个基本概念**

- **切面(Aspect)** 横切关注点(跨越应用程序多个模块的功能)被模块化的特殊对象
- **通知(Advice)** 切面必须要完成的工作
- **目标(Target)** 被通知的对象
- **代理(Proxy)** 向目标对象应用通知之后创建的对象
- **连接点（Joinpoint）** 程序执行的某个特定位置：如类某个方法调用前、调用后、方法抛出异常后等。
- **切点（pointcut）** 连接点是程序类中客观存在的事务,AOP 通过切点定位到特定的连接点。
![](/img/web/spring/aop/aop-elems.png)

**aop的好处**<br>

- 将系统服务等功能独立出来，业务模块更加简洁；
- 降低代码的耦合程度，便于维护和升级

spring引入AOP之后，可以让容器中的对象都享有容器中的公共服务。<br>
AOP代理主要分为静态代理和动态代理，静态代理的代表为AspectJ；而动态代理则以Spring AOP为代表。

#### AspectJ编译时增强
AspectJ是静态代理的增强，所谓的静态代理就是AOP框架会在编译阶段生成AOP代理类，因此也称为编译时增强。
![](/img/web/spring/aop/aspectj.png)

#### 动态代理
AOP 拦截功能是通过java中动态代理实现的。<br>

**代理模式**<br>
给某个对象提供一个代理对象，并由代理对象控制对于原对象的访问，即客户不直接操控原对象，而是通过代理对象间接地操控原对象。
```java
public class ProxyDemo {
    public static void main(String args[]){
        RealSubject subject = new RealSubject();
        Proxy p = new Proxy(subject);
        p.request();
    }
}

interface Subject{
    void request();
}

class RealSubject implements Subject{
    public void request(){
        System.out.println("request");
    }
}

class Proxy implements Subject{
    private Subject subject;
    public Proxy(Subject subject){
        this.subject = subject;
    }
    public void request(){
        System.out.println("PreProcess");
        subject.request();
        System.out.println("PostProcess");
    }
}
```
代理模式是一种静态代理，在编译的时候就已经确定代理类将要代理谁；动态代理在运行的时候才知道
自己要代理谁。<br>

**动态代理两种方式**<br>

- **JDK 动态代理**<br>
由java内部的反射机制来实现的，但是被代理的类必须实现接口.<br>
动态代理主要涉及到`java.lang.reflect.Proxy`、`java.lang.reflect.InvocationHandler`两个类。
    - **Proxy**<br>
    ```java
    static Object newProxyInstance(ClassLoader loader,Class<?>[] interfaces,InvocationHandler h)
    ```
第一个参数是类加载器对象（即哪个类加载器来加载这个代理类到 JVM 的方法区），第二个参数是接口（表明你这个代理类需要实现哪些接口），第三个参数是调用处理器类实例（指定代理类中具体要干什么）.

    - **InvocationHandler**<br>
```java
invoke(Object proxy, Method method, Object[] args)
```
第一个参数是代理对象（表示哪个代理对象调用了method方法），第二个参数是 Method 对象（表示哪个方法被调用了），第三个参数是指定调用方法的参数。<br>

下面是一个demo
```java
package com.julyerr.interviews.aop;

interface Subject {
    void request();
}

package com.julyerr.interviews.aop;

class RealSubject implements Subject{
    public void request(){
        System.out.println("request");
    }
}

package com.julyerr.interviews.aop;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class JdkDynamicProxyDemo {
    public static void main(String[] args) {
        RealSubject realSubject = new RealSubject();    //1.创建委托对象
        ProxyHandler handler = new ProxyHandler(realSubject);   //2.创建调用处理器对象
        Subject proxySubject = (Subject) Proxy.newProxyInstance(RealSubject.class.getClassLoader(),
                RealSubject.class.getInterfaces(), handler);    //3.动态生成代理对象
        proxySubject.request(); //4.通过代理对象调用方法
    }
}


/**
 * 代理类的调用处理器
 */
class ProxyHandler implements InvocationHandler {
    private Subject subject;

    public ProxyHandler(Subject subject) {
        this.subject = subject;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args)
            throws Throwable {
        System.out.println("====before====");//定义预处理的工作，当然你也可以根据 method 的不同进行不同的预处理工作
        Object result = method.invoke(subject, args);
        System.out.println("====after====");
        return result;
    }
}

```
- **cglib动态代理**<br>
通过继承的方式做的动态代理，因此如果某个类被标记为final，那么它是无法使用CGLIB（Code Generation Library,是一个代码生成的类库，可以在运行时动态的生成某个类的子类)做动态代理的。<br>
    - **CGLIB的核心类**<br>

```java
net.sf.cglib.proxy.Enhancer  //主要的增强类
net.sf.cglib.proxy.MethodProxy //JDK的java.lang.reflect.Method类的代理类：
net.sf.cglib.proxy.MethodInterceptor  //主要的方法拦截类，它是Callback接口的子接口，需要用户实现
    //实现的子接口，第一个参数是代理对像，第二和第三个参数分别是拦截的方法和方法的参数。
    public Object intercept(Object object, java.lang.reflect.Method method,
Object[] args, MethodProxy proxy) throws Throwable;
```

以下是一个demo,需要引入cglib.jar和asm.jar（如果项目工程不是maven管理）
```java
package com.julyerr.interviews.aop.cglib;

public class SubjectDemo {
    public void request(){
        System.out.println("request");
    }
}

package com.julyerr.interviews.aop.cglib;

import net.sf.cglib.proxy.Enhancer;
import net.sf.cglib.proxy.MethodInterceptor;
import net.sf.cglib.proxy.MethodProxy;
import java.lang.reflect.Method;

public class CglibDynamicProxyDemo implements MethodInterceptor {
    @Override
    public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
        System.out.println("before "+methodProxy.getSuperName());
        Object o1 = methodProxy.invokeSuper(o,objects);
        System.out.println("after "+methodProxy.getSuperName());
        return o1;
    }

    public static void main(String[] args){
        CglibDynamicProxyDemo cglibDynamicProxyDemo = new CglibDynamicProxyDemo();

        Enhancer enhancer = new Enhancer();
        enhancer.setSuperclass(SubjectDemo.class);
        enhancer.setCallback(cglibDynamicProxyDemo);

        SubjectDemo subjectDemo = (SubjectDemo) enhancer.create();
        subjectDemo.request();
    }
}
```

**上面所涉及的[所有代码参见](https://github.com/julyerr/collections/tree/master/java/src/com/julyerr/interviews/aop)**<br>

---
### AOP在spring中使用
- **定义切入点函数**

```java
// 直接使用execution定义匹配表达式
//execution(<scope> <return-type> <fully-qualified-class-name>.*(parameters))
@After(value="execution(* com.zejian.spring.springAop.dao.UserDao.addUser(..))")
  public void after(){
      System.out.println("最终通知....");
  }

/**
 * 使用Pointcut定义切点，可以实现重用，实际中运用场景比较多
 */
@Pointcut("execution(* com.zejian.spring.springAop.dao.UserDao.addUser(..))")
private void myPointcut(){}

/**
 * 应用切入点函数
 */
@After(value="myPointcut()")
public void afterDemo(){
    System.out.println("最终通知....");
}  
```

- **切入指示符**
    - 通配符
        - .. 匹配方法中任意数量的参数 
        - \+  匹配给定类的任意子类
        - \*  匹配任意数量的字符   
    - 类型签名表达式 within(<type name>)

```java
//匹配com.zejian.dao包及其子包中所有类中的所有方法
@Pointcut("within(com.zejian.dao..*)")

//匹配UserDaoImpl类中所有方法
@Pointcut("within(com.zejian.dao.UserDaoImpl)")

//匹配UserDaoImpl类及其子类中所有方法
@Pointcut("within(com.zejian.dao.UserDaoImpl+)")

//匹配所有实现UserDao接口的类的所有方法
@Pointcut("within(com.zejian.dao.UserDao+)")
```

- 其他指示符(不太常用)
    - target ：用于匹配当前目标对象类型的执行方法；
    - @within：用于匹配所以持有指定注解类型内的方法；请与within是有区别的， within是用于匹配指定类型内的方法执行；
    - @annotation: 根据所应用的注解进行方法过滤
- **5中通知函数**
    - **前置通知@Before** 通知在目标函数执行前执行，通过joinPoint 参数，可以获取目标对象的信息,如类名称,方法参数,方法名称等，该参数是可选的    
    - **后置通知@AfterReturning**目标函数执行完成后执行可以获取到目标函数最终的返回值returnVal，当目标函数没有返回值时，returnVal将返回null。
```java
@AfterReturning(value="execution(* com.zejian.spring.springAop.dao.UserDao.*User(..))",returning = "returnVal")
public void AfterReturning(JoinPoint joinPoint,Object returnVal){
   System.out.println("我是后置通知...returnVal+"+returnVal);
}
```
    - **异常通知@AfterThrowing**  在异常时才会被触发，并由throwing来声明一个接收异常信息的变量
    - **最终通知@After** 类似于finally代码块，只要应用了无论什么情况下都会执行
    - **环绕通知@Around** 可以在目标方法前执行也可在目标方法之后执行,第一个参数必须是ProceedingJoinPoint，通过该对象的proceed()方法来执行目标函数，proceed()的返回值就是环绕通知的返回值
```java
@Around("execution(* com.zejian.spring.springAop.dao.UserDao.*User(..))")
public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
    System.out.println("我是环绕通知前....");
    //执行目标函数
    Object obj= (Object) joinPoint.proceed();
    System.out.println("我是环绕通知后....");
    return obj;
}
```

- **通知传递参数** 都可以将匹配的方法相应参数或对象自动传递给通知方法   

```java
@Before("execution(public * com.zejian..*.addUser(..)) && args(userId,..)")  
public void before(int userId) {  
    //调用addUser的方法时如果与addUser的参数匹配则会传递进来会传递进来
    System.out.println("userId:" + userId);  
}  
```

- **Aspect优先级** 同一个切面定义的通知函数会根据在类中的声明顺序执行，可以设置优先级（越小优先级越高）。
    - 实现 Ordered 接口, getOrder() 方法的返回值越小, 优先级越高；
    - 使用 @Order 注解, 序号出现在注解中

在spring中有两种使用AOP方式基于注解配置AOP、基于XML配置AOP。


**基于注解方式配置AOP**<br>

1. 使用注解@Aspect来定义一个切面，在切面中定义切入点(@Pointcut),通知类型(@Before, @AfterReturning,@After,@AfterThrowing,@Around).;
2. 开发需要被拦截的类;
3. 将切面配置到xml中。

[项目实例代码参见](https://github.com/julyerr/springdemo/tree/master/src/main/java/com/julyerr/aopdemo)

**基于XML配置AOP**<br>
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop.xsd">
       <bean id="logInterceptor" class="com.julyerr.aopdemo.aop.LogInterceptor"></bean>
    <aop:config>
        <aop:pointcut expression="execution(public * com.julyerr.aopdemo.service.*.add(..))"
                      id="servicePointcut"/>
        <aop:aspect id="logAspect" ref="logInterceptor">
            <aop:before method="before"  pointcut-ref="servicePointcut" />
        </aop:aspect>

    </aop:config>
</beans>
```

---
### 参考资料
- [Spring 容器AOP的实现原理——动态代理](http://wiki.jikexueyuan.com/project/ssh-noob-learning/dynamic-proxy.html)
- [代理模式及Java实现动态代理](https://www.jianshu.com/p/6f6bb2f0ece9)
- [Java动态代理的两种实现方法](http://lib.csdn.net/article/java/63500)
- [Spring学习之AOP(面向切面编程)](http://blog.51cto.com/s5650326/1717136)
- [关于 Spring AOP (AspectJ) 你该知晓的一切](http://blog.csdn.net/javazejian/article/details/56267036#神一样的aspectj-aop的领跑者)