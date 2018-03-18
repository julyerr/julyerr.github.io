---
layout:     post
title:      "面试问题总结-java基础知识一"
subtitle:   "面试问题总结-java基础知识一"
date:       2018-03-10 8:00:00
author:     "julyerr"
header-img: "img/interviews/java/basic.png"
header-mask: 0.5
catalog:    true
tags:
    - interviews
---

1、float f=3.4;是否正确？ 
答:不正确。3.4是双精度数，将双精度型（double）赋值给浮点型（float）属于下转型（down-casting，也称为窄化）会造成精度损失，因此需要强制类型转换float f =(float)3.4; 或者写成float f =3.4F;。

2、short s1 = 1; s1 = s1 + 1;有错吗?short s1 = 1; s1 += 1;有错吗？ 
答：对于short s1 = 1; s1 = s1 + 1;由于1是int类型，因此s1+1运算结果也是int 型，需要强制转换类型才能赋值给short型。而short s1 = 1; s1 += 1;可以正确编译，因为s1+= 1;相当于s1 = (short)(s1 + 1);其中有隐含的强制类型转换。

Java中==和equals的区别，equals和hashCode的区别

== 运算符，用于比较两个变量是否相等；equals，是Objec类的方法，用于比较两个对象是否相等，默认Object类的equals方法是比较两个对象的地址，跟==的结果一样；hashCode也是Object类的一个方法，返回一个离散的int型整数，在集合类操作中使用，为了提高查询速度。

数据类型：

基本数据类型：
    byte,short,char,int,long,float,double,boolean，==比较的是他们的值；
复合类型数据
    在Object中的基类中定义了一个equals的方法，这个方法的初始行为是比较对象的内存地 址，但在一些类库当中这个方法被覆盖掉了，如String,Integer,Date在这些类当中equals有其自身的实现

    对象的equals()相等，hashCode()方法也相等；
    hashCode()相等，并不代表equals()相等。在每个覆盖了equals方法的类中，也必须覆盖hashCode方法



3、int和Integer有什么区别？ 

```java
public static void main(String[] args) {
    Integer a = new Integer(3);
    Integer b = 3;                  // 将3自动装箱成Integer类型
    int c = 3;
    System.out.println(a == b);     // false 两个引用没有引用同一对象
    System.out.println(a == c);     // true a自动拆箱成int类型再和c比较
}
```

如果整型字面量的值在-128到127之间，那么不会new新的Integer对象，而是直接引用常量池中的Integer对象，所以上面的面试题中f1==f2的结果是true，而f3==f4的结果是false。


```java
public static void main(String[] args) {
    Integer f1 = 100, f2 = 100, f3 = 150, f4 = 150;

    System.out.println(f1 == f2);
    System.out.println(f3 == f4);
}
```

4、
String 
final修饰类
初始化方法：
字面量
	从常量池中查找是否有相同值的字符串对象，如果有，则直接将对象地址赋予引用变量；如果没有，在首先在常量池区域中创建一个新的字符串对象，然后将地址赋予引用变量。
构造方法
	每次调用构造方法都会在堆内存中创建一个新的字符串对象。

String和JVM常量池

常量池（准确地说是运行时常量池），在JDK1.6及以前都是方法区中的一部分，在JDK1.7之后被移入堆区		

intern()方法

intern()方法的作用是在常量池中查找值等于（equals）当前字符串的对象，如果找到，则直接返回这个对象的地址；如果没有找到，则将当前字符串拷贝到常量池中，然后返回拷贝后的对象地址。
jdk1.7及之后版本，intern()方法调用之后，如果堆中存在该字符串常亮返回堆中的引用。

String、StringBuffer与StringBuilder

String	不可变	线程安全
StringBuffer	可变	线程安全
StringBuilder	可变	非线程安全（没有同步代码块约束，效率更高）

+操作

编译时优化

```java
String str1 = "ab" + "cd";   //编译的时候已经可以确定str1的值
String str11 = "abcd";   
System.out.println("str1 = str11 : "+ (str1 == str11));  // true
```

局部变量表

```java
String str2 = "ab";  
String str3 = "cd";         
/**
运行期JVM首先会在堆中创建一个StringBuilder类， 
 * 同时用str2指向的拘留字符串对象完成初始化， 
 * 然后调用append方法完成对str3所指向的拘留字符串的合并， 
 * 接着调用StringBuilder的toString()方法在堆中创建一个String对象， 
 * 最后将刚生成的String对象的堆地址存放在局部变量str3中。 
**/                                 
String str4 = str2 + str3;   
String str5 = "abcd";    
System.out.println("str4 = str5 : " + (str4 == str5)); // false  
```

final字符串编译时优化

```java
final String str8 = "b";  //编译的时候str8优化成常量变量
String str9 = "a" + str8;  
String str89 = "ab";  
System.out.println("str9 = str89 : "+ (str9 == str89)); // true  
```


5、Math.round(11.5) 等于多少？Math.round(-11.5)等于多少？ 
答：Math.round(11.5)的返回值是12，Math.round(-11.5)的返回值是-11。四舍五入的原理是在参数上加0.5然后进行下取整。

6、switch 是否能作用在byte 上，是否能作用在long 上，是否能作用在String上？ 
答：在Java 5以前，switch(expr)中，expr只能是byte、short、char、int。从Java 5开始，Java中引入了枚举类型，expr也可以是enum类型，从Java 7开始，expr还可以是字符串（String），但是长整型（long）在目前所有的版本中都是不可以的。

7、构造器（constructor）是否可被重写（override）？ 
答：构造器不能被继承，因此不能被重写，但可以被重载。


8、当一个对象被当作参数传递到一个方法后，此方法可改变这个对象的属性
是值传递。Java语言的方法调用只支持参数的值传递。

9、重载（Overload）和重写（Override）的区别。重载的方法能否根据返回类型进行区分？ 
重载发生在一个类中，同名的方法如果有不同的参数列表（参数类型不同、参数个数不同或者二者都不同）则视为重载；重写发生在子类与父类之间


实现多态的机制是什么
    靠的是父类或接口定义的引用变量可以指向子类或具体实现类的实例对象，而程序调用的方法在运行期才动态绑定，就是引用变量所指向的具体实例对象的方法，也就是内存里正在运行的那个对象的方法，而不是引用变量的类型中定义的方法    

子类能否重写父类的静态方法
    不能，如果是非静态方法，编译时编译器以为是要调用Employee类的，可是实际运行时，解释器就从堆上开工了，实际上是从Manager类的那个对象上走的，所以调用的方法实际上是Manager类的方法。有这种结果关键在于man实际上指向了Manager类对象。现在用man来调用静态方法，实际上此时是Employee类在调用静态方法，Employee类本身肯定不会指向Manager类的对象，那么最终调用的是Employee类的方法。
    总之：静态方法和属性能够被继承但是不能被重写，不能实现多态；实例的方法和属性可以被继承、重写、重载    

```java
Employee man = new Manager();
man.test();
```    
    解释比较好：http://blog.csdn.net/FG2006/article/details/6703529


10、抽象类（abstract class）和接口（interface）有什么异同？ 
抽象类和接口都不能够实例化，但可以定义抽象类和接口类型的引用。
接口比抽象类更加抽象，因为抽象类中可以定义构造器，可以有抽象方法和具体方法，而接口中不能定义构造器而且其中的方法全部都是抽象方法。

