---
layout:     post
title:      "《java并发编程实战》线程安全性以及对象发布"
subtitle:   "《java并发编程》线程安全性以及对象发布"
date:       2018-04-04 12:00:00
author:     "julyerr"
header-img: "img/lib/concurrent/concurrent.png"
header-mask: 0.5
catalog: 	true
tags:
    - concurrent
---

>这一阵子重读了《java并发编程实战》[这本书](https://github.com/julyerr/Java_Books)，感觉收获还是挺大的，打算通过博客的形式将内容梳理成系列的读书笔记。一方面更加清楚的理清文章脉络，一方面也希望给大家在并发编程方面有点帮助。<br>

java方面有很多值得啃的书，下面是《java并发编程实战》的目录

![](/img/lib/concurrent/index.png)

本文就java并发编程中一些基本概念和发布安全对象等内容进行总结。


#### 使用多线程需要考虑的问题

**线程优势**

- 充分发挥处理器处理能力，线程作为任务的调度单元，多个线程同时能够在多个cpu上运行；
- 建模简单性，为模型中多种类型的任务分配专门的线程进行处理，一定程度降低了开发的难度；
- 异步事件简化处理，多个客户端向服务器发起处理请求，单线程为了提高效率必须使用非阻塞io，但是使用多线程，每个线程可以处理一个请求，对该请求使用同步io，减低开发难度；
- 响应灵敏用户界面，和cs模式类似，界面程序有一个主事件循环线程，对于需要花费较长时间的请求，可以建立一个新线程独立进行处理，主线程可以继续响应用户请求。

**线程风险**

- 安全性，多个线程对变量的访问和修改不可预测，会出现各种错误结果；
- 活跃性，多线程之间使用锁进行互斥，锁的不正当使用，导致死锁、饥饿、活锁等问题；
- 性能问题，多个线程上下文的频繁切换给系统带来较大的开销。

---
#### 多线程中的一些概念

**安全性**<br>
可以理解为正确性，程序在多线程环境下依然能够保证正确运行，不会出现错误。<br>
**原子性**<br>
一组操作要么全部执行，要么全不执行。破坏原子性常见的竞态条件：先检查后执行，如下一个demo

```java
public class UnsageCachingFactorizer implements Servlet {
    private final AtomicReference<BigInteger> lastNumber = new AtomicReference<>();
    private final AtomicReference<BigInteger[]> lastFactors = new AtomicReference<>();

    @Override
    public void service(ServletRequest servletRequest, ServletResponse servletResponse) throws ServletException, IOException {
        BigInteger i = extractFromRequest(servletRequest);
        if (i.equals(lastNumber.get())) {
            encodeIntoResponse(servletResponse, lastFactors.get());
        } else {
            BigInteger[] factors = factor(i);
    //            依然不能保证线程的安全性
            lastNumber.set(i);
            lastFactors.set(factors);
            encodeIntoResponse(servletResponse, factors);
        }
    }
}
``` 

虽然lastNumber和lastFactors是线程安全的对象，但是两个赋值过程应该是原子性的。<br>

**加锁**

- **内置锁** synchronized、Lock等
- **重入** 获取锁的粒度是"线程"而不是"调用"，一个线程获取到某个对象的锁，去执行对象的其他同步方法不要求再次获取锁操作

```java
public class ReentrantDemo {
    public synchronized void doSomething(){}
}

public class ReentrantDemoChild extends ReentrantDemo {
    public synchronized void doSomething() {
        System.out.println("in child");
        //可以成功访问，如果不能重入的话可能发生死锁的现象
        super.doSomething();
    }
}
```

**活跃性与性能**<br>
线程同步和并发是两个相对互斥的概念，同步性较高并发性便较低；反之，亦然。需要在保证线程安全的前提下，尽可能少使用同步，提高程序的并发性。

**对象的可见性**<br>
保证一个线程对某个对象或者变量操作的时候，其他的线程都能够及时看到这种变化。
可以通过加锁和对使用volatile关键字进行约束。对于非volatile类型的long和double变量，jvm允许将64位读操作或写操作分解为两个32位操作

---
#### 线程封闭
通常有下面三种封闭的方式

- Ad-hoc 由程序实现线程的封闭性
- 栈封闭 局部变量封装在执行线程的私有栈中
- ThreadLocal 使用类似map<thread,val>的形式为不同的线程保存不同的变量

例如下面使用ThreadLocal保证多线程对数据库建立连接访问的安全性

```java
private static ThreadLocal<Connection> connectionHolder =
    new ThreadLocal<Connection>(){
        public Connection initialValue(){
            return DriverManager.getConnection(DB_URL);
        }
    }

public static Connection getConnection(){
    return connectionHolder.get();
}   
``` 

**不变性**<br>
即使对象中所有域都是final类型，由于final域中可以保存对可变对象的引用，该对象仍然可能是可变的。可以封装一个不可变对象给外部调用

```java
public class FinalWrapper {
    private final Set<String> stooges = new HashSet<>();

    public FinalWrapper() {
        stooges.add("Moe");
        stooges.add("Larry");
        stooges.add("Curly");
    }

    public boolean isStooge(String name){
        return stooges.contains(name);
    }
}
``` 

#### 对象的发布
发布对象，将对象能够在当前作用域之外使用，发布对象可能会破坏封装性。某个不应该发布的对象被发布时，就称为逸出（Escape）

```java
//逸出的没有构造完全的this对象,可以通过EventListener对象.this访问到ThisEscape对象
public class ThisEscape{
    public ThisEscape(EventSource source){
        source.registerListener(
            new EventListener(){
                public void onEvent(Event e){
                    doSomething(e);
                }
            });
    }
}
```

可以使用一个私有构造函数和一个公共的工厂方法解决

```java
public class SafeListener{
    private final EventListener listener;

    private SafeListener(){
        listener = new EventListener(){
            public void onEvent(Event e){
                doSomething(e);
            }
        }
    }

    public static SafeListener newInstance(EventSource source){
        SafeListener safe = new SafeListener();
        source.registerListener(safe.listener);
        return safe;
    }
}
```

---
#### 安全发布
可以使用volatile和不可变对象实现不添加锁就能被多线程安全访问

```java
public class VolatileCachedFactorizer implements Servlet {
    class OneValueCache {
        private final BigInteger lastNumber;
        private final BigInteger[] lastFactors;

        public OneValueCache(BigInteger lastNumber, BigInteger[] lastFactors) {
            this.lastNumber = lastNumber;
//            重新生成一个对象，保证不受到外部影响
            this.lastFactors = Arrays.copyOf(lastFactors, lastFactors.length);
        }

        public BigInteger[] getLastFactors(BigInteger i) {
            if (lastNumber == null || !lastNumber.equals(i)) {
                return null;
            } else {
//                返回的对象不会对内部产生影响
                return Arrays.copyOf(lastFactors, lastFactors.length);
            }
        }
    }

    private volatile OneValueCache cache = new OneValueCache(null, null);

    @Override
    public void service(ServletRequest servletRequest, ServletResponse servletResponse) throws ServletException, IOException {
        BigInteger i = UnsageCachingFactorizer.extractFromRequest(servletRequest);
        BigInteger[] factors = cache.getLastFactors(i);
        if (factors == null) {
            factors = UnsageCachingFactorizer.factor(i);
//            volatile保证多线程的可见性
            cache = new OneValueCache(i, factors);
        }
        UnsageCachingFactorizer.encodeIntoResponse(servletResponse, factors);
    }
}
```

通常有以下的方式安全的发布对象方式

- 静态初始化函数中初始化一个对象引用
- 对象的引用保存到volatile类型或者AtomicReferance对象中
- 对象引用保存到正确构造对象的final类型域中
- 对象引用保存到一个由锁保护的域中

---
#### 设计一个线程安全的类

- 收集同步需求 确定对象在哪些状态和状态转换是有效的;
- 依赖状态的操作 基于状态的先验条件
- 状态所有权 对象封装拥有的状态，对象封装的状态拥有所有权。如果发布了某个可变对象的引用，就不再拥有独占的控制权，最多是"共享控制权"。

**实例封装**

```java
public class PersonSet {
    private final Set<Person> people = new HashSet<>();

    public synchronized void addPerson(Person p) {
        people.add(p);
    }

    public synchronized boolean containsPerson(Person p) {
        return people.contains(p);
    }

    class Person {
        private String name;

        public Person() {
        }
    }
}
``` 

**监视器模式**

```java
/*
 * MutablePoint对象可以改变，返回的时候都需要拷贝数据，数据量较大性能成问题
 * */
public class MonitorVehicleTracker {
    private final Map<String, MutablePoint> locations;

    public MonitorVehicleTracker(Map<String, MutablePoint> locations) {
        this.locations = deepCopy(locations);
    }

    public synchronized Map<String, MutablePoint> getLocations() {
        return deepCopy(locations);
    }

    public synchronized MutablePoint getLocation(String id) {
        MutablePoint point = locations.get(id);
        return point == null ? null : new MutablePoint(point);
    }

    private static Map<String, MutablePoint> deepCopy(Map<String, MutablePoint> m) {
        Map<String, MutablePoint> result = new HashMap<>();
        for (String id :
                m.keySet()) {
            result.put(id, new MutablePoint(m.get(id)));
        }
        return result;
    }

    static class MutablePoint {
        public int x, y;

        public MutablePoint(int x, int y) {
            this.x = x;
            this.y = y;
        }

        public MutablePoint(MutablePoint p) {
            this.x = p.x;
            this.y = p.y;
        }
    }
}
``` 

**委托模式(较为常用)**

```java
public class DelegationVehicleTracker {

    private final ConcurrentMap<String, Point> locations;
    private final Map<String, Point> unmodifiableMap;

    public DelegationVehicleTracker(Map<String, Point> points) {
        locations = new ConcurrentHashMap<String, Point>(points);
        unmodifiableMap = Collections.unmodifiableMap(locations);
    }

    public Map<String, Point> getLocations() {
        return unmodifiableMap;
    }

    public Point getLocation(String id) {
        return locations.get(id);
    }

    public void setLocations(String id, int x, int y) {
        if (locations.replace(id, new Point(x, y)) == null) {
            throw new IllegalArgumentException(
                    "invalid vehicle name: " + id);
        }
    }
    
    class Point {
        public final int x, y;

        public Point(int x, int y) {
            this.x = x;
            this.y = y;
        }
    }
}
```     

**独立状态变量**<br>
多个变量彼此独立，可以将变量委托为多个状态变量

```java
//将多个对象委托给多个状态变量
public class VisualComponent {
    private final List<KeyListener> keyListeners = new CopyOnWriteArrayList<>();
    private final List<MouseListener> mouseListeners = new CopyOnWriteArrayList<>();
    
    public void addKeyListener(KeyListener listener){
        keyListeners.add(listener);
    }
    
    public void addMouseListener(MouseListener listener){
        mouseListeners.add(listener);
    }
    
    public void removeKeyListener(KeyListener listener){
        keyListeners.remove(listener);
    }
    
    public void removeMouseListener(MouseListener listener){
        mouseListeners.remove(listener);
    }
}
```
---
#### 现有线程安全类添加功能
1.**修改原有基础类（不太可能）**<br>
2.**直接扩展类**，提供方法比较脆弱，如果底层类发生改变，那么子类会发生改变

```java
public class BetterVector<E> extends Vector<E> {
    public synchronized boolean putIfAbsent(E x) {
        boolean absent = !contains(x);
        if (absent) {
            add(x);
        }
        return absent;
    }
}
```

3.**客户端加锁**<br>
将扩展代码放到一个辅助类中，将类加锁代码分布到多个类中，客户端加锁更加脆弱。

```java
public class ListHelper<E>{
    public List<E> list = Collections.synchronizedList(new ArrayList<E>());

    public boolean putIfAbsent(E x){
        //对list进行加锁，而不是ListHelper实例
        synchronized(list){
            boolean absent = !list.contains(x);
            if(absent){
                list.add(x);
            }
            return absent;
        }
    }
}
```

4.**更好的方法-组合**

```java
public class ImproveList<T> implements List<T> {
    private final List<T> list;

    public ImproveList(List<T> list) {
        this.list = list;
    }

    public synchronized boolean putIfAbsent(T x) {
        boolean contains = list.contains(x);
        if (!contains) {
            list.add(x);
        }
        return contains;
    }
}
```

**同步策略文档化**

- 用户通过文档查阅某个类的线程安全性
- 很多文档没有说明，该类是否是线程安全的，但是可以合理的推测。例如多线程可以访问ServletContext对象，因此ServletContext应该是线程安全的，JDBC DataSource是一个可重用的数据库连接，在单线程应用程序中没有太大意义，在多线程中才有价值。

---
### 参考资料
- 《Java并发编程实战》