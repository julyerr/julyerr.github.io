---
layout:     post
title:      "java 常见设计模式一"
subtitle:   "java 常见设计模式一"
date:       2018-03-07 12:00:00
author:     "julyerr"
header-img: "img/lib/designPattern/designPattern.png"
header-mask: 0.5
catalog: 	true
tags:
    - designPattern
---

>一谈起设计模式，顿时感觉逼格高了不少...说白了设计模式就是开发大牛们不断总结出的代码书写方式，优秀的类库或者框架都有良好的设计模式，例如java中很多api的设计、spring 接口的设计、tomcat的设计等。设计模式种类有23种，其实常见的也就是10几种左右。本人也是小白一个，一边学一遍总结，下面就常见的几种设计模式加以总结哈，很多内容参照[1]。

### 单例模式

单例就是某个类在整个应用程序中只有一个实例对象。使用单例，可以避免建立多个实例带来的资源开销，而且在某些场景下，必须使用单个实例对象，多个实例还会引发异常，例如常用的工具类、线程池、缓存等场合。<br>

**实现的思路**:对象的创建必须在内部进行，不能直接被用户new,通常通过类的一个方法将创建的实例对象返回。<br>

很自然就想到下面的写法

```java
public class Singleton1NotSafe {
    private static Singleton1NotSafe instance=null;

    private Singleton1NotSafe() {};

    public static Singleton1NotSafe getInstance(){

        if(instance==null){
            instance=new Singleton1NotSafe();
        }
        return instance;
    }
}
```

上面写法在单线程是可以使用的，但是在多线程环境下，线程A和线程B同时执行到`if(instance==null)`这条语句，可能同时修改两个值，出现异常错误。<br>

下面总结的均是**多线程安全的单例**写法：<br>

**静态代码块**

```java
public class Singleton1 {
    private static Singleton1 instance=new Singleton1();
    private Singleton1(){};
    public static Singleton1 getInstance(){
        return instance;
    }
}
```

**双重检测**

```java
public class Singleton2 {
    private static Singleton2 instance=null;

    private Singleton2() {};

    public static Singleton2 getInstance(){
        if (instance == null) {
        	//同步代码块内部重新进行判断
            synchronized (Singleton2.class) {
                if (instance == null) {
                    instance = new Singleton2();
                }
            }
        }
        return instance;
    }
}
```

**内部类**

```java 
public class Singleton3 {
    private Singleton3() {};

    private static class SingletonHolder{
        private static Singleton3 instance=new Singleton3();
    }

    public static Singleton3 getInstance(){
        return SingletonHolder.instance;
    }
}
```

**枚举类型**

```java 
public enum Singleton4 {  
      
     instance;   
       
     private SingletonEnum() {}  
       
     public void method(){  
     }  
}  
```

使用方式：Singleton4.SingletonEnum.instance.method() 进行方法调用<br>

**synchronized代码块**（性能问题，一般不建议使用）

```java
public class Singleton5 {

    private static Singleton5 instance = null;

    private Singleton5() {
    };

    public static synchronized Singleton5 getInstance() {

        if (instance == null) {
            instance = new Singleton5();
        }
        return instance;
    }
}
```

上面使用的[单例代码参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/designPattern/singleton/)

---
### 工厂设计模式
细分为以下几种

- **静态工厂模式** 最为常见的辅助工具类，例如Character.isDigit()
- **简单工厂模式** 简单工厂模式的工厂类一般是使用静态方法，通过接收的参数的不同来返回不同的对象实例。不修改代码的话，无法新增新的对象的实例。
- **工厂方法模式** 工厂方法是针对每一种产品提供一个工厂类。通过不同的工厂实例来创建不同的产品实例，在同一等级结构中，支持增加任意产品。
- **抽象工厂模式** 应对产品族概念而生，增加新的产品线很容易，但是无法增加新的产品。

典型[示例伪码参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/designPattern/factory/)	


---
### 适配器模式

将一个类的接口转换成客户期望的另一个接口,适配器让原本接口不兼容的类可以相互合作.

![](/img/lib/designPattern/adapter.png)

下面是一个充电器的示例demo,完整代码[参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/designPattern/adapter/)

**提供者和需求者**