接口存在的意义
    简单、规范性：描述业务架构的一些重要接口
    维护、拓展性：接口可以引用多个实现该接口的类
    安全、严密性：描述对外部提供的服务，而不涉及到任何具体实现细节

泛型中extends和super的区别
    <? extends T>：是指 “上界通配符（Upper Bounds Wildcards）”
        所有的元素都是T的子类，可以用同一个的父类进行获取，通常用于读取较多的情况，也称为get原则
    <? super T>：是指 “下界通配符（Lower Bounds Wildcards）”
        所有元素都是T的父类，可以添加多个其他类型的元素，通常用于赋值较多的情况下，也称为set原则

    具体参见：https://itimetraveler.github.io/2016/12/27/%E3%80%90Java%E3%80%91%E6%B3%9B%E5%9E%8B%E4%B8%AD%20extends%20%E5%92%8C%20super%20%E7%9A%84%E5%8C%BA%E5%88%AB%EF%BC%9F/    


11、静态嵌套类(Static Nested Class)和内部类（Inner Class）的不同？ 
Static Nested Class是被声明为静态（static）的内部类，它可以不依赖于外部类实例被实例化。而通常的内部类需要在外部类实例化后才能实例化

```java
class Outer {

    class Inner {}

    public void bar() { new Inner(); }

    public static void main(String[] args) {
        new Outer.new Inner();
    }
}
```

15、内部类

很好隐藏内部实现的细节
    内部类可以访问外围类所有元素的访问权限
    实现多重继承
        没有内部类只能通过实现多接口（必须实现所有的方法）
        声明多个内部类，分别继承不同的类或者接口，达到多继承的目的
    避免修改接口实现同一类的同名方法的调用

一个内部类对象可以访问创建它的外部类对象的成员，包括私有成员。

成员内部类，局部内部类(使用和成员内部类类似，只是生命周期限制在局部函数中)
    如果内部类和外部类名称相同时，默认情况下访问的是成员内部类的成员。如果要访问外部类的同名成员，需要用下面的形式访问。外部类.this.成员变量，外部类.this.成员方法

匿名内部类 
    要求：没有访问修饰符、内部必须继承一个抽象类或者实现一个接口

```java
public class Button {
    public void click(){
        //匿名内部类，实现的是ActionListener接口
        new ActionListener(){
            public void onAction(){
                System.out.println("click action...");
            }
        }.onAction();
    }
    //匿名内部类必须继承或实现一个已有的接口
    public interface ActionListener{
        public void onAction();
    }

    public static void main(String[] args) {
        Button button=new Button();
        button.click();
    }
}
```

静态内部类（嵌套内部类） static关键字限制而已，不能引用对象的方法属性等


12、抽象的（abstract）方法是否可同时是静态的（static）,是否可同时是本地方法（native），是否可同时被synchronized修饰？
答：都不能。抽象方法需要子类重写，而静态的方法是无法被重写的，因此二者是矛盾的。本地方法是由本地代码（如C代码）实现的方法，而抽象方法是没有实现的，也是矛盾的。synchronized和方法的实现细节有关，抽象方法不涉及实现细节，因此也是相互矛盾的。

13、如何实现对象克隆？

1). 实现Cloneable接口并重写Object类中的clone()方法； 
2). 实现Serializable接口，通过对象的序列化和反序列化实现克隆，可以实现真正的深度克隆


注解

    @Target @Retention @Documented @Inherited 四种注解
    @Target 说明了修饰对象的范围：
        CONSTRUCTOR:用于描述构造器
        FIELD:用于描述域
        LOCAL_VARIABLE:用于描述局部变量
        METHOD:用于描述方法
        PACKAGE:用于描述包
        PARAMETER:用于描述参数
        TYPE:用于描述类、接口(包括注解类型) 或enum声明
    @Retention 定义了Annotation的保留的时间长短
        SOURCE:在源文件中有效（即源文件保留）
        CLASS:在class文件中有效（即class保留）
        RUNTIME:在运行时有效（即运行时保留）
    @Documented
        Documented是一个标记注解，没有成员
    @Inherited
        阐述了某个被标注的类型是被继承的。如果一个使用了@Inherited修饰的annotation类型被用于一个class，则这个annotation将被用于该class的子类。
    自定义注解：
        使用@interface自定义注解时，自动继承了java.lang.annotation.Annotation接口
        中间参数的使用：
            只能用public或默认(default)这两个访问权修饰.例如,String value();这里把方法设为defaul默认类型
            参数成员只能用基本类型byte,short,char,int,long,float,double,boolean八种基本数据类型和 String,Enum,Class,annotations等数据类型,以及这一些类型的数组


14、jvm中常见的调优参数

```
-Xms / -Xmx — 堆的初始大小 / 堆的最大大小
-Xmn — 堆中年轻代的大小
-XX:-DisableExplicitGC — 让System.gc()不产生任何作用
-XX:+PrintGCDetails — 打印GC的细节
-XX:+PrintGCDateStamps — 打印GC操作的时间戳
-XX:NewSize / XX:MaxNewSize — 设置新生代大小/新生代最大大小
-XX:NewRatio — 可以设置老生代和新生代的比例
-XX:PrintTenuringDistribution — 设置每次新生代GC后输出幸存者乐园中对象年龄的分布
-XX:InitialTenuringThreshold / -XX:MaxTenuringThreshold：设置老年代阀值的初始值和最大值
-XX:TargetSurvivorRatio：设置幸存区的目标使用率
```

17、类加载代码的运行结果

创建对象时构造器的调用顺序是：先初始化静态成员，如果有成员块，然后调用父类构造器，再初始化非静态成员，最后调用自身构造器。

对象什么情形下会被垃圾回收？

所有实例都没有活动线程访问，
没有被其他任何实例访问的循环引用实例，
判断实例是否符合垃圾收集的条件都依赖于它的引用类型
    强引用：只要强引用还存在，垃圾收集器就永远不会回收掉被引用的对象。
    软引用：在系统内存不够用时，这类引用关联的对象将被垃圾收集器回收
    弱引用：被弱引用关联的对象只能生存到下一次垃圾收集发生之前。
    虚引用：为一个对象设置虚引用关联的唯一目的是希望能在这个对象被收集器回收时收到一个系统通知


18、怎样将GB2312编码的字符串转换为ISO-8859-1编码的字符串？ 
答：代码如下所示：

```java
String s1 = "你好";
String s2 = new String(s1.getBytes("GB2312"), "ISO-8859-1");
```

19、获取时间

java.util.Calendar

java8 中的java.time.LocalDateTime

```java
public static void main(String[] args) {
//        calendar
    Calendar calendar = Calendar.getInstance();
    System.out.println(calendar.getTime());
//        昨天的时间
    calendar.add(Calendar.DATE, -1);

    SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy/MM/dd");
    System.out.println(simpleDateFormat.format(calendar.getTime()));

//        java8
    LocalDateTime localDateTime = LocalDateTime.now();
    DateTimeFormatter dateTimeFormatter = DateTimeFormatter.ofPattern("yyyy/MM/dd");
    System.out.println(dateTimeFormatter.format(localDateTime.minusDays(1)));

}
```

java异常体系结构

Throwable类是整个Java异常体系的超类，都有的异常类都是派生自这个类。包含Error和Exception两个直接子类。
Exception是应用层面上最顶层的异常类，包含RuntimeException（运行时异常）和 Checked Exception（受检异常）
RuntimeException:
    出现表示程序中出现了编程错误，所以应该找出错误修改程序，而不是去捕获RuntimeException
