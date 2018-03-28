---
layout:     post
title:      "Java 集合框架常见面试总结"
subtitle:   "Java 集合框架常见面试总结"
date:       2018-03-22 8:00:00
author:     "julyerr"
header-img: "img/lib/collection/collection.jpg"
header-mask: 0.5
catalog:    true
tags:
    - collections
---



collection

集合容器在不断向上抽取过程中。出现了集合体系。
在使用一个体系时，原则：参阅顶层内容。建立底层对象。

集合和数组的区别：
1：数组是固定长度的；集合可变长度的。
2：数组可以存储基本数据类型，也可以存储引用数据类型；集合只能存储引用数据类型。
3：数组存储的元素必须是同一个数据类型；集合存储的对象可以是不同数据类型。

使用基本数据类型或者知道数据元素数量的时候可以考虑Array;
ArrayList处理固定数量的基本类型数据类型时会自动装箱来减少编码工作量，但是相对较慢。




Iterator、ListIterator 和 Enumeration的区别?
Enumeration 接口在 Java1.2 版本开始有，所以 Enumeration 是合法规范的接口
Enumeration 使用 elements() 方法
Iterator 对所有 Java 集合类都有实现
Iterator 使用 iterator 方法
Iterator 只能往一个方向前进
ListIterator 仅仅对 List 类型的类实现了
ListIterator 使用 listIterator ()方法

Iterator远远比Enumeration安全，因为其他线程不能够修改正在被iterator遍历的集合里面的对象。同时，Iterator允许调用者删除底层集合里面的元素，这对Enumeration来说是不可能的。

1、List、Set、Map是否继承自Collection接口？ 
答：List、Set 是，Map 不是。Map是键值对映射容器，与List和Set有明显的区别，而Set存储的零散的元素且不允许有重复元素（数学中的集合也是如此），List是线性结构的容器，适用于按数值索引访问元素的情形。

2、阐述ArrayList、Vector、LinkedList的存储性能和特性。 
ArrayList 使用数组实现存储，随机访问速度效率高；
LinkedList使用双向链表实现存储，插入和删除的效率较高；
Vector中的方法由于添加了synchronized修饰，因此Vector是线程安全的容器，但性能上较ArrayList差；
由于ArrayList和LinkedListed都是非线程安全的，如果遇到多个线程操作同一个容器的场景，则可以通过工具类Collections中的synchronizedList方法将其转换成线程安全的容器后再使用（这是对装潢模式的应用，将已有对象传入另一个类的构造器中创建新的对象来增强实现）。
Vector默认大小10，2倍长度扩容。，ArrayList默认大小10，1.5倍长度扩容

3、Collection和Collections的区别？ 
答：Collection是一个接口，它是Set、List等容器的父接口；Collections是个一个工具类，提供了一系列的静态方法来辅助容器操作，这些方法包括对容器的搜索、排序、线程安全化等等。


TreeSet和HashSet 以及 TreeMap和HashMap之间的比较：
    对于HashMap，系统仅将value作为key的附属物而已，系统采用Hash算法来决定key的存储位置，这样可以保证快速的存，取集合key，而value仅仅总是作为key的附属。HashSet采用Hash算法来决定集合元素的存储位置，这样可以保证快速的存，取集合元素（底层还是使用了HashMap结构，适配器模式，只不过value域是一个空对象）。
    

    TreeSet的底层实际使用的存储容器就是TreeMap（将空对象设置成value域），采用红黑树的结构保存每个Entry,每个Entry被当成”红黑数”的一个节点来对待。
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


java中fail-fast 和 fail-safe的区别

fail-fast机制在遍历一个集合时，当集合结构被修改，会抛出Concurrent Modification Exception。
fail-fast会在以下两种情况下抛出ConcurrentModificationException
（1）单线程环境
集合被创建后，在遍历它的过程中修改了结构(遍历过程中调用了remove()方法)。
（2）多线程环境
当一个线程在遍历这个集合，而另一个线程对这个集合的结构进行了修改。

fail-safe任何对集合结构的修改都会在一个复制的集合上进行修改，因此不会抛出ConcurrentModificationException
fail-safe机制有两个问题
（1）需要复制集合，产生大量的无效对象，开销大
（2）无法保证读取的数据是目前原始数据结构中的数据。
java.util.concurrent下的包比如CopyOnWriteArrayList，ConcurrentHashMap都是fail-safe的

具体参考：http://blog.csdn.net/ch717828/article/details/46892051


将数组转换成集合，有什么好处呢？
用aslist方法，将数组变成集合；
可以通过list集合中的方法来操作数组中的元素：isEmpty()、contains、indexOf、set；
数组是固定长度，不可以使用集合对象增加或者删除等，会改变数组长度的功能方法。比如add、remove、clear。（会报不支持操作异常UnsupportedOperationException）,可以将数组原有的内容来初始化List对象

2.为什么集合类没有实现Cloneable和Serializable接口？

集合类接口指定了一组叫做元素的对象。集合类接口的每一种具体的实现类都可以选择以它自己的方式对元素进行保存和排序。有的集合类允许重复的键，有些不允许。
克隆(cloning)或者是序列化(serialization)的语义和含义是跟具体的实现相关的。因此，应该由集合类的具体实现来决定如何被克隆或者是序列化。

