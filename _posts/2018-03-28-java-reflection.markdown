---
layout:     post
title:      "java 反射简析和使用"
subtitle:   "java 反射简析和使用"
date:       2018-03-28 12:00:00
author:     "julyerr"
header-img: "img/lib/reflection/reflection.png"
header-mask: 0.5
catalog: 	true
tags:
    - java
---

>隔了一阵子没有更新blog，最近忙于很多公司的在线编程测试。哇，真的是被虐，由于没有acm的刷题经验，自己在牛客网上刷题的次数也比较少，头条、网易等公司编程题没有做出多少来。。。只能等等秋招了，也给自己提了个醒，需要花更多的时间在刷题上，然后做更多的总结，后面也会添加相关的blog，介绍在牛客网上觉得比较典型的题目并且总结常见的方法。好了，下面开始正题

### 反射概念

通俗地讲，反射就是java提供的一种机制，允许程序在运行的时候获取任意一个类的属性和方法。<br>

先简单分析反射实现原理（下面有更为详细的介绍），针对每个class，jvm将其加载到内存中，便保存了该类的方法、属性等；反射提供的api便封装了对class的常见操作。<br>

为什么要提供这一种机制呢？试想，以前我们在程序中新建一个对象，需要手动new；但是还有一些场合，需要程序根据外部条件，自动去加载类，生成对象并且调用方法，有了反射方便了许多。

### 反射常见api

**反射提供的功能**

- 在运行时判断任意一个对象所属的类
- 在运行时构造任意一个类的对象
- 在运行时判断任意一个类所具有的成员变量和方法
- 在运行时调用任意一个对象的方法

**涉及的常见类**

- Class类：代表一个类
- Field 类：代表类的成员变量（成员变量也称为类的属性） 
- Method类：代表类的方法
- Constructor 类：代表类的构造方法 
- Array类：提供了动态创建数组，以及访问数组的元素的静态方法

Class作为核心类存在，**获取Class对象如下**

- 使用Class的静态方法forName():例如:Class.forName(“java.lang.Class”); 
- 使用XXX.Class语法:例如:String.Class； 
- 使用具体某个对象.getClass()方法（最为常用）

**Class的常用方法**

- getName()：获得类的完整名字 
- getFields()：获得类的public类型的属性。
- getDeclaredFields()：获得类的所有属性 
- getMethods()：获得类的public类型的方法 
- getDeclaredMethods()：获得类的所有方法 
- getMethod(String name, Class[] parameterTypes)：获得类的特定方法，name参数指定方法的名字parameterTypes参数指定方法的参数类型 
- getConstructors()：获得类的public类型的构造方法
- getConstructor(Class[] parameterTypes)：获得类的特定构造方法，parameterTypes参数指定构造方法的参数类型
- newInstance()：通过类的不带参数的构造方法创建这个类的一个对象

### 结合demo，两种使用方式


**反射调用方法**

```java
public class AccessMethod {
    public int sum(int a,int b){
        return a+b;
    }

    public String addr(String str){
        return "this is the "+str;
    }

    public static void main(String[] args) throws Exception {
        Class<?> classType = AccessMethod.class;

        Constructor<?> constructor = classType.getConstructor(new Class[]{});
//        新建对象实例
        Object object = constructor.newInstance(new Object[]{});
//        获取对应的方法
        Method method = classType.getMethod("sum", int.class, int.class);
//        执行结果
        Object result1 = method.invoke(object,1,2);
        System.out.println((Integer)result1);

        method = classType.getMethod("addr", String.class);
        Object result2 = method.invoke(object,"julyerr");
        System.out.println((String)result2);

    }
}
```

**反射访问私有属性**（实际运用中可能产生安全问题）

```java
public class AccessPrivate {
    private String name = "julyerr";

    private String setName(String newName) {
        name = newName;
        return "this is :" + name;
    }

    private String getName() {
        return name;
    }

    public static void main(String[] args) throws Exception {
        AccessPrivate accessPrivate = new AccessPrivate();
        Class<?> classType = accessPrivate.getClass();

//        访问私有方法
        Method method = classType.getDeclaredMethod("setName", String.class);
        method.setAccessible(true);

        Object object = method.invoke(accessPrivate, "julyerr1");
        System.out.println((String) object);

//        方法私有属性
        Field field = classType.getDeclaredField("name");
        field.setAccessible(true);
//        直接设置属性
        field.set(accessPrivate, "julyerr2");

        method = classType.getDeclaredMethod("getName");
        System.out.println((String) method.invoke(accessPrivate));
    }
}
```

完整代码[参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/reflect)

---
### 反射的原理

由上可知，Field对应成员变量，Method对应方法，两者工作原理类似，下面以Method对象分析反射执行过程<br>

#### Method对象的生成

![](/img/lib/reflection/method-create.png)

Class对象里维护着该类的所有Method，Field，Constructor等信息（也被称为根对象）。每次getMethod获取到的Method对象都持有对根对象的引用，因为一些重量级的Method的成员变量（主要是MethodAccessor），我们不希望每次创建Method对象都要重新初始化，于是所有代表同一个方法的Method对象都共享着根对象的MethodAccessor，每一次创建都会调用根对象的copy方法复制一份

```java
Method copy() {
        Method res = new Method(clazz, name, parameterTypes, returnType,
                exceptionTypes, modifiers, slot, signature,
                annotations, parameterAnnotations, annotationDefault);
        res.root = this;
        res.methodAccessor = methodAccessor;
        return res;
    }
```

#### Method调用invoke()

![](/img/lib/reflection/invoke-process.png)

调用Method.invoke之后，会直接去调MethodAccessor.invoke。MethodAccessor就是上面提到的所有同名method共享的一个实例，由ReflectionFactory创建。创建机制采用了一种名为inflation的方式（JDK1.4之后）：如果该方法的累计调用次数<=15，会创建出NativeMethodAccessorImpl，它的实现就是直接调用native方法实现反射；如果该方法的累计调用次数>15，会由java代码创建出字节码组装而成的MethodAccessorImpl,创建出的字节码大致如下

```java
public class GeneratedMethodAccessor1 extends MethodAccessorImpl {    
    public Object invoke(Object obj, Object[] args)  throws Exception {
        try {
            MyClass target = (MyClass) obj;
            String arg0 = (String) args[0];
            target.myMethod(arg0);
        } catch (Throwable t) {
            throw new InvocationTargetException(t);
        }
    }
}

```

调用次数较少时，使用native方式初始化更快；但是随着调用次数的增加，每次反射都使用JNI跨越native边界会对优化有阻碍作用，便切换成Java实现的版本，来优化未来可能的更频繁的反射调用。

---
### 参考资料
- [Java中反射机制（Reflection）](https://blog.csdn.net/shengzhu1/article/details/73013506)
- [Java反射原理简析](http://www.fanyilun.me/2015/10/29/Java%E5%8F%8D%E5%B0%84%E5%8E%9F%E7%90%86/)