Checked Exception:
    所有继承自Exception并且不是RuntimeException的异常都是Checked Exception，必须对checked Exception作处理，编译器会对此作检查。    

总结比较好的文章：【系列】重新认识Java语言——异常（Exception）：http://blog.csdn.net/xialei199023/article/details/63251277    

20、Error和Exception有什么区别？ 
答：Error表示系统级的错误和程序不必处理的异常，是恢复不是不可能但很困难的情况下的一种严重问题；比如内存溢出，不可能指望程序能处理这样的情况；Exception表示需要捕捉或者需要程序进行处理的异常，是一种设计或实现问题；也就是说，它表示如果程序运行正常，从不会发生的情况。

21、try{}里有一个return语句，那么紧跟在这个try后的finally{}里的代码会不会被执行？
会被执行，finally不论如何都会被执行，如果finally中对返回值进行了修改，返回的是被修改的值。

22、finalize的使用
Object类中定义的方法，Java中允许使用finalize()方法在垃圾收集器将对象从内存中清除出去之前做必要的清理工作。这个方法是由垃圾收集器在销毁对象时调用的，通过重写finalize()方法可以整理系统资源或者执行其他清理工作。


浅拷贝和深拷贝
    对于基本类型，=表示赋值；对于实例对象，=表示对象的引用传递
    没有真正创建一个对象表示浅拷贝，创建了一个新的对象，并且复制其内的成员变量，则认为是深拷贝。
    实现拷贝，需要对应的类实现Cloneable接口（但是还是浅拷贝，创建了对象，但是对象中其他对象还是引用）；
    如果实现深拷贝，需要成员对象也实现Cloneable接口
    具体参见：https://segmentfault.com/a/1190000010648514    


collection

1、List、Set、Map是否继承自Collection接口？ 
答：List、Set 是，Map 不是。Map是键值对映射容器，与List和Set有明显的区别，而Set存储的零散的元素且不允许有重复元素（数学中的集合也是如此），List是线性结构的容器，适用于按数值索引访问元素的情形。

2、阐述ArrayList、Vector、LinkedList的存储性能和特性。 
ArrayList 使用数组实现存储，随机访问速度效率高；
LinkedList使用双向链表实现存储，插入和删除的效率较高；
Vector中的方法由于添加了synchronized修饰，因此Vector是线程安全的容器，但性能上较ArrayList差；
由于ArrayList和LinkedListed都是非线程安全的，如果遇到多个线程操作同一个容器的场景，则可以通过工具类Collections中的synchronizedList方法将其转换成线程安全的容器后再使用（这是对装潢模式的应用，将已有对象传入另一个类的构造器中创建新的对象来增强实现）。

3、Collection和Collections的区别？ 
答：Collection是一个接口，它是Set、List等容器的父接口；Collections是个一个工具类，提供了一系列的静态方法来辅助容器操作，这些方法包括对容器的搜索、排序、线程安全化等等。


TreeSet和HashSet 以及 TreeMap和HashMap之间的比较：
    对于HashMap，系统仅将value作为key的附属物而已，系统采用Hash算法来决定key的存储位置，这样可以保证快速的存，取集合key，而value仅仅总是作为key的附属。HashSet采用Hash算法来决定集合元素的存储位置，这样可以保证快速的存，取集合元素（底层还是使用了HashMap结构，只不过value域是一个空对象）。
    TreeSet的底层实际使用的存储容器就是TreeMap（空对象设置为Value域），采用红黑树的结构保存每个Entry,每个Entry被当成”红黑数”的一个节点来对待。
    具体参见：https://my.oschina.net/u/3448551/blog/1536545

4、TreeMap和TreeSet在排序时如何比较元素？Collections工具类中的sort()方法如何比较元素？ 

    TreeMap和TreeSet的使用方式

    TreeSet:
        需要自定义排序方式使用：
            Comparator选择new TreeMap(Comparator<? super E> comparator);
            Comparable选择new TreeMap();
                要添加的元素实现compareTo接口，插入的时候判断
    TreeMap:

    两者使用方式基本一致，具体的参考实现demo：http://blog.csdn.net/liuxiao723846/article/details/53521182

答：TreeSet要求存放的对象所属的类必须实现Comparable接口，该接口提供了比较元素的compareTo()方法，当插入元素时会回调该方法比较元素的大小。TreeMap要求存放的键值对映射的键必须实现Comparable接口从而根据键对元素进行排序。Collections工具类的sort方法有两种重载的形式，第一种要求传入的待排序容器中存放的对象比较实现Comparable接口以实现元素的比较；第二种不强制性的要求容器中的元素必须可比较，但是要求传入第二个参数，参数是Comparator接口的子类型（需要重写compare方法实现元素的比较），相当于一个临时定义的排序规则，其实就是通过接口注入比较元素大小的算法，也是对回调模式的应用（Java中对函数式编程的支持）。 



Thread

volatile 实现原理
    添加volatile关键字之后，会增加lock前缀指令（内存屏障）：
        它确保指令重排序时不会把其后面的指令排到内存屏障之前的位置，也不会把前面的指令排到内存屏障的后面；即在执行到内存屏障这句指令时，在它前面的操作已经全部完成；
        会强制将对缓存的修改操作立即写入主存；
        如果进行写操作，它会导致其他CPU中对应的缓存行无效。

synchronized实现原理 
    对象头：
        Mark Word在默认情况下存储着对象的HashCode、分代年龄、锁标记位等，
        还可能转变成不同的锁标志
    jdk1.6之后对synchronized进行了优化：
        偏向锁、轻量级锁、自旋锁、重度锁、锁消除 

    分析比较好blog:http://blog.csdn.net/javazejian/article/details/72828483    

AQS:AbstractQueuedSynchronizer又称为队列同步器
内部通过一个int类型的成员变量state来控制同步状态,当state=0时，则说明没有任何线程占有共享资源的锁，当state=1时，则说明有线程目前正在使用共享变量，其他线程必须加入同步队列进行等待。

ReentrantLock实现原理
    基于AQS的独占锁实现类，一个同步锁，同一个锁拥有多个等待队列
    通过构造器决定是公平锁还是非公平锁，公平锁确保前进行等待的队列的线程先获得锁    

Condition实现原理
    每个Condition都对应着一个等待队列，也就是说如果一个锁上创建了多个Condition对象，那么也就存在多个等待队列。    

Semaphore实现原理
    AQS中通过state值来控制对共享资源访问的线程数，每当线程请求同步状态成功，state值将会减1，如果超过限制数量的线程将被封装共享模式的Node结点加入同步队列等待，直到其他执行线程释放同步状态，才有机会获得执行权

    这里的文章总结得非常好：
        http://blog.csdn.net/javazejian/article/details/75043422

线程池实现原理（自己实现线程池）


1、Thread类的sleep()方法和对象的wait()方法都可以让线程暂停执行，它们有什么区别? 
答：sleep()方法（休眠）是线程类（Thread）的静态方法，调用此方法会让当前线程暂停执行指定的时间，将执行机会（CPU）让给其他线程，但是对象的锁依然保持。wait()是Object类的方法，调用对象的wait()方法导致当前线程放弃对象的锁（线程暂停执行），进入对象的等待池（wait pool），只有调用对象的notify()方法（或notifyAll()方法）时才能唤醒等待池中的线程进入等锁池（lock pool），如果线程重新获得对象的锁就可以进入就绪状态。