```java
public class V220Power {
    public int provideV220Power()
    {
        System.out.println("提供220V交流电压");
        return 220 ;
    }
}

public class Mobile {
    public void inputPower(V5Power power)
    {
        int provideV5Power = power.provideV5Power();
        System.out.println("手机（客户端）：需要5V电压充电，现在是-->" + provideV5Power + "V");
    }
}
```

**适配器**

```
public interface V5Power {
    int provideV5Power();
}

public class V5PowerAdapter implements V5Power {
    /**
     * 组合的方式
     */
    private V220Power v220Power ;

    public V5PowerAdapter(V220Power v220Power){
        this.v220Power = v220Power ;
    }

    @Override
    public int provideV5Power()
    {
        int power = v220Power.provideV220Power() ;
        System.out.println("适配器：适配了电压。");
        return 5 ;
    }

}
```

---
### 装饰者模式

要扩展功能的时候，装饰者可以动态将责任附加到对象上。主要用于动态给某给类增加一些辅助的功能。

![](/img/lib/designPattern/decorator.jpg)

下面以游戏装备为例，只粘贴出核心代码，[完整代码参见](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/designPattern/decorator/)<br>

游戏中各种装备可以进行组合，所具备的攻击值也会叠加。如果设计出所有组合的类的话，显然是不可能的；通过动态给装备增加装备的方式才能较好的解决这种问题。<br>


**装备接口以及几个实现类**

```java
public interface IEquip {
    /**
     * 计算攻击力
     * @return
     */
    int caculateAttack();
    /**
     * 装备的描述
     * @return
     */
    String description();
}


public class ArmEquip implements IEquip {
    @Override
    public int caculateAttack(){
        return 20;
    }
    @Override
    public String description(){
        return "屠龙刀";
    }
}

public class RingEquip implements IEquip {
    @Override
    public int caculateAttack(){
        return 5;
    }
    @Override
    public String description(){
        return "圣战戒指";
    }
}
```

**装饰器接口以及对应的实现类**

```java
public interface IEquipDecorator extends IEquip {

}

public class BlueGemDecorator implements IEquipDecorator {
    /**
     * 每个装饰品维护一个装备
     */
    private IEquip equip;

    public BlueGemDecorator(IEquip equip){
        this.equip = equip;
    }
    @Override
    public int caculateAttack(){
        return 5 + equip.caculateAttack();
    }
    @Override
    public String description(){
        return equip.description() + "+ 蓝宝石";
    }
}

public class YellowGemDecorator implements IEquipDecorator {
    /**
     * 每个装饰品维护一个装备
     */
    private IEquip equip;

    public YellowGemDecorator(IEquip equip) {
        this.equip = equip;
    }
    @Override
    public int caculateAttack() {
        return 5 + equip.caculateAttack();
    }
    @Override
    public String description() {
        return equip.description() + "+ 蓝宝石";
    }
}
```

**测试文件**

```java
public class DecoratorDemo {
    public static void main(String[] args){
        System.out.println(" 一个镶嵌1颗蓝宝石，1颗黄宝石的屠龙刀");
        IEquip equip = new BlueGemDecorator(new YellowGemDecorator(new BlueGemDecorator(new ArmEquip())));
        System.out.println("攻击力  : " + equip.caculateAttack());
        System.out.println("描述 :" + equip.description());
        System.out.println("-------");
        System.out.println(" 一个镶嵌2颗黄宝石，1颗蓝宝石的圣战戒指");
        equip = new YellowGemDecorator(new BlueGemDecorator(new YellowGemDecorator(new RingEquip())));
        System.out.println("攻击力  : " + equip.caculateAttack());
        System.out.println("描述 :" + equip.description());
        System.out.println("-------");
    }
}
```

**输出如下**

```
一个镶嵌1颗蓝宝石，1颗黄宝石的屠龙刀
攻击力  : 35
描述 :屠龙刀+ 蓝宝石+ 蓝宝石+ 蓝宝石
-------
 一个镶嵌2颗黄宝石，1颗蓝宝石的圣战戒指
攻击力  : 20
描述 :圣战戒指+ 蓝宝石+ 蓝宝石+ 蓝宝石
-------
```

在java i/o 类库中，FilterInputStream就是一个抽象装饰器
![](/img/lib/designPattern/java-io.jpg)

可以通过装饰器给FilterInputStream动态增加一个输入流全部转换为小写的功能