hashmap工作原理
存储
首先获取key的hashcode，然后取模数组的长度，快速定位到要存储到数组中的坐标，然后判断数组中是否存储元素；
如果没有存储则新构建Node节点，把Node节点存储到数组中；
如果有元素，则迭代链表(红黑二叉树)，如果存在此key,默认更新value,不存在则把新构建的Node存储到链表的头部。
查找
获取key的hashcode，通过hashcode取模数组的长度，获取要定位元素的坐标，然后迭代链表（红黑树），进行每一个元素的key的equals对比，如果相同则返回该元素。

有两个参数可以影响HashMap的性能：初始容量（initalcapacity）和负载系数（load factor）。初始容量指定了初始table的大小，负载系数用来指定自动扩容的临界值。
HashMap默认的初始容量是32，负荷系数是0.75。如果map的大小比阀值大的时候，HashMap会对map的内容进行重新哈希Rehash，且使用更大的容量。容量总是2的幂,h&(length-1)就相当于对length取模，其效率要比直接取模高得多.


我们能否使用任何类作为Map的key？

我们可以使用任何类作为Map的key，然而在使用它们之前，需要考虑以下几点：
（1）如果类重写了equals()方法，它也应该重写hashCode()方法。
（2）类的所有实例需要遵循与equals()和hashCode()相关的规则。（请参考之前提到的这些规则）
（3）如果一个类没有使用equals()，你不应该在hashCode()中使用它。
（4）用户自定义key类的最佳实践是使之为不可变的，这样，hashCode()值可以被缓存起来，拥有更好的性能。不可变的类也可以确保hashCode()和equals()在未来不会改变，这样就会解决与可变相关的问题了。

对于ArrayList集合，判断元素是否存在，或者删元素底层依据都是equals方法。
对于HashSet集合，判断元素是否存在，或者删除元素，底层依据的是hashCode方法和equals方法。

什么是Java优先级队列(Priority Queue)？

PriorityQueue是一个基于优先级堆的无界有序队列，它的元素是按照自然顺序(natural order)排序的。在创建的时候，我们可以给它提供一个负责给元素排序的比较器。PriorityQueue不允许null值，因为他们没有自然顺序，或者说他们没有任何的相关联的比较器。最后，PriorityQueue不是线程安全的，入队和出队的时间复杂度是O(log(n))。


如何权衡是使用无序的数组还是有序的数组？

有序数组最大的好处在于查找的时间复杂度是O(log n)，而无序数组是O(n)。有序数组的缺点是插入操作的时间复杂度是O(n)，因为值大的元素需要往后移动来给新元素腾位置。相反，无序数组的插入时间复杂度是常量O(1)。
所以，查找操作多的时候，使用有序；增删操作多的使用无序的即可。



与Java集合框架相关的有哪些最好的实践？
（1）根据需要选择正确的集合类型。若指定大小，选用Array而非ArrayList；若要根据插入顺序遍历一个Map，使用TreeMap。若不需要重复元素，应该使用Set。
（2）一些集合类允许指定初始容量，所以如果我们能够估计到存储元素的数量，我们可以使用它，就避免了重新哈希或大小调整。
（3）基于接口编程，而非基于实现编程，它允许我们后来轻易地改变实现。
（4）总是使用类型安全的泛型，避免在运行时出现ClassCastException。
（5）使用JDK提供的不可变类作为Map的key，可以避免自己实现hashCode()和equals()。
（6）尽可能使用Collections工具类，或者获取只读、同步或空的集合，而非编写自己的实现。它将会提供代码重用性，它有着更好的稳定性和可维护性。

什么是 Properties 类？
· Properties 是Hashtable的子类。它被用于维护值的list，其中它们的键、值都是String类型

concurrenthashmap如何保证多线程访问的安全性？

jdk1.7之前，ConcurrentHashMap就是一个Segment(继承ReentrantLock)数组，每个Segment实例又是一个hash表;针对hash表的不同部分,使用不同的锁控制，从而允许多个修改的线程并发进行，理论上最大并发度和Segment个数相等。

读写某个Key，先获取Key的hash值，将哈希值的高N位对Segment个数取模从而得到该Key应该属于哪个Segment。
对于写操作，先获取Key所在的Segment的锁，然后对待普通HashMap一样操作该Segment.
对于读操作,由于value被声明为volatile类型，key、hash、next均为final类型，因此可以不用加锁直接诶进行读取操作。
进行跨段计算size的大小，不上锁的前提下逐个Segment计算3次size，如果某相邻两次计算获取的所有Segment的更新次数相同，说明中间无更新操作，可直接返回结果;如果Map有更新，对所有的Segment加锁重新计算size大小。

jdk1.8中，为减少hash碰撞带来的效率问题，在链表长度超过一定阈值（8）时将链表转换为红黑树。对于写操作，如果Key对应的数组元素为null，则通过CAS操作将其设置为当前值; 如果Key对应的数组元素（不为null，则对该元素使用synchronized关键字申请锁，然后进行操作。如果该put操作使得当前链表长度超过一定阈值，则将该链表转换为树。对于读操作，val被volatile关键字修饰,对多线程可见。 只要hash不发生冲突就不会涉及锁的操作




---
### 参考资料
- [Java集合类相关面试题](http://blog.csdn.net/caohaicheng/article/details/38040595)
- [Java集合面试总结](http://blog.csdn.net/CSDN_Terence/article/details/78379878)