2、线程的sleep()方法和yield()方法有什么区别？ 
答： 
① sleep()方法给其他线程运行机会时不考虑线程的优先级，因此会给低优先级的线程以运行的机会；yield()方法只会给相同优先级或更高优先级的线程以运行的机会； 
② 线程执行sleep()方法后转入阻塞（blocked）状态，而执行yield()方法后转入就绪（ready）状态    

3、当一个线程进入一个对象的synchronized方法A之后，其它线程是否可进入此对象的synchronized方法B？ 
答：不能。其它线程只能访问该对象的非同步方法，同步方法则不能进入。因为非静态方法上的synchronized修饰符要求执行方法时要获得对象的锁，如果已经进入A方法说明对象锁已经被取走，那么试图进入B方法的线程就只能在等锁池（注意不是等待池哦）中等待对象的锁。

4、CountDownLatch、CyclicBarrier和Semaphore
CountDownLatch 功能类似计数器,await()方法调用之后等待指定的数目线程运行完成
CyclicBarrier等待一组线程至某个状态再全部同时执行。叫做回环是因为当所有等待线程都被释放以后，CyclicBarrier可以被重用。
Semaphore 可以控同时访问的线程个数，通过 acquire() 获取一个许可，如果没有就等待，而 release() 释放一个许可。
    具体参见:https://www.cnblogs.com/dolphin0520/p/3920397.html

5、编写多线程程序有几种实现方式？ 
答：Java 5以前实现多线程有两种实现方法：一种是继承Thread类；另一种是实现Runnable接口。两种方式都要通过重写run()方法来定义线程的行为，推荐使用后者，因为Java中的继承是单继承，一个类有一个父类，如果继承了Thread类就无法再继承其他类了，显然使用Runnable接口更为灵活。Java5以后创建线程还有第三种方式：实现Callable接口，该接口中的call方法可以在线程执行结束时产生一个返回值。

6、举例说明同步和异步
同步，网络编程中，为读取数据发起一个函数调用，由于数据未读取完毕，因此线程阻塞在函数调用处，称为同步编程；
异步，发起读取数据函数调用之后，即使数据未读取完毕，也直接返回。

7、什么是线程池（thread pool）？ 
答：在面向对象编程中，创建和销毁对象是很费时间的，因为创建一个对象要获取内存资源或者其它更多资源。在Java中更是如此，虚拟机将试图跟踪每一个对象，以便能够在对象销毁后进行垃圾回收。所以提高服务程序效率的一个手段就是尽可能减少创建和销毁对象的次数，特别是一些很耗资源的对象创建和销毁，这就是”池化资源”技术产生的原因。线程池顾名思义就是事先创建若干个可执行的线程放入一个池（容器）中，需要的时候从池中获取线程不用自行创建，使用完毕不需要销毁线程而是放回池中，从而减少创建和销毁线程对象的开销。 

- newFixedThreadPool：创建固定大小的线程池。每次提交一个任务就创建一个线程，直到线程达到线程池的最大大小。线程池的大小一旦达到最大值就会保持不变，如果某个线程因为执行异常而结束，那么线程池会补充一个新线程。 
- newCachedThreadPool：创建一个可缓存的线程池。如果线程池的大小超过了处理任务所需要的线程，那么就会回收部分空闲（60秒不执行任务）的线程，当任务数增加时，此线程池又可以智能的添加新线程来处理任务。此线程池不会对线程池大小做限制，线程池大小完全依赖于操作系统（或者说JVM）能够创建的最大线程大小。 
- newScheduledThreadPool：创建一个大小无限的线程池。此线程池支持定时以及周期性执行任务的需求。 
- newSingleThreadExecutor：创建一个单线程的线程池。此线程池支持定时以及周期性执行任务的需求。


8、简述synchronized 和java.util.concurrent.locks.Lock的异同？ 
答：Lock是Java 5以后引入的新的API，和关键字synchronized相比主要相同点：Lock 能完成synchronized所实现的所有功能；主要不同点：Lock有比synchronized更精确的线程语义和更好的性能，而且不强制性的要求一定要获得锁。synchronized会自动释放锁，而Lock一定要求程序员手工释放，并且最好在finally 块中释放（这是释放外部资源的最好的地方）

9、Java中如何实现序列化，有什么意义？ 
答：序列化就是一种用来处理对象流的机制，所谓对象流也就是将对象的内容进行流化。可以对流化后的对象进行读写操作，也可将流化后的对象传输于网络之间。序列化是为了解决对象流读写操作时可能引发的问题（如果不进行序列化可能会存在数据乱序的问题）。 
要实现序列化，需要让一个类实现Serializable接口，该接口是一个标识性接口，标注该类对象是可被序列化的，然后使用一个输出流来构造一个对象输出流并通过writeObject(Object)方法就可以将实现对象写出（即保存其状态）；如果需要反序列化则可以用一个输入流建立对象输入流，然后通过readObject方法从流中读取对象。序列化除了能够实现对象的持久化之外，还能够用于对象的深度克隆。


几个典型的io编程题目、网络编程的题目

10、XML文档定义有几种形式？它们之间有何本质区别？解析XML文档有哪几种方式？ 
答：XML文档定义分为DTD和Schema两种形式，二者都是对XML语法的约束，其本质区别在于Schema本身也是一个XML文件，可以被XML解析器解析，而且可以为XML承载的数据定义类型，约束能力较之DTD更强大。对XML的解析主要有DOM（文档对象模型，Document Object Model）、SAX（Simple API for XML）和StAX（Java 6中引入的新的解析XML的方式，Streaming API for XML），其中DOM处理大型文件时其性能下降的非常厉害，这个问题是由DOM树结构占用的内存较多造成的，而且DOM解析方式必须在解析文件之前把整个文档装入内存，适合对XML的随机访问（典型的用空间换取时间的策略）；SAX是事件驱动型的XML解析方式，它顺序读取XML文件，不需要一次全部装载整个文件。当遇到像文件开头，文档结束，或者标签开头与标签结束时，它会触发一个事件，用户通过事件回调代码来处理XML文件，适合对XML的顺序访问；顾名思义，StAX把重点放在流上，实际上StAX与其他解析方式的本质区别就在于应用程序能够把XML作为一个事件流来处理。将XML作为一组事件来处理的想法并不新颖（SAX就是这样做的），但不同之处在于StAX允许应用程序代码把这些事件逐个拉出来，而不用提供在解析器方便时从解析器中接收事件的处理程序。


11、你在项目中哪些地方用到了XML？ 
答：XML的主要作用有两个方面：数据交换和信息配置

数据库

1、阐述JDBC操作数据库的步骤
加载驱动
创建连接
创建语句
执行语句
处理结果
关闭资源（也就是说先关闭ResultSet、再关闭Statement、在关闭Connection）

2、Statement和PreparedStatement有什么区别？哪个性能更好？ 
答：与Statement相比，①PreparedStatement接口代表预编译的语句，它主要的优势在于可以减少SQL的编译错误并增加SQL的安全性（减少SQL注射攻击的可能性）；②PreparedStatement中的SQL语句是可以带参数的，避免了用字符串连接拼接SQL语句的麻烦和不安全；③当批量处理SQL或频繁执行相同的查询时，PreparedStatement有明显的性能上的优势，由于数据库可以将编译优化后的SQL语句缓存起来，下次执行相同结构的语句时就会很快（不用再次编译和生成执行计划）。

    为了提供对存储过程的调用，JDBC API中还提供了CallableStatement接口。