```java
public class LowerCaseInputStream extends FilterInputStream {
    protected LowerCaseInputStream(InputStream in){
        super(in);
    }

    @Override
    public int read() throws IOException{
        int c = super.read();
        return (c == -1 ? c : Character.toLowerCase((char) c));
    }

    @Override
    public int read(byte[] b, int offset, int len) throws IOException {
        int result = super.read(b, offset, len);

        for (int i = offset; i < offset + result; i++)
        {
            b[i] = (byte) Character.toLowerCase((char) b[i]);
        }

        return result;
    }
}

public static void main(String[] args) throws IOException {
        int c;
        try
        {
            InputStream in = new LowerCaseInputStream(new BufferedInputStream(
                    new FileInputStream("/home/julyerr/github/collections/src/main/java/" +
                            "com/julyerr/interviews/designPattern/decorator/iodemo/LowCaseDemo.java")));

            while ((c = in.read()) >= 0)
            {
                System.out.print((char) c);
            }

            in.close();
        }
        catch (IOException e)
        {
            e.printStackTrace();
        }
    }
```

---
### 观察者模式

定义了对象之间的一对多的依赖，当一个对象改变时，它的所有的依赖者都会收到通知并自动更新。<br>

观察者模式还是比较好理解的，下面是一个demo。<br>


**主题接口及其实现类**

```java
public interface Subject {
    /**
     * 注册一个观察着
     * @param observer
     */
    void registerObserver(Observer observer);
    /**
     * 移除一个观察者
     * @param observer
     */
    void removeObserver(Observer observer);

    /**
     * 通知所有的观察着
     */
    void notifyObservers();
}

public class ObjectFor3D implements Subject {
    private List<Observer> observers = new ArrayList<Observer>();
    /**
     * 3D彩票的号码
     */
    private String msg;

    @Override
    public void registerObserver(Observer observer) {
        observers.add(observer);
    }

    @Override
    public void removeObserver(Observer observer){
        int index = observers.indexOf(observer);
        if (index >= 0){
            observers.remove(index);
        }
    }

    @Override
    public void notifyObservers(){
        for (Observer observer : observers){
            observer.update(msg);
        }
    }

    /**
     * 主题更新消息
     * @param msg
     */
    public void setMsg(String msg){
        this.msg = msg;
        notifyObservers();
    }
}
```

**观察者接口及其实现类**

```java
public interface Observer {
    void update(String msg);
}

public class Observer1 implements Observer {
    private Subject subject;
    public Observer1(Subject subject){
        this.subject = subject;
        subject.registerObserver(this);
    }

    @Override
    public void update(String msg){
        System.out.println("observer1 得到 3D 号码  -->" + msg );
    }
}

//observer2一样
```

**测试文件及其输出**

```java
public class ObjectDemo {
    public static void main(String[] args){
        //模拟一个3D的服务号
        ObjectFor3D subjectFor3d = new ObjectFor3D();
        //客户1
        Observer observer1 = new Observer1(subjectFor3d);
        //客户2
        Observer observer2 = new Observer2(subjectFor3d);

        subjectFor3d.setMsg("20140421的3D号码是：333" );
    }
}
```

```
observer1 得到 3D 号码  -->20140421的3D号码是：333
observer2 得到 3D 号码  -->20140421的3D号码是：333
```

`java.util.*`包为观察者模式提供了支持：<br>

- 被观察者(Subject)需要继承Observable类，该类已经实现了`addObserver`,`removeObserver,`notifyObservers`等方法；
- 观察者需要实现Observer接口，重载`update(Observable o, Object arg)`。

上面示例[完整代码](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/designPattern/observe/)和使用java内置库实现的[demo代码](https://github.com/julyerr/collections/tree/master/src/main/java/com/julyerr/interviews/designPattern/observe/internel/)

---
### 参考资料
[1]:https://github.com/youlookwhat/DesignPattern
- [DesignPattern](https://github.com/youlookwhat/DesignPattern)
- [工厂模式和抽象工厂模式的区别](https://my.oschina.net/hanzhankang/blog/195150)
- [Java-设计模式-三种工厂模式-比较区分](http://blog.csdn.net/qq_32115439/article/details/72719312)
- [装饰者模式](http://www.cnblogs.com/god_bless_you/archive/2010/06/10/1755212.html)