3、在进行数据库编程时，连接池有什么作用？ 
答：由于创建连接和释放连接都有很大的开销（尤其是数据库服务器不在本地时，每次建立连接都需要进行TCP的三次握手，释放连接需要进行TCP四次握手，造成的开销是不可忽视的），为了提升系统访问数据库的性能，可以事先创建若干连接置于连接池中，需要时直接从连接池获取，使用结束时归还连接池而不必关闭连接，从而避免频繁创建和释放连接所造成的开销，这是典型的用空间换取时间的策略（浪费了空间存储连接，但节省了创建和释放连接的时间）。池化技术在Java开发中是很常见的，在使用线程时创建线程池的道理与此相同。基于Java的开源数据库连接池主要有：C3P0、Proxool、DBCP、BoneCP、Druid等。

4、什么是DAO模式？ 
答：DAO（Data Access Object）顾名思义是一个为数据库或其他持久化机制提供了抽象接口的对象，在不暴露底层持久化方案实现细节的前提下提供了各种数据访问操作

5、事务的ACID是指什么？ 
答： 
- 原子性(Atomic)：事务中各项操作，要么全做要么全不做，任何一项操作的失败都会导致整个事务的失败； 
- 一致性(Consistent)：事务结束后系统状态是一致的； 
- 隔离性(Isolated)：并发执行的事务彼此无法看到对方的中间状态； 
- 持久性(Durable)：事务完成后所做的改动都会被持久化，即使发生灾难性的失败。通过日志和同步备份可以在故障发生后重建数据。

5类问题，包括3类数据读取问题（脏读、不可重复读和幻读）和2类数据更新问题
    脏读（Dirty Read）：A事务读取B事务尚未提交的数据并在此基础上操作，而B事务执行回滚，那么A读取到的数据就是脏数据。
    不可重复读（Unrepeatable Read）：事务A重新读取前面读取过的数据，发现该数据已经被另一个已提交的事务B修改过了。
    幻读（Phantom Read）：事务A重新执行一个查询，返回一系列符合查询条件的行，发现其中插入了被事务B提交的行。

    第1类丢失更新：事务A撤销时，把已经提交的事务B的更新数据覆盖了
    第2类丢失更新：事务A覆盖事务B已经提交的数据，造成事务B所做的操作丢失。


数据库通常会通过锁机制来解决数据并发访问问题，按锁定对象不同可以分为表级锁和行级锁；按并发事务锁定关系可以分为共享锁和独占锁    

隔离级别    脏读  不可重复读   幻读  第一类丢失更新 第二类丢失更新
READ UNCOMMITED 允许  允许  允许  不允许 允许
READ COMMITTED  不允许 允许  允许  不允许 允许
REPEATABLE READ 不允许 不允许 允许  不允许 不允许
SERIALIZABLE    不允许 不允许 不允许 不允许 不允许

6、JDBC中如何进行事务处理？ 
答：Connection提供了事务处理的方法，通过调用setAutoCommit(false)可以设置手动提交事务；当事务完成后用commit()显式提交事务；如果在事务处理过程中发生异常则通过rollback()进行事务回滚。除此之外，从JDBC 3.0中还引入了Savepoint（保存点）的概念，允许通过代码设置保存点并让事务回滚到指定的保存点。 

7、JDBC能否处理Blob和Clob？ 
答： Blob是指二进制大对象（Binary Large Object），而Clob是指大字符对象（Character Large Objec），因此其中Blob是为存储大的二进制数据而设计的，而Clob是为存储大的文本数据而设计的。JDBC的PreparedStatement和ResultSet都提供了相应的方法来支持Blob和Clob操作。
    可以直接将输入流或者输入字符流最为参数设置到PreparedStatement


其他知识点

1、Java中是如何支持正则表达式操作的？ 
答：Java中的String类提供了支持正则表达式操作的方法，包括：matches()、replaceAll()、replaceFirst()、split()。此外，Java中可以用Pattern类表示正则表达式对象，它提供了丰富的API进行各种正则表达式操作

反射

这篇文章总结比较好:http://blog.csdn.net/shengzhu1/article/details/73013506

JVM会启动，你的代码会编译成一个.class文件，然后被类加载器加载进jvm的内存中，你的类Object加载到方法区中，创建了Object类的class对象到堆中，注意这个不是new出来的对象，而是类的类型对象，每个类只有一个class对象，作为方法区类的数据结构的接口。

反射提供的功能:

    ①:在运行时判断任意一个对象所属的类。 
    ②:在运行时构造任意一个类的对象。 
    ③:在运行时判断任意一个类所具有的成员变量和方法。 
    ④: 在运行时调用任意一个对象的方法

java.lang.reflect

①:Class类：代表一个类。【注:这个Class类进行继承了Object，比较特别】 
②:Field 类：代表类的成员变量（成员变量也称为类的属性）。 
③:Method类：代表类的方法。 
④:Constructor 类：代表类的构造方法。 
⑤:Array类：提供了动态创建数组，以及访问数组的元素的静态方法

常使用的方法

①: getName()：获得类的完整名字。 
②: getFields()：获得类的public类型的属性。 
③: getDeclaredFields()：获得类的所有属性。 
④: getMethods()：获得类的public类型的方法。 
⑤: getDeclaredMethods()：获得类的所有方法。 
⑥:getMethod(String name, Class[] parameterTypes)：获得类的特定方法，name参数指定方法的名字parameterTypes参数指定方法的参数类型。 
⑦:getConstructors()：获得类的public类型的构造方法。 
⑧:getConstructor(Class[] parameterTypes)：获得类的特定构造方法，parameterTypes参数指定构造方法的参数类型。 
⑨:newInstance()：通过类的不带参数的构造方法创建这个类的一个对象。

2、获得一个类的类对象有哪些方式？ 
答： 
- 方法1：类型.class，例如：String.class 
- 方法2：对象.getClass()，例如："hello".getClass() 
- 方法3：Class.forName()，例如：Class.forName("java.lang.String")

3、如何通过反射创建对象？ 
答： 
- 方法1：通过类对象调用newInstance()方法，例如：String.class.newInstance() 
- 方法2：通过类对象的getConstructor()或getDeclaredConstructor()方法获得构造器（Constructor）对象并调用其newInstance()方法创建对象，例如：String.class.getConstructor(String.class).newInstance("Hello");

4、如何通过反射获取和设置对象私有字段的值？ 
答：可以通过类对象的getDeclaredField()方法字段（Field）对象，然后再通过字段对象的setAccessible(true)将其设置为可以访问，接下来就可以通过get/set方法来获取/设置字段的值了。

5、如何通过反射调用对象的方法？ 

```java
import java.lang.reflect.Method;

class MethodInvokeTest {

    public static void main(String[] args) throws Exception {
        String str = "hello";
        Method m = str.getClass().getMethod("toUpperCase");
        System.out.println(m.invoke(str));  // HELLO
    }
}
```


设计模式

面向对象三大特征：
    封装
    继承
    多态
        覆盖
        重载


1、面向对象的"六原则一法则"
    单一职责原则：一个类只做它该做的事情
    依赖倒转原则："抽象不应依赖于细节，细节应该依赖于抽象。"，面向接口编程
    接口隔离原则：接口要小而专，绝不能大而全
    开闭原则：软件实体应当对扩展开放，对修改关闭
    里氏替换原则 ： "子类型必须能够替换掉它们的基类型。"
    合成聚合复用原则：优先使用聚合或合成关系复用代码。类与类之间简单的说有三种关系，Is-A关系、Has-A关系、Use-A关系，分别代表继承、关联和依赖。其中，关联关系根据其关联的强度又可以进一步划分为关联、聚合和合成。

    迪米特法则：迪米特法则又叫最少知识原则，一个对象应当对其他对象有尽可能少的了解。
    总结表较好：http://blog.csdn.net/yanbober/article/details/45312243

2、简述一下你了解的设计模式。 
答：所谓设计模式，就是一套被反复使用的代码设计经验的总结（情境中一个问题经过证实的一个解决方案）。使用设计模式是为了可重用代码、让代码更容易被他人理解、保证代码可靠性。设计模式使人们可以更加简单方便的复用成功的设计和体系结构。将已证实的技术表述成设计模式也会使新系统开发者更加容易理解其设计思路。 

单例模式：某个类在整个应用程序中只有一个实例对象。使用单例，可以避免建立多个实例带来的资源开销，而且在某些场景下，必须使用单个实例对象，多个实例还会引发异常，例如常用的工具类、线程池、缓存等场合。
工厂设计模式：工厂类可以根据条件生成不同的子类实例，这些子类有一个公共的抽象父类并且实现了相同的方法，但是这些方法针对不同的数据进行了不同的操作（多态方法）。静态工厂、简单工厂、工厂模式、抽象工厂
适配器模式：将一个类的接口转换成客户期望的另一个接口,适配器让原本接口不兼容的类可以相互合作.
观察者模式：定义了对象之间的一对多的依赖，当一个对象改变时，它的所有的依赖者都会收到通知并自动更新。


3、什么是UML？ 
答：UML是统一建模语言（Unified Modeling Language）的缩写。使用UML可以帮助沟通与交流，辅助应用设计和文档的生成，还能够阐释系统的结构和行为。

4、UML定义了多种图形化的符号来描述软件系统部分或全部的静态结构和动态结构，包括：用例图（use case diagram）、类图（class diagram）、时序图（sequence diagram）、状态图（statechart diagram）、活动图（activity diagram）、构件图（component diagram）、部署图（deployment diagram）等。在这些图形化符号中，有三种图最为重要，分别是：用例图（用来捕获需求，描述系统的功能，通过该图可以迅速的了解系统的功能模块及其关系）、类图（描述类以及类与类之间的关系，通过该图可以快速了解系统）、时序图（描述执行特定任务时对象之间的交互关系以及执行顺序，通过该图可以了解对象能接收的消息也就是说对象能够向外界提供的服务）。 


Java Web和Web Service

1、阐述Servlet和CGI的区别? 
答：Servlet与CGI的区别在于Servlet处于服务器进程中，它通过多线程方式运行其service()方法，一个实例可以服务于多个请求，并且其实例一般不会销毁，而CGI对每个请求都产生新的进程，服务完成后就销毁，所以效率上低于Servlet。

2、Servlet接口中有哪些方法？ 
答：Servlet接口定义了5个方法，其中前三个方法与Servlet生命周期相关： 
- void init(ServletConfig config) throws ServletException 
- void service(ServletRequest req, ServletResponse resp) throws ServletException, java.io.IOException 
- void destory() 
- java.lang.String getServletInfo() 
- ServletConfig getServletConfig()

    Web容器加载Servlet并将其实例化后，Servlet生命周期开始，容器运行其init()方法进行Servlet的初始化；请求到达时调用Servlet的service()方法，service()方法会根据需要调用与请求对应的doGet或doPost等方法；当服务器关闭或项目被卸载时服务器会将Servlet实例销毁，此时会调用Servlet的destroy()方法。

4、转发（forward）和重定向（redirect）的区别？ 
答：forward是容器中控制权的转向，是服务器请求资源，服务器直接访问目标地址的URL，把那个URL 的响应内容读取过来，然后把这些内容再发给浏览器；redirect就是服务器端根据逻辑，发送一个状态码，告诉浏览器重新去请求那个地址。
forward更加高效，所以在满足需要时尽量使用forward（通过调用RequestDispatcher对象的forward()方法，该对象可以通过ServletRequest对象的getRequestDispatcher()方法获得），并且这样也有助于隐藏实际的链接；在有些情况下，比如需要访问一个其它服务器上的资源，则必须使用重定向（通过HttpServletResponse对象调用其sendRedirect()方法实现）。


spring

1、Spring中自动装配的方式有哪些？ 
答： 
- no：不进行自动装配，手动设置Bean的依赖关系。 
- byName：根据Bean的名字进行自动装配。 
- byType：根据Bean的类型进行自动装配。 
- constructor：类似于byType，不过是应用于构造器的参数，如果正好有一个Bean与构造器的参数类型相同则可以自动装配，否则会导致错误。 
- autodetect：如果有默认的构造器，则通过constructor的方式进行自动装配，否则使用byType的方式进行自动装配。

2、Spring MVC的工作原理？
① 客户端的所有请求都交给前端控制器DispatcherServlet来处理，它会负责调用系统的其他模块来真正处理用户的请求。 
② DispatcherServlet收到请求后，将根据请求的信息（包括URL、HTTP协议方法、请求头、请求参数、Cookie等）以及HandlerMapping的配置找到处理该请求的Handler（任何一个对象都可以作为请求的Handler）。 
③在这个地方Spring会通过HandlerAdapter对该处理器进行封装。 
④ HandlerAdapter是一个适配器，它用统一的接口对各种Handler中的方法进行调用。 
⑤ Handler完成对用户请求的处理后，会返回一个ModelAndView对象给DispatcherServlet，ModelAndView顾名思义，包含了数据模型以及相应的视图的信息。 
⑥ ModelAndView的视图是逻辑视图，DispatcherServlet还要借助ViewResolver完成从逻辑视图到真实视图对象的解析工作。 
⑦ 当得到真正的视图对象后，DispatcherServlet会利用视图对象对模型数据进行渲染。 
⑧ 客户端得到响应，可能是一个普通的HTML页面，也可以是XML或JSON字符串，还可以是一张图片或者一个PDF文件

3、选择使用Spring框架的原因（Spring框架为企业级开发带来的好处有哪些）？ 
答：可以从以下几个方面作答： 
- 非侵入式：支持基于POJO的编程模式，不强制性的要求实现Spring框架中的接口或继承Spring框架中的类。 
- IoC容器：IoC容器帮助应用程序管理对象以及对象之间的依赖关系，对象之间的依赖关系如果发生了改变只需要修改配置文件而不是修改代码，因为代码的修改可能意味着项目的重新构建和完整的回归测试。有了IoC容器，程序员再也不需要自己编写工厂、单例，这一点特别符合Spring的精神"不要重复的发明轮子"。 
- AOP（面向切面编程）：将所有的横切关注功能封装到切面（aspect）中，通过配置的方式将横切关注功能动态添加到目标代码上，进一步实现了业务逻辑和系统服务之间的分离。另一方面，有了AOP程序员可以省去很多自己写代理类的工作。 
- MVC：Spring的MVC框架是非常优秀的，从各个方面都可以甩Struts 2几条街，为Web表示层提供了更好的解决方案。 
- 事务管理：Spring以宽广的胸怀接纳多种持久层技术，并且为其提供了声明式的事务管理，在不需要任何一行代码的情况下就能够完成事务管理。 
- 其他：选择Spring框架的原因还远不止于此，Spring为Java企业级开发提供了一站式选择，你可以在需要的时候使用它的部分和全部，更重要的是，你甚至可以在感觉不到Spring存在的情况下，在你的项目中使用Spring提供的各种优秀的功能。


4、阐述Spring框架中Bean的生命周期？ 
答： 
① Spring IoC容器找到关于Bean的定义并实例化该Bean。 
② Spring IoC容器对Bean进行依赖注入。 
③ 如果Bean实现了BeanNameAware接口，则将该Bean的id传给setBeanName方法。 
④ 如果Bean实现了BeanFactoryAware接口，则将BeanFactory对象传给setBeanFactory方法。 
⑤ 如果Bean实现了BeanPostProcessor接口，则调用其postProcessBeforeInitialization方法。 
⑥ 如果Bean实现了InitializingBean接口，则调用其afterPropertySet方法。 
⑦ 如果有和Bean关联的BeanPostProcessors对象，则这些对象的postProcessAfterInitialization方法被调用。 
⑧ 当销毁Bean实例时，如果Bean实现了DisposableBean接口，则调用其destroy方法。


5、在Web项目中如何获得Spring的IoC容器？ 
答：

WebApplicationContext ctx = 
WebApplicationContextUtils.getWebApplicationContext(servletContext);


大型网站架构方面问题总结

1、大型网站在架构上应当考虑哪些问题？ 
答： 
- 分层：分层是处理任何复杂系统最常见的手段之一，将系统横向切分成若干个层面，每个层面只承担单一的职责，然后通过下层为上层提供的基础设施和服务以及上层对下层的调用来形成一个完整的复杂的系统。计算机网络的开放系统互联参考模型（OSI/RM）和Internet的TCP/IP模型都是分层结构，大型网站的软件系统也可以使用分层的理念将其分为持久层（提供数据存储和访问服务）、业务层（处理业务逻辑，系统中最核心的部分）和表示层（系统交互、视图展示）。需要指出的是：（1）分层是逻辑上的划分，在物理上可以位于同一设备上也可以在不同的设备上部署不同的功能模块，这样可以使用更多的计算资源来应对用户的并发访问；（2）层与层之间应当有清晰的边界，这样分层才有意义，才更利于软件的开发和维护。 
- 分割：分割是对软件的纵向切分。我们可以将大型网站的不同功能和服务分割开，形成高内聚低耦合的功能模块（单元）。在设计初期可以做一个粗粒度的分割，将网站分割为若干个功能模块，后期还可以进一步对每个模块进行细粒度的分割，这样一方面有助于软件的开发和维护，另一方面有助于分布式的部署，提供网站的并发处理能力和功能的扩展。 
- 缓存：所谓缓存就是用空间换取时间的技术，将数据尽可能放在距离计算最近的位置。使用缓存是网站优化的第一定律。我们通常说的CDN、反向代理、热点数据都是对缓存技术的使用。 
- 异步：异步是实现软件实体之间解耦合的又一重要手段。异步架构是典型的生产者消费者模式，二者之间没有直接的调用关系，只要保持数据结构不变，彼此功能实现可以随意变化而不互相影响，这对网站的扩展非常有利。使用异步处理还可以提高系统可用性，加快网站的响应速度（用Ajax加载数据就是一种异步技术），同时还可以起到削峰作用（应对瞬时高并发）。&quot；能推迟处理的都要推迟处理"是网站优化的第二定律，而异步是践行网站优化第二定律的重要手段。 
- 分布式：除了上面提到的内容，网站的静态资源（JavaScript、CSS、图片等）也可以采用独立分布式部署并采用独立的域名，这样可以减轻应用服务器的负载压力，也使得浏览器对资源的加载更快。数据的存取也应该是分布式的，传统的商业级关系型数据库产品基本上都支持分布式部署，而新生的NoSQL产品几乎都是分布式的。当然，网站后台的业务处理也要使用分布式技术，例如查询索引的构建、数据分析等，这些业务计算规模庞大，可以使用Hadoop以及MapReduce分布式计算框架来处理。 
- 集群：集群使得有更多的服务器提供相同的服务，可以更好的提供对并发的支持。 
- 冗余：各种服务器都要提供相应的冗余服务器以便在某台或某些服务器宕机时还能保证网站可以正常工作，同时也提供了灾难恢复的可能性。冗余是网站高可用性的重要保证。


2、你用过的网站前端优化的技术有哪些？ 
答： 
① 浏览器访问优化： 
- 减少HTTP请求数量：合并CSS、合并JavaScript、合并图片（CSS Sprite） 
- 使用浏览器缓存：通过设置HTTP响应头中的Cache-Control和Expires属性，将CSS、JavaScript、图片等在浏览器中缓存，当这些静态资源需要更新时，可以更新HTML文件中的引用来让浏览器重新请求新的资源 
- 启用压缩 
- CSS前置，JavaScript后置 
- 减少Cookie传输 
② CDN加速：CDN（Content Distribute Network）的本质仍然是缓存，将数据缓存在离用户最近的地方，CDN通常部署在网络运营商的机房，不仅可以提升响应速度，还可以减少应用服务器的压力。当然，CDN缓存的通常都是静态资源。 
③ 反向代理：反向代理相当于应用服务器的一个门面，可以保护网站的安全性，也可以实现负载均衡的功能，当然最重要的是它缓存了用户访问的热点资源，可以直接从反向代理将某些内容返回给用户浏览器。

3、你使用过的应用服务器优化技术有哪些？ 
答： 
 
① 使用集群。
②分布式缓存：缓存的本质就是内存中的哈希表，如果设计一个优质的哈希函数，那么理论上哈希表读写的渐近时间复杂度为O(1)。缓存主要用来存放那些读写比很高、变化很少的数据，这样应用程序读取数据时先到缓存中读取，如果没有或者数据已经失效再去访问数据库或文件系统，并根据拟定的规则将数据写入缓存。对网站数据的访问也符合二八定律（Pareto分布，幂律分布），即80%的访问都集中在20%的数据上，如果能够将这20%的数据缓存起来，那么系统的性能将得到显著的改善。当然，使用缓存需要解决以下几个问题： 
- 频繁修改的数据； 
- 数据不一致与脏读； 
- 缓存雪崩（可以采用分布式缓存服务器集群加以解决，memcached是广泛采用的解决方案）； 
- 缓存预热； 
- 缓存穿透（恶意持续请求不存在的数据）。 
 ③ 异步操作：可以使用消息队列将调用异步化，通过异步处理将短时间高并发产生的事件消息存储在消息队列中，从而起到削峰作用。电商网站在进行促销活动时，可以将用户的订单请求存入消息队列，这样可以抵御大量的并发订单请求对系统和数据库的冲击。目前，绝大多数的电商网站即便不进行促销活动，订单系统都采用了消息队列来处理。 
④ 代码优化： 
- 多线程：基于Java的Web开发基本上都通过多线程的方式响应用户的并发请求，使用多线程技术在编程上要解决线程安全问题，主要可以考虑以下几个方面：A. 将对象设计为无状态对象（这和面向对象的编程观点是矛盾的，在面向对象的世界中被视为不良设计），这样就不会存在并发访问时对象状态不一致的问题。B. 在方法内部创建对象，这样对象由进入方法的线程创建，不会出现多个线程访问同一对象的问题。使用ThreadLocal将对象与线程绑定也是很好的做法，这一点在前面已经探讨过了。C. 对资源进行并发访问时应当使用合理的锁机制。 
- 非阻塞I/O： 使用单线程和非阻塞I/O是目前公认的比多线程的方式更能充分发挥服务器性能的应用模式，基于Node.js构建的服务器就采用了这样的方式。Java在JDK 1.4中就引入了NIO（Non-blocking I/O）,在Servlet 3规范中又引入了异步Servlet的概念，这些都为在服务器端采用非阻塞I/O提供了必要的基础。 
- 资源复用：资源复用主要有两种方式，一是单例，二是对象池，我们使用的数据库连接池、线程池都是对象池化技术，这是典型的用空间换取时间的策略，另一方面也实现对资源的复用，从而避免了不必要的创建和释放资源所带来的开销。

4、什么是XSS攻击？什么是SQL注入攻击？什么是CSRF攻击？ 
答： 
- XSS（Cross Site Script，跨站脚本攻击）是向网页中注入恶意脚本在用户浏览网页时在用户浏览器中执行恶意脚本的攻击方式。跨站脚本攻击分有两种形式：反射型攻击（诱使用户点击一个嵌入恶意脚本的链接以达到攻击的目标，目前有很多攻击者利用论坛、微博发布含有恶意脚本的URL就属于这种方式）和持久型攻击（将恶意脚本提交到被攻击网站的数据库中，用户浏览网页时，恶意脚本从数据库中被加载到页面执行，QQ邮箱的早期版本就曾经被利用作为持久型跨站脚本攻击的平台）。XSS虽然不是什么新鲜玩意，但是攻击的手法却不断翻新，防范XSS主要有两方面：消毒（对危险字符进行转义）和HttpOnly（防范XSS攻击者窃取Cookie数据）。 
- SQL注入攻击是注入攻击最常见的形式（此外还有OS注入攻击（Struts 2的高危漏洞就是通过OGNL实施OS注入攻击导致的）），当服务器使用请求参数构造SQL语句时，恶意的SQL被嵌入到SQL中交给数据库执行。SQL注入攻击需要攻击者对数据库结构有所了解才能进行，攻击者想要获得表结构有多种方式：（1）如果使用开源系统搭建网站，数据库结构也是公开的（目前有很多现成的系统可以直接搭建论坛，电商网站，虽然方便快捷但是风险是必须要认真评估的）；（2）错误回显（如果将服务器的错误信息直接显示在页面上，攻击者可以通过非法参数引发页面错误从而通过错误信息了解数据库结构，Web应用应当设置友好的错误页，一方面符合最小惊讶原则，一方面屏蔽掉可能给系统带来危险的错误回显信息）；（3）盲注。防范SQL注入攻击也可以采用消毒的方式，通过正则表达式对请求参数进行验证，此外，参数绑定也是很好的手段，这样恶意的SQL会被当做SQL的参数而不是命令被执行，JDBC中的PreparedStatement就是支持参数绑定的语句对象，从性能和安全性上都明显优于Statement。 
- CSRF攻击（Cross Site Request Forgery，跨站请求伪造）是攻击者通过跨站请求，以合法的用户身份进行非法操作（如转账或发帖等）。CSRF的原理是利用浏览器的Cookie或服务器的Session，盗取用户身份，其原理如下图所示。防范CSRF的主要手段是识别请求者的身份，主要有以下几种方式：（1）在表单中添加令牌（token）；（2）验证码；（3）检查请求头中的Referer（前面提到防图片盗链接也是用的这种方式）。令牌和验证都具有一次消费性的特征，因此在原理上一致的，但是验证码是一种糟糕的用户体验，不是必要的情况下不要轻易使用验证码，目前很多网站的做法是如果在短时间内多次提交一个表单未获得成功后才要求提供验证码，这样会获得较好的用户体验。


5、谈一谈测试驱动开发（TDD）的好处以及你的理解。 
答：TDD是指在编写真正的功能实现代码之前先写测试代码，然后根据需要重构实现代码。在JUnit的作者Kent Beck的大作《测试驱动开发：实战与模式解析》（Test-Driven Development: by Example）一书中有这么一段内容：“消除恐惧和不确定性是编写测试驱动代码的重要原因”。因为编写代码时的恐惧会让你小心试探，让你回避沟通，让你羞于得到反馈，让你变得焦躁不安，而TDD是消除恐惧、让Java开发者更加自信更加乐于沟通的重要手段。TDD会带来的好处可能不会马上呈现，但是你在某个时候一定会发现，这些好处包括： 
- 更清晰的代码 — 只写需要的代码 
- 更好的设计 
- 更出色的灵活性 — 鼓励程序员面向接口编程 
- 更快速的反馈 — 不会到系统上线时才知道bug的存在


linux

进程和线程的区别：
    进程有独立的地址空间，一个进程崩溃后，在保护模式下不会对其它进程产生影响，而线程只是一个进程中的不同执行路径。线程有自己的堆栈和局部变量，但线程之间没有单独的地址空间，一个线程死掉就等于整个进程死掉，所以多进程的程序要比多线程的程序健壮，但在进程切换时，耗费资源较大，效率要差一些。而且多线程之间通过共享内存空间非常高效。
    linux通过fork创建子进程，通过clone创建线程。
    进程和线程的区别：http://blog.csdn.net/qq_21792169/article/details/50437304


---
### 参考资料
- [Java面试题全集（上](http://blog.csdn.net/jackfrued/article/details/44921941)
- [【系列】重新认识Java——字符串（String）](http://blog.csdn.net/xialei199023/article/details/63251366)
- [深入分析Java String.intern()方法](http://blog.csdn.net/u012546526/article/details/44619519)
- [java 内部类（inner class）详解](http://blog.csdn.net/suifeng3051/article/details/51791812)
- [Java中反射机制（Reflection）](http://blog.csdn.net/shengzhu1/article/details/73013506)
tmp: 
    jdk中不同版本设置：http://blog.csdn.net/qq_27093465/article/details/52796892
    java中信号量机制：限制对某个共享资源进行访问的线程的数量，须得到信号量的许可（调用Semaphore对象的acquire()方法）；完成对资源的访问后，线程必须向信号量归还许可（调用Semaphore对象的release()方法）。

    java7、java8中引入的一些特性
    java网络编程方面的一些内容总结
    PrintWriter在实际应用中也使用比较多
    maven属性作用范围：http://blog.csdn.net/kimylrong/article/details/50353161


海量数据问题

参考资料：http://blog.csdn.net/v_july_v/article/details/7382693

密匙一、分而治之/Hash映射 + Hash_map统计 + 堆/快速/归并排序
    海量日志数据，提取出某日访问百度次数最多的那个IP？
    寻找热门查询，300万个查询字符串中统计最热门的10个查询？
        hashmap + 堆，维护k个元素的最小堆，即用容量为k的最小堆存储最先遍历到的k个数，并假设它们即是最大的k个数。继续遍历数列，每次遍历一个元素x，与堆顶元素比较，若x>kmin，则更新堆。
        